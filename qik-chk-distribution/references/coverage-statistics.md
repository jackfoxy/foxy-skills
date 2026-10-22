# Coverage statistics and reporting (QuickCheck 2.19)

Companion to [qik-chk-distribution](../SKILL.md). Code references are to
`src/Test/QuickCheck/Test.hs` and `Property.hs` at commit `3d8fe868`.

## Contents

- [What is collected](#what-is-collected)
- [When coverage is checked](#when-coverage-is-checked)
- [The decision rule](#the-decision-rule)
- [Choosing Confidence](#choosing-confidence)
- [Output formats](#output-formats)
- [Result fields](#result-fields)
- [labelledExamples](#labelledexamples)

## What is collected

Each passing test's per-test result carries `labels` (strings from
`label`/`collect`), `classes` (`(name, Bool)` from `classify`/`cover`),
`tables` (`(table, value)` pairs from `tabulate`), and `requiredCoverage`
(`(Maybe table, value, proportion)` from `cover`/`coverTable`). The runner
accumulates them in its state for passing tests only (`runATest`,
L415); discarded tests do not add coverage.

## When coverage is checked

Only when `checkCoverage` is active (`timeToCheckCoverage`, L330):

- when the number of passing tests equals the configured count and the
  last test was not discarded; and
- at every passing-test count `100 * 2^k` (100, 200, 400, 800, ...).

At each check, testing stops with success if every requirement is known to
be sufficient and at least the configured number of tests ran, stops with
failure ("Insufficient coverage") if any requirement is known to be
insufficient, and continues otherwise. This is why a borderline
requirement can run thousands of tests (3200 in the pack's example).

## The decision rule

For a requirement with proportion `p`, `k` hits in `n` relevant tests:

- **sufficient** if the lower bound of the Wilson score interval at
  significance `1 / certainty` is at least `tolerance * p`;
- **insufficient** if the upper bound is below `p`.

The implementation computes the inverse normal CDF itself (Acklam's
algorithm, accurate to about one part in 10^9) rather than depending on the
`erf` package (removed in 2.13). A source comment notes that a one-sided
test might use `a` instead of `a/2`, so the bounds are somewhat
conservative.

For `cover`, `n` is the number of passing tests; for `coverTable`, `n` is the
number of values collected into that table.

Without `checkCoverage`, the warning test is simply `k < p * n`.

## Choosing Confidence

```haskell
data Confidence = Confidence { certainty :: Integer, tolerance :: Double }
stdConfidence = Confidence { certainty = 10^9, tolerance = 0.9 }
```

From the field documentation: with certainty `n`, a requirement that is
actually met causes a false failure at most once in `n` runs. For a suite
with `m` calls to `cover` that will be run `n` times over a project's
lifetime, use at least `100 * m * n` for a 1% lifetime false-alarm chance.
Lower `tolerance` accepts larger shortfalls and speeds testing up; higher
values (up to 1) make borderline requirements run longer.

```haskell
quickCheck (checkCoverageWith stdConfidence { certainty = 10^6 } prop)
```

## Output formats

```text
+++ OK, passed 100 tests (22% non-trivial).        -- one class
+++ OK, passed 100 tests:                          -- several classes or labels
61% long
 5% empty

signs (2513 in total):                             -- a tabulate table
50.62% neg
48.23% pos

Only 75% longer than 5, but expected 90%           -- cover warning
Table 'signs' had only 18.0% LogOut, but expected 25.0%   -- coverTable warning
*** Failed! Insufficient coverage (after 400 tests):      -- checkCoverage failure
```

Tables are sorted by descending frequency, ties by key. Classes that are
never hit are shown as 0% (fixed in 2.15).

## Result fields

`Success`, `GaveUp` and `NoExpectedFailure` carry `labels :: Map [String]
Int` (counts per combination of labels), `classes :: Map String Int`, and
`tables :: Map String (Map String Int)`. `Failure` carries the failing
case's `failingLabels` and `failingClasses`. Programmatic coverage checks
can read these from `quickCheckResult`.

## labelledExamples

`labelledExamples prop` (`Features.hs` L76, since 2.12) repeatedly runs
`prop` under a wrapper that fails as soon as a test has a label or class
not seen before ("New feature found"). Each such failure is shrunk, giving
a small example of the new label, which is printed as
`*** Found example of <labels>`. The seed and size of each find are replayed
for the next round. When no new label appears in a full run, it prints the
normal summary. Variants: `labelledExamplesWith args`,
`labelledExamplesResult`, `labelledExamplesWithResult`. Since 2.16 the
implementation no longer depends on the internal test loop.
