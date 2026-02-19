---
{
    "title": "Choosing a Language Based on its Syntax?",
    "slug": "choosing-a-language-based-on-syntax",
    "author": "Ginger Bill",
    "date": "2026-02-19",
    "categories": [
        "programming language theory",
        "programming language design",
        "people",
    ],
}
---

I am still perplexed by how people judge a language purely by its **_declaration_** syntax, and will decide whether to use the language purely based on whether they like that aspect or not.

The general categories of declarations can be classified as the following:

* `type name = value`---type-focused
* `name: type = value`---name-focused
* `var name type = value`---qualifier-focused

When designing a language, if your semantics are pretty clear you can trivially change this declaration syntax and the semantics of the language will be mostly the same (if not identical). People seriously think the declaration syntax is what gives a language its "character. I do not get this train of thought in the slightest[^compiler-bias].

[^compiler-bias]: I probably do have a bias in that I know how compilers work, but even when I didn't understand, I chose languages based on my need, not on whether they "looked good".


## Syntax Doesn't Matter Until it Does

A programming language is not _merely_ its syntax. _Semantics_ actually exist, be that [denotation semantics](https://en.wikipedia.org/wiki/Denotational_semantics)[^important], [operational semantics](https://en.wikipedia.org/wiki/Operational_semantics), or [algebraic semantics](https://en.wikipedia.org/wiki/Algebraic_semantics_(computer_science)). The issue is that many inexperienced programmers don't have this mental distinction and think all languages are mostly the same but with just differing "syntax". Just wait until they are exposed to a functional programming language or a database language or even find out that a spreadsheet is a language.

[^important]: I've always found that focusing on the denotational semantics of a language is more important than focusing on the operational semantics because (for me at least) the operational semantics are "obvious" once the denotational semantics are decided upon.

I wrote an article in 2018[^old-article] about the different families of declaration syntax, but it is still weird to me how people view things when deciding whether to use a language or not. To use my language language Odin as an example, do people think this substantially changes the _semantics_ if its declaration syntax had these different looks? At best the difference here is going to be slightly more typing needed for `var` and `const`, and thus just becomes a question of ergonomics or "optimizing for typing" (which is never the bottleneck).

[^old-article]: [On the Aesthetics of the Syntax of Declarations](https://gingerbill.org/article/2018/03/12/on-the-aesthetics-of-the-syntax-of-declarations/)


```odin
// Actual Odin
x: i32 = 123
FOO :: "some constant"
bar :: proc() -> i32 {
    return 123
}
```
to this:

```pascal
// Qualifier focused
var x i32 = 123
const FOO = "some constant"
proc bar() -> i32 {
    return 123
}
```

I'd argue most of the compiler would effectively be the same for the latter approach, since it already has to disambiguate between the different kinds of declarations[^entities]. However each syntax family does have its own trade-offs which allow or prevent certain possibilities.

[^entities]: Internally within the compiler, they are called _entities_. Some other compilers will use the term _symbol_, and other terms.

> Syntax restricts the possibilities of what semantics are possible.

## Semicolons in "The Current Year"

The other similar thing I've seen numerous times before across numerous languages:

> Semicolons in \<insert-current-year\>? Why do you still have them, haven't you learnt that we don't need them any more?. <footer>Some Rando</footer>

From what I gather, this sentiment of not understanding why many "modern" languages still use semicolons is either:

* From people having bad error reporting when forgetting a semicolon
* Not liking the naïve aesthetics of semicolons
* From people who don't even know the very basics of parsing nor the function of what a semicolon is in many languages (statement terminators/separators[^separators])

[^separators]: Pascals initially used semicolons as statement separators, similar to using a comma, whilst languages in the C-family used semicolons as statement terminators. Eventually most Pascal compilers allowed the user to have an extra semicolon at the end allowing them to pretend to be terminators or separators.

When I first created Odin, semicolons were mostly required and inferred in many places but I eventually made semicolons fully optional as statement terminators. There were two reasons I made them optional:

* To make the grammar consistent, coherent, and simpler
* To honestly shut up these kinds of bizarre people

That second point might sound silly but it really was a thing where people were put off even _trying_ Odin due to it having semicolons. The first point was the main reason I did it though, especially since even at work, many of my colleagues still use semicolons in the codebase purely out of habit from programming in C/C++ for decades[^removal].

[^removal]: We will eventually clean this up, even if removing unnecessary semicolons simple from our codebase is as simple as calling `odin strip-semicolon`.

However making semicolons optional in a language can come with a few compromises. One option is to design the grammar such that they are "obvious" to infer their usage. Lua is an example of such a language, and when a semicolon is necessary is when you have something that could be misconstrued as being a call:

```lua
(function() print("Test1") end)(); -- That semicolon is required
(function() print("Test2") end)()
```

Another option is to do something like automatic semicolon insertion (ASI) based on a set of rules. Unfortunately, a lot of people's first experience with this kind of approach is JavaScript and its really poor implementation of it, which means people usually just write semicolons regardless to remove the possible mistakes. However there are languages that have relatively sane approaches to ASI such as Go, Python, and Odin.

Go's approach is purely a lexical rule, which does mean you are forced to do things like trailing commas in lists that span multiple lines. However this is probably not just done for simplicity but also to enforce a code styling.

Python and Odin's approach is both a lexical rule + syntactical rule. Odin's lexical rule is very similar to Go's but with the added syntactical rules, it makes it a lot less annoying to use and allows for more code styling options. The rules that Odin does (which is very similar to Python) is to ignore newline-based "semicolons" within brackets (`( )` and `[ ]`, and `{ }` used as an expression or record block).


## First Exposure Bias

How is it that people literally choose a language purely on the most minute syntax issues rather than on the (denotational or operational) semantics? Or do most people not actually "program" but just "pattern match" syntax together and _hope_ it works?

Maybe I don't need to be as cynical and it is a lot simpler than all of that: **first exposure bias**. It's the tendency for an individual to develop a _preference_ simply because they became familiar with it first, rather that it be a rational choice from a plethora of options. People keep to what they are familiar with, which can be rational. But saying they don't like something without even trying it, is a bit irrational.

## Syntax Decisions

I've written about how C's [declarations match usage](https://www.gingerbill.org/article/2020/01/25/a-reply-to-lets-stop-copying-c/#heading-2-9), which I'd argue most people don't realize unless they have made C parser/compiler[^spec]. Most people think C's declaration syntax is either just type-first or something arcane that you just randomly guess at. For Odin, I designed the syntax for types to be more Pascal-style to improve reading, parsing, and comprehension:

[^spec]: Or read the C spec.

```odin
x: [3]^int // array 3 of pointer to int
y: ^[3]int // pointer to array 3 of int
```

The unfortunate equivalent of this in C would be:

```c
int *x[3];   // array 3 of pointer to int
int (*y)[3]; // pointer to array 3 of int
```

Instead of following C's approach of "declarations match usage", Odin's approach is "types on the left, usage on the right":

```odin
x: [3]int  // type on the LHS
x[1] = 123 // usage on the RHS

y: ^int = ...
y^ = 123

z: [6]^int = ...
z[3]^ = 123
```

Coupled with Odin’s very strong and orthogonal type system, things _just work_<sup><small>TM</small></sup> as expected and are easy to comprehend for mere mortals like myself.

I have seen many criticisms of Odin's usage of a caret `^` for pointers[^pointers-criticism] due to them being dead keys on many keyboard layouts, but due to Odin's type inference system through `:=`, auto-dereferencing (`x^.y` becomes `x.y`), a much better type system (e.g. actual arrays for example), and other semantics in general, the need to type out explicitly type pointers is a heck of a lot less common than in C. But that's the problem when people complain about syntax between languages without even trying it or thinking through the actual consequences of such decisions.

[^pointers-criticism]: Usually from people who have never tried the language, and only thinking of hypothetical issues. And even on such keyboards, symbols like `{}` and `[]` are probably just as hard to type but they are rarely (if ever) complained about by the very same people.

I know I've spent a lot of time on Odin's syntax so that it is as consistent as possible[^inconsistent] and to be very ergonomic with respect to the semantics of the language, but I don't think the declaration syntax or optional semicolons of Odin "make or break" the language. For me, the essence of Odin is to _feel_ like a modern C alternative with the joy of programming, rather than to _look_ like C. Even languages which keep as close to the type-focused declaration syntax of C, such as [C3](https://c3-lang.org/), still depart from the rest of C's syntax for other features and constructs. This is because C's syntax has a lot of issues to it which should not be repeated, especially not its actual declaration syntax.

[^inconsistent]: And "inconsistent" where it is absolutely necessary.

Sometimes tiny syntax decisions do add friction, and they do add up. One of the approaches to designing Odin has been to _nudge_ people in a direction which is usually a better way of doing things, rather than cause direct friction. However if friction is needed, usually what is needed is the equivalent of a brick wall, not sandpaper. But the syntax in this case is a reflection of the semantics of the language itself, and that's what many people seem to misunderstand. Syntax is not everything, semantics are the actual foundation of a language.

## Ignoring Such Opinions

If you're a fellow language designer, honestly: ignore these people. Everyone has an opinion but that opinion might not be of value to anyone, even the person who holds it.

If a person complains about the general category (not the specifics) of a syntax decision in your language, such as the declaration syntax, the use of semicolons or not, whether the core/standard library uses `snake_case` or `camelCase` for procedure names, or some other asinine position: **just ignore them.**

## Conclusion

I think a lot of the reasons people judge languages based on such "minor" syntactic decisions is probably because they don't have much experience with other programming languages. I've found that as people become more experienced with programming and other programming languages, this sentiment disappears entirely and people just focus on programming. The syntax is just there for reading, not for "appreciating".

Look for the opinions of people that you do value and to be of worth, not some rando off the internet.