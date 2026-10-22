---
name: qik-chk-functions
description: Test higher-order Haskell code with QuickCheck - generating random functions through CoArbitrary (coarbitrary, variant, generic instances) and through the showable, shrinkable Fun type with the Function class (function, functionMap, functionShow, generic deriving), the Fn/Fn2/Fn3 patterns and applyFun, how function counterexamples are displayed as finite tables (and why unshrunk ones show as "fun"), Blind for unshowable arguments, and properties of map, filter, folds, combinators and callbacks. Use when a property quantifies over functions or predicates, when a counterexample involving a function needs to be readable, or when someone defines CoArbitrary or Function instances.
user-invocable: true
disable-model-invocation: false
---

# Random functions: `CoArbitrary`, `Function`, `Fun`

**Scope:** properties whose arguments are functions. Ordinary generators
are [qik-chk-generators](../qik-chk-generators/SKILL.md); shrinking of
ordinary values is [qik-chk-shrinking](../qik-chk-shrinking/SKILL.md).

**Prerequisites:** [qik-chk-generators](../qik-chk-generators/SKILL.md).

**Version:** QuickCheck 2.19.0.0. `Fun`/`Function` need GADTs (GHC and
MicroHs; not Hugs). The design is from Koen Claessen, *Shrinking and
showing functions* (Haskell Symposium 2012), which the module documentation
cites; that paper was not accessible for this pack (see the
[source manifest](../qik-chk-overview/references/source-manifest.md)), so
details below come from the 2.19 source.

## Two mechanisms

| | `CoArbitrary` (original, 2000 paper) | `Fun` + `Function` (QuickCheck 2) |
|---|---|---|
| Argument type needs | `CoArbitrary a` | `Function a` **and** `CoArbitrary a` |
| Property argument | `a -> b` (must be wrapped in `Blind` or not printed) | `Fun a b`, usually matched with `Fn f` |
| Counterexample | cannot be shown (`(*)` under `Blind`) | a finite table such as `{"banana"->0, _->1}` |
| Shrinks | no | yes: to a small table plus a default |
| Use when | you only need a random function | you want readable, minimal counterexamples (almost always) |

How `CoArbitrary` makes functions: `coarbitrary x` perturbs a generator by
the argument `x`, and `promote` turns `\x -> coarbitrary x arbitrary` into a
`Gen (a -> b)` (2000 paper, section 3.3). Different arguments must give
independent perturbations; `variant n` does this with a prefix-free code
over seed splits.

How `Fun` works: `function` tabulates a function into a concrete,
possibly partial representation (`a :-> b`: tables, pairs, sums, maps
through isomorphisms). A `Fun` holds the representation, a default
result, and the plain function. Shrinking removes table entries and
shrinks results; a `Fun` that has never been shrunk prints as `<fun>`
(so with `maxShrinks = 0` or `noShrinking` you only see `<fun>`).

## Procedure

1. Write the property with `Fun` arguments and match them with patterns:

   ```haskell
   prop_mapFusion :: Fun Int Int -> Fun Int Int -> [Int] -> Property
   prop_mapFusion (Fn f) (Fn g) xs = map f (map g xs) === map (f . g) xs
   ```

   Use `Fn2`/`Fn3` (`Fun (a, b) c`) for curried functions of two or three
   arguments, or `applyFun`/`applyFun2`/`applyFun3`.
2. For a **new argument type**, provide both instances:
   - algebraic data type: derive `Generic`, then `instance Function T` and
     `instance CoArbitrary T` with no body (generic defaults);
   - otherwise map to a type that has them:
     `function = functionMap to from` (needs a bijection),
     `functionShow` (via `Show`/`Read`), `functionIntegral`,
     `functionRealFrac`, `functionBoundedEnum`, and from
     `Test.QuickCheck.Function` also `functionElements` (small finite
     types) and the lower-level `functionMapWith`/`functionPairWith`/
     `functionEitherWith`;
   - `CoArbitrary`: `coarbitrary = coarbitrary . toSomethingWithAnInstance`,
     or `coarbitraryIntegral`, `coarbitraryShow`, `coarbitraryEnum`,
     `coarbitraryReal`, or `genericCoarbitrary`.
3. **Result types** need `Arbitrary` (and `Show` for display).
4. Keep argument domains small when equality matters: random functions
   from `String` give mostly distinct results, so properties about
   collisions need a constrained result type or domain.

## Pitfalls

| Pitfall | What happens | Fix |
|---|---|---|
| Plain `a -> b` argument | no `Show` instance, property does not compile | `Fun a b`, or `Blind (a -> b)` |
| `Blind` function counterexample | prints `(*)`; nothing to debug | `Fun` |
| Shrinking disabled | `Fun` prints `<fun>` | allow shrinking for that argument |
| Function of a huge or infinite domain | the table can only show the points that were used | expected; the default `_->v` covers the rest |
| Equality of functions | not decidable | compare on generated points (`map f xs`) |
| `CoArbitrary` that ignores part of the value | functions cannot distinguish those inputs, so the test is weaker | perturb by every field |
| Old style `coarbitrary` inside `Arbitrary` | QuickCheck 1 only; now a separate class | see [qik-chk-history](../qik-chk-history/SKILL.md) |

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `No instance for (Function T)` | type lacks `Function` | `instance Function T where function = functionMap to from`, or derive via `Generic` |
| `No instance for (CoArbitrary T)` | needed for `a -> b` and `Fun` | `instance CoArbitrary T` (generic default) or `coarbitrary = variant . fromEnum` style |
| Counterexample shows `<fun>` | function not shrunk (shrinking off or limit reached) | allow shrinking; raise `withMaxShrinks` |

## Executable example

[ShowableFunctions.hs](examples/ShowableFunctions.hs) runs: the module
documentation's three-words property (fails, shrunk to a table); map
fusion (passes); `foldr` versus `foldl` (fails, `Fn2` table shown); a
Generic-derived `Function`/`CoArbitrary` instance; `functionMap` for a
newtype; and a `Blind` function argument.

Recorded run (tables vary with the seed):

```text
=== f distinguishes three words (false) (expect Fail)
*** Failed! Falsified (after 3 tests and 75 shrinks):
{"banana"->0, _->1}
=== foldr equals foldl (false) (expect Fail)
*** Failed! Falsified (after 2 tests and 6 shrinks):
{(-1,0)->1, _->0}
-1
[0]
0 /= 1
```

Read the first table as: the function maps `"banana"` to 0 and everything
else to 1, so `f "monkey" == f "elephant"` but neither equals
`f "banana"`. The module documentation's own run reports a different
table after 134 shrinks; any table with that shape is a valid
counterexample.

Run: `qik-chk-workflow/scripts/run-examples.sh qik-chk-functions`.

## Go deeper

- [references/function-representation.md](references/function-representation.md):
  the `:->` constructors, how a `Fun` is shrunk and shown, and the
  `CoArbitrary` laws in detail.
- API rows: [qik-chk-api-index](../qik-chk-api-index/references/test-quickcheck.md).
