---
{
    "title": "Multiple Return Values Research",
    "slug": "multiple-return-values-research",
    "author": "Ginger Bill",
    "date": "2021-12-15",
    "categories": [
        "philosophy",
        "programming philosophy",
        "programming languages"
    ],
    "tags": [
        "philosophy",
        "odin",
        "go",
        "lua",
        "lisp",
        "python"
    ]
}
---

I have recently been thinking about multiple return values as a concept, and wondering if there has been any kind of literature into the topic of "true" multiple return values which are not emulated through [tuples](https://en.wikipedia.org/wiki/Tuple). 
My current working hypothesis is that I think I have come to the conclusion (unless there is evidence to the contrary) [Odin](https://odin-lang.org/) has invented a new kind of type system, something to the akin of _polyadic expressions_.

It appears that [Go](https://go.dev/) and [Odin](https://odin-lang.org/) are the only ones with what I call "true" multiple return values, _but_ Odin's approach is a lot more sophisticated than Go's and extends the concept further.

Odin's idea is pretty simple: an expression may have *n*-values, where *n* is a natural number *≥0*. Meaning an expression may have 0, 1, 2, 3, 4, etc values, of which each value has a type, not that each expression has a type. An expression with 0-values has no (final) type to it (not even `void` like in some languages).

A way of thinking about this is that Odin is fundamentally a [polyadic](https://wikipedia.org/wiki/Polyad) language rather than a [monadic](https://wikipedia.org/wiki/Monad_(functional_programming)) language, like pretty much everything else. However most languages seem to be polyadic in one aspect: input parameters to procedures/functions. In most languages, you have multiple (monadic) inputs but only one (monadic) output, e.g. (`int foo(int, bool, float);`). Odin's approach is to just extend this to the rest of the language's type system, not just procedure inputs.

## Emulation with Tuples in Other Languages

In languages with [tuples](https://wikipedia.org/wiki/Tuple), they can emulate the ability to have multiple return values, especially if the language has sugar encouraging it.
Let's take [Python](https://www.python.org/) as this basic example where tuples can be used to emulate multiple return values:
```py
def foo():
    return (1, True, "hellope") # can also be written without the parentheses, as a form of syntactic "sugar"

(x, y, z) = foo() # explicit tuple syntax with a basic form of pattern matching
x, y, z = foo() # sugar for the above
a = foo() # assigning  all the values not a single (monadic) 3-tuple
```

Other languages may not use tuples to achieve multiple return values; languages such as [Common Lisp](https://lisp-lang.org/) and [Lua](http://www.lua.org/) do things slightly differently by pushing multiple values BUT the handling of the number of values is handled dynamically rather than statically:

```lua
function foo()
    return 1, true, "hellope"
end

x, y, z    = foo() -- same as Python example
x, y       = foo() -- the string value is dropped/ignore
x, y, z, w = foo() -- a value for 'w' was never returned therefore it is set to 'nil'
```

This is similar to [`values`](https://lisp-lang.org/learn/functions) in Common Lisp, Scheme, etc, of which it can suffer from exactly the same issues in terms of dropping of value bugs etc, especially due to its dynamic typing approach. A good example of this is to show that `(type-of (values x y z))` is the same as `(type-of x)` in Common Lisp.

However, dynamically typed languages are not my area of research for this specific question, statically and strongly typed ones are. And in that case, all of the languages that allow for something like multiple return values (except for Odin and Go) use tuples. However tuples can still be passed around as a singular/monadic intermediary value. Tuples are effectively a form of monad which wrap values of (possibly) different types (essentially an ad-hoc record/struct type), which some languages may allow for explicit or implicit tuple destruction.

## How Odin Differs

Odin does differ from Go on multiple return values in one important aspect: Go's approach is a bit of hack which only applies in the context of variable assignments. The following is valid in Odin but _not_ valid in Go:
```go
x, y, z := 1, foo() // assuming 'foo' returns 2 values
```

The reason being is that Go's approach for multiple returns only works in the context of assignment, and the assignment assumes that there is either N-expressions on the RHS or 1-expression on the RHS to match the N-variables on the LHS. Odin's approach is a little more sophisticated here, the assignment assumes that there are N-values on the RHS for each of the N-variables on the LHS; where the N-values may be made from M-expressions (N ≥ M).

Another fun thing about Odin because of this fact is that you can do the following (which is also not possible in Go):
```odin
foo :: proc() -> (int, bool, string) { ... }
bar :: proc(int, bool, string) { ... }

bar(foo())
```

It also means something like this is possible in Odin:
```odin
x, y, z, w := 1.34, foo() // N-variables on the LHS, N-values on the RHS

blaz :: proc() -> (bool, string) { ... }
bar(1, blaz())
```

Internally, Odin's approach could be implemented identically to as if a procedure was an input tuple + an output tuple and then automatically destructed, but semantically Odin does not support first-class tuples. n.b. For this research, implementation details are not of concern, only usage/grammar.

### Other Areas of Use In Odin

Polyadic expressions are also used in another areas of the Odin programming language. One of the most common is the optional-ok idiom[^ok-idiom]:

[^ok-idiom]: This is technically 3 different addressing modes depending on the context ([map-index, optional-ok, or optional-ok-ptr](https://github.com/odin-lang/Odin/blob/4423bc0706a6a1a64cf419720fd65bc723fdf58a/src/parser.hpp#L19-L23))

```odin
m: map[string]int
x: union{int, bool}

value, ok := m[key] // map access

v, ok := x.(int) // type assertion

// a type switch statement is more commonly seen as more cases may need to be handled
switch y in x {
case int:  ...
case bool: ...
case:      ... 
}
```

## Is Rob Pike to Blame?

I am wondering if this approach to multiple return values is all [Rob Pike](https://wikipedia.org/wiki/Rob_Pike)'s fault. Since the only languages I can find that are like what I speak of are: 

* [Alef](https://swtch.com/~rsc/thread/alef.pdf), [Limbo](http://www.vitanuova.com/inferno/papers/limbo.html), [Go](https://go.dev/) (Rob Pike related, the first two being non-destructing tuples)
* [Odin](https://odin-lang.org/) ([me](https://www.gingerbill.org/), who has been influenced by many of Pike's languages)


Alef and Limbo had multiple return values through tuples, but tuples were still not really first-class data types in those languages. In many ways, Alef and Limbo were the main precursors to Go (not just [Oberon](https://en.wikipedia.org/wiki/Oberon_(programming_language)) and [Modula](https://en.wikipedia.org/wiki/Modula)). Limbo's declaration syntax comes from [Newsqueak](https://swtch.com/~rsc/thread/newsqueak.pdf) which is also the precursor to Odin's very own declaration syntax[^on-declaration-syntax].

[^on-declaration-syntax]: https://www.gingerbill.org/article/2018/03/12/on-the-aesthetics-of-the-syntax-of-declarations/

So maybe the reason there is little literature (that I can fine) into this topic is purely because it is limited to languages related-to/influenced-by Rob Pike.

## Conclusion

It might be the approach taken by Odin may be extremely unique to Odin, however it is also one of the my favourite things about Odin too. And I am really glad I added it so early on, since it has shown its utility really quickly. Coupled with [named return values](https://odin-lang.org/docs/overview/#named-results), bare `return` statements, and [`or_return`](https://odin-lang.org/docs/overview/#or_return-statement), it is an absolute pleasure to work with.

If anyone has any more information about this topic, please feel free to contact me with it! 

P.S. If there is no research done into this area, it is a good sign since there is so much left to discover in Programming Language Theory.
