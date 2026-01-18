---
{
    "title": "Was it really a Billion Dollar Mistake?",
    "slug": "was-it-really-a-billion-dollar-mistake",
    "author": "Ginger Bill",
    "date": "2026-01-02",
    "categories": [
        "software",
        "programming language theory"
    ],
    "series": [
        "The Billion Dollar Mistake?",
    ]
}
---

**TL;DR** `null` pointer dereferences are empirically the easiest class of invalid memory addresses to catch at runtime, and are the least common kind of invalid memory addresses that happen in memory unsafe languages. The trivial solutions to remove the "problem" `null` pointers have numerous trade-offs which are not obvious, and the cause of why people think it is a "problem" comes from a specific kind of individual-element mindset.

**Part Two** of this article clarifies a lot more: [Mitigating the Billion Dollar Mistake](/article/2026/01/11/mitigating-the-billion-dollar-mistake/)

---

Most people have probably heard of the _Billion Dollar Mistake_ before, which was coined/invented by [Tony Hoare](https://en.wikipedia.org/wiki/Tony_Hoare): the inventor of null references/pointers.

> I call it my billion-dollar mistake. It was the invention of the null reference in 1965. At that time, I was designing the first comprehensive type system for references in an object oriented language (ALGOL W). My goal was to ensure that all use of references should be absolutely safe, with checking performed automatically by the compiler. But I couldn't resist the temptation to put in a null reference, simply because it was so easy to implement. This has led to innumerable errors, vulnerabilities, and system crashes, which have probably caused a billion dollars of pain and damage in the last forty years.

<p style="text-align:right">&mdash; Tony Hoare, 2009</p>

One thing I'd like to remark is that a Billion Dollars over a forty years over an entire industry is literally nothing, and close to a rounding error. I assume the number is just hyperbole, and not a real estimate, since there are loads of software industries today which make much more expensive mistakes than this one. However, I would still like to discuss this "problem" onwards.

If you have ever used pretty much any programming language that deals with memory, you will have encountered `null` pointers, sometimes referred to as `nullptr`, `NULL`, `nil`, or many other similar names. It is typically used as a pointer/reference that does not refer to a valid object. However another way to think about `null` is that it is just one of many invalid memory addresses.

In many memory-managed garbaged collected languages, it will be the most common invalid memory address since it is very difficult to reach other invalid memory states. However, the general criticism of null arises more commonly in systems-level programming languages such as C or [Odin](https://odin-lang.org/), and I am going to argue that in practice, most invalid memory addresses are not null in those languages.

This issue of null pointers is related to the [drunkard’s search principle](https://en.wikipedia.org/wiki/Streetlight_effect) (a drunk man looks for his lost keys at night under a lamppost because he can see in that area). I have found that null pointers are usually very easy to find and fix, especially since most are caused by trivial bugs (usually typos).

In _theory_, null is still a perfectly valid memory address, but as a practical matter, we have decided on the convention that null being zero is useful for marking a pointer as unset. Modern platforms reserve the first few pages of (virtual) memory to check for these errors. Typically on all modern systems, that memory address is located at `0`[^c-null-definition], but it didn't always used to be on all platforms[^weird-null]. Meaning that null is just a kind of sentinel value for memory addresses.

[^c-null-definition]: `#define NULL ((void *)0)` in C99, or `nullptr` in C++11 and C23.

[^weird-null]: Historically, the [Prime 50, CDC Cyber 180, and some Honeywell-Bull](https://c-faq.com/null/machexamp.html) machines all had nonzero null, as might DG Eclipse MV, HP 3000, Lisp Machine, some 64-bit Cray,

But the real question of all of this is: if `null` is generally considered to be a mistake, what is the cause of this mistake and is it actually a problem?

## The Symptom

The problem with a null pointer in practice is not the existence of the null pointer itself, but rather the dereferencing of them causing a runtime panic. As I've previously stated, a null pointer is just one kind of invalid memory address, and in languages like C or Odin, it is much more common to get other kinds of invalid memory addresses which are not solved by removing the symptom of null pointer dereferencing. Other common forms of invalid memory address are use-after-free, incorrect pointer-arithmetic calculations, unmapped memory regions, and many more, which are not trivially solvable in the same way that null pointers could be.

Compile-time memory safety is not something I require for my kinds of systems level programming, but languages such as Rust and Ada are usually the go-to languages for when that is a need.

## The Cause and "Solutions"

For Odin, I decided to not remove the existence of `nil` pointers. Why I have not tried to "solve" this "problem" is due to it being a trade-off in programming language design which is not immediately obvious.

If you want to make pointers not have a `nil` state by default, this requires one of two possibilities: requiring the programmer to test every pointer on use, or assume pointers cannot be `nil`. The former is really annoying, and the latter requires something which I did not want to do (which you will most likely not agree with just because it doesn't _seem_ like a bad thing from the start): _**explicit initialization of every value everywhere**_.

**Fundamentally the problem of `nil` pointers/references arising comes from the ability of not having to explicitly initialize individual-elements on creation, allowing them to be in a "nil" state by default.**

The first option is solved in many languages (partially including [Odin](https://odin-lang.org/)) with having support for [maybe](https://pkg.odin-lang.org/base/builtin/#Maybe)/[option types](https://en.wikipedia.org/wiki/Option_type) or nullable types (monads), however I am still not a huge fan of them in practice as I rarely require them in systems-level programming. I know very well this is a _"controversial"_ opinion, but systems-level programming languages deal with memory all the time and can easily get into "unsafe" states on purpose. Restricting this can actually make constructs (like custom allocators) very difficult to implement, along with other things.

Odin does have `Maybe(^T)`, and that's fine that it does exist, but it's actually rare it is needed in practice. When it is needed, it's either for documenting foreign code's usage of pointers (i.e. non-Odin code), or it's for things which are not pointers at all (in Odin code). And coupled with many of the other features of Odin (multiple return values, `or_return` et al, proper array types, etc), a lot of the need disappears in most cases.

n.b. For the ML/Rust users, Odin's `Maybe(^T)` is identical to `Option<&T>` in Rust in terms of semantics and optimizations.

The second option is a subtle one: it forces a specific style and architectural practices whilst programming. Odin is designed around two things: to be a C alternative which still feels like C whilst programming and "try to make the zero value useful", and as such, a lot of the constructs in the language and core library have been structured around this. Odin is trying to be a C alternative, and as such it is not trying to change how most C programmers actually program in the first place. This is why you are allowed to declare variables without an explicit initializer, but the difference to that of C is that variables will be zero-initialized by default[^uninitialized].

[^uninitialized]: You can do `x: T = ---` to make it uninitialized stack memory, if that is necessary for certain optimizations.

Fundamentally this idea of _explicit individual-element based initialization_ everywhere is a viral concept which does lead to what I think are bad architectural decisions in the long run. Compilers are dumb---they cannot do everything for you, especially know the cost of the architectural decisions throughout your code, which requires knowing the (global) intent of your code. When people argue that a lot of the explicit initialization can be "optimized" out, this is only thinking from a _local_ position of individual-elements, which does total up to being slower in some cases at a more _global_ scale.

To give an example of what I mean, take `make([]Some_Struct, N)`. In Odin, it just zeroes the memory because in some cases, it is literally free (i.e. `mmap` must zero). However, when you need to initialize each value of that slice, you are now turning a O(1) problem into a O(N) problem. And it can get worse if each field in the struct also needs its own form of construction.

I do not think the `nil` pointer problem is as much of an empirical problem in practice. I know a lot of people want to "prove" things whenever they can at compile-time, but I still have to test a lot of code in the first place, and for this very very specific example, it is a trivial one to catch.

And I'd argue a lot (not all) of the `NULL` pointer problems in C are caused by the lack of a proper array type. C's biggest mistake in my opinion is conflating a pointer with an array. Odin has solved this by having different bounds-checked array types.

A general habit of people who criticize newer languages is to say the problems exist in C and therefore must exist in this new language, without even doing basic research if that's true in the first place[^tiresome].

[^tiresome]: If you didn't guess, this is kind of tiresome when I am trying to explain Odin to other people who just want to dismiss it out-right because of some preconceived notion of the problems in C. Most of these people are generally not serious, but they are the loudest on the social media sites.

## The "Gotcha"

I find this "gotcha" that people bring up[^excuse] is probably one of the most common ones because it _seems_ like an "obvious" and "simple" win, and I'd argue it's the exact opposite of either "simple" and even a "win". Language design is all about trade-offs and compromises as there is never going to be a perfect language for anyone's problem. Even if you designed the Domain Specific Language (DSL) for your task, you'll still have loads of issues, especially with specific semantics (not just syntax).

[^excuse]: I find it mainly as a excuse to not try Odin, which is fine, I don't care if you use Odin or not, but be honest that it's just not a language for you rather than finding excuses.

Languages like Rust were designed from day zero around _explicit individual-element based initialization_, however when designing Odin, from day zero I wanted to still keep the feel of C (along without other design philosophies) so I explicitly wanted implicit zero based initialization (e.g. `x: T` has zeroed memory). This ever so minor choice might not seem like a big thing to you, but it leads to _MASSIVE_ architectural decisions later on when developing a program.

Odin could not "just add" non-nil pointers and it be "fine". It would actually not be Odin any more, and the entire language would not even be a C alternative any more, and feel much more like C++, Rust, or OCaml. Rust and OCaml (which Rust is based off) are different kinds of languages to Odin and their approach does not translate well to what Odin (or C) is trying to do.

The analogy I like to use is complaining that French cannot do the English equivalent of [Iambic Pentameter](https://en.wikipedia.org/wiki/Iambic_pentameter). Different languages just have different approaches to doing things.

## The Problem of the Individual-Element Mindset

I believe this general local based thinking leads to poor architectural decisions at the global scope. It is unfortunately one of the most common mindsets in programming but it is a phase that every programmer does go through in their journey. I and many others have evolved how we think about architecting programs, but most programmers in their journey usually go through a few phases.

A good explanation of this general thinking is presented in this [video with Casey Muratori](https://www.youtube.com/watch?v=xt1KNDmOYqA):

<div class="youtube">
  <iframe width="560" height="315" src="https://www.youtube.com/embed/xt1KNDmOYqA" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>


On this journey/life-cycle, no-one is born knowing how to program: you learn how to do it. And when it comes to programming, you think in stages (at least in my personal experience) that are usually quite consistent in their ordering amongst most people. At some point during this stage of thinking, people reach a point of what I'll dub the _Individual-Element Mindset_. This mindset is when you think of each specific piece of data (element) as having its own _lifetime_. This leads to common approaches of thinking each element having to be constructed/`malloc`ed individually with its own unique lifetime, then it's destructed/`free`d individually (or automatically by a garbage collector).

The architectures that arise from this mindset tends to be based around things like:

* Thousands/millions of `new`/`delete` or `malloc`/`free`
* Data structures full of pointers which point to other things
* RAII
* "Smart" pointers and reference counting

RAII and "smart" pointers[^smart-pointers-insult] are both mitigations to get around many of the architectural issues of this mindset. RAII will handle the construction and destruction of elements automatically by the compiler. "Smart" pointers are there to help with the problems with forgetting to free allocations and to prevent use-after-frees, by tying the lifetime of the usage of the object with its allocation.

[^smart-pointers-insult]: I am placing quotes around "smart" to emphasize that they are not really "smart" in their construction nor "smart" in their usage.

This architectural mindset does lead to loads of problems as a project scales. Unfortunately, a lot of people never move past this point on their journey as a programmer. Sometimes they do not move past this point as they only program in a language with automatic memory management (e.g. garbage collection or automatic reference counting), and when you are in such a language, you pretty much never think about these aspects as much. And if you ever do think about these, it's usually because you are trying to do something performance-oriented and you have to _pretend_ you are managing your own memory. It is common for many games that have been written with garbage collected languages to try to get around the inadequacies of not being able to manage your own memory. But if you are never writing performance-critical code, it would be very unlikely that you would know that you have to get past this point.

If you were having to manage these _millions_ of individual allocations manually, it does make sense why people recommend things like RAII or "smart" pointers as the compiler will add the constructors and destructors automatically for you. You can see why a person at this stage of their programming journey can think it would be a good thing to do, since it removes a lot of the boilerplate and minimizes the possible errors due to forgetting to write things.

I am not saying people who do this are stupid---far from it! I've had this mindset before in my journey as a programmer, as have most programmers. It's something you either come to naturally or you are taught from the general programming culture on the internet. I cannot think of any one who has shipped software who has NOT been at this phase/stage at some point in their life.

The problem with this mindset and the solutions it produces is that you are effectively patching over a flaw in your architecture. If two things are inextricably linked such that you have one thing getting automatically freed when the other thing gets freed (in all but the rarest of circumstances) this means that those things should have a combined lifetime. The better approach to this is to have one large "pool"/"arena" that all of those things got created in, so that things from that "pool" get freed together.

The stage of the individual-element mindset is _stupid_, as in the code that you write whilst in this mindset will not be good, but __you are not__ stupid. Especially since everyone will be at this stage at some point. The next stage to get to after this is the _grouped-element mindset_.

n.b. I call myself an idiot/numpty/moron on a daily basis for things that I do, so don't think I am saying I am "smart". I am just as "stupid" as most. Stupid is as stupid does.

## The Grouped-Element Mindset

When you move from the Individual-Element Mindset to the Grouped-Element Mindset, things like smart-pointers and RAII[^defer] become mostly irrelevant. This is because ownership and lifetime concerns are not as much of a problem any more, like the kind you had in the previous mindset. Ownership is a constant concern and mental overhead when thinking in an individual-element mindset. Whilst ownership is obvious (and usually trivial) in the vast majority (99+%) of cases when you are in the grouped-element mindset.

[^defer]: Note I am _not_ saying things like an explicit `defer` statement is not useful, but rather the need for the implicit RAII style of lifetime handling of individual-elements is bad. If I thought `defer` was bad, I would not have added it to Odin.

This grouped-element mindset tends to be based around things like:

* Large collections created/destroyed at the same time
* Very limited uses of `new`/`delete` or `malloc`/`free`
* Heavy use of scratch space
* Hashing and the reuse of elements

Most of the advice (and criticisms) online that you will read are for/from the Individual-Element Mindset, and I'd argue the goal is to get to the Group-Element Mindset (and even pass it). It's still a way of thinking for people who are not that good at programming as they could be _yet_. They are still in a stage of architecture which is very limited, and not appropriate for modern high-performance well-architected code. It is an old way thinking which is still very prevalent, and people need to get past it. I'd argue there is no "good code" that is written in the Individual-Element Mindset. It might do the job, but the code itself won't be "good", at best it will be adequate, but the mindset is inherently inefficient and bug-prone.

n.b. In many ways, this individual-element mindset is a hell of a lot more costly than worrying about the "Billion Dollar Mistake" of this article. The performance losses alone are probably wasting BILLIONS PER DAY as an industry.

The grouped-element mindset does tend solve a lot of other kinds of invalid memory addresses too (such as use-after-free) because the lifetime and ownership of things is made a lot clearer just by thinking about large collections.

Use-after-free is usually another symptom of poor architectural decisions, and the common "solution" that some languages do without garbage collection is to  add even more complex lifetime and ownership semantics to the language (e.g. Rust). Not everything has to be nor needs to be solved in the language if memory safety is not of paramount concern, of which I'd argue most pieces of software are not in that realm. I think it's another "mistake" to think everything need to be as temporally memory safe as randos on the internet claim. Odin already has a lot of features in it which solve the spatial memory safety problems already; it just doesn't try to "solve" temporal memory safety at the language level as much as other popular languages. It's all about these trade-offs in design between compile-time enforcement, run-time catching, and architectural design.

It'd even argue the individual-element mindset is a reason why a lot of people still love the OOP approach to programming. You only have to think, and can only think, about a very small piece. OOP allows you to think very small and not how the whole program works. This was its initial goal too of both the Alan Kay style OOP (message passing) and the Java style OOP (inheritance-based encapsulation).

As you get a little bit larger and start thinking about _systems_ within your code, then you can see how things cohere and bind together much more easily. Once you are at this _systems_ level of grouped-elements, you're at this next phase of thinking.

However, I do not think you can skip past the individual-element mindset and jump straight to the group-element mindset, at least not the majority of people. I think it's probably a necessary phase of thinking from understanding the fundamental _unit_ of data within a problem, from the individual to the group[^communism].

[^communism]: This should probably be its own article, not a footnote, but with a poor analogy, this grouped-element mindset is actually akin to "communism", and that the individual-element mindset is closer to "capitalism". Please note I think "communism" is evil, but the analogy of the politico-economics systems mirror quite well due to the thinking of element-based-lifetimes rather than system-based-lifetimes.

## The Consequences of These Mindsets Applied to Language Design

When designing Odin, I had a lot of these distinctions of mindsets explicitly in mind. Most of my choices were conscious about what I wanted and did not want from a language. A lot of Odin's design has been around this "nudging" to a certain style away from mindsets I do not feel are good in the long run.

However these design decisions do come into conflict with the common _mindset_ that a lot of programmers have. If you don't agree with the design decisions of Odin, that's fine, and Odin might not be the language for you, but don't think you can trivially wedge an idea/feature/construct into another language and think it will just work as you expect.

A lot of language design is thinking about these local decisions and how they will affect the landscape of the global possibilities. We want to be able to think locally about something most of the time, but when it comes to architectural decisions, we need to think as global as we possibly can.

Designing a language isn't just about adding cool new features, or syntactic sugar, or whatever. It's about thinking what you are trying to achieve for the problem space you are designing for, and how the individual features and constructs interact with each other and the consequences that they produce whether they improve or restrict things as things scale.

## Conclusion

`null` pointer dereferences are empirically the easiest class of invalid memory addresses to catch at runtime, and are the least common kind of invalid memory addresses that happen in memory unsafe languages. And the cause of why people think it is a "problem" comes from a specific kind of individual-element mindset.

In statically typed compiled manual-memory managed languages, it's not as much of a problem empirically compared to the set of invalid memory address problems, of which most of them are solved with a different mindset.


**Part Two** of this article clarifies a lot more: [Mitigating the Billion Dollar Mistake](/article/2026/01/11/mitigating-the-billion-dollar-mistake/)
