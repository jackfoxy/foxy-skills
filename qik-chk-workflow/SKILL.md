---
name: qik-chk-workflow
description: Put QuickCheck to work in a real Haskell project - from requirements to properties, exploring in GHCi, a cabal test-suite (exitcode-stdio-1.0) that fails CI on a failed property, tasty-quickcheck and hspec (prop, modifyMaxSuccess, --quickcheck-tests, --quickcheck-replay), turning shrunk counterexamples into permanent regression tests, deterministic and time-bounded CI runs, choosing test counts, compatibility flags and compilers (templateHaskell, old-random, Hugs, MicroHs), and this pack's examples harness. Use when adding QuickCheck to a project, wiring properties into a test framework or CI, deciding how many tests to run, saving a failure as a regression test, or reproducing a CI failure locally.
user-invocable: true
disable-model-invocation: false
---

# QuickCheck in a project workflow

**Scope:** everything around the properties: where they live, how they
run, how failures become permanent tests. The runner's own options are
[qik-chk-running](../qik-chk-running/SKILL.md); upstream QuickCheck's own
build and CI are in [qik-chk-internals](../qik-chk-internals/references/contributing.md).

**Prerequisites:** [qik-chk-foundations](../qik-chk-foundations/SKILL.md),
[qik-chk-running](../qik-chk-running/SKILL.md).

**Version:** QuickCheck 2.19.0.0 with GHC 9.10.3; tasty 1.5.4 with
tasty-quickcheck 0.11.1; hspec 2.11.18. Framework versions are what this
pack ran, not requirements.

## The loop

1. **Requirements to properties.** For each requirement, write the
   property that would fail if it were violated; for each function, look
   for a model, an inverse, an invariant, or a metamorphic relation
   ([qik-chk-property-design](../qik-chk-property-design/SKILL.md)).
2. **Explore in GHCi.** `quickCheck`, `verboseCheck`, `sample
   (arbitrary :: Gen T)`, `labelledExamples` give fast feedback. Annotate
   types: an unannotated `quickCheck (\xs -> ...)` defaults to `()` in GHCi
   ([VacuousAndDefaulting.hs](../qik-chk-property-design/examples/VacuousAndDefaulting.hs)).
3. **Seed a bug** and check that some property catches it.
4. **Move properties into the test suite** so that a failing property fails
   the build.
5. **Capture each counterexample as a regression test** once fixed.
6. **Check distribution** with `classify`/`cover`, and use `checkCoverage`
   for requirements that matter ([qik-chk-distribution](../qik-chk-distribution/SKILL.md)).

## A cabal test suite

`quickCheck` returns `()` and never fails the process. A suite of type
`exitcode-stdio-1.0` must exit non-zero itself:

```haskell
main :: IO ()
main = do
  results <- sequence [ quickCheckResult prop_roundTrip
                      , quickCheckResult (withNumTests 500 prop_noEmptyRuns) ]
  unless (all isSuccess results) exitFailure
```

Complete package: [examples/cabal-project/](examples/cabal-project/)
(`qik-chk-demo.cabal`, `src/RunLength.hs`, `test/Main.hs`). With Template
Haskell, `$quickCheckAll :: IO Bool` gives the same with one line:
`main = $quickCheckAll >>= \ok -> unless ok exitFailure` (upstream examples
use `True <- $quickCheckAll`).

## Test frameworks

| Framework | Entry | Per-test count | Replay a failure |
|---|---|---|---|
| tasty + tasty-quickcheck | `testProperty name prop` | `adjustOption (\(QuickCheckTests n) -> QuickCheckTests (n*5))`; CLI `--quickcheck-tests N` | prints `Use --quickcheck-replay="(SMGen ...,2)" to reproduce.` |
| hspec (`Test.Hspec.QuickCheck`) | `prop name prop`, or `it name (property p)` | `modifyMaxSuccess (const 1000)`; CLI `--qc-max-success` | prints a `--seed` to rerun with |
| plain `exitcode-stdio` | `quickCheckResult` | `withNumTests`, `Args` | `recheck`, `replay` |

Executed: [TastySuite.hs](examples/TastySuite.hs) (a passing tree and a
failing tree, checking tasty's exit codes) and
[hspec/HspecSpec.hs](examples/hspec/HspecSpec.hs) (run manually; needs
hspec). Option names and output: [references/integration.md](references/integration.md).

QuickCheck's own per-property modifiers (`withNumTests`, `withMaxSize`,
`checkCoverage`, `within`) travel with the property and work under every
framework; framework options set the defaults around them.

## Regression tests from counterexamples

**Save the counterexample, not the seed.** The `replay` documentation:
seeds are not portable across QuickCheck versions, and changing generators
or property code changes what a seed produces.

```haskell
regressionCases :: [(Int, Int)]
regressionCases = [(-7, 2), (7, -2), (-7, -2)]

prop_regressions :: Property
prop_regressions = once $ conjoin
  [ counterexample (show c) (prop_law a (NonZero b)) | c@(a, b) <- regressionCases ]
```

Keep the randomized property next to it. Executed in
[RegressionCapture.hs](examples/RegressionCapture.hs), which also shows
that 2000 random tests miss the `divMod minBound (-1)` overflow that one
explicit boundary case finds.

## CI practice

- **Fail the job** on any failed property (framework or `isSuccess`).
- **Print the seed or replay token** in logs (frameworks do), so a failure
  can be replayed locally with the same QuickCheck version and code.
- **Fixed seeds in CI** (`--quickcheck-replay`, hspec `--seed`) give
  reproducible runs but explore the same inputs every time; random seeds
  explore more over time. A common compromise: random by default, seed
  printed on failure.
- **Test counts:** the default 100 is a smoke test. Raise counts for cheap
  properties and properties with rare cases (`withNumTests`), or nightly
  with a CLI option. Coverage requirements with `checkCoverage` choose their
  own count.
- **Bound time** with framework timeouts (`--quickcheck-timeout`, tasty
  `--timeout`) and `within` for individual tests; neither interrupts a
  non-allocating loop ([qik-chk-running](../qik-chk-running/SKILL.md#timeouts-and-their-guarantees)).
- **Pin QuickCheck** (and random/splitmix) in the build plan if saved seeds
  or recorded outputs matter.

## Compatibility

| Setting | Effect |
|---|---|
| cabal flag `templateHaskell` (default on, manual) | builds `Test.QuickCheck.All`; off for compilers without TH |
| cabal flag `old-random` (default off, automatic) | build against `random < 1.2` |
| GHC | `Tested-with: GHC >= 8.10 && < 9.15`; upstream CI covers 8.10 to 9.14 and latest |
| Hugs | supported via `make-hugs` (cpphs with `-DNO_...` flags); no TH, timeouts, generics, Typeable, splitmix |
| MicroHs | supported since 2.17; no generics or TH |

Feature macros (`NO_TIMEOUT`, `NO_GENERICS`, ...) mean some functions do
nothing or do not exist on those compilers: `within` and `discardAfter` do
nothing without timeout support.

## Pitfalls

- A test `main` built from `quickCheck` calls **always succeeds**.
- **`()` defaulting** in GHCi or with polymorphic properties: annotate, or
  use `$(monomorphic 'prop)`.
- **Order-dependent suites:** properties sharing global state pass alone
  and fail together (or the reverse).
- **Flaky CI** from rare-case bugs: a failure that appears once in many
  runs is a real bug found late; capture its counterexample, then raise the
  test count or improve the generator ([qik-chk-debugging](../qik-chk-debugging/SKILL.md)).
- **Seed replay across versions** silently reproduces nothing.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| CI passes although a property failed | `quickCheck` in `main` | `quickCheckResult` + `isSuccess`, or a framework |
| Replay token from CI does not reproduce locally | different QuickCheck version or code | pin versions; save the counterexample |
| hspec option ignored | QuickCheck modifiers in the property override defaults | adjust the modifier, or remove it |
| `cabal test` cannot find `QuickCheck` | missing `build-depends` in the test stanza | add `QuickCheck` to the test suite |

## Executable examples

| File | Shows |
|---|---|
| [TastySuite.hs](examples/TastySuite.hs) | tasty tree, `adjustOption`, a failing tree's exit code and replay token |
| [RegressionCapture.hs](examples/RegressionCapture.hs) | saved counterexamples with `once`/`conjoin`, `withNumTests`, a boundary case |
| [cabal-project/](examples/cabal-project/) | a package with an `exitcode-stdio-1.0` QuickCheck suite (`cabal test`) |
| [hspec/HspecSpec.hs](examples/hspec/HspecSpec.hs) | hspec `prop`, `modifyMaxSuccess`, `property` (manual) |

Run: `qik-chk-workflow/scripts/run-examples.sh qik-chk-workflow`.

## Go deeper

- [references/integration.md](references/integration.md): framework
  options, output, replay, and the cabal package walk-through.
- [references/examples-harness.md](references/examples-harness.md): how
  this pack's examples declare and check expected outcomes.
