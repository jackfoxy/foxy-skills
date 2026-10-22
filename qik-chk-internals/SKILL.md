---
name: qik-chk-internals
description: How QuickCheck 2.19 works inside and how to work on it - the Gen representation (seed and size function, seed splitting, variant, promote), rose trees, Prop, Property and Testable, the per-test Result record, the runner State and test loop, computeSize, the greedy localMin shrink search, coverage statistics, exception and discard handling, terminal output, the Fun and InfiniteList partial-value tricks, CPP feature flags for Hugs and MicroHs, Haddock-hidden but exposed modules (Property, Test, Random, State, Exception, Text, Features), the upstream test suites and what they cover, CI, and contribution practice. Use when someone asks why QuickCheck behaves a certain way at the implementation level, wants to write a custom combinator against internals, debug QuickCheck itself, contribute upstream, or port it.
user-invocable: true
disable-model-invocation: false
---

# QuickCheck internals

**Scope:** implementation and upstream development. User-level behaviour
is documented in the other skills; this one explains why it happens.

**Prerequisites:** [qik-chk-generators](../qik-chk-generators/SKILL.md),
[qik-chk-shrinking](../qik-chk-shrinking/SKILL.md),
[qik-chk-running](../qik-chk-running/SKILL.md).

**Version:** QuickCheck 2.19.0.0, commit
`3d8fe8686024760006ca1ca656cbdd82cd71f11e` (tag `2.19`, also `master` on
2026-10-20). Internal modules have no stability promise; check the source
for the version you use.

## The model in one paragraph

A `Gen a` is a function from a seed (`QCGen`, splitmix) and a size to a
value; `>>=` splits the seed. A `Property` is a `Gen Prop`, and a `Prop`
is a lazy rose tree of per-test `Result`s whose children are the results
for shrink candidates. The runner draws a seed and a size per test,
evaluates the root, and on failure walks the tree greedily: the first
failing child becomes the new counterexample. Everything else (labels,
coverage, per-property settings, callbacks for printing) rides along in
the `Result` record. Full walk-through:
[references/architecture.md](references/architecture.md).

## Where things are

| Question | Look at |
|---|---|
| How is a value generated from a seed? | `Gen.hs` (`Gen`, `>>=`, `variant`), `Random.hs` (`QCGen`, `integerVariant`) |
| What does a property evaluate to? | `Property.hs` (`Property`, `Prop`, `Rose`, `Result`, `Testable`) |
| How are multi-argument properties shrunk? | `Property.hs` L172: the function instance pairs arguments |
| What size does test *n* get? | `Test.hs` `computeSize` (L240) |
| Why did shrinking stop? | `Test.hs` `localMin` (L604): local minimum or `maxShrinks` |
| When does `checkCoverage` decide? | `Test.hs` `timeToCheckCoverage` (L330), `sufficientlyCovered` (L666) |
| Why did Ctrl-C / stack overflow abort? | `Exception.hs` `tryEvaluateIO` rethrows asynchronous exceptions |
| How is `discard` implemented? | `Exception.hs`: a private `ErrorCall` recognised by `isDiscard` |
| Why does a `Fun` print `<fun>`? | `Function.hs`: unshrunk functions are not printed |
| What is hidden from Haddock? | `Property`, `Test`, `Features`, `Random`, `State`, `Exception`, `Text`: `OPTIONS_HADDOCK hide` but exposed; public parts re-exported by `Test.QuickCheck` |

Every public and hidden-module symbol, with signature and source link:
[qik-chk-api-index](../qik-chk-api-index/SKILL.md).

## Writing code against internals

- **Custom quantifiers**: build them from `forAllShrinkShow` or
  `shrinking` instead of constructing `Rose` trees by hand; hand-built
  trees must be protected against exceptions (`protectRose`), which
  `tests/Weird.hs` notes as a pitfall.
- **Running a generator directly**: `unGen g (mkQCGen n) size` needs
  `Test.QuickCheck.Gen` (the main module exports `Gen` abstractly) and
  `Test.QuickCheck.Random`.
- **Per-property options**: combinators set `maybeNumTests`, ... on every
  result in the tree with `mapTotalResult`; follow the pattern of
  `withNumTests`.
- **Progress and tooling**: prefer `withProgress` (2.16) and `callback`
  with `PostTest`/`PostFinalFailure` over patching the loop.

Executed: [GenInternals.hs](examples/GenInternals.hs) shows that
`return x >>= f` and `f x` differ seed by seed but agree in distribution,
`variant` independence, `promote`, and the size schedule.

## Working on QuickCheck

Build with `cabal build all --enable-tests`, test with `cabal test all`
(13 suites; all passed for this pack with GHC 9.10.3). CI covers GHC 8.10
to 9.14 with cabal and stack, plus Hugs and MicroHs smoke tests. Guard new
features with `NO_...` macros for compilers that lack the extensions.
Details: [references/contributing.md](references/contributing.md). What
each test suite establishes, files not wired into cabal, and untested
behaviour: [references/upstream-tests.md](references/upstream-tests.md).

## Pitfalls

- Internal modules change between versions (2.17 removed `Gen.Class`);
  pin the version when depending on them.
- Seeds and sizes are part of observable behaviour: a change to splitting
  or `computeSize` changes every replay.
- `Test.QuickCheck.Property.Result` and `Test.QuickCheck.Test.Result` are
  different types with overlapping field names (`reason`,
  `theException`, `labels`); import qualified.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `cabal test all` fails building `test-quickcheck-instances` | needs `hint`, `split`; not buildable on GHC 8.10 | install the dependencies or skip that suite |
| Link error `cannot find -lgmp` | no libgmp development symlink | install `libgmp-dev` or set `LIBRARY_PATH` |
| A change breaks `prop_discardCoverage` | it depends on the exact size sequence | keep `computeSize` behaviour or update the test deliberately |
| A new feature breaks the Hugs build | missing `NO_...` guard | add a CPP guard and a `make-hugs` flag if needed |

## Go deeper

- [references/architecture.md](references/architecture.md): module map,
  seeds, Gen, rose trees, Testable, Result, test loop, shrinking, coverage,
  exceptions, terminal, partial-value tricks, CPP flags.
- [references/upstream-tests.md](references/upstream-tests.md): the 13
  cabal suites, unwired test files, Hugs/MHS scripts, and gaps.
- [references/contributing.md](references/contributing.md): build, CI,
  portability rules, changelog, sensitive areas.
