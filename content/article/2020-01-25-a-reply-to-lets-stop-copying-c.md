---
{
    "title": "A Reply to _Let's stop copying C_",
    "slug": "a-reply-to-lets-stop-copying-c",
    "author": "Ginger Bill",
    "date": "2020-01-25",
    "categories": [
        "programming language theory",
        "programming languages"
    ],
    "tags": [
        "c",
        "odin"
    ]
}
---


I read the article [Let's stop copying C](https://eev.ee/blog/2016/12/01/lets-stop-copying-c/) about 3 years ago. Recently someone brought it up again and I thought I would comment on the points being made. The article argues that newer languages ought not to copy the mistakes of C and comment on may of C's mistakes.

I recommend reading the original article first before reading this one as I will be commenting directly on the subsections of the article.

A lot of my comments will be with regards to systems-level programming languages and not programming languages in general, and I will be referring back to [my language Odin](https://odin-lang.org/) as a contrast with C.

## Textual inclusion

Back in the day when C was made, it is perfectly understandable why `#include` was used over different approaches. C was designed to be able to be implemented with a single-pass compiler[^preprocessor]. However, since the advent of more modern computers, this approach is not needed and a proper library/module/package system is a better solution to the problem. C++ approach with `namespace`s is not a solution and more of a hack.

[^preprocessor]: The preprocessor is technically a separate language on top of C, and single-pass too.

One huge annoyance with C is the issue of namespace collisions. The general approach to solve this is to make the interface to your library prefixed with something e.g. `lib_`. However, this does not guarantee that namespace collisions don't happen, and it means that you have to write these extra prefixes when you just want to write the code as normal without having to worry about all of this. From a usability standpoint, when you "import" a library, you want to be able to have those imported entities belong to its own scope which can be named with an _import name_.

The main categories of how I think most languages handle libraries in this fashion are the following:

* Python (file is the library scope)
	* `import foo`
	* `from foo import bar`
	* `from foo import *`
* Modula/Odin/Go (directory is the library scope)
	* `import "foo"`
	* `import bar "foo"`

After a lot of experimentation, I decided to settle for something like Modula for Odin as it was the best compromise in practice. I originally wanted to support single-file libraries but found that I could not get them to work with multiple-file libraries in a nice way.

There is kind of a use case for textual inclusion, and that is embedding data within the program itself. This is one of the reasons why I have the built-in procedure `#load` in Odin. This procedure takes a constant string as a file path and returns a slice of bytes of the data of that file. It's not exactly textual inclusion but it does solve some of the problems that `#include` has been used for in C.

## Optional block delimiters

In Odin, there are no optional block delimiters but if you want to do a single statement, you have to explicitly state it (as a compromise):
```odin
if condition {
	thing();
}

if condition do thing();

// Mixing {} and do is not allowed
if condition do { thing(); } // not allowed
```

## Bitwise operator precedence

C's operator precedence for bitwise operations is bad and requires an "overuse" of parentheses. I fixed this in Odin so that they feel a lot better. Getting the right precedence required a bit of experimentation to get it to _feel_ correct.

## Negative modulo

In different languages, the operator `%` is usually implemented as either dividend modulo or divisor modulo operations. In C, it is now defined as dividend. In Odin, I added the `%%` operator to solve this issue. Where `%` is dividend and `%%` is divisor. For unsigned integers, `%` and `%%` are identical, but the difference comes when using signed integers.

`%%` is equivalent to the following using `%`:

```
a %% b == ((a % b) + b) % b
```

```
a %  b = a - trunc(a/b) * b
a %% b = a - floor(a/b) * b
```

See the following for more information: <https://wikipedia.org/wiki/Modulo_operation>

## Leading zero for octal

I agree C's octal notation has many issues, and this has its routes back when bytes were not always a multiple of 8 bits. This is why Odin uses `0o777` to denote a number as octal; it is more consistent with other numeric bases too: `0b` for binary, `0o` for octal, `0d` for explicit decimal, `0z` for dozenal, `0x` for hexadecimal.

## No power operator

For a systems level programming language, having a "power" operator is not a good idea. Having an explicit `pow` procedure is a lot clearer as to what is happening for two reasons:

* It is not a cheap operation and it is rarely a single instruction on the hardware
* There are different approaches to handling the power operation, so favouring one over the other in syntax is a little weird

## C-style for loops

I agree that 90% of the time you just want a `for in` style loop. However C-style `for` loops do have their uses and getting rid of them entirely is not a great idea.

If you would like to see Odin's approach to loops, I recommend reading the overview for them at <https://odin-lang.org/docs/overview/#for-statement>.

## Switch with default fallthrough

I personally use `switch` statement as the equivalent of a jump-table and/or if-else chain. For this reason, I usually want each case to have a `break` at the end and for each case to be a separate scope too. This is why in Odin I added an explicit `fallthrough` statement and made each case its own scope.

I also extended the `switch` statement to properly understand:

* `enum` types
* discriminated `union`s
* `any` type
* Ranges
* Multiple cases

`switch` statements in Odin require all cases of `enum` and `union` to be handled by default unless explicitly specified with `#partial switch`.

If you would like to see Odin's approach to switch statements, I recommend reading the overview for them at <https://odin-lang.org/docs/overview/#switch-statement>.

## Type first

C's "type first" was a weird design decision. It was meant to expression that the type declaration is the same as how it is used in an expression. For this reason, C has given us some of the most "wonderful" declarations:

```c
int *x[3];   // array 3 of pointer to int
int (*x)[3]; // pointer to array 3 of int

_Atomic unsigned long long int const volatile *restrict foo[]; // Yeah...
```

And not to mention that type qualifiers can be in different places and still mean the same thing:

```c
int const x;
const int x;

const int *y;
int const *y;
```

C's approach also requires a symbol table whilst parsing to disambiguate between types declarations and an expression e.g.:
```
foo * bar; // Is this an expression or a declaration? You need to check the symbol table to find out
```

This is why for Odin, I went for a more Pascal-style approach to types, which is a lot easier to read, parse, and comprehend.

```odin
x: [3]^int; // array 3 of pointer to int
y: ^[3]int; // pointer to array 3 of int
```

Instead of following C's approach of "declarations match usage", Odin's approach is "types on the left, usage on the right".

```odin
x: [3]int;  // type on the LHS
x[1] = 123; // usage on the RHS

y: ^int = ...;
y^ = 123;

z: [6]^int = ...;
z[3]^ = 123;
```

Coupled with Odin's very strong and orthogonal type system, things _just work_ as expected and are easy to comprehend for mere mortals like myself.

## Weak typing


C's implicit numeric conversions and _array demotion to pointer_ conversion are a source of many bugs and confusions. C++ tried to fix some of this but still its type system is quite weak in many regards.

```c
typedef int My_Int;

int x = 123;
My_Int y = x; // this is allowed as `My_Int` is just an alias of `int`
```

Odin's strong type system is one of its extremely huge advantages. More errors are caught earlier because of it, and it allows you to do a lot more.

```odin
Int_Alias :: int;          // alias of int
My_Int    :: distinct int; // distinct type from int but keeps its properties

#assert(Int_Alias == int);
#assert(My_Int != int);

x: int = 123;
y: Int_Alias = x; // fine

z: My_Int = x; // error, an explicit cast is required
```

If you would like to see Odin's approach to `distinct` types, I recommend reading the overview for them at <https://odin-lang.org/docs/overview/#distinct-types>.


## Integer division

I disagree with this conclusion here regarding integer division. I guess dimensional analysis is baked into me as I don't usually want an expression to change the types based on the operator. If I have two integers of the same type and use an operator on them, I expect the result to be of the same type, not a new one.

```odin
z := x / y;
#assert(type_of(x) == type_of(y));
#assert(type_of(z) == type_of(y));
```

## Bytestrings

Strings are funny things because human languages are complicated things. With Odin I went with what I think is the best compromise: strings are internally byte slices with the assumption that they have UTF-8 encoding.

I am not a fan of UTF-32 strings due to their size, and UTF-16 should die out but Windows still uses the encoding pervasively.

C's null-terminated strings made sense back in the day but not any more. Storing the length with the pointer to the data is personally my preferred approach, as this allows for substrings very easily.

Along with the `string` type in Odin, Odin does support `cstring` to aid with the `foreign` system with interfacing with languages like C that have null-terminates strings.

## Increment and decrement

`++` and `--` are both a blessing and a curse in C. They are an expression which allows for things like `*ptr++` and `array[index++]` to be done. However, in a language that does not require these "hacks", these operators are quite useless. The other issue is that order of evaluation for `++` in undefined behaviour in C, so `array[index++] = ++index;` is not a good idea to do.

This is why Odin only has `+=` and `-=`.

## `!` Operator

This is mainly an aesthetic thing and I personally don't care either way. I chose `!`, `&&`, and `||` for Odin as I was trying to make an alternative to C. However, I could have easily gone down the keyword approach like Python with `not`, `and`, and `or`.

## Single return and out parameters

Multiple results are a godsend to use in Odin. They allow for numerous things where passing pointers were originally needed. In Odin, if a pointer is passed to a procedure now, it is usually implies an "in-out" parameter, coupled with the Odin's calling convention allowing certain parameters to be passed by pointer implicitly to improve performance (equivalent to an implicit `T const &` in C++).

Multiple results allow for named results which allows for a form of auto-documentation.

If you would like to see Odin's approach to multiple results, I recommend reading the overview for them at <https://odin-lang.org/docs/overview/#multiple-results>.

## Silent errors

As many know, I am not a fan of exception-style error handling, which I expressed in my [article on exceptions](/article/2018/09/05/exceptions-and-why-odin-will-never-have-them/).

With Odin's multiple results, strong type system, and `enum`s & `union`s, error handling is a lot nice to deal with.

## Nulls

I think the notion that "null" is a billion dollar mistake is well overblown. `NULL`/`nil` is just one of many invalid memory addresses, and in practice most of invalid memory address are not `NULL`. This is related to the [drunkard's search principle](https://wikipedia.org/wiki/Streetlight_effect) (a drunk man looks for his lost keys at night under a lamppost because he can see in that area). I have found that null pointers are usually very easy to find and fix, especially since most platforms reserve the first page of (virtual) memory to check for these errors.

In theory, `NULL` is still a perfectly valid memory address it is just that we have decided on the convention that `NULL` is useful for marking a pointer as unset.

Many languages now have support for maybe/option types or nullable types (monads), however I am still not a huge fan of them in practice as I rarely require them in systems-level programming. I know very well this is a "controversial" opinion, but systems-level programming languages deal with memory all the time and can easily get into "unsafe" states on purpose. Restricting this can actually make things like custom allocators very difficult to implement, along with other things[^null-pointer-topic].

Odin can technically implement a maybe type through `union` but not to the extent many people would like (especially with the syntactic sugar).

[^null-pointer-topic]: This topic alone may require an article to itself.

## Assignment as expression

I completely agree that assignment as an expression is a bad idea and causes more problems than the utility it gives.

## No hyphens in identifiers

I think using possible operators in identifiers is just waiting for trouble, even if it "looks pretty".

## Braces and semicolons

This is mainly an aesthetic thing with huge consequences. Braces and semicolons serve purposes. Braces denote a new block and semicolons terminate a statement. If you want to remove semicolons from a language, you will either need to enforce a brace style (like Go) or have sensitive white-space through something like Python's offside rule.

For Odin, I wanted braces but I did not want to enforce a code style on the use at the language level, which means that it requires semicolons.

I could have gone with Python's offside rule but I personally prefer braces even if I enjoy programming in Python.

## Blaming the programmer

A lot of the issues in C come from C's poor and lacking type system. I am not against "blaming the programmer", in theory, for a systems-level programming language because in many cases you are meant to be able to shoot your foot off if you so do wish. However, I do think providing extra structure to the type system to not require the user having to do any of this is a very good idea.


## Conclusion

A lot of C's mistakes are only mistakes in retrospective, but C is still an extremely useful language to use, and I am still extremely productive in it.

To quote Fred Brooks in his book _No Silver Bullet – Essence and Accident in Software Engineering_:

> There is no single development, in either technology or management technique, which by itself promises even one order of magnitude [tenfold] improvement within a decade in productivity, in reliability, in simplicity.

And sadly, this is _still_ true with regards to comparing C to other higher level general purpose languages, as they do not offer an order of magnitude improvement in productivity. C hit a local maximum of productive for which so many still have yet to understand why and learn from.
