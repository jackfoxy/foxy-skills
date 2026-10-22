-- qik-chk-example: observing test data (label, collect, classify, tabulate)
-- and enforcing it (cover, coverTable, checkCoverage), plus labelledExamples.
import Data.List (delete, insert)
import QikChkHarness
import Test.QuickCheck

sorted :: Ord a => [a] -> Bool
sorted xs = and (zipWith (<=) xs (drop 1 xs))

-- classify: report a proportion; does not change the verdict.
prop_classify :: Int -> [Int] -> Property
prop_classify x xs =
  classify (null xs) "empty" $
  classify (length xs > 10) "long" $
  sorted (insert x (insert x [])) === True

-- tabulate: one table entry per value, several values per test case.
prop_tabulate :: [Int] -> Property
prop_tabulate xs =
  tabulate "signs" [if x < 0 then "neg" else if x == 0 then "zero" else "pos" | x <- xs] $
  length xs >= 0

-- cover without checkCoverage only warns; the property still passes.
prop_coverWarns :: [Int] -> Property
prop_coverWarns xs = cover 90 (length xs > 5) "longer than 5" True

-- checkCoverage turns the requirement into a statistical test that fails
-- when the requirement is (with high confidence) not met...
prop_coverChecked :: [Int] -> Property
prop_coverChecked xs = checkCoverage $ cover 90 (length xs > 5) "longer than 5" True

-- ...and passes when it is met (sometimes after running extra tests).
-- Empty lists are about 5% of default list tests (lengths are uniform in
-- 0..size, and size runs over 0..99), so require 3%, not 10%.
prop_coverMet :: [Int] -> Property
prop_coverMet xs = checkCoverage $ cover 3 (null xs) "empty" True

-- coverTable: requirements on the values collected by tabulate.
prop_coverTable :: [Int] -> Property
prop_coverTable xs =
  checkCoverage $
  coverTable "signs" [("neg", 20), ("pos", 20)] $
  tabulate "signs" [if x < 0 then "neg" else if x == 0 then "zero" else "pos" | x <- xs] $
  True

-- labelledExamples finds and shrinks one example per label.
prop_delete :: Int -> [Int] -> Property
prop_delete x xs =
  classify (count == 0) "absent" $
  classify (count == 1) "once" $
  classify (count >= 2) "repeated" $
  length (filter (== x) (delete x xs)) === max 0 (count - 1)
  where count = length (filter (== x) xs)

main :: IO ()
main = do
  putStrLn "=== labelledExamples prop_delete"
  labelledExamples prop_delete
  putStrLn ""
  runChecks
    [ check Pass "classify" prop_classify
    , check Pass "tabulate" prop_tabulate
    , check Pass "cover only warns" prop_coverWarns
    , check Fail "checkCoverage fails an unmet requirement" prop_coverChecked
    , check Pass "checkCoverage accepts a met requirement" prop_coverMet
    , check Pass "coverTable with checkCoverage" prop_coverTable
    ]
