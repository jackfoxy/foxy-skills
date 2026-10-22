---
name: qik-chk-property-design
description: Design strong QuickCheck properties - choosing among validity (invariant) properties, postconditions, metamorphic relations, round trips, algebraic laws, inductive and model-based properties, differential testing against a reference, and preconditions (implication); and spotting weak, tautological, vacuous, or type-defaulted properties that pass for the wrong reason. Use when writing properties from requirements, reviewing a property suite, deciding what to assert about a function or data structure, or when a property passes but feels too weak.
user-invocable: true
disable-model-invocation: false
---

# Designing QuickCheck properties

**Scope:** what to claim. How to generate the inputs is
[qik-chk-generators](../qik-chk-generators/SKILL.md); the combinators that
express a claim (`===`, `==>`, `conjoin`, ...) are
[qik-chk-properties](../qik-chk-properties/SKILL.md); stateful APIs are
[qik-chk-monadic-state](../qik-chk-monadic-state/SKILL.md).

**Prerequisites:** [qik-chk-foundations](../qik-chk-foundations/SKILL.md).

**Version:** QuickCheck 2.19.0.0; the techniques are version-independent.
The taxonomy follows Hughes, *How to Specify It!* (TFP 2019, LNCS 12053,
2020); see the [source manifest](../qik-chk-overview/references/source-manifest.md).

## Choose a kind of property

| Kind | Claim | Strength | Cost |
|---|---|---|---|
| **Validity / invariant** | Every value the API produces satisfies the data invariant | Necessary, never sufficient: catches invalid output only | Write `valid`; test generators and shrinkers too |
| **Postcondition** | After `f x`, a relation between `x` and the result holds | Medium; can check one aspect per call | One property per operation |
| **Metamorphic** | Two related calls give related results (`f (g x)` vs `h (f x)`) | Individually weak, strong in combination; needs no oracle | Many properties |
| **Round trip** | `decode (encode x) == x` | Strong for codecs; misses bugs shared by both sides | Cheap |
| **Algebraic law** | Associativity, identity, idempotence, commutativity, distributivity | Specifies abstractions precisely | Cheap |
| **Inductive** | Base case plus "each constructor step preserves the relation" | Can be complete for an API | Needs reasoning |
| **Model-based** | `abstract (f x) == f_model (abstract x)` against a simple model | Strongest single property; complete with one per operation | Must write and trust a model |
| **Differential** | New implementation agrees with an old/slow/reference one | Strong when a reference exists | Needs the reference |

*How to Specify It!* measured these on a binary search tree with eight
seeded bugs (section 5). Validity properties missed five of the eight
bugs. Every bug was found by at least one postcondition, one metamorphic
property and one model-based property. Each model-based property found
every bug in the operation it tests, and model-based properties failed
fastest: a mean of 5.8 tests to failure, against 77 for postconditions and
56 for metamorphic properties (Fig. 9). Some individually plausible
metamorphic properties missed bugs entirely. The paper's recommendation:
if time is limited, write model-based properties plus validity properties;
use metamorphic properties where a model would be too expensive or too
close to the implementation (section 5.3).

## Procedure: from a requirement to properties

1. **Write `valid`** for each data type with an invariant, and test that
   generators, shrinkers and every operation preserve it. Without this, a
   later failure may be caused by invalid test data rather than a bug.
2. **Look for a model.** Is there a simpler representation (a sorted
   association list for a tree, a list for a queue, `Data.List.sort` for a
   sort) with an obvious implementation of each operation? If yes, write
   one model-based property per operation.
3. **Add laws and round trips** that the abstraction should satisfy
   (identity elements, inverses, idempotence of normalisation,
   `parse . print`).
4. **Add metamorphic relations** for operations where computing the right
   answer is hard but relating two answers is easy (shortest paths, search
   results, optimisers).
5. **Make every property falsifiable by a plausible bug.** Seed a bug
   mentally or literally (mutation) and ask which property fails; if none,
   the suite is too weak.
6. **Check what was tested** with `classify`/`collect`
   ([qik-chk-distribution](../qik-chk-distribution/SKILL.md)).

## Properties that pass for the wrong reason

| Smell | Example | Fix |
|---|---|---|
| **Tautology** | `reverse xs == reverse xs` | Compare two different computations |
| **Weak oracle** | `sorted (sort xs)` passes for a sort that drops elements | Also require a permutation, or compare with a model |
| **Vacuous precondition** | `sortedLong xs ==> ...` where `sortedLong` is almost never true: gives up, or passes on a few tiny cases | Generate the domain constructively |
| **Type defaulting** | `\x y -> x == y` in GHCi defaults to `()` and passes | Annotate argument types (`x :: Int`) |
| **Implication used as converse** | Testing `p x ==> q x` when the requirement was `q x ==> p x` | State the direction from the requirement, then test both if both are meant |
| **Degenerate model** | Model shares the implementation's code or its bug | Write the model independently and simply |
| **Unreachable bug** | Bug only for inputs the generator never makes (`minBound`, long lists, equal keys) | Fix the generator, add explicit cases |
| **`.&.` for conjunction** | `p .&. q` tests only one side per case | Use `.&&.` or `conjoin` |

Each row except the last two is executed in the examples below.

## Preconditions and implication

`cond ==> prop` **discards** tests where `cond` is false; they do not count
as passes, and after `maxDiscardRatio` (10) discards per pass QuickCheck
gives up. Use preconditions for rare exclusions (`n /= 0`). When the
condition rejects most inputs, generate the domain directly instead
(`forAll orderedList`, modifiers like `NonEmptyList`, or a custom
generator): the precondition otherwise skews the data towards small cases
(the 2000 paper's `prop_Insert`, section 2.4).

## Equality and equivalence

Use `===` rather than `==` so failures print both sides. When values have
several representations (trees balanced differently, maps built in
different orders), compare a canonical form (`toList`) or define an
equivalence and test that your operations preserve it (*How to Specify
It!*, section 4.3). Floating point needs a tolerance
([qik-chk-applications](../qik-chk-applications/SKILL.md)).

## Pitfalls

The table in [Properties that pass for the wrong reason](#properties-that-pass-for-the-wrong-reason),
plus:

- **Over-specification**: a model that fixes incidental behaviour (order of
  equal elements, error message text) makes valid refactorings fail.
- **Validity alone is weak**: in *How to Specify It!* validity properties
  missed 5 of the 8 seeded bugs, while each of the postcondition,
  metamorphic, and model-based property sets found all 8. Give each
  operation at least one model-based or metamorphic property.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Every property passes on code you know is buggy | weak oracles, or the generator never reaches the bug | add a model property; seed the bug and classify ([qik-chk-distribution](../qik-chk-distribution/SKILL.md)) |
| Properties fail on valid refactorings | over-specification | compare up to the intended equivalence |
| No model is available | complex specification | metamorphic properties, round trips, or inductive properties |
| Most tests discarded | preconditions instead of generators | [qik-chk-generators](../qik-chk-generators/SKILL.md) |

## Executable examples

| File | Shows | Expected |
|---|---|---|
| [WeakToStrong.hs](examples/WeakToStrong.hs) | `sorted (badSort xs)` passes a sort that removes duplicates; adding a length check or a model catches it | weak: pass; stronger and model: fail on two equal elements |
| [VacuousAndDefaulting.hs](examples/VacuousAndDefaulting.hs) | precondition that gives up, constructive fix, `()` defaulting, tautology | give up; pass; pass (vacuous); fail; pass (vacuous) |
| [SpecStyles.hs](examples/SpecStyles.hs) | validity, postcondition, metamorphic, model-based properties on a BST with a bug that keeps old values on re-insert | validity passes (the bug is not an invariant violation); the other three fail |

Recorded run of `SpecStyles.hs` (counterexamples vary with the seed):

```text
=== validity is preserved by insert (bug not visible) (expect Pass)
+++ OK, passed 100 tests.
=== postcondition: find after insert (expect Fail)
*** Failed! Falsified (after 7 tests and 5 shrinks):
1
0
Node Leaf 1 1 Leaf
Just 1 /= Just 0
=== model-based: against an association list (expect Fail)
*** Failed! Falsified (after 2 tests and 1 shrink):
0
0
Node Leaf 0 1 Leaf
[(0,1)] /= [(0,0)]
```

Run: `qik-chk-workflow/scripts/run-examples.sh qik-chk-property-design`.

## Go deeper

- [references/specification-styles.md](references/specification-styles.md):
  the five approaches of *How to Specify It!* with their trade-offs, and
  the 2002 monadic paper's specification styles.
- [references/property-catalog.md](references/property-catalog.md): reusable
  property patterns with templates.
