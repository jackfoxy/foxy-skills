-- qik-chk-example: within, discardAfter, laziness, and exceptions.
import Data.Maybe (isJust)
import QikChkHarness
import Test.QuickCheck

-- A function that is very slow for some inputs.
slowWhenLarge :: Int -> Bool
slowWhenLarge n
  | n > 50 = length [1 .. 10 ^ (8 :: Int)] > 0   -- pathological case
  | otherwise = True

-- within n: fail a test case that does not finish in n microseconds.
-- Put `within` inside the quantifier so the slow input is reported.
prop_within :: Int -> Property
prop_within n = within 100000 (slowWhenLarge n)

-- discardAfter n: discard such a test case instead of failing it.
prop_discardAfter :: Int -> Property
prop_discardAfter n = discardAfter 100000 (slowWhenLarge n)

-- Laziness: the property's Bool is evaluated; values it does not demand are
-- never evaluated, so a bottom hidden in an unused component passes.
prop_lazyPair :: Int -> Bool
prop_lazyPair n = fst (n, undefined :: Int) == n

-- total forces the whole value and reports the hidden bottom.
prop_forced :: Int -> Property
prop_forced n = total (n, if n > 3 then undefined else n :: Int)

-- A partial function called with a bad input fails with its exception.
prop_partial :: [Int] -> Property
prop_partial xs = counterexample (show xs) (minimum xs <= maximum xs)

failedWithTimeout :: Result -> Bool
failedWithTimeout r@Failure{} = take 10 (reason r) == "Timeout of"
failedWithTimeout _ = False

failedWithException :: Result -> Bool
failedWithException r@Failure{} = isJust (theException r)
failedWithException _ = False

main :: IO ()
main = runChecks
  [ checkResult stdArgs "within fails the slow case" failedWithTimeout prop_within
  , check Pass "discardAfter discards the slow case" prop_discardAfter
  , check Pass "unused bottom is never evaluated" prop_lazyPair
  , checkResult stdArgs "total exposes the bottom" failedWithException prop_forced
  , checkResult stdArgs "exception from a partial function" failedWithException prop_partial
  ]
