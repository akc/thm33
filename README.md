# thm33

## Usage

```
  thm33 [-t target] alphabet [p1 p2 ...]
```
where target is `sympy` (default) or `sage` and `p1`, `p2`, ...
are the patterns/factors to be avoided

## Example

Calling `thm33 abc cba aa` results in SymPy code for counting words over
the alphabet `{a,b,c}` avoiding `cba` and `aa` as factors:

```
$ thm33 abc cba aa
from sympy import *
x = Symbol('x')
A = Matrix([
  [1-3*x,1,1],
  [x**5,-x**3*(1+x),-x**2*(x**2)],
  [x**5,-x**3*(0),-x**2*(1)]
])
b = Matrix([[1],[0],[0]])
F = A.solve(b)[0]
F = F.factor()
print(F)
print(series(F,n=10))
```

Executing this script, e.g. by piping through `python3`, we find the
rational generating function and the first few terms of its Taylor
series:
```
$ thm33 abc cba aa | python3 -
1/(x**2 - 3*x + 1)
1 + 3*x + 8*x**2 + 21*x**3 + 55*x**4 + 144*x**5 + 377*x**6 + 987*x**7 + 2584*x**8 + 6765*x**9 + O(x**10)
```

## Reference

L. J. Guibas and A. M. Odlyzko, [String overlaps, pattern matching, and
nontransitive games](http://www.sciencedirect.com/science/article/pii/0097316581900054),
*Journal of Combinatorial Theory, Series A*, Volume 30, Issue 2, March 1981,
Pages 183-208.
