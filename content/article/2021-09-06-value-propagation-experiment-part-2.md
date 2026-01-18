---
{
    "title": "The Value Propagation Experiment Part 2",
    "slug": "value-propagation-experiment-part-2",
    "author": "Ginger Bill",
    "date": "2021-09-06",
    "categories": [
        "programming",
        "programming philosophy",
        "programming languages"
    ],
    "tags": [
        "philosophy",
        "c",
        "odin",
        "zig",
        "rust"
    ]
}
---

[**[Originally from a Twitter Thread]**](https://twitter.com/TheGingerBill/status/1427226906538168320)

I have revisited [The Value Propagation Experiment](/article/2021/07/05/value-propagation-experiment/) and have come to a different conclusion as to why it failed and how I recovered it. 

The recovery work has been merged into master now with this PR: <https://github.com/odin-lang/Odin/pull/>1082


I think there were three things which were confusing which make it look like a failure of an experiment:

* `try` was a confusing name for what the semantics were.
* `try` as a prefix was the wrong place.
* Unifying `try` with `try else` was a bad idea for many reasons.

Changes in the PR:

* Built-in `or_else` procedure became a binary operator instead (meaning it became a keyword).
* `or_return` was added as a keyword.
* `or_return` became a suffix-operator/atom-expression.


```odin
if i, ok = m["hellope"] !ok { i = 123 }
```
becomes
```odin
i = m["hellope"] or_else 123
```


```odin
if err = foo(); err != nil { return }
```

becomes
```odin
foo() or_return
```


Most people understood what the purpose and semantics `or_else `pretty intuitively but many were very confused regarding the semantics of `try`. My conclusion was that the keyword-name and positioning were the main culprits for that.

Another aspect which I stated in the original article was that I thought the construct was not as common as I originally thought. And for my codebases (including most of Odin's core library), this was true. However it was false for many codebases, including the new [core:math/big](https://github.com/odin-lang/Odin/tree/master/core/math/big).

In the [core:math/big](https://github.com/odin-lang/Odin/tree/master/core/math/big) package alone, or_return was able to replace 350+ instances of `if err != nil { return }` idioms.

The more C-like a library is in terms of design, the more it required this `or_return` construct. It appears that when a package needs it, it _REALLY_ needs it.

When this correction was made, there were 350+ instances of `or_return` in a ~3900 LOC is ~9% of (non-blank) lines of code. That's a useful construct for definite.

Another (smaller) package that found or_return useful was the new core:encoding/hxa, which is an Odin native implementation of 
[@quelsolaar](http://www.quelsolaar.com/ministry_of_flat/)'s HxA format. https://github.com/quelsolaar/HxA

The entire implementation for reading and writing is 500 LOC, of which there are 32 `or_return`s.


I do believe that my general hypotheses are still correct regarding exception-like error value handling. The main points being:

* Error value propagation _ACROSS_ library boundaries
* _Degenerate states_ due to type erasure or automatic inference
* Cultural lack of partial success states


The most important one is the degenerate state issue, where all values can degenerate to a single type. It appears that you and many others pretty much only want to know if there was an error value or not and then pass that up the stack, writing your code as if it was purely the happy path and then handling any error value. Contrasting with Go, Go a built-in concept of an `error` interface, and all `error` values degenerate to this interface. In practice from what I have seen of many Go programmers, most people just don't handle error values and just pass them up the stack to a very high place and then pretty much handle any error state as they are all the same degenerate value: "error or not". This is now equivalent to a fancy boolean.

----

I do hope that this addition of `or_return` does aid a lot of people when making projects and designing packages.

It does appear to be very useful already for many of the core library package developers for Odin.