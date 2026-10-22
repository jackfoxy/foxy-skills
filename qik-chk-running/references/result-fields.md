# Args, Result, and runner termination

Companion to [qik-chk-running](../SKILL.md). Definitions:
`src/Test/QuickCheck/Test.hs` L65 (`Args`), L94 (`Result`), L299 (`test`),
at commit `3d8fe868`.

## Contents

- [Args fields](#args-fields)
- [Result constructors and fields](#result-constructors-and-fields)
- [When the runner stops](#when-the-runner-stops)
- [Output text](#output-text)

## Args fields

| Field | Type | Default | Notes |
|---|---|---|---|
| `replay` | `Maybe (QCGen, Int)` | `Nothing` | seed and start size; not portable across versions |
| `maxSuccess` | `Int` | 100 | passing tests to reach |
| `maxDiscardRatio` | `Int` | 10 | see stopping rules |
| `maxSize` | `Int` | 100 | largest size |
| `chatty` | `Bool` | `True` | `False` prints nothing; output still in `output` |
| `maxShrinks` | `Int` | `maxBound` | successful plus failed shrink attempts; 0 disables |

`Args` derives `Show` and `Read` (and `Typeable`), so arguments can be
stored or passed on a command line.

## Result constructors and fields

| Field | Success | GaveUp | Failure | NoExpectedFailure | Meaning |
|---|---|---|---|---|---|
| `numTests` | yes | yes | yes | yes | passing tests (for Failure: including the failing one) |
| `numDiscarded` | yes | yes | yes | yes | discarded tests |
| `labels` | yes | yes | - | yes | `Map [String] Int`: counts per label combination |
| `classes` | yes | yes | - | yes | `Map String Int` |
| `tables` | yes | yes | - | yes | `Map String (Map String Int)` |
| `output` | yes | yes | yes | yes | everything printed (also when `chatty = False`) |
| `numShrinks` | - | - | yes | - | successful shrink steps |
| `numShrinkTries` | - | - | yes | - | failed shrink attempts, excluding those since the last success |
| `numShrinkFinal` | - | - | yes | - | failed attempts since the last success |
| `usedSeed`, `usedSize` | - | - | yes | - | for replay |
| `reason` | - | - | yes | - | `"Falsified"`, `"Exception: ..."`, `"Timeout of n microseconds exceeded."`, `"Insufficient coverage"`, `"Assertion failed"`, ... |
| `theException` | - | - | yes | - | `Maybe AnException` (`SomeException` on GHC) |
| `failingTestCase` | - | - | yes | - | printed lines of the counterexample (shown values and `counterexample` text) |
| `failingLabels`, `failingClasses` | - | - | yes | - | labels and classes of the failing case |
| `witnesses` | - | - | yes | - | values recorded with `witness` (Typeable compilers) |

Important case: when an `expectFailure` property fails, the runner
returns **`Success`** (`+++ OK, failed as expected.`); when it passes, it
returns `NoExpectedFailure`.

## When the runner stops

`test` checks, before each test (L299):

1. **Finished successfully**: `numSuccessTests >= maxSuccess` (with
   `checkCoverage`: also at a coverage check point and with all
   requirements known to be met).
2. **Insufficient coverage** (only with `checkCoverage`): a requirement is
   known to be unmet at a check point: `Failure` with reason
   "Insufficient coverage".
3. **Too many discards**: `numDiscarded div maxDiscardRatio >= max
   numSuccess maxSuccess` (with ratio 0: any discard): `GaveUp`. With the
   defaults that is 1000 discards (shown as
   `Passed only 0 tests; 1000 discarded tests.`).
4. Otherwise run a test (`runATest`, L415). A failing test starts
   shrinking and ends the run. A test whose result has `abort` set (from
   `once`) ends the run after it: a pass goes to the success report, a
   discard to the give-up report.

Per-property settings (`withNumTests`, `withDiscardRatio`, `withMaxSize`,
`withMaxShrinks`, `expectFailure`, `checkCoverage`) are read from each
test's result and update these limits as the run proceeds.

## Output text

| Text | Meaning |
|---|---|
| `+++ OK, passed 100 tests.` | success |
| `+++ OK, passed 100 tests; 18 discarded.` | success with discards |
| `+++ OK, passed 100 tests (22% non-trivial).` / `:` followed by a table | with classes or labels |
| `*** Failed! Falsified (after 5 tests and 4 shrinks):` | counterexample follows |
| `*** Failed! (after 1 test):` then `Exception:` | the property threw |
| `*** Failed! Timeout of 100000 microseconds exceeded. (after 62 tests and 1 shrink):` | `within` |
| `*** Failed! Insufficient coverage (after 400 tests):` | `checkCoverage` |
| `*** Failed! Assertion failed (after 1 test):` | `assert` in `PropertyM` |
| `*** Gave up! Passed only 77 tests; 1000 discarded tests:` | too many discards |
| `+++ OK, failed as expected. Falsified (...)` | `expectFailure` satisfied |
| `*** Failed! Passed 100 tests (expected failure).` | `expectFailure` violated |

While running, a temporary status line on stderr (only when stderr is a
terminal) shows progress such as `(23 tests)` or the shrinking summary;
it is overwritten by the final message.
