-- qik-chk-example: a data structure tested by invariant, model, and
-- metamorphic properties, with a seeded bug in merge.
import Data.List (sort)
import QikChkHarness
import Test.QuickCheck

-- Leftist heap: rank of the left child >= rank of the right child, and the
-- heap order (a node is <= its children).
data Heap = E | T Int Int Heap Heap deriving Show   -- rank, value, left, right

rank :: Heap -> Int
rank E = 0
rank (T r _ _ _) = r

node :: Int -> Heap -> Heap -> Heap
node x a b = if rank a >= rank b then T (rank b + 1) x a b else T (rank a + 1) x b a

merge, mergeBad :: Heap -> Heap -> Heap
merge h E = h
merge E h = h
merge h1@(T _ x a1 b1) h2@(T _ y a2 b2)
  | x <= y = node x a1 (merge b1 h2)
  | otherwise = node y a2 (merge h1 b2)

-- Bug: on equal keys the right subtree of h1 is dropped.
mergeBad h E = h
mergeBad E h = h
mergeBad h1@(T _ x a1 b1) h2@(T _ y a2 b2)
  | x < y = node x a1 (mergeBad b1 h2)
  | x == y = node x a1 h2
  | otherwise = node y a2 (mergeBad h1 b2)

insertWith :: (Heap -> Heap -> Heap) -> Int -> Heap -> Heap
insertWith m x = m (T 1 x E E)

toSortedWith :: (Heap -> Heap -> Heap) -> Heap -> [Int]
toSortedWith _ E = []
toSortedWith m (T _ x a b) = x : toSortedWith m (m a b)

fromListWith :: (Heap -> Heap -> Heap) -> [Int] -> Heap
fromListWith m = foldr (insertWith m) E

invariant :: Heap -> Bool
invariant E = True
invariant (T r x a b) =
  r == rank b + 1 && rank a >= rank b && above a && above b && invariant a && invariant b
  where above E = True
        above (T _ y _ _) = x <= y

prop_invariant :: [Int] -> Bool
prop_invariant = invariant . fromListWith merge

prop_model :: [Int] -> Property
prop_model xs = toSortedWith merge (fromListWith merge xs) === sort xs

prop_modelBad :: [Int] -> Property
prop_modelBad xs = toSortedWith mergeBad (fromListWith mergeBad xs) === sort xs

-- Metamorphic: merging two heaps holds the elements of both.
prop_mergeUnion :: [Int] -> [Int] -> Property
prop_mergeUnion xs ys =
  toSortedWith merge (merge (fromListWith merge xs) (fromListWith merge ys))
    === sort (xs ++ ys)

main :: IO ()
main = runChecks
  [ check Pass "leftist and heap invariants" prop_invariant
  , check Pass "heap sort equals sort" prop_model
  , check Fail "buggy merge loses elements on ties" prop_modelBad
  , check Pass "merge is a multiset union" prop_mergeUnion
  ]
