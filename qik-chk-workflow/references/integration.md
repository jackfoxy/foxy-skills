# Test-framework and build integration

Companion to [qik-chk-workflow](../SKILL.md). Everything here was run on
2026-10-20 with GHC 9.10.3, cabal-install 3.16.1.0 and QuickCheck
2.19.0.0. Framework packages are third-party; versions are what the build
plan chose (tasty 1.5.4, tasty-quickcheck 0.11.1, hspec 2.11.18), not
requirements.

## Contents

- [cabal test-suite](#cabal-test-suite)
- [tasty-quickcheck](#tasty-quickcheck)
- [hspec](#hspec)
- [Other frameworks](#other-frameworks)
- [Template Haskell discovery](#template-haskell-discovery)

## cabal test-suite

[examples/cabal-project/](../examples/cabal-project/) is a complete
package:

```cabal
test-suite properties
  type:             exitcode-stdio-1.0
  hs-source-dirs:   test
  main-is:          Main.hs
  build-depends:    base, qik-chk-demo, QuickCheck ==2.19.*
```

`test/Main.hs` collects `quickCheckResult` results and calls `exitFailure`
unless all are `isSuccess`. Run from the package directory:

```bash
cabal test --test-show-details=direct
```

Recorded (a copy in the research area): the three properties passed and
the suite reported `Test suite properties: PASS`, exit 0. With a seeded bug
in `decode` (runs longer than 2 truncated), the suite printed the shrunk
counterexample `[False,False,False]` / `[False,False] /= [False,False,False]`,
`Test suite properties: FAIL`, and `cabal test` exited 1.

`isSuccess` treats `GaveUp` and `NoExpectedFailure` as failures, which is
usually what a CI suite wants.

## tasty-quickcheck

```haskell
import Test.Tasty
import Test.Tasty.QuickCheck as QC

main = defaultMain $ testGroup "lists"
  [ QC.testProperty "reverse involution" $ \xs -> reverse (reverse xs) == (xs :: [Int])
  , adjustOption (\(QuickCheckTests n) -> QuickCheckTests (n * 5)) $
      QC.testProperty "append length" $ \xs ys -> length (xs ++ ys) == length xs + length (ys :: [Int])
  ]
```

`Test.Tasty.QuickCheck` re-exports QuickCheck, so modifiers and
generators are in scope. `defaultMain` exits non-zero on failure
(checked in [TastySuite.hs](../examples/TastySuite.hs) by catching the
`ExitCode`). Command-line options (from `--help` of a test binary,
tasty-quickcheck 0.11.1):

| Option | Meaning |
|---|---|
| `--quickcheck-tests NUMBER` | number of test cases (default 100; underscores allowed) |
| `--quickcheck-replay SEED` | replay a previous run |
| `--quickcheck-show-replay` | show a replay token even for passing tests |
| `--quickcheck-max-size NUMBER` | `maxSize` (default 100) |
| `--quickcheck-max-ratio NUMBER` | `maxDiscardRatio` |
| `--quickcheck-verbose` | show generated test cases |
| `--quickcheck-shrinks NUMBER` | `maxShrinks` |
| `--quickcheck-timeout DURATION` | timeout for each test case (`ms`, `s`, `m`, `h`) |

Each has an option type for `adjustOption`/`localOption`
(`QuickCheckTests`, `QuickCheckReplay`, `QuickCheckMaxSize`, ...). A
failure prints:

```text
reverse is the identity (false): FAIL
  *** Failed! Falsified (after 3 tests and 3 shrinks):
  [0,1]
  Use --quickcheck-replay="(SMGen 2991095277165689883 4164009092495857329,2)" to reproduce.
```

The token is a `QCGen` and a size: replay is exact only with the same
QuickCheck version and code. Select one test with tasty's `-p PATTERN`.

## hspec

```haskell
import Test.Hspec
import Test.Hspec.QuickCheck (modifyMaxSuccess, prop)
import Test.QuickCheck

main = hspec $ describe "reverse" $ do
  prop "is an involution" $ \xs -> reverse (reverse xs) == (xs :: [Int])
  modifyMaxSuccess (const 1000) $
    prop "keeps the length" $ \xs -> length (reverse xs) === length (xs :: [Int])
  it "distributes over append" $ property $ \xs ys ->
    reverse (xs ++ ys) === reverse ys ++ reverse (xs :: [Int])
```

[hspec/HspecSpec.hs](../examples/hspec/HspecSpec.hs) was compiled against
a separate package environment containing hspec 2.11.18 and run by hand.
The deliberately false property failed and hspec printed

```text
  1) a deliberately false law reverse is the identity
       Falsified (after 5 tests and 2 shrinks):
         [0,1]

  To rerun use: --match "/a deliberately false law/reverse is the identity/" --seed 1489698406
```

and exited 1. Rerunning with that `--match` and `--seed` reproduced the
same failure. hspec's QuickCheck options: `--qc-max-success=N` (`-a N`),
`--qc-max-discard=N`, `--qc-max-size=N`, `--qc-max-shrinks=N`, and `--seed`
(shared with `--randomize`). `modifyMaxSuccess`, `modifyMaxSize`,
`modifyMaxDiscardRatio`, `modifyMaxShrinks`, and `modifyArgs` adjust a
subtree (re-exported from hspec-core; `fprop`/`xprop` focus or skip).

## Other frameworks

Not run for this pack:

- `test-framework` with `test-framework-quickcheck2` (`testProperty`):
  older, still found in existing projects.
- `sydtest`, `hedgehog` (a different property-testing library, not
  QuickCheck), `doctest` (properties in Haddock comments with `prop>`).

## Template Haskell discovery

`Test.QuickCheck.All` (cabal flag `templateHaskell`, default on):
`$quickCheckAll` runs every top-level `prop_*` in the module and returns
`IO Bool`; `$forAllProperties runner` uses a custom runner; `return []`
must precede the splice so the definitions are visible. Executed in
[AllProperties.hs](../../qik-chk-running/examples/AllProperties.hs).
Upstream example files end with `main = do True <- $quickCheckAll; return ()`,
which fails with a pattern-match error when any property fails
([upstream-examples.md](../../qik-chk-applications/references/upstream-examples.md)).
