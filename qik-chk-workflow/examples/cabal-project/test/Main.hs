-- | The test suite: runs every property and exits non-zero if any fails,
-- which is what `cabal test` and CI rely on.
module Main (main) where

import Control.Monad (unless)
import RunLength
import System.Exit (exitFailure)
import Test.QuickCheck

prop_roundTrip :: [Bool] -> Property
prop_roundTrip xs = decode (encode xs) === xs

prop_noEmptyRuns :: [Bool] -> Bool
prop_noEmptyRuns xs = all ((> 0) . fst) (encode xs)

prop_adjacentDiffer :: [Bool] -> Bool
prop_adjacentDiffer xs = and (zipWith (/=) vs (drop 1 vs))
  where vs = map snd (encode xs)

main :: IO ()
main = do
  results <- sequence
    [ quickCheckResult prop_roundTrip
    , quickCheckResult (withNumTests 500 prop_noEmptyRuns)
    , quickCheckResult prop_adjacentDiffer
    ]
  unless (all isSuccess results) exitFailure
