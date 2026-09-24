# Mutation sweep

Measures how much the KosherJava parity harness (`tool/kosherjava_parity`) can see. `mutate.dart` makes one
small change at a time to kosher_dart (flips `<` and `<=`, `&&` and `||`, `+` and `-`, `floor` and `ceil`,
`min` and `max`, bumps a number, and so on), runs the harness areas that cover that file, and records whether
any check diverged. A mutant nobody notices is either a blind spot in the harness or a change that can't
alter any result.

This is not a launch blocker. kosher_dart itself is checked directly by the harness (0 divergences on
millions of random cases), `tool/kosherrust_parity` and `dart test`. The sweep checks the checker.

## Status (2026-09-24)

- 4,044 mutants over the files listed in `mutate.dart`'s `areasByFile`. 1,092 done; the records are in
  `results/` (git-ignored). A rerun skips everything already recorded there.
- The sweep was stopped twice by Claude Code for low system memory (20 and 16 workers). Other programs use
  most of the 63 GB; free memory was around 5 GB with no workers running.
- Found and fixed so far: calendar/location/calculator equality was never compared (added in
  `areas/zmanim.dart`, 4a3aa31); the added-back helpers (`isErevPesach`, `getCandleLightingTonight`, the
  TefilaRules extras) are covered only by `dart test`, which the first pass doesn't run.
- Survivors seen so far that look equivalent: one-sided "argument omitted" branches in `getTemporalHour` /
  `getSunTransit` (no KosherJava call can reach them), sub-millisecond rounding, conditions true at a single
  instant (`currentTime` exactly equal to sunset), `getInstantFromTime`'s day-shift thresholds that only
  matter far from a zone's meridian. The Kiddush Levana day-of-month limits and
  `getSunrise/SunsetSolarDipFromOffset`'s search loop still need the 10x rerun to settle.

## Running

Needs Docker and the `kosherjava-parity-linux` image (`docker build -t kosherjava-parity-linux .` here), and
`tool/kosherjava_parity/build/` from its `tool/setup.dart`.

```sh
sh tool/mutation/sweep.sh 8 300
```

Arguments: workers, cases per mutant. Each worker is capped at 1.2 GB; check free memory before going past 8.
About 50 seconds per mutant per worker.

When the first pass is done, rerun only the survivors at 10x the cases with `dart test` added:

```sh
grep -h '"survived"' tool/mutation/results/mut*.jsonl > tool/mutation/survivors.jsonl
OUT=results-survivors RUN_TESTS=1 sh tool/mutation/sweep.sh 8 3000 /m/survivors.jsonl
```

`OUT` names a separate results folder so the rerun doesn't skip the survivors as already done.

Then read every mutant that still survives and decide: widen the harness input (and prove it catches the
mutant), or write down why it is equivalent.

Files: `run.sh` sets up a worker (copies the repo, builds `libdartjni.so`), `mut.sh` starts `mutate.dart`,
`Dockerfile` is the image, `sweep.sh` launches the workers.
