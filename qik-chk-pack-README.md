# `qik-chk-*` Skill Pack

Sixteen skills for **Haskell QuickCheck**, pinned to QuickCheck 2.19.0.0
(`github.com/nick8325/quickcheck`, commit
`3d8fe8686024760006ca1ca656cbdd82cd71f11e`, tag `2.19`). Written
2026-10-20 from the upstream source, tests, changelog and CI, the
Chalmers QuickCheck page and manual, and the ICFP 2000, Haskell Workshop
2002 and *How to Specify It!* papers; examples executed with GHC 9.10.3.

Scope is QuickCheck itself (broader than `%quiz`, which this pack does
not document). Historical QuickCheck 1, research, third-party packages,
ports, and Quviq's Erlang QuickCheck are kept separate and labelled.

## Contents

| Skill | Owns |
|---|---|
| `qik-chk-overview` | Entry point, routing, learning paths, source manifest, coverage ledger, validation report |
| `qik-chk-foundations` | Concepts, first property, what a run establishes, limits of random testing |
| `qik-chk-property-design` | Choosing properties: validity, postcondition, metamorphic, inductive, model-based; vacuity |
| `qik-chk-properties` | Property combinators and their exact semantics |
| `qik-chk-generators` | `Gen`, `Arbitrary`, size, combinators, default instances, modifiers, recipes |
| `qik-chk-shrinking` | `shrink`, standard and custom shrinkers, dependent values, the shrink search |
| `qik-chk-functions` | `Fun`, `Function`, `CoArbitrary`, showing and shrinking functions |
| `qik-chk-distribution` | `label`, `classify`, `tabulate`, `cover`, `checkCoverage`, `labelledExamples` |
| `qik-chk-running` | Runners, `Args`, `Result`, replay, size schedule, timeouts, TH runners |
| `qik-chk-workflow` | cabal test suites, tasty, hspec, regression capture, CI, compatibility, examples harness |
| `qik-chk-debugging` | Symptom → cause → fix for surprising runs |
| `qik-chk-monadic-state` | `ioProperty`, `PropertyM`, ST, model-based testing of stateful APIs |
| `qik-chk-applications` | Domain recipes; the upstream example programs |
| `qik-chk-api-index` | Every exported symbol of every exposed module, with owner and source permalink |
| `qik-chk-internals` | Implementation, upstream tests, CI, contributing |
| `qik-chk-history` | QuickCheck 1, release history and migration, papers, ecosystem |

Each skill is `SKILL.md` + `references/*.md` + `agents/openai.yaml`, most
with `examples/`. Cross-skill links are sibling-relative
(`../qik-chk-x/...`, `../../qik-chk-x/...`), so they resolve here and
when the skill directories are symlinked side by side.

## Examples and scripts

- `qik-chk-workflow/scripts/run-examples.sh`: compiles and runs every
  `qik-chk-*/examples/*.hs` against QuickCheck 2.19.0.0; each example
  declares expected outcomes, so deliberate failures pass the check
  (`--setup` builds the package environment once).
- `qik-chk-workflow/scripts/QikChkHarness.hs`: the shared harness module.
- `qik-chk-api-index/scripts/browse-api.sh`: dumps the API with GHCi and
  checks every exported name has an index row.

## Install (not done)

Not installed anywhere. To install for Claude Code:

```bash
for d in /mnt/mars/gitrepos/foxy-skills/qik-chk-*/; do
  ln -sfn "$d" ~/.claude/skills/"$(basename "$d")"
done
```

## Provenance and verification

See `qik-chk-overview/references/source-manifest.md` (sources, versions,
access status), `coverage-ledger.md` (what is covered, excluded,
inaccessible, unresolved), and `validation-report.md` (commands and
results).
