-- qik-chk-example: validity, postcondition, metamorphic and model-based
-- properties for a small binary search tree with a seeded insertion bug.
import qualified Data.List as L
import QikChkHarness
import Test.QuickCheck

data BST = Leaf | Node BST Int Int BST deriving Show

-- Bug: when the key is already present, the old value is kept.
insert :: Int -> Int -> BST -> BST
insert k v Leaf = Node Leaf k v Leaf
insert k v t@(Node l k' v' r)
  | k < k'    = Node (insert k v l) k' v' r
  | k > k'    = Node l k' v' (insert k v r)
  | otherwise = t

find :: Int -> BST -> Maybe Int
find _ Leaf = Nothing
find k (Node l k' v r)
  | k < k' = find k l
  | k > k' = find k r
  | otherwise = Just v

toList :: BST -> [(Int, Int)]
toList Leaf = []
toList (Node l k v r) = toList l ++ [(k, v)] ++ toList r

keys :: BST -> [Int]
keys = map fst . toList

valid :: BST -> Bool
valid t = let ks = keys t in and (zipWith (<) ks (drop 1 ks))

fromList :: [(Int, Int)] -> BST
fromList = foldr (uncurry insert) Leaf

instance Arbitrary BST where
  arbitrary = fromList <$> arbitrary
  shrink t = map fromList (shrink (toList t))

-- Validity: generated and transformed trees keep the ordering invariant.
prop_validArbitrary :: BST -> Bool
prop_validArbitrary = valid

prop_insertValid :: Int -> Int -> BST -> Bool
prop_insertValid k v t = valid (insert k v t)

-- Postcondition: after insert, looking up k gives v.
prop_insertPost :: Int -> Int -> BST -> Property
prop_insertPost k v t = find k (insert k v t) === Just v

-- Metamorphic: inserting twice with the same key is like inserting the
-- second value once.
prop_insertInsert :: Int -> Int -> Int -> BST -> Property
prop_insertInsert k v v' t =
  toList (insert k v' (insert k v t)) === toList (insert k v' t)

-- Model-based: compare against an association list.
prop_insertModel :: Int -> Int -> BST -> Property
prop_insertModel k v t =
  toList (insert k v t) === L.insert (k, v) (filter ((/= k) . fst) (toList t))

main :: IO ()
main = runChecks
  [ check Pass "validity of generated trees" prop_validArbitrary
  , check Pass "validity is preserved by insert (bug not visible)" prop_insertValid
  , check Fail "postcondition: find after insert" prop_insertPost
  , check Fail "metamorphic: insert twice" prop_insertInsert
  , check Fail "model-based: against an association list" prop_insertModel
  ]
