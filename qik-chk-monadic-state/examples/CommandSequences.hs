-- qik-chk-example: model-based testing of a stateful API with generated
-- command sequences, using only core QuickCheck (no state-machine library).
import Data.IORef
import QikChkHarness
import Test.QuickCheck

-- System under test: a bounded queue in an IORef, with a seeded bug:
-- `pop` on a queue of exactly 3 elements returns the newest, not the oldest.
data Queue = Queue (IORef [Int]) Int

newQueue :: Int -> IO Queue
newQueue cap = (\r -> Queue r cap) <$> newIORef []

push :: Queue -> Int -> IO Bool
push (Queue r cap) x = do
  xs <- readIORef r
  if length xs >= cap then return False else writeIORef r (xs ++ [x]) >> return True

pop :: Queue -> IO (Maybe Int)
pop (Queue r _) = do
  xs <- readIORef r
  case xs of
    [] -> return Nothing
    _ | length xs == 3 -> writeIORef r (init xs) >> return (Just (last xs))
    (y:ys) -> writeIORef r ys >> return (Just y)

-- The model: a pure list and a capacity.
data Cmd = Push Int | Pop deriving (Show, Eq)

type Model = [Int]

capacity :: Int
capacity = 4

-- Expected response and next model state for each command.
step :: Model -> Cmd -> (Either Bool (Maybe Int), Model)
step m (Push x)
  | length m >= capacity = (Left False, m)
  | otherwise = (Left True, m ++ [x])
step [] Pop = (Right Nothing, [])
step (y:ys) Pop = (Right (Just y), ys)

-- Commands are always valid here, so no preconditions are needed; with
-- preconditions, generate commands from the current model state instead.
genCmds :: Gen [Cmd]
genCmds = listOf (frequency [(2, Push <$> choose (0, 9)), (1, pure Pop)])

-- Shrinking a command list with the default list shrinker removes and
-- simplifies commands; every sub-list is still a valid program here.
shrinkCmds :: [Cmd] -> [[Cmd]]
shrinkCmds = shrinkList shrinkCmd
  where shrinkCmd (Push x) = Pop : map Push (shrink x)
        shrinkCmd Pop = []

prop_queueModel :: Property
prop_queueModel = forAllShrink genCmds shrinkCmds $ \cmds -> ioProperty $ do
  q <- newQueue capacity
  let go _ [] = return (property True)
      go m (c : cs) = do
        actual <- case c of
          Push x -> Left <$> push q x
          Pop -> Right <$> pop q
        let (expected, m') = step m c
        if actual /= expected
          then return (counterexample ("after " ++ show c ++ ": got " ++ show actual
                                        ++ ", model says " ++ show expected) False)
          else go m' cs
  go [] cmds

main :: IO ()
main = runChecks [ check Fail "queue against a list model" prop_queueModel ]
