# Domain recipes

Companion to [qik-chk-applications](../SKILL.md). Templates are written
against QuickCheck 2.19.0.0; the ones marked *checked* were type-checked
with GHC 9.10.3 for this pack (see
[validation-report.md](../../qik-chk-overview/references/validation-report.md)).

## Contents

- [Data structures](#data-structures)
- [Printers, parsers, serializers](#printers-parsers-serializers)
- [Lists, sorting, merging](#lists-sorting-merging)
- [Numeric code](#numeric-code)
- [Interpreters, compilers, lambda calculi](#interpreters-compilers-lambda-calculi)
- [Differential testing](#differential-testing)
- [Text and Unicode](#text-and-unicode)
- [Systems with effects](#systems-with-effects)

## Data structures

Properties, from cheapest to strongest (*How to Specify It!*):

1. **Invariant (validity)**: every operation preserves the representation
   invariant. Also check that the generator and shrinker produce valid
   values (`prop_arbitraryValid`, `prop_shrinkValid`).
2. **Postconditions**: `member k (insert k v t)`, `lookup k (insert k v t)
   == Just v`.
3. **Metamorphic**: `insert k v (insert k' v' t)` relates to the other
   order; `size (union a b) <= size a + size b`.
4. **Model**: `toList (op t) == modelOp (toList t)` against a list,
   `Data.Map`, or `Data.Set`.

```haskell
-- checked
prop_insertModel :: Int -> Int -> Tree Int Int -> Property
prop_insertModel k v t = toList (insert k v t) === Map.toList (Map.insert k v (Map.fromList (toList t)))
```

Generators: build through the API (`foldr insert empty <$> arbitrary`)
**and** generate operation programs (inserts, deletes, merges interleaved,
as in upstream `Heap_Program.hs`) so states reached by deletion appear.
Shrink with an invariant-preserving shrinker, or shrink the program that
built the value. Keys from a small range (`choose (0, 20)`) make
collisions, which test updates and deletes, common
([DiagnoseRuns.hs](../../qik-chk-debugging/examples/DiagnoseRuns.hs)).

## Printers, parsers, serializers

| Property | Use when |
|---|---|
| `parse (print x) === Just x` | the printer is injective and the parser exact |
| `fmap meaning (parse (print x)) === Just (meaning x)` | the parser normalises |
| `fmap print (parse (print x)) === Just (print x)` | print-parse-print is stable |
| `decode (encode x) === Right x` | binary or JSON codecs |
| `isLeft (parse s) || ...` on arbitrary strings | robustness: no exceptions on garbage |
| `length (encode x) <= bound x` | size limits |

Generators for ASTs: sized recursion with a leaf case at size 0 and
`size div 2` (or `div n` for `n` children); restrict leaves to printable
ranges the grammar accepts; include boundary tokens (negative numbers,
empty strings, escapes). For robustness tests, mutate valid outputs
(drop, duplicate, or swap characters) instead of fully random strings,
which the parser rejects at the first character.

Executed: [PrintParse.hs](../examples/PrintParse.hs).

## Lists, sorting, merging

- Sorting: output ordered **and** a permutation of the input (or equal to
  `Data.List.sort`). Ordered alone accepts `const []`.
- Use `OrderedList` or `sort <$> arbitrary` for sorted inputs, never
  `ordered xs ==> ...` (upstream `Merge.hs` gives up after 22 tests).
- Stability: sort pairs by key and check equal keys keep input order.
- Duplicates matter: element types with few values (`Bool`, small `Int`
  ranges) find dedup bugs
  ([WeakToStrong.hs](../../qik-chk-property-design/examples/WeakToStrong.hs)).

## Numeric code

- **Integers**: test against `Integer` arithmetic to find overflow:
  `toInteger (f x y) === g (toInteger x) (toInteger y)`. Default `Int`
  generation stays within about ±size and never produces `minBound`; use
  `Large`, `arbitraryBoundedIntegral`, or explicit boundary cases.
- **Floating point**: exact laws (associativity, distributivity) are false
  ([FloatingPoint.hs](../examples/FloatingPoint.hs): `0.1 1.0 3.1`). Use a
  relative tolerance, compare against `Rational` computations, or restrict
  to exactly representable inputs (small integers, dyadic fractions). Test
  NaN, ±Infinity, -0.0, and subnormals explicitly: the default generator
  produces none of NaN or infinity.
- `Ratio` and `Fixed` have generators; `Data.Fixed` uses
  `arbitrarySizedFractional`.
- Laws for `Num` instances: commutativity, associativity, identity,
  `abs x * signum x == x`, and `fromInteger` homomorphism.

```haskell
-- checked
approxEq :: Double -> Double -> Bool
approxEq x y = abs (x - y) <= 1e-9 * maximum [1, abs x, abs y]
```

## Interpreters, compilers, lambda calculi

- **Semantics preservation**: `eval (optimise e) === eval e`;
  `run (compile e) === eval e`; `typeOf (step e) == typeOf e` (subject
  reduction); progress: a well-typed term is a value or can step.
- **Well-scoped terms**: carry the list of bound variables in the
  generator, produce variables only from it (upstream `Lambda.hs`
  `arbExp xs n`), and filter shrunk terms to closed ones.
- **Well-typed terms**: generate by target type (`genExpr :: Type -> Int
  -> Gen Expr`), choosing constructors whose result type matches; shrink by
  replacing a subterm with a same-typed subterm.
- **Divergence**: untyped or recursive languages may loop. Use fuel in the
  evaluator (preferred), or `within` (which cannot interrupt
  non-allocating loops).
- Show terms in concrete syntax for readable counterexamples.

```haskell
-- checked
data Ty = TInt | TBool deriving (Eq, Show)
data E = I Int | B Bool | Plus E E | If E E E | Leq E E deriving Show

genE :: Ty -> Int -> Gen E
genE TInt 0 = I <$> arbitrary
genE TBool 0 = B <$> arbitrary
genE t n = oneof (genE t 0 : rules t)
  where
    m = n `div` 3
    rules TInt = [Plus <$> genE TInt m <*> genE TInt m, ifE]
    rules TBool = [Leq <$> genE TInt m <*> genE TInt m, ifE]
    ifE = If <$> genE TBool m <*> genE t m <*> genE t m
```

## Differential testing

Compare an optimised implementation with a simple reference (the
reference can be slow, or a previous version):

```haskell
-- checked
prop_fastMatchesSlow :: [Int] -> Property
prop_fastMatchesSlow xs = fastSort xs === sort xs
```

Make sure the generator reaches the fast paths (sizes above thresholds,
special alignments). `classify` on the path taken shows whether it does.

## Text and Unicode

The default `Char` generator produces ASCII three times as often as other
Unicode code points; `ASCIIString`, `UnicodeString`, `PrintableString`
modifiers narrow or widen. Test encodings (UTF-8 round trips), case
mapping (not an involution in general), and normalisation explicitly with
targeted code points; random code points rarely form combining sequences or
hit boundaries such as the surrogate range.

## Systems with effects

Files, databases, network services, caches: test against a model with
generated command sequences, fresh state per test, and cleanup with
`bracket`. See [qik-chk-monadic-state](../../qik-chk-monadic-state/SKILL.md)
and its [stateful-testing.md](../../qik-chk-monadic-state/references/stateful-testing.md).
