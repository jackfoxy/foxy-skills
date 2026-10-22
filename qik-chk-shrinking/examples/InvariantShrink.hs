{-# LANGUAGE DeriveGeneric #-}
-- qik-chk-example: a shrinker that breaks an invariant, and one that keeps it.
import GHC.Generics (Generic)
import QikChkHarness
import Test.QuickCheck

-- Invariant: lo <= hi.
data Interval = Interval Int Int deriving (Show, Eq, Generic)

valid :: Interval -> Bool
valid (Interval lo hi) = lo <= hi

genInterval :: Gen Interval
genInterval = do
  lo <- arbitrary
  NonNegative w <- arbitrary
  pure (Interval lo (lo + w))

-- genericShrink shrinks each field independently, so it can produce
-- Interval 0 (-3) from Interval 2 (-3)... it does not know the invariant.
genericCandidates :: Interval -> [Interval]
genericCandidates = genericShrink

-- Invariant-preserving: shrink a representation that cannot be invalid
-- (start and non-negative width), then rebuild.
safeShrink :: Interval -> [Interval]
safeShrink (Interval lo hi) =
  [ Interval lo' (lo' + w') | (lo', w') <- shrink (lo, hi - lo), w' >= 0 ]

-- The code under test: width of an interval, with a seeded bug for wide
-- intervals.
width :: Interval -> Int
width (Interval lo hi) = if hi - lo > 5 then hi - lo - 1 else hi - lo

-- Using the generic shrinker, shrinking may wander into invalid intervals.
-- The precondition discards them, which costs shrink attempts but is safe.
prop_widthGeneric :: Property
prop_widthGeneric =
  forAllShrink genInterval genericCandidates $ \i ->
    valid i ==> width i == let Interval lo hi = i in hi - lo

-- The safe shrinker never leaves the domain and reaches the minimal width 6.
prop_widthSafe :: Property
prop_widthSafe =
  forAllShrink genInterval safeShrink $ \i@(Interval lo hi) ->
    width i == hi - lo

-- A direct check: the generic shrinker really produces invalid candidates.
prop_genericBreaksInvariant :: Property
prop_genericBreaksInvariant =
  forAll genInterval $ \i -> all valid (genericCandidates i)

prop_safeKeepsInvariant :: Property
prop_safeKeepsInvariant =
  forAll genInterval $ \i -> all valid (safeShrink i)

main :: IO ()
main = runChecks
  [ check Fail "generic shrinker (precondition guards it)" prop_widthGeneric
  , check Fail "invariant-preserving shrinker" prop_widthSafe
  , check Fail "genericShrink yields invalid intervals" prop_genericBreaksInvariant
  , check Pass "safe shrinker yields only valid intervals" prop_safeKeepsInvariant
  ]
