{-# LANGUAGE DeriveGeneric #-}
-- qik-chk-example: random functions with Fun/Function, CoArbitrary, and Blind.
import GHC.Generics (Generic)
import QikChkHarness
import Test.QuickCheck

-- 1. A false claim about every function String -> Integer. Fun can be shown,
--    and shrinking reduces it to a small table plus a default value.
prop_threeWords :: Fun String Integer -> Bool
prop_threeWords (Fun _ f) = f "monkey" == f "banana" || f "banana" == f "elephant"

-- 2. A true law, using the Fn pattern for a plain function.
prop_mapFusion :: Fun Int Int -> Fun Int Int -> [Int] -> Property
prop_mapFusion (Fn f) (Fn g) xs = map f (map g xs) === map (f . g) xs

-- 3. A false law about foldr vs foldl for an arbitrary binary function.
--    Fn2 shows the counterexample function as a finite table.
prop_foldDirection :: Fun (Int, Int) Int -> Int -> [Int] -> Property
prop_foldDirection (Fn2 f) z xs = foldr f z xs === foldl f z xs

-- 4. User-defined argument types need Function and CoArbitrary instances.
--    Generic deriving provides both for algebraic data types.
data Shape = Circle Int | Square Int Int deriving (Show, Eq, Generic)
instance Function Shape
instance CoArbitrary Shape
instance Arbitrary Shape where
  arbitrary = oneof [Circle <$> arbitrary, Square <$> arbitrary <*> arbitrary]
  shrink = genericShrink

prop_filterPartition :: Fun Shape Bool -> [Shape] -> Property
prop_filterPartition (Fn p) xs =
  length (filter p xs) + length (filter (not . p) xs) === length xs

-- 5. A type without a convenient structure: map it to one that has
--    Function (functionMap needs a bijection in both directions).
newtype Name = Name String deriving (Show, Eq)
instance Function Name where function = functionMap (\(Name s) -> s) Name
instance CoArbitrary Name where coarbitrary (Name s) = coarbitrary s
instance Arbitrary Name where arbitrary = Name <$> elements ["ann", "bob", "cy"]

prop_nameFunction :: Fun Name Int -> Name -> Bool
prop_nameFunction (Fn f) n = f n == f n

-- 6. Plain function arguments (via CoArbitrary only) cannot be shown:
--    Blind hides them as "(*)" so the property is still Testable.
prop_blind :: Blind (Int -> Int) -> Int -> Bool
prop_blind (Blind f) x = f x == f x

main :: IO ()
main = runChecks
  [ check Fail "f distinguishes three words (false)" prop_threeWords
  , check Pass "map fusion" prop_mapFusion
  , check Fail "foldr equals foldl (false)" prop_foldDirection
  , check Pass "filter partitions a list" prop_filterPartition
  , check Pass "functionMap for a newtype" prop_nameFunction
  , check Pass "Blind function argument" prop_blind
  ]
