# Parity against kosher-rust

[kosher-rust](https://github.com/dickermoshe/kosher-rust) is a Rust port of KosherJava
that is parity tested against the Java it came from. This harness compares kosher_dart
against it: `golden/` dumps kosher-rust's answers as NDJSON, and `parity.dart` recomputes
each one with kosher_dart and reports every disagreement grouped by check.

It found the divergences the commits around it fix. Run it after touching anything in
`lib/src/util/`, `lib/src/*zmanim_calendar.dart`, or `lib/src/hebrewcalendar/`.

## Running it

Clone kosher-rust next to this repository, then:

```bash
cd tool/parity/golden
cargo build --release
mkdir -p ../../../.goldens
./target/release/golden calendar > ../../../.goldens/calendar.ndjson
./target/release/golden zmanim   > ../../../.goldens/zmanim.ndjson
./target/release/golden presets  > ../../../.goldens/presets.ndjson

cd ../../..
dart run tool/parity/parity.dart .goldens
```

A clean run prints the counts and nothing else. Anything after them is a divergence:
the check that failed, how many dates or locations hit it, and five examples.

`--only calendar` or `--only zmanim` restricts the run; `--limit N` stops after N records.

## What it covers

`calendar.ndjson` holds every day from 2019 to 2030 plus 4000 days drawn from 1750-2350:
the Hebrew date, days in the year and month, the kviah, the molad, the holidays in Israel
and the diaspora with and without the modern ones, assur bemelacha, candle lighting, the
parsha and any special parsha, the omer and Chanukah counts, and Daf Yomi Bavli and
Yerushalmi.

`zmanim.ndjson` holds 8 locations - including two far enough north for the sun to misbehave
and two whose longitude is a long way from their meridian - across 3 calculator
configurations and 60 dates, every one of kosher-rust's 167 zman presets.

## What it does not compare

- The 14 presets in `unimplementedZmanim` in `zman_dispatch.dart`, which kosher_dart has
  no counterpart for.
- The zmanim in `deliberatelyDifferent` in `parity.dart`, which answer on a different
  contract: candle lighting, the chametz zmanim, and the Kiddush Levana zmanim.
- Differences of up to `toleranceMillis`, since kosher-rust keeps nanoseconds where
  `DateTime` keeps milliseconds.

## Regenerating the dispatch table

`zman_dispatch.dart` maps each preset's KosherJava method name to the kosher_dart getter.
`gen_dispatch.mjs` writes it from a list of kosher-rust's names, a list of kosher_dart's,
and the alias and unimplemented tables it carries. Regenerate it when either library gains
a zman:

```bash
node tool/parity/gen_dispatch.mjs tool/parity/zman_dispatch.dart
```

It reads `rust_names.txt` and `dart_names.txt` from the working directory, and fails
loudly on any preset it cannot place.
