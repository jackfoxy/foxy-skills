---
name: qik-chk-distribution
description: Observe and enforce what QuickCheck actually tested - label, collect, classify and tabulate for reporting test case distribution, cover and coverTable for coverage requirements, checkCoverage and checkCoverageWith (Confidence, certainty, tolerance) for statistically sound coverage checks, the output tables they print, and labelledExamples for finding one minimal example per class. Use when a passing property might be testing only trivial inputs, when someone asks what share of tests hit a case, when coverage warnings appear, or when tests must fail if the data distribution is inadequate.
user-invocable: true
disable-model-invocation: false
---

# Test-data distribution and coverage

**Scope:** measuring and asserting the distribution of inputs that
passed. Changing the distribution is
[qik-chk-generators](../qik-chk-generators/SKILL.md); deciding what to
claim is [qik-chk-property-design](../qik-chk-property-design/SKILL.md).

**Prerequisites:** [qik-chk-properties](../qik-chk-properties/SKILL.md).

**Version:** QuickCheck 2.19.0.0. The label/cover family was overhauled in
2.12 (argument order of `cover` swapped, `checkCoverage`, `tabulate`,
`coverTable` added); older tutorials use the pre-2.12 forms.

## Why it matters

"If test data is not well distributed then conclusions drawn from the test
results may be invalid" (Chalmers manual, *Observing Test Case
Distribution*). The original `prop_Insert` passed while testing mostly
empty and one-element lists (2000 paper, section 2.4). Observers do not
change the verdict; requirements under `checkCoverage` do.

## The combinators

| Combinator | Records | Output |
|---|---|---|
| `label s p` | one string per test | a frequency table per `label` call |
| `collect x p` | `label (show x)` | same |
| `classify b s p` | whether the test is in class `s` | percentages of tests in each class |
| `tabulate name vs p` | several values per test into table `name` | a table with "(N in total)" and per-value percentages of all collected values |
| `cover pct b s p` | `classify` plus a requirement: at least `pct`% of passing tests in class `s` | a warning `Only 75% longer than 5, but expected 90%` |
| `coverTable name [(v, pct)] p` | requirement on values of a `tabulate` table | warning `Table 'signs' had only 18.0% ...` |
| `checkCoverage p` | turns all requirements into a statistical test that can **fail** | `*** Failed! Insufficient coverage (after 400 tests)` |
| `checkCoverageWith conf p` | as above with a custom `Confidence` | |
| `labelledExamples p` | runs `p`, and for every label or class finds and shrinks one example | `*** Found example of <label>` then the example |

Discarded tests contribute to none of these.

## Procedure: make sure a property tests what you think

1. **Classify the interesting cases** of the property's input: empty versus
   non-empty, key present versus absent, boundary values, each constructor.
2. **Run it and read the table.** Rare classes (under a few percent) are a
   generator problem.
3. **Turn expectations into requirements** with `cover` (per class) or
   `coverTable` (per value), choosing modest percentages that a correct
   generator easily exceeds.
4. **Wrap the property in `checkCoverage`** so CI fails when the
   distribution regresses. Expect it to run more tests: it continues until it
   is confident, checking at 100, 200, 400, 800, ... passing tests.
5. **Use `labelledExamples`** to see a concrete, shrunk example of each
   class, which is often the quickest way to see whether a class means what
   you intended.

## How checkCoverage decides

Requirements are checked with a Wilson score confidence interval
([Test.hs L666](https://github.com/nick8325/quickcheck/blob/3d8fe8686024760006ca1ca656cbdd82cd71f11e/src/Test/QuickCheck/Test.hs#L666)):

- it **passes** once, with the configured certainty, the true proportion is
  at least `tolerance` (default 0.9) times the requirement;
- it **fails** once it is confident the proportion is below the
  requirement;
- otherwise it keeps testing. Checks happen when the normal test count is
  reached and at test counts 100 times a power of two.

`stdConfidence = Confidence { certainty = 10^9, tolerance = 0.9 }`.
`certainty` is the inverse false-positive rate per check: the source
advises at least `100 * m * n` for a 1% lifetime chance of a false alarm in
a suite with `m` coverage requirements run `n` times. Lowering certainty or
tolerance makes checks faster and less strict. Details:
[references/coverage-statistics.md](references/coverage-statistics.md).

Without `checkCoverage`, `cover` uses no statistics: it warns whenever the
observed percentage is below the requirement, even if that was bad luck.

## Pitfalls

- **Requirements that the default generator cannot meet.** Default lists are
  empty only about 5% of the time (lengths are uniform in `0..size` with
  size 0..99), so `cover 10 (null xs) "empty"` fails under `checkCoverage`
  even though the generator is fine (measured: 5.22% after 3200 tests).
  Executed in [Coverage.hs](examples/Coverage.hs).
- **Labels are per call.** Two `label` calls produce two tables; one
  `label` with a combined string produces one table of combinations.
  `tabulate` is for several values per test.
- **Preconditions and coverage interact.** Coverage counts only passing
  tests, so a precondition that discards a class silently removes it from
  the table.
- **`checkCoverage` with `withNumTests`.** Fixed in 2.15: earlier versions
  ignored `withMaxSuccess` under `checkCoverage`.
- **Old argument order.** Before 2.12, `cover` took the condition first:
  `cover b pct s`. Since 2.12: `cover pct b s`, matching `classify b s` with
  the percentage in front.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Only 5% empty, but expected 10%` warning | requirement above the generator's rate | lower the requirement or change the generator |
| `Insufficient coverage` in CI only sometimes | without `checkCoverage` the check is plain sampling; with it, false failures are at most 1 in `certainty` | use `checkCoverage`; raise `certainty` |
| Run takes thousands of tests | borderline requirement under `checkCoverage` | lower `tolerance`, or make the requirement clearly met or clearly not |
| Labels missing from the table | the tests were discarded | coverage counts passing tests only |

## Executable example

[Coverage.hs](examples/Coverage.hs) runs `labelledExamples` on the
documentation's `delete` property, then `classify`, `tabulate`, a `cover`
that only warns, a `checkCoverage` requirement that fails (90% of lists
longer than 5), one that passes after 3200 tests (3% empty), and a
`coverTable`. Recorded fragments:

```text
=== checkCoverage fails an unmet requirement (expect Fail)
*** Failed! Insufficient coverage (after 400 tests):
76.0% longer than 5

Only 76.0% longer than 5, but expected 90.0%
=== checkCoverage accepts a met requirement (expect Pass)
+++ OK, passed 3200 tests (5.12% empty).
```

Run: `qik-chk-workflow/scripts/run-examples.sh qik-chk-distribution`.

## Go deeper

- [references/coverage-statistics.md](references/coverage-statistics.md):
  the statistics, output formats, and the `Result` fields that carry the
  collected data.
