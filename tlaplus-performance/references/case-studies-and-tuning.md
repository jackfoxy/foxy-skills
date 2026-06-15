# Performance Case Studies, Harness & Tuning

## Case-study corpus (`general/performance/`)
Real-world spec snapshots used as perf baselines, each typically with `README.md` and a `LINK.md` recording provenance (e.g. `PaxosMadeSimple/LINK.md`: "Copied from https://github.com/nano-o/PaxosMadeSimple"). Credit original authors; these are external snapshots, not project-authored specs.

Directories: `PaxosMadeSimple`, `PaxosCommit`, `Bookkeeper`, `SwarmKit`, `Ghostferry`, `MongoRepl`, `Bloemen`, `EWD840`, `Grid5k` (+ `Grid5k.tla`). Harness: `measure.tla`, `measure.sh`, `measureFPSet.sh`, `csv.sh`, `stats.R`, `stats.tla`.

## Measurement harness
**`measure.tla`** is a TLA+ spec that *orchestrates* a run; CI runs it with TLC and emits `out_run-stats.csv`:
```bash
cd general/performance
java -jar ../../tlatools/org.lamport.tlatools/dist/tla2tools.jar -config measure.tla measure.tla
```
**`measure.sh`** runs a parameterized model (default spec `Grid5k`) with explicit knobs — workers, heap, off-heap memory, FPSet impl:
```bash
# measure.sh K L N C [WORKERS] [HEAP_MEM] [DIRECT_MEM]
./measure.sh 04 01 10 04            # defaults: WORKERS=$(nproc), HEAP=8G, DIRECT=8g
```
Pins `FPSET_IMPL=tlc2.tool.fp.OffHeapDiskFPSet`, records the git rev. `stats.R`/`stats.tla` post-process the CSV.

## CI perf job (`.github/workflows/perf.yml`)
`workflow_dispatch` + monthly cron, JDK 11 on a large ARM runner (720-min timeout): build `tla2tools.jar` → fetch CommunityModules deps → download the previous `perf-results` artifact → run `measure.tla` appending to `out_run-stats.csv` → upload `out_run*` for regression comparison (artifacts expire ≤90 days, so a missing baseline just skips comparison).

## JMH micro-benchmarks
`ant -f customBuild.xml benchmark` builds a self-contained JMH jar (`target/benchmarks.jar`) from `test-benchmark/`; run `java -jar target/benchmarks.jar`. For hot-path Java (value enumeration, fingerprinting), not whole-spec timing.

## Tuning knobs

| Lever | How | Trade-off |
|-------|-----|-----------|
| Parallelism | `-workers N`/`auto` | throughput; near-linear until memory-bound |
| Heap / off-heap | `-Xmx`, `-fpmem`, OffHeap FPSet/StateQueue | fits bigger state spaces |
| Fingerprint bits | `-fpbits`, `-fp N` | fewer hash collisions vs memory |
| `CONSTRAINT` | bound variable ranges in `.cfg` | shrinks space; may hide deep bugs |
| `SYMMETRY` | `Permutations(M)` | collapses equivalent states — **safety only**, unsound with liveness |
| Simulation | `-simulate`, `-depth` | samples huge/infinite spaces; not exhaustive |
| DFID | `-dfid n` | depth-first iterative deepening for deep specs |
