---
name: qik-chk-overview
description: Entry point and router for the qik-chk skills on Haskell QuickCheck (version 2.19.0.0) - what the pack covers, which qik-chk skill answers which question, learning paths for beginners, experienced testers, debugging, advanced generators and shrinking, stateful testing, project integration and upstream work, plus the pack's source manifest, coverage ledger, and validation report. Use first for any QuickCheck or Haskell property-based testing question when it is not obvious which qik-chk skill applies, when someone wants to learn QuickCheck, asks what the pack can do, or asks how the pack's claims were verified.
user-invocable: true
disable-model-invocation: false
---

# QuickCheck skills: start here

**Scope:** Haskell QuickCheck 2.19.0.0 (`nick8325/quickcheck`, commit
`3d8fe868`), its history, research background, and integration. Other
property-testing libraries (Quviq, Hypothesis, Hedgehog, %quiz, ...) are
mentioned only for orientation in
[qik-chk-history](../qik-chk-history/references/ecosystem.md).

**Prerequisites:** basic Haskell (types, type classes, `do` notation).

## What the pack offers

- 16 skills, each with a `SKILL.md` procedure and references, and runnable
  examples in 13 of them (25 harness-run example files with 119 declared
  outcomes, plus three manual ones: a `-O2` timeout demonstration, an
  hspec spec, and a cabal package), including deliberately failing ones that show
  weak properties, bad generators and shrinkers, discards, coverage
  failures, replay, and timeouts.
- An API index giving every symbol exported by every exposed module a
  row with signature, purpose, owner skill, and source permalink.
- Claims checked against source at a pinned commit, the upstream test
  suite (13 of 13 passed), and execution with GHC 9.10.3. What was and
  was not verified: [validation report](references/validation-report.md);
  what is covered and what is not: [coverage ledger](references/coverage-ledger.md).

**Limits:** behaviour is documented for 2.19.0.0 with splitmix 0.1.3.2;
seeds, sizes, shrink results, and message text can differ in other
versions. Framework integrations were run for tasty-quickcheck and hspec
only. Hugs and MicroHs were not run. Third-party libraries, ports, and
Quviq QuickCheck are described from their mentions, not examined.

## Route a request

| The user wants to... | Skill |
|---|---|
| understand what QuickCheck is, write a first property | [qik-chk-foundations](../qik-chk-foundations/SKILL.md) |
| decide what properties to write; strengthen a weak one | [qik-chk-property-design](../qik-chk-property-design/SKILL.md) |
| know exactly what `==>`, `forAll`, `.&&.`, `.||.`, `===`, `once`, `expectFailure`, `witness` do | [qik-chk-properties](../qik-chk-properties/SKILL.md) |
| write a generator or `Arbitrary` instance; use modifiers; control size | [qik-chk-generators](../qik-chk-generators/SKILL.md) |
| write `shrink`; understand why a counterexample is not minimal | [qik-chk-shrinking](../qik-chk-shrinking/SKILL.md) |
| quantify over functions (`Fun`, `Function`, `CoArbitrary`) | [qik-chk-functions](../qik-chk-functions/SKILL.md) |
| see or enforce what was tested (`label`, `cover`, `checkCoverage`) | [qik-chk-distribution](../qik-chk-distribution/SKILL.md) |
| run properties; set test counts; replay a seed; add timeouts; read `Result` | [qik-chk-running](../qik-chk-running/SKILL.md) |
| add QuickCheck to a project, tasty, hspec, CI; save regressions | [qik-chk-workflow](../qik-chk-workflow/SKILL.md) |
| understand a surprising result: gave up, passes wrongly, hangs, flaky | [qik-chk-debugging](../qik-chk-debugging/SKILL.md) |
| test IO, ST, or a stateful API against a model | [qik-chk-monadic-state](../qik-chk-monadic-state/SKILL.md) |
| property-test a parser, data structure, numeric code, interpreter | [qik-chk-applications](../qik-chk-applications/SKILL.md) |
| look up a function, type, module, or deprecation | [qik-chk-api-index](../qik-chk-api-index/SKILL.md) |
| understand the implementation; contribute upstream | [qik-chk-internals](../qik-chk-internals/SKILL.md) |
| know which version changed something; update old code; find papers; compare with other tools | [qik-chk-history](../qik-chk-history/SKILL.md) |

Several skills often apply; the
[skill map](references/skill-map.md) lists ownership boundaries (for
example "fix a skewed generator" is generators, "measure the skew" is
distribution).

### Sample requests and their routes

| Request | Route |
|---|---|
| "How do I start testing my Haskell functions with QuickCheck?" | foundations → properties → property-design |
| "My property says Gave up! after 30 tests." | debugging (gave up) → generators (construct instead of filter) |
| "quickCheck passes but my sort is obviously broken." | property-design (weak properties) → distribution |
| "The counterexample is a 200-element list." | debugging → shrinking |
| "How do I test a function that takes a function argument?" | functions |
| "Make CI fail if fewer than 10% of tests hit the empty case." | distribution (`cover` + `checkCoverage`) → workflow |
| "Reproduce a failure CI printed with a seed." | running (replay) → workflow (tasty/hspec tokens) |
| "Test my key-value store's IO API." | monadic-state |
| "Write properties for my JSON encoder." | applications (round trips) |
| "What does `withMaxSuccess` do? Is it deprecated?" | api-index → history |
| "Why does `return x >>= f` not equal `f x` for `Gen`?" | internals |
| "This 2015 tutorial's `cover` call doesn't compile." | history (migration) |
| "How does QuickCheck compare to Hypothesis?" | history (ecosystem) |

## Learning paths

Ordered sequences for: newcomers; experienced testers; debugging; advanced
generators and shrinking; stateful systems; project integration;
upstream contributors; migrating old code.
[references/learning-paths.md](references/learning-paths.md).

## Running the examples

```bash
export PATH=$HOME/.ghcup/bin:$PATH                  # GHC and cabal on PATH
qik-chk-workflow/scripts/run-examples.sh --setup    # once
qik-chk-workflow/scripts/run-examples.sh            # all examples
```

Each example declares the expected outcome of every property, so
deliberate failures count as success. Details:
[examples-harness.md](../qik-chk-workflow/references/examples-harness.md).

## Pitfalls

- **Version-specific facts.** Seeds, sizes, shrink results, percentages,
  and message text are for 2.19.0.0; random outcomes quoted from example
  runs vary between runs unless the example fixes a seed.
- **Routing by keyword alone.** "Coverage" can mean distribution
  (`cover`) or code coverage (HPC, not covered by this pack).

## Troubleshooting the pack itself

| Symptom | Cause | Fix |
|---|---|---|
| `run-examples: package environment ... missing` | setup not done for this GHC | `run-examples.sh --setup` |
| `cannot find -lgmp` while linking | no libgmp development symlink | install `libgmp-dev`, or put a `libgmp.so` symlink on `LIBRARY_PATH` |
| An example reports `MISMATCH` | a different QuickCheck or GHC version, or a rare random outcome | check versions; rerun; compare with the [validation report](references/validation-report.md) |
| A link to upstream shows different code | the link is a permalink to commit `3d8fe868`; `master` may have moved | read the pinned commit, or recheck against your version |

## Pack records

- [references/skill-map.md](references/skill-map.md): tree, ownership,
  prerequisites, boundaries.
- [references/learning-paths.md](references/learning-paths.md): paths by
  goal.
- [references/source-manifest.md](references/source-manifest.md): upstream
  commit, versions, toolchain, every source with access status.
- [references/coverage-ledger.md](references/coverage-ledger.md): modules,
  exports, tests, examples, papers, concepts, use cases → where covered,
  and what is excluded, inaccessible, or unresolved.
- [references/validation-report.md](references/validation-report.md):
  commands run, results, checks not run.
