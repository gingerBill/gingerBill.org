---
{
    "title": "Blessed Syntax and Ergonomics",
    "slug": "blessed-syntax-and-ergonomics",
    "author": "Ginger Bill",
    "date": "2026-04-29",
    "categories": [
        "programming language theory",
        "programming languages",
        "ergonomics"
    ],
}
---

I have seen a common remark from people who are not the biggest fans of Odin and it is usually the remark that Odin is "full of sugar" which only works for the "blessed types" and it cannot be replaced or implemented for user-level types. Firstly, I don't think this is necessarily an example of "sugar" since that term implies it is shortening a construct / feature / idea into something smaller, whilst a lot of the ideas in Odin that would be classed as "blessed syntax" by such people would not be classed "sugar" by virtually anyone else.

This decision to "bless" built-in types with the "blessed syntax" was not a mistake.

I wanted that explicitly because I know what the alternative is and the problems that arise from having it. Odin isn't trying to be the next C++ or Rust by allowing for arbitrary syntax for all custom data types. It's just trying to solve the average common case _very well_, rather than allowing the ability to solve "everything" _poorly_ which leads to the problems of dialects and poor defaults.

## Case Study: String Types

I'll start with a  specific example of a need to swap out the default string type. One such case would be the need for a string type that has inlined-data for small strings but still has the same _interaction_ syntax as another/default string type. I'd easily argue that this is an "optimization" of a problem that should not have happened in the first place.

It is an indirect consequence of both automatic-memory-management (which means defaulting to "the heap") _AND_ treating strings as an overloaded construct of the string value, string builder, and the backing buffer for a string[^string-article]. I remember when Facebook did a similar "optimization" for their string[^facebook-yt] and found a ~1% reduction in memory usage, which is not small at their scale, however it did show how strings were being used. Now that's because their string type was an amalgamation of a builder and value and backing (`ptr+len+cap`). But it did allow their inlining amount allowed for more embedding because they had so many extra fields to "overlap" with.

[^string-article]: I've written an article on this too: [String Type Distinctions](https://www.gingerbill.org/article/2024/04/05/string-type-distinctions/).
[^facebook-yt]: [CppCon 2016: Nicholas Ormrod “The strange details of std::string at Facebook"](https://www.youtube.com/watch?v=kPR8h4-qZdk>)

A popular user-library in Rust is [`cold_string::ColdString`](https://docs.rs/cold-string/latest/cold_string/), and its approach to this "optimization" is a little more interesting because it's opting for using only a tagged pointer which is either inline an ASCII or UTF-8 string or points to a Pascal String. As long as the string is <= 8 bytes UTF-8 or ASCII (on 64-bit machines)[^32-bit-machines], then the `ColdString` does minimize heap memory usage (assuming a lot of common strings are small).

[^32-bit-machines]: It says it works for 32-bit machines, but the tagging mechanism cannot work generally on 32-bit machines, especially those of which use larger address spaces (e.g. Windows 32-bit `/LARGEADDRESSAWARE`). This trick works on 64-bit machines because the vast majority of 64-bit machines use an address space between 48 and 53 bits, and not the full 64-bits, so that top bit can be masked.

Odin's `string` type was chosen as the default because at most it "wastes" an extra 8-9 bytes and allows for trivial substring creation. But because Odin is a manual memory managed language, you are free to choose how that memory is allocated. Whilst in Rust, things are much more assumed to be "automatic" most of the time, and thus heap will be the general default[^rust-allocations].

[^rust-allocations]: Rust does allow for a global custom allocator, or general manual memory management, but it's not what is encourage by the design of the language itself.

Odin also has ways to allow for struct fields to be interpreted at runtime as if they are a string if they want to be used by serializers/formatted-printing, which also helps with the usage. Rust has this too but in a much more specific macro approach (and thus preferred to be compile time). Thus separating the serialization aspects of the type from the type itself.


## Arrays---What Always Happens

What is interesting is that the common examples of user-level data structures that people want with what you call "blessed syntax" are virtually always some sort of custom array type. It is rare that people want this for anything BUT an array-like data structure, and when they do want something different, I'd argue it is _always_ a bad idea to give it any form of "blessed syntax"[^lisp-fans].

[^lisp-fans]: LISP Enjoyers will clearly disagree with me here, but we do have different philosophical approaches to programming in general, and thus this disagreement.

But this raises the question of what should be allowed to be user-defined and what should not be. The first is operator overloading for indexing. In Odin, this would mean at a minimum allowing for overloading `[]` as three different forms:

1. `[]`  for rvalue access (e.g. `x[i]`)
2. `&[]` for lvalue access (e.g. `&x[i]`)
3. `[]=` for assignments (e.g. `x[i] = y`)

C++ sadly does not make a distinction between (2) and (3), and has heavily suffered from this poor decision. But since Odin has other array indexing operations such as slicing (`x[:]`, `x[lo:hi]`, etc) and matrix indexing (`m[row, col]`), it means you'd have to add to the list of things you could overload, leading to about 7 different overloading operations (but only 4 in practice would be used).

There is also the question of compound literals to initialize array-like data structures too, which means the overloading behaviour now has to become a lot more complicated, and might be "easier" to do this in a macro system rather than normal syntax.

## Odin's Alternative to Operator Overloading

When I designed Odin, I thought what do the vast majority of people use operator overloading from in practice, and just implement that directly into the language---solving the common case rather than the general case. And from my research, the general use cases fell into two categories:

* Overloading for mathematical types
* Overloading for array-like data structures (including strings and hash maps)

For mathematical types, Odin supports array programming natively, complex numbers, matrices[^matrix-layout], and `#simd` operations. In general, this solved the vast vast majority of needs for mathematical types in the language, and even gets better optimizations for those cases by default because the language has native semantics for them.

[^matrix-layout]: Matrices are "dense" in Odin and allocated inline "on the stack". This decision was made because generalized matrices which are larger than a certain size are better optimized with a different memory layout and access patterns.

For array-like data structures, Odin has a lot of built-in data structures which cover the common cases:

* fixed-length arrays `[N]T`
* slices `[]T`
* dynamic arrays `[dynamic]T`
* fixed-capacity dynamic arrays `[dynamic; N]T`
* `#soa` variants of the above
* multi-pointers `[^]T`
* simd-vectors `#simd[N]T`
* hash maps `map[K]V`
* enumerated arrays `[Enum]T`
* matrices `matrix[R, C]T`[^overlap]

[^overlap]: Note there is some overlap with fixed-length arrays, simd-vectors, and matrices which apply to mathematical types too.

Beyond `[N]T`, everything else could hypothetically be implemeted in a language with "more control" over user-defined syntax, however it would suffer in many aspects.

**n.b.** A huge reason why the Odin compiler is written in C++ rather than C is because I wanted proper array types with runtime bounds checking. Other than that and other very minor things, my style of C++ is very C-like.

### Slices

The first example would be slices `[]T`. A lot of the slicing operations would not be able to be trivially optimized by a compiler if it was a user-level defined type, and especially not be optimized in development builds. A good example of this is the idiom `x[off:][:len]`, which replaces a lot of the need that (bounded) pointer arithmetic would in a C-like language. This operation in the Odin compiler is optimized into a single `x[off:off+len]` which would not be trivially done so in a generalized approach. Having it be language-level does reduces the amount of runtime bounds checking that has to be done since the compiler can trivially optimize such tests from two tests into one (or even more if it is chained).

### Hash Maps

Hash maps `map[K]V` are another in which the semantics could not be easily dealt with when it comes how keys are defined. In Odin, a hash map accepts any type that is _comparable_ as its key. This is because anything that is _comparable_ can be _hashable_. If this was user-definable, the user would either have to:
* explicitly pass the comparison function and hashing function manually
* overload operators and/or traits for or comparisons and hashing
* just rely on a default hashing approach.

Odin's approach is to deal with the common case but not making too many assumptions due to it being a manual-memory-managed language[^string-map]. The way Odin works is that the comparable types will have a default hash function generated for them any time they are used as a `map` key (this hash function _cannot_ be overridden, by design). It does mean that the hashing function might not be the optimal one for every use case, but it will be more than good enough for the vast majority of cases. If a user actually needs something more specialized for the hash map, then it is recommend you do not use the default one and use a custom variant, and have that syntax be obvious it is something custom.

[^string-map]: A good example of this is `map[string]V`. `map` does not "manage" the memory of the `string` based keys. The user is responsible for managing that memory. If it did managed it, it would be an exception of the general case which would not be consistent for other things (e.g. strings within a comparable struct).

### Enumerated Arrays

And lastly [enumerated arrays](https://odin-lang.org/docs/overview/#enumerated-array) are a great example of something which is not _trivially_ implemented at the user-level. Enumerated arrays allow the user of an `enum` to be used as indices to a fixed-length array. This is a very common idiom in C but is not strongly typed checked by the compiler.

```odin
Direction :: enum{North, East, South, West}

Direction_Vectors :: [Direction][2]int {
    .North = {  0, -1 },
    .East  = { +1,  0 },
    .South = {  0, +1 },
    .West  = { -1,  0 },
}

assert(Direction_Vectors[.North] == { 0, -1 })
assert(Direction_Vectors[.East] == { 1, 0 })
assert(Direction_Vectors[cast(Direction) 2] == { 0, 1 })
```

The indexing syntax could be trivially allowed with operator overloading however the compound literal syntax would not be. By default, a compound literal for an enumerated array must be _complete_, meaning all of the cases must be initialized, and only use `key=value` pairs. Other arrays in Odin allow for both positional values (which must be complete) and `key=value` paris (which can be "partial"), but enumerated arrays are very different.

```odin
arr: [enum {A, B, C}]int
arr = #partial { // without partial the compiler would complain
    .A = 42,
}
fmt.println(arr) // [.A = 42, .B = 0, .C = 0]
```

As I stated, of course all of this is possible in a hypothetical language, but none of it would be "trivial" nor necessarily a good idea.

### Bit Sets

Odin supports other data types which could be "hypothetically implemented" at the user level and a great example of this is the [`bit_set`](https://odin-lang.org/docs/overview/#bit-sets). They don't really fall into the array-like category since they do not support indexing but they can be iterated across. And they have a "blessed syntax" because of how useful they are. Unironically `bit_set` usually becomes a lot of people's favourite thing about Odin because it solves a very common problem of using enums for flags without overloading the usage of the enum with the flag of an enum.

Bit sets are a very old idea which can be seen in the original Pascal. It's very sad that C never had such a type, but that's probably because C didn't really have a concept of an enum type either, just a grouping of constants which implicitly incremented by `1`.


## For Loops as "Blessed Syntax"

Regarding `for` loops, I have written on this before where there is a possible case for macros in Odin to allow for the custom iteration through push-based iterators: [If Odin Had Macros](https://www.gingerbill.org/article/2025/07/31/if-odin-had-macros/). Odin's current approach to custom iterators is to just call a procedure with multiple return values (pull-based iterator). Construction, iteration, and destruction is made explicit for these custom operations. Yes it does mean "refactoring" from the default type to the new custom type is now "more work", but it's also probably a better indicator of something else going on. Especially when the iteration for the custom data type is not "obvious".


## Ergonomic Mindsets

I think there is this general distinction between a C-like programmer and a C++/Rust-like programmer[^example-not-exhaustive], which I will call the "Pragmatic Camp" and the "Generalizable Camp", respectively:

[^example-not-exhaustive]: I'm using these languages as examples, not an exhaustive list. This could easily include other languages like LISPs or anything macro or operator overload heavy.

* The [Pragmatic Programmer](https://www.gingerbill.org/article/2020/05/31/programming-pragmatist-proverbs/) has defaults which use the "blessed syntax" and then anything else beyond that is clear that it is custom/user-level, and it encourages the usage of the built-in data structures over custom ones, which is better most of the time for most people[^not-c].
* Whilst the Generalizable Programmer wants to have the same syntax for the built-in features/constructs for their user-level types, in order to be able to _hide_ the abstractions---optimizing for things like "refactoring". This means now the user now has to think which "defaults" to use a little more, even if those defaults may be a bad choice.

[^not-c]: Assuming the language isn't actually C since that it doesn't even have a proper non-demoting array type.

Both of these camps have different takes on what "ergonomics" means, and I'd argue it's not merely _just_ a syntax thing. Ergonomics is designing for humans and that does not mean just designing for "syntax" or "typing" or any of that. It can even mean designing to slow people down or nudge them to do something different. The act of making something difficult to do in a language, the latter camp would probably class that as "terrible ergonomics", but interestingly it could be viewed by the former-camp as "brilliant ergonomics". It's all about what you are trying to _optimize_ for in the domain of _ergonomics_.

<p style="text-align: center;">Ergonomics <em>is</em> <a href="https://www.gingerbill.org/article/2026/02/23/designing-odins-casting-syntax/#heading-2-6">Design as a Human Endevaour</a>.</p>

I am clearly in the _Pragmatic Camp_, especially with the design of Odin. And a lot of people who dislike Odin (but not all) are in the Generalizable Camp. It's absolutely fine for someone to dislike Odin, and I am so glad there are now other choices in languages to choose from in this domain other than C, C++, Ada, and other older Pascals. However, what is interesting is that many people in the Generalizable Camp don't see to want to understand the other camp's way of thinking; trivially dismissing the position as if it is a dumb way of thinking. And usually when people take that position, it means that they don't really understand the trade-offs and compromises of their _OWN_ position, let alone other people's positions.

n.b. the _Pragmatic Camp_ is not equivalent to the [New Jersey Model of "Worse is Better"](https://en.wikipedia.org/wiki/Worse_is_better). I don't subscribe to that nor the MIT model. I have massive issues with both of them and that should be self-evident with the design of Odin.

## Pandora's Box

Some of the main design goals of Odin have been to minimize the possibility of dialects but also bring the _Joy of Programming_ back to a lot of people. Both of these are a problem of ergonomics; a direct consequence of trying to minimize the "Generalizability" aspect. When everything can be generalized and default "idioms" are _not_ common place, this does lead to what many call [The Curse of Common Lisp](https://www.winestockwebdesign.com/Essays/Lisp_Curse.html)[^hackernews]. This "power" you get from the _Generalizable camp's_ approach to language design is its downfall. When idiomatic data structures are not encourage/enforced by default, then people tend to try to implement their own or even defaulting to creating even more to the madness. Generalizable approaches tend to lead to worse error messages from the compiler, and for it to struggle optimizing them too.

[^hackernews]: Please don't keep submitting the article to Hacker News!

Dialects are a consequence of having too many options to do things in a language or a heavily generalized feature, resulting in different sets of people preferring one approach over another. And in the worse case, everyone has their own dialect making them not possible to use any else's code. Some LISP derivatives, such as Clojure, have mitigated a lot of the curse of lisp by having a lot of built-in idioms (data structures and functions), but it doesn't fully fix the problem because it cannot. The C programming language the community has some people who keep to certain dialects which aim to be the most compatible, but even then that does not necessarily aid everyone.

This is why Odin has so many different built-in language-level data types rather than rely on a more generalized approach to implement them. It's to encourage their general usage; to have a common idiomatic foundation that everyone understand and build upon. This is what I view to be a sign of good language design, where the foundations of the language optimize for not just the lone-programmer but also how a project scales as it gets larger and more people working on it. The balance between the lone-programming and the team is a hard thing to design for, and it can lead to very annoying decisions in both cases.

Go is a great example of a language that was explicitly designed for large teams of programmers with varying skill levels. Many of its decisions are brilliant for what it was trying to achieve, but this is also why individuals hate. Things like not allowing unused variables, or enforcing 1TBS braces. Enforcing coding styles at the language-level rather than having it be a secondary vet pass. For a large company like Google, this ergonomics decision makes sense, but for smaller teams (or lone-programmers), this is an extremely unergonomic design choice.

You cannot please everyone with your design choices, nor should you try to. It's a gentle balance of trade-offs between different groups of people, and trying to maximally please everyone _will_ please no one. Fundamentally, everything is a trade-off in design, and that's your entire point of a language designer: choosing the trade-offs and compromises for your imperfect language.

Be careful with what you choose because you might not like the consequences.