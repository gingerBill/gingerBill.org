---
{
    "title": "A Reply to _The Road to Zig 1.0_",
    "slug": "a-reply-to-the-road-to-zig",
    "author": "Ginger Bill",
    "date": "2019-05-13",
    "categories": [
        "programming language theory",
        "programming languages"
    ],
    "tags": [
        "zig"
    ]
}
---


It is lovely to see many new programming languages being produced to solve different issues that the designers are trying to address. Many of the new big ones include Rust, Go, and Swift, all of which are trying to solve different problems. There are some not-as-big programming languages that I recommend everyone to checkout:

* [Odin](https://www.gingerbill.org/odin/)[^odin-lang-creator]
* [Scopes](http://scopes.rocks)
* [Zig](https://ziglang.org/)

They are all very good languages but with entirely different philosophies behind them. See if one suits your personal philosophy better!

[^odin-lang-creator]: For those who do not know, I am the creator of the [Odin programming language](https://www.gingerbill.org/odin/).


Which brings to me to the latest talk by [Andrew Kelley](https://twitter.com/andy_kelley) about his programming language, [Zig](https://ziglang.org/), titled _[The Road to Zig 1.0](https://chariotsolutions.com/screencast/philly-ete-2019-andrew-kelley-the-road-to-zig-1-0/)_. In this talk, Andrew presents the Zig programming language as a programming language for maintaining robust reusable software with a tour of the unique features of that Zig has. I recommend watching the talk before reading this article to make your own decision about it.

@@youtube:Gv2I7qTux7g

## Opening

The talk opens with the [xkcd comic 2030](https://www.xkcd.com/2030/) regarding the fragility and terrifying nature of software compared to engineering disciplines; with Andrew commenting that "we can do better than this". I agree with this basic premise however, I do not agree with Andrew's philosophical approach to aid this issue, and in general the entire philosophy behind Zig. Andrew's two key points to improving the problem are:

* Write quality software (compared to writing crappy software)
* Promote code reuse (compared to preventing code reuse)

From experience of programming and the current programming culture, the second should be rephrased to "promote reuse of quality code" as with the rise of package managers and library repositories, code is being reused quite a lot, even if that code is not at all robust. This crappy code reuse as resulted in many of the infamous dependency hells[^left-pad].

[^left-pad]: See the Left-Pad Package causing severe issues across many other piece of code, <https://en.wikipedia.org/wiki/Npm_(software)#Notable_breakages>.


However, my biggest gripe is the first point: write quality software. I wholeheartedly believe that writing quality software is not due to the issues of the programming language but the lack of incentives to make quality software and general culture around programming[^handmade-manifesto]. Humans are flawed beings and are incentive focused. Unless we have an incentive to do something, we are very unlikely to do it. There are many languages that are striving for robustness in the code, such as Rust and Ada, but to ensure robustness and quality, a robust and quality culture will be required to enforce it.

[^handmade-manifesto]: For a possible way to improve the culture, please see the [Handmade.Network](https://handmade.network/manifesto)

Andrew then precedes to talk about many of the things which will prevent software from being widely used:

* Garbage collection
* Automatic heap allocation (which may cause the system to run out of memory)
* If you code is slower than C, it will be rewritten in C
* A lack of C ABI will mean it is not usable by most languages
* Complicated build systems from source

These points are only mildly related to producing _quality software_ and closer to concerns about performance, ease of use, safety, and compatibility. I appreciate the caveats do not fit on the slide but many of these points do seem to be a completely different issue to the what question of _quality software_.

* Garbage collection (and automatic memory management in general) has its uses in certain problem domains and in those domains, it does not reduce the quality of that software.
* Automatic heap allocation is more of a problem with the language (and third party code) doing things behind the back of the developer which may have performance implications. I have never had a program cause a system to run out of memory in real software (other than artificial stress tests). If you are working in a low-memory environment, you should be extremely aware of its limitations and plan accordingly[^lack-of-memory].
* A piece of software doesn't need to be as fast as C to be quality software. If the performance is within a certain margin and/or the performance of your code has little overhead for the problem-at-hand (e.g. a one-off task), then the clarity of the code is much more important than its performance. This is why Python is so popular in the scientific community as prototyping/glue language, with the actual heavy-lifting done by C/FORTRAN bindings to the highly optimized code.
* A lack of C ABI is an issue if you need your software to interface with other software but as I said, this has nothing to do with quality software itself rather compatibility with other software[^c-abi-aid-pl].
* Complicated build systems is mostly a cultural issue where people are either told to use a certain approach or learn about "best practices".

[^lack-of-memory]: I have discussed this issue before with Andrew and I really do not see this as much of an issue as he does. If you are a desktop machine and run out of memory, don't try to recover from the panic, quit the program or even shut-down the computer. As for other machinery, plan accordingly!

[^c-abi-aid-pl]: And aiding your programming language with interfacing with foreign code and help it get more widely adopted.


## Condition Compilation

After this, Andrew talks about a lot of the issues in C which can cause friction and problems, and how Zig addresses them. Many are simple problems which have been solved by many languages before and after C, and many are core library issues and have nothing to do with the language itself. One of the issues that Andrew covers is conditional compilation and the compile-time system in Zig is used in conjunction with branch/if statements to produce compile-time evaluated clauses. The issue I have with this approach is that run-time evaluated if statements and compile-time evaluated if statements use the exact same syntax:


```zig
if (builtin.os == .windows) {
	var FT: FILETIME = undefined;
	GetSystemTimeAsFileTime(&ft);
	// ...
} else if (builtin.os == .linux) {
	var tms: timespec = undefined;
	clock_gettime(CLOCK_REALTIME, &tms);
} else {
	@compileError("unknown how to get the time");
}
```

A huge issue with this approach is that it is not clear that these clauses will be evaluated at compile-time nor that they will actually produce a scope or not. Odin solves this issue by using a separate keyword, `when`, to denote a compile-time branching statement:

```odin
when ODIN_OS == "windows" {
	// ...
} else when ODIN_OS == "linux" {
	// ...
} else {
	// ...
}
```

This `when` statement is clearer to read and because it is denoted different, it is clear that it has different semantics to an `if` statement. A `when` statement in Odin does not produce a new scope for each clause, and only the clause that is true at compile-time will be semantically checked (all clauses are syntactically checked, unlike an `#if 0` block in C), whilst in an `if` statement, all clauses are semantically checked.

## Error Handling

My biggest issue with the design of the Zig language, which is demonstrated in this talk, is that "error values" are built into the language itself. In a [previous article](/article/2018/09/05/exceptions-and-why-odin-will-never-have-them/), I discuss the issues with exceptions, error handling, and error propagation. Zig's _error_ types have a similar syntax to exceptions but they do not share the same internals as exceptions in that they are handled as part of the return values rather than through unwinding the stack (or some similar mechanism). Andrew comments that people are lazy (which they are) and will do whatever the default way is, so why not at least get them to handle things "correctly?" and "make handling errors fun".

Firstly, error handling should not be fun---it should be painless. It's akin to saying paying taxes should be fun. It will never be fun, but you can remove a lot of the drudge work from it. Secondly, as I previously wrote, my issue with exception-based/exception-like errors is not the syntax but how they encourage error propagation. This encouragement promotes a culture of pass the error up the stack for "someone else" to handle the error. I hate this culture and I do not want to encourage it at the language level. Handle errors there and then and don’t pass them up the stack. _You make your mess; you clean it._

Error propagation is fine within a library/package/module but you ought not to be encouraging propagation _across_ library boundaries. There are so many issues I have seen in real life, which lead to _crappy software_, where errors are just left for "someone else" to handle. Error propagation also has the the tendency to remove information about the type of error as it is reduced to a "simpler" error type up the stack. If you are designing a language to aid in producing _quality software_, don't add a core feature to the language which encourages sloppy habits.

Odin's approach to error handling is to treat errors as nothing special. Error cases are handled like any other piece of code. In conjunction with Odin's multiple return values, enumerations, unions, and many other features, this means the user can return extra information, including _error values_, alongside the normal return values if wanted and handle them accordingly.

## Clean-up Code

One feature that both Odin and Zig share is `defer`. A `defer` statement _defers_ a statement until the end of scope. I think this concept is much more powerful and versatile than C++'s RAII concept as it conceptually links the creation with the destruction without hiding it nor tying it to a type[^previous-defer]. Zig extends the `defer` to work with the error system with `errdefer`, which is a nice and natural extension of this system and is coherent with the rest of the language's design.

[^previous-defer]: I talk about the `defer` statement in a previous [article](/article/2015/08/19/defer-in-cpp/).

## Error Sets

Errors sets are an interesting concept that extend the error system in Zig. I would personally like to see this feature extended to enumerations too as it seems like a natural extension to the concept of a value set[^set-union]. However, it might be better to have a specialized error type than a specialization of a previous error type even if it increases code use (this is of course depends on the situation).

[^set-union]: It might be incorrect to call it a set as they can only be one of the values in the set of possible values. A union, sum-type, or something similar may be a better name for the concept.

## Build System

The Zig build system is the language itself. ~~It extends the compile-time execution system to call a "build" function to set up the build requirements. Having the same language be the build-language is very useful and a natural extension of the compile-time execution system. The compile-time execution system itself is already a huge requirement for the language which does complicate things but if that is accepted and desired, this feature is less of an issue.~~

Update: It appears that the build system is not part of the compile-time system whatsoever. It appears to be apart of the core library rather than a feature of the language itself. This could be easily replicate this in any language however having it part of the core library itself, this means that there is a _standard_ approach to use which nudges it towards being the _default_ approach.

In Odin, "foreign" code is handled by the `foreign` system. Foreign code that is imported is associated with its dependencies, this means that only the dependencies that are used are built against. Coupled with Odin's package system, it helps encapsulate the foreign code along with the Odin code. Odin does not directly import C header file, like Zig, but I found that in practice, you rarely want to use the raw bindings to the C code. From what I know of, how Zig is currently designed, its build system does not allow for this minimal dependency tracking that Odin offers.

## Designed Around LLVM

The Zig language is heavily designed around the LLVM ecosystem as a result, relies upon many of its features. I personally see this as vice rather than a virtue. Even though LLVM supports numerous target platforms, it does mean that any issue LLVM has, your language will have it too. Odin uses LLVM as its current backend, but there is work to replace it with a custom backend, and I have personally experienced a huge number of bugs and design flaws which cannot be avoided without removing LLVM itself. LLVM was built to optimize C and C++ and as a result, it is heavily designed around many of the "quirks" of C. LLVM is a huge dependency which I would rather not have to deal with.

I will not talk about LLVM any more as it requires another entirely separate article if I was to go into it further.

## Summary

Andrew sets out by striving to aid in the production of _quality software_ but does not really address why _crappy software_ is produced in the first place. Many of the features in Zig itself encourage what I see to be poor and lazy practice, especially the error system. Zig is a well designed language but I disagree with many of the design decisions and the fundamental philosophy behind it. I hope Andrew is successful and is continually able to make a living off from Zig as this is a wonderful project.

If you like the sound of it and want to find out more, please check it out at <https://ziglang.org/>.


## P.S. Why Odin?

Throughout this article, I have been discussing Zig and its issues. Why do I recommend Odin over Zig?

Odin is not trying to solve the problem of _quality software_ as that is fundamentally a cultural problem. The Odin programming language is fast, concise, readable, pragmatic, and open sourced. It is designed with the intent of being an alternative to C with the following goals:

* simplicity
* high performance
* built for modern systems
* joy of programming

I wanted a language that solved many of the issues I had with programming. I wanted the specification of the language to be 100% knowable by a mere mortal. There are probably less than a dozen people in the world that know all of the C++ specification _and_ understand it. Rust is starting to approach that complexity even though it is a new language. Swift already has a lot of baggage as its evolved past from Objective-C and the NeXTstep ecosystem.

At the turn of 2016, I gave myself a New Year's Resolution to start any new personal programming project in pure C to see what I really needed from a language. It turned out that I needed very little to be very productive. The friction from having to remember many of the features in C++ and other languages reduced my productivity a lot more than I realised. From using pure C for a few months, I noticed that there were features that I wanted to add to C to increase my productivity and reducing errors. These features included `defer` and tagged-unions. I started creating a metaprogramming tool to augment my C code so I could add these new features. I quickly began to realise that what I wanted was a new language as this endeavour was a dead-end.

The project started one evening in late July 2016 when I was annoyed with programming in C++ (not a new project). The language began as a Pascal clone (with begin and end and more) but changed quite quickly to become something else.

Odin borrows heavily from (in order of philosophy and impact): Pascal, C, Go, Oberon. [Niklaus Wirth](https://en.wikipedia.org/wiki/Niklaus_Wirth) and [Rob Pike](https://en.wikipedia.org/wiki/Rob_Pike) have been the programming language design idols throughout this project. Simplicity was always a deriving force in the design, but as I found very early on, simplicity is complicated.

The design underwent a lot of revisions and experiments in the very early stages as I did not know what was optimal for increasing my productivity. I knew the basic concepts of what I wanted but that was it. Concepts such as the package system took nearly a year to flesh-out and design as it took a while to discover what were the actual problems with certain approaches.

At the end of the day, I am a pragmatic man and I do not see the need for type-theory purity if it increases friction in the language.

If you like the sound of it and want to find out more, please check it out at <https://www.odin-lang.org/> and <https://github.com/odin-lang/Odin>.
