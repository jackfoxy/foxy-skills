# Property catalog

Reusable shapes for [qik-chk-property-design](../SKILL.md). Each template
is written for QuickCheck 2.19 and uses `===` so failures show both sides.
Replace the placeholder functions with your own.

## Contents

- [Round trips and inverses](#round-trips-and-inverses)
- [Algebraic laws](#algebraic-laws)
- [Idempotence and normal forms](#idempotence-and-normal-forms)
- [Invariants and validity](#invariants-and-validity)
- [Postconditions](#postconditions)
- [Metamorphic relations](#metamorphic-relations)
- [Model-based and differential](#model-based-and-differential)
- [Conditional properties](#conditional-properties)
- [Negative and exception properties](#negative-and-exception-properties)
- [Anti-patterns](#anti-patterns)

## Round trips and inverses

```haskell
prop_roundTrip :: Value -> Property
prop_roundTrip v = decode (encode v) === Just v

-- When only one direction is total, test that direction; for printers and
-- parsers compare meaning if parsing does not restore the exact tree.
prop_printParse :: Expr -> Property
prop_printParse e = fmap eval (parse (pretty e)) === Just (eval e)
```

Round trips miss bugs that `encode` and `decode` share (both swap two
fields). Add at least one property that pins down the encoding itself (a
known value, or a model of the format). Worked example:
[PrintParse.hs](../../qik-chk-applications/examples/PrintParse.hs).

## Algebraic laws

```haskell
prop_assoc a b c = (a <> b) <> c === a <> (b <> (c :: T))
prop_leftId a    = mempty <> a === (a :: T)
prop_comm a b    = a `op` b === b `op` (a :: T)
prop_distrib a b c = f (a + b) === f a + f (b :: T)   -- for additive f
```

Laws are the cheapest strong properties for abstractions with an algebra
(monoids, lattices, containers). For floating point, exact laws fail; see
[FloatingPoint.hs](../../qik-chk-applications/examples/FloatingPoint.hs).

## Idempotence and normal forms

```haskell
prop_idempotent x = normalise (normalise x) === normalise (x :: T)
prop_fixedPoint x = isNormal (normalise (x :: T))
```

Idempotence alone is weak (`const c` is idempotent); pair it with a
property saying the normal form is equivalent to the input.

## Invariants and validity

```haskell
prop_genValid    = forAll genT valid            -- generator correct
prop_shrinkValid = forAll genT (all valid . shrinkT)   -- shrinker correct
prop_opValid x t = valid t ==> valid (op x t)   -- operation preserves it
```

Test the generator and the shrinker before anything else: a failure caused
by an invalid input looks like a bug in unrelated code. Executed in
[SpecStyles.hs](../examples/SpecStyles.hs) and
[InvariantShrink.hs](../../qik-chk-shrinking/examples/InvariantShrink.hs).

## Postconditions

```haskell
prop_insertPost k v t = find k (insert k v t) === Just v
prop_sortPost xs = sorted ys .&&. sameElements ys xs where ys = sort xs
```

## Metamorphic relations

Relate two runs when computing the right answer is hard:

```haskell
prop_filterDistrib p xs ys =
  filter p (xs ++ ys) === filter p xs ++ filter p ys
prop_searchMonotone q extra docs =
  results q docs `isSubsetOf` results q (docs ++ extra)
prop_shortestPathTriangle g a b c =
  dist g a c <= dist g a b + dist g b c
```

## Model-based and differential

```haskell
-- Model-based: abstract the result and compare with a simple model.
prop_insertModel k v t =
  toList (insert k v t) === modelInsert k v (toList t)

-- Differential: compare two implementations (new vs reference).
prop_fastEqualsSlow xs = fastSum xs === sum (xs :: [Int])
```

A model must be simpler than the implementation and independently
written. *How to Specify It!*'s first model-based property was itself wrong
(`Data.List.insert` keeps duplicate keys); fix the model rather than the
property.

## Conditional properties

```haskell
prop_divide n (NonZero d) = (n `div` d) * d + n `mod` d === n   -- modifier: no discards
prop_lookupPresent k v m  = k `member` m ==> lookup k m =/= Nothing   -- rare: discards
```

Prefer modifiers or generators to `==>` whenever the condition is false
for more than a small fraction of inputs.

## Negative and exception properties

```haskell
prop_mustFail = expectFailure prop_believedWrong   -- assert that a claim is false
prop_throws n = assertException (== DivideByZero) (n `div` (0 :: Int))
```

`assertException` is in `Test.QuickCheck.Monadic` (since 2.15); see
[qik-chk-monadic-state](../../qik-chk-monadic-state/SKILL.md).

## Anti-patterns

| Anti-pattern | Why it is wrong |
|---|---|
| `f x == f x` | Tautology: can never fail |
| Polymorphic property run in GHCi | Defaults to `()`; equality is always true |
| `p .&. q` meaning "both" | Tests one side per case |
| Precondition that is rarely true | Gives up, or tests only trivial inputs |
| Model that calls the implementation | Shares its bugs |
| Comparing `Double`s with `==` | False failures from rounding; and the default generator never produces NaN or infinities, so special-value bugs stay hidden |
| Asserting only shape (`sorted`, `valid`) | Accepts wrong contents |
