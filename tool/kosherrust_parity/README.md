# Limudim parity against kosher-rust

Compares kosher_dart's learning schedules against
[kosher-rust](https://github.com/dickermoshe/kosher-rust) date by date and fails on any
disagreement.

`rust/` is a small binary on kosher-rust's public API. It reads `YYYY-MM-DD` lines on
stdin and prints one JSON line per date. `bin/limudim_parity.dart` builds the dates,
pipes them all through that binary once, computes the same limudim with kosher_dart, and
compares them field by field.

## Setup

`rust/Cargo.toml` points at a local kosher-rust clone by path; change that path to wherever
yours is. Then:

```bash
cd tool/kosherrust_parity/rust
cargo build --release
cd ..
dart pub get
```

On Windows without the MSVC build tools, build with an installed GNU toolchain, e.g.
`cargo +1.93.0-x86_64-pc-windows-gnu build --release`.

## Running

```bash
cd tool/kosherrust_parity
dart run bin/limudim_parity.dart --seed 7
```

It prints the seed, then per limud how many dates agreed on a value, agreed there is none,
agreed on an error, and differed, then examples of each difference. Exit code 1 means a
difference; rerun with the printed `--seed` to reproduce it.

Options: `--random N` (default 20000), `--sweep-from`/`--sweep-to` (default 1900-01-01 to
2300-12-31), `--random-from`/`--random-to` (default 0001-01-01 to 6235-12-31),
`--edge-days` (default 1500), `--golden <path to the binary>`.

## What it covers

Daf Yomi Bavli, Daf Yomi Yerushalmi, Daf Hashavua Bavli, Amud Yomi Bavli Dirshu, Mishna
Yomis, Pirkei Avos in Israel and in the diaspora, and monthly Tehillim.

The dates are:

- every day of the sweep range, which holds several full cycles of every schedule, each
  cycle start, and the years before the first one;
- every day of the first and last `--edge-days` of the random range;
- `--random` days drawn uniformly from the random range.

Each date gets a random `inIsrael`, which only Pirkei Avos may depend on, and a random way
of building its `JewishCalendar`: from a local or UTC `DateTime`, `setGregorianDate` on a
new calendar, `fromJewishDate` from the Hebrew date, or `setGregorianDate` on one calendar
reused across dates.

## Normalizations

- Tractates are compared by position in kosher-rust's lists: `Daf` and `Amud` numbers
  index its Bavli or Yerushalmi order and `Mishna` numbers its Mishna order. Amud side
  `BEIS` is kosher-rust's `Bet`.
- kosher_dart follows KosherJava and throws `ArgumentError` for Daf Yomi Bavli before
  1923-09-11 and Daf Yomi Yerushalmi before 1980-02-02; kosher-rust returns `None`. Those
  throws count as no limud. Any other error only agrees with an error.

## What agreement does not prove

Both libraries port the same sources, so a defect they share passes. Checked against
hebcal's `@hebcal/learning` over 1900-2300, every schedule agrees except two, where
kosher_dart keeps KosherJava's and kosher-rust's answer:

- Daf Yomi Yerushalmi: KosherJava's cycle-end search, which both ports copy, does not count
  a skipped day that lands on the first day of an extension. On 2172-07-30 (Tisha B'Av)
  that drops Niddah 13 and starts the next cycle a day early.
- Dirshu Amud Yomi: kosher-rust ends Rosh Hashana on 35b; hebcal ends it on 35a
  (hebcal/hebcal#316), and every date from 2027-07-01 is an amud apart.

## Range

The random range stops at 6235-12-31 because kosher-rust's Hebrew calendar ends with year
9999 (September 6239): from about 6236 its Yerushalmi cycle search runs past that year and
returns `None`, and in 9999 its Pirkei Avos panics looking for Rosh Hashana 10000.
0001-01-01 is the first date kosher_dart accepts.
