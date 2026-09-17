# KosherJava parity

Calls [KosherJava](https://github.com/KosherJava/zmanim) through JNI and compares it with kosher_dart
on random inputs. Only what both libraries have is compared.

## Setup

Needs a JDK (`JAVA_HOME` or `java` on the path), git, and on Windows gcc (MinGW).

```bash
dart pub get
dart run tool/setup.dart
```

`setup.dart` clones KosherJava at the commit pinned in it, compiles it, generates the bindings with
jnigen, and builds `jni.jar` and the native `dartjni` library. Everything it writes is ignored by git.
On Windows it builds `dartjni.dll` with gcc instead of `jni:setup`, which expects MSVC.

## Running

```bash
dart run bin/parity.dart --seed 2026 --cases 5000
dart run bin/parity.dart --only zmanim --seed 2026 --case 812
```

Areas: `zmanim`, `calendar`, `tefila`, `formatter`, `geo`, `calculators`. A run prints its seed, then
every check that diverged with counts and example inputs. `--case` replays one input. Exit code 1
means something diverged.

Differences of at most 1 ms (instants) or 1e-9 relative (numbers) are listed separately as rounding:
KosherJava keeps nanoseconds, `DateTime` keeps microseconds. Both sides throwing counts as agreement.

## Inputs

- Zmanim: dates 1900-2300, any latitude, longitudes near and far from the zone's meridian, elevation
  0-4000 m, every IANA zone both sides know, both calculators, and random calculator settings.
- Each Dart zone is rebuilt from java.time's rules for that week, so tz database differences never
  count. How often `package:timezone` itself disagrees is printed as a note.
- Calendar: a day-by-day sweep from 1900, random Gregorian and Jewish dates, and chains of
  arithmetic.
- Machine zone: kosher_dart must not depend on it. Run with `TZ=JST-9` or `TZ=HST10` to check.

## Known contract differences

These are counted in notes or left out, not reported as divergences:

- Candle lighting is compared only on Fridays and weekday erev yom tov. kosher_dart answers by the day.
- Chametz zmanim are compared only on 14 Nissan, where KosherJava answers.
- `getFixedLocalChatzosBasedZmanim` keeps the 2.x meaning of negative hours.
