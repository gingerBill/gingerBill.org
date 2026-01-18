---
{
    "title": "The Value Propagation Experiment",
    "slug": "value-propagation-experiment",
    "author": "Ginger Bill",
    "date": "2021-07-05",
    "categories": [
        "programming",
        "programming philosophy",
        "programming languages"
    ],
    "tags": [
        "philosophy",
        "c",
        "odin",
        "zig",
        "rust"
    ]
}
---

**[Originally from a Twitter Thread]**

[Part 2 of this Experiment](/article/2021/09/06/value-propagation-experiment-part-2/)

## The Idea

I recently experimented with adding a feature into [Odin](https://odin-lang.org/) which allowed for a way to propagate a value by early returning if that value was `false` or not `nil`. It was in a similar vein to Rust's `try!` which became [`?`](https://doc.rust-lang.org/edition-guide/rust-2018/error-handling-and-panics/the-question-mark-operator-for-easier-error-handling.html), or Zig's [`try`](https://ziglang.org/documentation/master/#try), etc.

I have now removed it from Odin. But why?

## The Problem

The hypothesis was that that this idiom was common:

```odin
x, err := foo();
if err != nil {
    return err;
}
```

where `err` may be an enum, a (discriminated) union, or any other kind of value that has `nil`.

And replace it with[^implementation]

[^implementation]: The concept of `try` worked by popping off the end value in a multiple valued expression and checking whether it was `nil` or `false`, and if so, setting the end return value to value if possible. If the procedure only had one return value, it did a simple return. If the procedure had multiple return values, `try` required that they were all named so that the end value could be assigned to by name and then an empty `return` could be called.

```c
x := try foo();
```

This construct solves a very specific kind of error handling, of which optimizes for typing code rather than reading code. It also fails because Odin (and Go) are languages with multiple return values rather than single-type returns.

And the more I think about it, the `if err != nil { return err }` and similar stuff may be the least worst option, and the best in terms of readability.

It's a question of whether you are optimizing for reading or typing, and in Odin, it has usually been reading.

And something like `x := try foo();` instead of `x, err := foo(); if err != nil { return err }` does reduce typing but `try` is a lot harder to catch (even with syntax highlighting).

It happens that Go already declined such a [proposal](https://github.com/golang/go/issues/32437#issuecomment-512035919
) for numerous reasons. And the research done for this is directly applicable to Odin because both languages share the multiple return value semantics.

The research has been fruitful however. I did experiment with a `try x else y` construct which has now become a built-in procedure `or_else(x, y)` which can be used on things with an optional-ok check e.g. map indices, type assertions
```odin
or_else(m["hellope"], 123)
or_else(x.?, true)
```

## Degenerate States

Some people may be a little surprised with my experimentation with this exception-like shorthand with error values. Especially since I wrote an article (which was originally two github comments) titled: [Exceptions — And Why Odin Will Never Have Them](/article/2018/09/05/exceptions-and-why-odin-will-never-have-them/).

One thing I did not comment on in the that article is the cause of the problem (other than the cultural issues). My hypothesis is that if you have a degenerate type ([type erasure](https://en.wikipedia.org/wiki/Type_erasure) or automatic inference), then if a value can convert to it implicitly (easily), people will (ab)use it.

So in languages with exceptions, all exception values can degenerate to the "base type". In Rust, it can either go to the base trait or be inferred parametrically. In Zig it can either do `anyerror` or it will infer the error set from usage. Go has the built-in interface type `error` which acts as the common degenerate value.

As I discuss in the article, I am not against error value propagation within a library, but I am pretty much always against it **_across_** library boundaries. A degenerate state has high entropy and a lack of specific information. And due to this form of type erasure, "downcasting" (broad use of term) is a way to recover the information, but it assumes implicit information which is not known in the type system itself.

The other issue when people pass the error up the stack for someone else to handle (something I criticize in the previous article already) is that it's common to see this in many codebases already that have such a type: Go, Rust, and Zig (public) codebases exhibit this a lot.

And my hypothesis for this phenomenon is due to the very nature of this "degenerative type".

Now a design judgement is to be made when designing a language: is such a concept worth it for the problems it intrinsically has. For Odin, I do not think it was worth it. In Odin, errors are just values, and not something special. For other languages? That's another thing. For Odin, I have found that having an error value type defined per package is absolutely fine (and ergonomic too), and minimizes, but cannot remove, the problem value propagation across library boundaries.

## Summary

`try foo()` was a bad idea for Odin consider the rest of its semantics (multiple return values, lack of error value type at the semantics level, optimizes for typing rather than reading)

`try x else y` has now become `or_else(x, y)` which is useful.


n.b. I am not criticizing any particular language's design for doing this, but rather saying that it does not work well for Odin's semantics nor philosophy.


[Part 2 of this Experiment](/article/2021/09/06/value-propagation-experiment-part-2/)
