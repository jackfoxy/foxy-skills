# Generator recipes

Worked shapes for [qik-chk-generators](../SKILL.md), for QuickCheck 2.19.
Snippets marked **(executed)** come from the pack's examples; the others are
templates to adapt.

## Contents

- [Newtypes that carry a distribution](#newtypes-that-carry-a-distribution)
- [Dependent fields](#dependent-fields)
- [Recursive and mutually recursive types](#recursive-and-mutually-recursive-types)
- [Related inputs that collide](#related-inputs-that-collide)
- [Weighted structure and boundary cases](#weighted-structure-and-boundary-cases)
- [Generating valid programs and command sequences](#generating-valid-programs-and-command-sequences)
- [Lifting with Arbitrary1](#lifting-with-arbitrary1)
- [External generator packages](#external-generator-packages)

## Newtypes that carry a distribution

The 2000 manual's tip ("Tip: Using newtype") and the paper's unifier case
study: give domain concepts their own type so `arbitrary` can be tuned
once.

```haskell
newtype Name = Name String deriving (Eq, Show)
instance Arbitrary Name where
  arbitrary = Name <$> elements ["a", "b", "c", "d", "e"]
  shrink (Name n) = [Name m | m <- ["a"], m < n]
```

(The original manual writes `oneof ["a", "b", ...]`, which does not type
check with today's `oneof :: [Gen a] -> Gen a`; `elements` is meant.)

## Dependent fields

Generate the parts in dependency order inside `do`. **(executed)**
[GenToolkit.hs](../examples/GenToolkit.hs):

```haskell
genRange = do
  lo <- chooseInt (-50, 50)
  width <- chooseInt (0, 20)
  pure (Range lo (lo + width))
```

Shrinking such values needs the same care; see
[DependentShrink.hs](../../qik-chk-shrinking/examples/DependentShrink.hs).

## Recursive and mutually recursive types

```haskell
data Expr = Lit Int | Neg Expr | Add Expr Expr | Let String Expr Expr

genExpr :: Gen Expr
genExpr = sized go
  where
    go 0 = Lit <$> arbitrary
    go n = frequency
      [ (1, Lit <$> arbitrary)
      , (1, Neg <$> go (n - 1))
      , (2, Add <$> go (n `div` 2) <*> go (n `div` 2))
      , (1, Let <$> elements ["x", "y"] <*> go (n `div` 2) <*> go (n `div` 2)) ]

-- Mutual recursion: thread one decreasing size through both types.
data Stmt = Assign String Expr | Block [Stmt]
genStmt :: Int -> Gen Stmt
genStmt 0 = Assign <$> elements ["x", "y"] <*> resize 0 genExpr
genStmt n = oneof
  [ Assign <$> elements ["x", "y"] <*> resize (n `div` 2) genExpr
  , Block <$> (chooseInt (0, 3) >>= \k -> vectorOf k (genStmt (n `div` 4))) ]
```

Rules: every recursive call gets a strictly smaller size; size 0 has only
non-recursive constructors; unary recursion may use `n - 1`, k-ary
recursion should divide. **(executed)**
[SizedRecursion.hs](../examples/SizedRecursion.hs) shows the depth
distribution that results.

## Related inputs that collide

Independent generation rarely makes equal keys, equal strings, or a
lookup key that is present. Generate the second value *from* the first.
**(executed)** [DiagnoseRuns.hs](../../qik-chk-debugging/examples/DiagnoseRuns.hs):

```haskell
forAll (listOf (elements "ab")) $ \a ->
forAll (oneof [pure a, listOf (elements "ab")]) $ \b -> ...
```

Templates:

```haskell
-- a key that is present half of the time
genKeyFor :: Map K V -> Gen K
genKeyFor m | Map.null m = arbitrary
            | otherwise  = oneof [elements (Map.keys m), arbitrary]
```

*How to Specify It!* (section 4.6) measured only about 21% "present" for an
independently generated key and tree, the motivation for this pattern.

## Weighted structure and boundary cases

```haskell
genLength :: Gen Int
genLength = frequency
  [ (1, pure 0), (1, pure 1)          -- degenerate cases, explicitly
  , (6, sized (\n -> chooseInt (2, max 2 n))) ]

genIntWithEdges :: Gen Int
genIntWithEdges = frequency
  [ (8, arbitrary)
  , (1, elements [minBound, maxBound, 0, -1, 1]) ]
```

The default `Int` never reaches `minBound`; the `divMod minBound (-1)`
overflow in [RegressionCapture.hs](../../qik-chk-workflow/examples/RegressionCapture.hs)
passes 2000 random tests and fails one explicit case.

## Generating valid programs and command sequences

For an API with preconditions (pop needs a non-empty stack), generate each
command from the state reached so far:

```haskell
genCmds :: Model -> Int -> Gen [Cmd]
genCmds _ 0 = pure []
genCmds m n = do
  c <- elements (validCommands m)     -- only commands whose precondition holds
  (c :) <$> genCmds (step m c) (n - 1)
```

When every command is always valid, a plain `listOf` works, as in
[CommandSequences.hs](../../qik-chk-monadic-state/examples/CommandSequences.hs).
Shrinking such sequences must keep them valid; see
[qik-chk-monadic-state](../../qik-chk-monadic-state/SKILL.md).

## Lifting with Arbitrary1

For a container type constructor, write `Arbitrary1` once and get
`Arbitrary (f a)` for every element type:

```haskell
instance Arbitrary1 Bag where
  liftArbitrary g = Bag <$> listOf g
  liftShrink s (Bag xs) = Bag <$> shrinkList s xs
instance Arbitrary a => Arbitrary (Bag a) where
  arbitrary = arbitrary1
  shrink = shrink1
```

## External generator packages

These are separate packages with their own documentation; they are not
part of QuickCheck and their versions are not pinned by this pack.

| Package | Use | Source |
|---|---|---|
| `generic-random` | derive `arbitrary` from `Generic`, with size control and weights | [hackage](https://hackage.haskell.org/package/generic-random) |
| `testing-feat` | functional enumeration of algebraic types (uniform by size, exhaustive for small sizes) | [hackage](https://hackage.haskell.org/package/testing-feat) |
| `quickcheck-instances` | `Arbitrary`/`CoArbitrary`/`Function` for types in common packages (text, bytestring, time, ...) | [hackage](https://hackage.haskell.org/package/quickcheck-instances) |
| `QuickCheck-GenT`, `quickcheck-transformer` | `Gen` as a monad transformer | [GenT](https://hackage.haskell.org/package/QuickCheck-GenT), [transformer](https://hackage.haskell.org/package/quickcheck-transformer) |

The first two are named in the `Arbitrary` class documentation, the third in
the package description and README, the last two in the `Gen`
documentation.
