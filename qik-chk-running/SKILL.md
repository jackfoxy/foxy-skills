---
name: qik-chk-running
description: Run QuickCheck tests and control the runner - quickCheck, quickCheckWith, quickCheckResult, quickCheckWithResult, verboseCheck*, Args and stdArgs (maxSuccess, maxDiscardRatio, maxSize, maxShrinks, chatty, replay), the Result type (Success, GaveUp, Failure, NoExpectedFailure and their fields), isSuccess, recheck and seed replay with mkQCGen, the size schedule, per-property settings (withNumTests, withMaxSuccess deprecation, withDiscardRatio, withMaxSize, withMaxShrinks, mapSize, once), timeouts with within and discardAfter and their real guarantees, laziness and exceptions, withProgress, and Template Haskell runners (quickCheckAll, allProperties, forAllProperties, monomorphic, polyQuickCheck). Use when running properties from GHCi, code, or a main, reproducing a failure, tuning test counts or sizes, interpreting a result value, or adding timeouts.
user-invocable: true
disable-model-invocation: false
---

# Running properties

**Scope:** the runner and its knobs. Test-framework and CI integration is
[qik-chk-workflow](../qik-chk-workflow/SKILL.md); what the output means for
diagnosis is [qik-chk-debugging](../qik-chk-debugging/SKILL.md); the loop's
implementation is [qik-chk-internals](../qik-chk-internals/SKILL.md).

**Prerequisites:** [qik-chk-properties](../qik-chk-properties/SKILL.md).

**Version:** QuickCheck 2.19.0.0 (`src/Test/QuickCheck/Test.hs`, `All.hs`).

## Runners

| Runner | Args | Prints | Returns |
|---|---|---|---|
| `quickCheck p` | `stdArgs` | yes | `()` |
| `quickCheckWith args p` | given | if `chatty` | `()` |
| `quickCheckResult p` | `stdArgs` | yes | `Result` |
| `quickCheckWithResult args p` | given | if `chatty` | `Result` |
| `verboseCheck*` | as above | every test case too | as above |
| `recheck result p` | replay of a `Failure` | yes | `()` |
| `$quickCheckAll` | `stdArgs` | yes | `IO Bool` |

**`quickCheck` never fails the process.** It returns `()` whether the
property passed or not. A `main` that should fail must inspect the result:

```haskell
main = do
  r <- quickCheckResult prop
  unless (isSuccess r) exitFailure
```

or use a test framework ([qik-chk-workflow](../qik-chk-workflow/SKILL.md)).

## Args

`stdArgs` = `Args { replay = Nothing, maxSuccess = 100, maxDiscardRatio =
10, maxSize = 100, chatty = True, maxShrinks = maxBound }` (printed from
GHCi on 2.19).

| Field | Meaning | Per-property equivalent |
|---|---|---|
| `maxSuccess` | passing tests needed | `withNumTests n` (`withMaxSuccess` is deprecated since 2.18) |
| `maxDiscardRatio` | give up when discards reach this many per pass (or per target test) | `withDiscardRatio n` |
| `maxSize` | largest size used | `withMaxSize n` (since 2.15); `mapSize f` transforms sizes |
| `maxShrinks` | total shrink attempts (successful plus failed); 0 turns shrinking off | `withMaxShrinks n` (since 2.15) |
| `chatty` | print output (output is still returned in `output`) | - |
| `replay` | `Just (seed, size)`: start from that seed, first test at that size | `recheck` |

Per-property settings override `Args` and travel with the property, so
they also apply under test frameworks.

## Result

| Constructor | When | Notable fields |
|---|---|---|
| `Success` | enough tests passed | `numTests`, `numDiscarded`, `labels`, `classes`, `tables`, `output` |
| `GaveUp` | too many discards | same as Success |
| `Failure` | a counterexample (or insufficient coverage, or a timeout from `within`) | `reason`, `theException`, `failingTestCase` (printed lines), `usedSeed`, `usedSize`, `numShrinks`, `numShrinkTries`, `numShrinkFinal`, `failingLabels`, `failingClasses`, `witnesses`, `output` |
| `NoExpectedFailure` | an `expectFailure` property passed | same as Success |

`isSuccess` is true only for `Success`. Note that an `expectFailure`
property that failed returns `Success` (it behaved as expected).

## Reproducing a failure

1. Capture `r <- quickCheckWithResult args prop`.
2. Replay: `quickCheckWith args { replay = Just (usedSeed r, usedSize r) }
   (once prop)`, or simply `recheck r prop`. Executed in
   [ReplayAndResults.hs](examples/ReplayAndResults.hs): the replayed
   failing case was identical (`["[10,21]"]`).
3. **For permanence, save the test case, not the seed.** The `replay`
   documentation states that saving a seed from one QuickCheck version and
   replaying it in another is not supported; changing the property or its
   generators also changes what a seed produces. Turn the counterexample
   into an explicit test ([qik-chk-workflow](../qik-chk-workflow/SKILL.md)).
4. A seed can be written with `show` and read back: `QCGen` has `Show` and
   `Read` (`SMGen 9297814886316923340 13679457532755275413`), and `mkQCGen
   :: Int -> QCGen` (in `Test.QuickCheck.Random`) makes one from an `Int`.

## The size schedule

With `maxSuccess = 100` and `maxSize = 100`, test `i` (from 0) runs at size
`i`: 0, 1, ..., 99. When `maxSuccess` is not a multiple of `maxSize`, the
last partial cycle is stretched (the source example: with 250 tests,
0..99, 0..99, then 0, 2, ..., 98). Discards since the last pass add a
little to the size so a run with many discards still grows. `generate`
always uses size 30 and `sample` sizes 0, 2, ..., 20. Details:
[references/size-and-seeds.md](references/size-and-seeds.md).

A bug that only appears above a certain size is found late in a run, or
not at all with a small `maxSize`: in
[DiagnoseRuns.hs](../qik-chk-debugging/examples/DiagnoseRuns.hs) a bug for
lists longer than 60 cannot be found before test 62 (list lengths are at
most the size); recorded runs found it after 64 and 70 tests.

## Timeouts and their guarantees

| Combinator | On timeout | Since |
|---|---|---|
| `within n p` | fail with "Timeout of n microseconds exceeded." | long-standing (duration added to the message in 2.14) |
| `discardAfter n p` | discard the test case | 2.14.3 |

Both use `System.Timeout.timeout` around the test's evaluation, which
interrupts it with an asynchronous exception. **This is not a hard
guarantee:** GHC delivers asynchronous exceptions only at allocation or
yield points, so a tight loop that does not allocate cannot be interrupted.
Measured with GHC 9.10.3: the isolated example
[manual/WithinTightLoop.hs](examples/manual/WithinTightLoop.hs) times out
correctly at `-O0`, hangs at `-O2`, and times out again at
`-O2 -fno-omit-yields`. On compilers without timeout support (`NO_TIMEOUT`)
the combinators do nothing.

Put `within` inside the quantifiers (`prop x = within 100000 ...`) so the
slow input is printed; outside, the variables are not shown. Without a
timeout, a looping property cannot report anything: `verboseCheck` prints
cases only after they finish, and Ctrl-C (not caught since 2.10) aborts
without a counterexample.

## Evaluation and exceptions

A property is evaluated only as far as its result needs, so bottoms in
unused values are not found (`total` forces a value completely).
Synchronous exceptions fail the test and are reported with their message;
`theException` holds the exception. Executed in
[TimeoutsAndEvaluation.hs](examples/TimeoutsAndEvaluation.hs).

## Template Haskell helpers

`Test.QuickCheck.All` (built when the default `templateHaskell` flag is on):

```haskell
{-# LANGUAGE TemplateHaskell #-}
prop_a = ...
prop_b = ...
return []                       -- makes the definitions above visible to TH
runTests :: IO Bool
runTests = $quickCheckAll       -- every prop_* in this file
```

- `$allProperties :: [(String, Property)]` lists them (names include file and
  line); `$forAllProperties runner :: IO Bool` runs them with a custom
  runner, e.g. `quickCheckWithResult args`.
- `$(monomorphic 'prop)` instantiates type variables to `Integer`;
  `$(polyQuickCheck 'prop)` and `$(polyVerboseCheck 'prop)` test the result.
- The discovery reads the source file and looks for lines beginning with
  `prop_`; it errors when used interactively, and warns about names that are
  found in the file but not in scope.

Executed in [AllProperties.hs](examples/AllProperties.hs).

## Progress callbacks

`withProgress f p` (since 2.16) calls `f :: TestProgress -> IO ()` after
every test with `currentPassed`, `currentDiscarded`, `maxTests`,
`currentShrinks`, `currentFailedShrinks`, `currentTotalShrinks`. The
callback runs before the counters are updated for the latest test. It is
intended for downstream tools such as progress bars.

## Pitfalls

- **`quickCheck` returns `()`** whatever happens: use `quickCheckResult`
  and `isSuccess`, or a framework.
- **Seeds are version-bound**: replay across QuickCheck versions or after
  generator changes reproduces nothing useful.
- **`within` is not a hard limit** (non-allocating loops at `-O2`).
- **TH discovery needs `return []`** before the splice and only finds
  top-level `prop_*` names in the same file.
- **`maxSuccess` below `maxSize`** stretches sizes (20 tests use sizes 0,
  5, ..., 95), which changes which bugs are found.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| CI green although a property failed | `quickCheck` in `main` | check `isSuccess` |
| `recheck` shows a different case | different version or code | save the counterexample as a test |
| Run never ends | looping test, no timeout | `within` inside the quantifier; see [qik-chk-debugging](../qik-chk-debugging/references/symptoms.md#hangs-and-loops) |
| `$quickCheckAll` finds nothing / TH error in GHCi | missing `return []`, or interactive use | add `return []`; compile the module |
| More tests than `maxSuccess` ran | `checkCoverage` continues until confident | expected; see [qik-chk-distribution](../qik-chk-distribution/SKILL.md) |

## Executable examples

| File | Shows |
|---|---|
| [ReplayAndResults.hs](examples/ReplayAndResults.hs) | `Result` fields, replay and `recheck`, `withNumTests`, `maxShrinks = 0`, `maxSize`, `maxDiscardRatio` |
| [TimeoutsAndEvaluation.hs](examples/TimeoutsAndEvaluation.hs) | `within`, `discardAfter`, laziness, `total`, exceptions |
| [AllProperties.hs](examples/AllProperties.hs) | `$allProperties`, `$quickCheckAll`, `$(monomorphic ...)` |
| [manual/WithinTightLoop.hs](examples/manual/WithinTightLoop.hs) | not run by the harness: shows `within` failing to interrupt a non-allocating loop at `-O2` |

Run: `qik-chk-workflow/scripts/run-examples.sh qik-chk-running`.

## Go deeper

- [references/size-and-seeds.md](references/size-and-seeds.md): the exact
  size formula, seed splitting, what replay does and does not reproduce.
- [references/result-fields.md](references/result-fields.md): every `Args`
  and `Result` field, output text forms, and runner termination rules.
