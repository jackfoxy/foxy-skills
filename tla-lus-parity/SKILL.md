---
name: tla-lus-parity
description: The differential-parity discipline behind %tla-lus - the pinned Java oracle (tla2tools.jar at tlaplus@4ba7d8811), how goldens are built and normalized, the machine-checked parity ledger and its statuses, and every approved difference with its evidence. Use when judging whether a divergence from the Java tools is a bug or a documented decision, when adding or changing a ledger row, or when regenerating goldens.
user-invocable: true
disable-model-invocation: false
---

# Parity, the Oracle, and the Ledger

`%tla-lus` is validated by **differential testing** against the Java TLA+
toolchain at a pinned commit: every Hoon component is compared, output for
output, with the corresponding Java tool.

- The pins, the jar build, invocation forms, dumpers, normalization rules →
  [references/oracle-and-goldens.md](references/oracle-and-goldens.md)
- Ledger statuses, what a row claims, the history and its lessons →
  [references/ledger-discipline.md](references/ledger-discipline.md)
- The full argument for each difference → `desk/doc/compatibility.md`
- Running any of it → `tla-lus-dev-workflow`

## The rule

**Never weaken a golden without first proving the Java behaviour from the pin.**
Any intentional divergence is recorded in `desk/doc/compatibility.md`, carries a
ledger row, and is pinned by a test that fails if *either* side changes.

Current state: **134 rows, 0 owed — closed 2026-09-05 by R3.0d.**
`release-gate.sh` PASSES every clause; `r3-acceptance.py --suite-log` prints
**R3 ACCEPTED** on 5/5 (2179 suite arms, 0 failed). Evidence: **1277 compared
cases, 22 oracle-only** (`desk/doc/evidence-counts.md`, generated).

## Is this divergence a bug?

Ask in this order:

1. **Is it in `compatibility.md`'s support matrix?** Ten rows are
   `approved-difference`. If it is there, it is a decision with evidence.
2. **Is it in the typed-rejection table?** Then it is a refusal by name, not a
   divergence — and the release gate checks that table against the desk in both
   directions.
3. **Did you reproduce the Java side at the pin, with `-workers 1 -fp 0` and an
   explicit `-seed`?** Most reported divergences are unpinned flags.
4. **Is the Java side even a function of its input?** DFID counterexamples,
   `_PERIODIC`, `TLCGet("duration")`, unseeded RNG and trace-explorer module
   names are all wall-clock or clock-seeded: the same jar on the same spec
   disagrees with itself, so no port can match and no oracle can define
   matching.

Only then is it a bug.

## The ten approved differences, in one line each

| Row | Difference |
|---|---|
| `tlc-value-order`, `tlc-uniquestring` | strings order **lexicographically**, not by Java intern position — measured, SANY interns 399 strings before a 10-line fixture's own lexemes |
| `tlc-value-model` | model values order lexicographically and fingerprint their **name**, not the `UniqueString` token. Injective, not byte-identical |
| `tlc-module-tlc` | some `TLC` argument-error text is normalized where the pin names a Java signature; `TLCSet("exit"/"pause", …)` refused by name; **and** an unseeded run's seed is 0 here, unrecoverable there |
| `tlc-eval-cst` | `lib/eval` stays a narrower constant evaluator, no longer backing state generation — it owns the canonical `value` mold |
| `tlc-eval-node` | every **value** agrees; only tlc2's lazy-set *class* column can differ (`Reducible` has exactly two implementors) |
| `tlc-driver` | `-terse` has no analogue (it is per-Value-class, not a switch); `-simulate stats=basic/full` writes no `_actions.dot` |
| `tlc-live-product` | the product graph is in memory over `(state-fp, tableau-node)` pairs, not tlc2's disk layout — performance only |
| `tlc-dfid` | DFID counterexample traces are not compared: tlc2 descends at random from a clock-seeded generator `-seed` does not reach (six runs, three different counterexamples) |
| `tlc-coverage` | five line kinds minus two — no per-`VARIABLE` HyperLogLog estimate, no per-node sub-expression lines, and **no block at all** on a run that prints a counterexample |
| `cfg-internal-kw` | `_PERIODIC` refused by name: `doPeriodicWork` runs on tlc2's wall-clock thread (1 677 194 states one run, 1 740 872 the next) |
| `tlc-value-order`, `tlc-uniquestring` | (cause) no intern table exists; strings are atoms |

The ten rows are exactly: `tlc-driver`, `tlc-dfid`, `tlc-eval-cst`,
`tlc-value-model`, `cfg-internal-kw`, `tlc-value-order`, `tlc-module-tlc`,
`tlc-live-product`, `tlc-coverage`, `tlc-uniquestring`. The table above
collapses `tlc-value-order` and `tlc-uniquestring` into one line (cause and
effect) and splits `tlc-module-tlc`'s two clauses.

`compatibility.md`'s matrix also carries rows marked ✅ **CLOSED** or ⟶ **R2**.
Those are **the record of what a difference was**, not a claim that it still
exists — R2 and R3 closed all seven, and their ledger status is `parity`. Two
behaviours are pinned by approved-difference **test arms** rather than a ledger
row: the `+expand-cap` bound on runaway `RECURSIVE` temporal expansion
(`gh1389-loops`, `gh1389-guard` — tlc2 overflows its stack, EC 1005, so neither
side produces a verdict) and `-terse` rendering (`terse-subset`).

## How to keep it honest

- **Measure the pin before changing the Hoon.** A flag whose recorded effect
  was backwards, a "timing" difference that was really a verdict difference, a
  "missing recursion" that had shipped two releases earlier — all three were
  found by measuring what the document already claimed.
- **New corpora find new rows.** Three rows re-opened the first time
  `tlaplus-Examples` specs ran through the Hoon checker.
- **Know why a differential passed.** A rendering differential cannot see an
  equality; a comparator that reads trace lines only after the counter-example
  markers cannot see an initial-state violation.
