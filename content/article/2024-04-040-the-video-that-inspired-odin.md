---
{
    "title": "The Video That Inspired Me To Create Odin",
    "slug": "video-that-inspired-odin",
    "author": "Ginger Bill",
    "date": "2024-04-04",
    "categories": [
        "software"
    ],
    "tags": [
        "odin",
        "c",
        "stb"
    ]
}
---


**[Originally from a Twitter Thread]**

[Original Twitter Post](https://twitter.com/TheGingerBill/status/1775853386694332461)


Many people may not know this but this video by Sean Barrett [@nothings](https://twitter.com/nothings) is partially the reason why I made the [Odin programming language](https://odin-lang.org/).


<div class="youtube">
  <iframe width="560" height="315" src="https://www.youtube.com/embed/eAhWIO1Ra6M" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>

And I'll explain what insights it gave me in this thread 🧵.

A lot of these seem "so obvious" but for some reason it never clicked to me before this video. A lot of the "higher level" "scripting" languages are not that much higher level than C. Those languages just have garbage collection and much better standard libraries than C.

Those languages are "easier to use" than C just because they have loads of built-in data structures like arrays, hash maps, and built-in syntax for them (how "extravagant", I know).

I was already well aware of the STB libraries that Sean developed, and the single-header-file style too of them (which is mostly a cope for C's flaws), but it never clicked to me that the library that Sean used the most was the ["stb.h"](https://github.com/nothings/stb) one.

This lead me to organize code I had used in previous projects already and put that into a single and easy to use library which I could use in any of my C projects going forward in 2015/2016: https://github.com/gingerBill/gb/blob/master/gb.h

However by around March, I began experimenting with just making an "augmented" C compiler so that I could add constructs to C which I found to be some of the most annoying things C lacked. The first, and most important, two constructs were:

* Slices
* `defer`


I had already been using `defer` in C++ for many years already. I really wished the concept was native to C. (My opinion has now changed now for C for many reasons).

P.S. I wrote an [article](https://www.gingerbill.org/article/2015/08/19/defer-in-cpp/) about what I had been doing back in 2015 for defer in C++11

Eventually I realized I couldn't just add constructs and features to C to "improve" my personal projects, and that any of my professional projects could not use them either. This then lead me to starting my own compiler to fix those issues I had with C.

Interestingly, "Odin" (which was the original codename which just stuck) started life as a Pascal-like language with begin/end too, but I was trying to make it "C-like" enough for what I wanted. About 3 months later, I had implemented ~70% of Odin; the other ~30% took 7 years.

Odin wasn't my first programming language that I had designed nor implemented, but it was the first where I actually went "you know what?—this will actually be useful for my general needs". And now I use it for my living at [JangaFX](https://jangafx.com/), where all of our products are written in it.


Other than slices and `defer`, the other things I did for Odin were to solve a few practical issues I had in C:

* A slice-based `string` type
* Decent variadic parameters (a slice-based one)
* RTTI (not bug-prone format verbs in printf, and not my janky generated stuff)
* Actual libraries

I won't discuss the benefits of slices here but I will discuss the latter 3 things of that list.

In C, pretty much my only use case for variadic parameters were `printf`-style things. Adding a decent form of that + coupled with RTTI, allowed me to have a runtime-typesafe `printf`.


As for "actual libraries", they need their own namespace. When the user imports it, he can change import name itself, rather than relying on the library to prefix everything (or C++ namespace) to minimize namespace collisions.

This eventually lead to Odin's [package system](https://odin-lang.org/docs/overview/#packages).


I highly recommend everyone to watch [this talk](https://www.youtube.com/embed/eAhWIO1Ra6M) by Sean Barrett! It was a huge inspiration for me, and just a general eye-opener for something which should have been obvious to me at the time but wasn't.