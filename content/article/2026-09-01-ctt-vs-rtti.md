---
{
    "title": "CTTI is Exponential, RTTI is Linear",
    "slug": "ctti-is-exponential-rtti-is-linear",
    "author": "Ginger Bill",
    "date": "2026-09-02",
    "categories": [
        "programming language theory",
        "programming language design",
        "ctti",
        "rtti",
    ],
    series: [],
}
---

## Abstract

Runtime Type Information (RTTI) has a cost, but it is a *tame* cost compared to Compile-Time Type Information (CTTI), which is sold as "zero-cost", and it is anything but.

* RTTI's tables are a ***linear*** cost in the number of types (N types -> N entries), single cost.
* The use of RTTI is a ***fixed constant*** cost, one procedure iterating over one table, no matter how many types exist.
* RTTI is effectively ***zero*** additional cost during semantic-checking, because there is nothing to specialize.
* CTTI does not necessarily need any extra tables, but usually does create them in some cases.
* CTTI is an ***exponential*** cost everywhere in the worst-case: semantic checking, code generation, *and* binary size. Instantiations go multiplicative in the general-case.

There is a trade-off between a linear memory cost (that can be measured) for an exponential compile-time cost (that cannot be measured), and people argue for the latter, advertising it as "zero-cost".

------

## Introduction

A common question I have received is regarding why Odin uses Runtime Type Information (RTTI) instead of Compile Time Type Information (CTTI) for things like formatted printing. Isn't that an extra runtime cost? And isn't everything to do with CTTI "zero-cost"? Of course you should just bake all of the computation at compile time so the compiler can optimize for those sets of types, right?

There's a nuance to be made between "known at compile time" and "free to enumerate at compile time", it's a category error to conflate them. This kind of lack of understanding comes about due to reasoning locally about a single thing, one instantiation, and never once about the aggregate nor the emergent properties of such a system.

In this article, I will try to explain the actual cost of both, as very few people seem to even sketch it out.

## The Cost of RTTI

RTTI is commonly stored in a table, and that is not different for Odin. Each type[^each-type] in your program will be stored in the table. The RTTI tables store some information about those types such as its size, its alignment, its kind, its fields, and whatever the language/language-designer decides is worth keeping. The set is finite and known, since ultimately, types are just *data*.

[^each-type]: Note that "each type" here just means each type whose information is actually retained and used for RTTI purposes, not every type expressible in the language nor even the expressed types in the program.

The price of RTTI is spread across a few places: the procedures that handle the RTTI, tables, and the semantic checking.

When you print a value with `fmt.println`, or (de)serialize anything in general, you are calling *one* procedure (or set of procedures) that iterates over types referenced in a type-table. That procedure's code doesn't grow because your program has more types in it, nor does it need to be duplicated per type by the linker, nor does it produce more *code* for each new combination of types passed to it. It is the same code reading, just type-information in a type-table.

The *code* handling this runtime type information will always be the same size and shape, as the only thing that grows is the type-table itself which it reads from (and as I said, that grows linearly).

The complexity of a type-table is linear: `N` types gives you `N` entries. Typically (and hopefully) this type-table then resides in a read-only data section (e.g. `@(rodata)` in Odin), then the cost of this table is paid once at compile time, in the binary, and the memory of the executing program. You can then go and look at the binary directly and see how many bytes that table occupies in the binary. All of that is trivially measurable, which is precisely why many people who state they dislike RTTI can quote you a number since the cost is trivial enough to be quotable[^same-said-ctti].

[^same-said-ctti]: The same cannot be trivially said for CTTI, but I will get to that later.

There is nothing extra to semantically "check" when you have RTTI. The checker only checks one procedure for a parameter of type `any` (or whatever the erased handle type happens to be in your language), it then type-checks it *once*, and states it is used. It does not have to recheck anything per-type, because there is no per-type code in this case.

### RTTI Scaling Complexity

RTTI is linear in the table size, constant in the amount of code written/generated, "zero" in the case of semantic checking.

$$
\mathcal{O}(table \cdot code + checking) = \mathcal{O}(N \cdot 1 + 0) = \mathcal{O}(N)
$$

So even in the worst case, RTTI scales linearly, with the cost being (obviously) a purely runtime cost in terms of table indirection, code size for the serialization procedures, and lack of specific optimizations for the code working over specific types.

## The Cost of CTTI

The entire point of using CTTI in the first place is that it allows you to specialize *code* everywhere you use it. Every *distinct* type you use an operation on (e.g. printing) gets its own generated version of that operation. For a small set of types, this is completely fine, even lovely. It's a small set of code that the compiler and optimizer can deal with; there is little-to-no indirection, and no tables[^ctti-no-table] to iterate across.

If you truly only have a small set of types, CTTI can be a great tool. However that small case is never true in practice, even for small programs that heavily rely on type-safe formatted printing, it becomes huge quite quickly. So any use of CTTI nowadays is fraught with a cost you pay everywhere, and it grows exponentially.

[^ctti-no-table]: CTTI does not *necessarily* need any extra tables, but in practice it usually generates some anyway for practical reasons.

When you use CTTI in workloads that matter, it is never just a small set of types, it's always a *combination* of types, and those combinatorics do tend to explode. Let's use the basic examples of a printer over `N` types, or a serializer over `N` types into `K` formats, or a container type parametrically polymorphized by `K` different type arguments. The moment these examples are any form of polyadic in their type arguments: multiple value/type parameters, multiple return values, multiple fields; the language is full of places where this combinatorial explosion happens.

This means that the number of instantiations isn't only `N`, it becomes `N×K`, or `Nᵏ`. You didn't write `Nᵏ` procedures, but the compiler monomorphized them for you, whoops. And because each instantiation is a *distinct* thing, it must be semantically checked separately each time (assuming C++/Odin style parametric polymorphism), and then the code must be generated separately each time. Both of those are the expensive aspects in the compilation stage, and both of them just went exponential. You might have saved yourself a "table" (both storage and access) but you paid for it `Nᵏ` times over inside the compiler and in the final binary.

Unfortunately these are the costs so many programmers are most conditioned/trained to ignore, because they are told that it is better to make the compiler do something if it can, rather than question if it should. And when the day comes that a build takes 6 minutes (rather than 600ms) and the binary is now 400MiB, nobody can point at the lines of code that caused that inflation of insanity. It cannot be any specific line, as it was caused by the combinatorics of the code itself.

### CTTI Scaling Complexity

Calculating the scaling complexity of CTTI is a little more complicated but still possible to do.

$$
N = \text{number of types}
$$
$$
K = \text{combination of the types passed to a procedure}
$$

In the case of `K=0`, the number of instances of the procedure is `1`. In the case of `K=1`, the maximum number of instances of a procedure is `N`. In the case of `K=2`, the maximum number of instances of a procedure is `N²`. Et cetera, this can be generalized for any amount of combination of `N` types:

$$
\sum_{i=0}^{K} N^i = \frac{N^{K+1} - 1}{N-1} \implies \mathcal{O}(N^K)
$$

So even in the most common case of a printing procedure, this scales exponentially with the instantiations. Some languages just do this naïve approach to printing and don't think it'll be a problem. They even say "well it's only one instantiation per input", but then forget that the internals are now combinatoric instead. So in the best case scenario, this approach is `N×K`, but the worst-case it is `Nᵏ`[^power-law-caveat]. Some languages that do use CTTI for printing (e.g. Rust) try to mitigate this disaster with an explicit edge case in the compiler that tries to minimize this explosion in compiler complexity, but it does not necessarily solve the binary problem in medium–large projects.

[^power-law-caveat]: Depending on how you conceive of it, this is either a power-law (constant-`K`) or exponential (constant-`N`), but practically since `N` is not really "fixed", I conceive of it being exponential. Either way, it is heck of a lot worse than linear.

Some languages also try to mitigate the combinatorial explosion with explicit tagging to produce the CTTI-related code generation, forcing a multiplicative complexity instead. For example, [`serde` in Rust](https://serde.rs/) can be used for CLI parameters, GUI forms, pretty printing, etc. All of this I implement in Odin with RTTI and [struct field tags](https://odin-lang.org/docs/overview/#struct-field-tags), which I find a lot easier to deal with.

## Asymmetric Approaches

* RTTI's worst case is **linear, in one place**, and it is the place (memory) you can actually measure.
* CTTI's worst case is **exponential, in three places at once** (semantic checking, code generation, and binary size).

In my opinion, I don't think this is at all a close call to make in terms of cost; when I started Odin back in 2016, I went straight for RTTI without hesitation. It seems that people trade a measurable linear memory cost they can see (and workaround if it becomes a problem), for an exponential compile-time cost they cannot see. And all because they cannot see the second one, they have talked themselves into calling it a "zero-cost abstraction". I really dislike the phrase "zero-cost" so much because it is hiding an enormous amount, pretty much always.

## The Individual-Element Mindset, Again

I have written about the [*individual-element mindset*](https://www.gingerbill.org/article/2026/01/02/was-it-really-a-billion-dollar-mistake/): the habit of reasoning about one thing, in isolation, and never about the group. CTTI-by-reflex in language design is that exact mindset wearing a type-theory [hat](https://en.wikipedia.org/wiki/Mr_Benn).

I chose RTTI in Odin because it is a data-driven approach (one procedure over a table). The CTTI approach is a very code-driven approach, which might produce better _code_ for each instantiation of the procedure, at the cost of pretending you don't want the data to exist.

## Coherency vs Cleverness

There is an architectural design argument on top of the cost argument, and this is a big reason behind why I chose RTTI in Odin.

In Odin, `fmt.println` works on everything through RTTI. Any form of (de)serialization/(un)marshalling uses RTTI.

One of the beautiful things about RTTI in Odin is that `typeid`s are deterministic—they will be the same per type regardless of the program (assuming the types are the same). When a `typeid` crosses a LIB/DLL boundary (without re-instantiating anything), it "can" work across that boundary as it is just *data* with a stable canonical layout. There are no Nᵏ generated procedures that both sides have to agree to have generated identically monomorphized code, as it does not cross a dynamic library boundary for free. With CTTI, both sides have to have produced the same instantiations, or *you* reproduce them. Data moves absolutely fine across such a boundary.

This design argument is effectively coherency vs [per-type] cleverness. It's a single idea which can be applied uniformly, which everyone can understand and build upon. Rather than N different generated things and the compiler groaning under the weight of checking all of them.

And what does CTTI give you in exchange?

* Parametric-Polymorphism/Templates that become [metastatic](https://en.wikipedia.org/wiki/Metastasis) over time
* Error messages measured in kilobytes, requiring a degree in Egyptology to decipher
* Build times that scale exponentially allowing you to cook a full Sunday Roast in that time
* Binaries full of near-identical procedures that the linker now has to deduplicate (but cannot in practice)

And what makes me laugh is that relying on the linker to deduplicate this concedes the point. You goddamn generated all of it, checked all of it, and only then asked another tool to spend time throwing most of it away... A big reason I made Odin was to get *away* from that madness of doing "make work".

## Trade-Offs Exist

To be clear, there are cases when CTTI is a better trade-off. Odin does have a form of CTTI through its `base:intrinsics`, albeit clunky to use[^clunky].

[^clunky]: This is partially on purpose to nudge people to minimize their usage, but also because it does not have the same data-driven design and is purely code-derived through compile-time evaluated procedures/intrinsics.

* When you have a hot code path where you cannot afford an indirection or iterating through the type-table.
* When you want the optimizer to actually optimize the code itself for a specific type and not have it be generic.
* When you actually have a small known set of types, and the combinatorics never caused anything to blow up.

In these above cases, the specialization that CTTI provides is great, but I'd argue these are rarer than you think.

And RTTI, of course, does have its own set of costs:

* The tables take space in the binary and executing memory.
* The table lookup is a runtime cost, even if it is "constant".
* All information has to be retained, or the whole thing doesn't work.
* You might need to obfuscate some of the type information over privacy/security concerns.
* If you are in an environment where you cannot spare the bytes or the indirection (which is a real constraint), then RTTI can be wasteful.

My point here is not that "CTTI bad, RTTI good", rather that I don't think many people realize that the cost of CTTI is exponential in the worst-case and multiplicative in the general-case, considering checking, code-gen, and binary size. The benefit of CTTI is pretty much always _local_, but has _global_ effects. And when designing a language, I'd argue for using RTTI by default pretty much always, and only using CTTI when you absolutely require it.

## Conclusion

RTTI has a ***linear*** cost in the number of types, which is then paid at runtime (table lookup/indirection), binary size, and memory usage. CTTI has a ***exponential*** cost in the number of types in the worst-case, and multiplicative in the general-case, which is then paid at compile-time (checking and code gen), and binary size.
