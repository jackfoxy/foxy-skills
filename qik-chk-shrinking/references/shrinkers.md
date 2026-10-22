# Standard shrinkers (QuickCheck 2.19)

Companion to [qik-chk-shrinking](../SKILL.md). Definitions are in
`src/Test/QuickCheck/Arbitrary.hs` and `Modifiers.hs` at commit
`3d8fe868`.

## Contents

- [Numbers](#numbers)
- [Lists and structures](#lists-and-structures)
- [Generic shrinking](#generic-shrinking)
- [Building shrinkers from others](#building-shrinkers-from-others)
- [Modifier shrinking](#modifier-shrinking)
- [Worked candidate lists](#worked-candidate-lists)

## Numbers

**`shrinkIntegral x`** (L1481)

```haskell
[ -x | x < 0, -x > x ] ++ [ x - i | i <- takeWhile (/= 0) (iterate (`quot` 2) x) ]
```

For 10: `[0, 5, 8, 9]`. For -10: `[10, 0, -5, -8, -9]`. The 2.18 changelog
notes an improved implementation. The `-x > x` guard avoids `minBound`
(whose negation overflows).

**`shrinkRealFrac x`** (L1516): NaN shrinks to 0 and small powers of two;
infinity similarly; negatives shrink to their negation and to negated
shrinks; otherwise integers first (truncation and its shrinks), then
smaller numerators, then smaller denominators, all filtered to be strictly
smaller in magnitude (to guarantee termination).

**`shrinkDecimal x`** (L1539): candidates with fewer decimal digits (`pi`
shrinks via 3, 3.1, 3.14, ...), at most 6 digits of precision considered,
filtered to smaller magnitude. Used by `Double`, `Float`, `CFloat`,
`CDouble`, `Data.Fixed.Fixed`. The 2.14.3 changelog records that
`shrinkRealFrac` and `shrinkDecimal` were previously broken; 2.12.2 fixed an
infinite shrinking loop for fractional types.

**`shrinkBoundedEnum x`** (L1504, since 2.14.3): `shrinkIntegral` of
`fromEnum x`, keeping values `>= fromEnum minBound`; `minBound` has no
candidates. Example from the source: `shrinkBoundedEnum E9 == [E0,E5,E7,E8]`.

## Lists and structures

**`shrinkList shr xs`** (L515): for `n = length xs`, first **remove** chunks
of size `k` for `k = n, n/2, n/4, ..., 1` (every aligned position), then
**shrink one element** at a time using `shr`. Removing everything comes
first, so `[]` is the first candidate of a non-empty list.

| Type | Candidates |
|---|---|
| `Bool` | `True` to `[False]` |
| `Ordering` | `GT` to `[EQ, LT]`, `LT` to `[EQ]` |
| `Maybe a` | `Just x` to `Nothing : map Just (shrink x)` |
| `Either a b` | shrink inside the same constructor |
| `(a, b)` | `[(x', y) | x' <- shrink x] ++ [(x, y') | y' <- shrink y]` |
| `(a, b, c)` and larger | via nested pairs: one component at a time |
| `Char` | simpler characters from a fixed list (`'a'..'c'`, lower case, `'A'..'C'`, `'1'..'3'`, `' '`, `'\n'`) |
| `Set`, `Map`, `IntMap`, `Seq` | shrink the element list, rebuild with `fromList` |
| `NonEmpty a` | list shrinking, dropping empty results |
| functions `a -> b` | none (use `Fun` for shrinkable functions) |

## Generic shrinking

Requires `Generic` (GHC; disabled where `NO_GENERICS` is set).

- `subterms x`: the immediate subterms of `x` that have the same type.
- `recursivelyShrink x`: shrink each immediate field with its own `shrink`,
  one field at a time.
- `genericShrink x = subterms x ++ recursivelyShrink x` (L355).

`genericShrink` cannot know invariants and never replaces a constructor
with a simpler constructor. The class documentation's recommendation is
`shrink x = shrinkToNil x ++ genericShrink x` for types with a trivial
constructor, and warns that `shrink x = Nil : genericShrink x` loops
because it shrinks `Nil` to `Nil`.

## Building shrinkers from others

| Helper | Use |
|---|---|
| `shrinkMap f g` | shrink `b` by shrinking `g b :: a` with `a`'s `shrink`, then `map f` |
| `shrinkMapBy f g shr` | as above with an explicit `a` shrinker |
| `shrinkNothing` | `const []` |
| `liftShrink`, `liftShrink2` | shrinkers for `Arbitrary1`/`Arbitrary2` containers given element shrinkers |
| `shrink1`, `shrink2` | the lifted shrinker at the elements' own `shrink` |

`shrinkMap` preserves an invariant only if `f` re-establishes it: the
upstream test `tests/ShrinkMap.hs` checks that `shrinkMap sort id` yields
only sorted lists (that file is not wired into the cabal test suites).

## Modifier shrinking

| Modifier | Shrinking |
|---|---|
| `Positive`, `Negative`, `NonZero`, `NonNegative`, `NonPositive` | shrink the number, keep only candidates in the domain |
| `Small`, `Large` | `shrinkIntegral` |
| `NonEmptyList` | list shrinking, dropping empty lists |
| `OrderedList` | list shrinking, keeping only sorted candidates |
| `SortedList` | list shrinking, then `sort` each candidate |
| `InfiniteList` | shrinks to a finite prefix (shown as `xs ++ ...`) |
| `Fixed`, `NoShrink` | none |
| `Blind` | as the underlying value |
| `Shrink2` | `shrink x` followed by `shrink` of every candidate (two steps) |
| `Smart i x` | the shrink list reordered: candidates from position `i - 2` onward interleaved with those before |
| `Shrinking s x` | `shrinkState x s` gives `(candidate, new state)` pairs; `shrinkInit` gives the first state |
| `ASCIIString`, `UnicodeString`, `PrintableString` | list shrinking of the string |

## Worked candidate lists

```text
shrink (10 :: Int)        == [0,5,8,9]
shrink [3, 1 :: Int]      == [[],[1],[3],[0,1],[2,1],[3,0]]
shrink (Just (2 :: Int))  == [Nothing,Just 0,Just 1]
shrink (True, 'c')        == [(False,'c'),(True,'a'),(True,'b')]
```

These were evaluated in GHCi against QuickCheck 2.19.0.0
(see the [validation report](../../qik-chk-overview/references/validation-report.md)).
