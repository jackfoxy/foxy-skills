-- qik-chk-example: a printer/parser round trip for arithmetic expressions,
-- with a seeded precedence bug in the printer.
import Data.Char (isDigit, isSpace)
import QikChkHarness
import Test.QuickCheck

data Expr = Lit Int | Add Expr Expr | Mul Expr Expr deriving (Show, Eq)

-- Grammar: sum := product ('+' product)* ; product := atom ('*' atom)* ;
-- atom := digits | '(' sum ')'
parseExpr :: String -> Maybe Expr
parseExpr s = case sumP (filter (not . isSpace) s) of
  Just (e, "") -> Just e
  _ -> Nothing
  where
    sumP t = prodP t >>= uncurry (chain '+' Add prodP)
    prodP t = atomP t >>= uncurry (chain '*' Mul atomP)
    chain op k next acc (c : rest) | c == op = next rest >>= \(e, r) -> chain op k next (k acc e) r
    chain _ _ _ acc rest = Just (acc, rest)
    atomP ('(' : t) = sumP t >>= \(e, r) -> case r of
      (')' : r') -> Just (e, r')
      _ -> Nothing
    atomP t = case span isDigit t of
      ("", _) -> Nothing
      (ds, r) -> Just (Lit (read ds), r)

-- Correct printer: parenthesise a sum inside a product.
pretty :: Expr -> String
pretty (Lit n) = show n
pretty (Add a b) = pretty a ++ "+" ++ pretty b
pretty (Mul a b) = factor a ++ "*" ++ factor b
  where factor e@(Add _ _) = "(" ++ pretty e ++ ")"
        factor e = pretty e

-- Buggy printer: forgets the parentheses for a sum on the right.
prettyBad :: Expr -> String
prettyBad (Lit n) = show n
prettyBad (Add a b) = prettyBad a ++ "+" ++ prettyBad b
prettyBad (Mul a b) = left a ++ "*" ++ prettyBad b
  where left e@(Add _ _) = "(" ++ prettyBad e ++ ")"
        left e = prettyBad e

-- Evaluation is the meaning that printing and parsing must preserve.
eval :: Expr -> Int
eval (Lit n) = n
eval (Add a b) = eval a + eval b
eval (Mul a b) = eval a * eval b

instance Arbitrary Expr where
  arbitrary = sized go
    where go 0 = Lit <$> choose (0, 9)
          go n = frequency [ (1, Lit <$> choose (0, 9))
                           , (2, Add <$> go (n `div` 2) <*> go (n `div` 2))
                           , (2, Mul <$> go (n `div` 2) <*> go (n `div` 2)) ]
  shrink (Lit n) = Lit <$> shrink n
  shrink (Add a b) = [a, b] ++ [Add a' b' | (a', b') <- shrink (a, b)]
  shrink (Mul a b) = [a, b, Add a b] ++ [Mul a' b' | (a', b') <- shrink (a, b)]

-- Round trip up to meaning: parsing does not restore associativity, so
-- compare values, not trees.
prop_roundTrip :: Expr -> Property
prop_roundTrip e = fmap eval (parseExpr (pretty e)) === Just (eval e)

prop_roundTripBad :: Expr -> Property
prop_roundTripBad e = fmap eval (parseExpr (prettyBad e)) === Just (eval e)

-- A second, stronger round trip: print . parse . print is stable.
prop_printStable :: Expr -> Property
prop_printStable e = (pretty <$> parseExpr (pretty e)) === Just (pretty e)

main :: IO ()
main = runChecks
  [ check Pass "correct printer round-trips" prop_roundTrip
  , check Fail "buggy printer is caught" prop_roundTripBad
  , check Pass "printing is stable through parsing" prop_printStable
  ]
