use std::io::{BufRead, BufWriter, Write};
use std::panic::{AssertUnwindSafe, catch_unwind};

use jiff::civil::Date;
use kosher_rust::limudim::prelude::*;

fn guarded(compute: impl FnOnce() -> String) -> String {
    catch_unwind(AssertUnwindSafe(compute)).unwrap_or_else(|_| "\"error\"".to_string())
}

fn daf(value: Option<Daf>) -> String {
    match value {
        Some(daf) => format!("{{\"t\":\"{:?}\",\"p\":{}}}", daf.tractate, daf.page),
        None => "null".to_string(),
    }
}

fn amud(value: Option<Amud>) -> String {
    match value {
        Some(amud) => format!(
            "{{\"t\":\"{:?}\",\"p\":{},\"s\":\"{:?}\"}}",
            amud.tractate, amud.page, amud.side
        ),
        None => "null".to_string(),
    }
}

fn mishna(value: &Mishna) -> String {
    format!(
        "{{\"t\":\"{:?}\",\"c\":{},\"m\":{}}}",
        value.tractate, value.chapter, value.mishna
    )
}

fn mishnas(value: Option<Mishnas>) -> String {
    match value {
        Some(Mishnas(first, second)) => format!("[{},{}]", mishna(&first), mishna(&second)),
        None => "null".to_string(),
    }
}

fn pirkei_avos(value: Option<PirkeiAvosUnit>) -> String {
    match value {
        Some(PirkeiAvosUnit::Single(perek)) => format!("[{perek}]"),
        Some(PirkeiAvosUnit::Combined(first, second)) => format!("[{first},{second}]"),
        None => "null".to_string(),
    }
}

fn tehillim(value: Option<TehillimUnit>) -> String {
    match value {
        Some(TehillimUnit::Psalms { start, end }) => format!("{{\"start\":{start},\"end\":{end}}}"),
        Some(TehillimUnit::PsalmVerses {
            psalm,
            start_verse,
            end_verse,
        }) => format!("{{\"psalm\":{psalm},\"startVerse\":{start_verse},\"endVerse\":{end_verse}}}"),
        None => "null".to_string(),
    }
}

fn line_for(day: Date) -> String {
    let fields = [
        ("dafYomiBavli", guarded(|| daf(day.limud(DafYomiBavli::default())))),
        ("dafYomiYerushalmi", guarded(|| daf(day.limud(DafYomiYerushalmiVilna::default())))),
        ("dafHashavuaBavli", guarded(|| daf(day.limud(DafHashavuaBavli::default())))),
        ("amudYomiBavliDirshu", guarded(|| amud(day.limud(AmudYomiBavliDirshu::default())))),
        ("mishnaYomis", guarded(|| mishnas(day.limud(MishnaYomis)))),
        ("pirkeiAvosIsrael", guarded(|| pirkei_avos(day.limud(PirkeiAvos::new(true))))),
        ("pirkeiAvosDiaspora", guarded(|| pirkei_avos(day.limud(PirkeiAvos::new(false))))),
        ("tehillimMonthly", guarded(|| tehillim(day.limud(TehillimMonthly)))),
    ];
    let body: Vec<String> = fields.iter().map(|(key, value)| format!("\"{key}\":{value}")).collect();
    format!("{{\"g\":\"{day}\",{}}}", body.join(","))
}

fn main() -> std::io::Result<()> {
    std::panic::set_hook(Box::new(|_| {}));
    let texts: Vec<String> = std::io::stdin()
        .lock()
        .lines()
        .collect::<std::io::Result<Vec<String>>>()?
        .into_iter()
        .map(|line| line.trim().trim_start_matches('\u{feff}').to_string())
        .filter(|text| !text.is_empty())
        .collect();
    let workers =std::thread::available_parallelism().map_or(1, |n| n.get());
    let chunk = texts.len().div_ceil(workers).max(1);
    let answers: Vec<String> = std::thread::scope(|scope| {
        let handles: Vec<_> = texts
            .chunks(chunk)
            .map(|part| {
                scope.spawn(move || {
                    part.iter()
                        .map(|text| match text.parse::<Date>() {
                            Ok(day) => line_for(day),
                            Err(_) => format!("{{\"g\":\"{text}\",\"unparsed\":true}}"),
                        })
                        .collect::<Vec<String>>()
                })
            })
            .collect();
        handles.into_iter().flat_map(|handle| handle.join().unwrap_or_default()).collect()
    });
    let stdout = std::io::stdout();
    let mut out = BufWriter::new(stdout.lock());
    for answer in answers {
        writeln!(out, "{answer}")?;
    }
    out.flush()
}
