-- qik-chk-example: properties that pass for the wrong reason, and the fixes.
import QikChkHarness
import Test.QuickCheck

-- 1. A precondition that random lists almost never satisfy.
--    QuickCheck gives up instead of reporting 100 meaningful tests.
sortedLong :: [Int] -> Bool
sortedLong xs = length xs >= 6 && and (zipWith (<) xs (drop 1 xs))

prop_rejectionHeavy :: [Int] -> Property
prop_rejectionHeavy xs = sortedLong xs ==> minimum xs < maximum xs

-- Fix: generate the domain directly instead of filtering it.
prop_constructive :: Property
prop_constructive =
  forAll (vectorOf 6 (choose (0, 10)) >>= return . scanl1 (+) . map (+1)) $ \xs ->
    sortedLong xs ==> minimum xs < maximum xs

-- 2. Type defaulting: with x and y at type (), "all values are equal" is true.
prop_unitEquality :: () -> () -> Bool
prop_unitEquality x y = x == y

-- Fix: give the property a type with more than one value.
prop_intEquality :: Int -> Int -> Bool
prop_intEquality x y = x == y

-- 3. A tautology: comparing an expression with itself tests nothing.
prop_tautology :: [Int] -> Bool
prop_tautology xs = reverse xs == reverse xs

main :: IO ()
main = runChecks
  [ check GiveUp "rejection-heavy precondition" prop_rejectionHeavy
  , check Pass "constructive generator" prop_constructive
  , check Pass "all () values are equal (vacuous)" prop_unitEquality
  , check Fail "all Int values are equal (false)" prop_intEquality
  , check Pass "tautology passes but specifies nothing" prop_tautology
  ]
