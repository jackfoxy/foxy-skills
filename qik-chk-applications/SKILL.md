---
name: qik-chk-applications
description: Apply QuickCheck to concrete kinds of code - collections and data structures (invariants, models, heaps, search trees, sets, maps), printers, parsers and serializers (round trips), numeric and floating-point code (tolerances, NaN, overflow), compilers, interpreters and lambda calculi (well-scoped and well-typed term generators), sorting and merging, APIs, protocols, databases and other stateful systems, and testing an optimised implementation against a reference. Includes the upstream example programs (Heap, Set, Merge, Lambda, Simple) and what they demonstrate. Use when someone asks how to property-test a specific kind of component, wants worked domain examples, or needs a starting point for properties of a parser, data structure, numeric routine, or interpreter.
user-invocable: true
disable-model-invocation: false
---

# Applying QuickCheck by domain

**Scope:** recipes per kind of code, each combining a property style, a
generator, and a shrinker. The general method is in
[qik-chk-property-design](../qik-chk-property-design/SKILL.md); effectful
systems in [qik-chk-monadic-state](../qik-chk-monadic-state/SKILL.md).

**Prerequisites:** [qik-chk-property-design](../qik-chk-property-design/SKILL.md),
[qik-chk-generators](../qik-chk-generators/SKILL.md).

**Version:** QuickCheck 2.19.0.0. Upstream examples from `examples/` at
commit `3d8fe868`, compiled and run with GHC 9.10.3 for this pack.

## Pick a recipe

| Code under test | Strongest cheap properties | Generator concern | Recipe |
|---|---|---|---|
| Data structure (heap, tree, set, map) | invariant after every operation; model (`toList` against a list or `Data.Map`) | build through the API *and* generate operation programs | [data structures](references/domain-recipes.md#data-structures) |
| Printer and parser, serializer | round trip `parse (print x) == Just x`; or up to meaning | valid ASTs, sized recursion; also random strings for robustness | [round trips](references/domain-recipes.md#printers-parsers-serializers) |
| Sorting, merging, permutations | ordered output and permutation of input; against `Data.List.sort` | duplicates, sorted inputs (`OrderedList`) | [lists](references/domain-recipes.md#lists-sorting-merging) |
| Numeric, floating point | algebraic laws with tolerance; against `Rational`/`Integer` | boundaries (`minBound`, 0, -0.0, NaN, Inf), `Large` | [numeric](references/domain-recipes.md#numeric-code) |
| Compiler, interpreter, optimiser | evaluation preserved: `eval (optimise e) == eval e`; type preservation | well-scoped and well-typed terms | [languages](references/domain-recipes.md#interpreters-compilers-lambda-calculi) |
| Optimised versus reference implementation | equal outputs on all inputs | inputs that exercise the fast paths | [differential](references/domain-recipes.md#differential-testing) |
| Encoders, hashes, codecs | round trip; injectivity on distinct inputs; size bounds | edge sizes (0, block boundaries) | [round trips](references/domain-recipes.md#printers-parsers-serializers) |
| Stateful API, database, service | command sequences against a model | valid sequences, shrinking with preconditions | [qik-chk-monadic-state](../qik-chk-monadic-state/SKILL.md) |
| Concurrent code | linearizability against a model | scheduling | [stateful-testing.md](../qik-chk-monadic-state/references/stateful-testing.md#concurrency) |

## Procedure

1. **Find the oracle**: a model, an inverse, a reference implementation, an
   invariant, or a metamorphic relation. Prefer models and round trips:
   they catch the most bugs per test (*How to Specify It!*, see
   [qik-chk-property-design](../qik-chk-property-design/SKILL.md)).
2. **Write a generator for the domain's valid inputs**, sized and with a
   shrinker that preserves validity. Check the distribution
   ([qik-chk-distribution](../qik-chk-distribution/SKILL.md)).
3. **Add a robustness property for invalid inputs** where the code faces
   untrusted data (parsers should return an error, not crash).
4. **Seed a bug and confirm a property catches it** before trusting a green
   run. Every example here contains one.

## Worked examples in this pack

All executed with the harness; recorded counterexamples:

| File | Domain | Seeded bug | Counterexample |
|---|---|---|---|
| [PrintParse.hs](examples/PrintParse.hs) | arithmetic printer and parser | missing parentheses for a sum on the right of `*` | `Mul (Lit 0) (Add (Lit 0) (Lit 1))`, `Just 1 /= Just 0` |
| [LeftistHeap.hs](examples/LeftistHeap.hs) | leftist heap | `merge` drops a subtree on equal keys | `[1,0,0,-1,0]`: `[-1,0,0,0] /= [-1,0,0,0,1]` |
| [FloatingPoint.hs](examples/FloatingPoint.hs) | `Double` laws | exact associativity; NaN | `0.1 1.0 3.1`; `NaN` |
| [SpecStyles.hs](../qik-chk-property-design/examples/SpecStyles.hs) | binary search tree | `insert` keeps the old value | see property-design |
| [CommandSequences.hs](../qik-chk-monadic-state/examples/CommandSequences.hs) | mutable queue | `pop` on three elements | `[Push 0,Push 0,Push 1,Pop]` |

Run: `qik-chk-workflow/scripts/run-examples.sh qik-chk-applications`.

## Upstream example programs

The QuickCheck repository's `examples/` directory (only `Heap.hs` is built
by the cabal test suite) shows complete applications. Run for this pack;
several contain deliberate bugs and end with `True <- $quickCheckAll`, so
they exit with a pattern-match failure when a property fails. What each
demonstrates and what it printed:
[references/upstream-examples.md](references/upstream-examples.md).

## Pitfalls

- **Round trip up to what?** Parsers often normalise (associativity,
  whitespace, number formats). Compare meanings, or print twice and compare
  strings, as in `PrintParse.hs`.
- **Generators that only build through the API** cannot produce states the
  API reaches by other routes (deletions, merges); generate programs too.
- **Floating point**: the default `Double` generator never produces NaN or
  infinities and rarely produces values near overflow; exact laws fail for
  ordinary values. Use tolerances, `Rational` models, and explicit special
  values ([default-instances.md](../qik-chk-generators/references/default-instances.md)).
- **Default `Int` never produces `minBound`**: overflow cases such as
  `abs minBound` or `divMod minBound (-1)` need explicit tests
  ([RegressionCapture.hs](../qik-chk-workflow/examples/RegressionCapture.hs)).
- **Interpreters that loop** need `within` or fuel, and `within` cannot
  interrupt non-allocating loops ([qik-chk-running](../qik-chk-running/SKILL.md#timeouts-and-their-guarantees)).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Round-trip property fails on equivalent but different trees | parser normalises | compare meanings or printed forms |
| Floating-point law fails on ordinary values | exact equality | tolerance or `Rational` model |
| Interpreter property hangs | divergent programs | fuel in the evaluator, or `within` |
| Data-structure property passes on a buggy delete | generator only builds via insert | generate operation programs |

## Go deeper

- [references/domain-recipes.md](references/domain-recipes.md): property
  templates and generator advice for each domain.
- [references/upstream-examples.md](references/upstream-examples.md): the
  seven upstream example programs, run results, and lessons.
