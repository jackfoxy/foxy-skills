-- qik-chk-example: floating-point laws need tolerances and care with
-- special values.
import QikChkHarness
import Test.QuickCheck

-- Exact associativity is false for Double.
prop_assocExact :: Double -> Double -> Double -> Bool
prop_assocExact a b c = (a + b) + c == a + (b + c)

-- A relative tolerance makes the law meaningful again for bounded inputs.
approxEq :: Double -> Double -> Bool
approxEq x y = abs (x - y) <= 1e-9 * maximum [1, abs x, abs y]

prop_assocApprox :: Double -> Double -> Double -> Bool
prop_assocApprox a b c = approxEq ((a + b) + c) (a + (b + c))

-- Round trip through a decimal string: Show/Read for Double is exact.
prop_showRead :: Double -> Bool
prop_showRead d = read (show d) == d

-- The default generator never produces NaN or infinity, so a law that
-- breaks only for them passes; test those values explicitly.
prop_selfEqual :: Double -> Bool
prop_selfEqual d = d == d

prop_selfEqualSpecial :: Property
prop_selfEqualSpecial = forAll (elements [0 / 0, 1 / 0, -1 / 0, -0.0]) $ \d -> d == d

main :: IO ()
main = runChecks
  [ check Fail "exact associativity (false)" prop_assocExact
  , check Pass "associativity with a tolerance" prop_assocApprox
  , check Pass "show/read round trip" prop_showRead
  , check Pass "x == x for generated Doubles" prop_selfEqual
  , check Fail "x == x fails for NaN" prop_selfEqualSpecial
  ]
