-- qik-chk-example: size-controlled recursive generation and how to observe it.
import QikChkHarness
import Test.QuickCheck

data Tree = Leaf Int | Branch Tree Tree deriving (Show, Eq)

-- The size parameter bounds the tree: halve it at each recursion and force a
-- leaf at size 0, so generation always terminates. (An unsized
-- `oneof [Leaf <$> arbitrary, Branch <$> t <*> t]` has no such bound: with
-- two recursive children chosen half of the time, the expected size is
-- infinite.)
genTree :: Gen Tree
genTree = sized go
  where
    go 0 = Leaf <$> arbitrary
    go n = frequency
      [ (1, Leaf <$> arbitrary)
      , (3, Branch <$> go (n `div` 2) <*> go (n `div` 2)) ]

instance Arbitrary Tree where
  arbitrary = genTree
  shrink (Leaf n) = Leaf <$> shrink n
  shrink (Branch l r) = [l, r] ++ [Branch l' r' | (l', r') <- shrink (l, r)]

size :: Tree -> Int
size (Leaf _) = 1
size (Branch l r) = size l + size r

depth :: Tree -> Int
depth (Leaf _) = 0
depth (Branch l r) = 1 + max (depth l) (depth r)

mirror :: Tree -> Tree
mirror t@(Leaf _) = t
mirror (Branch l r) = Branch (mirror r) (mirror l)

-- Observe the distribution while testing a real law.
prop_mirrorInvolution :: Tree -> Property
prop_mirrorInvolution t =
  collect (depth t) $ mirror (mirror t) === t

-- The size parameter really bounds the result.
prop_sizeBound :: Property
prop_sizeBound = forAll (resize 16 genTree) $ \t -> size t <= 32

-- `scale` shrinks the size seen by a sub-generator, e.g. for lists of trees.
prop_scaledLists :: Property
prop_scaledLists =
  forAll (listOf (scale (`div` 4) genTree)) $ \ts -> all ((<= 50) . size) ts

main :: IO ()
main = runChecks
  [ check Pass "mirror is an involution (depth distribution shown)" prop_mirrorInvolution
  , check Pass "resize bounds tree size" prop_sizeBound
  , check Pass "scale keeps element trees small" prop_scaledLists
  ]
