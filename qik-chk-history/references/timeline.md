# QuickCheck timeline

Companion to [qik-chk-history](../SKILL.md). Sources: the Chalmers
QuickCheck page and files (accessed 2026-10-20), the ICFP 2000 and Haskell
Workshop 2002 papers, and `changelog.md` and git history of
`nick8325/quickcheck` at commit `3d8fe868`. Dates for releases are from
the changelog; earlier dates from the papers and git log.

## Contents

- [QuickCheck 1 (Chalmers)](#quickcheck-1-chalmers)
- [Repository history](#repository-history)
- [QuickCheck 2 releases](#quickcheck-2-releases)
- [Migrating old code](#migrating-old-code)

## QuickCheck 1 (Chalmers)

- **2000**: Claessen and Hughes, *QuickCheck: A Lightweight Tool for Random
  Testing of Haskell Programs*, ICFP 2000. The Chalmers page links the
  module `QuickCheck.hs` ("distributed with Hugs and GHC"), an online
  manual, `ShowFunctions.hs`, and a `quickcheck` script that ran every
  property in a module through GHCi (the script link returned 404 at
  access).
- **2002**: *Testing Monadic Code with QuickCheck* (Haskell Workshop);
  `QuickCheckM.hs` extends QuickCheck with `PropertyM`, `forEvery`,
  `&&&`, and ST support.
- The Chalmers page also warns that some Hugs versions' `split` returned
  its argument, breaking QuickCheck's assumption that repeatedly split
  generators are independent (`randoms.html`), and mentions experimental
  versions, one integrated with the Hat tracer, and the commercial Erlang
  version by Quviq.

QuickCheck 1 API, from `QuickCheck.hs`:

| QuickCheck 1 | QuickCheck 2.19 |
|---|---|
| `Config { maxTest, maxFail, size, every }`, `check config p` | `Args`, `quickCheckWith` |
| `quick` (100 tests, give up after 1000 failed preconditions, size `n div 2 + 3`) | `stdArgs` (100 tests, discard ratio 10, size 0..99) |
| `test`, `quickCheck`, `verboseCheck` | `quickCheck`, `verboseCheck` |
| "Falsifiable, after N tests:" | "*** Failed! Falsified (after N tests ...)" |
| "Arguments exhausted after N tests" | "*** Gave up! Passed only N tests" |
| `class Arbitrary a where arbitrary; coarbitrary :: a -> Gen b -> Gen b` | `arbitrary`, `shrink` in `Arbitrary`; `coarbitrary` in `CoArbitrary` |
| no shrinking | `shrink`, greedy shrink search |
| `trivial b` | `classify b "trivial"` |
| `two`, `three`, `four` | `vectorOf`, tuples |
| `rand :: Gen StdGen` | `QCGen`, `mkQCGen` |
| `generate :: Int -> StdGen -> Gen a -> a` | `unGen g seed size`; `generate :: Gen a -> IO a` |
| functions shown as `<function>` (`ShowFunctions`) | `Fun` shown as a finite table after shrinking |

## Repository history

- The git history starts on 2006-11-14 with a "tailorization" import and
  commits by Björn Bringert; 1218 commits up to 2.19.
- Tags from `2.4.1` to `2.19`; earlier QuickCheck 2 versions predate the
  tags.
- The repository lives at `github.com/nick8325/quickcheck` (Nick
  Smallbone).

## QuickCheck 2 releases

Highlights per release (summarised; see `changelog.md` for the full text):

| Version | Date | Highlights |
|---|---|---|
| 2.19.0.0 | 2026-09-16 | more `Arbitrary1` instances, `OneTuple` compat instances, better deprecation warning |
| 2.18.0.0 | 2026-02-26 | BREAKING: `CoArbitrary`/`Function` instances for many `base` types; `withMaxSuccess` deprecated for `withNumTests`; `Function` module `Trustworthy` |
| 2.17.1.0 | 2025-10-13 | random-1.2 fix |
| 2.17.0.0 | 2025-10-07 | BREAKING: `Arbitrary` instances for most of `base`; `Gen.Class` removed; MicroHs support; lower memory for `Double`/`Float` |
| 2.16.0.0 | 2025-06-17 | `withProgress`, `Every`/`Some`, `displayException` in messages, `Features` no longer uses the internal loop |
| 2.15 | 2024-04-22 | BREAKING: unquantified properties no longer wrapped in `once`; `witness`; `assertException*`; `withMaxSize`, `withMaxShrinks`, `withMaxDiscardRatio`; `recheck`; `HasCallStack` |
| 2.14.3 | 2023-05-31 | `shrinkBoundedEnum`, `discardAfter`, `assertWith`, `functionElements` |
| 2.14 | 2020-03-28 | fast `chooseInt`/`chooseWord`/... |
| 2.13 | 2019-03-26 | multi-argument properties shrink jointly; `Maybe` is `Testable`; splitmix |
| 2.12 | 2018-09-03 | coverage overhaul: `cover` argument order, `checkCoverage`, `tabulate`, `coverTable`; `labelledExamples`; `idempotentIOProperty`, `forAllBlind`, `verboseShrinking` |
| 2.11 | 2018-01-12 | `InfiniteList`, `applyArbitrary2/3/4`, `allProperties`; `Applicative Gen` splits less; `Fun` constructor exported from `Test.QuickCheck` |
| 2.10 | 2017-06-15 | Unicode `Char`, asynchronous exceptions not caught (Ctrl-C cancels), `Arbitrary1`/`Arbitrary2`, `maxShrinks`, `PropertyM` result must be `Testable` |
| 2.9 | 2016-07-10 | more instances, generic `Function`; `again` added and `exhaustive` removed from `Testable` (non-exhaustive combinators such as `forAll` called `again`; no longer so in 2.19); GHC 6 dropped |
| 2.8 | 2015-03-18 | `shuffle`, `sublistOf`, generic `coarbitrary`, `Fn` pattern; `genericShrink` without `Typeable`; insufficient `cover` made properties fail (a `Result` constructor `InsufficientCoverage`, absent in 2.19, where coverage failures are `Failure` with reason "Insufficient coverage") |
| 2.7 | 2014-03-19 | `Small`/`Large`, `===`, `generate`, `delay`/`capture`, `printTestCase` renamed `counterexample`, `morallyDubiousIOProperty` renamed `ioProperty` |
| 2.6 | 2013-03-07 | `Function` instances up to 7-tuples; line-buffered stderr; interrupted flag in results |
| 2.5 | 2012-06-18 | earliest entry in the changelog |

Point releases (2.x.y) are omitted; consult the changelog.

## Migrating old code

| Old form | Current form | Since |
|---|---|---|
| `cover b pct "s"` | `cover pct b "s"` | 2.12 |
| `printTestCase` | `counterexample` | 2.7 |
| `morallyDubiousIOProperty` | `ioProperty` | 2.7 (old name deprecated) |
| `withMaxSuccess` | `withNumTests` | 2.18 (deprecated) |
| relying on `quickCheck True` running once | `once` | 2.15 |
| `Test.QuickCheck.Gen.Class` | `Gen` directly | removed in 2.17 |
| orphan `Arbitrary` instances for `base` types | delete them (now upstream) | 2.17, 2.18 |
| seed replay across versions | save test cases | never supported |
