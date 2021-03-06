# peach

[![Build](https://travis-ci.org/joews/peach.svg?branch=master)](https://travis-ci.org/joews/peach)

A statically typed functional language.

```
fib =
  (0) => 1,
  (1) => 1,
  (x) => fib(x - 1) + fib(x - 2)

map(fib, [0 1 2 3 4 5 6 7 8 9 10])
# [ 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89 ]
```

# Syntax
Peach is inspired by JavaScript, Elm, Clojure and @bodil's [BODOL](https://github.com/bodil/BODOL), which I learned about from [this awesome talk](https://www.youtube.com/watch?v=DHubfS8E--o).

```javascript
# assignment
x = 2 # 2

# equality
x == 2 # true

# maths and stuff
x * 2 # 4

# conditionals
if (x < 10)
  `little`
else if (x < 20)
  `medium`
else
  `large`

# functions
double = x => x * 2
map(x => (pow x 2), [1, 2, 3, 4]) # [2 4 8 16]

# currying
double-all = map(double)
double-all([1 2 3 4]) # (2 4 6 8)

# pattern matching
fib =
  (0) => 1,
  (1) => 1,
  (x) => fib(x - 1) + fib(x - 2

starts-with-one =
  ([1|_]) => true,
  _  => false

# tail call optimisation
# n: the accumulating factorial
# x: a decrementing iteration count
factorial =
  (n, 1) => n,
  (n, x) => factorial((n * x), (x - 1))

factorial(1, 32768) # Infinity, because JavaScript. Better than a stack overflow!
```

# Semantics
* Static typing (with [Damas-Hindley-Milner type inference](https://en.wikipedia.org/wiki/Hindley%E2%80%93Milner_type_system))
* Pure functions
* Everything is an expression
* Immutability
* Strict evaluation
* Currying

# Features
* Minimal syntax
* A tree-based JavaScript interpreter
* REPL
* Proper tails calls

# Plans
Coming soon:
* Type hint syntax
* More stdlib
* Algebraic data types

And then:
* JavaScript interop
* JavaScript code generation
* Lazy sequences
* IO

One day:
* Efficient bytecode interpreter
* Interactive debugger
* Immutable data structures with structural sharing
* Self-hosting

# Develop

Use Node 6+.

```bash
npm install
npm test
```


