---
name: tlaplus-performance
description: Work with large-scale / real-world TLA+ models and TLC performance measurement - the general/performance case studies (Paxos, Bookkeeper, SwarmKit, ...), the measure.tla/measure.sh harness, the perf.yml regression job, the JMH benchmark target, and state-explosion tuning. Use when scaling TLC, studying perf case studies, or running performance measurements. For routine checking see tlaplus-model-checking.
user-invocable: true
disable-model-invocation: false
---

# TLC Performance & Scaling

Covers `general/performance/` and perf tooling. Routine checking + flags: [[tlaplus-model-checking]]; OOM/explosion diagnosis: [[tlaplus-debugging]].

## Run a measurement (validated harness)
```bash
cd general/performance
# orchestrated run -> out_run-stats.csv (what perf CI runs):
java -jar ../../tlatools/org.lamport.tlatools/dist/tla2tools.jar -config measure.tla measure.tla
# parameterized model with explicit tuning knobs (default spec Grid5k):
./measure.sh 04 01 10 04   # K L N C [WORKERS] [HEAP] [DIRECT]; defaults nproc/8G/8g
```
The case-study corpus (Paxos, Bookkeeper, SwarmKit, Ghostferry, …), the harness files, the perf CI job, the JMH target, and the full tuning table are in `references/case-studies-and-tuning.md`.

## JMH micro-benchmarks
```bash
ant -f customBuild.xml benchmark        # -> target/benchmarks.jar
java -jar target/benchmarks.jar
```
For hot-path Java (value enumeration, fingerprinting), not whole-spec timing.

## Tuning at a glance
`-workers` (throughput), `-Xmx`/`-fpmem` + OffHeap FPSet (capacity), `-fpbits` (collisions vs memory), `CONSTRAINT`/smaller constants (shrink space), `SYMMETRY` (safety only — unsound with liveness), `-simulate`/`-dfid` (sampling/deep). Methodology: snapshot a real spec → choose constants/constraints → measure → tune → compare CSV vs baseline. Details: the reference file.

## Validation
Reproduce one case study's measurement run, capture `out_run-stats.csv`, and explain how a chosen knob (workers/symmetry/constraint) changed the state count or runtime.

## References (local)
- `references/case-studies-and-tuning.md` — corpus, harness, perf CI, JMH, tuning table
- `general/performance/` — case-study dirs (`README.md`, `LINK.md`), `measure.{tla,sh}`, `Grid5k.tla`, `stats.{R,tla}`
- `.github/workflows/perf.yml`, `tlatools/org.lamport.tlatools/customBuild.xml` (`benchmark`), `test-benchmark/`
