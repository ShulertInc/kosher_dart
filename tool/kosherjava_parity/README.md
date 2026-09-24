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

Areas: `zmanim`, `calendar`, `tefila`, `formatter`, `geo`, `calculators`, `zmanim-formatter`. A run prints its seed, then
every check that diverged with counts and example inputs. `--case` replays one input. Exit code 1
means something diverged.

Differences of at most 1 ms (instants) or 1e-9 relative (numbers) are listed separately as rounding:
KosherJava keeps nanoseconds, `DateTime` keeps microseconds. Both sides throwing counts as agreement.

## Inputs

- Zmanim: dates 1900-2300, any latitude, longitudes near and far from the zone's meridian, elevation
  0-4000 m, every IANA zone both sides know, all four calculators (NOAA, SunTimes, Meeus, SPA), and random
  calculator settings including Meeus and SPA delta T, pressure and temperature.
- Each Dart zone is rebuilt from java.time's rules for that week, so tz database differences never
  count. How often `package:timezone` itself disagrees is printed as a note.
- Calendar: a day-by-day sweep from 1900, random Gregorian and Jewish dates, and chains of
  arithmetic.
- Machine zone: kosher_dart must not depend on it. Run with `TZ=JST-9` or `TZ=HST10` to check.
- Zmanim formatter: `Double.toString` on random bit patterns, every `ZmanimFormatter` format and
  pattern on random durations, doubles and instants near transitions, the `Zman` comparators on
  random lists, `Zman` and `GeoLocation` XML, and `toXML` / `toJSON` of random calendars of all three
  classes.

`dart run tool/zone_names.dart` regenerates kosher_dart's table of java.time's English zone names.

## Known differences

kosher_dart names the month Marcheshvan / מרחשון where KosherJava says Cheshvan / חשון. KosherJava's output is
mapped to the full name before comparing.

`ZmanimFormatter.toXML` sorts by value and keeps reflection order for ties and missing zmanim, and
`getMethods()` order changes between JVM runs. kosher_dart orders those by name, so KosherJava's
ties are put in name order before comparing. Durations in `toXML` / `toJSON` differ below the
microsecond, so those checks are rounding.

SPA has no sunrise or sunset at a zenith below 0° or above 180°, and its secant search then ends wherever
rounding noise takes it: one ulp of zenith moves the answer by hours. For those zeniths only whether a time
exists is compared.
