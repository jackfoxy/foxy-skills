{-# LANGUAGE TemplateHaskell #-}
-- qik-chk-example: Template Haskell discovery of prop_ definitions, and
-- testing a polymorphic property at Integer with monomorphic.
import QikChkHarness
import Test.QuickCheck

prop_appendLength :: [Int] -> [Int] -> Bool
prop_appendLength xs ys = length (xs ++ ys) == length xs + length ys

prop_reverseAppend :: [Int] -> [Int] -> Bool
prop_reverseAppend xs ys = reverse (xs ++ ys) == reverse ys ++ reverse xs

-- Polymorphic: quickCheckAll and polyQuickCheck default the type variable
-- to Integer (not to (), as GHCi's defaulting would).
prop_polyIdentity :: Eq a => [a] -> Bool
prop_polyIdentity xs = xs == xs

-- A false polymorphic law: it only holds at a type with one value.
prop_polyAllEqual :: Eq a => a -> a -> Bool
prop_polyAllEqual x y = x == y

-- The splice must come after all prop_ definitions: TH only sees
-- declarations above a top-level splice, and `return []` creates one.
return []

main :: IO ()
main = do
  -- $allProperties lists every prop_* in this file as (name, Property).
  let names = map fst $allProperties
  mapM_ putStrLn names
  runChecks
    [ return (length names == 4)
    , check Pass "monomorphic at Integer" $(monomorphic 'prop_polyIdentity)
    , check Fail "polyAllEqual at Integer" $(monomorphic 'prop_polyAllEqual)
    -- quickCheckAll runs everything and returns True only if all pass.
    , fmap not $quickCheckAll
    ]
