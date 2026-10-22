-- qik-chk-example: a true law, a false law, and why a pass is evidence, not proof.
import QikChkHarness
import Test.QuickCheck

-- A true algebraic law: reversing twice is the identity.
prop_reverseTwice :: [Int] -> Bool
prop_reverseTwice xs = reverse (reverse xs) == xs

-- A false claim. QuickCheck searches for a counterexample and shrinks it;
-- the smallest list it can reach has two distinct elements.
prop_reverseIsIdentity :: [Int] -> Bool
prop_reverseIsIdentity xs = reverse xs == xs

-- A false claim that random testing usually misses: it only fails for one
-- specific large input. 100 passing tests are not a proof.
prop_rareBug :: Int -> Bool
prop_rareBug n = n /= 123456789

main :: IO ()
main = runChecks
  [ check Pass "reverse twice is identity" prop_reverseTwice
  , check Fail "reverse is identity (false)" prop_reverseIsIdentity
  , check Pass "rare bug escapes 100 tests" prop_rareBug
  ]
