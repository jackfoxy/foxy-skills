# Symptoms, causes, fixes

Companion to [qik-chk-debugging](../SKILL.md). QuickCheck 2.19.0.0.
"Measured" means run with GHC 9.10.3 for this pack; evidence is listed in
[validation-report.md](../../qik-chk-overview/references/validation-report.md).

## Contents

- [Gave up](#gave-up)
- [Passes but should not](#passes-but-should-not)
- [Flaky or rare failures](#flaky-or-rare-failures)
- [Counterexamples too large](#counterexamples-too-large)
- [Slow runs](#slow-runs)
- [Hangs and loops](#hangs-and-loops)
- [Stack and heap overflow](#stack-and-heap-overflow)
- [Exceptions](#exceptions)
- [Laziness](#laziness)
- [Replay does not reproduce](#replay-does-not-reproduce)
- [Type errors and defaulting](#type-errors-and-defaulting)

## Gave up

`*** Gave up! Passed only K tests; D discarded tests` means
`D div maxDiscardRatio >= max K maxSuccess`: with defaults, 1000 discards.
Discards come from `==>` with a false condition, `discard`, `pre` in
`PropertyM`, `discardAfter` timeouts, and `Nothing`/`Discard` results.

Checks and fixes:

- Measure how often the condition holds: `sample` the generator and count,
  or `classify cond "valid"` without the `==>`.
- Replace the filter with a construction: `OrderedList` instead of
  `sorted xs ==>`, `NonEmpty`, `Positive`, `choose`, `sort <$> arbitrary`.
  Upstream `Merge.hs` gives up after 22 tests on `ordered xs && ordered ys
  ==>` (measured); the pack's
  [FilterVsConstruct.hs](../../qik-chk-generators/examples/FilterVsConstruct.hs)
  compares the approaches.
- Conditions true for small sizes only (sorted long lists) starve as sizes
  grow: the passing tests are all small. `collect (length xs)` shows it.
- Raising `withDiscardRatio` hides the problem and costs time; use it only
  for mild filters.
- `suchThat` never gives up: `suchThatMaybe` tries sizes `n` to `2n`, then
  `suchThat` retries with the size increased by one, forever. A rarely true
  predicate makes generation slow (or endless) instead of reporting
  "Gave up".

## Passes but should not

| Cause | Check | Fix |
|---|---|---|
| Vacuous: most tests discarded or trivial | `classify`, `collect`; "N discarded" in the output | construct valid inputs; `cover` + `checkCoverage` |
| `()` defaulting: a polymorphic property tested at `()` | `verboseCheck` shows `()` or `[(),()]` | annotate (`xs :: [Int]`), `$(monomorphic 'prop)` |
| Tautology: the property compares a thing with itself | read it; mutate the code and see if it fails | compare against an independent model |
| The bug needs inputs the generator cannot make | `labelledExamples`; boundary values | change the generator; explicit cases |
| The bug needs rare inputs (collisions, duplicates, boundaries) | `classify` the rare case | generate related values, small ranges, `frequency` |
| Since 2.15, unquantified properties run 100 times (not once) | output says `passed 100 tests` for a constant | harmless; use `once` for constants |
| Laziness: the wrong part is never evaluated | see [Laziness](#laziness) | force results |

Upstream `Simple.hs` `prop_SimonThompson` passed 100 tests although false
(`x = 0, y = -1, z = 1`), measured: random triples rarely satisfy
`2*x == y + z` without being equal.

## Flaky or rare failures

A failure that appears in one CI run out of many is usually a real bug in
a rare input region, not a test problem.

1. Capture the counterexample from the log; make it an explicit test
   ([qik-chk-workflow](../../qik-chk-workflow/SKILL.md#regression-tests-from-counterexamples)).
2. Ask why it is rare: `classify` the condition it needs. Improve the
   generator so it is common, or add `cover` with `checkCoverage`.
3. Raise `withNumTests` for that property.
4. If replay with the same version does not reproduce it, look for
   nondeterminism: IO, time, global state, concurrency, `unsafePerformIO`,
   hash-table iteration order.

## Counterexamples too large

| Cause | Fix |
|---|---|
| Value from `forAll`, `pick`, `forAllBlind`, or inside `ioProperty`: never shrunk | `forAllShrink gen shrink`, generate outside `ioProperty`, `idempotentIOProperty` if safe |
| Custom type with no `shrink` (default `shrink _ = []`) | `shrink = genericShrink`, or a hand-written shrinker |
| Shrinker preserves an invariant poorly, so most candidates are rejected or invalid | invariant-preserving shrinker ([qik-chk-shrinking](../../qik-chk-shrinking/SKILL.md)) |
| Local minimum: no single shrink step keeps the failure | shrink in larger steps, or pairs of elements; accept and minimise by hand |
| `maxShrinks` reached | larger `withMaxShrinks` |
| `noShrinking` somewhere | remove it |

`verboseShrinking` shows each successful step and helps tell "not
shrinking at all" from "stuck".

## Slow runs

- **Generator size blow-up**: nested lists grow multiplicatively (a
  `[[[Int]]]` averages thousands of elements at large sizes), recursive
  generators without `sized` division explode or fail to terminate. Use
  `scale`, `resize`, `mapSize`, `withMaxSize`.
- **Expensive property**: profile one test; reduce `withNumTests`, or
  bound sizes.
- **Shrinking**: each candidate reruns the property; cyclic shrinkers never
  stop. `withMaxShrinks n` bounds it; `numShrinkTries` in the `Result` shows
  how many candidates were tried.
- **`suchThat` with a rare predicate** retries for a long time.
- **Coverage**: `checkCoverage` with borderline requirements runs
  thousands of tests by design.

## Hangs and loops

- QuickCheck has no default timeout. Put `within micros` inside the
  quantifiers so the input is printed when it fires
  (`prop x = within 100000 (...)`).
- `verboseCheck` prints each case *after* it finishes; a looping test
  shows only the progress line (measured).
- `within` cannot interrupt code that never allocates; GHC with `-O2` can
  compile tight loops that way (measured: hangs at `-O2`, times out at
  `-O0` and with `-fno-omit-yields`). Add fuel to evaluators and
  interpreters instead.
- Ctrl-C cancels testing without a counterexample (asynchronous exceptions
  are not caught since 2.10); interrupted test cases are not shrunk.
- Infinite structures: `show` of an infinite counterexample never ends;
  `===` on infinite lists never ends.

## Stack and heap overflow

`StackOverflow` and `HeapOverflow` are asynchronous exceptions, so the
runner does not catch them: the program aborts with the RTS message and
no counterexample (measured with a non-tail-recursive sum and `+RTS
-K1m`). To find the input: bound sizes (`withMaxSize`), run
`verboseCheck` to see the last passing cases, or catch the overflow
yourself around the code under test. Large generated values with
`maxSize` 100 can also exhaust memory for nested types.

## Exceptions

- A synchronous exception in the property fails the test with
  `*** Failed! (after N tests ...)` then `Exception:` and the message;
  shrinking continues with the exception as the failure.
- `Exception thrown while showing test case:` means `show` of the
  counterexample threw (measured in
  [RegressionCapture.hs](../../qik-chk-workflow/examples/RegressionCapture.hs):
  `===` printed a value whose computation overflowed). The failure itself
  is real; avoid printing partial values, or print a forced summary with
  `counterexample`.
- `error` inside a generator also fails the test with `Exception:`, and,
  because the generated value is the failing thunk, is followed by
  `Exception thrown while showing test case:` with the same message
  (measured). Both messages pointing at a generator line is the tell.
- To *expect* an exception use `assertException`/`assertExceptionIO`
  ([qik-chk-monadic-state](../../qik-chk-monadic-state/SKILL.md)).
- With `-threaded` code and `forkIO`, exceptions in other threads are not
  seen by QuickCheck.

## Laziness

A property is evaluated only to the extent its `Bool` or `Property`
result needs. Bottoms or wrong values in parts not inspected go unseen,
and `===` only forces what `==` inspects. `total x` checks that `x` is
fully defined (needs `NFData`). Lazy exceptions inside a returned result
escape `assertException` (WHNF); use `assertDeepException`. Measured in
[TimeoutsAndEvaluation.hs](../../qik-chk-running/examples/TimeoutsAndEvaluation.hs).

## Replay does not reproduce

Replay (`recheck`, `replay`, `--quickcheck-replay`, hspec `--seed`) is
exact only if all of these are unchanged: QuickCheck version (and the
random/splitmix version), generators, order of quantified arguments,
property code before the failure point, and the absence of IO or global
state influence. Otherwise save the counterexample as a test case. See
[size-and-seeds.md](../../qik-chk-running/references/size-and-seeds.md#what-replay-reproduces).

## Type errors and defaulting

| Error | Meaning |
|---|---|
| `No instance for (Arbitrary T)` | write an instance or use `forAll gen` |
| `No instance for (Show (a -> b))` | quantify over `Fun a b` with `applyFun` or the `Fn` pattern ([qik-chk-functions](../../qik-chk-functions/SKILL.md)) |
| `No instance for (Testable (IO Bool))` | `ioProperty` or `monadicIO` |
| `Ambiguous type variable ... Arbitrary` | annotate; in GHCi defaulting to `()` happens silently instead |
| `Couldn't match Property with Bool` | use `.&&.`/`conjoin` instead of `&&` once one side is a `Property` |
