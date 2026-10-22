-- qik-chk-example: testing IO code with ioProperty and Test.QuickCheck.Monadic.
import Control.Exception (ArithException (..), evaluate)
import Data.IORef
import QikChkHarness
import Test.QuickCheck
import Test.QuickCheck.Monadic

-- A mutable counter with a seeded bug: increments above 10 are lost.
newCounter :: IO (IORef Int)
newCounter = newIORef 0

bump :: IORef Int -> Int -> IO ()
bump ref k = modifyIORef' ref (\n -> if k > 10 then n else n + k)

-- ioProperty: generate pure inputs outside the IO action (so they shrink),
-- run the action, return a Testable result.
prop_bumpIO :: [Int] -> Property
prop_bumpIO ks = ioProperty $ do
  ref <- newCounter
  mapM_ (bump ref) ks
  total' <- readIORef ref
  return (total' === sum ks)

-- PropertyM: interleave generation (pick), preconditions (pre), actions
-- (run), observations (monitor), and assertions (assert).
prop_bumpMonadic :: Property
prop_bumpMonadic = monadicIO $ do
  ks <- pick (listOf (choose (0, 10)))   -- values from pick do not shrink
  pre (not (null ks))
  ref <- run newCounter
  run (mapM_ (bump ref) ks)
  n <- run (readIORef ref)
  monitor (classify (length ks > 5) "more than five bumps")
  assert (n == sum ks)

-- assertWith attaches a message to the assertion.
prop_assertWith :: Property
prop_assertWith = monadicIO $ do
  k <- pick (choose (11, 20))
  ref <- run newCounter
  run (bump ref k)
  n <- run (readIORef ref)
  assertWith (n == k) ("bump by " ++ show k ++ " was recorded")

-- assertException / assertExceptionIO check that a specific exception occurs.
prop_divZero :: Int -> Property
prop_divZero n = assertException (== DivideByZero) (n `div` 0)

prop_divZeroIO :: Int -> Property
prop_divZeroIO n = assertExceptionIO (== DivideByZero) (evaluate (n `div` 0))

-- monadicST tests ST code without unsafePerformIO.
prop_sumST :: [Int] -> Property
prop_sumST xs = monadicST $ do
  s <- run (return (sum xs))
  assert (s == foldr (+) 0 xs)

main :: IO ()
main = runChecks
  [ check Fail "ioProperty finds the lost increment" prop_bumpIO
  , check Pass "PropertyM with small increments" prop_bumpMonadic
  , check Fail "assertWith reports its message" prop_assertWith
  , check Pass "assertException" prop_divZero
  , check Pass "assertExceptionIO" prop_divZeroIO
  , check Pass "monadicST" prop_sumST
  ]
