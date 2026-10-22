-- qik-chk-example (manual, needs hspec): QuickCheck properties in an hspec
-- spec. Not run by run-examples.sh, whose package environment has no hspec;
-- see qik-chk-workflow/references/integration.md for how it was run.
import Test.Hspec
import Test.Hspec.QuickCheck (modifyMaxSuccess, prop)
import Test.QuickCheck

main :: IO ()
main = hspec $ do
  describe "reverse" $ do
    prop "is an involution" $ \xs ->
      reverse (reverse xs) == (xs :: [Int])
    -- hspec's own setting for the number of tests in this subtree.
    modifyMaxSuccess (const 1000) $
      prop "keeps the length" $ \xs ->
        length (reverse xs) === length (xs :: [Int])
    -- `property` turns any Testable into an hspec example.
    it "distributes over append (flipped)" $ property $ \xs ys ->
      reverse (xs ++ ys) === reverse ys ++ reverse (xs :: [Int])
  describe "a deliberately false law" $
    prop "reverse is the identity" $ \xs ->
      reverse xs == (xs :: [Int])
