-- | Run-length encoding: the code under test.
module RunLength (encode, decode) where

import Data.List (group)

encode :: Eq a => [a] -> [(Int, a)]
encode = map (\g -> (length g, head' g)) . group
  where head' (x : _) = x
        head' [] = error "group never returns an empty group"

decode :: [(Int, a)] -> [a]
decode = concatMap (uncurry replicate)
