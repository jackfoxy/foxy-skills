-- qik-chk-example: Gen is a function of a split seed and a size; observing
-- the "moral" monad laws, variant, promote, and the size schedule.
import QikChkHarness
import Test.QuickCheck
import Test.QuickCheck.Gen (unGen)
import Test.QuickCheck.Gen.Unsafe (promote)
import Test.QuickCheck.Random (mkQCGen)

seeds :: [Int]
seeds = [1 .. 200]

run :: Gen a -> Int -> a
run g s = unGen g (mkQCGen s) 30

-- return x >>= f and f x use different seeds for f: equal as distributions,
-- not as functions of the seed (the ICFP 2000 paper's "morally a monad").
f :: Int -> Gen Int
f x = (+ x) <$> chooseInt (0, 1000)

prop_leftIdentityPointwise :: Bool
prop_leftIdentityPointwise = all (\s -> run (return 7 >>= f) s == run (f 7) s) seeds

prop_leftIdentityInDistribution :: Bool
prop_leftIdentityInDistribution =
  let mean g = fromIntegral (sum (map (run g) seeds)) / 200 :: Double
  in abs (mean (return 7 >>= f) - mean (f 7)) < 100

-- variant k gives independent streams for different k (a prefix-free code),
-- and the same stream for the same k.
prop_variant :: Bool
prop_variant =
  let g k = variant (k :: Int) (chooseInt (0, maxBound))
  in run (g 3) 9 == run (g 3) 9 && run (g 3) 9 /= run (g 4) 9

-- promote turns a function to generators into a generator of functions;
-- the generated function is deterministic for a fixed seed.
prop_promote :: Bool
prop_promote =
  let gf = promote (\x -> (+ (x :: Int)) <$> chooseInt (0, 10)) :: Gen (Int -> Int)
      h = run gf 5
  in h 1 == h 1

-- The runner's size schedule: with maxSuccess = 100 and maxSize = 100 the
-- sizes are 0, 1, ..., 99 in order.
prop_sizeSchedule :: Property
prop_sizeSchedule = forAll getSize $ \n -> collect (n `div` 25 * 25) True

main :: IO ()
main = runChecks
  [ check Fail "left identity, seed by seed (false)" (once prop_leftIdentityPointwise)
  , check Pass "left identity, in distribution" (once prop_leftIdentityInDistribution)
  , check Pass "variant streams" (once prop_variant)
  , check Pass "promoted function is deterministic" (once prop_promote)
  , check Pass "size schedule buckets" prop_sizeSchedule
  ]
