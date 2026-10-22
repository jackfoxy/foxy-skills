---
name: qik-chk-debugging
description: Diagnose QuickCheck runs that misbehave - "Gave up!" and too many discards, properties that pass vacuously or test only trivial data, () type defaulting, skewed distributions, rare or flaky failures, counterexamples that are huge or not minimal, slow generators or shrinking, hangs and loops (within, verboseCheck, Ctrl-C), stack overflows and memory blow-ups, laziness hiding bottoms, exceptions while showing a test case, and failures that do not replay. Use whenever a QuickCheck result is surprising, a property passes but should not, a run never finishes, a failure cannot be reproduced, or someone pastes QuickCheck output and asks what it means.
user-invocable: true
disable-model-invocation: false
---

# Debugging QuickCheck runs

**Scope:** symptom to cause to fix. The tools themselves are documented
in [qik-chk-running](../qik-chk-running/SKILL.md) (runner, output),
[qik-chk-distribution](../qik-chk-distribution/SKILL.md) (labels,
coverage), [qik-chk-shrinking](../qik-chk-shrinking/SKILL.md) (shrink
search).

**Prerequisites:** [qik-chk-properties](../qik-chk-properties/SKILL.md),
[qik-chk-running](../qik-chk-running/SKILL.md).

**Version:** QuickCheck 2.19.0.0; behaviours marked *measured* were run
with GHC 9.10.3.

## First moves

1. **Read the whole message.** The first line says what kind of result it
   is ([output forms](../qik-chk-running/references/result-fields.md#output-text)).
2. **Watch it run.** `verboseCheck` (or `verbose p`) prints every test
   case; `verboseShrinking p` prints every failing shrink candidate.
3. **Look at the data.** `sample (arbitrary :: Gen T)`, then
   `collect`/`classify`/`tabulate` inside the property.
4. **Reproduce.** `recheck r p`, or `replay = Just (usedSeed r, usedSize r)`,
   with the same code and QuickCheck version.
5. **Minimise further by hand** if the shrinker stops early: try the
   failing case with parts removed in GHCi.

## Symptom table

| Symptom | Likely cause | Fix | Detail |
|---|---|---|---|
| `*** Gave up! Passed only K tests; 1000 discarded tests` | `==>` precondition rarely true | generate valid inputs (modifiers, `suchThat` for mild filters, constructive generators) | [gave up](references/symptoms.md#gave-up) |
| `+++ OK` but the property is wrong | vacuous: precondition or `classify` shows trivial cases; `()` defaulting; generator never reaches the bug | `classify`, `cover` + `checkCoverage`, annotate types, seed a bug | [passes wrongly](references/symptoms.md#passes-but-should-not) |
| Fails only sometimes in CI | rare inputs found by chance, or nondeterminism | save the counterexample; raise `withNumTests`; improve the generator; check for IO state | [flaky](references/symptoms.md#flaky-or-rare-failures) |
| Huge counterexample | no shrinker (`forAll`, `pick`, `ioProperty`, custom type without `shrink`), or shrinking stopped | `forAllShrink`, define `shrink`, `genericShrink` | [shrinking](references/symptoms.md#counterexamples-too-large) |
| Shrinking takes forever | shrinker cycles, too many candidates, or each candidate is slow | `withMaxShrinks`, fix cycles, shrink to fewer candidates | [slow](references/symptoms.md#slow-runs) |
| Run never ends | a test loops; huge sizes; nested structures exploding | `within` inside the quantifiers, `mapSize`/`withMaxSize`, check sized recursion | [hangs](references/symptoms.md#hangs-and-loops) |
| `Stack space overflow` and the run aborts | deep recursion in property or generator; asynchronous exceptions are not caught | increase stack or fix recursion; find the input by bounding size | [crashes](references/symptoms.md#stack-and-heap-overflow) |
| `Exception thrown while showing test case` | the counterexample's `show` throws (often an exception value inside it) | force or avoid partial values in shown data | [exceptions](references/symptoms.md#exceptions) |
| A bug in an unused field is never found | laziness: the property never forces it | `total`, `===` on forced values, `deepseq` | [laziness](references/symptoms.md#laziness) |
| Replay shows a different case | different QuickCheck version, changed generators or argument order, IO dependence | save test cases, not seeds | [replay](references/symptoms.md#replay-does-not-reproduce) |
| `Insufficient coverage` | requirement above what the generator produces, or borderline | lower the requirement or fix the generator | [qik-chk-distribution](../qik-chk-distribution/SKILL.md) |

## Measured behaviours worth knowing

- **verboseCheck does not show a looping input.** It prints each case after
  its test finishes; a test that never finishes leaves only the progress
  line `(7 tests)` (measured with a property that loops for `n > 5`).
  Use `within` inside the quantifiers so the input is printed on timeout.
- **A stack overflow aborts the whole run.** `StackOverflow` is an
  asynchronous exception, which QuickCheck does not catch (since 2.10, so
  that Ctrl-C works); the program died with `Stack space overflow` and no
  counterexample or `Result` (measured, `+RTS -K1m`).
- **`forAll` does not shrink.** In
  [DiagnoseRuns.hs](examples/DiagnoseRuns.hs) the colliding keys failed
  "after 10 tests" with no shrinks at all; `forAllShrink gen shrink` or an
  `Arbitrary` instance would shrink them.
- **Defaults rarely collide.** Two independent default `String`s were equal
  in 1-2% of tests, and only when short: generate related values to test
  collisions.
- **Late bugs.** A bug for lists longer than 60 cannot be found before test
  62, because list length is bounded by the size.

## Executable example

[DiagnoseRuns.hs](examples/DiagnoseRuns.hs): `verbose`, `verboseShrinking`
(seeded, shrink path `[0,3,8,-8,7,1,7,6,6]` to `[4,6]`), a long-input bug
with `collect`, default versus related key generation. Run:
`qik-chk-workflow/scripts/run-examples.sh qik-chk-debugging`. Related
diagnostic examples elsewhere:
[VacuousAndDefaulting.hs](../qik-chk-property-design/examples/VacuousAndDefaulting.hs),
[FilterVsConstruct.hs](../qik-chk-generators/examples/FilterVsConstruct.hs),
[ShrinkTraps.hs](../qik-chk-shrinking/examples/ShrinkTraps.hs),
[TimeoutsAndEvaluation.hs](../qik-chk-running/examples/TimeoutsAndEvaluation.hs).

## Go deeper

- [references/symptoms.md](references/symptoms.md): each symptom with
  causes, checks, and fixes.
