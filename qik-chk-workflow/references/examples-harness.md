# The examples harness

Companion to [qik-chk-workflow](../SKILL.md). Files:
[scripts/QikChkHarness.hs](../scripts/QikChkHarness.hs) and
[scripts/run-examples.sh](../scripts/run-examples.sh).

## Why

Many examples in this pack fail on purpose: they show a weak property
passing, a bug being found, a generator giving up. A plain "exit 0 means
fine" check cannot tell those from regressions. Each example therefore
declares what every property it runs should report, and the harness checks
the declaration.

## Writing an example

```haskell
-- qik-chk-example: one line saying what the file shows.
import QikChkHarness
import Test.QuickCheck

prop_ok :: [Int] -> Bool
prop_ok xs = reverse (reverse xs) == xs

prop_wrong :: [Int] -> Bool
prop_wrong xs = reverse xs == xs

main :: IO ()
main = runChecks
  [ check Pass "reverse twice" prop_ok
  , check Fail "reverse is not the identity" prop_wrong
  ]
```

| Function | Use |
|---|---|
| `check e name p` | run with `stdArgs`, expect `e` |
| `checkWith args e name p` | run with given `Args` |
| `checkSeeded n e name p` | replay seed `mkQCGen n` from size 0, for expectations about one particular search (for example a shrink that reaches a local minimum) |
| `checkResult args name judge p` | judge the whole `Result` (reason, exception, failing test case) |
| `runChecks [..]` | print `QIK-CHK-EXAMPLE OK: N checks as expected` and exit 0, or `QIK-CHK-EXAMPLE MISMATCH: ...` and exit 1 |

`Expect` is `Pass` (`Success`), `Fail` (`Failure`), `GiveUp` (`GaveUp`), or
`NoExpected` (`NoExpectedFailure`).

**Stability:** an unseeded `Fail` expectation must fail essentially every
run (bugs found within a few tests); a `Pass` for a buggy property is only
acceptable when the bug is unreachable by the generator, which is then the
point of the example. Seeded expectations hold for QuickCheck 2.19.0.0
with splitmix 0.1.3.2 only.

## Running

```bash
export PATH=$HOME/.ghcup/bin:$PATH          # wherever ghc and cabal are
qik-chk-workflow/scripts/run-examples.sh --setup      # once: package environment
qik-chk-workflow/scripts/run-examples.sh              # every example
qik-chk-workflow/scripts/run-examples.sh qik-chk-shrinking
qik-chk-workflow/scripts/run-examples.sh qik-chk-shrinking/examples/ShrinkTraps.hs
```

`--setup` runs `cabal install --lib --package-env ENV QuickCheck-2.19.0.0
containers deepseq tasty tasty-quickcheck` with QuickCheck pinned. Each
example is compiled with `ghc -package-env ENV -O0` and run with a timeout
(`QIK_CHK_TIMEOUT`, default 120 s). Results:

| Report | Meaning |
|---|---|
| `ok` | exit 0 and the OK line |
| `MISMATCH` | some result differed from its declaration (the `=== ` and `!!! ` lines are shown) |
| `COMPILE-ERROR` | did not compile (output shown) |
| `TIMEOUT` | ran longer than the limit |

The script exits non-zero if any example is not `ok`.

## What is not run

- `qik-chk-running/examples/manual/WithinTightLoop.hs`: hangs at `-O2` by
  design; run it by hand as its header describes.
- `qik-chk-workflow/examples/hspec/HspecSpec.hs`: needs `hspec`, which the
  harness environment does not include.
- `qik-chk-workflow/examples/cabal-project/`: a package, run with
  `cabal test` (see [integration.md](integration.md)).

## Notes on the environment used for this pack

GHC 9.10.3 and cabal-install 3.16.1.0 from ghcup, Linux x86-64. Without
the `libgmp-dev` development symlink, linking failed with `cannot find
-lgmp`; a directory holding `libgmp.so -> /usr/lib/x86_64-linux-gnu/libgmp.so.10`
on `LIBRARY_PATH` fixed it. Recorded in the
[validation report](../../qik-chk-overview/references/validation-report.md).
