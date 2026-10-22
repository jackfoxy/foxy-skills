# Combinator semantics (QuickCheck 2.19)

Companion to [qik-chk-properties](../SKILL.md). Line numbers refer to
`src/Test/QuickCheck/Property.hs` at commit `3d8fe868` unless noted.

## Contents

- [Fixities](#fixities)
- [Testable instances](#testable-instances)
- [Quantifiers](#quantifiers)
- [Discarding](#discarding)
- [Equality](#equality)
- [Conjunction, disjunction, choice](#conjunction-disjunction-choice)
- [Failure reporting](#failure-reporting)
- [Exceptions](#exceptions)
- [Per-test result fields](#per-test-result-fields)

## Fixities

```haskell
infixr 0 ==>
infixr 1 .&., .&&., .||.
infix  4 ===, =/=
```

So `a ==> b .&&. c` parses as `a ==> (b .&&. c)`, and `$` chains of
modifiers (`counterexample s $ classify c l $ p`) wrap from the outside in.

## Testable instances

| Type | Behaviour |
|---|---|
| `Bool` | `True` passes; `False` fails with reason "Falsified" |
| `()` | always passes (the unit is forced, so an exception in it fails) |
| `Maybe p` | `Nothing` discards; `Just p` tests `p` (since 2.13) |
| `Discard` | discards |
| `Gen p` | generate a `p`, then test it |
| `Property` | itself (with an exception handler installed) |
| `a -> p` | generate `a` with `arbitrary`, shrink with `shrink`, show with `show`; multi-argument functions generate and shrink their arguments as one tuple |
| `Every`, `Some` | the wrapped property (see below) |
| `Result`, `Prop` | internal per-test results |

Verified: `quickCheck True` runs 100 tests, `quickCheck (once True)` runs
one, `property Discard` and `Nothing` give up after 1000 discards (the
default discard ratio 10 times 100 tests).

## Quantifiers

All are defined in terms of `forAllShrinkBlind gen shr pf` (L942), which
generates `x`, then builds the shrink tree with `shrinking shr x pf`.

| Combinator | Generator | Shrinker | Printed as |
|---|---|---|---|
| `forAll` | given | none | `show` |
| `forAllShrink` | given | given | `show` |
| `forAllShow` | given | none | given function |
| `forAllShrinkShow` | given | given | given function |
| `forAllBlind` | given | none | not printed |
| `forAllShrinkBlind` | given | given | not printed |
| function argument | `arbitrary` | `shrink` | `show` |

(The 2.9 changelog says non-exhaustive combinators such as `forAll` call
`again`; the 2.19 definitions no longer do, and since 2.15 an unquantified
property is not implicitly run once, so `again` only matters to undo an
explicit `once`.)

## Discarding

| Mechanism | Where it works |
|---|---|
| `cond ==> p` (L867) | property level; `False ==> _ = property Discard` |
| `property Discard`, `Nothing` | property level |
| `discard :: a` | anywhere, including inside generators: it is a special exception value that the runner recognises (`Exception.hs` L96) |
| `pre cond` | inside `PropertyM` ([qik-chk-monadic-state](../../qik-chk-monadic-state/SKILL.md)) |
| `discardAfter n` | discards a test that takes more than n microseconds |

Discarded tests do not count towards `maxSuccess`, do not contribute to
coverage, and count against the discard ratio. During shrinking, a
discarded candidate counts as a failed shrink attempt. `sample` prints
`<DISCARDED>` for a value whose generation discards (since 2.15 the internal
exception no longer leaks there).

## Equality

`x === y` builds `counterexample (show x ++ " == " / " /= " ++ show y) (x
== y)` (L1074); `=/=` is the mirror image (since 2.12). Both need `Eq` and
`Show`. The message is printed only on failure. Because it calls `show`, a
value that throws when shown produces "Exception thrown while showing test
case".

## Conjunction, disjunction, choice

- `p .&&. q = conjoin [p, q]`. `conjoin` (L967) runs the properties in
  order, stops at the first failure, keeps labels, classes, tables and
  coverage from the passing parts, and reports a discard if a part is
  discarded and the rest pass.
- `p .||. q = disjoin [p, q]` (L1005). Fails only if all parts fail; then the
  reasons are joined with ", " and all counterexamples are shown. A
  discarded left side makes the whole disjunction discarded without
  evaluating the right side (comment in the source explains why this is
  cheaper and still sound).
- `p .&. q`: a random `Bool` chooses one side per test case, and
  `counterexample "LHS"`/`"RHS"` records which.
- `Every` / `Some` (`Monoids.hs`, since 2.16): `Semigroup`/`Monoid` wrappers
  using `.&&.` / `.||.`, with `mempty = Every True` / `Some False`. The
  monoid laws hold up to `isSuccess` except when `checkCoverage` is used.
- `expectFailure` inside `conjoin` or `disjoin` makes the test fail with
  "expectFailure may not occur inside a conjunction/disjunction".

## Failure reporting

| Combinator | Effect |
|---|---|
| `counterexample s` | adds `s` to the test case lines, printed after the generated values on the final failure |
| `printTestCase` | deprecated alias of `counterexample` |
| `whenFail io` | runs `io` once after the final, shrunk failure |
| `whenFail' io` | runs `io` after every failing test, including shrink candidates |
| `withProgress f` | runs `f` with a `TestProgress` after every test (since 2.16; called before the counters are updated for that test) |
| `witness x` | records `x` (Typeable, Show) in `witnesses` of the `Failure` (since 2.15) |
| `label`, `classify`, ... | distribution reporting: [qik-chk-distribution](../../qik-chk-distribution/SKILL.md) |

## Exceptions

QuickCheck catches synchronous exceptions from the property and its
`Show` output (`tryEvaluateIO`, `Exception.hs` L62) and turns them into
failures with reason `Exception: ...`. It does **not** catch asynchronous
exceptions (since 2.10), so Ctrl-C stops testing; `isInterrupt` detects
`UserInterrupt` so an interrupted case is not shrunk. Since 2.16 the
exception text uses `displayException` rather than `show`.

## Per-test result fields

The per-test `Result` record in this module (not the runner's `Result`):
`ok` (`Just True`/`Just False`/`Nothing` for discard), `expect`, `reason`,
`theException`, `abort` (set by `once`), `maybeNumTests`,
`maybeCheckCoverage`, `maybeDiscardedRatio`, `maybeMaxShrinks`,
`maybeMaxTestSize` (set by the `with*` combinators), `labels`, `classes`,
`tables`, `requiredCoverage`, `callbacks`, `testCase`, and `theWitnesses`.
Every `with*` combinator works by setting one of these fields, which the
runner reads after each test. This is internal API
([qik-chk-internals](../../qik-chk-internals/SKILL.md)).
