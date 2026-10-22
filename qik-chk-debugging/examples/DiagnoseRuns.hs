-- qik-chk-example: diagnosing suspicious runs: watching tests and shrinks,
-- spotting skewed data, and a generator that rarely reaches the bug.
import QikChkHarness
import Test.QuickCheck

-- 1. verbose prints every test case (bounded here to five tests).
prop_watch :: Int -> Bool
prop_watch n = n * 2 `div` 2 == n

-- 2. verboseShrinking prints every failing candidate during shrinking.
prop_shrinkPath :: [Int] -> Bool
prop_shrinkPath xs = sum xs < 10

-- 3. A bug only for long inputs: the default size makes long lists rare at
--    the start of a run. The collected lengths show why it is found late.
buggyLength :: [a] -> Int
buggyLength xs = if length xs > 60 then 0 else length xs

prop_lengthBug :: [Int] -> Property
prop_lengthBug xs =
  collect (length xs `div` 20 * 20) $ buggyLength xs === length xs

-- 4. A bug that needs two equal keys of length >= 3. Independently
--    generated strings almost never collide (the 2% that do are short), so
--    the classification exposes why the default generator passes.
lookupBug :: String -> String -> Bool
lookupBug k1 k2 = k1 /= k2 || length k1 < 3

prop_collisionsDefault :: String -> String -> Property
prop_collisionsDefault a b = classify (a == b) "same key" (lookupBug a b)

-- Fix: generate the second key from the first, so equal keys are common.
prop_collisionsRelated :: Property
prop_collisionsRelated =
  forAll (listOf (elements "ab")) $ \a ->
  forAll (oneof [pure a, listOf (elements "ab")]) $ \b ->
    classify (a == b) "same key" (lookupBug a b)

main :: IO ()
main = runChecks
  [ check Pass "verbose: watch five tests" (withNumTests 5 (verbose prop_watch))
  , checkSeeded 1 Fail "verboseShrinking: watch the shrink path" (verboseShrinking prop_shrinkPath)
  , check Fail "a long-input bug, with the length distribution" (withNumTests 1000 prop_lengthBug)
  , check Pass "default strings almost never collide" prop_collisionsDefault
  , check Fail "related keys make collisions common" prop_collisionsRelated
  ]
