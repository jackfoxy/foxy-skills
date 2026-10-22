# Validation report

Companion to [qik-chk-overview](../SKILL.md). What was checked for the
qik-chk pack, how, and with what result; then what was not checked.
Date: 2026-10-20. Toolchain and versions: see the
[source manifest](source-manifest.md). Evidence files (`evidence/...`)
are in the research scratch area, not in the pack; their content is
summarised here.

Environment used by the commands below:

```bash
export PATH=$HOME/.ghcup/bin:$PATH
export LIBRARY_PATH=$HOME/.ghcup/gmp-shim   # libgmp.so -> libgmp.so.10 (no libgmp-dev)
```

## Contents

- [Upstream build and tests](#upstream-build-and-tests)
- [Upstream examples and unwired tests](#upstream-examples-and-unwired-tests)
- [Pack examples](#pack-examples)
- [Snippets in references](#snippets-in-references)
- [Framework and package integration](#framework-and-package-integration)
- [Behaviour probes](#behaviour-probes)
- [API index](#api-index)
- [Skill metadata, naming, links, scripts](#skill-metadata-naming-links-scripts)
- [Checks not run](#checks-not-run)
- [Authored versus executed](#authored-versus-executed)

## Upstream build and tests

In a clean clone at `3d8fe868`:

```bash
cabal build all --enable-tests
cabal test all
```

Result: all **13 of 13** test suites `PASS` (`test-quickcheck`,
`-gcoarbitrary`, `-generators`, `-gshrink`, `-terminal`, `-monadfix`,
`-split`, `-strictness`, `-misc`, `-discard`, `-monoids`,
`-withprogress`, `-instances`). The first build failed with `cannot find
-lgmp`, fixed by the `LIBRARY_PATH` shim.

## Upstream examples and unwired tests

| What | Command | Result |
|---|---|---|
| `examples/*.hs` (7 files) | `ghc -package-env ENV -O0` each, run once | `Set`, `Lambda`, `Heap`, `Heap_ProgramAlgebraic`: exit 0; `Simple`, `Merge`, `Heap_Program`: exit 1 by design (deliberate failures, `True <- $quickCheckAll`). Details: [upstream-examples.md](../../qik-chk-applications/references/upstream-examples.md) |
| `tests/ShrinkMap.hs` | `ghc -O1`, run | passed 100 tests |
| `tests/TestRandom.hs` | `ghc -O1 -package random`, run | exit 0 in 11 s (no split-quality property falsified) |
| `tests/Weird.hs` | - | **not run**: contains properties that loop forever without a timeout |

## Pack examples

Setup once: `qik-chk-workflow/scripts/run-examples.sh --setup`.

| Check | Command | Result |
|---|---|---|
| Full harness, run 1 | `qik-chk-workflow/scripts/run-examples.sh` | 25 files, 119 declared outcomes, all as expected, exit 0, 62 s |
| Full harness, run 2 | same | 24 as expected, **1 mismatch**: `ReplayAndResults.hs` "discard ratio 1" (a ~50% condition raced the ratio). Fixed by using a rarer condition; the fixed file then passed 100 of 100 runs |
| Full harness, run 3 | same | 25 files, all as expected |
| Stability sweep, 20 runs per file | scratch `stability.sh 20` | 24 files 20/20; `Combinators.hs` 16/20 ("an exception is a failure" needed input `n == 5`). Fixed (divisor zero for a third of inputs); then 100/100 |
| Stability sweep, 50 runs per file (after both fixes) | scratch `stability.sh 50` | all 25 files 50/50 (1250 runs) |
| Final full harness run (after all edits) | `run-examples.sh` | 25 files, 119 outcomes, all as expected, exit 0, 61 s |

Every example declares `Pass`, `Fail`, `GiveUp`, `NoExpected`, or a
predicate on `Result` for each property; deliberate failures therefore
count as success, and a different outcome counts as a regression. Seeded
expectations (`checkSeeded`) hold for QuickCheck 2.19.0.0 with splitmix
0.1.3.2.

Manual examples (not run by the harness), run by hand:

| Example | Result |
|---|---|
| `qik-chk-running/examples/manual/WithinTightLoop.hs` | `-O0`: `Timeout of 200000 microseconds exceeded`; `-O2`: hung, killed by `timeout 15` (exit 124); `-O2 -fno-omit-yields`: timeout reported |
| `qik-chk-workflow/examples/hspec/HspecSpec.hs` | separate package environment with hspec 2.11.18: 4 examples, 1 deliberate failure, exit 1; rerun with the printed `--match ... --seed 1489698406` reproduced the failure |
| `qik-chk-workflow/examples/cabal-project/` (copied to scratch) | `cabal test --test-show-details=direct`: suite PASS, exit 0; with a seeded bug in `decode`: counterexample `[False,False,False]`, suite FAIL, exit 1 |

## Snippets in references

Template code blocks were collected into two scratch modules with stubs
for the user code they assume, compiled, and run:

| Module | Covers | Result |
|---|---|---|
| `Templates.hs` | generators (SKILL, recipes 0-7), shrinking (Tree shrinker; `shrinkIntegral` formula, checked equal to `shrink` on 100 random `Int`s), functions (`prop_mapFusion`), monadic-state (`prop_bump`, `genCmds` variants), property-catalog (5 templates), coverage-statistics, workflow regression snippet | 23 properties run, 23 successful |
| `Applications.hs` | domain-recipes: model property, `approxEq`, well-typed `genE` (checked to produce well-typed terms), differential property | 4 properties, all successful |

Not compiled: schematic fragments (`...` bodies, single expressions,
type declarations quoted from the source, the TH template in running), and
the tasty/hspec snippets in `integration.md`, which are near copies of the
executed `TastySuite.hs` and `HspecSpec.hs`.

## Framework and package integration

| Check | Result |
|---|---|
| tasty-quickcheck 0.11.1 `--help` | option list recorded in [integration.md](../../qik-chk-workflow/references/integration.md) |
| `TastySuite.hs` | passing tree exit 0, failing tree non-zero with replay token |
| hspec 2.11.18 `--help`, `:browse Test.Hspec.QuickCheck` | `prop`, `fprop`, `xprop`, `modify*` confirmed |

## Behaviour probes

Short programs or GHCi sessions whose output is quoted in the skills:

| Probe | Result used in |
|---|---|
| Size schedule via `getSize` (20 and 250 tests) | running (size-and-seeds) |
| `show (mkQCGen 42)`, `stdArgs`, replay token | running |
| Unquantified properties (`True`, `Discard`, `Nothing`) | properties, history |
| Shrink candidates of standard types | shrinking |
| Output forms (exception, assertion, gave up, expected failure, timeout, classes) | running (result-fields) |
| Stack overflow under `+RTS -K1m` aborts the run | debugging |
| `verboseCheck` on a looping property shows no input | debugging |
| `error` in a generator | debugging |
| `within` at `-O0`/`-O2`/`-fno-omit-yields` | running, debugging |

## API index

| Check | Result |
|---|---|
| `qik-chk-api-index/scripts/browse-api.sh` | 18 modules browsed, 339 distinct exported names, **0 missing** from the index, exit 0 |
| Negative test (index copy without `shrinkIntegral`) | reported `MISSING Test.QuickCheck shrinkIntegral` and `... Arbitrary shrinkIntegral`, exit 1 |
| Permalinks (scratch `check_permalinks.py`) | 537 GitHub links: correct commit, existing path and line; for all 530 index rows the symbol occurs within two lines of the linked line. Three `<path>` placeholders in prose are not links |

## Skill metadata, naming, links, scripts

| Check | Result |
|---|---|
| Directory names | all 16 start with `qik-chk-`; frontmatter `name` equals the directory |
| skill-creator `quick_validate` | flags `user-invocable` and `disable-model-invocation` as unexpected keys (the same as the repository's existing `tla-lus-*` skills, which use them by convention); with those two keys removed in a scratch copy, all 16 are valid (after removing angle brackets from three descriptions) |
| Frontmatter values | `user-invocable: true`, `disable-model-invocation: false` in all 16 |
| `agents/openai.yaml` | 16 files parse as YAML with `display_name`, `short_description`, `default_prompt` |
| Relative links and anchors (scratch `check_links.py`) | 1136 relative links checked (files and `#anchors`), 0 broken; a negative test with one bad anchor and one missing file reported both |
| `bash -n` on both scripts | ok |
| SKILL.md length | 86 to 205 lines (all under 500) |

## Checks not run

- **Hugs and MicroHs** builds (`test-hugs`, `test-mhs`): compilers not
  installed.
- **Other GHC versions**, the upstream CI matrix, stack builds, macOS,
  Windows, non-x86 platforms.
- **`tests/Weird.hs`**: deliberately non-terminating.
- **shellcheck**: not installed.
- **Live fetch of external URLs** in the pack: not re-fetched after the
  research phase; Hackage package links for companion libraries were never
  fetched.
- **Third-party libraries** other than tasty, tasty-quickcheck, hspec.
- **Installing the skills** into `~/.claude/skills` or elsewhere: not done
  by request.
- **Skill triggering evaluations** (skill-creator eval loop): not run.
- **Browser or UI checks**: not applicable.

## Authored versus executed

| Kind | Executed |
|---|---|
| 25 harness examples (all authored for the pack) | yes, repeatedly |
| 3 manual examples (authored) | yes, by hand |
| Reference templates | 27 compiled and run via scratch modules; schematic fragments not compiled |
| Upstream examples and tests | run as listed above (except `Weird.hs`) |
| Statements about QuickCheck 1, papers, ecosystem | source reading only (not executable) |
| Statements about Hugs/MicroHs behaviour | source reading only |
