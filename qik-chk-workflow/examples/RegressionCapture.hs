-- qik-chk-example: turning a shrunk counterexample into a permanent
-- regression test, and keeping the property beside it.
import QikChkHarness
import Test.QuickCheck

-- A function that used to be wrong for negative divisors (the fixed version).
safeDivMod :: Int -> Int -> Maybe (Int, Int)
safeDivMod _ 0 = Nothing
safeDivMod a b = Just (a `divMod` b)

-- The general law (a property).
prop_divModLaw :: Int -> NonZero Int -> Property
prop_divModLaw a (NonZero b) = case safeDivMod a b of
  Just (q, r) -> q * b + r === a
  Nothing -> property False

-- 1. Save the shrunk counterexample itself, not the seed: seeds are not
--    stable across QuickCheck versions or code changes, test cases are.
regressionCases :: [(Int, Int)]
regressionCases = [(-7, 2), (7, -2), (-7, -2)]

-- 2. Run the saved cases on every build with `once`, and keep them
--    separate from the randomized property.
prop_regressions :: Property
prop_regressions = once $ conjoin
  [ counterexample (show c) (prop_divModLaw a (NonZero b)) | c@(a, b) <- regressionCases ]

-- 3. The randomized property explores new inputs; give it more tests in CI.
prop_divModMore :: Property
prop_divModMore = withNumTests 2000 prop_divModLaw

-- 4. Boundaries need their own cases: the default Int generator is
--    size-bounded and never produces minBound, where divMod by -1
--    overflows. 2000 random tests pass; one explicit case fails.
prop_boundary :: Property
prop_boundary = once (prop_divModLaw minBound (NonZero (-1)))

main :: IO ()
main = runChecks
  [ check Pass "saved regression cases" prop_regressions
  , check Pass "randomized law" prop_divModMore
  , check Fail "explicit boundary case exposes overflow" prop_boundary
  ]
