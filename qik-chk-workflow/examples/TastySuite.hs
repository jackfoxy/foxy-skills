-- qik-chk-example: QuickCheck properties inside a tasty test tree
-- (extra packages: tasty, tasty-quickcheck).
import Control.Exception (try)
import System.Exit (ExitCode (..))
import QikChkHarness
import Test.Tasty
import Test.Tasty.QuickCheck as QC

tests :: TestTree
tests = testGroup "lists"
  [ QC.testProperty "reverse is an involution" $
      \xs -> reverse (reverse xs) == (xs :: [Int])
  -- Per-test options: more tests for this property only.
  , adjustOption (\(QuickCheckTests n) -> QuickCheckTests (n * 5)) $
      QC.testProperty "append length" $
        \xs ys -> length (xs ++ ys) == length xs + length (ys :: [Int])
  -- QuickCheck's own modifiers still work inside tasty.
  , QC.testProperty "take a non-negative prefix" $
      \(NonNegative n) xs -> length (take n xs) <= length (xs :: [Int])
  ]

-- A deliberately failing tree, to show that tasty reports a failure and
-- exits non-zero (the integration a CI job relies on).
failing :: TestTree
failing = QC.testProperty "reverse is the identity (false)" $
  \xs -> reverse xs == (xs :: [Int])

runTree :: TestTree -> IO ExitCode
runTree t = either id (const ExitSuccess) <$> try (defaultMain t)

main :: IO ()
main = do
  ok <- runTree tests
  bad <- runTree failing
  runChecks [ return (ok == ExitSuccess), return (bad /= ExitSuccess) ]
