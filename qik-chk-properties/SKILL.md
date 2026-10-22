---
name: qik-chk-properties
description: Express QuickCheck properties with the right combinators - the Testable class and its instances (Bool, Property, (), Maybe, Discard, Gen, functions), explicit quantification (forAll, forAllShrink, forAllShow, forAllBlind and their combinations), implication (preconditions) and discard, equality reporting with === and =/=, conjunction and disjunction (.&&., conjoin, .||., disjoin, Every, Some) versus the random choice .&., failure annotation (counterexample, whenFail, whenFail'), expectFailure, once/again, total, witness, and the Poly types for polymorphic properties. Use when writing or reading property code, when a combinator behaves unexpectedly, or when a failure report needs more information.
user-invocable: true
disable-model-invocation: false
---

# Property combinators

**Scope:** the vocabulary for stating a property and its report. What to
claim is [qik-chk-property-design](../qik-chk-property-design/SKILL.md);
distribution observers (`label`, `classify`, `cover`, ...) are
[qik-chk-distribution](../qik-chk-distribution/SKILL.md); runner controls
(`withNumTests`, `within`, `verbose`) are
[qik-chk-running](../qik-chk-running/SKILL.md); IO is
[qik-chk-monadic-state](../qik-chk-monadic-state/SKILL.md).

**Prerequisites:** [qik-chk-foundations](../qik-chk-foundations/SKILL.md).

**Version:** QuickCheck 2.19.0.0 (`src/Test/QuickCheck/Property.hs`,
`Monoids.hs`, `Poly.hs`).

## What can be a property

`Testable` instances in 2.19: `Bool`, `Property`, `()` (always passes; lets
`IO ()` code become a property via `ioProperty`), `Maybe p` (`Nothing`
discards, since 2.13), `Discard`, `Gen p`, `Result` and `Prop` (internal),
`Every`/`Some`, and functions `a -> p` with `Arbitrary a` and `Show a`.
Everything else is built from `Property`.

Since 2.15 a property without quantification is **no longer** run only
once automatically: `quickCheck True` runs 100 identical tests. Use `once`
for a test that does not quantify over anything.

## Choosing the combinator

| Intent | Write | Not |
|---|---|---|
| Show both sides when an equality fails | `x === y` | `x == y` (prints only "Falsified") |
| Show both sides for inequality | `x =/= y` | `x /= y` |
| All of several claims | `p .&&. q`, `conjoin ps`, `mconcat (map Every ps)` | `p .&. q` |
| One of several claims | `p .||. q`, `disjoin ps`, `mconcat (map Some ps)` | |
| Test one of two claims at random per case | `p .&. q` (labelled LHS/RHS) | |
| Exclude an input | `cond ==> p`, `property Discard`, return `Nothing`, or evaluate `discard` | `if cond then p else True` (counts as a pass) |
| Use a custom generator for one argument | `forAll gen $ \x -> ...` (no shrinking) | |
| ... and shrink it | `forAllShrink gen shr $ \x -> ...` | |
| ... and print it differently or not at all | `forAllShow gen showF`, `forAllBlind gen`, `forAllShrinkShow`, `forAllShrinkBlind` | |
| Explain a failure | `counterexample msg p` | `trace` |
| Run IO after the final failure / after every failure | `whenFail io p` / `whenFail' io p` | |
| Assert that a claim is false | `expectFailure p` | |
| Check a value does not crash when fully evaluated | `total x` (needs `NFData`) | `x == x` |
| Get the counterexample as a Haskell value | `witness x p`, then `castWitness` on `witnesses` of the `Failure` | parsing `failingTestCase` strings |
| Run once / repeatedly | `once p` / `again p` | |

## Semantics that surprise people

- **`.&.` is not conjunction.** Each test case evaluates *one* side, chosen
  at random. For "both must hold" use `.&&.`. Executed in
  [Combinators.hs](examples/Combinators.hs): `(n >= 0) .&. (n <= 0)` fails
  and reports `RHS`.
- **`.||.` and discards.** If the left side is discarded, the whole
  disjunction is discarded and the right side is not evaluated (2.12
  semantics, documented in the source as a deliberate choice).
- **`expectFailure` cannot be nested in `conjoin`/`disjoin`**; it is
  reported as an error ("expectFailure may not occur inside a conjunction").
  A property under `expectFailure` that never fails returns
  `NoExpectedFailure`, and the runner prints
  `*** Failed! Passed 100 tests (expected failure).`
- **`counterexample` text is printed only on failure**, after the
  quantified values, in the order the combinators wrap the property.
- **Exceptions are failures.** An exception while evaluating a property
  (including `error`, pattern-match failure, `div` by zero) fails the test
  and is reported with its message; shrinking then looks for smaller inputs
  that still throw. The exception is in `theException` of the result.
- **Exceptions while showing are reported too.** If printing a
  counterexample itself throws, the report says
  "Exception thrown while showing test case" (seen with `===` on an
  overflowing value in [RegressionCapture.hs](../qik-chk-workflow/examples/RegressionCapture.hs)).
- **`total` uses `rnf`**: it fails on any bottom inside the value, unlike
  `seq`, which only reaches weak head normal form.
- **`witness` needs `Typeable`** (since 2.15); witnesses come back
  outermost first.

## Pitfalls

The surprises above, plus:

- **`&&` versus `.&&.`**: `&&` works only on `Bool`; once a side is a
  `Property` use `.&&.` or `conjoin`.
- **Implication discards.** Every false precondition is a discarded test;
  1000 discards (default ratio) give up.
- **Unquantified properties run 100 times** since 2.15.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Couldn't match type Property with Bool` | `&&`/`||` on properties | `.&&.`, `.||.` |
| Test says `RHS`/`LHS` | `.&.` chose one side | intended? otherwise `.&&.` |
| `expectFailure may not occur inside a conjunction` | `expectFailure` under `conjoin`/`disjoin`/`.&&.` | apply it to the whole property |
| `No instance for (Show ...)` with `===` | `===` prints both sides | derive `Show`, or use `counterexample` with `==` |
| Property passes with `+++ OK, passed 100 tests` but has no arguments | constant property | expected since 2.15; use `once` |

## Polymorphic properties

QuickCheck tests monomorphic properties. For a polymorphic one either
annotate a type, use `Test.QuickCheck.Poly`'s `A`, `B`, `C` (wrappers around
positive `Integer`s with `Eq`, `Show`, `Arbitrary`, `CoArbitrary`) or
`OrdA`, `OrdB`, `OrdC` (also `Ord`, `Num`), or the Template Haskell helpers
`$(monomorphic 'prop)` / `$(polyQuickCheck 'prop)`, which default type
variables to `Integer` ([qik-chk-running](../qik-chk-running/SKILL.md)). In
GHCi an unannotated property defaults to `()` and equality claims
pass vacuously (executed in
[VacuousAndDefaulting.hs](../qik-chk-property-design/examples/VacuousAndDefaulting.hs)).

## Executable example

[Combinators.hs](examples/Combinators.hs): 12 checks covering `===` and
`=/=` output, `conjoin` with named parts, `.||.`, `.&.`, both outcomes of
`expectFailure`, `total` on defined and undefined values, an exception as a
failure, `once`, and retrieving a typed witness from the result. Recorded
fragments:

```text
=== === shows both sides (expect Fail)
*** Failed! Falsified (after 4 tests and 1 shrink):
[0,-1]
[-1,0] /= [0,-1]
=== expectFailure on a true property (expect NoExpected)
*** Failed! Passed 100 tests (expected failure).
=== total exposes a hidden error (expect Fail)
*** Failed! (after 4 tests):
Exception:
  boom
[3]
```

Run: `qik-chk-workflow/scripts/run-examples.sh qik-chk-properties`.

## Go deeper

- [references/combinator-semantics.md](references/combinator-semantics.md):
  definitions, fixities, and the exact discard/exception rules for each
  combinator.
