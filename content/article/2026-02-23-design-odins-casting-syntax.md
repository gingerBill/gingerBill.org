---
{
    "title": "Designing Odin's Casting Syntax",
    "slug": "designing-odins-casting-syntax",
    "author": "Ginger Bill",
    "date": "2026-02-23",
    "categories": [
        "programming language theory",
        "programming language design",
    ],
    series: [
        "Syntax and how it Matters",
    ],
}
---

Odin's declaration syntax becomes second nature to everyone who uses the language but I do sometimes get asked ["Why are there two ways to do type conversions?"](https://odin-lang.org/docs/faq/#why-are-there-two-ways-to-do-type-conversions)[^faq].

[^faq]: Enough that I had to make an FAQ entry.


```odin
cast(type)value
type(value) or (type)(value)
```

The reason that there are two ways to do type conversions is because one approach may feel better than the other case. If you are converting a large expression, it sometimes a lot easier to use the operator-style approach, `cast(type)`. The call syntax is commonly used to specify a type of an expression which may be relatively short such as `u32(123)` or `uintptr(ptr)`.

There are two other type conversion operators, [transmute](https://odin-lang.org/docs/overview/#type-conversion) and [auto_cast](https://odin-lang.org/docs/overview/#auto-cast-operation).

The general design of this took a lot of trial and error in the early days with people giving me feedback about what felt right and wrong.

## The Syntax Ideas

Verbosity is actually a problem when you realize how much noise casting produces when you have to do it a lot, especially in a language like Odin with distinct typing (i.e. there is very little implicit type conversions, even between integers, meaning you need to do explicit casts).

I went through a plethora of different syntax for Odin's type casting:

```
x as T
x.(T) // now used for type assertions
cast(x, T)
cast(T, x)
cast(T)x // used
T(x)     // used
(T)(x)   // used
// and a few more but they were just too bad to mention
```

One thing to consider is the need for parentheses and how that can actually cause issues in terms of scannability and ergonomics (not typing but flow). The `cast(T, x)` like syntaxes actually required _more_ parentheses in practice that you might realize.

## Reflecting on the Semantics of Declarations

The flow aspect was actually interesting because I wanted the syntax to match the semantics more correctly and I found that the type must be on the left of the expression since that is how declarations work too: `name: type = value`, so a cast would make sense that way too: `name := type(value)`. This also turned out to be a similar realization in languages like Newsqueak (where that declaration syntax originates from) and Ada. This actually ruled out a lot of the other syntax options as a result.

But before that, I experimenting with `x as T` because it _seemed_ like a good idea but turned out to be a mess because of precedence rules. Either `as` was "tight" towards the expression meaning you then had to use a lot of parentheses to be clear what was being cast, or you had it very "loose" towards the expression which lead to the same problem. `as` didn't reduce the need for parentheses in practice and only led to confusion with precedence.

I then reused `x.(T)` syntax for the type assertions. One because it has some familiarity from Go but also because the "type" itself is the tag in the `union`, making it feel more like a field access using a type. The parentheses around the type in this case are necessary to remove any ambiguity syntactically and semantically.

## Optimizing for the Common Use Case

This then lead to the possibilities of `T(x)`, `cast(T)x` and `cast(T, x)`. Odin's type system is a bit different to other languages so sometimes people don't always realize the consequences. A good example of this is with the constant value system. `123` is an "untyped" number (existential typing if we are being accurate, but that confuses people so I stuck to the terminology of "untyped"), and you sometimes want this to be a specific type. Many languages "solve" this by having suffixes on literals e.g. `123i32`[^imaginary], but this is not an option in Odin because of `distinct` typing allows anyone to create their own `distinct` form of a type[^distinct-types]. So if I wanted to keep that syntax short for the most common use case of casting, `T(x)` was unironically the best option possible.

[^imaginary]: Odin also supports imaginary numbers so that could have been tokenized as `123i` thus being a little ambiguous.
[^distinct-types]: For more information on `distinct` types, check the overview: <https://odin-lang.org/docs/overview/#distinct-types>


For when a prefix style of casting was desired, doing `cast(T, x)` wasn't really aiding in reading any more than `cast(T)x`. I also didn't want then to be built-in procedures because that actually means they would not be keywords but identifiers, since even `i32` in Odin is an identifier and not a keyword. So if I wanted them to be a features of the languages using keywords, making them procedure calls felt very wrong.

## Scannability is Very Important

As I say in the [previous article](https://www.gingerbill.org/article/2026/02/21/does-syntax-matter/), I will stick to coherency over consistency if necessary, and this was on of those cases. And I didn't want to fall into the trap that some languages have done which makes the entire thing _unscannable_. Zig is a "great" example of a language with poor scannability due to its very dense and sigil-heavy syntax. And it having way too many casting operations (17+ IIRC) does not help this matter any better, nor does not actually give any real benefit in the long run to anyone (even the compiler). A real world example of this syntactic mess[^syntactic-diabetes]\:

[^syntactic-diabetes]: I am not sure what to call this but it's the exact opposute of syntactic diabetes.

```zig
const gap: f32 = @divTrunc(@as(f32, @floatFromInt(rl.getScreenWidth() - (4 * objectWidth))), 5.0);
const offsetX: f32 = @as(f32, @floatFromInt(index + 1)) * gap + @as(f32, @floatFromInt(index)) * @as(f32, @floatFromInt(objectWidth));
```

The equivalent in Odin would be written as this:

```odin
gap := math.trunc(f32(rl.GetScreenWidth() - 4 * objectWidth) / 5)
offsetX := f32(index+1) * gap + f32(index)*f32(objectWidth)
```
Note that were many of the parentheses exist in Odin, most would already exist any way, and thus all you are doing is annotating the grouped expressions with a specific type.

## Design as a Human Endeavour

All I can say is, humans are odd creatures and you'll be surprised how they think in practice. Design is about understanding humans. How they function, mentally and physically. Their perception, psychology, sociology, physiology, ergonomics, needs, desires, etc. It's all about being able to put yourself in other people's shoes, more than making _the thing_.

Designing a programming language is no exception to this. Syntax is how we express the semantics we want in a program. It's the interface to the code itself. The littlest of things matter and they do add up when you have so many little things.