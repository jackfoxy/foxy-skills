-- qik-chk-example: precondition filtering, suchThat, and constructive generation.
import Data.List (insert, sort)
import QikChkHarness
import Test.QuickCheck

sorted :: Ord a => [a] -> Bool
sorted xs = and (zipWith (<=) xs (drop 1 xs))

-- Filtering with ==> skews the data towards short lists: most random
-- lists of length >= 3 are not sorted, so they are discarded. With the
-- default discard ratio (10) this property sits near the give-up limit;
-- raising the ratio lets it finish, but the skew remains.
prop_insertFiltered :: Int -> [Int] -> Property
prop_insertFiltered x xs =
  withDiscardRatio 100 $
  sorted xs ==> collect (length xs) (sorted (insert x xs))

-- Constructive generation: build a sorted list directly (orderedList),
-- so nothing is discarded and long lists are tested too.
prop_insertConstructive :: Int -> Property
prop_insertConstructive x =
  forAll orderedList $ \xs ->
    classify (length xs >= 5) "length >= 5" (sorted (insert x xs))

-- The OrderedList modifier is the same idea in type form.
prop_insertModifier :: Int -> OrderedList Int -> Bool
prop_insertModifier x (Ordered xs) = sorted (insert x xs)

-- suchThat retries inside the generator (raising the size after repeated
-- failures); it never discards a test, but a rare predicate makes it slow.
prop_suchThatEven :: Property
prop_suchThatEven = forAll (arbitrary `suchThat` even) $ \n -> even (n :: Int)

-- suchThatMaybe gives up and returns Nothing instead of looping.
prop_suchThatMaybe :: Property
prop_suchThatMaybe =
  forAll ((arbitrary :: Gen Int) `suchThatMaybe` (> 1000000)) $ \m ->
    label (maybe "Nothing" (const "Just") m) True

-- A long sorted list cannot be found by filtering 100 times in a row.
prop_longSortedFiltered :: [Int] -> Property
prop_longSortedFiltered xs = (length xs >= 8 && sorted xs) ==> sorted (sort xs)

main :: IO ()
main = runChecks
  [ check Pass "filtered insert (see the length skew)" prop_insertFiltered
  , check Pass "constructive insert" prop_insertConstructive
  , check Pass "OrderedList modifier" prop_insertModifier
  , check Pass "suchThat even" prop_suchThatEven
  , check Pass "suchThatMaybe gives up quietly" prop_suchThatMaybe
  , check GiveUp "long sorted lists by filtering" prop_longSortedFiltered
  ]
