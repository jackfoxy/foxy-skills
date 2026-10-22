# `Gen` combinators: exact semantics (QuickCheck 2.19)

Companion to [qik-chk-generators](../SKILL.md). Line references are to
`src/Test/QuickCheck/Gen.hs` at commit `3d8fe868` unless stated; the
[API index](../../qik-chk-api-index/references/test-quickcheck.md) has every
signature.

## Contents

- [The type](#the-type)
- [Size](#size)
- [Uniform choice](#uniform-choice)
- [Choosing among alternatives](#choosing-among-alternatives)
- [Lists](#lists)
- [Filtering](#filtering)
- [Running generators](#running-generators)
- [Unsafe combinators](#unsafe-combinators)

## The type

`newtype Gen a = MkGen { unGen :: QCGen -> Int -> a }` (L66). `Functor`,
`Applicative`, `Monad`, `MonadFix`. `>>=` splits the seed and gives the left
half to the first generator and the right half to the continuation (L86);
`*>` and `<*` do not split (since 2.14). `Test.QuickCheck` exports `Gen`
abstractly: `MkGen` and `unGen` require `import Test.QuickCheck.Gen`.

Monad transformer versions of `Gen` are not in the package; the source
points to the external `QuickCheck-GenT` and `quickcheck-transformer`.

## Size

| Combinator | Semantics |
|---|---|
| `sized f` | `f` receives the current size |
| `getSize` | the current size (since 2.10) |
| `resize n g` | run `g` at size `n`; `error` if `n < 0` (with HasCallStack) |
| `scale f g` | `sized (\n -> resize (f n) g)` |
| `mapSize f p` | property-level: transform the size for a whole property |

The runner chooses the size of each test; see
[size schedule](../../qik-chk-running/references/size-and-seeds.md).

## Uniform choice

| Combinator | Range | Implementation |
|---|---|---|
| `choose (lo, hi)` | inclusive, via `random`'s `Random` class | `randomR`; slower |
| `chooseInt`, `chooseBoundedIntegral` | inclusive | splitmix bitmask-with-rejection over `Word64`/`Int64` |
| `chooseInteger` | inclusive, unbounded | fast path for 64-bit ranges, else splitmix `nextInteger` |
| `chooseEnum (lo, hi)` | inclusive | `toEnum <$> chooseInt (fromEnum lo, fromEnum hi)` |
| `chooseInt64`, `chooseWord64` | inclusive; bounds may be given in either order | splitmix |
| `chooseUpTo n` | `[0, n]` for `Word64` | splitmix |
| `chooseAny` | the type's natural range | `random` |
| `genDouble`, `genFloat` | `[0, 1)` | splitmix (Gen module only) |

The 64-bit and `chooseUpTo` variants are unavailable when QuickCheck is
built without splitmix (Hugs). The 2.14 changelog reports roughly twice the
speed for the bundled examples after switching internal uses of `choose` to
the specialised forms.

## Choosing among alternatives

| Combinator | Semantics | Errors |
|---|---|---|
| `elements xs` | uniform element | empty list |
| `oneof gs` | uniform generator | empty list |
| `frequency [(w, g)]` | weight-proportional generator | empty list, negative weight, all weights zero |
| `growingElements xs` | uniform from a prefix of `xs` whose length grows with the logarithm of the size | empty list |
| `sublistOf xs` | each element kept with probability 1/2, order kept | - |
| `shuffle xs` | random permutation (sort by random keys) | - |

`elements`, `oneof`, `frequency`, `growingElements`, `resize` carry
`HasCallStack` (since 2.15), so the error names the call site.

## Lists

| Combinator | Length | Notes |
|---|---|---|
| `listOf g` | uniform in `0..size` | default for `[a]` |
| `listOf1 g` | uniform in `1..max 1 size` | |
| `vectorOf n g` | exactly `n` | `replicateM` |
| `vector n` | exactly `n` | `vectorOf n arbitrary` |
| `infiniteListOf g`, `infiniteList` | infinite | lazy; take a prefix before comparing |
| `orderedList` | as `listOf`, then sorted | |

Elements are generated at the **same** size as the list, so nested lists
grow quadratically.

## Filtering

| Combinator | Behaviour |
|---|---|
| `g \`suchThat\` p` | `suchThatMaybe` at the current size; on `Nothing`, retry at size + 1, forever (L279) |
| `g \`suchThatMaybe\` p` | try sizes `n, n+1, ..., 2n` once each; `Nothing` if all fail |
| `g \`suchThatMap\` f` | `suchThat` on `isJust . f`, then `fromJust` |
| `discard` | an exception value: evaluating it inside a generator discards the whole test case |

`suchThat` therefore loops when `p` can never hold, and slows down when it
rarely holds (each retry also grows the size). Prefer construction.

## Running generators

| Function | Size | Seed |
|---|---|---|
| `generate g` | 30 | fresh (`newQCGen`) |
| `sample g` | prints one value at each of 0, 2, ..., 20 | fresh per value; prints `<DISCARDED>` for a discarded value |
| `sample' g` | returns values at 0, 2, ..., 20 | fresh |
| `unGen g seed size` | as given | as given (`mkQCGen n` for a fixed seed) |

## Unsafe combinators

`Test.QuickCheck.Gen.Unsafe` breaks the distribution abstraction by reusing
one seed: `promote :: Monad m => m (Gen a) -> Gen (m a)`, `delay :: Gen (Gen
a -> a)`, and `capture :: Gen Capture` (a rank-2 evaluator for generating
polymorphic values). QuickCheck uses `promote` for random functions and for
monadic properties. See [qik-chk-internals](../../qik-chk-internals/SKILL.md).
