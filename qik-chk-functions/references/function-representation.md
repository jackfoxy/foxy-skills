# How random functions are represented, shrunk and shown

Companion to [qik-chk-functions](../SKILL.md); from
`src/Test/QuickCheck/Function.hs` and `Arbitrary.hs` at commit `3d8fe868`.

## CoArbitrary: functions as generator perturbations

```haskell
class CoArbitrary a where
  coarbitrary :: a -> Gen b -> Gen b      -- default: genericCoarbitrary

instance (CoArbitrary a, Arbitrary b) => Arbitrary (a -> b) where
  arbitrary = arbitrary1     -- liftArbitrary arbB = promote (`coarbitrary` arbB)
```

`promote` (Gen.Unsafe) evaluates `\x -> coarbitrary x arbitrary` with one
fixed seed, so the generated function is deterministic: the same argument
always gives the same result. `coarbitrary` must give *independent*
generators for different arguments. `variant n` implements this for
integers with a prefix-free code: `integerVariant` writes `n` as a sequence
of left/right seed splits (one sign bit, then Elias gamma coding), so no two
integers' codes are prefixes of each other (`Random.hs` L106; tested by
upstream `tests/Split.hs`). The 2.7 changelog notes this prefix code fixed
"potential bananaskins with coarbitrary".

Built-in helpers: `coarbitraryIntegral = variant`, `coarbitraryEnum =
variant . fromEnum`, `coarbitraryReal` (via `toRational`), `coarbitraryShow`
(via the shown string), and `(><)` (composition of perturbations, from the
QuickCheck 1 idiom `variant 0 . coarbitrary x`).

## `a :-> b`: concrete functions

```haskell
data a :-> c where
  Pair  :: (a :-> (b :-> c)) -> ((a,b) :-> c)
  (:+:) :: (a :-> c) -> (b :-> c) -> (Either a b :-> c)
  Unit  :: c -> (() :-> c)
  Nil   :: a :-> c
  Table :: Eq a => [(a,c)] -> (a :-> c)
  Map   :: (a -> b) -> (b -> a) -> (b :-> c) -> (a :-> c)
```

The constructors are not exported. `function :: (a -> b) -> (a :-> b)` from
the `Function` class builds this structure **lazily**: `functionIntegral`
maps through `Integer`, whose instance splits off the sign (`Either`) and
encodes the magnitude as a list of base-256 digits (`[Word8]`), so only the
parts of the infinite table that a test actually uses are ever built. `abstract
p d` turns a representation back into a function, using the default `d`
where the representation is partial (`Nil`, missing table entries).

`Arbitrary (a :-> b)` generates `function <$> arbitrary` (a random
`CoArbitrary` function, then tabulated) and shrinks with `shrinkFun`, which
can delete parts of the representation (turning them into `Nil`, so they
fall back to the default) and shrink results.

## `Fun`

```haskell
data Fun a b = Fun (a :-> b, b, Shrunk) (a -> b)
```

- `arbitrary` builds `mkFun p d` from a random representation `p` and a
  random default `d`, marked `NotShrunk`.
- `shrink` shrinks `(p, d)` and, once, flips the flag to `Shrunk` without
  changing the function.
- `show` prints `<fun>` while `NotShrunk`, and `showFunction p (Just d)`
  (`{x1->y1, ..., _->d}`) once shrunk. The table lists only the entries the
  representation contains: after shrinking, those are the points that
  mattered for the failure.

The flag explains a surprise: with shrinking disabled, every function
counterexample prints as `<fun>` (checked with `maxShrinks = 0` against
2.19).

Patterns: `Fn f` matches any `Fun` and binds `applyFun`; `Fn2` and `Fn3`
bind curried versions of `Fun (a, b) c` and `Fun (a, b, c) d`. All three
have `COMPLETE` pragmas (since 2.14.3), so matching on them does not warn
about incomplete patterns.

## Function instances in 2.19

The module has 87 `Function` instance heads: base types, tuples up to
seven components, `Maybe`, `Either`, lists, `Ratio`, `Complex`, containers,
`Data.Monoid` wrappers, `Const`, `Identity`, and since 2.18 many more `base`
types. There is no `Function Void` instance in QuickCheck itself: the
source comment on `functionVoid` (a helper for types isomorphic to `Void`)
says that instance lives in `quickcheck-instances`. Generic deriving covers your own
algebraic types: `instance Function T` with `deriving Generic`.
