-- qik-chk-example: a weak property passes a broken sort; stronger ones catch it.
import Data.List (sort)
import QikChkHarness
import Test.QuickCheck

-- A broken "sort": it removes duplicates, so it loses elements.
badSort :: [Int] -> [Int]
badSort = dedup . sort
  where dedup (x:y:zs) | x == y = dedup (y:zs)
        dedup (x:zs) = x : dedup zs
        dedup [] = []

sorted :: Ord a => [a] -> Bool
sorted xs = and (zipWith (<=) xs (drop 1 xs))

-- Weak: only the output's shape is checked. badSort satisfies it.
prop_outputSorted :: [Int] -> Bool
prop_outputSorted xs = sorted (badSort xs)

-- Stronger: also require the output to be a permutation of the input
-- (here via the same multiset of lengths and elements).
prop_sortedPermutation :: [Int] -> Property
prop_sortedPermutation xs =
  counterexample ("output: " ++ show ys) $
    sorted ys .&&. length ys === length xs
  where ys = badSort xs

-- Strongest and simplest: compare with a trusted model (Data.List.sort).
prop_model :: [Int] -> Property
prop_model xs = badSort xs === sort xs

main :: IO ()
main = runChecks
  [ check Pass "weak: output is sorted" prop_outputSorted
  , check Fail "stronger: sorted and same length" prop_sortedPermutation
  , check Fail "model: equals Data.List.sort" prop_model
  ]
