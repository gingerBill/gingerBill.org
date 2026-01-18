---
{
    "title": "Mitigating the Billion Dollar Mistake",
    "slug": "mitigating-the-billion-dollar-mistake",
    "author": "Ginger Bill",
    "date": "2026-01-11",
    "categories": [
        "software",
        "programming language theory",
        "programming language design",
        "programming languages"
    ],
    "series": [
        "The Billion Dollar Mistake",
    ]
}
---

This article is continuation to: [Was it really a Billion Dollar Mistake?](/article/2026/01/02/was-it-really-a-billion-dollar-mistake/).

---

After reading a lot of the comments on numerous social media sites on the [original article](/article/2026/01/02/was-it-really-a-billion-dollar-mistake/), I think I need to clarify _a lot_ more.

The main points I wanted to clarify:

* Null pointer dereferences are empirically the easiest class of invalid memory addresses to catch at runtime, and are the least common kind of invalid memory addresses that happen in memory unsafe languages.
* I do think it was a _costly_ mistake but the "obvious solutions" to the problem are probably just as _costly_, if not more so, but in very subtle ways which most people neglected to understand in the article[^didn't-read].
* I think that even if Tony Hoare didn't "invent" `NULL` pointers, within a couple years someone else would have. I don't think it's a "mistake" the programming world was ever going to avoid.
* I am talking about languages that run on modern systems with virtual memory, not embedded systems where you interact with physical memory directly. Those platforms in my opinion need much different kinds of languages which unfortunately do not exist yet.
* I was also talking about languages akin to C and Odin, not languages that run on a VM or have "everything be a reference".

[^didn't-read]: Most of the bad criticisms just came from people who didn't read the article or didn't read past a couple paragraphs. That's why I wanted to state this comment very clearly.

## Languages where Everything is a Pointer

A lot of commentors based their complaints in their experience with languages like Java/C#/Python/etc, and the issues with null-pointer-exceptions (NPEs) in them. What I think a lot of people seemed to forget is that in those languages, virtually _everything_ is a pointer, unlike in a language like C/Go/Odin which has explicit pointers. When everything is a pointer, it is _exponentially_ more likely that you will hit a pointer that is invalid. And in the case of a managed (garbage collected) language, that invalid pointer will most definitely be a null pointer. This is why I can understand the problem of having `null` pointers in such languages.

But I think this still missed the point of what I trying to state, that the reason `null` even exists in those languages is because you can declare a variable without an explicit initialization value:

```java
Object value; // Object is internally a pointer in Java

// which is equivalent to the following in C
Object *value_ptr = NULL;
```

Because you can declare such a thing in a language like Java, then there are three options to try and mitigate this design flaw:

* Allow for `null` pointers (and just deal with it)
* All pointers are implicitly maybe types (e.g. `Optional<Object>` in Java)
* Require all explicit initialization of every element everywhere to assume `null` cannot happen, along with things like maybe types.

Unfortunately existing languages like Java cannot have these problems solved, but newer languages that want to stylize themselves similar to that could solve them. One of the issues is that languages like Java added maybe/option/optional types too late AND it is not the default behaviour.

The first approach is the current status quo, the second approach keeps the implicit value declarations but adds more checks, whilst the third approach requires doing explicit value declarations.

## Mitigations with Implicit Value Declarations

The enforcement of maybe types as the default pointer/reference type leads to two possibilities:

1) Requiring each reference to be checked if it is `null`.
2) Check if a value is `null` and propagate that `null` up the expression tree.

Version 1 would be something like this:
```rs
if let x {
    // x is assumed to be not equal to `null` in this case
    print(x.y)
}
```
but because of the ergonomic pains, can also lead to unwrapping cases, which are _practically equivalent_ to NPEs:

```c
print(x.unwrap().y)
```

At least with an `unwrap`, it is a little clearer that a panic could happen. But it can also just be an early-out too like with Odin's `or_return`:
```c
print((try x).y) // returns on x if nil
```

Version 2 is a bit weirder, since it doesn't remove the concept of `null` but propagates further up the expression tree.

```cs
a?.b?.c
// which is equivalent to
a != null ? (a.b != null ? (a.b.c != null ? a.b.c : null) : null) : null
```

The first approach is unergonomic to use, especially in a language where virtually _everything_ is a pointer/reference, and with the addition of unwrapping which just panics on `null`, it's practically reinvented NPEs with more steps. As for the second approach, I'd argue is very bug prone if it was the default, since you cannot trivially know where the `null` arose from since it was just passed up the stack[^akin-to-exceptions].

[^akin-to-exceptions]: This is partially why I do not like exceptions as error handling in many languages. It is not obvious where things are thrown/raised from and they encourage the practice of ignoring them until the latest possible space. I discuss that problem in [The Value Propagation Experiment Part 2](/article/2021/09/06/value-propagation-experiment-part-2/).

Therefore most people think the third approach to mitigating `null` pointers is the "obvious" and "trivial" approach: _explicit individual initialization of every value/element everywhere_.

## Mitigations with Explicit Value Declarations

One thing which I commonly saw was people saying was that I "missed the point" that null safety is not about protecting from common invalid memory access but rather it's about clarifying the states that a pointer can be in the type system itself, whether it cannot be null or _maybe_ it could be null. I already knew this, and I find it bizarre[^insulting] that people did not understand that from the article.

[^insulting]: I understand what type systems do and their benefits, and it is a little insulting when people assume my knowledge (or lack of) without doing a modicum of review.

The point I was trying to get across which most people seemed to either ignore or not understand was that the approach of requiring _explicit initialization of every element everywhere_ comes with a cost and trade-offs. Most people who bring this up as "the solution" think there was either no cost or they think the cost is worth it. The former group are just wrong, and the latter group are the point I was focusing the article at in the first place: you don't actually understand the costs fully if you are answering the way that you do. I understand this sounds "condescending" to some people, but I am not trying to be. The point I am arguing is far from the common view/wisdom, and thus I tried to explain my position. Why would a person listen to someone with a "fringe" view? "Fringe" views are typically wrong in other areas of life, so it makes sense to apply that heuristic to the domain of programming too. I don't care if people agree with me or not, rather I wish people actually understand it and then comment.

But as a systems programmer, I deal with memory all the time, and null pointers are the least common kind of invalid memory that I have to deal with, and the other kinds were not handled by the type system, nor would be handled with solving the problems of null. No, this is not saying "well just because you cannot solve problem X with Y, therefore don't solve either", it's saying that they are different problems, and empirically they are just different with different kinds of severity and ways to mitigate them. I am not saying you shouldn't try to solve either problem if you are designing your own language, but rather they are both kinds of invalid memory, but solutions to mitigate the problems are completely different in kind[^linear-types].

[^linear-types]: In the case of the other invalid memory addresses, linear/affine substructural type systems with lifetime semantics can help with this (e.g. Rust) but they come at another cost in terms of language ergonomics and restrictions. Language design is hard.

For a managed language like Java, the cost of _explicit initialization of every element everywhere_ is so little in comparison to the rest of the language, that approach is honestly fine. But for a language like the one I have designed and created---Odin---the cost of non-zero initialization is extremely costly as things scale.

This simple/naïve approach looks like this in a pseudo-C:

```c
Object *x; // ERROR: must be initialized
Object *x = new_with_constructor(Object); // Correct approach
```

But if you use a lot of pointers everywhere, the initialization becomes a lot more complex, and non-linear too.

People argue the need to express non-nullable pointers, and either version 1 of the previous approach or this explicit approach are effectively the only ways of doing this. You could tell the compiler to assume the pointer is never null (e.g. `__attribute__((nonnull))` or `int foo(char const bar[static 1])`), but those are not guarantees in the type system, just you telling the compiler to assume it is never `NULL`. The non-nullability is not possible outside of those two approaches.


This was the entire point I was making between the [Individual-Element Mindset](/article/2026/01/02/was-it-really-a-billion-dollar-mistake/#the-gotcha) and the [Group-Element Mindset](/article/2026/01/02/was-it-really-a-billion-dollar-mistake/#the-grouped-element-mindset) is that the individual-element mindset lends itself well to thinking about individual elements like this. And as such, it doesn't really think about the cost of thinking in individual elements as compounding to something expensive. I've been in projects where a lot of the time in a program in spent in the destructors/`Drop` traits of individual elements, when all they are doing is trivial things which could have been trivially done in bulk. Most people don't consider these as "costs" nor that there are trade-offs to this approach to programming, rather it's "just the way it is".

There is the other aspect where if the explicit initialization is applied to every type, not just ones which contains pointers/references, then it can be less ergonomic to type and have visual noise:[^bottleneck]

[^bottleneck]: I know typing is never the bottleneck in programming, but the visual noise aspect is a big one when you are trying to _scan_ (not necessarily _read_) code. I want to see the pattern and not be swamped with syntactic noise.

```c
Foo f = {};
Bar b = {};
grab_data(&f, &b);
```
This constant syntactic noise can be tiring and detracts from what is actually going on. With the implicit zero initialization that I had in Odin, it has worked out really well. Many might expect it to be confusing, but it isn't and you can rely on it and becomes very natural to use.

## Mitigation with a Different Paradigm

As the creator and main architect of Odin, a lot of Odin's design has been to fix a lot of the problems I and many others faced with C, whilst still not veering too far from the general _feel_ of C. Odin does have `nil` pointers by default, but in practice they are a very rare problem due numerous features and constructs of the language.

One of the reasons for `NULL` pointers in C is caused to due the lack of a proper array type. Odin has proper array types and does not implicitly demote arrays to pointers. Odin has slices which replace a lot of the needs for pointers and pointer arithmetic, and because array types (including slices) are bounds checked, that already solves many of the problems that would have occurred in C with treating pointers as arrays, which may or may not have an associated length to check against.

Odin also has tagged unions and multiple return values. Tagged unions should be "obvious" to the people who had be complaining about the initial article, but the use of tagged unions isn't necessarily there to solve the `nil` pointer problem.

Odin's `Maybe` is an example of a maybe/option type, which is just a built-in discriminated union, with the following definition:

```odin
Maybe :: union($T: typeid) { T }
```

And due to the design of Odin's `union`, if a union only has one variant and that variant is any pointer-like type, no explicit tag is stored. The `nil` state of the pointer-like value also represents the `nil` state of the `union`. This means that `size_of(Maybe(^T)) == size_of(^T)`.

Another reason why C has problems with `NULL` pointers is the lack of way to state a parameter to a procedure as being optional. C doesn't have default values for parameters, nor any way in its type system to express this. C's type system is just too poor and too weak. This is why people unfortunately use pointers as a way to do thus, since they can write `NULL`.

However, it is rare to see `Maybe` in Odin code be used to indicate `nil` pointers except when interfacing with foreign code, or optional parameters to a procedure. This is because the need for a `nil` pointer itself is quite rare. There are multiple reasons why:

* Odin has slice types
* Odin has multiple return values to allow for out-only parameters, which could be ignored with `_`
* Odin isn't a "everything is a pointer" kind of language: pointers have to be explicit typed to exist.
* Writing pointer types as value declarations is less common due to type inference
  * e.g. `p := &x` is more much common than: `p: ^T; p = &x`.

However one of the main reasons why `nil` pointers are rarely a problem in Odin is because of multiple return values. Multiple return values when used for this manner, are akin (but not semantically equivalent) to something like a `Result` type in other languages[^result-type]. When a procedure returns a pointer, it is either assumed to be never `nil` OR accompanied with another value to indicate its validity, commonly in the form of a boolean or `enum`:

[^result-type]: I know a result type is a kind of _sum_ type and multiple return values are more akin to a _product_ type, but how different languages want to be used and expressed, this works out fine in practice for the same kinds of problems. Please don't give me a FP rant.

```odin
allocate_something :: proc(...) -> (^T, mem.Allocation_Error) {
	...
}
```

And coupled with the `or_*` constructs (`or_return`, `or_break`, `or_continue`, `or_else`), `defer`, and named return values, a lot of those issues never arise:
```odin
ptr, err := allocate_something()
if err != nil {
	return err
}
// becomes
ptr := allocate_something() or_return
```

Odin is designed around multiple return values rather than `Maybe`/`Result` constructs, but this approach does in practice does solve the same kinds of problems.

Before people go "well the assumption is not enforced in the type system", remember where all of this derives from: Odin allows for implicit declarations of variables without an explicit initialization value. And as the designer of Odin, I think enforcing that is both quite a high cost (see the individual-element vs grouped-elements mindsets) and far from the original approach to programming C. I know this is not going to convince people, but it's effectively trying to make someone think like another person, which is never easy, let alone always possible to do in the first place. And it's not a mere "aesthetic preference" either. This very little design decision has _MASSIVE_ architectural consequences which lead to numerous performance problems and maintenance costs as a project grows.


## Analogies to Other Panicking Constructs in a Language

Null pointer exceptions (NPEs) are in a category of constructs in a language which I class as "panic/trap on failure". What I find interesting is that there are numerous other things in this category, but many people will normally take a different approach to those constructs compared to NPEs, due to whatever reason or bias that they have.

The canonical example is integer division by zero. Instinctually, what do you think division by zero of an integer should result it?

* Trap
* Zero (`x/0 == 0`)
* All bits set (`x/0 == ~0`)
* The same value (`x/0 == x`)


I'd argue most people will say "trap", even if a lot of modern hardware (e.g. ARM64 and RISC-V) does not trap, and only the more common x86-related architectures do trap. Odin does currently[^currently-trap] define the behaviour of division by zero to "trap" only because of this assumption, but we have considered changing this default behaviour. Odin does allow the programmer to control this behaviour at a global level or on a per-file level basis if they want a different behaviour for division by zero (and consequentially `%` by zero).

[^currently-trap]: At the time of writing, I am not sure which approach is the better one: trap or zero by default, but we allow for all four options in the Odin compiler. Division by zero for floats results in "Inf" and that's not necessarily as much of a problem in practice, so why would division by zero be as bad?

But some languages such as [Pony](https://tutorial.ponylang.io/expressions/errors.html?h=exception#try-then-blocks), Coq, Isabelle, etc actually define division by zero of an integer to be `0`. This is because it can help a lot of [theorem provers](https://xenaproject.wordpress.com/2020/07/05/division-by-zero-in-type-theory-a-faq/).

But there is the other question of production code. One of the main arguments against NPEs (especially in languages like Java) is that it causes a crash. So in the case of division by zero, do you want this to happen? Or would you prefer all integer division to be explicitly handled, or default to a predictable/useful value, like `0`?---which prevents crashing in the first place.

Another common example of "panic on failure" is languages with runtime bounds checking. If `x[i]` is out of bounds, most languages just panic. It's rare to find a language that returns a `Maybe(T)` on every array access to prevent an out of bounds. Not even languages like OCaml do this.

NPEs, division by zero (if traps), and runtime bounds checking are all examples of this kind of "panic on failure", but people rarely treat them as being the same, even if they are of the same kind of problem.

## Is this Experience or Selection Bias?

Honestly, no. I understand it might be common for beginners to a language like C to have many `NULL` pointer related problems, but they will also have loads of other problems too. However as you get more competent at programming, that kind of problem is honestly the least of your problems.


## Conclusion

I honestly think a lot of this discussion is fundamentally a misunderstanding of different perspectives rather than anything technical. A lot of what some people think are their "technical opinions" are merely just aesthetic judgements. And to be clear, aesthetic judgements are not bad, but they are not necessarily technical.

But I'd argue most people are not applying their opinions consistently when it comes to the category of "panic on failure", and NPEs are no different; they only seem more of a problem to them either because of the existence of the name of the "Billion Dollar Mistake" or because they encounter it more.

I know a lot of people view the _explicit individual initialization of every element everywhere_ approach as the "obvious solution", as it seems like low-hanging fruit. As a kid, I was told to not pick low-hanging fruit, especially anything below my waist. Just because it looks easy to pick, a lot of it might not be unpicked for a reason. It does not mean that you should or should not pick that fruit, but rather you need to consider the trade-offs.

If you honestly think the costs of _explicit individual initialization of every element everywhere_ are worth it for the language you are working in or developing, then great! But at least know the trade-offs of that approach. For Odin, I thought it was not worth the cost---compared to the alternative ways of mitigating the problem empirically.
