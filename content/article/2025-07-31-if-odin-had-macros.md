---
{
    "title": "If Odin Had Macros",
    "slug": "if-odin-had-macros",
    "author": "Ginger Bill",
    "date": "2025-07-31",
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

I sometimes get asked if Odin has any plans to add hygienic macros or some other similar construct. My general, and now (in)famous, answer is to many such questions is: **No**.

I am not against macros nor metaprogramming in general, and in fact I do make metaprograms quite often (i.e. programs that make/analyse a program). However my approach with the design of Odin has been extremely [pragmatic](/article/2020/05/31/progamming-pragmatist-proverbs/). I commonly ask people who ask for such things what are they specifically trying to solve? Usually they are not trying to do anything whatsoever and are just thinking about non-existent hypotheticals. However, in the cases when people are trying to do something that they believe they need a macro for, Odin usually has a different approach to doing it and it is usually much better and more suited for the specific need of the problem.

This is the surprising thing about designing Odin, I was expecting I would need some form of compile-time metaprogramming at the language level, be it hygienic macros, compile-time execution, or even complete compile-time AST modification. But every problem I came across, I find a better solution that could be solved with a different language construct or idiom. My original hypothesis in general has been shown to be wrong.


## A Possible Case for Macros in Odin

**n.b. This is all hypothetical, and the construct is very unlikely to happen in Odin**

One of the best cases for a macro-like construct that I can think of which Odin does not support would be push-based iterators. Since Go 1.23, it now has a way of doing [push-based iterators](https://github.com/golang/go/issues/61897). I've written on this topic before ([Why People are Angry over Go 1.23 Iterators](/article/2024/06/17/go-iterator-design/)) and how they work. The main issue I have with them, and which many other individuals have complaints with too, is that they effectively rely on 3-levels deep of closures. You have a function that returns a closure that in turn takes in a closure which is automatically and implicitly generated from the body of a `for range` loop. This is honestly not going to be the best construct for performance by any stretch because it is relying on so heavily on closures.

For Odin since it has no concept of a closure, being that it is a language with manual-memory-management[^mmm-note], it would not be possible to add the same approach that Go does. However there is a way of achieving this in a similar way which requires no closures, and would produce very good code due to its imperative nature.

## The Idea

[^mmm-note]: I'd argue that actual closures which are unified everywhere as a single procedure type with non-capturing procedure values require some form of automatic-memory-management. That does not necessarily garbage collection nor ARC, but it could be something akin to RAII. This is all still automatic and against the philosophy of Odin.

Using the example from the previous [Go article](/article/2024/06/17/go-iterator-design/) I wrote, consider the following pseudo-syntax:

```odin
backward :: iterator(s: []$E) -> (E, int) {
	for i := len(s)-1; i >= 0; i -= 1 {
		if #yield(s[i], i) == .Break {
			break
		}
	}
}

s := []string{"a", "b", "c"}
for e, i in backward(s) {
	if i == 0 {
		break
	}
	fmt.println(e, i)
}
```

The internally expanded code in the backend would look something similar to this:

```
s := []string{"a", "b", "c"}

{ // backward
	for i := len(s)-1; i >= 0; i -= 1 {
		br: Branch_Result = .Continue
		body: {
			if i == 0 {
				br = .Break
				break body
			}
			fmt.println(e, i)
		}
		if br == .Break {
			break
		}
	}
}
```

This is of course a restricted form of a hyigenic macro only applicable to iterators. However this is only way to achieve such a construct in the language.

However the way you'd write the macro is still extremely imperative in nature. The push-iterator approach allows you to store state/data in the control flow itself without the need for explicit state which a pull-iterator would require.

A more common example would be the iteration over a custom hash map:

```odin
my_string_map_iterator :: iterator(m: My_String_Map($V)) -> (string, V) {
	for bucket in m.buckets {
		if !bucket.filled {
			continue
		}
		if #yield(bucket.key, bucket.value) == .Break {
			break
		}
	}
}

for k, v in my_string_map_iterator(m) {
	fmt.printfln("Key: %v, Value: %v", k, v)
}

```


## Composability (or Lack Of)

This approach to iterators is very imperative and not very "composable" in the functional sense. You cannot chain multiple iterators together using this approach. I personally don't have much need for composing iterators in practice and I usually just want the ability to iterate across a custom data structure and that's it. I honestly don't think the composability of iterators is an actual need most programmers have, but rather something that "seems cool"[^cool] to use.

[^cool]: Remember, you're a bunch of programmers--you're not cool.


I don't think I can think of a case when I've actually wanted to use reusable composable iterators either, and when I've had something near to that, I've just written the code in-line since it was always a one-off.


## Will This Ever Happen?

It's unlikely that I would ever add a construct like this to Odin. Not because I don't think it isn't useful (it obviously is) but rather it is a [slippery slope](https://en.wikipedia.org/wiki/Slippery_slope) construct. A lot of features and constructs that have been proposed to me over the years usually fall into this category. A slippery slope is rarely a fallacy in my opinion[^argue] when it comes to design and that if you allow it at one point, there isn't much justification to stop it later on. Giving into one whim does lead to giving into another whim.

[^argue]: I'd easily argue if it actually is slippery slope, it cannot be a fallacy.

In this case, I'd argue the slippery slope is the design for more hygienic macros throughout the language, not just to modify pre-existing control flow but to add new control flow, or add other constructs to the language. This is why I have to say **no**. To keep Odin the language that is loved by so many people, I have to hold the reins and steer it with a clear vision in the right direction. If I allow anyone's and everyone's desire to slip into the language, it will become worse than a design by committee language such as C++.

The road to hell is not paved with good intentions but rather the lack of intention.

So my current answer at the time of writing to this construct is this: **No**.

