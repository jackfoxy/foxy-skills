-- qik-chk manual example: NOT run by run-examples.sh (it can hang).
--
-- `within` uses System.Timeout, which interrupts a computation with an
-- asynchronous exception. GHC delivers those only at allocation/yield
-- points, so a tight loop that never allocates cannot be interrupted.
--
-- Measured with GHC 9.10.3 and QuickCheck 2.19.0.0:
--   ghc -O0 WithinTightLoop.hs                    -> fails with "Timeout of 200000 microseconds exceeded."
--   ghc -O2 WithinTightLoop.hs                    -> hangs (within never fires)
--   ghc -O2 -fno-omit-yields WithinTightLoop.hs   -> fails with the timeout again
--
-- Run it under an external limit, for example:
--   ghc -package-env "$QIK_CHK_ENV" -O2 WithinTightLoop.hs && timeout 15 ./WithinTightLoop
import Test.QuickCheck

spin :: Int -> Int
spin n = if n == -1 then 0 else spin (n + 1 - 1)

main :: IO ()
main = quickCheck (within 200000 (spin 5 == 0))
