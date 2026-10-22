-- qik-chk-example: shrinkers must preserve what the generator guaranteed,
-- including dependencies between values, or shrinking reports a different
-- failure (here an exception) instead of the bug.
import Data.Maybe (isJust, isNothing)
import QikChkHarness
import Test.QuickCheck

-- Seeded bug: the last position of the list reads as 0.
safeAt :: [Int] -> Int -> Int
safeAt xs i = if i == length xs - 1 then 0 else xs !! i

nonEmptyShrink :: [Int] -> [[Int]]
nonEmptyShrink = filter (not . null) . shrink

-- A list (at least three elements) and an index into it, generated together.
genPair :: Gen ([Int], Int)
genPair = do
  xs <- (++) <$> vectorOf 3 (choose (1, 9)) <*> listOf (choose (1, 9))
  i <- choose (0, length xs - 1)
  pure (xs, i)

-- 1. Generator guarantee lost: listOf1 never makes [], but plain `shrink`
--    on lists does. The shrunk input crashes `!!`.
prop_emptyAfterShrink :: Property
prop_emptyAfterShrink =
  forAllShrink (listOf1 (choose (1, 9))) shrink $ \xs ->
  forAll (choose (0, length xs - 1)) $ \i ->
    safeAt xs i == xs !! i

-- 2. Dependency lost: the list stays non-empty, but the index is shrunk
--    independently of it and ends up past the end.
prop_indexAfterShrink :: Property
prop_indexAfterShrink =
  forAllShrink genPair (\p -> [ q | q@(xs, _) <- shrink p, not (null xs) ]) $
    \(xs, i) -> safeAt xs i == xs !! i

-- 3. Dependency-aware shrinker: clamp the index whenever the list shrinks.
shrinkPair :: ([Int], Int) -> [([Int], Int)]
shrinkPair (xs, i) =
  [ (xs', min i (length xs' - 1)) | xs' <- nonEmptyShrink xs ]
  ++ [ (xs, i') | i' <- shrink i, i' >= 0 ]

prop_aware :: Property
prop_aware = forAllShrink genPair shrinkPair $ \(xs, i) -> safeAt xs i == xs !! i

-- 4. Nested quantification keeps the dependency by itself: when the outer
--    list shrinks, the inner generator runs again for the new list, so the
--    index always fits (it may jump around while shrinking).
prop_nested :: Property
prop_nested =
  forAllShrink (listOf1 (choose (1, 9))) nonEmptyShrink $ \xs ->
  forAll (choose (0, length xs - 1)) $ \i ->
    safeAt xs i == xs !! i

failsWithException, failsCleanly :: Result -> Bool
failsWithException r@Failure{} = isJust (theException r)
failsWithException _ = False
failsCleanly r@Failure{} = isNothing (theException r)
failsCleanly _ = False

main :: IO ()
main = runChecks
  [ checkResult stdArgs "plain list shrink escapes listOf1" failsWithException
      prop_emptyAfterShrink
  , checkResult stdArgs "index shrunk independently of the list" failsWithException
      (withNumTests 1000 prop_indexAfterShrink)
  , checkResult stdArgs "dependency-aware shrinker finds the real bug" failsCleanly
      prop_aware
  , checkResult stdArgs "nested forAll with a non-empty shrinker" failsCleanly
      prop_nested
  ]
