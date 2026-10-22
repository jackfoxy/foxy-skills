# Default `Arbitrary` instances (QuickCheck 2.19)

What `arbitrary` and `shrink` do for common types, read from
`src/Test/QuickCheck/Arbitrary.hs` at commit `3d8fe868`. Since 2.17
QuickCheck has instances for most types in `base` (208 `Arbitrary` and 89
`CoArbitrary` instance heads in that file); `quickcheck-instances`
(external) covers other packages. Shrinkers are explained in
[qik-chk-shrinking](../../qik-chk-shrinking/SKILL.md).

## Numbers

| Type | `arbitrary` | `shrink` |
|---|---|---|
| `Int`, `Integer` | `arbitrarySizedIntegral`: uniform in `[-n, n]` | `shrinkIntegral` |
| `Word`, `Natural` | `arbitrarySizedNatural`: uniform in `[0, n]` | `shrinkIntegral` |
| `Int8`..`Int64`, `Word8`..`Word64`, `CInt`, `CChar`, ... | `arbitrarySizedBoundedIntegral`: bounds `±2^p` with `p` growing to the full width by size 80 | `shrinkIntegral` |
| `Double`, `Float` | `oneof` of: uniform `[0,1)`; `fromIntegral` of an `Int`; fractions with small denominators (first 0..min n 256 of an enumeration of the rationals); uniform `[-n, n]` with denominator up to n; `arbitrarySizedFractional` | `shrinkDecimal` |
| `CFloat`, `CDouble` | `arbitrarySizedFractional` | `shrinkDecimal` |
| `Ratio a` | denominator `1..max 1 n`, numerator in `[-n*d, n*d]` (0 lower bound for non-negative types) | `shrinkRealFrac` |
| `Complex a` | real and imaginary parts independently | one part at a time |
| `Data.Fixed.Fixed a` | `arbitrarySizedFractional` | `shrinkDecimal` |

Here `n` is the current size. No default numeric generator produces NaN,
infinity, or `-0.0` deliberately. Modifiers: `Small` (sized), `Large`
(sized-bounded, full range), `Positive`, `Negative`, `NonZero`, `NonNegative`,
`NonPositive` (filters with `suchThat`, shrinking stays in the domain).

## Characters and strings

| Type | `arbitrary` | `shrink` |
|---|---|---|
| `Char` | `frequency [(3, arbitraryASCIIChar), (1, arbitraryUnicodeChar)]` | candidates from `'a'..'c'`, the lower-case version, `'A'..'C'`, `'1'..'3'`, space and newline that are simpler under an order preferring lower case, then upper case, then digits |
| `String` | list of `Char` | list shrinking |
| `ASCIIString`, `UnicodeString`, `PrintableString` | lists of `arbitraryASCIIChar` / `arbitraryUnicodeChar` / `arbitraryPrintableChar` | list shrinking |

`arbitraryUnicodeChar` excludes surrogates and unassigned code points
(changelog 2.14).

## Structures

| Type | `arbitrary` | `shrink` |
|---|---|---|
| `()` | `()` | none |
| `Bool` | uniform | `True` to `False` |
| `Ordering` | uniform | `GT` to `EQ`/`LT`, `LT` to `EQ` |
| `Maybe a` | `frequency [(1, Nothing), (3, Just <$> arb)]` | `Nothing`, then shrink the payload |
| `Either a b` | `oneof [Left, Right]` | shrink within the same side |
| `[a]` | `listOf` | `shrinkList shrink` |
| `NonEmpty a` | `listOf1` | list shrinking, keeping non-empty |
| tuples (up to 10) | components independently (pairs via `liftM2`) | one component at a time (pairs: first component's candidates, then second's) |
| `Set`, `Map`, `IntSet`, `IntMap`, `Seq` | `fromList` of a generated list | shrink the list, rebuild |
| `Data.Tree.Tree` | sized random partition of the size among children | |
| functions `a -> b` | `promote (\x -> coarbitrary x arbitrary)` (needs `CoArbitrary a`) | none, and not `Show`able: see `Fun` |

The container instances carry a source warning: they aim for good
coverage of the *mathematical* values, not of internal representations, so
code working on `Data.Set.Internal` and similar should not rely on them.

## Changes that matter when reading old material

| Version | Change |
|---|---|
| 2.7 | `Int` generator made to produce only fairly small numbers; `Small`/`Large` modifiers |
| 2.10 | strings and characters include Unicode by default |
| 2.12 | `Word` generates small values like `Int` |
| 2.14 | specialised `choose*` used internally; invalid Unicode no longer generated |
| 2.14.3 | improved `Float`/`Double` instances |
| 2.17 | instances for most of `base`; lower memory use for `Double`/`Float` |
| 2.18 | more `CoArbitrary` and `Function` instances for `base` types |
| 2.19 | more `Arbitrary1` instances; compatibility instances for `OneTuple` |

Source: [changelog.md](https://github.com/nick8325/quickcheck/blob/3d8fe8686024760006ca1ca656cbdd82cd71f11e/changelog.md).
