---
{
    "title": "Untyped Types",
    "slug": "untyped-types",
    "author": "Ginger Bill",
    "date": "2021-03-07",
    "categories": [
        "programming",
        "programming philosophy",
        "programming languages"
    ],
    "tags": [
        "philosophy",
        "c",
        "odin",
        "ada",
        "go"
    ]
}
---

When I was designing the constant value system in [Odin](https://odin-lang.org/), I wanted literals (especially numbers) to "just work". I was inspired by how both [Ada](https://www.adacore.com/about-ada)[^ada-constant] and [Go](https://golang.org/)[^go-constants] both handled their constant value systems. But this lead me to a realization that there are two general different models of thought when it comes to values in programming languages.

[^ada-constant]: https://www.adaic.org/resources/add_content/docs/95style/html/sec_3/3-2-6.html
[^go-constants]: I highly recommend reading the article regarding how Go implements its constant value system <https://blog.golang.org/constants>

* Model-1: Expressions have a type, not all expressions may have a value. Therefore all values must have a type.
* Model-2: Expressions may have a value, not all expressions have a type. Therefore some values may not have a (concrete) type.

## Value Models

### Model-1

Model-1 is the more traditional approach in most languages, especially C-like languages. This has the consequence that all literals must have a concrete type associated with them.

Using C as an example, every number literal has a type, and to change to a specific type requires a suffix:
```c
123    // int
123.0  // double
123.0f // float
123u   // unsigned int
123l   // long
123ll  // long long
123ul  // unsigned long
123ull // unsigned long long
```


#### C's Type Promotion

In C, there is a set of rules called the "usual arithmetic conversions" which are a form of implicit type promotion. Due to this concept, most people who do not realize that literals have specific types have had little issue in practice due to these implicit conversions. However, these implicit conversions may leads to many bugs, crashes, and other problems relating to portability when integers of different sizes and signedness are combined[^modern-compilers].

[^modern-compilers]: Most modern C compilers can catch these bugs but that is a patch over a design flaw rather than solution to the underlying problem.

### Model-2

Model-2 is quite different and can be very foreign to think about if you are so used to Model-1. Model-2 treats values closer to how most people intuitively think about them. The literal `123.0` just represents the _number_ one hundred and twenty three. It has no intrinsic type to it, it's just a value. Applying this idea to a programming language, the value literal `123.0` can be represented by a whole range of different types.

In Odin, all of these examples will work with the same value literal:
```odin
a: i32 = 123.0;
b: f32 = 123.0;
c: f64 = 123.0;
d: u64 = 123.0;
// etc
```

Value literals are not just limited to numbers but work for other kinds of values:
```odin
a: string  = "Hellope!";
b: cstring = "Hellope!";
c: bool    = true;
d: b32     = true;
e: rune    = '\n';
f: i32     = '\n'; // rune literals can be treated as just numbers
```

No implicit conversions _at runtime_ have been performed (unlike C) as each value can be represented without truncation.

A consequence of this model is that constants could have no (concrete) type to them:
```odin
MY_AWESOME_SOCK_COUNT :: 123.0; // named constant without a concrete type

a: i32 = MY_AWESOME_SOCK_COUNT;
b: f32 = MY_AWESOME_SOCK_COUNT;
```

In order to get this to "feel correct" and make it "just work" leads to a complication in the design of the compiler requiring a big number implementation, since numbers don't have any "size"/"width" to them. As a consequence, `~0` is an error in Odin, whilst it's perfectly valid in C because `0` has the width of `int`. In order to achieve the same thing in Odin, a type must be assigned like `~u32(0)`.


## Untyped Types

Odin supports type inference which leads to a interesting question, is the following a valid statement:
```odin
x := 123; // what is the type of 'x'?
```

There are two solutions to this problem: make this invalid since `123` has no type, give `123` a _untyped type_.

Untyped types sound like an oxymoron but it is a way to give a _default type_ to a typeless value. The literal `123` can be assigned the "untyped type" of "untyped integer".
```odin
123       // untyped integer
123.0     // untyped float
true      // untyped boolean
"hellope" // untyped string
'\n'      // untyped rune
1i        // untyped complex number
3j        // untyped quaternion
5k        // untyped quaternion
```

Each "untyped type" can be assigned a _default type_ to which if the value needs to be made concrete at runtime, it will default to that (if possible).
```
untyped integer    -> int
untyped float      -> f64
untyped boolean    -> bool
untyped string     -> string
untyped rune       -> rune
untyped complex    -> complex128
untyped quaternion -> quaternion256
```

### Comparison Operations in Odin

In Odin, comparison operations will result in the type of the expression to be an "untyped boolean". There are two reasons behind this behaviour:

* Allows any comparisons to assign to any boolean type
* Allows the backend to choose the more efficient sized operation if needed, rather than requiring a byte sized operation.

## Extra Consequences of Each Model

For Model-1, the consequence of every expression having a type requires the idea of giving a type to something with no value: `void`.

For Model-2, the consequence of some expressions not have a type does not lead a concept of `void` in the type system. I have noticed this confusion when people ask what the equivalent of `void *` is in Odin, which is `rawptr` (a separate specialized pointer type). Another consequence is that it allows for the ability for expressions to have multiple values (not tuples) associated with them, which is how Odin's multiple return values in procedures work.


## Advantages of Each Model

A common question after learning about each model is ask "what are the advantages of each model?". Personally, I think this question is actually nonsensical since you cannot compare without context due to each model having different foundational axioms. The advantages completely depend on what you are trying to aim for, the models cannot be compared out of context.

In Odin and Go, literals are "untyped" and there are (virtually) no implicit type conversions. The advantage of the untyped literals in this case is that they work for any type that can represent that value (which has no type). This also complements the [distinct](https://odin-lang.org/docs/overview/#distinct-types) type systems of both languages.

In languages with implicit type promotions, literals being typed is less of a (hypothetical) problem. If the rules can be defined without many of the issues from C, then typed literals have little disadvantages to them. Applying typed literals to a distinct type system will cause some problem since explicit casting may be required or defeats the point of distinct typing because implicit casting will be applied.
