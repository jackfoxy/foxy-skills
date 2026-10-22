-- qik-chk-example: shrinking traps (cycles, joint values, local minima) and
-- the controls for them.
import QikChkHarness
import Test.QuickCheck

-- Trap 1: a shrinker that can return its own input (or cycle) never ends.
-- QuickCheck stops only because of the shrink limit; withMaxShrinks makes
-- the bound explicit and small.
cyclicShrink :: Int -> [Int]
cyclicShrink n = [n, n - 1]   -- n is a candidate for itself: a loop

prop_cyclic :: Property
prop_cyclic = withMaxShrinks 200 $
  forAllShrink (choose (10, 20)) cyclicShrink $ \n -> n < 5

-- Trap 2: two values that must change together. Shrinking each
-- element on its own cannot keep them equal, so shrinking stops early
-- at a local minimum such as [7,7] instead of [0,0].
prop_noDuplicates :: [Int] -> Bool
prop_noDuplicates xs = all (\(a, b) -> a /= b) (zip xs (drop 1 xs))

-- Fix: shrink a representation where the coupling is explicit.
prop_noDuplicatesPaired :: Property
prop_noDuplicatesPaired =
  forAllShrink arbitrary (\(n, len) -> shrink (n, len)) $ \(n, NonNegative len) ->
    let xs = replicate (len + 2) (n :: Int) in prop_noDuplicates xs

-- Shrink2 also tries two consecutive shrink steps of ONE value. That does
-- not help here: escaping this local minimum needs two elements to move
-- together, which no element-wise shrinker does.
prop_noDuplicatesShrink2 :: [Shrink2 Int] -> Bool
prop_noDuplicatesShrink2 = prop_noDuplicates . map getShrink2

-- noShrinking: report the original failing input as found.
prop_noShrink :: Property
prop_noShrink = noShrinking $ \xs -> length (xs :: [Int]) < 3

main :: IO ()
main = runChecks
  [ check Fail "cyclic shrinker is cut off by withMaxShrinks" prop_cyclic
  , checkSeeded 3 Fail "independent shrinking: local minimum" prop_noDuplicates
  , check Fail "paired representation shrinks to the minimum" prop_noDuplicatesPaired
  , checkSeeded 3 Fail "Shrink2 does not escape it" prop_noDuplicatesShrink2
  , check Fail "noShrinking keeps the original input" prop_noShrink
  ]
