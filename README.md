# `thm33`

## Usage

```
  thm33 [-t target] alphabet [p1 p2 ...]
```
where target is `sympy` (default) or `sage` and `p1`, `p2`, ...
are the patterns/factors to be avoided

## Example

Sage code for words over the alphabet `{a,b,c}` avoiding
`cba` and `aa` as a factors:

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
