import Data.Char
import Data.List
import Control.Monad
import System.IO
import System.Environment

{- A typical system of equations looks like this

A =
[ 1-mx      1                     1               ]
[ x^k    -x^(k-k1)poly(1,1)    -x^(k-k2)poly(2,1) ]
[ x^k    -x^(k-k1)poly(1,2)    -x^(k-k2)poly(2,2) ]

b =
[1]
[0]
[0]

-}

data Prg a = Prg Int [[a]]

data Sys a = Sys Int [[a]]

-- A term -x^i*poly
data Term = Term Int Poly

-- A row such as [x^k -x^(k-k1)poly(1,1) -x^(k-k2)poly(2,1)]
data Row = Row Int [Term]

-- The matrix A
data A = A Int [Row]

-- The matrix/vector b = [1,0,0,...,0]
data B = B Int

-- A correlation polynomial
newtype Poly = Poly [Int] deriving Eq

-- Dummy types:
data Preamble = Preamble
data Solve = Solve
data Power = Power -- power operator

data Target = Sage | SymPy

class Render a where
    render :: Target -> a -> String

instance Render Power where
    render SymPy = const "**"
    render _     = const "^"

instance Render Int where
    render _ i = show i

instance Render Char where
    render _ c = [c]

instance Render a => Render [a] where
    render t = concatMap (render t)

instance (Render a, Render b) => Render (a,b) where
    render t (a,b) = render t a ++ render t b

instance (Render a, Render b, Render c) => Render (a,b,c) where
    render t (a,b,c) = render t a ++ render t (b,c)

instance (Render a, Render b, Render c, Render d) => Render (a,b,c,d) where
    render t (a,b,c,d) = render t a ++ render t (b,c,d)

instance Render Poly where
    render t (Poly []) = "0"
    render t (Poly js) =
        concat $ intersperse "+" $ do
            j <- js
            return $ case j of
                0 -> "1"
                1 -> "x"
                _ -> render t ("x", Power, j)

instance Render Term where
    render t (Term i p) = render t ("-", Poly [i], "*") ++ paren (render t p)

instance Render Row where
    render t (Row k terms) =
        bracket (render t (Poly [k]) : (render t <$> terms))

instance Render A where
    render t (A m rows) =
        "A = Matrix" ++ paren (bracketLn (bracket row0 : (render t <$> rows)))
      where
        row0 = ("1-" ++ render t m ++ "*x") : replicate (length rows) "1"

instance Render B where
    render t (B k) =
        "b = Matrix" ++
        paren (bracket (bracket . return . render t <$> ((1 :: Int) : replicate k 0)))

instance Eq a => Render (Sys a) where
    render t (Sys m ps) = render t a ++ "\n" ++ render t b
      where
        a = A m [Row k [Term (k-i) (corr p q)  | p <- ps, let i = length p] | q <- ps ]
        b = B (length ps)
        k = sum (map length ps)

instance Eq a => Render (Prg a) where
    render t (Prg m ps) = unlines $ filter (not . null)
        [ render t Preamble
        , render t (Sys m ps)
        , render t Solve
        ]

instance Render Preamble where
    render Sage  = const $ intercalate "\n" ["x = var('x')"]
    render SymPy = const $ intercalate "\n" ["from sympy import *", "x = Symbol('x')"]

instance Render Solve where
    render Sage = const $ unlines
        [ "F = A.solve_right(b)[0][0]"
        , "F = F.factor()"
        , "print(F)"
        , "print(F.taylor(x,0,10))"
        ]
    render SymPy = const $ unlines
        [ "F = A.solve(b)[0]"
        , "F = F.factor()"
        , "print(F)"
        , "print(series(F,n=10))"
        ]

paren :: String -> String
paren s = "(" ++ s ++ ")"

bracket :: [String] -> String
bracket ss = "[" ++ intercalate "," ss ++ "]"

bracketLn :: [String] -> String
bracketLn ss = "[\n  " ++ intercalate ",\n  " ss ++ "\n]"

-- | The correlation polynomial of two strings
corr :: Eq a => [a] -> [a] -> Poly
corr xs ys = Poly
    [ j
    | (u,v,j) <- zip3 (init (tails xs)) [drop i (take k ys) | i <- [d,d-1..]] [0..]
    , u `isPrefixOf` v
    ]
  where
    k = length xs
    d = length ys - k

reduce :: Eq a => [[a]] -> [[a]]
reduce = reduce' . sortOn length
  where
    reduce' [] = []
    reduce' (p:ps) = p : reduce' (ps \\ filter (p `isInfixOf`) ps)

wordStream :: [a] -> [[[a]]]
wordStream alphabet = [[]] : [ (:) <$> alphabet <*> ws | ws <- wordStream alphabet ]

naiveCount :: Eq a => [a] -> [[a]] -> [Int]
naiveCount alphabet patterns =
    [ sum [ 1 | w <- ws, not (any (`isInfixOf` w) patterns) ]
    | ws <- wordStream alphabet
    ]

parseTarget :: String -> Maybe Target
parseTarget s
    | map toLower s == "sage" = Just Sage
    | map toLower s == "sympy" = Just SymPy
    | otherwise = Nothing

usage :: IO ()
usage = putStrLn $ intercalate "\n"
    [ "usage:"
    , ""
    , "  thm33 [-t target] alphabet [p1 p2 ...]"
    , ""
    , "where target is 'sympy' (default) or 'sage' and p1, p2, ..."
    , "are the patterns/factors to be avoided"
    ]

main = do
    args <- getArgs
    case args of

      ("--help" : _) -> usage

      ("-n" : n : alphabet : patterns) ->
          putStrLn $ intercalate ","
                   $ map show
                   $ take (read n) (naiveCount alphabet (reduce patterns))

      ("-t" : t : alphabet : patterns) ->
          case parseTarget t of
            Nothing -> hPutStrLn stderr $ "Target \"" ++ t ++ "\" isn't recognized"
            Just target -> putStr $ render target (Prg (length alphabet) (reduce patterns))

      (alphabet : patterns) ->
          putStr $ render SymPy (Prg (length alphabet) (reduce patterns))

      _ -> usage
