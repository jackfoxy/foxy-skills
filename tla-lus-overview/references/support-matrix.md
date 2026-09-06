# Support Matrix — what runs, what is refused

Authoritative sources: `desk/lib/job.hoon` `+validate` (submit-time),
`desk/lib/config.hoon` `+unsupported-kw` (config-time), and
`desk/doc/compatibility.md` §"Typed-rejected / unsupported public options —
summary". The release gate checks the desk and that table against each other in
both directions, so the table cannot drift silently.

## Live capabilities

| Area | Live |
|---|---|
| `%analyze` | `syntax` (mandatory), `semantic`, `level`, `lint` |
| `%check` exhaustive | BFS safety, invariants (ordered), deadlock, `CONSTRAINT`/`ACTION_CONSTRAINT`, symmetry, FP64 state identity, shortest counterexample, out-degree stats |
| `%check` liveness | full normalizer + Manna–Pnueli tableau + product + SCC verdict + lasso trace: `<>P`, `[]<>P`, `[]P`, `~>`, `-+->`, `<>[]`, `WF_`/`SF_` |
| `%check` simulate | seeded random behaviours, `generate=&` (tlc2 `-generate`, probabilistic successor), per-behaviour PROPERTY check, trace-length statistics |
| `%check` dfid | tlc2 `-dfid N`: iterative deepening, EC 2205 level lines, EC 2204/2208 counts |
| Config | `INIT`/`NEXT`, `SPECIFICATION`, `INVARIANT`, `PROPERTY`, `CONSTANT`/`CONSTANTS`, `CONSTRAINT`, `ACTION_CONSTRAINT`, `SYMMETRY`, `VIEW`, `ALIAS`, `POSTCONDITION`, `CHECK_DEADLOCK` |
| Request options | `coverage`, `continue`, `difftrace` (simulate only), `view`, `seed`, `postconditions`, `promote` (`-messagesAsErrors`), `cfg` source override |
| Sources | `%inline` bundles **and** `%clay` bundles (async load, pinned revision, escape-free paths) |
| Output | typed `%report` / `%trace` / `%violations` / `%sources` artifacts; optional Clay **write-back** via `write=(unit write-target)` |
| Standard modules | `Naturals`, `Integers`, `Reals`, `Sequences`, `FiniteSets`, `Bags`, `TLC`, `TLCExt`, `Randomization`, `RealTime`, `Json`, `Toolbox` (vendored MIT text; overrides in `lib/stdops`) |

## Refused at submit (`%rejected`, before a job exists)

| Ask | Message |
|---|---|
| `op = %translate` | `unsupported: PlusCal translation is not ported yet (unit 8)` |
| `check-opts.translate = &` | `unsupported: translate-before-check is not ported yet (unit 8)` |
| `analyze-flags.syntax = \|` | `unsupported: syntactic analysis cannot be skipped; every later stage consumes the tree` |
| `difftrace` outside `%simulate` | `unsupported: -difftrace outside simulation (tlc2 honours it only in -simulate)` |
| `continue` with `%dfid` | `unsupported: -continue with -dfid (the DFID engine records one violation; use exhaustive mode)` |
| `coverage` outside `%exhaustive` | `unsupported: -coverage outside exhaustive mode (the counters live on the safety search)` |
| `coverage` with `SPECIFICATION` | `unsupported: -coverage with a SPECIFICATION (the INIT action has no declaration to label; use INIT/NEXT)` |
| `coverage` with a temporal `PROPERTY` | `unsupported: -coverage with a temporal PROPERTY (the port collects coverage on the safety search only)` |
| `view` with no `VIEW` in the config | `unsupported: -view without a VIEW in the config (nothing to render)` |
| `check-opts.cfg` on a `%clay` bundle | `unsupported: cfg source override on a %clay bundle; select the config with src.cfg (a path)` |
| `check-opts.cfg` naming an absent source | `unknown cfg source: <name>` |
| `%check` with no cfg | `a %check request requires a config` |
| `%clay` with no search root | `a %clay bundle needs at least one module-search root` |
| `%clay` with an empty root name | `empty root module name` |
| `%clay` on an unknown desk / unsettled case | `cannot resolve the Clay revision: unknown desk or unsettled case` |
| `write` target overlapping a search root | `write target <pax> overlaps a module-search root; a run may not write over its own sources` |
| bundle empty / root absent / over `max-modules` / over `max-source` | `empty source bundle`, `root module not in bundle`, `too many modules`, `source exceeds limit` |
| duplicate **active** id | `duplicate active id` (a terminal id may be resubmitted) |
| ship-wide quota | `global limit: too many active jobs` / `global limit: retained artifact bytes; delete a result first` / `global limit: in-flight source bytes` |

## Refused later, as a typed `%failed`

| Ask | Where | Message |
|---|---|---|
| `_PERIODIC` in the config | `%config` | `unsupported: _PERIODIC <name>; tlc2 evaluates it inside the search loop and ENDS the run when it is false, which no completed run here could report` |
| `_RL_REWARD` in the config | `%config` | `unsupported: _RL_REWARD <name>; its only consumer is the reinforcement-learning simulation worker, which this engine does not have` |
| `VIEW` **with** a temporal `PROPERTY` | `%config` | `unsupported: VIEW with a temporal PROPERTY (the liveness graph is not view-keyed; unit 8)` |
| `ALIAS` with a temporal `PROPERTY`, or in simulation | `%config` | `unsupported: ALIAS with a temporal PROPERTY (the lasso trace is not aliased; unit 8)` / `… in simulation mode (the simulated trace is not aliased; unit 9)` |
| `CASE` in the next-state relation under `generate=&` | `%simulate` | `unsupported: probabilistic evaluation of the next-state relation is not implemented for CASE (tlc2 -generate refuses the same way).` — **the pin refuses it too** (`Tool.java:1323`) |
| a temporal formula the normalizer cannot decompose | `%config` | the pin's own `TLC cannot handle the temporal formula …` |
| `TLCSet("exit"…)` / `TLCSet("pause"…)` | evaluation | refused by name — neither is a channel this engine has |
| a genuine temporal `PROPERTY` under `%dfid` | `%dfid` | refused verbatim as at the pin (upstream issue 548). A `[]P` box-state runs — it is an invariant |
| a runaway `RECURSIVE` temporal expansion | `%liveness` | the port's own message naming `+expand-cap` (1.000 nested expansions); tlc2 overflows its stack and reports EC 1005 |

## Deliberately different (approved), not refused

Ten ledger rows are `approved-difference`; each has a differential test pinning
it. The behaviourally visible ones:

- **String and model-value order is lexicographic**, not Java intern order
  (`tlc-value-order`, `tlc-uniquestring`, `tlc-value-model`). Intern order is
  an artifact of the Java toolchain's path — measured, SANY interns 399 strings
  before a 10-line fixture's own lexemes.
- **An unseeded run's default seed is 0**, so runs are reproducible;
  tlc2 draws from `new Random().nextLong()` and never prints it. Comparing
  against the pin needs `-seed N` **and** `-fp 0`.
- **`-terse` has no analogue** — a printed state always shows the enumerated
  form. Rendering only; verdict, counts and trace shape are unaffected.
- **DFID counterexample traces are not compared** to the pin: tlc2 descends
  into a *random* eligible successor from a clock-seeded generator `-seed` does
  not reach (six runs of the same jar gave three different counterexamples).
  Verdict, level lines and counts are byte-exact.
- **Coverage reports five line kinds minus two**: no per-`VARIABLE`
  HyperLogLog estimate, no per-node sub-expression lines, and **no block at all
  on a run that prints a counterexample**. All three are absences declared by
  name, never a different number under the same label.
- **`lib/eval` remains a narrower constant-expression evaluator**, no longer
  backing state generation (`tlc-eval-cst`); the product graph is in-memory
  over `(state-fp, tableau-node-index)` pairs rather than tlc2's disk layout
  (`tlc-live-product`) — performance only.
- **`_PERIODIC` is refused by name** (`cfg-internal-kw`): `doPeriodicWork` runs
  on tlc2's wall-clock thread, so where it fires varies run to run — 1 677 194
  states one run, 1 740 872 the next.

The exact ten rows: `tlc-driver`, `tlc-dfid`, `tlc-eval-cst`,
`tlc-value-model`, `cfg-internal-kw`, `tlc-value-order`, `tlc-module-tlc`,
`tlc-live-product`, `tlc-coverage`, `tlc-uniquestring`. Rows marked ✅ CLOSED
or ⟶ R2 in `compatibility.md`'s matrix are kept as the **record of what the
difference was** — R2 and R3 closed all seven of them, and they are `parity`
now. Two behaviours are pinned by approved-difference **test arms** rather than
by a ledger row: the `+expand-cap` bound on runaway `RECURSIVE` temporal
expansion (`gh1389-loops`, `gh1389-guard`) and `-terse` rendering
(`terse-subset`).

Two further normalizations live in the differential **harness**, not the
engine (`tools/gen-tier2-tests.py`): the generated-state count is dropped, and
each state's bindings are sorted, because tlc2 prints them in
`java.util.Hashtable` bucket order.
