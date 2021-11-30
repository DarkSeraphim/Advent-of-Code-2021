module Day01.Part1 (solve) where
  import Text.ParserCombinators.Parsec.Char
  import Text.ParserCombinators.Parsec
  import Helpers.Input (orFail)
  import Text.Printf (printf)

  import Debug.Trace (trace)
  import Data.Set (Set, empty, insert, member)
  
  movements :: GenParser Char st [(Char, Int)]
  movements = sepBy movement (string ", ")

  movement :: GenParser Char st (Char, Int)
  movement = do
    dir <- char 'R' <|> char 'L'
    mag <- many digit
    let num = read mag
    return (dir, num)

  rot' (0, 1) 'R' = (1, 0)
  rot' (0, 1) 'L' = (-1, 0)
  rot' (1, 0) 'R' = (0, -1)
  rot' (1, 0) 'L' = (0, 1)
  rot' (0, -1) 'R' = (-1, 0)
  rot' (0, -1) 'L' = (1, 0)
  rot' (-1, 0) 'R' = (0, 1)
  rot' (-1, 0) 'L' = (0, -1)
  rot' _ _ = (0, 0)

  walk :: ((Int, Int), (Int, Int)) -> [(Char, Int)] -> (Int, Int)
  walk (dir, pos) [] = pos
  walk (dir, (x, y)) ((rot, mag):xs) = walk  ((dx, dy), (x', y')) xs
    where (dx, dy) = rot' dir rot 
          x' = x + dx * mag
          y' = y + dy * mag

  solve = do
    contents <- getLine
    moves <- orFail $ parse movements "whoops" contents
    let (x, y) = walk ((0, 1), (0, 0)) moves
    printf "You moved %d steps" (abs x + abs y)
