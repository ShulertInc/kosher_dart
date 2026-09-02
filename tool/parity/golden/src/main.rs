//! Dumps kosher-rust results as NDJSON so a Dart harness can diff kosher_dart against them.

use std::fmt::Write as _;
use std::io::Write as _;

use icu_calendar::cal::Hebrew;
use jiff::civil::{date, Date};
use jiff::tz::TimeZone;
use kosher_rust::calendar::{HebrewCalendar, HebrewCalendarDate, HebrewHolidayCalendar};
use kosher_rust::limudim::prelude::*;
use kosher_rust::zmanim::molad::MoladCalendar;
use kosher_rust::zmanim::presets::ALL_ZMANIM;
use kosher_rust::zmanim::types::config::CalculatorConfig;
use kosher_rust::zmanim::types::location::Location;
use kosher_rust::zmanim::ZmanimCalculator;

struct Place {
    key: &'static str,
    lat: f64,
    lon: f64,
    elev: f64,
    tz: &'static str,
}

const PLACES: &[Place] = &[
    Place { key: "jerusalem", lat: 31.778, lon: 35.2354, elev: 754.0, tz: "Asia/Jerusalem" },
    Place { key: "lakewood", lat: 40.0828, lon: -74.2094, elev: 0.0, tz: "America/New_York" },
    Place { key: "london", lat: 51.5074, lon: -0.1278, elev: 0.0, tz: "Europe/London" },
    Place { key: "melbourne", lat: -37.8136, lon: 144.9631, elev: 0.0, tz: "Australia/Melbourne" },
    Place { key: "anchorage", lat: 61.2181, lon: -149.9003, elev: 0.0, tz: "America/Anchorage" },
    Place { key: "reykjavik", lat: 64.1466, lon: -21.9426, elev: 0.0, tz: "Atlantic/Reykjavik" },
    // longitude/timezone mismatch: local mean time is far from civil time
    Place { key: "vigo", lat: 42.2406, lon: -8.7207, elev: 0.0, tz: "Europe/Madrid" },
    // southern hemisphere, no DST, far from its meridian
    Place { key: "johannesburg", lat: -26.2041, lon: 28.0473, elev: 1753.0, tz: "Africa/Johannesburg" },
    // inside the arctic circle: months at a time with no sunrise and no sunset
    Place { key: "longyearbyen", lat: 78.22, lon: 15.63, elev: 0.0, tz: "Arctic/Longyearbyen" },
];

fn configs() -> Vec<(&'static str, CalculatorConfig)> {
    let default = CalculatorConfig::default();
    let mut elevation = CalculatorConfig::default();
    elevation.use_elevation = true;
    let mut half_day = CalculatorConfig::default();
    half_day.use_astronomical_chatzos = false;
    half_day.use_astronomical_chatzos_for_other_zmanim = false;
    vec![
        ("default", default),
        ("elevation", elevation),
        ("halfday", half_day),
    ]
}

fn json_string(value: &str) -> String {
    let mut out = String::with_capacity(value.len() + 2);
    out.push('"');
    for ch in value.chars() {
        match ch {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => {
                let _ = write!(out, "\\u{:04x}", c as u32);
            }
            c => out.push(c),
        }
    }
    out.push('"');
    out
}

fn json_opt_debug<T: std::fmt::Debug>(value: Option<T>) -> String {
    match value {
        Some(inner) => json_string(&format!("{inner:?}")),
        None => "null".to_string(),
    }
}

/// Deterministic 64-bit LCG so the sample set is reproducible without a rand dependency.
struct Lcg(u64);

impl Lcg {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        self.0 >> 11
    }

    fn range(&mut self, low: i64, high: i64) -> i64 {
        low + (self.next() % ((high - low + 1) as u64)) as i64
    }
}

fn calendar_dates() -> Vec<Date> {
    let mut dates = Vec::new();
    let mut day = date(2019, 1, 1);
    let sweep_end = date(2030, 12, 31);
    while day <= sweep_end {
        dates.push(day);
        day = day.tomorrow().expect("date in range");
    }

    let mut rng = Lcg(0x5EED_1234_ABCD_0001);
    let low = date(1750, 1, 1).to_string();
    let _ = low;
    let start = date(1750, 1, 1);
    let span_days = start.until(date(2350, 12, 31)).expect("span").get_days() as i64;
    for _ in 0..4000 {
        let offset = rng.range(0, span_days);
        let picked = start
            .checked_add(jiff::Span::new().days(offset))
            .expect("offset in range");
        dates.push(picked);
    }

    dates.sort();
    dates.dedup();
    dates
}

fn zman_dates() -> Vec<Date> {
    let mut dates = Vec::new();
    // Solstices, equinoxes and DST edges across a few years.
    for year in [2021, 2024, 2027] {
        for (month, day) in [
            (1, 1),
            (2, 14),
            (3, 8),
            (3, 21),
            (3, 28),
            (4, 15),
            (5, 30),
            (6, 21),
            (7, 4),
            (8, 20),
            (9, 23),
            (10, 25),
            (11, 3),
            (12, 21),
            (12, 31),
        ] {
            dates.push(date(year, month, day));
        }
    }

    let mut rng = Lcg(0xC0FF_EE00_1234_5678);
    let start = date(1990, 1, 1);
    let span_days = start.until(date(2060, 12, 31)).expect("span").get_days() as i64;
    for _ in 0..60 {
        let offset = rng.range(0, span_days);
        dates.push(
            start
                .checked_add(jiff::Span::new().days(offset))
                .expect("offset in range"),
        );
    }

    dates.sort();
    dates.dedup();
    dates
}

fn daf_json(daf: Option<Daf>) -> String {
    match daf {
        Some(daf) => format!(
            "{{\"t\":{},\"p\":{}}}",
            json_string(&format!("{:?}", daf.tractate)),
            daf.page
        ),
        None => "null".to_string(),
    }
}

fn amud_json(amud: Option<Amud>) -> String {
    match amud {
        Some(amud) => format!(
            "{{\"t\":{},\"p\":{},\"s\":{}}}",
            json_string(&format!("{:?}", amud.tractate)),
            amud.page,
            json_string(&format!("{:?}", amud.side))
        ),
        None => "null".to_string(),
    }
}

fn mishna_json(mishna: &Mishna) -> String {
    format!(
        "{{\"t\":{},\"c\":{},\"m\":{}}}",
        json_string(&format!("{:?}", mishna.tractate)),
        mishna.chapter,
        mishna.mishna
    )
}

fn mishnas_json(mishnas: Option<Mishnas>) -> String {
    match mishnas {
        Some(Mishnas(first, second)) => {
            format!("[{},{}]", mishna_json(&first), mishna_json(&second))
        }
        None => "null".to_string(),
    }
}

fn pirkei_avos_json(unit: Option<PirkeiAvosUnit>) -> String {
    match unit {
        Some(PirkeiAvosUnit::Single(perek)) => format!("[{perek}]"),
        Some(PirkeiAvosUnit::Combined(first, second)) => format!("[{first},{second}]"),
        None => "null".to_string(),
    }
}

fn tehillim_json(unit: Option<TehillimUnit>) -> String {
    match unit {
        Some(TehillimUnit::Psalms { start, end }) => {
            format!("{{\"start\":{start},\"end\":{end}}}")
        }
        Some(TehillimUnit::PsalmVerses {
            psalm,
            start_verse,
            end_verse,
        }) => format!(
            "{{\"psalm\":{psalm},\"startVerse\":{start_verse},\"endVerse\":{end_verse}}}"
        ),
        None => "null".to_string(),
    }
}

fn holiday_view(day: &Date, in_israel: bool, modern: bool) -> String {
    let holidays: Vec<String> = day
        .holidays(in_israel, modern)
        .map(|holiday| json_string(&format!("{holiday:?}")))
        .collect();
    format!(
        "{{\"hol\":[{}],\"assur\":{},\"cl\":{},\"tp\":{},\"sp\":{},\"up\":{},\"ayt\":{}}}",
        holidays.join(","),
        day.is_assur_bemelacha(in_israel),
        day.has_candle_lighting(in_israel),
        json_opt_debug(day.todays_parsha(in_israel)),
        json_opt_debug(day.special_parsha(in_israel)),
        json_opt_debug(day.upcoming_parsha(in_israel)),
        day.is_aseres_yemei_teshuva(),
    )
}

fn dump_calendar(out: &mut impl std::io::Write) -> std::io::Result<()> {
    let jerusalem = TimeZone::get("Asia/Jerusalem").expect("bundled tzdb");

    for day in calendar_dates() {
        let hebrew = day.hebrew_date();
        let year = hebrew.year().extended_year();
        let month = hebrew.month();
        let molad = match day.molad(&jerusalem) {
            Ok((timestamp, month)) => {
                // Undo the Har Habayis local-mean-time offset and read the civil fields at
                // the fixed GMT+2 the molad is defined in, so a host with any timezone can
                // compare against them.
                let standard = timestamp + jiff::SignedDuration::from_millis(1_256_496);
                let civil = standard
                    .to_zoned(TimeZone::fixed(jiff::tz::offset(2)))
                    .datetime();
                format!(
                    "{{\"ms\":{},\"mo\":{},\"y\":{},\"mon\":{},\"d\":{},\"h\":{},\"mi\":{},\"s\":{},\"ns\":{}}}",
                    timestamp.as_millisecond(),
                    json_string(month.code().0.as_str()),
                    civil.year(),
                    civil.month(),
                    civil.day(),
                    civil.hour(),
                    civil.minute(),
                    civil.second(),
                    civil.subsec_nanosecond()
                )
            }
            Err(_) => "null".to_string(),
        };

        writeln!(
            out,
            "{{\"k\":\"cal\",\"g\":{},\"hy\":{},\"hmOrd\":{},\"hmCode\":{},\"hd\":{},\"hdoy\":{},\"dow\":{},\
             \"diy\":{},\"dim\":{},\"leap\":{},\"kviah\":{},\"il\":{},\"ch\":{},\"ilModern\":{},\"molad\":{},\
             \"dafYomiBavli\":{},\"dafYomiYerushalmi\":{},\"dafHashavua\":{},\"amudYomiDirshu\":{},\
             \"mishnaYomis\":{},\"pirkeiAvosIl\":{},\"pirkeiAvosCh\":{},\"tehillim\":{}}}",
            json_string(&day.to_string()),
            year,
            month.ordinal,
            json_string(month.standard_code.0.as_str()),
            hebrew.day_of_month().0,
            hebrew.day_of_year().0,
            day.weekday().to_sunday_one_offset(),
            json_opt_number(Hebrew::days_in_hebrew_year(year).map(i64::from)),
            json_opt_number(Hebrew::days_in_hebrew_month(year, day.input_month()).map(i64::from)),
            Hebrew::is_hebrew_leap_year(year),
            json_opt_debug(Hebrew::cheshvan_kislev_kviah(year)),
            holiday_view(&day, true, false),
            holiday_view(&day, false, false),
            holiday_view(&day, true, true),
            molad,
            daf_json(day.limud(DafYomiBavli::default())),
            daf_json(day.limud(DafYomiYerushalmiVilna::default())),
            daf_json(day.limud(DafHashavuaBavli::default())),
            amud_json(day.limud(AmudYomiBavliDirshu::default())),
            mishnas_json(day.limud(MishnaYomis)),
            pirkei_avos_json(day.limud(PirkeiAvos { in_israel: true })),
            pirkei_avos_json(day.limud(PirkeiAvos { in_israel: false })),
            tehillim_json(day.limud(TehillimMonthly)),
        )?;
    }

    Ok(())
}

fn json_opt_number(value: Option<i64>) -> String {
    match value {
        Some(number) => number.to_string(),
        None => "null".to_string(),
    }
}

fn dump_zmanim(out: &mut impl std::io::Write) -> std::io::Result<()> {
    let dates = zman_dates();

    for place in PLACES {
        let timezone = TimeZone::get(place.tz).expect("bundled tzdb");
        let location = Location::new(place.lat, place.lon, place.elev, Some(timezone))
            .expect("valid location");

        for (config_key, config) in configs() {
            for day in &dates {
                let calculator = ZmanimCalculator::new(location.clone(), *day, config);
                let mut entries: Vec<String> = Vec::with_capacity(ALL_ZMANIM.len());

                for preset in ALL_ZMANIM {
                    let value = match calculator.calculate(*preset) {
                        Ok(timestamp) => timestamp.as_millisecond().to_string(),
                        Err(error) => json_string(&format!("{error:?}")),
                    };
                    entries.push(format!("{}:{}", json_string(preset.method_name), value));
                }

                writeln!(
                    out,
                    "{{\"k\":\"zman\",\"loc\":{},\"lat\":{},\"lon\":{},\"elev\":{},\"tz\":{},\"cfg\":{},\"g\":{},\"t\":{{{}}}}}",
                    json_string(place.key),
                    place.lat,
                    place.lon,
                    place.elev,
                    json_string(place.tz),
                    json_string(config_key),
                    json_string(&day.to_string()),
                    entries.join(",")
                )?;
            }
        }
    }

    Ok(())
}

fn dump_presets(out: &mut impl std::io::Write) -> std::io::Result<()> {
    for preset in ALL_ZMANIM {
        writeln!(
            out,
            "{{\"k\":\"preset\",\"method\":{},\"name\":{},\"type\":{},\"deprecated\":{}}}",
            json_string(preset.method_name),
            json_string(preset.name),
            json_string(&format!("{:?}", preset.zman_type)),
            preset.deprecated
        )?;
    }
    Ok(())
}

fn main() -> std::io::Result<()> {
    let target = std::env::args().nth(1).unwrap_or_else(|| "all".to_string());
    let stdout = std::io::stdout();
    let mut out = std::io::BufWriter::new(stdout.lock());

    match target.as_str() {
        "calendar" => dump_calendar(&mut out)?,
        "zmanim" => dump_zmanim(&mut out)?,
        "presets" => dump_presets(&mut out)?,
        _ => {
            dump_presets(&mut out)?;
            dump_calendar(&mut out)?;
            dump_zmanim(&mut out)?;
        }
    }

    out.flush()
}
