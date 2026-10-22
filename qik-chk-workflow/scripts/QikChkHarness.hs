-- | Tiny harness shared by the qik-chk-* executable examples.
--
-- Each example states what it expects from every property it runs, so the
-- validation script can tell a deliberately failing teaching example from a
-- regression. Examples print QuickCheck's ordinary output; this module only
-- adds a header line per check and a final verdict.
--
-- Seeds: 'checkSeeded' replays a fixed seed so that an expectation about a
-- randomized search stays stable for one QuickCheck version. A seed from one
-- QuickCheck version is not guaranteed to reproduce anything in another.
module QikChkHarness
  ( Expect(..)
  , check
  , checkWith
  , checkSeeded
  , checkResult
  , runChecks
  ) where

import Control.Monad (unless)
import System.Exit (exitFailure, exitSuccess)
import Test.QuickCheck
import Test.QuickCheck.Random (mkQCGen)

-- | What a check is expected to report.
data Expect
  = Pass       -- ^ 'Success'
  | Fail       -- ^ 'Failure' (a counterexample is expected)
  | GiveUp     -- ^ 'GaveUp' (too many discarded tests)
  | NoExpected -- ^ 'NoExpectedFailure' ('expectFailure' that did not fail)
  deriving (Eq, Show)

matches :: Expect -> Result -> Bool
matches Pass Success{} = True
matches Fail Failure{} = True
matches GiveUp GaveUp{} = True
matches NoExpected NoExpectedFailure{} = True
matches _ _ = False

-- | Run one property with 'stdArgs'.
check :: Testable prop => Expect -> String -> prop -> IO Bool
check = checkWith stdArgs

-- | Run one property with explicit 'Args'.
checkWith :: Testable prop => Args -> Expect -> String -> prop -> IO Bool
checkWith args expect name prop = do
  putStrLn ("=== " ++ name ++ " (expect " ++ show expect ++ ")")
  result <- quickCheckWithResult args prop
  let ok = matches expect result
  unless ok (putStrLn ("!!! UNEXPECTED: " ++ name))
  putStrLn ""
  return ok

-- | Run one property from a fixed seed and start size 0.
checkSeeded :: Testable prop => Int -> Expect -> String -> prop -> IO Bool
checkSeeded seed =
  checkWith stdArgs { replay = Just (mkQCGen seed, 0) }

-- | Run one property and judge the whole 'Result' with a predicate, for
-- expectations finer than pass/fail (the failure reason, an exception, the
-- shrunk test case, a replayed seed).
checkResult :: Testable prop => Args -> String -> (Result -> Bool) -> prop -> IO Bool
checkResult args name judge prop = do
  putStrLn ("=== " ++ name ++ " (expect: custom predicate)")
  result <- quickCheckWithResult args prop
  let ok = judge result
  unless ok (putStrLn ("!!! UNEXPECTED: " ++ name))
  putStrLn ""
  return ok

-- | Run all checks; exit 1 if any result differed from its expectation.
runChecks :: [IO Bool] -> IO ()
runChecks checks = do
  results <- sequence checks
  let bad = length (filter not results)
  if bad == 0
    then putStrLn ("QIK-CHK-EXAMPLE OK: " ++ show (length results) ++ " checks as expected")
      >> exitSuccess
    else putStrLn ("QIK-CHK-EXAMPLE MISMATCH: " ++ show bad ++ " unexpected result(s)")
      >> exitFailure
