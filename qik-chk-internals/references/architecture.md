# QuickCheck 2.19 architecture

Companion to [qik-chk-internals](../SKILL.md). All paths are under `src/`
at commit `3d8fe8686024760006ca1ca656cbdd82cd71f11e`; line numbers refer
to that commit (`https://github.com/nick8325/quickcheck/blob/3d8fe8686024760006ca1ca656cbdd82cd71f11e/src/<path>#L<n>`).
Descriptions are summaries of the code, not copies.

## Contents

- [Module map](#module-map)
- [Seeds: QCGen and splitting](#seeds-qcgen-and-splitting)
- [Gen](#gen)
- [Rose trees and Prop](#rose-trees-and-prop)
- [Testable and Property](#testable-and-property)
- [The per-test Result](#the-per-test-result)
- [The test loop](#the-test-loop)
- [Shrinking: localMin](#shrinking-localmin)
- [Coverage](#coverage)
- [Exceptions and discard](#exceptions-and-discard)
- [Terminal output](#terminal-output)
- [Function and InfiniteList: the partial-value trick](#function-and-infinitelist-the-partial-value-trick)
- [CPP feature flags](#cpp-feature-flags)

## Module map

| Module (lines) | Documented? | Contents |
|---|---|---|
| `Test/QuickCheck.hs` | yes | the main re-export list |
| `Test/QuickCheck/Gen.hs` (385) | yes | `Gen`, combinators, `generate`, `sample` |
| `Test/QuickCheck/Gen/Unsafe.hs` (53) | yes | `promote`, `delay`, `capture` |
| `Test/QuickCheck/Arbitrary.hs` (1979) | yes | `Arbitrary`, `CoArbitrary`, instances, shrinkers, generic deriving |
| `Test/QuickCheck/Modifiers.hs` (566) | yes | newtype modifiers (`Positive`, `OrderedList`, `InfiniteList`, ...) |
| `Test/QuickCheck/Function.hs` (773) | yes | `Fun`, `:->`, `Function` |
| `Test/QuickCheck/Property.hs` (1099) | Haddock-hidden, exposed | `Property`, `Testable`, `Rose`, per-test `Result`, combinators |
| `Test/QuickCheck/Test.hs` (780) | Haddock-hidden, exposed | `Args`, run `Result`, runners, test loop, shrink loop, coverage statistics |
| `Test/QuickCheck/Monadic.hs` (368) | yes | `PropertyM` |
| `Test/QuickCheck/Poly.hs` (179) | yes | `A`, `B`, `C`, `OrdA`, ... for polymorphic testing |
| `Test/QuickCheck/Monoids.hs` (83) | yes | `Every`, `Some` |
| `Test/QuickCheck/All.hs` (229) | yes, if TH | `quickCheckAll`, `monomorphic` |
| `Test/QuickCheck/Features.hs` (108) | Haddock-hidden, exposed | `labelledExamples` |
| `Test/QuickCheck/Random.hs` (131) | Haddock-hidden, exposed | `QCGen`, `mkQCGen`, `newQCGen`, `integerVariant` |
| `Test/QuickCheck/Exception.hs` (118) | Haddock-hidden, exposed | exception helpers, `discard` |
| `Test/QuickCheck/State.hs` (111) | Haddock-hidden, exposed | runner `State`, `Confidence`, `TestProgress` |
| `Test/QuickCheck/Text.hs` (236) | Haddock-hidden, exposed | `Terminal`, table formatting |
| `Test/QuickCheck/Compat.hs` (35) | exposed | `Solo` compatibility shims |

Haddock-hidden modules carry `OPTIONS_HADDOCK hide` but are listed in
`Exposed-Modules`, so they can be imported. All except `Text` have no
export list, so every top-level name is visible. Their public parts
(`Property`, `Testable`, `Args`, `Result`, the runners, `labelledExamples`,
...) are documented through the `Test.QuickCheck` re-exports; anything
else in them is an implementation detail.

## Seeds: QCGen and splitting

`QCGen` (`Random.hs` L19-21) wraps splitmix's `SMGen` on GHC, `StdGen`
where splitmix is unavailable (`NO_SPLITMIX`, Hugs). It has `Show`/`Read`
instances, `RandomGen`, and a `Splittable` class with `left`/`right`.
`integerVariant` (L106) maps an `Integer` to a sequence of left/right
splits using a sign bit and Elias gamma coding, a prefix-free code, so
`variant m` and `variant n` give independent seeds for `m /= n`. The
upstream test `tests/Split.hs` checks the prefix-free property.

## Gen

`newtype Gen a = MkGen { unGen :: QCGen -> Int -> a }` (`Gen.hs` L66): a
function of a seed and a size.

- `>>=` splits the seed: the first action gets one half, the
  continuation the other (L86). `*>` and `<*` do not split (comment: not
  needed). `fmap` passes the seed through.
- Because of splitting, `return x >>= f` and `f x` see different seeds:
  the laws hold in distribution only, the 2000 paper's "morally a monad"
  (executed in [GenInternals.hs](../examples/GenInternals.hs)).
- `MonadFix` ties the knot with the same seed.
- `variant k` (L109) transforms the seed with `integerVariant`;
  `CoArbitrary` instances use it to make generated functions depend on
  their argument.
- `promote` (`Gen/Unsafe.hs` L28) turns `m (Gen a)` into `Gen (m a)` for a
  monad `m` by capturing the seed; used by `PropertyM` and by function
  generation.

## Rose trees and Prop

`data Rose a = MkRose a [Rose a] | IORose (IO (Rose a))` (`Property.hs`
L195): a lazy tree of results whose children are shrink candidates;
`IORose` delays IO until the node is needed. `joinRose` (L201) flattens a
tree of trees: the outer tree's children (shrinking the outer quantified
value) come first, then the inner root's children (shrinking the inner
value), which is how nested quantifiers order their shrinking.
`newtype Prop = MkProp { unProp :: Rose Result }`.

## Testable and Property

`newtype Property = MkProperty { unProperty :: Gen Prop }` (L85).
`class Testable prop` (L92) has `property :: prop -> Property` and
`propertyForAllShrinkShow` (an internal hook). Instances: `Bool`,
`Result`, `Prop`, `Property`, `Gen prop`, `Maybe prop` (since 2.13:
`Nothing` discards), `Discard`, `()`, functions, and `Every`/`Some`
(`Monoids.hs`, since 2.16).

The function instance (L172) quantifies the argument with `arbitrary`,
`shrink`, and `show`, and for curried functions **pairs** each new
argument with the earlier ones, so multi-argument properties shrink as one
tuple (2.13 changelog). `forAllShrink`-style quantifiers build a rose
tree whose children are the property applied to each shrink candidate
(`shrinking`, L394).

## The per-test Result

`Property.hs` has its own `data Result = MkResult { ... }`, distinct from
the runner's `Test.QuickCheck.Test.Result`. Fields include `ok :: Maybe
Bool` (`Nothing` = discarded), `expect` (cleared by `expectFailure`),
`reason`, `theException`, `abort` (set by `once`), the per-property
settings `maybeNumTests`, `maybeCheckCoverage`, `maybeDiscardedRatio`,
`maybeMaxShrinks`, `maybeMaxTestSize`, the observations `labels`,
`classes`, `tables`, `requiredCoverage`, `callbacks` (`PostTest`,
`PostFinalFailure`, used by `whenFail`, `verbose`, `counterexample`),
`testCase` (printed lines), and `witnesses`. Combinators such as `label`,
`withNumTests`, or `counterexample` work by mapping over this record in
every node of the rose tree.

## The test loop

`Test.hs`: `quickCheckWithResult` builds a `State` (`State.hs`) from
`Args` and calls `test` (L299), which chooses, in order:
`finishedSuccessfully` → `doneTesting`; `finishedInsufficientCoverage` →
`failCoverage`; `tooManyDiscards` → `giveUp`; otherwise `runATest`
(L415). `runATest` computes the size (`computeSize`, L240), splits the
seed, runs the property's `Gen Prop` at that seed and size, reduces the
root of the rose tree, runs `PostTest` callbacks, and then:

- `ok = Just True`: count a success, add labels/classes/tables/coverage to
  the state, continue (or stop if `abort`);
- `ok = Nothing`: count a discard (no coverage), continue;
- `ok = Just False`: call `foundFailure` with the root's children.

Per-test settings from the result (`maybeNumTests`, ...) update the state
before continuing. `usedSeed` is the seed *before* the split (comment:
"correct! (this will be split first)").

## Shrinking: localMin

`foundFailure` → `localMin` (L604): greedy depth-first search over the
rose tree. For each child in order: evaluate it (exceptions are failures);
if it fails, it becomes the new current counterexample and the search
restarts from *its* children; otherwise try the next sibling. It stops
when no child fails (a local minimum) or when successful plus failed
attempts reach `maxShrinks`. It returns successful shrinks, failed tries
excluding those since the last success, and failed tries since the last
success (`numShrinks`, `numShrinkTries`, `numShrinkFinal`). The progress
line on stderr shows the running counts. An exception while computing the
shrink list ends shrinking with "Exception while generating shrink-list".

## Coverage

Coverage requirements are stored per `(Maybe table, label)` with the
maximum required proportion. `timeToCheckCoverage` (L330) fires at the
configured test count and at 100·2^k; `sufficientlyCovered`/
`insufficientlyCovered` (L666 onward) use a Wilson score interval with an
inverse normal CDF implemented in the module. Details:
[coverage-statistics.md](../../qik-chk-distribution/references/coverage-statistics.md).

## Exceptions and discard

`Exception.hs`: `tryEvaluateIO` (L62) catches all synchronous exceptions
and rethrows asynchronous ones (`SomeAsyncException`), so Ctrl-C,
timeouts, `StackOverflow` and `HeapOverflow` escape the runner.
`isInterrupt` recognises `UserInterrupt`; interrupted cases are not
shrunk. `discard` (L96) is `throw (ErrorCall "DISCARD. ...")` with a
private message; `isDiscard` recognises it and the property layer turns
it into a rejected (discarded) result. `protect`, `protectRose`,
`protectProp` wrap evaluation so a throwing property becomes a failed
`Result` with reason `Exception: ...`.

## Terminal output

`Text.hs`: a `Terminal` accumulates the final output (returned in
`output`) and writes temporary progress text (`putTemp`) to stderr only
when it is a terminal, erasing it with backspaces; `putPart`/`putLine`
write permanent text. `withNullTerminal` backs `chatty = False`. The
upstream suite `tests/Terminal.hs` checks this against a model.

## Function and InfiniteList: the partial-value trick

- `data Fun a b = Fun (a :-> b, b, Shrunk) (a -> b)` (`Function.hs`
  L682): a concrete representation `a :-> b` (L127: `Pair`, `:+:`, `Unit`,
  `Nil`, `Table`, `Map`), a default result, a `Shrunk` flag, and the
  derived function. The generated `:->` is infinite in principle;
  shrinking (`shrinkFun`, L631) replaces parts by `Nil` (use the default)
  and shrinks results, making the function finite and printable. A `Fun`
  still flagged `NotShrunk` prints `<fun>`.
- `InfiniteList` (`Modifiers.hs` L183 onward) uses the same idea: it starts
  as an infinite list, shrinks to finite prefixes, and appends `discard`
  after the prefix, so a test that reads past the prefix is discarded
  rather than passing with fake data. It prints as `"bbbbbbbbbb" ++ ...`.

## CPP feature flags

The library adapts with `-DNO_...` macros set in `QuickCheck.cabal` per
compiler: `NO_TIMEOUT` (no `within`/`discardAfter` effect),
`NO_TEMPLATE_HASKELL` (no `All`), `NO_GENERICS`, `NO_TYPEABLE` (no
witnesses), `NO_SPLITMIX` with `OLD_RANDOM`, `NO_ST_MONAD`, `NO_DEEPSEQ`,
`NO_CALLSTACK`, `NO_SAFE_HASKELL`, `NO_MONADFAIL`, `NO_TRANSFORMERS`, and
more. `make-hugs` applies a fixed set of them with `cpphs` to produce a
Hugs-compatible tree.
