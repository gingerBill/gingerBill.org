---
{
    "title": "Why I Hate Language Benchmarks",
    "slug": "comparing-language-benchmarks",
    "author": "Ginger Bill",
    "date": "2024-01-22",
    "categories": [
        "software"
    ],
    "tags": [
        "odin",
        "c",
        "comparison",
        "benchmark"
    ]
}
---

**[Originally from a Twitter Thread]**

[Original Twitter Post](https://twitter.com/TheGingerBill/status/1749417960559505591)


I don't know if I have "ranted" about this here before but:

I absolutely **HATE** comparing programming languages with "benchmarks".

Language benchmarks _rarely_ ever actually test for anything useful when comparing one language against another. This goes for ANY language.

Even in the best case scenario: you are comparing different compilers for the same language (and the same input). This means that you are just comparing how well the optimizing backends work for those compilers. Comparing different languages is not even in the same category. When comparing languages, you are not just comparing the optimizing backend of the compiler (assuming it even is compiled), but a completely different input. And most benchmarks rarely use the semantically equivalent code to test against. The implementations vary widely. And even in the case where the input is semantically equivalent AND the compiler backends for each language use the same "library" (e.g. LLVM), even then the semantics of each language may not allow for certain passes. LLVM is a good example which assumes C and C++ semantics. If your language does not adhere to C and C++ semantics, then most of the passes in LLVM cannot be used. And some compilers may have different default "flags" too, which makes dumb comparisons rarely equal (e.g. native vs portable microarchitectures).

Clarifying the semantically equivalent aspect: a printing procedure in one language may be drastically different too. Runtime vs compile-time type information or none at all, flushing after each call or not, richer formatting or not, etc. Are you even comparing the same thing? There is also the "idiomatic" aspect which I hate too. "Idiomatic" in one language is a subjective and personal construct, and may produce very different results compared to "non-idiomatic" code. "Idiomatic" styles might produce slower code in general; the tests won't show this.

One of the most egregious websites for this is: <https://programming-language-benchmarks.vercel.app>. I recommend anyone to compare two languages of the same ilk and actually read the differences between the code in the tests; note how they are nothing alike most of the time. Different implementations &amp; logic.

_**n.b.**_ I do personally try to make distinctions between the language, the compiler, the core library, and the ecosystem, as much as I can. I know most people do not and just lump everything together as a single package. This is due to most languages having a single implementation. But if you come from a C or C++ background, like my own, then you are/were confronted with the selection of different toolchains from the start (MSVC, Clang, GCC, Intel, tcc, 8cc, etc). And you are usually forced to write/import your own core library too (e.g. C's is awful). For a language like Lua, there are different implementations, but they pretty much offer the same "ecosystem", but just differ in how they are ran (i.e. VM vs JIT). And for many people, the choice of which to use is dictated by the use case.

In summation, metrology is hard. You actually need to know what you are comparing against; if that thing is even measurable (quantitatively or qualitatively) in the first place; that the things you are comparing are actually useful or valid for what you want to know. Comparing multivariate things against each other and going "yep, that entire 'language' is faster than this one" is misguided at best, and idiotic at worse. Please don't treat "benchmarks" such as these as mostly pseudo-science, not science. Just because it has loads of numbers and "measurements", does not make it "scientific".