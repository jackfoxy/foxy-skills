-- qik-chk-example: equality reporting, conjunction, disjunction, failure
-- annotation, expected failure, totality, and witnesses.
import Control.Exception (ErrorCall (..))
import Data.List (sort)
import QikChkHarness
import Test.QuickCheck

-- === and =/= print both sides on failure; == only says "Falsified".
prop_eqReport :: [Int] -> Property
prop_eqReport xs = sort xs === xs

prop_neqReport :: Int -> Property
prop_neqReport x = x * 0 =/= 0

-- .&&. needs both sides; conjoin needs all; counterexample labels which part
-- failed.
prop_sortSpec :: [Int] -> Property
prop_sortSpec xs =
  conjoin
    [ counterexample "idempotent" (sort (sort xs) === sort xs)
    , counterexample "length kept" (length (sort xs) === length xs)
    , counterexample "first is minimum" (not (null xs) ==> take 1 (sort xs) === [minimum xs])
    ]

-- .||. passes if either side passes; disjoin generalises it.
prop_either :: Int -> Property
prop_either n = even n .||. odd n

-- .&. is different: it picks ONE side at random per test.
prop_randomSide :: Int -> Property
prop_randomSide n = (n >= 0) .&. (n <= 0)

-- expectFailure: the property is required to fail at least once.
prop_mustFail :: Property
prop_mustFail = expectFailure $ \xs -> reverse xs == (xs :: [Int])

prop_mustFailButHolds :: Property
prop_mustFailButHolds = expectFailure $ \xs -> reverse (reverse xs) == (xs :: [Int])

-- total: fully evaluates a value; a hidden error is a failure.
prop_total :: [Int] -> Property
prop_total xs = total (map (`div` 1) xs)

prop_notTotal :: [Int] -> Property
prop_notTotal xs = total (map (\x -> if x == 3 then error "boom" else x) xs)

-- An exception inside a property is a failure, reported with the exception,
-- even though the property would be True if evaluation finished. The
-- divisor is zero for a third of all inputs, so the failure is found
-- within a few tests.
prop_exception :: Int -> Bool
prop_exception n = 100 `div` (n `mod` 3) >= 0 || True

-- once: run a property exactly one time.
prop_onceOnly :: Property
prop_onceOnly = once (length "abc" === 3)

-- witness: return the failing value to the caller as a typed Haskell value.
prop_witness :: Int -> Property
prop_witness n = witness n (n < 20)

hasWitness :: Result -> Bool
hasWitness r@Failure{} = case map castWitness (witnesses r) of
  [Just n] -> (n :: Int) >= 20
  _ -> False
hasWitness _ = False

main :: IO ()
main = runChecks
  [ check Fail "=== shows both sides" prop_eqReport
  , check Fail "=/= shows both sides" prop_neqReport
  , check Pass "conjoin of three named laws" prop_sortSpec
  , check Pass ".||. disjunction" prop_either
  , check Fail ".&. tests one side per case" prop_randomSide
  , check Pass "expectFailure on a false property" prop_mustFail
  , check NoExpected "expectFailure on a true property" prop_mustFailButHolds
  , check Pass "total on a defined list" prop_total
  , check Fail "total exposes a hidden error" prop_notTotal
  , check Fail "an exception is a failure" prop_exception
  , check Pass "once" prop_onceOnly
  , checkResult stdArgs "witness returns the counterexample" hasWitness prop_witness
  ]
