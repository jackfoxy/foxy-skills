# Coverage ledger

Companion to [qik-chk-overview](../SKILL.md). Inventory of the source
material against where the pack covers it. Evidence codes:

- **S**: read in source at commit `3d8fe868`
- **X**: executed (example, probe, or upstream test) with GHC 9.10.3
- **P**: from a paper or the Chalmers material
- **M**: mentioned only, not examined

Statuses: **covered**, **summarised** (described, not taught in depth),
**excluded** (out of scope by decision), **inaccessible**, **unresolved**
(in scope, not done). This pack is **not exhaustive**: see
[Unresolved](#unresolved) and [Inaccessible](#inaccessible).

## Contents

- [Modules](#modules)
- [Exported API](#exported-api)
- [Upstream tests](#upstream-tests)
- [Upstream examples](#upstream-examples)
- [Build, CI, and portability files](#build-ci-and-portability-files)
- [Changelog](#changelog)
- [Chalmers material](#chalmers-material)
- [Papers](#papers)
- [Concepts](#concepts)
- [Use cases](#use-cases)
- [Excluded](#excluded)
- [Inaccessible](#inaccessible)
- [Unresolved](#unresolved)

## Modules

| Module | Evidence | Destination | Status |
|---|---|---|---|
| `Test.QuickCheck` | S X | api-index (main), every skill | covered |
| `Test.QuickCheck.Gen` | S X | generators, internals | covered |
| `Test.QuickCheck.Gen.Unsafe` | S X | generators, internals (`promote` in GenInternals) | covered |
| `Test.QuickCheck.Arbitrary` | S X | generators (default-instances), shrinking (shrinkers) | covered |
| `Test.QuickCheck.Modifiers` | S X | generators, shrinking, properties | covered |
| `Test.QuickCheck.Function` | S X | functions | covered |
| `Test.QuickCheck.Property` | S X | properties (combinator-semantics), internals | covered |
| `Test.QuickCheck.Test` | S X | running (result-fields, size-and-seeds), internals | covered |
| `Test.QuickCheck.Monadic` | S X | monadic-state | covered |
| `Test.QuickCheck.Poly` | S | properties | covered |
| `Test.QuickCheck.Monoids` | S | properties | covered (no pack example; upstream suite passes) |
| `Test.QuickCheck.Features` | S X | distribution (`labelledExamples`) | covered |
| `Test.QuickCheck.All` | S X | running (AllProperties.hs), workflow | covered |
| `Test.QuickCheck.Random` | S X | running (size-and-seeds), internals | covered |
| `Test.QuickCheck.State` | S | internals, running (`TestProgress`) | covered |
| `Test.QuickCheck.Exception` | S X | internals, debugging | covered |
| `Test.QuickCheck.Text` | S | internals | summarised |
| `Test.QuickCheck.Compat` | S | internals, api-index | summarised |

## Exported API

| Item | Evidence | Destination | Status |
|---|---|---|---|
| 339 distinct exported top-level names across 18 modules | S X (`browse-api.sh`: 0 missing) | api-index: 530 rows in 3 files, each with owner skill and permalink | covered |
| Signatures | X (GHCi `:browse`, GHC 9.10.3) | api-index | covered |
| Permalinks | S (537 checked offline: path, line, and for all 530 rows the symbol within two lines) | api-index, references | covered |
| Constructors and class methods | S | inside their type's row | covered (not checked separately by the script) |
| Deprecations (`withMaxSuccess`, `printTestCase`, `(><)`, `morallyDubiousIOProperty`) | S | api-index, history | covered |
| Instance lists (208 `Arbitrary`, 89 `CoArbitrary`, 87 `Function` heads) | S | generators (default-instances), functions | summarised (families, not every head) |

## Upstream tests

| File | Evidence | Destination | Status |
|---|---|---|---|
| 13 cabal suites (`examples/Heap.hs`, `GCoArbitraryExample`, `Generators`, `GShrinkExample`, `Terminal`, `MonadFix`, `Split`, `Strictness`, `Misc`, `DiscardRatio`, `Monoids`, `WithProgress`, `RunCollectDataTypes`+`CollectDataTypes`) | S X (13/13 PASS) | internals (upstream-tests) | covered |
| `tests/ShrinkMap.hs` | S X (pass) | internals | covered |
| `tests/TestRandom.hs` | S X (exit 0, 11 s) | internals | covered |
| `tests/Weird.hs` | S | internals | covered by reading; **not run** (deliberate infinite loops) |
| `test-hugs`, `test-mhs` | S | internals (contributing) | read; not run (no Hugs/MicroHs) |

## Upstream examples

| File | Evidence | Destination | Status |
|---|---|---|---|
| `Simple.hs`, `Merge.hs`, `Set.hs`, `Lambda.hs`, `Heap.hs`, `Heap_Program.hs`, `Heap_ProgramAlgebraic.hs` | S X (all compiled and run; exit codes recorded) | applications (upstream-examples), monadic-state (stateful-testing) | covered |

## Build, CI, and portability files

| File | Evidence | Destination | Status |
|---|---|---|---|
| `QuickCheck.cabal` | S X | workflow (compatibility), internals | covered |
| `.github/workflows/haskell-ci.yml`, `hugs-ci.yml`, `microhs-ci.yml` | S | internals (contributing) | covered (CI not run; equivalent `cabal build/test all` run locally on one GHC) |
| `make-hugs` | S | internals | covered |
| `README`, `LICENSE` | S | history (ecosystem), source-manifest | covered |
| `changelog.md` | S | history (timeline) | covered |

## Changelog

| Range | Evidence | Destination | Status |
|---|---|---|---|
| 2.5 to 2.19 headline changes | S | history (timeline) | covered for minor releases (2.x); point releases summarised |
| BREAKING entries (2.15, 2.17, 2.18) | S X (2.15 unquantified behaviour measured) | history, properties, generators | covered |

## Chalmers material

| Item | Evidence | Destination | Status |
|---|---|---|---|
| Page `index.html` | P | history | covered |
| Manual (frames) | P | history, distribution, foundations | covered (as QuickCheck 1 documentation) |
| `QuickCheck.hs` (QC1) | P | history (QC1 vs QC2 table) | covered |
| `QuickCheckM.hs` | P | history, monadic-state | summarised |
| `ShowFunctions.hs` | P | history, functions | covered |
| `randoms.html` | P | history (split independence) | covered |
| `quickcheck` script | - | - | **inaccessible** (404) |

## Papers

| Paper | Sections | Evidence | Destination | Status |
|---|---|---|---|---|
| ICFP 2000 | 1-4, 6, 7 | P | foundations (theory), generators, functions, distribution, internals | covered |
| ICFP 2000 | 5 case studies (unification, Lava circuits, Stålmarck, pretty printing, Edison) | P | history (papers) | summarised (not reproduced as examples) |
| Haskell Workshop 2002 | all | P | monadic-state (stateful-testing) | covered |
| *How to Specify It!* | all, including measured effectiveness and appendix of metamorphic properties | P X (SpecStyles.hs reproduces the approach on a pack-written BST) | property-design | covered |
| *Shrinking and showing functions* (2012) | - | - | functions (from source only) | **inaccessible** |
| Others cited (SmallCheck, SmartCheck, targeted PBT, PropEr, Quviq telecoms, *Experiences with QuickCheck*) | - | M | history (papers, ecosystem) | listed, not read |

## Concepts

| Concept | Evidence | Destination |
|---|---|---|
| Properties as executable specifications; random testing rationale; oracle problem | P | foundations |
| Specification styles and their effectiveness | P X | property-design |
| Vacuity, `()` defaulting, tautologies, weak properties | X | property-design, debugging |
| `Testable`, quantification, implication, discard, conjunction/disjunction semantics | S X | properties |
| Size, `sized`, `resize`, `scale`, size schedule (`computeSize`) | S X | generators, running |
| Seeds, splitting, `variant`, prefix-free code, replay limits | S X | running, internals |
| Default generator distributions (Int, Char, Double, lists, Maybe, ...) | S X | generators (default-instances) |
| Filtering vs construction; `suchThat` behaviour | S X | generators, debugging |
| Shrinking: greedy search, local minima, joint shrinking, nested quantifiers, invariant preservation, dependent shrinking | S X | shrinking |
| Function generation and shrinking, `<fun>` display | S X | functions |
| Coverage statistics (Wilson interval, check points, `Confidence`) | S X | distribution |
| Timeouts and their limits (asynchronous exceptions, non-allocating loops) | S X | running, debugging |
| Exceptions: synchronous vs asynchronous, stack overflow, show-time exceptions, generator errors | S X | debugging, internals |
| Laziness and `total` | S X | running, debugging |
| Monadic properties, `PropertyM`, ST | S P X | monadic-state |
| Model-based stateful testing, observational equivalence | P X | monadic-state |
| Template Haskell discovery | S X | running, workflow |
| Framework integration (tasty, hspec), cabal suites | X | workflow |
| Regression capture | X | workflow |
| Portability (CPP flags, Hugs, MicroHs) | S | internals, workflow |

## Use cases

| Use case | Evidence | Destination |
|---|---|---|
| Data structures (heap, BST, set) | X | applications, property-design |
| Printers/parsers | X | applications |
| Floating point and integer overflow | X | applications, workflow |
| Interpreters, typed term generation | X (snippet) S (upstream Lambda.hs run) | applications |
| Sorting and merging | X | property-design, applications |
| Stateful API (queue in IORef) | X | monadic-state |
| IO properties, exceptions | X | monadic-state |
| CI suites | X | workflow |
| Concurrency, linearizability | M | monadic-state (stateful-testing) — **not executed** |
| Databases, network services | - | applications, monadic-state — guidance only, **not executed** |

## Excluded

| Item | Reason |
|---|---|
| Quviq QuickCheck (Erlang), PropEr, ports in other languages | out of scope (separate products); mentioned for orientation |
| Third-party Haskell libraries other than tasty-quickcheck and hspec (`quickcheck-state-machine`, `quickcheck-dynamic`, `quickcheck-instances`, generic-random, ...) | out of scope; mentioned only |
| `%quiz` | explicitly broader scope requested; not documented; not modified |
| Copying upstream documentation or code | copyright; summarised and cited instead |

## Inaccessible

| Source | Attempt | Effect |
|---|---|---|
| Chalmers `quickcheck` script | HTTP 404 | its behaviour described from the page text only |
| `http://www.md.chalmers.se/~koen/Papers/quick.ps` | DNS failure | used the Tufts mirror PDF of the same paper |
| Moertel ICFP 2001 story | domain parked | not used |
| Claessen, *Shrinking and showing functions* | ACM DL HTTP 403 | `Function` documented from source and execution only |

## Unresolved

In scope, not done; each is a known gap.

| Gap | Why | Impact |
|---|---|---|
| Hugs and MicroHs builds | compilers not available | portability statements rest on cabal file, CI files, and scripts |
| Other GHC versions (8.10 to 9.14) and other OS/architectures | one toolchain | measured behaviours (for example `within` at `-O2`) may differ |
| GitHub issues, pull requests, discussions, remote branches | not examined | design rationale beyond source comments and changelog may be missing |
| Rendered Haddock on Hackage | not fetched; documentation read from source comments | formatting differences only, expected |
| Upstream CI matrix | not run | local single-GHC run only |
| Every `Arbitrary` instance head (208) individually | summarised by family | an unusual instance's behaviour may be undocumented |
| Concurrency testing in practice | no example | guidance only |
| `Test.QuickCheck.Text` table formatting details | summarised | affects only output appearance |
| Performance characteristics (generator and shrink cost at scale) | not measured beyond the examples | advice is qualitative |
