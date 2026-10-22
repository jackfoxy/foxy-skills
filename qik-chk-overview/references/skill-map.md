# Skill map

Companion to [qik-chk-overview](../SKILL.md). Sixteen skills, organised by
what the user is trying to do. Arrows point from prerequisite to
dependent skill.

## Tree

```text
qik-chk-overview                      entry point, routing, manifest, ledger, validation
│
├── Learn
│   ├── qik-chk-foundations           what a property is, first run, how QuickCheck thinks
│   ├── qik-chk-property-design       what to claim: specification styles, weak vs strong
│   └── qik-chk-properties            the property language: ==>, forAll, ===, .&&., ...
│
├── Build inputs
│   ├── qik-chk-generators            Gen, Arbitrary, sizes, modifiers, recipes
│   ├── qik-chk-shrinking             shrink, shrinkers, the shrink search
│   └── qik-chk-functions             Fun, CoArbitrary, Function, showing functions
│
├── Check what was tested
│   └── qik-chk-distribution          label, classify, cover, checkCoverage, labelledExamples
│
├── Run and integrate
│   ├── qik-chk-running               runners, Args, Result, seeds, sizes, timeouts, TH
│   ├── qik-chk-workflow              cabal suites, tasty, hspec, regressions, CI, harness
│   └── qik-chk-debugging             symptom → cause → fix
│
├── Apply
│   ├── qik-chk-monadic-state         IO, ST, PropertyM, model-based stateful testing
│   └── qik-chk-applications          per-domain recipes, upstream example programs
│
└── Reference and depth
    ├── qik-chk-api-index             every exported symbol with signature, owner, source link
    ├── qik-chk-internals             implementation, upstream tests, contributing
    └── qik-chk-history               QuickCheck 1, release history, papers, ecosystem
```

## Ownership and prerequisites

| Skill | Owns | Prerequisites | References | Examples |
|---|---|---|---|---|
| [overview](../SKILL.md) | routing, learning paths, provenance, coverage, validation | none | skill-map, learning-paths, source-manifest, coverage-ledger, validation-report | - |
| [foundations](../../qik-chk-foundations/SKILL.md) | concepts, first property, Testable, the test-shrink-report loop, limits of random testing | none | theory | FirstProperties |
| [property-design](../../qik-chk-property-design/SKILL.md) | choosing properties: validity, postcondition, metamorphic, inductive, model-based; vacuity; catalog | foundations | specification-styles, property-catalog | WeakToStrong, VacuousAndDefaulting, SpecStyles |
| [properties](../../qik-chk-properties/SKILL.md) | property combinators and their exact semantics | foundations | combinator-semantics | Combinators |
| [generators](../../qik-chk-generators/SKILL.md) | `Gen`, `Arbitrary`, combinators, size, default instances, modifiers, generic derivation | foundations | combinators, default-instances, recipes | SizedRecursion, FilterVsConstruct, GenToolkit |
| [shrinking](../../qik-chk-shrinking/SKILL.md) | `shrink`, standard shrinkers, invariant-preserving and dependent shrinking, search behaviour | generators | shrinkers, search | InvariantShrink, ShrinkTraps, DependentShrink |
| [functions](../../qik-chk-functions/SKILL.md) | `Fun`, `Function`, `CoArbitrary`, `applyFun`, `Fn` | generators | function-representation | ShowableFunctions |
| [distribution](../../qik-chk-distribution/SKILL.md) | labels, classes, tables, coverage requirements and statistics | properties | coverage-statistics | Coverage |
| [running](../../qik-chk-running/SKILL.md) | runners, `Args`, `Result`, replay, size schedule, timeouts, TH runners, progress | properties | size-and-seeds, result-fields | ReplayAndResults, TimeoutsAndEvaluation, AllProperties, manual/WithinTightLoop |
| [workflow](../../qik-chk-workflow/SKILL.md) | project integration, frameworks, regression capture, CI, compatibility, the pack harness | foundations, running | integration, examples-harness | TastySuite, RegressionCapture, cabal-project/, hspec/ |
| [debugging](../../qik-chk-debugging/SKILL.md) | diagnosis of surprising results | properties, running | symptoms | DiagnoseRuns |
| [monadic-state](../../qik-chk-monadic-state/SKILL.md) | `ioProperty`, `PropertyM`, ST, exceptions, command-sequence model testing | properties, generators, shrinking | stateful-testing | MonadicIO, CommandSequences |
| [applications](../../qik-chk-applications/SKILL.md) | domain recipes; upstream `examples/` | property-design, generators | domain-recipes, upstream-examples | PrintParse, LeftistHeap, FloatingPoint |
| [api-index](../../qik-chk-api-index/SKILL.md) | one row per exported symbol; API coverage script | none | test-quickcheck, other-modules, internal-modules | scripts/browse-api.sh |
| [internals](../../qik-chk-internals/SKILL.md) | implementation, upstream tests and CI, contributing | generators, shrinking, running | architecture, upstream-tests, contributing | GenInternals |
| [history](../../qik-chk-history/SKILL.md) | QuickCheck 1, versions and migration, papers, ecosystem | none (foundations helps) | timeline, papers, ecosystem | - |

## Dependency graph

```text
foundations ──► property-design ──► applications
     │                                  ▲
     ├──► properties ──► distribution   │
     │        │                         │
     │        ├──► running ──► workflow │
     │        │        │                │
     │        │        └──► debugging   │
     │        └──────────────► monadic-state
     └──► generators ──► shrinking ─────┘
              │   └────► functions
              └──► internals (also needs shrinking, running)
history, api-index: no prerequisites
```

## Boundaries between neighbours

| Question | Goes to | Not to |
|---|---|---|
| "Which property should I write?" | property-design | properties |
| "What does `.||.` do with discards?" | properties | property-design |
| "My generator is skewed" (fix it) | generators | distribution |
| "How skewed is my data?" (measure it) | distribution | generators |
| "Why is the counterexample big?" | shrinking (mechanism), debugging (diagnosis) | generators |
| "How do I run 1000 tests?" | running | workflow |
| "How do I make CI fail on a property?" | workflow | running |
| "Why does QuickCheck do X?" (user level) | the owning skill | internals |
| "Why does QuickCheck do X?" (code level) | internals | the owning skill |
| "Which version added X?" | history | api-index |
