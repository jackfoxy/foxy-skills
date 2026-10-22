-- qik-chk-example: core Gen combinators, modifiers, and deterministic runs.
import Data.Char (isAscii, isPrint)
import QikChkHarness
import Test.QuickCheck
import Test.QuickCheck.Gen (unGen)
import Test.QuickCheck.Random (mkQCGen)

data Colour = Red | Green | Blue deriving (Show, Eq, Enum, Bounded)

instance Arbitrary Colour where
  arbitrary = arbitraryBoundedEnum
  shrink = shrinkBoundedEnum

-- A record whose fields depend on each other: generate the bound first.
data Range = Range Int Int deriving Show

genRange :: Gen Range
genRange = do
  lo <- chooseInt (-50, 50)
  width <- chooseInt (0, 20)
  pure (Range lo (lo + width))

prop_rangeOrdered :: Property
prop_rangeOrdered = forAll genRange $ \(Range lo hi) -> lo <= hi

-- Weighted choice and enumerations.
prop_frequencyBias :: Property
prop_frequencyBias =
  forAll (frequency [(9, pure Red), (1, elements [Green, Blue])]) $ \c ->
    classify (c == Red) "red" True

-- Modifiers restrict the domain without a custom generator.
prop_modifiers :: Positive Int -> NonNegative Int -> NonEmptyList Char -> Bool
prop_modifiers (Positive p) (NonNegative n) (NonEmpty cs) =
  p > 0 && n >= 0 && not (null cs)

prop_strings :: ASCIIString -> PrintableString -> Bool
prop_strings (ASCIIString a) (PrintableString p) = all isAscii a && all isPrint p

-- Large draws from the whole range of a bounded type; plain Int is small.
prop_intIsSmall :: Int -> Bool
prop_intIsSmall n = abs n <= 100

prop_largeIsLarge :: Large Int -> Bool
prop_largeIsLarge (Large n) = abs n <= 100

-- A generator is a function of a seed and a size: same inputs, same value.
prop_deterministic :: Property
prop_deterministic = once $
  let g = vectorOf 5 (arbitrary :: Gen Int)
  in unGen g (mkQCGen 42) 30 === unGen g (mkQCGen 42) 30

-- shuffle and sublistOf preserve or restrict the elements of a list.
prop_shuffle :: [Int] -> Property
prop_shuffle xs = forAll (shuffle xs) $ \ys -> length ys === length xs

main :: IO ()
main = runChecks
  [ check Pass "dependent fields stay ordered" prop_rangeOrdered
  , check Pass "frequency biases the choice" prop_frequencyBias
  , check Pass "numeric and list modifiers" prop_modifiers
  , check Pass "string modifiers" prop_strings
  , check Pass "default Int stays within the size bound" prop_intIsSmall
  , check Fail "Large Int leaves that bound" prop_largeIsLarge
  , check Pass "unGen is deterministic for a fixed seed" prop_deterministic
  , check Pass "shuffle is a permutation" prop_shuffle
  ]
