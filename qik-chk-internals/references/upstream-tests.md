# Upstream tests: what they establish

Companion to [qik-chk-internals](../SKILL.md). Test files at commit
`3d8fe868` (`tests/`, plus `examples/Heap.hs`). Run for this pack on
2026-10-20 with GHC 9.10.3 and cabal-install 3.16.1.0 in a clean clone:

```bash
cabal build all --enable-tests
cabal test all
```

All 13 test suites reported `PASS`. Exact log lines and the dependency
versions chosen are in the
[validation report](../../qik-chk-overview/references/validation-report.md).

## Cabal test suites

| Suite | File | Checks |
|---|---|---|
| `test-quickcheck` | `examples/Heap.hs` | skew-heap example, nine properties with `$quickCheckAll` |
| `test-quickcheck-gcoarbitrary` | `GCoArbitraryExample.hs` | generic `CoArbitrary` and `functionShow` produce functions that depend on the argument: `f (C1 2) ∈ {0,1}` must fail within 1000 tests (`expectFailure`) |
| `test-quickcheck-generators` | `Generators.hs` | modifiers stay in range and reach bounds (`Positive`, `NonZero`, `Small`, `Large`, ...); `prop_reachesBound_*` for fixed-width integers; `prop_no_shrinking_loop_*` for ~30 types (shrinking terminates); Double shrink candidates; Fixed; `Blind`; run with `maxShrinks = 10000` |
| `test-quickcheck-gshrink` | `GShrinkExample.hs` | `genericShrink (S (S Z)) == [S Z]`, `genericShrink [0] == [[]]` |
| `test-quickcheck-terminal` | `Terminal.hs` | terminal output against a model: temporary text erased, stdout equals `terminalOutput` |
| `test-quickcheck-monadfix` | `MonadFix.hs` | `MonadFix Gen` on cyclic structures |
| `test-quickcheck-split` | `Split.hs` | `integerVariant` is a prefix-free code |
| `test-quickcheck-strictness` | `Strictness.hs` | generated strict `Map`s contain no thunks (an `Arbitrary` that throws must surface) |
| `test-quickcheck-misc` | `Misc.hs` | `verbose` does not change results; `failingTestCase` lines `read` back to a failing case; `withMaxSize`; `checkCoverage` honours `withNumTests 1000`; discards and coverage (issue #382); classes counted at 0%; shrinkers that `discard`; `sample` with `discard` does not crash |
| `test-quickcheck-discard` | `DiscardRatio.hs` | discard-ratio arithmetic: `False ==> True` with ratio 2 gives up after exactly 200 discards; ratio 1 fails and ratio 40 passes for a 1-in-20 condition; `cover`/`classify` with `discard` |
| `test-quickcheck-monoids` | `Monoids.hs` | `Every`/`Some` monoid and semigroup laws |
| `test-quickcheck-withprogress` | `WithProgress.hs` | `withProgress` callback counts for passing and discarded tests, and when not installed |
| `test-quickcheck-instances` | `RunCollectDataTypes.hs` with `CollectDataTypes.hs` | uses `hint` to enumerate the types exported by `base` (minus a block list) and generates, for each, properties that `arbitrary`, `arbitrary` of functions from it (`CoArbitrary`), and `:->` from it (`Function`) exist and evaluate; not buildable for GHC 8.10 or without TH |

## Files not wired into cabal

| File | Content | Run for this pack |
|---|---|---|
| `ShrinkMap.hs` | `shrinkMap sort id` keeps lists sorted | yes: passed 100 tests |
| `TestRandom.hs` | statistical checks that split paths give independent values (comment: "disabled by default as it's expensive and not testing QuickCheck as such") | see validation report |
| `Weird.hs` | corner cases of exception and Ctrl-C handling: `undefined` properties, callbacks, `within` around loops, shrinkers that loop forever, `$(monomorphic ...)` on constructors | **no**: contains deliberately non-terminating properties (`prop_loop`, `prop_forevershrink`) with no timeout |

`test-hugs` and `test-mhs` (repository root) build QuickCheck with Hugs or
MicroHs and check two outputs: a passing `reverse . reverse` property and a
failing `reverse` shrinking to `[0,1]`. Not run (no Hugs or MicroHs here).

## Gaps

Behaviour the upstream suites do **not** test directly, as far as these
files show (relevant when changing QuickCheck):

- the exact output text of `Success`, `GaveUp`, `Failure` messages beyond
  the terminal model;
- `within`/`discardAfter` timing;
- `labelledExamples`;
- shrinking order and minimality for standard types (only termination);
- `recheck` and `replay` reproducing a failure across runs;
- `Test.QuickCheck.Monadic` beyond what examples use;
- `witness`/`witnesses`;
- the size schedule, except indirectly through `prop_discardCoverage`
  (the `computeSize` comment warns that test depends on the sequence).

The pack's executable examples cover several of these (see the
[coverage ledger](../../qik-chk-overview/references/coverage-ledger.md)).
