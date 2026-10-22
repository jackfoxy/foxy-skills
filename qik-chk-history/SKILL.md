---
name: qik-chk-history
description: The history, research background, and ecosystem of QuickCheck - the Chalmers QuickCheck 1 (Claessen and Hughes, ICFP 2000), the 2002 monadic testing paper, How to Specify It!, the QuickCheck 2 release history from 2.5 to 2.19 with breaking changes and migration of old code (cover argument order, printTestCase, withMaxSuccess, once for unquantified properties), Quviq's Erlang QuickCheck, PropEr, ports to other languages, and Haskell companions and alternatives (quickcheck-instances, SmallCheck, Hedgehog). Use when someone asks where QuickCheck came from, which version introduced or changed something, how to update old QuickCheck code or tutorials, which paper to read, or how QuickCheck relates to Hypothesis, ScalaCheck, Hedgehog, Quviq, or other property-testing tools.
user-invocable: true
disable-model-invocation: false
---

# QuickCheck history and ecosystem

**Scope:** what came before 2.19, and what exists beside it. Current
behaviour is documented in the other skills; this one explains versions,
papers, and relatives, and keeps them clearly separated from current
Haskell QuickCheck.

**Prerequisites:** none; [qik-chk-foundations](../qik-chk-foundations/SKILL.md)
helps.

**Version:** current = QuickCheck 2.19.0.0 (2026-09-16). Sources accessed
2026-10-20; see the
[source manifest](../qik-chk-overview/references/source-manifest.md).

## Four things called QuickCheck

| Name | What it is | Status in this pack |
|---|---|---|
| QuickCheck 1 | Claessen and Hughes's original Haskell module (Chalmers, 2000), `QuickCheck.hs` and the online manual | read from the Chalmers page; historical |
| QuickCheck 2 | the `QuickCheck` package on Hackage, `github.com/nick8325/quickcheck`; this pack documents 2.19.0.0 | read, built, tested, executed |
| Quviq QuickCheck | commercial Erlang tool by Quviq | mentioned only; not examined |
| Ports | independent libraries in other languages (ScalaCheck, Hypothesis, FsCheck, ...) | mentioned only; not examined |

## Key changes when reading old material

| You see | Today | Since |
|---|---|---|
| `cover b 10 "s"` (condition first) | `cover 10 b "s"` | 2.12 |
| `printTestCase` | `counterexample` | 2.7 |
| `morallyDubiousIOProperty` | `ioProperty` | 2.7 |
| `withMaxSuccess` | `withNumTests` | 2.18 deprecation |
| `quickCheck True` runs once | runs 100 tests; use `once` | 2.15 |
| multi-argument properties shrinking one argument at a time | arguments shrink jointly as a tuple | 2.13 |
| `Config`, `check`, `coarbitrary` in `Arbitrary`, no shrinking, "Falsifiable" | QuickCheck 1 | before QuickCheck 2 |
| orphan `Arbitrary`/`CoArbitrary`/`Function` instances for `base` types | now in QuickCheck; remove them | 2.17, 2.18 |
| `Test.QuickCheck.Gen.Class` | removed | 2.17 |
| `StdGen` seeds | splitmix `SMGen` seeds (`QCGen`) | 2.13 |

Full release table and QuickCheck 1 versus 2 mapping:
[references/timeline.md](references/timeline.md).

## Which paper to read

| Goal | Paper | Read for this pack |
|---|---|---|
| Original design and rationale | Claessen, Hughes: *QuickCheck: A Lightweight Tool for Random Testing of Haskell Programs* (ICFP 2000) | yes |
| Testing monadic and imperative code | Claessen, Hughes: *Testing Monadic Code with QuickCheck* (Haskell Workshop 2002) | yes |
| Writing good properties | Hughes: *How to Specify It!* (LNCS 12053, 2020) | yes |
| Function generation and shrinking | Claessen: *Shrinking and showing functions* (Haskell Symposium 2012) | no: ACM DL returned 403 |
| Industrial experience | Hughes: *Experiences with QuickCheck* (2016) | no |

Summaries and section maps: [references/papers.md](references/papers.md).

## Relatives

Haskell companions (`quickcheck-instances`, test-framework integrations,
state-machine libraries), alternatives (SmallCheck, Hedgehog, SmartCheck),
Erlang (Quviq, PropEr), and other languages:
[references/ecosystem.md](references/ecosystem.md). All are labelled by
how they were sourced; none except tasty-quickcheck and hspec was run.

## Pitfalls

- **Old tutorials** use pre-2.12 coverage functions, QuickCheck 1 names,
  or behaviour (`once` wrapping, per-argument shrinking) that has changed.
  Check against [qik-chk-api-index](../qik-chk-api-index/SKILL.md).
- **Ports differ.** Shrinking strategy, size schedules, statistics, and
  output in other libraries are not those of Haskell QuickCheck.
- **Quviq features** (for example `eqc_statem`, PULSE) are not part of
  Haskell QuickCheck.
- **Changelog BREAKING entries** in 2.15, 2.17 and 2.18 affect existing
  suites: unquantified properties, new instances clashing with orphans.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `cover` call does not type-check | pre-2.12 argument order | `cover pct cond label` |
| `printTestCase`, `morallyDubiousIOProperty` deprecation warnings | renamed in 2.7 | `counterexample`, `ioProperty` |
| Duplicate instance errors after upgrading | 2.17/2.18 added instances for `base` types | delete the orphan instances |
| A tutorial's `quickCheck True` output differs | 2.15 runs unquantified properties 100 times | expected |

## Go deeper

- [references/timeline.md](references/timeline.md): QuickCheck 1, the
  repository's history, every 2.x release with highlights, migration.
- [references/papers.md](references/papers.md): papers read and not read.
- [references/ecosystem.md](references/ecosystem.md): companions,
  alternatives, Quviq, ports.
