---
name: qik-chk-generators
description: Generate QuickCheck test data well - the Gen monad and its size parameter, Arbitrary instances (default distributions for Int, Double, Char, lists, Maybe, containers), combinators such as choose*, elements, oneof, frequency, sized, resize, scale, listOf, vectorOf, suchThat, shuffle and sublistOf, modifiers like Positive and NonEmptyList, recursive and mutually recursive types, dependent or constrained inputs, filtering versus constructive generation, generic-random and testing-feat as external options, and sample/generate for inspecting generators. Use whenever someone writes an Arbitrary instance or custom Gen, a generator loops or produces huge or skewed data, a property gives up from discards, or a bug needs inputs the default generator rarely makes.
user-invocable: true
disable-model-invocation: false
---

# Generators: `Gen` and `Arbitrary`

**Scope:** producing test data. Shrinking that data is
[qik-chk-shrinking](../qik-chk-shrinking/SKILL.md); random functions are
[qik-chk-functions](../qik-chk-functions/SKILL.md); measuring the data you
produced is [qik-chk-distribution](../qik-chk-distribution/SKILL.md); how
`Gen` is implemented is [qik-chk-internals](../qik-chk-internals/SKILL.md).

**Prerequisites:** [qik-chk-foundations](../qik-chk-foundations/SKILL.md);
Haskell monads/applicatives.

**Version:** QuickCheck 2.19.0.0. Facts below are from the 2.19 source
(`src/Test/QuickCheck/Gen.hs`, `Arbitrary.hs`, `Modifiers.hs`); see the
[source manifest](../qik-chk-overview/references/source-manifest.md).

## The model

`Gen a` is a function from a random seed and an **size** (a non-negative
`Int`) to an `a`. It is a monad; `>>=` **splits** the seed, so the two sides
get independent randomness. The runner sets the size per test: with the
defaults (100 tests, `maxSize` 100) the sizes are 0, 1, ..., 99, so early
tests are small (measured in
[GenInternals.hs](../qik-chk-internals/examples/GenInternals.hs)). `generate`
uses size 30; `sample` uses sizes 0, 2, ..., 20. Generators interpret the
size freely: lists use it as a maximum length, sized integers as a maximum
magnitude, and many generators ignore it.

## Decide how to get a generator

| Situation | Use |
|---|---|
| Built-in type, default distribution is fine | `arbitrary` (implicit in property arguments) |
| Restrict a built-in type (sign, non-empty, sorted, ASCII) | a **modifier**: `Positive n`, `NonNegative n`, `NonZero n`, `NonEmpty xs`, `Ordered xs`, `Sorted xs`, `Small n`, `Large n`, `ASCIIString s`, `PrintableString s` |
| One property needs a different distribution | `forAll gen` / `forAllShrink gen shr` |
| Your own type, used in many properties | an `Arbitrary` instance (often on a `newtype`, as the 2000 paper recommends for names) |
| Algebraic type, structure is all that matters | hand-written instance, or `generic-random` (external) |
| Exhaustive or enumerative coverage of small values | `testing-feat` (external), or `elements`/`vectorOf` over a small domain |

`Arbitrary` has no generic `arbitrary`: the class documentation says there
is no high-quality generic implementation and points to the external
`testing-feat` and `generic-random` packages
([Arbitrary.hs L236](https://github.com/nick8325/quickcheck/blob/3d8fe8686024760006ca1ca656cbdd82cd71f11e/src/Test/QuickCheck/Arbitrary.hs#L236)).
`genericShrink` exists for shrinking only.

## Core combinators

| Need | Combinator | Notes |
|---|---|---|
| Uniform in a range | `chooseInt`, `chooseInteger`, `chooseEnum`, `chooseBoundedIntegral`, `choose` | The specialised forms (2.14) are much faster than `choose` |
| One of some values | `elements xs` | Errors on `[]` |
| One of some generators | `oneof gs`, `frequency [(w, g)]` | Errors on `[]`; `frequency` also on negative or all-zero weights |
| Lists | `listOf g` (0..size), `listOf1 g` (1..size), `vectorOf n g`, `infiniteListOf g` | Lazily infinite lists work because bind splits |
| Permutations / subsets | `shuffle xs`, `sublistOf xs`, `orderedList` | |
| Read / change size | `sized f`, `getSize`, `resize n g`, `scale f g` | `resize` errors on negative sizes |
| Filter inside a generator | `g \`suchThat\` p`, `suchThatMap`, `suchThatMaybe` | `suchThat` retries forever if `p` is unsatisfiable |
| Apply a constructor | `Con <$> arbitrary <*> arbitrary`, `applyArbitrary2..4 Con` | |
| Inspect | `sample g`, `sample' g`, `generate g` | Run in GHCi before trusting a generator |

The full list with semantics is in
[references/combinators.md](references/combinators.md).

## Procedure: write a generator for your own type

1. **Decide the distribution you want.** What inputs find bugs: collisions
   (equal keys), boundaries (empty, singleton, maximum), deep nesting? The
   generator should make them common.
2. **Make invalid values impossible by construction** rather than
   filtering: generate a sorted list as `orderedList`, a range as `lo` plus
   a non-negative width, a valid index after the list.
3. **Use the size** for anything recursive or unbounded: halve it per
   recursive call and force a base case at size 0 (template below).
4. **Write `shrink` too** (or `genericShrink` if there is no invariant);
   see [qik-chk-shrinking](../qik-chk-shrinking/SKILL.md).
5. **Look at the output** with `sample`, then measure it inside a real
   property with `collect`/`classify`/`tabulate`.
6. **Test the generator**: `forAll gen valid`, and a completeness check if
   the generator builds values through only part of an API (*How to Specify
   It!*, section 4.4).

Recursive template (the 2000 paper's and the manual's recommended shape):

```haskell
genTree :: Gen Tree
genTree = sized go
  where
    go 0 = Leaf <$> arbitrary
    go n = frequency
      [ (1, Leaf <$> arbitrary)
      , (3, Branch <$> go (n `div` 2) <*> go (n `div` 2)) ]
```

Without the size, `oneof [Leaf <$> arbitrary, Branch <$> t <*> t]` has two
recursive children half of the time: the expected number of nodes is
infinite and generation may not terminate. For **mutually recursive** types
pass the same decreasing size through every type's generator. For lists of
recursive values, `scale (`div` k)` keeps each element small.

## Filtering versus construction

| Approach | Cost | Distribution |
|---|---|---|
| `cond ==> prop` | Discarded tests; gives up after 10 discards per pass by default | Skews towards inputs that satisfy `cond` easily (usually small ones) |
| `gen \`suchThat\` cond` | Retries inside the generator, raising the size after repeated misses; never gives up | Same skew; loops forever if `cond` is unsatisfiable |
| Constructive generator | None | Whatever you design |

Measured in [FilterVsConstruct.hs](examples/FilterVsConstruct.hs): an
`ordered xs ==>` precondition needed `withDiscardRatio 100` to finish, with
over 2000 discards and almost no list longer than 3, while `orderedList`
produced lists of length 5 or more in over 80% of tests; a precondition
requiring sorted lists of length 8 gave up after 1000 discards with 0
passes.

## Default distributions worth knowing

Details and source lines in
[references/default-instances.md](references/default-instances.md).

- `Int`, `Integer`: uniform in `[-size, size]`; sizes run 0..99 in a
  default run, so a plain `Int` stays within ±99. `Large Int` spreads over
  the whole range ([GenToolkit.hs](examples/GenToolkit.hs) shows
  `Large Int` exceeding 100 within a few tests).
- `Int8`..`Int64`, `Word8`..`Word64`: `arbitrarySizedBoundedIntegral`, whose
  bit width grows with size, reaching the full range by size 80 (sooner for
  narrow types: `Int8` by size 16).
- `Double`/`Float`: an equal mix of five generators (uniform `[0,1)`,
  integers, small-denominator fractions, two sized fraction generators);
  never NaN or infinity.
- `Char`: three quarters from the ASCII generator, one quarter from all
  assigned Unicode; `String` is a list of these.
- `Maybe a`: `Nothing` one time in four. `Either a b`: `Left`/`Right` evenly.
- Lists: length uniform in `0..size`, so about 5% of default list tests are
  empty (measured 5.1 to 5.2% in
  [Coverage.hs](../qik-chk-distribution/examples/Coverage.hs)).
- `Set`, `Map`, `IntMap`, `Seq`: built from generated lists; the source warns
  that they do not vary the internal representation.

## Pitfalls

- **`unGen` is not exported by `Test.QuickCheck`.** Import
  `Test.QuickCheck.Gen` to run a generator on a fixed seed.
- **Morally a monad.** `return x >>= f` and `f x` give the same
  distribution but not the same value for a given seed (2000 paper,
  section 6.4; demonstrated in GenInternals.hs). Do not rely on seed-level
  equalities between generators.
- **Size blow-up.** A list of lists at size 100 has about 2,500 elements on
  average and up to about 10,000; scale inner generators.
- **Unicode surprises.** Default strings contain non-ASCII characters (since
  2.10); use `ASCIIString` or `arbitraryASCIIChar` when the code under test
  is ASCII-only by contract.
- **Orphan instances.** For types from other packages, `quickcheck-instances`
  (external) provides many instances; otherwise wrap the type in a newtype.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Generator never terminates | recursive generator without size reduction | `sized` and divide the size per child |
| `Gave up!` | filtering with `==>` | construct valid values ([FilterVsConstruct.hs](examples/FilterVsConstruct.hs)) |
| Generation is very slow | `suchThat` with a rare predicate, or nested sizes | construct; `scale`/`resize` |
| Values are always tiny or always huge | size ignored or misused | `sized`, `getSize`, check with `sample` |

## Executable examples

| File | Shows |
|---|---|
| [SizedRecursion.hs](examples/SizedRecursion.hs) | sized recursive generator, depth distribution via `collect`, `resize`, `scale` |
| [FilterVsConstruct.hs](examples/FilterVsConstruct.hs) | `==>` skew and give-up, `orderedList`, `OrderedList`, `suchThat`, `suchThatMaybe` |
| [GenToolkit.hs](examples/GenToolkit.hs) | dependent fields, `frequency`, modifiers, string modifiers, `Large`, deterministic `unGen`, `shuffle` |

Run: `qik-chk-workflow/scripts/run-examples.sh qik-chk-generators`.

## Go deeper

- [references/combinators.md](references/combinators.md): every `Gen`
  combinator with exact semantics.
- [references/default-instances.md](references/default-instances.md):
  default generators and shrinkers per type.
- [references/recipes.md](references/recipes.md): mutual recursion,
  dependent values, stateful generation, weighted structures, external
  packages.
- The API rows for every symbol: [qik-chk-api-index](../qik-chk-api-index/SKILL.md).
