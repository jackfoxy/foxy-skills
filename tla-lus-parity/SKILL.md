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

Current state: **141 rows, 0 owed, 16 approved differences (2026-11-05,
R4.5.2).** R3 closed the ledger at 134 (R3 ACCEPTED on 5/5); R4 widened the
corpus to tlaplus-Examples. Evidence counts: `desk/doc/evidence-counts.md`
(generated; never quote a number from memory).

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

## The sixteen approved differences, in one line each

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
| `tlc-var-order` (R4.2t) | a state's variables print in **declaration** order, not the Hashtable enumeration of SANY's context; verdicts and counts unaffected |
| `tlc-fp-identity` (R4.P5c) | a safety or DFID search keys its visited set on a 128-bit hash of the equality key, so two states whose FP64 fingerprints collide stay apart here (tlc2 merges them); FP64 stays wherever a fingerprint is observable |
| `tlc-module-community` (R4.2b) | CommunityModules operators are native overrides; `SVG!NodeOfRingNetwork`, `SVG!NodesOfDirectedMultiGraph`, `Statistics!ChiSquare`, `VectorClocks!CausalOrder` are refused by name |
| `sem-diag-location` (R4.5.1) | SANY's 4201 Multiply-defined and 4801 messages name the other symbol's location on a second line; the port's message is the first line |
| `sem-inner-module-dump` (R4.5.2) | SemDump nests an inner module's own section in its parent's dump; the port's dump is the parent's alone (dump-only: the inner module's diagnostics are the parent's) |
| `sem-substin-zero` (R4.5.1) | an INSTANCE of a parameterless module dumps `substin subs=0` around each body; SemDump has no SubstIn node (dump-only) |

The sixteen rows are exactly: `tlc-driver`, `tlc-dfid`, `tlc-eval-cst`,
`tlc-value-model`, `cfg-internal-kw`, `tlc-value-order`, `tlc-module-tlc`,
`tlc-module-community`, `tlc-live-product`, `tlc-fp-identity`, `tlc-coverage`,
`tlc-var-order`, `tlc-uniquestring`, `sem-diag-location`, `sem-substin-zero`,
`sem-inner-module-dump`
(`python3 tools/check-parity.py` prints the histogram). The table above
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
