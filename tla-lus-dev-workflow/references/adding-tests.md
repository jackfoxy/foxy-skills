# Adding and Maintaining Tests

## The four steps

1. Put the source fixture under the matching `desk/test-data/<stage>/` corpus.
2. Run that stage's generator (or `tools/validate.py`) to capture its golden
   **from the pinned oracle**.
3. Commit the fixture, the golden, and the regenerated shard **together**.
4. Confirm both tier-1 halves are green.

**Never weaken a golden without first proving the Java behaviour from the pin.**
Any intentional divergence goes in `desk/doc/compatibility.md` and gets a ledger
row.

## A case for a randomized operator

`TLC!RandomElement` and the three `Randomization` operators draw from a seeded
generator, so the case needs `desk/test-data/<case>/opts.txt` pinning **both**
`-fp 0` and `-seed N`. `-fp` matters because the per-predecessor reseed is
`state.fingerPrint() ^ seed`; a different fingerprint function is a different
draw sequence.

Three rules this port learned expensively:

- **Use wide seeds.** Measured: seeds 1, 2, 3, 7, 8 and 42 all produce the same
  first draw, because `Random.setSeed` scrambles multiplicatively and the first
  `nextDouble` barely moves. Agreement at a small seed is worth nothing as
  evidence. The corpus uses **12345** and **987654321**.
- **Use a domain big enough to discriminate.** A case drawing from `0..2`
  passed against a *wrong* generator about a third of the time — the wrong
  `nextDouble` still floored to the right index. A scramble bug survived two
  corpus cases for exactly this reason. Draw from ten or more elements.
- **Make the state count depend on the draws.** A graph shaped by a step
  counter reports the same numbers however the draws come out. Shape the guard
  with the drawn value (`1 \notin x`, `x # y`) so a dropped or repeated draw
  changes `generated`/`distinct`/`depth`, or violate an invariant so the trace
  prints the value.

A run whose state graph is **built** from draws (or from the `TLCSet` register)
cannot have its counterexample reliably re-solved by tlc2 — measured,
`tlcext-getandset` reported *"Failed to recover the initial state from its
fingerprint … probably a TLC bug"*. So such a case should either be a clean
`VERDICT ok` run, or violate at the **initial state**, where there is no trace
to re-solve.

## When the oracle is not a function of its input

The pattern to copy is `tools/gen-dfid-tests.py`: it runs the pinned jar **8
times per case** and compares the runs *to each other* before writing a golden.
DFID descends into a random eligible successor from a clock-seeded generator
`-seed` does not reach, so the same jar on the same spec can report different
counterexamples. Where the trace varied it is dropped and the case is marked
`nondeterministic` in its `trace.txt` — a **sticky** marker, so a rare
disagreement cannot un-mark itself later and make the generator irreproducible.
2 of 22 are marked; the other 20 compare byte-for-byte.

**Prove which part is comparable. Do not assert it.**

## Fuzzing

`desk/tests/lib/fuzz.hoon` drives stages with seeded random inputs. `+fz-run`
classifies each case four ways:

| Outcome | Meaning | Verdict |
|---|---|---|
| `%ok` | the stage produced a result | pass |
| `%rejected` | the stage produced a **typed** rejection | pass |
| `%bailed` | the stage crashed (`mule` caught it) | **failure** |
| `%budget` | the stage hit a work cap instead of finishing | **failure** |

`%budget` exists because **`mule` catches a bail but not a loop** — a liveness
build once ran 480 s on a five-state spec. Hoon has no externally imposed
timeout, so each stage adapter must call its stage with the caps that stage
already has (`live-graph-cap`, `+expand-cap`, `fuel:eenv`) and report a cap-hit
as `%budget`. That is a contract on the adapter, enforceable only by writing it
down.

The seed fixes the whole run, so a failure replays exactly and carries its
input.

**When fuzzing finds a crash, do not fix it in place.** In order: reduce the
input by hand; commit it as a fixture in the corpus that **owns the stage** (a
liveness crash in `test-data/liveness`, a config crash in `test-data/cfg-val`),
so the stage's existing generator and comparator pick it up as a permanent
tier-1 case; capture its oracle golden; **only then** fix the port. A fuzz-only
corpus would leave it outside every differential.

## Close-out discipline

A unit runs the shards it touched. That is right, and it is structurally blind
to two things this project has been bitten by:

- **Cross-shard breakage** — a changed arity that another shard also calls
  fails to *build*. Only the full suite sees it.
- **A gate nobody runs** — a stale scaffold-gate clause went red on 2026-08-17
  and stayed red through **nine units**, because none of them ran it. *A gate
  that never runs is not a gate. It is a claim.*

And the sibling lesson: **a gate that fails on purpose stops being read.**
`release-gate.sh` was red by design from R2.0 to R3.0d, and behind the one
clause everybody knew about, two others had rotted unseen — a `TODO` token in a
comment, and **eleven refusals missing from `compatibility.md`'s table**. Read a
red gate's *other* clauses, every time.

So a close-out runs, in this order:

| | Command | Proves |
|---|---|---|
| tier 1 | `python3 tools/validate.py --check` | every golden reproduces from the pin |
| tier 2 | `python3 tools/tier2.py --check` | inventory + curated oracle + comparators reproduce |
| ledger | `python3 tools/check-parity.py` | well-formed, and what is owed |
| gate | `bash tools/scaffold-gate.sh` | scaffold hygiene (11 gates) |
| release | `bash tools/release-gate.sh` | the real gate |
| acceptance | `python3 tools/r3-acceptance.py --suite-log <output>` | the acceptance sentence, computed |
| suite | `-test /=tla-lus=/tests ~` | `ok=%.y` — the only thing that sees cross-shard breakage |

The suite clause is **evidence the caller supplies**; omitting `--suite-log`
FAILS the clause rather than skipping it.

## Reading a `-test` verdict from the ship

A trap hit four times: `tmux capture-pane -S -N | grep FAILED` spans **several
runs**, and every stale hit looks exactly like a live one — roughly half an hour
lost per occurrence chasing an already-fixed failure. Anchor the read to the
current run: slice the scrollback between the **previous** `ok=%` line and the
last one, and report only what falls inside. The dojo prints its command echo at
the **end** of a run, so anchoring on the echo alone selects the wrong block.

## One more, from R1.8.8

**A projection that does not look at something cannot report it as agreeing.**
A tier-2 comparator captured trace lines only *after* the two counter-example
markers — and an initial-state violation prints neither, so a spec agreed on
`[verdict, counts, depth]` and disagreed on every line beneath, invisibly. When
a differential passes, it is worth knowing whether that is a measured agreement
or an unexamined one.
