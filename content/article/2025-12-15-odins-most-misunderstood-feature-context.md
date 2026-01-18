---
{
    "title": "context—Odin's Most Misunderstood Feature",
    "slug": "odins-most-misunderstood-feature-context",
    "author": "Ginger Bill",
    "date": "2025-12-15",
    "categories": [
        "software",
        "odin",
        "programming language theory"
    ],
    "tags": [
        "odin"
    ]
}
---

Even with the [documentation](https://odin-lang.org/docs/overview/#implicit-context-system) on the topic, many people completely misunderstand what the `context` system is for, and what problem it actually solves.

For those not familiar with Odin, in each scope, there is an implicit value named `context`. This context variable is local to each scope and is implicitly passed by pointer to any procedure call in that scope (if the procedure has the Odin calling convention).

The main purpose of the implicit `context` system is for the ability to intercept third-party code and libraries and modify their functionality. One such case is modifying how a library allocates something or logs something. In C, this was usually achieved with the library defining macros which could be overridden so that the user could define what they wanted. However, not many libraries support this, in any language, by default which meant intercepting third-party code to see what it does and to change how it does it is generally not possible.


The `context` value has default values for its parameters which is decided in the package runtime. These defaults are compiler specific. To see what the implicit `context` value contains, please see the definition of the `Context` struct in [package runtime](https://github.com/odin-lang/Odin/blob/master/base/runtime/core.odin).

## The Misunderstanding

Fundamentally, the entire point of the `context` system is to intercept third-party code, and to change how it does things. By third-party, I just mean code not written by yourself or code that you cannot easily modify (which could even be your own past self's code).

I expect most people to 100% ignore the `context` because its existence is not for whatever preconceived reason they think it is for, be that minimizing typing/passing things around, or dynamic scoping, etc. It's just for interception of third-party code.

Ironically, `context` works _because_ people misunderstand it, and thus generally leave it alone. That allows those who do understand it to work around less-than-ideal API's.

I understand a lot of people may not understand why it exists when they might not currently need it, but it's fundamentally a solution to a specific problem which cannot really be solved in another way.

A common misunderstanding usually arises when it is necessary to interact with third-party code and having to write callbacks which do not use the Odin calling convention. There is a general misunderstanding that because some procedure may not _appear_ to use `context` directly (or at least not obviously do so), people will say that they should be marked as `"contextless"` or `"c"`, however this misses the entire point. Because the default calling convention of Odin has this `context`, you don't actually know if the code needs it or not (which is by design).

The first common example of this of this interaction complain usually happens when using Odin's printing procedures in `core:fmt`. For most people, they just do `context = runtime.default_context()` to define a `context` and then continue, but I have had a lot of people "complain" as to why that is even necessary. Arguing that other than the `assert`, why would you need the `context`? This complaint is due to not understanding what `fmt.printf` et al actually do. `printf` is a wrapper around `wprintf` which takes in a generic `io.Stream`. Since other libraries can utilize these procedures, it might be necessary to intercept/override/track this behaviour. And from that, there is little choice to but require the `context`.

A good APIs offers a way to specify the allocator to use, e.g. `allocator: runtime.Allocator` or `allocator := context.allocator`. An API that doesn't offer it can be worked around by overriding the `context.allocator` for that call or series of calls, in the knowledge that the other programmer didn't hardcode the allocator they gave to `make`, et al.

## What is Provided by the `context`?

### The Allocators

There are two allocators on the `context.allocator` and `context.temp_allocator`. I expect most people to never use custom allocators whatsoever (which is empirically true), but I do also want to encourage things like using the `context.temp_allocator` because it allows for many useful benefits, especially those that most people don't even realize are a thing. For many people, they usually just want to do nothing with the `context` (assuming they know about it) or set the `context.allocator` to the `mem.Tracking_Allocator` and be done; that's pretty much it.

You could argue that it is "better" to pass allocators[^explicit-allocators] around explicitly, but from my own experience in C with this exact interface (made and used well before I even made Odin), I found that I got in a very very lazy habit of not actually passing around allocators properly. This overly explicitness with a generalized interface lead to more allocation bugs than if I had used specific allocators on a per-system basis.

[^explicit-allocators]: If you want to disallow `allocator := context.allocator` like defaults in Odin on a per-file basis, you can do so with the get tag `#+vet explicit-allocators`.

When explicit allocators are wanted, you rarely want the generic interface too, and usually a specific allocator instead e.g. `virtual.Arena`. As I have previously expressed in my [Memory Allocation Strategies](https://www.gingerbill.org/series/memory-allocation-strategies/) series, an allocator can be used to represent a specific set of lifetimes for a set of allocations---arenas being the most common kind but other allocators such as pools, basic free lists, etc may be useful.

However because most people will still default to a traditional `malloc`/`free` style of dynamic memory allocation, having a generic interface which can be overridden/intercepted/tracked is extremely useful to be able to do, especially in third-party libraries/code.

**n.b.** Odin's `context.allocator` defaults to a heap-like allocator on most platforms, and `context.temp_allocator` defaults to a growing arena-like allocator.

### `assertion_failure_proc`

The field `assertion_failure_proc` exists because you might honestly want a different way of asserting, with more information it like stack traces. You might even want to use it as a mechanism to do a rudimentary sort of exception handling (similar to Go's `panic` &amp; `recover`). Having this overridable is extremely useful, again with third-party code. I understand it does default to something when it is not set, but that's still kind of the point still. It does need to assert/panic, which means it cannot just do nothing.

### `logger`

Logging is common throughout most applications and we wanted to provide a default approach. I expect most people to default to this as they want a simple unified logging experience. Most people don't want their logs to be handled by different libraries in numerous different ways _BY DEFAULT_. But because it is on the `context`, the default logging behaviour can now overridden easily. If you something more than this logger interface, then use what you want. The point as I keep trying to iterate is: what is the default and what will third-party libraries default to so that you can then intercept it if necessary?

### `random_generator`

This is the newest addition to the `context`; part of the reason for this being here is probably less than obvious. Sometimes a third-party library will do (pseudo-)random number generation but controlling how it does that is very hard (if not impossible).

Take C's `rand()` for example. If you know the library is using `rand()`, you can at least set a seed with `srand()` if you want a deterministic controlled output. However I have used libraries in C which use a different random number generator (thank goodness because `rand()` is dreadful), but I had no way to overriding it without modifying the source code directly (which is not always possible if it's a precompiled LIB/DLL). The counter is when you want a cryptographic grade random number generator and you want non-determinacy whatsoever.

Having a random generator be on the `context` allows for all of this kind of interception.

**n.b.** Odin's default `random_generator` is based on [ChaCha8](https://github.com/odin-lang/Odin/blob/master/base/runtime/random_generator_chacha8.odin) is heavily optimized with SIMD.

### `user_ptr` and `user_index`

If you have used C, you've probably experienced having callbacks where there is way to pass a custom user data pointer as part of it. The API designer has assumed that the callback is "pure". However in reality, this is rarely the case, so how do you actually pass a callback (which is immediately used, not delayed) that you can pass user data too? The most obvious example of this is `qsort`, and even in the "pure" case, it is common to do a sort of a key based on an external table.

There are two approaches that some people do in languages without closures (e.g. C and Odin) to get around these issues, but neither of which are great: global variables and/or thread local variables. Honestly, those are just dreadful solutions to the problem, and why `context` has the `user_ptr` and `user_index` fields, to allow you to intercept this poorly thought out API.

Now you might be asking: Why both a pointer and an index? Why not just a pointer?

From my experience of programming over many years, it is very common I just want to pass the same value to many callbacks but I want to access a different "element" inside of the data passed. Instead of creating a wrapper struct which has both this pointer and the index, I wanted to solve it by just having both already. It's an empirically derived solution, not anything from "first principles".

I do recommend that an API should be designed to minimize the need for callbacks in the first place, but when necessary to at least have a `user_ptr` parameter for callbacks. For when people do not design good APIs, `context` is there to get around the crap.

### Lastly, `_internal`

This just exists for internal use within the core library, which no-one should never use _for any reason_. Most of the time, it exists just for temporary things which will be improved in the future, or for passing things down the stack in a bodgy way. Again, this is not for the programmer, it's for the compiler/core library developers only.

## Circumventing Bad APIs

As I said in the `user_ptr` and `user_index` section, a lot of the impetus for making `context` comes from the experience of using numerous C libraries. The _GOOD_ C libraries that allow for a form of interception usually do it through a macro; at best, they only do `MY_MALLOC` and `MY_FREE` style things, and sometimes `MY_ASSERT`. However, those are not the norm and usually only written by people in a similar "sphere of influence" to myself. Sadly, the average C library doesn't allow for this.

Even so, with the _GOOD_ C libraries, this macro approach fails across a LIB/DLL boundary. Which is part of the problem when interfacing with a foreign language (e.g. Odin). So even in the _GOOD_ case for C, it's not that good in practice.

Now some library writers are __REALLY GOOD__ and they provide things like an allocation interface, but I probably know all of these library writers personally at this point, so I'd be preaching to the choir with my complaints.

I've honestly had a few people effectively tell me that if it's an bad API then the user should put up with it---"It's API is bad? Oh well, tough luck". However, I've had a lot the same people then ask "but why does _the language_ need to solve that? Isn't it a library problem?".

I'm sorry but telling someone the API is at fault doesn't help them in the slightest, and if a API/library cannot be easily modified, then how can that be fixed in code? It's fundamentally only fixable at the language itself.

### The Evolution of Code

People rarely write things perfect the first time---code evolves. That's what engineering is all about. Requirements change. The people change. The problem changes entirely. Expecting not to be able to intercept third-party code is pie-in-the-sky thinking. As I've said numerous times before, Third-party just means "stuff not written by you"; that's it. As I stress, it could even be your past self, which is not the same as your present self.

Point out that shitty APIs exist is the entire point. Just saying "tough luck" doesn't solve anything, you're adding to the problem.

This is why `context` exists.

## ABI Layout

One important aspect about the `context` is that memory layout is __not__ user modifiable, and this is another big design choice too. It allows for a consistent and well understood ABI, which means you can---you guessed it---intercept third-party code even across LIB/DLL boundaries.

If the user was allowed to add as many custom fields to the `context` as desired, it would not be ABI consistent, and thus not be stable for the use of its interception abilities across LIB/DLL boundaries. At best, allowing for custom fields is allowing you to minimize passing/typing parameters to procedures. Typing is rarely---if ever---the bottleneck in programming.

## Implementation

Another common question I've gotten a few times is why the `context` is passed as an implicit pointer argument to a procedure, and not something like a thread local variable stack? The rationale being that there would not need to be a calling convention difference for `context`. Unfortunately through a lot of experimentation and thought, there are a few reasons why it is implemented the way it is:

* Easier to manage across LIB/DLL boundaries that trying to use a single thread-local stack
* Easier management of recovery from crashes where the `context` might be hard to figure out.
* Using the existing stack makes stack management easier already, you don't need to have a separate allocator for that stack
* Some platforms do not thread-local variables (e.g. freestanding targets)
* Works better with async/fiber based things, which would then require a fiber-local stack instead of a thread-local one
* Prevent back-propagation, which would be trivial with a global/thread-local stack

Odin's `context` also has copy-on-write semantics. This is done for two reasons: to keep things local, and prevent back-propagation of "bad" data from an third-party library (be it malicious or just buggy). So not having an easily accessible stack of `context` values makes it harder for this back-propagation to happen.


## The Inspiration

The main inspiration for the implicit `context` system does come from Jonathan Blow's language, however I believe the reasoning for its existence in Jonathan Blow's language is very different. As I have never used Jon's language, I am only going on what other people have told me and what I have seen from Jon's initial streams. From what I can tell, Jon's language's `context` behaves quite different to Odin's, since it allows for the ability to add custom fields to it and to back-propagate.

I am not sure what Jon's initial rationale was for his form of `context`, but I do not believe Jon was thinking of third-party code interception when he designed/implemented his `context`. I hypothesize it was something closer to a form of "static dynamic-scoping" but not exactly (I know that's an oxymoron of a statement). All I know is when I saw it, I saw a brilliant solution to third-party code interception problem.


## Conclusion

I hope this clarifies a lot of the design rationale behind the implicit `context` system, and why it exists.

If you have any more questions, or want me to clarify something further, please feel to contact me!