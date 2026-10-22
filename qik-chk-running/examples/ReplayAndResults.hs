-- qik-chk-example: Args, Result fields, replaying a failure from its seed,
-- recheck, and the limits that the runner enforces.
import QikChkHarness
import Test.QuickCheck

-- Fails for lists with a sum above 30.
prop_smallSum :: [Int] -> Bool
prop_smallSum xs = sum xs <= 30

quiet :: Args
quiet = stdArgs { chatty = False }

main :: IO ()
main = do
  -- 1. Capture a failure as a value instead of printing it.
  r <- quickCheckWithResult quiet prop_smallSum
  case r of
    Failure{} -> do
      putStrLn ("failing test case: " ++ show (failingTestCase r))
      putStrLn ("reason: " ++ reason r ++ "; tests: " ++ show (numTests r)
                ++ "; shrinks: " ++ show (numShrinks r))
      putStrLn ("usedSize: " ++ show (usedSize r))
    _ -> putStrLn "unexpected: no failure"

  -- 2. Replaying the recorded seed and size reproduces the same failing case
  --    (for this QuickCheck version and the same property code).
  let replayArgs = quiet { replay = Just (usedSeed r, usedSize r) }
  r' <- quickCheckWithResult replayArgs (once prop_smallSum)
  putStrLn ("replayed test case: " ++ show (failingTestCase r'))

  -- 3. recheck does the same and prints the result.
  putStrLn "--- recheck"
  recheck r prop_smallSum

  runChecks
    [ return (isFailure r && failingTestCase r == failingTestCase r')
    -- maxSuccess / withNumTests: how many passing tests are needed.
    , checkResult quiet "maxSuccess = 500 runs 500 tests" (\x -> numTests x == 500)
        (withNumTests 500 (\xs -> reverse (reverse xs) == (xs :: [Int])))
    -- maxShrinks = 0 disables shrinking.
    , checkResult quiet { maxShrinks = 0 } "maxShrinks = 0: no shrinks"
        (\x -> isFailure x && numShrinks x == 0) prop_smallSum
    -- maxSize bounds the size parameter, so small-only bugs stay hidden.
    , checkWith quiet { maxSize = 5 } Pass "maxSize 5 hides the bug" prop_smallSum
    -- maxDiscardRatio: how many discards per success are tolerated. With
    -- ratio 1 the run gives up once discards reach 100 (or the number of
    -- passes, if larger). n > 10 holds for well under half of the tests
    -- (never at sizes 0..10), so discards win the race; a condition true
    -- about half the time (n > 0) makes the outcome a coin flip.
    , checkWith quiet { maxDiscardRatio = 1 } GiveUp "discard ratio 1"
        (\n -> n > (10 :: Int) ==> n > 10)
    , return (not (isSuccess r))
    ]
  where
    isFailure Failure{} = True
    isFailure _ = False
