---
{
    "title": "Does Syntax Matter?",
    "slug": "does-syntax-matter",
    "author": "Ginger Bill",
    "date": "2026-02-21",
    "categories": [
        "programming language theory",
        "programming language design",
    ],
}
---

<span style="font-size:2em; font-weight: bold;">Yes.</span>

But not necessarily in the ways you might think[^note-length].

[^note-length]: n.b. This article could have been a lot longer than it currently is.

## Concrete and Abstract Syntaxes

In the previous article, [Choosing a Language Based on its Syntax?](https://www.gingerbill.org/article/2026/02/19/choosing-a-language-based-on-syntax/), I talked about how many people will not pick up a language purely based on its declaration syntax not being familiar to them or the usage of semicolons or more.

There were many lovely comments about the article, but some readers wrongly interpreted the article to mean that I don't care about concrete syntax and only focus on the abstract syntax. This is far from the truth and I have spent an inordinate amount of time designing Odin's _concrete_ syntax to be as best as it can be. From the littlest of things to the general idea of the concrete syntax is very important to me since this directly influences how the programmer interacts with the code and influences how they even write it.


When people talk about concrete syntax, they are referring to the specific structure and rules of a programming language's grammar as it appears to the programmer, including keywords, punctuation, and general layout. Whilst the abstract syntax represents the underlying structure of the code, focusing on the essential elements without the superficial details. This is what the parser will generate through an abstract syntax tree (AST), and then process over that.

Part of the point about declaration syntaxes is that for the most part, the abstract syntax will be mostly the same and not influence the semantics too much. However I was trying my best to focus on just one aspect of a language's syntax, not the entirety of it.

Odin's choice of name-focused declaration syntax was not a _mere_ aesthetic choice either. It was about unifying different semantic concepts together. `:=` is for the declaration of runtime variables and `::` is for the declaration of compile time constants[^inferred-type]. But general compile time constant values, types, and procedure values are at the end of the day just constant expressions. They are unified under the same syntax `::`.

[^inferred-type]: Both with inferred types since `:` and `=` are separate operators to begin with so `:    =` or `:    :` could be written.


This would mean it is the equivalent in qualifier-focused declaration syntax of having `var x = EXPR` and `const y = EXPR`, and not having `type` or `proc` distinction but for Odin, we wanted to keep the simplicity of this specific name-focused syntax and consistency of grep-ability for `:=` and `::`.

## Coherence and Consistency

People often criticize a language's syntax for not being "minimal" or "simple" enough. They tend to evaluate individual features in isolation, suggesting tweaks without regard for how those changes align (or conflict) with the rest of the language's design. Coherence means the syntax expresses ideas with logical clarity and conceptual flow. Consistency means applying the same style, rules, and tone uniformly across the entire language.

When I design languages (not just Odin), I always strive for both coherence and consistency in syntax and semantics. When the two cannot be fully reconciled, I choose coherence over consistency every time. A language that is conceptually clear and logically sound is far more valuable than one that is merely consistent yet lacks underlying coherence. Consistency helps programmers predict and extrapolate behaviour, but only when it rests on a foundation of genuine coherence.

A language's syntax can be very consistent but the entire logic that it represents is incoherent. The two concepts are separable ideas even if many people use the terms interchangeably. To use an example from C:
```c
int do_foo(Foo *ptr, size_t length);
// vs
int do_foo(Foo *ptr);
```

Both instances of `Foo *ptr` would translate to `ptr: ^Foo` in older versions of Odin. That is consistent, but it doesn't tell us if `ptr` points to a single `Foo`, or to an array terminated by some sentinel value. For this reason we added `[^]` to tell the reader to expect a pointer to multiple elements (`0+`) of `Foo`, not a singular value. This is less consistent[^no-inconsistent-ish], and yet more coherent.

[^no-inconsistent-ish]: It isn't necessarily inconsistent to a new data type, but the semantics that go along with [multi-pointers](https://odin-lang.org/docs/overview/#multi-pointers) might _seem_ "inconsistent" depending on how you view them.

## Syntactic Diabetes

It is common for people to ask for new syntactic sugar to "sweeten" the language so that they express something more concisely. In small amounts, a bit of syntactic sugar can be fine, but those same people have a tendency to over do things, and it very quickly leads to what I have called for many years _syntactic diabetes_.

C has a few instances of sugar such as `a[3]` being a equivalent[^c-index-trick] to `*(a + 3)` and `x->y` being equivalent to `(*x).y`, but these are very good cases of "sugar" since they do simplify and make the syntax easier to read in a concise manner. C macros can cause a lot of syntactic diabetes when abused.

[^c-index-trick]: Which leads to lovely "trick" of `3[a]`.

However some other languages have so much sugar that I'd argue is not useful in the slightest. `unless` is a construct in languages such as Perl which is syntactic sugar for the negation of an `if` statement:

```perl
unless (condition) {...}
```
being equivalent to
```perl
if (not condition) {...}
```

Swift has a similar construct with `guard condition else { ... }`. I completely understand the intent behind why such a construct is desirable but for my taste, it is completely redundant when you can just use an `if` statement, or even restructure the code such that it is not a negation of the `if` either.

These things in isolation do not lead to _syntactic diabetes_, but rather when a plethora of decisions like this add up.


## Scannability vs Readability

Many people say they value _readability_ in a programming language, however I've found that this term is extremely overloaded and does not mean the same thing across people.

There are some languages out there that I find very dense and hard to read at a glance, but many people will call such languages "readable" still. I believe this disagreement is not due to familiarity but down two different interpretations of the word _readable_: scannability and readability.

Languages with a heavy dense syntax are not easy to _scan_. By scannability, I mean how easily a reader can quickly locate specific information within the code/text, often by looking for obvious keywords or patterns. Readability, on the other hand, is more of a measure of how easily a reader can understand the content with a detailed inspection.

I rarely read code token-by-token from the start. Most of the time I first _scan_ a codebase to get the overall shape and locate the parts I care about, then have a deep detailed read, only where necessary. Dense-syntax languages[^dense-languages] usually lack many of the strong visual cues and landmarks that other languages possess, especially those that I would typically rely on for that initial _scan_, I often find it slow and tiring to navigate such code.

[^dense-languages]: There are quite a few languages I find to have very dense syntax, but not necessarily languages I dislike. Here is an incomplete list in alphabetical order: APL, (Modern) C++, Haskell, Perl, Rust macros, Swift, Zig. All of these languages are not easy to _scan_ in real life code, but _intensely reading_ them might not necessary be bad.


Languages with a soup of sigils and unusual operators actively hurt scannability. When scanning/skimming, my eyes have almost no reliable landmarks to latch onto: function calls, type conversions, error handling, and even regular arithmetic might all look disturbingly similar at a glance. This makes it much harder to quickly answer certain questions because of all of this noise.

I genuinely don't understand how people defend this from an aesthetic or practical standpoint unless their mental model of "reading code" is exclusively the slow, line-by-line, token-by-token style. For anyone who relies on fast visual scanning (which is most working programmers, most of the time), languages with very dense syntax feel like a significant step backward for day-to-day programming.

I've tried my best for Odin to be a very _scannable_ language along with being a very _readable_ language too, with the syntax clearly reflecting its semantics.


## Staying With Familiarity or Breaking Away?

Related to the [previous article](https://www.gingerbill.org/article/2026/02/19/choosing-a-language-based-on-syntax/), Odin's named-focused declaration syntax is unfamiliar, but the reason I chose it was not a mere aesthetic choice but rather it has massive syntactic and semantic reasons behind it.

A lot of people treat familiarity as a self-sufficient argument, when in reality it is _at best_ a tie-breaker. Many languages in the past usually opted for familiarity instead of trying to improve the design of a feature or construct. Usually as a misguided attempt to keep the language being perceived as being overly complicated.

A good example of something that should be not emulated is C's operator precedence rules. C's operator precedence rules have caused numerous bugs over the years to the point that people instinctually guard against them by putting loads of parentheses around them. For Odin, I tried to simplify the entire set so that there is only one level for prefix unary operators, and merge many of the levels for binary operators. I took inspiration from languages like Go along with numerous experiments to see what felt better for myself and others.

### Using `<>` for Generics is Harmful

Another is people coming from a language like C++ wanting to use `<>` for generics. There are always better alternatives to use than `<>`, but people request it in languages[^not-odin-generics] purely because of familiarity. `<>` is probably one of the worst options to use because it's both hard for humans to read and hard for compilers to parse. This is because `<` and `>` are used as binary operators for comparisons and bit-shifts (`<<` and `>>`). The only reason `<>` appears to be used is because the meanings behind `()`, `{}`, and `[]` already have meaning, which leads to people thinking `<>` is the only options.

[^not-odin-generics]: Not Odin, because it has a different approach to generics with its form of parametric polymorphism being _inline_ rather than a separate description.

However `<` and `>` are the worst, because they require at worst a symbol table to disambiguate how they are used, or at best a crazy grammar to workaround the possible problems. Java is an example that tried to approach this by making the syntax less consistent as it is still "mostly" a context-free grammar. C# tried to make the syntax more consistent, but required an infinite look-ahead to parse by looking ahead at `<` until it can figure out how it was meant to be used.

But why people want it is mostly coming from C++, and the numerous amount of issues that `<>` ensues. It took decades before the C++ committee allowed `A<B<C>>` to be used in a template and not having to require a space between the symbols to remove an ambiguity `A<B<C> >`.

Rust's approach is a little ugly, since it uses `::<>` to remove the ambiguity, but it still means that you cannot use general expressions between the `<>` (e.g. no binary expressions that contain `<` or `>`).

Odin decided upon using `()` for generics because it's just part of the procedure signature itself:

```odin
my_new :: proc($T: typeid, allocator: runtime.Allocator) -> ^T {
    ptr, err := mem.alloc(size_of(T), align_of(T), allocator)
    assert(err == nil)
    return (^T)(ptr)
}

// the "template" parameters are part of the procedure signature directly
ptr := my_new(int, my_allocator)
```

Odin does not separate the parametric polymorphic[^parapoly] parameters into a template list, unlike in C++. The `$` signifies what is to be determined at compile time. One of the reasons this was done was to prevent for partially evaluated template-like constructs in the language or overridden templates. I wanted the "generics" system to be simpler than a lot of languages, because I have found people do a lot of crazy things with generics.

[^parapoly]: In the Odin community, parametric polymorphism is typically shortened to "parapoly" rather than use the word "generics", since that is too "generic".

Odin does try to be consistent with its syntax here by applying that input list to other record types (`struct`s and tagged `union`s):

```odin
My_Array :: struct($N: uint, $T: typeid) {
    internal_array: [N]T,
}

x: My_Array(1024, u8)

// this literally how `Maybe` is defined in Odin
Maybe :: union($T: typeid) { T }

y: Maybe(int)
z: Maybe(^f32) // a `nil` pointer signifies a `nil` Maybe too
```

Unfortunately as a choice of this syntax choice, it does have the compromise that casting syntax requires parentheses to disambiguate what is needed. `int(x)` is a trivial form of a type conversion in Odin, but when applying it to something "generic"/parapoly, it requires wrapping to remove the ambiguity in type checking:

```odin
(Foo(T))(expr)
(^Foo(T))(expr)
// vs
^Foo(T)(expr) // this could be interpreted as a pointer to `Foo(T)(expr)`
```




## Syntax Restricts the Possibilities of Semantics

> The choice of the littlest difference between `,` and `;` makes all the difference in the world.

One of Odin's general philosophies is to keep hierarchies flat as possible, and to not encourage people to make needless taxonomies with their code. Most people think they are organizing code, when in reality they are just taxonomizing it---it does not give you any real benefit. The design of Odin's record types like `struct`s are an extension of this.

In Odin, struct fields are separated by a comma rather than a semicolon/newline. This decision might seem _very minor_ but the decision was to prevent something I did not want to allow in the syntax at all: nested declarations. Nested declarations naturally lead to people wanting to create hierarchies of declarations; usually as a way to taxonomize things.

Normal Odin looks like this:

```odin
// Actual Odin syntax using commas to separate fields
Foo :: struct {
    x:    int,
    y:    string,
    z, w: bool, // trailing commas are optional
}
```

The commas here are "field" separators, and in fact share identical syntax/parsing to procedure parameters too. However this is what people would intuitively expect if they wanted semicolons/newlines:
```odin
// Not Odin and with explicit semicolons
Foo :: struct {
    x:    int;
    y:    string;
    z, w: bool;
}
```

When using semicolons (or just newlines), the fields now look _exactly_ like declarations in the rest of the language. It would allow people to copy-and-paste declarations so that they can be wrapped in a struct, but it signifies that a struct is a bundle of "declarations", rather than just a list of "fields".

Because `name: T;` looks like variable declaration, it leads to allowing other kinds of declarations within a struct, especially constants.

```odin
// Not Odin
Foo :: struct {
    MY_CONSTANT :: 123;
    Node :: struct {
        Another_Type :: int;

        next:  ^Foo;
        value: Another_Type;
    };

    x:    int;
    y:    string = "hellope"; // default values
    z, w: [MY_CONSTANT]bool;
    root: Node;
}
```

This might seem harmless or even useful, but it was fundamentally something I wanted to prevent from my experience in other languages. I wanted to prevent this mess of nested declarations causing numerous problems. I've seen really deep taxonomies that don't even benefit their creators

This also leads to the question of what happens if you allow a procedure declaration within a `struct`?

```odin
// Not Odin
Foo :: struct {
    bar :: proc() {
        ...
    };


    x: int;
    y: string;
}
```

Is this nested procedure now a method of `Foo` (member function) or is it just nested within the namespace (static member function)? Or could it be both depending on the inferred usage?

For Odin, I wanted it to be a strictly imperative procedural language with no direct methods. I do not have anything against methods themselves, rather Odin is a C alternative after all and I wanted to keep that procedural nature[^why-no-methods]. If I was to design a language with methods, I would not want _mere methods_ which associate a procedure/function with a data type, but probably a full implicit type class system (similar to how generics now work in Go or traits in Rust).

[^why-no-methods]: If you want to read more about why Odin does not have any methods, I recommend reading the [FAQ's section](https://odin-lang.org/docs/faq/#but-really-why-does-odin-not-have-any-methods).

You could have fields which are separated by `,`, and then also allow for nested declarations which are terminated with `;`/`\n`, but I'd argue this is incoherent (yet still "consistent") as a language design because the declaration syntax of Odin itself doesn't really allow for it, by design. And with Odin, I've tried to keep its concrete syntax both consistent and coherent.

The littlest of things matter because they can lead to massive consequences in the future.

> All of this possiblity from just deciding between using a `,` vs `;`.


## There are no Solutions, Only Trade-Offs

There are numerous cases of language design decisions I have made which even I - as the creator of the language - do not like. Most of these fit into one of two categories:

* Multiple ways of doing the same thing, which exist for pragmatic reasons
* Overloaded concepts, that exist because of what people expect

### Multiple Ways to do the Same Thing

One of the first things in Odin that people will encounter is the two different syntaxes to perform type conversions:

```odin
cast(type)value
type(value) or (type)(value)
```

As much I dislike there are two different ways to do this, one of the approaches might _feel_ better than the other case. If you are converting a large expression, it is sometimes a lot easier to use the operator-style approach, `cast(type)`. The call syntax is commonly used to specify a type of an expression which may be relatively short, such as `u32(123)` or `uintptr(ptr)`.

But another reason is to be consistent with the other operator-like type conversion operators: [`transmute`](https://odin-lang.org/docs/overview/#type-conversion) and [`auto_cast`](https://odin-lang.org/docs/overview/#auto-cast-operation). If I wanted to aim for _consistency_ for all of the casts, I would have added a built-in procedure, which would have been:

```odin
cast(type, value)
transmute(type, value)
auto_cast(value)
```

But because of both what people expect from other languages, and how common casting can be, doing these style of casts everywhere would become both tiresome read to and write.

### Overloaded Concepts

Odin has many familiar control flow statements that people from C-like languages are familiar with: `if`, `switch`, `for`, and `defer`. Compared to C and C++, `if` and `switch` are heavily improved in terms of both their syntax and semantics, but the most-overloaded statement `for`. It is effectively two kinds of loops in one: a C-style `for` loop and a for-each loop.

Due to what people expect from other languages, I decided to merge the concepts, even if that means the syntax isn't that easy to parse any more.

The C-style `for` loop is like this:
```odin
for i := 0; i < 10; i += 1 {
    fmt.println(i)
}
```

**Note:** Unlike other languages like C, there are no parentheses `( )` surrounding the three components[^parentheses-decision]. Braces `{ }` or a do are always required.

[^parentheses-decision]: This decision to remove the need for parentheses has its own compromises too that conflict with compound literals, and thus requires either adding parentheses again, or carefully using compound literals not in control flow statements.

```odin
for i := 0; i < 10; i += 1 { }
for i := 0; i < 10; i += 1 do single_statement()
```

The initial and post statements are optional:
```odin
i := 0
for ; i < 10; {
    i += 1
}
```

These semicolons can be dropped. This `for` loop is equivalent to C’s `while` loop:
```odin
i := 0
for i < 10 {
    i += 1
}
```

If the condition is omitted, this produces an infinite loop:
```odin
for {
}
```

All of this is familiar to C programmers, but the overloading aspect is how the same keyword (`for`) can now be used to refer to range-based loops. For example the basic `for` loop:

```odin
for i := 0; i < 10; i += 1 {
    fmt.println(i)
}
```
can now be written as:
```odin
for i in 0..<10 {
    fmt.println(i)
}
// or
for i in 0..=9 {
    fmt.println(i)
}
```

Where `a..=b` denotes `a` closed interval `[a,b]`, i.e. the upper limit is inclusive, and `a..<b` denotes a half-open interval `[a,b)`, i.e. the upper limit is exclusive. Certain built-in types can be iterated over.

```odin
some_string := "Hello, 世界"
for character in some_string {
    fmt.println(character)
}

some_array := [3]int{1, 4, 9}
for value, index in some_array {
    fmt.println(value, index)
}

// etc
```

The problem is that these concepts are fundamentally different and overload `for` too much. If I wanted to separate them, this ranged based `for` loop would use something like a `for_each` keyword[^odin-done], but because people naturally want the `for x in y` style, I just decided to break the _consistency_ of separation of concepts, and kept to _coherency_ of expectations and programmer intuition.

[^odin-done]: Odin is not changing its syntax to add a `for_each` keyword. Odin as a language is effectively done and been for quite some time.



## Odin's Procedure Signature Syntax

Due to C's "declaration matches usage" syntax, as I have written about in previous articles, C's procedure/function syntax is quite a bit difficult to write unless you know exactly how to do things. When designing Odin's procedure signature syntax, it took me a little bit of work, as I wanted it to be consistent and coherent with the rest of the language, whilst also having the maximal amount of possibilities. I did not want to make the same mistakes as C.

The following is a general table of possibilities that could be chosen when designing a name-focused signature syntax.

Three things should be noted as to why some fields are "blank":

* No significant whitespace
* Keep the property that `(T) == T` where parentheses are just used for grouping expressions and have no extra semantic meaning
* `->` is used to disambiguate between the return values and a "call" expression
  * e.g. `(foo) (x)` would be a call expression, not a procedure definition as I do not want significant whitespace, and when `proc` is not used as prefix

<table>
<thead>
<tr>
<th></th>
<th>Prefix/Odin</th>
<th>Require Return Type</th>
<th>Return Named Inputs</th>
</tr>
</thead>
<tbody>
<tr>
<td>Empty Procedure</td>
<td><code>proc()</code></td>
<td><code>() -&gt; void</code></td>
<td><code>()</code></td>
</tr>
<tr>
<td>1 input, unnamed</td>
<td><code>proc(int)</code></td>
<td><code>(int) -&gt; void</code></td>
<td></td>
</tr>
<tr>
<td>1 input, named</td>
<td><code>proc(x: int)</code></td>
<td><code>(x: int) -&gt; void</code></td>
<td><code>(x: int)</code></td>
</tr>
<tr>
<td>1 input, 1 output</td>
<td><code>proc(int) -&gt; int</code></td>
<td><code>(x: int) -&gt; int</code></td>
<td><code>(x: int) -&gt; int</code></td>
</tr>
<tr>
<td>2 inputs, 2 unnamed outputs</td>
<td><code>proc(int, int) -&gt; (int, int)</code></td>
<td><code>(int, int) -&gt; (int, int)</code></td>
<td><code>(x: int, y: int) -&gt; (int, int)</code></td>
</tr>
<tr>
<td>0 inputs, 2 named outputs</td>
<td><code>proc() -&gt; (a: int, b: int)</code></td>
<td><code>() -&gt; (a: int, b: int)</code></td>
<td></td>
</tr>
<tr>
<td>2 inputs, 2 outputs, all named</td>
<td><code>proc(a, b: int) -&gt; (c, d: int)</code></td>
<td><code>(a, b: int) -&gt; (c, d: int)</code></td>
<td></td>
</tr>
</tbody>
</table>

Prefix/Odin Style:

* Advantages: Allows for any approach and any style of a procedure signature
* Disadvantages: Requires an extra keyword or sigil

Require Return Type Style:

* Advantages: Allows for most approaches of a procedure signature
* Disadvantages: Requires the concept of `void` (or 0-tuple) in the language

Return Named Inputs:

* Advantages: Does not require the concept of `void` in the language, allows for the return value to be omitted
* Disadvantages: It's worse than the other two styles in every other way

I made a gist of this a while ago with a list of examples where an ambiguity can arise depending on which approach is used:

<https://gist.github.com/gingerBill/27aec0cd434f2be58d024dccef6e8d13>

One of the other reasons to prefer using a `proc` prefix is to be consistent with the other data types within the language. Things like `struct`, `union`, `enum`, `bit_set`, and `bit_field` all start with a keyword to signify, so why should a procedure be treated any differently? Keeping `proc` maintains the coherency of Odin's syntax, and allows people to easily "grep" things and understand the general flow.

```odin
Some_Struct    :: struct      { ... }
Some_Union     :: union       { ... }
Some_Enum      :: enum        { ... }
Some_Bit_Field :: bit_field T { ... }
Some_Bit_Set   :: bit_set[T]
Some_Proc      :: proc()
```

If procedures had no `proc` prefix, there would be an inconsistency across those kinds of data types[^pascal-arrays].

[^pascal-arrays]: I did not want to go full Pascal-like with `array N of T` and `pointer of T` prefixes when `[N]T` and `^T`, respectively, are just as easy to understand.


As I found out when designing Odin, a lot of people struggle to see punctuation and much prefer keywords, and also the other way around. Sadly I cannot please everyone, but I've tried to keep a nice middle ground between the two. Not to lean too heavily into keywords like a traditional Pascal-like, or too punctuation-heavy like many ML-like languages.


### A Subtle Issue with Type-Focused Signature Syntax

This might not seem like a huge issue, but it syntax restricts semantics here. If you want C-style type-focused syntax for procedures, you cannot necessarily define the syntax to return the procedure type itself. This can be quite useful for certain state-machine like problems.

In Odin's syntax, this is pretty simple to do:
```odin
State_Proc :: proc(s: ^State) -> State_Proc

for sp: State_Proc = ...; sp != nil; sp = sp(s) {
    ...
}
```

and the equivalent in C would be this:
```c
typedef void *State_Proc(State *s);

for (State_Proc *sp = ...; sp != NULL; sp = (State_Proc *)sp(s)) {
    ...
}
```


## Auto Dereferencing for Convenience

When programming in C and C++, the programmer must know whether a field is a value, or accessed through a pointer. `x.y` implies that `x` is not a pointer whilst `x->y` means `x` is a pointer[^field-shorthand]. However when programming, this distinction can get quite annoying when refactoring code between values and pointers. The compiler even knows this and gives error messages depending on which mistake was made.

[^field-shorthand]: Where `x->y` is just shorthand for `(*x).y` in C/C++.

For Odin, I decided to just infer the dereference and make it more convenient. `x^.y` is equivalent of C's `x->y` but because of the auto-dereferencing, the programmer can just type `x.y` if `x` is a pointer. For further levels of indirection, e.g. `^^^T`, explicit dereferencing will still be required.

## Things Which Appear to be Inconsistent at First

I've sometimes had people ask why slice expressions use `:` instead of the range syntax (`..<` and `..=`) that already exists in Odin. It might seem like an "oversight", but there are specific reasons the syntax was chosen.

* It is the same syntax as Go and Python, making it familiar to others who are used to those languages. Another example of leaning into the familiarity bias.
* It aesthetically allows for partial ranges
  * `x[:]`, `x[:n]`, `x[i:]`
* Partial ranges with _two_ range expressions (`a..<b` and `a..=b`) are aesthetically unpleasant, as well as inconsistent.
  * `x[..<]`, `x[..=]`, `x[..<n]`, `x[..=n]`, `x[i..<]`, `x[i..=]`,
* Virtually all slicing cases only ever require the Python/Go like semantics because Odin is a 0-index language. `..=` style ranges are useless, if not error prone.
* Ranges in Odin are only allowed in [a limited number of specific contexts](https://odin-lang.org/docs/overview/#other-operators), namely range-based `for` loops, `switch` `case`s, `bit_set` definitions, and compound literals.

Even though some people would allow the concept of a range to work _everywhere_, they are implicitly adding another rule/axiom to the design to unify this concept, which would not benefit the programmer much in practice (and probably be error prone).

An inconsistency here would only happen if they were the exact same idea, rather that they _could_ be unified. And since they are separate ideas, there is no inconsistency.

## Testing Hypotheses

Odin has multiple return values as a core feature of the language. A large use case of multiple return values (not the sole case) is to return an error code/value as one of the values[^result-type].

[^result-type]: Please don't bring up `Result` types, Odin is not that kind of language and they would not necessarily be as pragmatically useful as you'd think, nor would they work in the way you'd expect given the other semantics of the Odin language.

Sometimes it is useful to propagate error values within a library by early returning if that value was `false` or not `nil`. This is a similar vein to Rust's `try!` which became `?`, or Zig's `try`, etc. What came of this in Odin was the `or_return` operator and the other related keywords (`or_break`, `or_continue`, and `or_else`).

### The Problem and Hypothesis

The hypothesis was that this idiom was common:
```odin
x, err := foo()
if err != nil {
    return err
}
```

Where `err` may be an `enum`, a (discriminated/tagged) `union`, or any other kind of value that can be `nil`. I originally experimented with replacing this pattern with the following syntax:

```odin
// Not Odin any more
x := try foo()
y := try foo() else 123 // default value
```

This construct solves a very specific kind of error handling, of which optimizes for typing code rather than reading code. The experiment also had a way to give a default value on the case of an "error": `try x else y`.

When this was experimented with, there were three things that were confusing which made it look like a failure of an experiment:

* `try` was a confusing name for what the semantics were.
* `try` as a prefix was the wrong place
* Trying to using `try` with `try else` was a bad idea for many reasons.

The concept of `try` worked[^or_return_semantics] by popping off the end value in a multiple valued expression and checking whether it was `nil` or `false`, and if so, setting the end return value to value if possible. If the procedure only had one return value, it did a simple return. If the procedure had multiple return values, `try` required that they were all named so that the end value could be assigned to by name and then an empty return could be called. Now `try` has been replaced with the suffix operator `or_return`.

[^or_return_semantics]: `or_return` works exactly the same, and that was the final language construct.

However I found that the problem wasn't the semantics of the construct, but rather the syntax itself. First I added a new binary operator `or_else` which replaced the `try else` syntax. Most people understood what the purpose and semantics `or_else` pretty intuitively but many were very confused regarding the semantics of `try`. My conclusion was that the keyword-name and positioning were the main culprits for that. This let me to replace the prefix `try` with a suffix `or_return`[^or_return_more_detail]. This resulted in the following:

[^or_return_more_detail]: If you would like to read more about this, I wrote about this at the time: <https://www.gingerbill.org/article/2021/09/06/value-propagation-experiment-part-2/>

```odin
x := foo() or_return
y := foo() or_else 123
```

Another aspect which of this approach was that I thought the construct was probably not as common as I originally thought. And for my codebases (including most of Odin's core library), this was true. However this hypothesis was false for many codebases, including package [`core:math/big`](https://github.com/odin-lang/Odin/tree/master/core/math/big). In the package [`core:math/big`](https://github.com/odin-lang/Odin/tree/master/core/math/big) alone, `or_return` was able to replace 350+ instances of `if err != nil { return }` idioms.

What we found was that the more C-like a library was in terms of its design, the more it required this `or_return` construct. It appears that when a package needs it, it _REALLY_ needs it. When the correction was made, those 350+ instances of `or_return` in a (at the time) ~3900 LOC is ~9% of (non-blank) lines of code. That's a useful construct for definite.

### Degenerate States

Some people may be a little surprised with my original experimentation with this exception-like shorthand with error values. Especially since I wrote an article (which was originally two GitHub comments) titled: [Exceptions—And Why Odin Will Never Have Them](https://www.gingerbill.org/article/2018/09/05/exceptions---and-why-odin-will-never-have-them/).

One thing I did not comment on in the that article is the cause of the problem (other than the cultural issues). My hypothesis is that if you have a degenerate type (type erasure or automatic inference), then if a value can convert to it implicitly (easily), people will (ab)use it.

In languages with exceptions, all exception values can degenerate to the “base type”. In Rust, it can either go to the base `trait` or be inferred parametrically. In Zig it can either do `anyerror` or it will infer the error set from usage. Go has the built-in interface type `error` which acts as the common degenerate value.

As I discuss in that [article](https://www.gingerbill.org/article/2018/09/05/exceptions---and-why-odin-will-never-have-them/), I am not against error value propagation _within a library_, but I am pretty much always against it across library boundaries. A degenerate state has high entropy and a lack of specific information. And due to this form of type erasure, “downcasting” (broad use of term) is a way to recover the information, but it assumes implicit information which is not known in the type system itself.

The other issue when people pass the error up the stack for someone else to handle (something I criticize in the previous article already) is that it’s common to see this in many codebases already that have such a type: Go, Rust, and Zig (public) codebases exhibit this a lot.

And my hypothesis for this phenomenon is due to the very nature of this “degenerative type”.

Design judgement had to be made when designing a language: is such a concept worth it for the problems it intrinsically has; for Odin, I did not think it was worth it. In Odin, errors are just values, and not something special. For other languages? That’s another thing. For Odin, I have found that having an error value type defined per package is absolutely fine (and ergonomic too), and minimizes, but cannot remove, the problem value propagation across library boundaries.

I do believe that my general hypotheses are still correct regarding exception-like error value handling. The main points being:

* Error value propagation _ACROSS_ library boundaries[^pokemon-catching]
* _Degenerate states_ due to type erasure or automatic inference
* Cultural lack of partial success states

[^pokemon-catching]: People are lazy and have a tendency to never actually handle errors so having a degenerate state for errors usually causes the errors to "bubble up" so you can "Catch 'em All" in one place---Pokémon error handling.

The most important one is the degenerate state issue, where all values can degenerate to a single type. It appears that you and many others pretty much only want to know if there was an error value or not and then pass that up the stack, writing your code as if it was purely the happy path and then handling any error value. Contrasting with Go, Go a built-in concept of an `error` interface, and all `error` values degenerate to this interface. In practice from what I have seen of many Go programmers, most people just don’t handle error values and just pass them up the stack to a very high place and then pretty much handle any error state as they are all the same degenerate value: “error or not”. This is now equivalent to a fancy boolean.

### The Choice of Syntax

The language constructs `or_return` etc were one of those things where the semantics (denotational and operational) were completely obvious but how to represent that in _concrete_ syntax was the problem. And what I expected to be what people would like (i.e. `try`) turned out to be confusing in both what the language semantics were for that syntax, and noisy reading the prefix.

If you are designing a language in isolation without consulting others, you will not know what mental biases you have with regards to that syntax. Since you are the creator, everything is "obvious", but other people think different to you. Sometimes you can just model most people's minds yourself but sometimes you actually have to test it in the real world, and the results can be surprising.


## Conclusion

Designing a language is more than just getting the syntax right, and denotation semantics are a lot more important in most ways, but that does not mean syntax does not matter. When you get syntax right, people won't even know you've done anything at all. But when you've got it wrong (and have actually tried using the language), they will complain instantly.