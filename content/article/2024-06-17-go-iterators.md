---
{
    "title": "Why People are Angry over Go 1.23 Iterators",
    "slug": "go-iterator-design",
    "author": "Ginger Bill",
    "date": "2024-06-17",
    "categories": [
        "software",
        "design"
    ],
    "tags": [
        "odin",
        "go"
    ]
}
---

_NOTE: This is based on, but completely rewritten, from a Twitter post:<br><https://x.com/TheGingerBill/status/1802645945642799423>_

**TL;DR**: It makes Go _feel_ too "functional" rather than being an unabashed imperative language.

I recently saw a post on [Twitter](https://x.com/ohmypy/status/1801180323406844062) showing the upcoming Go iterator design for Go 1.23 (August 2024). From what I can gather, many people seem to dislike the design. I wanted to give my thoughts on it as a language designer.

The _merged PR_ for the proposal can be found here:<br><https://github.com/golang/go/issues/61897>

It has a in-depth explanation of the design explaining why certain approaches were chosen instead, so I do recommend reading it if you are familiar with Go.

Here is the example from the original Tweet I found:

```go
func Backward[E any](s []E) func(func(int, E) bool) {
	return func(yield func(int, E) bool) {
		for i := len(s)-1; i >= 0; i-- {
			if !yield(i, s[i]) {
				// Where clean-up code goes
				return
			}
		}
	}
}

s := []string{"a", "b", "c"}
for _, el in range Backward(s) {
	fmt.Print(el, " ")
}
// c b a
```

This example is clear enough in _what_ it does, but the entire design of it is a bit crazy to me for the general/majority use case.

From what I understand it appears that the code will be transformed into something like the following:
```go
Backward(s)(func(_ int, el string) bool {
	fmt.Print(el, " ")
	return true // `return false` would be the equivalent of an explicit `break`
})
```

This means that Go's iterators are much closer to what some languages have with a "for each" method (e.g. `.forEach()` in JavaScript) and passing a callback to it. And fun fact, this approach is already possible in Go \<1.23 but it does not have the syntactic sugar to use it within a `for range` statement.

I will try to summarize the rationale Go 1.23 iterators, but it seems that they ware wanting to minimize a few factors:

* Make the iterator look/act like a generator from other languages (thus the `yield`)
* Minimize the need for sharing too many stack frames
* Allow for clean-up with `defer`
* Reduce data being stored outside of the control flow

As [Russ Cox (rsc)](https://research.swtch.com/) explains in the original proposal:

> Note regarding push vs pull iterator types: The vast majority of the time, push iterators are more convenient to implement and to use, because setup and teardown can be done around the yield calls rather than having to implement those as separate operations and then expose them to the caller. Direct use (including with a range loop) of the push iterator requires giving up storing any data in control flow, so individual clients may occasionally want a pull iterator instead. Any such code can trivially call Pull and defer stop.

Russ Cox goes into more detail in his article [Storing Data in Control Flow](https://research.swtch.com/pcdata) about why he likes this approach to design.


### More Complex Example

**NOTE:** Do not worry about what this actually does, I just wanted to show an example of the clean-up needed with something like `defer`.

An example from the original PR shows an example of a much more complex approach requiring clean-up where values which are _pulled_ directly:
```go
// Pairs returns an iterator over successive pairs of values from seq.
func Pairs[V any](seq iter.Seq[V]) iter.Seq2[V, V] {
	return func(yield func(V, V) bool) bool {
		next, stop := iter.Pull(it)
		defer stop()
		v1, ok1 := next()
		v2, ok2 := next()
		for ok1 || ok2 {
			if !yield(v1, v2) {
				return false
			}
		}
		return true
	}
}
```

## An Alternative Pseudo-Proposal (State Machine)

**NOTE:** I am not suggesting Go does this whatsoever.

When designing [Odin](https://odin-lang.org/), I wanted the ability for the user to design their own kind of "iterators", but have them be very simple; in fact, just normal procedures. I didn't want to add a special construct to the language just for this---this would complicate the language too much which is what I wanted to minimize in Odin.

One possible pseudo-proposal I could give for Go iterators would look like the following:

```go
func Backward[E any](s []E) func() (int, E, bool) {
	i := len(s)-1
	return func(onBreak bool) (idx int, elem E, ok bool) {
		if onBreak || !(i >= 0) {
			// Where clean-up code goes, if there is any
			return
		}
		idx, elem, ok = i, s[i], true
		i--
		return
	}
}
```

This pseudo-proposal would operator like this:

```go
for it := Backward(s);; {
	_, el, ok := it(false)
	if !ok {
		break // it(true) does not need to be called because the `false` was called
	}

	fmt.Print(el, " ")
}
```

This is similar what I do in Odin **BUT** Odin does not support stack-frame-scope-capturing closures, only non-scope-capturing procedure literals. Because Go is garbage-collected, I see little need to no utilize them like this. The main difference is that Odin does not try to unify the ideas into one construct.

I know some people will this think this approach is a lot more complicated. It is doing the opposite of what Cox prefers with storing data in control flow, and store the data outside of it. But this is usually what I want from an iterator rather than what Go is going to do. And this is the problem: it removes the elegance of storing the data in the control flow--the push/pull distinction that Cox explains.

**NOTE:** I am very much an imperative programmer and I like to know how things actually execute, rather than trying to make it "elegant looking" code. So the approach I wrote above is fundamentally about thinking with regards to execution.

n.b. The typeclass/interface route would not work in Go because this would not be an orthogonal design concept and actually be more confusing than necessary---this is why I did not originally propose it. Different languages have different requirements as to what works in them.

## Go's Apparent Philosophy

The approach that Go 1.23 takes seems to go in the face of the _apparent_ philosophy of making Go for the general (frankly mediocre) programmer at Google who doesn't want to (nor can) use a "complex" language like C++.

To quote [Rob Pike](http://herpolhode.com/rob/):

> The key point here is our programmers are Googlers, they're not researchers. They're typically, fairly young, fresh out of school, probably learned Java, maybe learned C or C++, probably learned Python. They're not capable of understanding a brilliant language but we want to use them to build good software. So, the language that we give them has to be easy for them to understand and easy to adopt.

I know many people are offended by this comment, but it's __brilliant__ language design by understanding who you are designing the language for. It is not insulting, but rather the a matter of fact statement as Go was originally for the people who work(ed) at Google, and similar industries. You might be a "better and more capable" programmer than the average Googler but that doesn't matter. There is a reason people love Go: it's simple, opinionated, and most people can pick it up very quickly.

However this iterator design does seem out of character to Go, especially for the someone like proposer Russ Cox (assuming he was _actual_ the original proposer) on the Go team. It makes Go a lot more complicated, and even more "magical" too. I understand how the iterator system works because I am _literally_ a language design and compiler implementer. It also has the possible issue to it won't be a well performing approach either because of its need for closures and callbacks.

Maybe the argument for its design is that the _average Go programmer_ is not meant to __implement__ iterators but just __use__ them. And that the majority of the iterators that people will need will be already available in Go's standard library, or by the third-party package itself. So the onus is put on the package _writer_, not the package _user_.

This is why I think a lot of people seem to be "angry" over the design. It goes against everything Go was originally "meant to be" in the eyes of a lot of people, and it seems like a really complicated "mess". I understand the "beauty" that it looks like a generator with the `yield` and inline code approach, but I do not think that is necessarily in the vein of what Go is to a lot of people. Go does hide a lot of how the magic works under the scenes, especially with garbage collection, `go`routines, `select` statement, and many other constructs. However, I think this is a little too magical in that it _exposes_ the magic to the user a little too much, whilst looking overly complex to the average Go programmer.

The other aspect where people find this "confusing" is that it's a `func` that returns `func` that takes a `func` as an argument. And that the body of the `for range` is transformed into a `func` and all `break`s (and other escaping control flow) are converted into a `return false`. It's just three levels of procedures deep, which again feels like a functional language rather than an imperative language.


**NOTE:** that I am not suggesting they replace the iterator design with what I am suggesting, but rather a generalized iterator approach may have not been a good thing Go in the first place. For me at least, Go is an unapologetic imperative language with first-class CSP-like constructs. It's not trying to be a functional-like language. Iterators are in that weird place where they do exist in imperative languages, but they are very "functionally" as a concept. Iterators can be very _elegant_ in functional languages, but in some many unabashed imperative languages, they always feel "weird" somehow __because__ they are being unified into a separate construct rather than separating out the parts of it (initialize+iterator+destroy).

## Aside: Odin's Approach

As I alluded to previously, in Odin an iterator is just a procedure call where the last value of the multiple return is just a boolean indicating whether to continue or not. And because Odin does not support closures, the equivalent Go `Backward` iterator in Odin is a little more code to type.

__**NOTE:** Before people say "that looks even more complex", please continue reading the article. Most Odin iterators are not like this, and I would never recommend writing such an iterator where a trivial for-loop would be preferred for both the reader and the writer of the code.__


```odin
// Explicit struct for the state
Backward_Iterator :: struct($E: typeid) {
	slice: []E,
	idx:   int,
}

// Explicit construction for the iterator
backward_make :: proc(s: []$E) -> Backward_Iterator(E) {
	return {slice = s, idx = len(s)-1}
}

backward_iterate :: proc(it: ^Backward_Iterator($E)) -> (elem: E, idx: int, ok: bool) {
	if it.idx >= 0 {
		elem, idx, ok = it.slice[it.idx], it.idx, true
		it.idx -= 1
	}
	return
}


s := []string{"a", "b", "c"}
it := backward_make(s)
for el, _ in backward_iterate(&it) { // `for el in` could have been written too
	fmt.print(el, " ")
}
// c b a
```

This does _appear to be_ a lot more complicated that the Go approach because it requires you to write a lot more code. However, it's actually a hell of a lot simpler to understand, comprehend, and even faster to execute. The iterator does not call the for-loop's body, rather the body calls the iterator. I know Cox loves the ability of [Storing Data in Control Flow](https://research.swtch.com/pcdata), and I do agree it is nice but does not fit well within Odin, especially with the lack of closures (because Odin is a manual memory managed language).

An "iterator" is just syntactic sugar for the following:
```odin
for {
	el, _, ok := backward_iterate(&it)
	if !ok {
		break
	}
	fmt.print(el, " ")
}

// With `or_break`

for {
	el, _ := backward_iterate(&it) or_break
	fmt.print(el, " ")
}
```

Odin's approach is just removing the magic and making it extremely clear what is going on. "Construction" and "destruction" must be handled manually with explicit procedures. And that iteration is just a simple procedure which is called each loop. All three constructs are handled separately rather merged into one confusing one like in Go 1.23.

Odin does not hide the magic, whilst Go's approach is actually very magical. Odin makes you handle the "closure-like" values manually along with the construction and destruction of the "iterator" itself.

Odin's approach also trivially allows you to have as many multiple return values as wanted too! A good example of this is Odin's `core:encoding/csv` package where the `Reader` can be treated like an iterator:

```odin
// core:encoding/csv
iterator_next :: proc(r: ^Reader) -> (record: []string, idx: int, err: Error, more: bool) {...}
```
```odin
// User code
for record, idx, err in csv.iterator_next(&reader) {
	...
}
```

## Aside: C++ Iterators

I will try to not get into a huge rant about C++ "iterators" in this article. C++ iterators are much more than _mere iterators_ whilst at least Go's approach is still a _mere iterator_. I completely understand why C++ "iterators" do what they do, but 99.99% of the time I just want a _mere iterator_; not something that has all of the algebraic properties that allow it to be utilized in more "general" places.

For people who don't know C++ very well, an iterator is a custom `struct`/`class` which requires it to have overloaded `operators` on it to make it act like a "pointer". Historically, a C++ "iterator" would look like this:

```cpp
{
	auto && __range = range-expression ;
	auto __begin = begin-expr ;
	auto __end = end-expr ;
	for ( ; __begin != __end; ++__begin) {
		range-declaration = *__begin;
		loop-statement
	}
}
```
And would be wrapped in a "macro" before C++11 ranged-for loop syntax (and `auto`) became a thing.

The biggest issue is that C++ "iterators" require you to define 5 different operations at a minimum.

The following three operator overloads:

* `operator==` or `operator!=`
* `operator++`
* `operator*`

Along with two stand-alone procedures or bound methods which return an iterator value:

* `begin`
* `end`

If I was to design C++ _mere iterators_, I would have just add a simple method to a `struct`/`class` called `iterator_next` or something. And that's it. Yes it does mean the other algebraic properties are lost, but I honestly do not need these EVER for any problem I am working on. When I am working on those kinds of problems, they will always be either a contiguous array, or I will implement the algorithm manually because I want to guarantee the performance will be good for that data-structure. However, there is a reason I made my own language (Odin) because I completely disagree with the entire C++ philosophy, and I want to get away from that madness.

C++ "iterators" are a hell of a lot more complicated than Go's iterators but they are much more "direct" with the local operation. At least with Go, you don't need to construct a type with 5 different properties rather


## In Conclusion

I feel like Go's iterators do make sense with the design principles applied to them **BUT** _seem_ antithetical to what most people view Go as being. I know Go "has had to" get more complex over the years, especially with the introduction of Generics (which I do think are actually well designed, with only a few syntax quibbles), but the introduction of iterators of this ilk _feels_ wrong.

I think the short of it is that it feels like it goes against the apparent philosophy of Go that many people believe, coupled with it being a very functional way of doing things rather than imperative.

And because of those reasons, I think that is why people don't like the iterator stuff, even if I completely understand the design choices made. It doesn't "feel" like what Go original was to many people.

Maybe the concerns of mine (and others) are overblown and most people will never actually implement them and just use them, and that them being this complicated to implement.

Second to last controversial take: Maybe Go needed to "gate-keep" even more and just tell the "functional-bros" to go away and stop asking for such features which make Go a much more complicated and complex language.

Last controversial take: if it was me, I would just not have allowed custom iterators into Go whatsoever, but I am not on the Go team (nor do I want to be).