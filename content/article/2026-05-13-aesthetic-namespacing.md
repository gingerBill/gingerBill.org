---
{
    "title": "The Aesthetic Problem of Namespacing",
    "slug": "aesthetic-namespacing",
    "author": "Ginger Bill",
    "date": "2026-05-13",
    "categories": [
        "programming language theory",
        "programming languages",
        "aesthetics",
        "ergonomics"
    ],
}
---

Karl Zylinski's [Tom's Namespaces: An Odin Fanfic](https://zylinski.se/posts/toms-namespaces/) is an excellent exploration of the namespacing problem in imperative programming languages such as Odin[^recommend]. After sharing it on many comment forum sites, I've concluded there's no real "solution."

[^recommend]: I highly recommend reading that article before reading this one!


## `type_verb` Association

The article uses a simple example:

```odin
world_add :: proc(w: ^World, e: Entity) {...}

// usage
world_add(&world, entity)
```

The _aesthetic_ argument against this form of namespacing is that this looks fine with short 1/2 word length type names, but becomes unwieldy with longer ones like `Thingy_Foo_Helper`:

```odin
thingy_foo_helper_get_handle :: proc(h: ^Thingy_Foo_Helper) -> Handle {...}

// usage
handle := thingy_foo_helper_get_handle(&tfh)
```

The proposed fix by the people complaining is usually methods: `tfh.get_handle()`.

But the core argument is still just an _aesthetic_ objection, and I'd argue an _aesthetic_ dislike for a pure imperative procedural programming language. Nothing is semantically impossible without methods, it just might appear "ugly" to some people. Unfortunately, methods introduce their own set of problems[^faq-methods] and Odin does not support them in the typical sense. The best approach to tackle this "aesthetic problem" for Odin is the [Newellian](https://en.wikipedia.org/wiki/Gabe_Newell) one:

> _Do nothing._

[^faq-methods]: Odin's [FAQ](https://odin-lang.org/docs/faq/#but-really-why-does-odin-not-have-any-methods) briefly covers why Odin has no methods.

## Public By Default

A related pattern I keep seeing: people's overuse of `@(private="file")` creating unnecessary friction. The question I always ask is: Who are you hiding code from? *Yourself?!*

I believe this habit usually comes from Java/C#/C++ developers treating private-by-default as self-evident good practice—without ever questioning whether it actually is[^other-examples]. Hint: It isn't, and that's exactly why Odin is public-by-default at the package level with no struct-level `private`/`protected`.

[^other-examples]: There is no shortage of unquestioned dogma in programming, but cataloguing it all is beyond the scope of this article.

Ask yourself: why does something need to be file-private? Why isn't package-private enough? And even, does it need to be private at all? Odin is public-by-default for a reason: try embracing it.

Most complaints boil down to wanting to separate a _public_ API from _private_ internals. And if you genuinely need that distinction, use a "pseudo-private" convention like a `_` prefix. It signals "internal" without actually preventing access if you later need it. Or if you need "true" privacy, try using [type erasure](https://en.wikipedia.org/wiki/Type_erasure).

I've repeatedly needed access to something a third-party API made private, whether a struct field or a procedure. For struct fields, I've resorted to unsafe pointer arithmetic to get around the `private`ness. And for procedures, I've had to reimplement them entirely from scratch.

Please, if you are designing an API, please don't assume you know better than the people using it. You cannot predict the future nor what they will actually need. Add warnings if necessary, but never outright prevent people from bypassing them. Let people disable the safety and shoot the gun if they need to.

## Nudging as an Aspect of Design Philosophy


Both issues, namespacing complaints and private-by-default habits, share the same root: developers carrying assumptions from other languages/paradigms into Odin instead of adapting to its design philosophy. Much of Odin's design is aimed at solving real-world problems in a pragmatic fashion[^other-way]. As a consequence, some things are *deliberately* annoying to do, because the language is [nudging](https://en.wikipedia.org/wiki/Nudge_theory) you away from them.

[^other-way]: The reverse also applies: forcing Odin's ideas onto languages that weren't designed for them probably isn't a good idea either.

The _Joy of Programming_ is hard to cultivate, and I've tried my best to foster it with Odin. Nudging is an aspect of why Odin feels so [ergonomic](https://en.wikipedia.org/wiki/Ergonomics). Most people naturally follow the "happy path", and typically the subtle _friction_ on bad approaches goes unnoticed since people do not fight it. But some people push headlong through that friction anyway, fighting the language/compiler instead of listening to it. Packages, namespaces, and `private`ness are all areas where people do this: misusing features based on unquestioned dogma from other languages.

Sometimes you cannot stop people poking themselves in the eye. You can only hope they eventually realize—on their own or through others—that they're making things worse for themselves and everyone who has to use their code.
