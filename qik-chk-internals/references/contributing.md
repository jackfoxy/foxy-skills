# Working on QuickCheck itself

Companion to [qik-chk-internals](../SKILL.md). Repository
`https://github.com/nick8325/quickcheck`; at access (2026-10-20) `master`
and tag `2.19` were the same commit `3d8fe868`.

## Build and test

```bash
git clone https://github.com/nick8325/quickcheck
cd quickcheck
cabal build all --enable-tests
cabal test all
```

Run for this pack with GHC 9.10.3: all 13 suites passed (see
[upstream-tests.md](upstream-tests.md)). The `instances` suite needs
`hint` and `split` and is not buildable with GHC 8.10 or without the
`templateHaskell` flag. `cabal haddock all` is part of CI.

## CI (`.github/workflows/`)

| Workflow | What it runs |
|---|---|
| `haskell-ci.yml` | `cabal build all`, `cabal test all`, `cabal haddock all` on GHC latest, 9.14, 9.12, 9.10, 9.8, 9.6, 9.4, 9.2, 9.0, 8.10; and `stack test` on LTS snapshots from 24.15 (GHC 9.10.3) down to 19.33 (GHC 9.0.2); on push and pull request to `master` and nightly |
| `hugs-ci.yml` | installs Hugs and cpphs, runs `./test-hugs` (regenerates `quickcheck-hugs` with `make-hugs`, checks two properties) |
| `microhs-ci.yml` | installs MicroHs nightly, runs `./test-mhs` (`mcabal install`, checks two properties) |

## Portability rules visible in the code

- Every non-Haskell-2010 feature is guarded by a `NO_...` CPP macro set in
  `QuickCheck.cabal` (`NO_TIMEOUT`, `NO_GENERICS`, `NO_TYPEABLE`,
  `NO_TEMPLATE_HASKELL`, `NO_SPLITMIX`, ...). New features need a guard if
  they use extensions Hugs or MicroHs lack.
- `make-hugs` lists the macros used for Hugs; its comment invites patches
  that add new `-DNO_...` flags.
- Some code has MicroHs-specific branches (for example `abstract` in
  `Function.hs`, marked as a temporary type-checker workaround).
- Safe Haskell: most public modules are `Safe` or `Trustworthy` (2.18 made
  `Test.QuickCheck.Function` `Trustworthy`).

## Versioning and changelog

`changelog.md` has an `UNRELEASED` section at the top; releases record a
date and mark breaking changes with "BREAKING". The package version
follows PVP-style numbering (2.19.0.0). Inconsistency at 2.19: the cabal
file's `source-repository this` still names tag `2.18`.

## Sensitive areas

- **Seed and size sequences**: `computeSize` warns that a test depends on
  the exact sequence; changing seeds or sizes changes every user's
  recorded replay seeds (documented as unsupported across versions, but
  visible).
- **Output text**: test frameworks and users parse or match QuickCheck's
  messages (hspec, tasty-quickcheck, the Hugs/MHS scripts' `grep`).
- **Instances**: adding `Arbitrary`/`CoArbitrary`/`Function` instances for
  `base` types is breaking for packages that define orphans (2.17 and 2.18
  changelogs mark this as BREAKING); `quickcheck-instances` provides
  instances for other packages.
- **Shrinking behaviour**: changing default shrinkers changes users'
  counterexamples and can introduce loops; `prop_no_shrinking_loop_*` in
  `tests/Generators.hs` guards termination.

## Unreleased work

The remote had feature branches (for example `PR-suchThatDiscard`,
`PR-tabulate-performance`, `PR-fix-table-coverage`) at access time. They
were not examined for this pack.
