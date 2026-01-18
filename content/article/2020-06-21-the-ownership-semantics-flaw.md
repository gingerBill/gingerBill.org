---
{
    "title": "The Fatal Flaw of Ownership Semantics",
    "slug": "the-ownership-semantics-flaw",
    "author": "Ginger Bill",
    "date": "2020-06-21",
    "categories": [
        "philosophy",
        "psychology",
        "ontology",
        "programming philosophy",
        "programming languages"
    ],
    "tags": [
        "philosophy",
        "psychology",
        "rust",
        "c++11"
    ]
}
---

I have been toying with a theoretical idea for the past 18 months off-and-on in my head and I have not fully articulated it aloud yet. It is regarding the concept of _Ownership Semantics_ (OS) or _Move Semantics_ in programming languages. Fundamentally this article is a criticism of the concept and states that the concept is a duality of traditional OOP but applied to a different area.

## General Definitions of Terminology

A general list of definitions of terminology used within this article in order to minimize confusion.

* A _Value_ is a datum with an associated type
* A _(Data) Type_ is an attribute of a value which encodes information about how the data value can be operated upon
* An _Object_ is a value with associated behaviour, and thus implies it has _agency_
* A _Class_ is the data type of an _Object_
* A hierarchy of value ownership is a hierarchy of responsibility of values
* An _Owned-Value_ is a value which belongs to a hierarchy of value ownership, which implies it is governed by an _agent_
* An _Agent_ is an actor with the capacity to act within a given environment
* A _Model of Interpretation_ is a way to view and analyse a subject
* A _Paradigm_ is a way of classifying models of structure of programming languages; a _Paradigm_ is a _model of interpretation_

* _Object Orient(at)ed Programming (OOP)_ - A paradigm of structuring a program around the sole concept of _Objects_, commonly through coupling data and code into a single unit.
* _Ownership/Move Semantics (OS)_ - Orientation around responsibility of values in a hierarchical fashion

## Foundations of the Object Orientation Paradigm

Though the original conception of the term coined by Alan Kay[^original-alan-kay] was never used as he intended it to be, the term _Object Orient(at)ed Programming (OOP)_ has been commonly understood to be a paradigm of structuring a program around the concept of _Objects_, commonly through coupling data and code into a single unit. Many languages support multiple paradigms, including aspects for the OOP paradigm, but I would class those as multiparadigm rather than being _solely_ an OOP language.

[^original-alan-kay]: "I thought of objects being like biological cells and/or individual computers on a network, only able to communicate with messages (so messaging came at the very beginning – it took a while to see how to do messaging in a programming language efficiently enough to be useful)." - Alan Kay, 2003 <http://userpage.fu-berlin.de/~ram/pub/pub_jf47ht81Ht/doc_kay_oop_en>

Most languages implement _Objects_ and _Classes_ in the Simula tradition; most of the notable OOP languages have a similar form by defining methods (member functions) within the class definition. Traditionally languages such as Java can be classed as _solely_ an OOP language.


Most traditional OOP languages are based around the concept of _inheritance_, a mechanism of deriving a class data type from another class data type and retaining similar information. Most people generally view inheritance as a combination of [subtyping](https://en.wikipedia.org/wiki/Subtyping) and [dynamic dispatch](https://en.wikipedia.org/wiki/Dynamic_dispatch) through [virtual method tables (vtables)](https://en.wikipedia.org/wiki/Virtual_method_table). This has lead to many discussions asking whether a language can be called as OOP if it does not support inheritance[^go-example].

[^go-example]: The [Go programming language](https://golang.org/) does not support inheritance. However under my definition, Go is an OOP language but is designed around (implicit) `interface`s (a form of [type-classes](https://en.wikipedia.org/wiki/Type_class) or [structural typing](https://en.wikipedia.org/wiki/Structural_type_system)) as a way to compose objects, and methods can be applied to any user defined type; not just record types.

In recent times, _inheritance_ has been falling out of fashion in favour of _composition_[^composition-over-inheritance]. This is mostly due to the issue of conforming a _class_ to a strict (singular) hierarchy of agency when in reality, things can belong to many (if not infinite) categories and hierarchies, as well as another aspect which I will be discussing throughout this article.

[^composition-over-inheritance]: <https://en.wikipedia.org/wiki/Composition_over_inheritance>

There are many criticisms of OOP[^brian-will-oop][^stepanov-oop][^rob-pike-oop-1][^rob-pike-oop-2][^cat-v-oop][^cat-v-joe-armstrong-oop] but my general criticism is that by placing emphasis on trying to solve problem in the type system, it shifts focus from the data structures and algorithms, [the core of what a program fundamentally is](/article/2020/05/31/progamming-pragmatist-proverbs/#the-concept-of-programming).

[^brian-will-oop]: <https://www.youtube.com/watch?v=QM1iUe6IofM>
[^stepanov-oop]: <http://www.stlport.org/resources/StepanovUSA.html>
[^rob-pike-oop-1]: <https://groups.google.com/forum/#!topic/comp.os.plan9/VUUznNK2t4Q%5B151-175%5D>
[^rob-pike-oop-2]: <https://commandcenter.blogspot.com/2012/06/less-is-exponentially-more.html>
[^cat-v-oop]: <http://harmful.cat-v.org/software/OO_programming/>
[^cat-v-joe-armstrong-oop]: <http://harmful.cat-v.org/software/OO_programming/why_oo_sucks>

[^loadsaclasses]: <https://web.archive.org/web/20180829092402/http://csis.pace.edu/~bergin/patterns/ppoop.html>

Since objects themselves are being treated _as if_ they have behaviour (not just type properties), they are effectively being treated as if they were _agents_ in the program. This mental model has many conclusions, many of which cause issues.

In my article [_Pragmatism in Programming Proverbs_](https://www.gingerbill.org/article/2020/05/31/progamming-pragmatist-proverbs/), I state:

> Object orientated programming is a form of misinterpreted and misapplied Aristotelian Metaphysics applied to a domain it was never meant to model

What I mean by this statement is that _artificially_ conforming any/all relationships between data and types to an artificial hierarchy of _agency_ is a form of naïve-Aristotelian metaphysics. Since there is no actual _agency_ in the programming objects, it is a partial fallacy. When trying to conform a program to have a particular structure when it does not naturally, the absence of a structure in a program is more useful than a bad structure.

### Methods

The concept of adding methods to classes/objects has proven useful to many. The real questions are:

* Why?
* And how do people actually conceptualize methods on a day-to-day basis?

For most people, I am going to bet that methods, in languages with an emphasis on inheritance rather than composition (such as C++ or Java), are treated as a way of categorizing and associating functions/procedures with a data record. There are a few reasons for this approach:

* Easy to organize and search for procedures by a data type
* Allowing methods as a form of syntactic sugar for writing calls in a _subject verb object_ manner e.g. `foo_do_thing(x, y)` vs `x.do_thing(y)`
* Mental model of behaviour for objects

From experience, I have found that long time users of "OOP" languages eventually start treating methods primarily in the first two approaches.

I will not go into depth about the other main aspects of OOP such as encapsulation, local retention, forms of polymorphism, etc, as the hierarchical nature is the fundamental aspect of focus for this article. The (linear) hierarchy of agency is the main problem. The reason why people argue for _composition over inheritance_ is that it flattens this linear hierarchy, reducing its effect. It is the transition from [nominal typing](https://en.wikipedia.org/wiki/Nominal_type_system) to [structural typing](https://en.wikipedia.org/wiki/Structural_type_system), which is more flexible because many data structures and problems have a _non-linear_ nature to them, which _linear_ approaches __cannot__ handle. When trying to adhere to the the strict hierarchical type system approaches, it leads to numerous issues because data is more commonly graph-like (non-linear) than tree-like (linear) for most problems. This strict hierarchy does occur with encapsulation at the object level too, a strict hierarchy of messages/references; this hierarchical nature arises from the concept agency itself, inheritance is not the root cause.

**n.b.** Inheritance is not all bad and does have many real life practical uses, but these costs must be known before using them, like with any tool.

**n.b.** The linearity is with regards to the data structures themselves and not the algorithms.

## Foundations of the Ownership Semantics Paradigm

[C++11](https://en.wikipedia.org/wiki/C%2B%2B) introduced the concept of _move semantics_ or _ownership semantics_ (OS), a way to minimize the copying of data through copy constructors. It utilizes the added concept of r-value references (`T &&`) as a means to do this. However, the concept began to be used for a lot more than its basic purpose. The concept adds the high level abstraction of "moving" objects rather than "copying" objects. Physically, a computer only ever copies and this high level abstraction, to treat objects _as if_ they were "real objects", is not what actually happens. It is also a [category error](https://en.wikipedia.org/wiki/Category_mistake) to treat them as "real objects" since "real objects" and "programming objects" have little connection with each other ontologically. When a value or object is "moved", this means is that the _responsibilities_ of the resources of that object have been transferred to another object or environment---_agents_. In this case, ownership/move semantics is fundamentally based around the _responsibilities of values_ by tracking value usage.

In this model of agency, the arena of agency can take on many forms, such as blocks, procedure bodies, or aggregate values. Therefore some _owned-values_ also _own_ other values, and thus a value could have agency.

If we were to call Ownership Semantics a paradigm, it would be the orientation around the _responsibility of values_ in a hierarchical fashion, placing emphasis on this system of responsibility, shifting focus from data structures and algorithms.

The concept of _responsibility_ and _ownership_ is similar to the real world counter parts in that to own something means to have exclusive use and full responsibility over it.

[Rust](https://www.rust-lang.org/) is a multi-paradigm programming language but at its core is an Ownership-Orientated language. Everything in Rust has a concept of _"ownership"_ and _lifetime_ associated with it. Rust is designed around trying to be first and foremost "safe", especially with regards to concurrency. Rust derives from the C++ family in terms of philosophy and style, but uses a more [qualifier-focused](https://www.gingerbill.org/article/2018/03/12/on-the-aesthetics-of-the-syntax-of-declarations/) declaration syntax and many concepts from functional languages from the [ML family](https://en.wikipedia.org/wiki/ML_%28programming_language%29).

_Lifetimes_ are theoretically orthogonal to _ownership_ but in practical, they usually are intrinsically coupled. I will not discuss the problems with object-based lifetimes in this article.

The following Rust code can be used to demonstrate this responsibility transfer between different capturing things such as `let` statements:

```rust
pub struct Foo {
	value: i32,
}

fn main() {
	let foo = Foo{value: 123};
	let bar = foo; // the responsibility of `foo` is transferred to `bar`

	println!("{}", foo.value); // error: use of moved value: `foo.value`
	println!("{}", bar.value);
}

```

Rust is an immutable-by-default language, with the option to opt into mutability with `mut`. Immutability helps a lot with mathematical proofs for logic since things things can be "flattened" quite easily, however virtually all computers are fundamentally mutable things, even if the abstraction of immutability is a useful tool. As a result, the ownership semantics system requires a few more rules to take into account mutability, by adding the concept of "borrowing" through references. The general rules for the borrow checker are:

* Each value may have as many immutable borrows as you want
* Each value may only have one mutable borrow at a time
* Each value may not borrow immutably and mutably at the same time
* Values will be "dropped" when the owning connecting goes out of scope
* Taking a value by `self` `Drop`s the original value

When using Rust (or move semantics to their full extent in C++11), most people will fight the borrow checker regularly[^fighting-borrow-checker]  (especially newcomers to the language or people swapping between different languages). Many people have found approaches to reduce these issues:

[^fighting-borrow-checker]: Getting used bypassing the borrow checker to reduce fighting implies people have just found a way to cope with the constraints it imposes.

* Keep blocks small, structs small, etc---this reduces the size of the arena of agency and thus reduces the amount of responsibility it must take care of
* Minimize self references in structs, i.e. graph-like data structures are difficult to implement using references
* `Cel`, `RefCell`, `Ref`, and `Rc` are more common than many would like
* Use indices/handles instead of references

Essentially, all of these approaches are bypassing the borrow checker in some form (if not entirely), especially the use of indices/handles. The first three approaches are to flatten the (linear) responsibility hierarchy.

**n.b.** Ownership semantics do have many practical use cases, and can be used to prove the safety of numerous problems, especially reducing vulnerabilities in programs. This is the main purpose why Rust was developed at Mozilla. Web browsers need to be very _safe_ programs, through sandboxing, data races, networking, and other concurrency issues. Being able to prove certain things at compile time is a very useful thing when it comes to safety and robustness of a program. However, as I have stated that because of the linear nature of OS, it cannot solve a whole range of other problems without resorting to `unsafe` or another way of bypassing the borrow checker entirely.

## Mathematical Formalism of Ownership Semantics

Ownership semantics are a form of an [affine substructural type system](https://en.wikipedia.org/wiki/Substructural_type_system#Affine_type_systems)[^rediscovery][^other-terminology] which means that they are fundamentally described by a [linear logic](https://en.wikipedia.org/wiki/Linear_logic), and explains why it struggles to express _non-linear_ problems. Therefore ownership semantics and the borrow checker are fundamentally a linear tree (hierarchy) and not a non-linear graph, as described by its underlying formal logic. Many data structures and problems in real life are fundamentally _non-linear_, of which _linear_ approaches __cannot__ handle.

[^rediscovery]: Whilst writing this article, I did not realize that this was already developed, and I accidentally rediscovered substructural type systems and linear logic, and had my own terminology for it. However, it is more appropriate to the more commonly used terminology.
[^other-terminology]: <div>`XnYo` (X-use Y-owners), `?` (0/1), `2+` (2 or more), `N` (arbitrary uses)<br>Examples:<ul><li>`1u1o` (1-use 1-owner, linear owned-value)</li><li>`?u0o` (0/1-use 0-owners, affine non-owned-value)</li><li>`Nu1o` (N-uses 1-owner, normal owned-value)</li><li>`2+1o` (2+-uses 1-owner, relevant owned-value)</ul></div>

In C++11 with introduction of move semantics, the STL includes the concept of "smart pointers", each with different substructural logic.

* `std::unique_ptr` - linear (1-use) self owning pointer  (1u1o)
* `std::shared_ptr` - normal (N-use) self owning pointer  (Nu1o)
* `std::weak_ptr`   - normal (N-use) non-owned pointer    (Nu0o)
* `T *&&`           - affine (0/1-use) non-owned pointer  (?u0o)

If you would like to learn more about the fundamental logic of the ownership semantics applied to the Rust language, I recommend reading this paper explaining the logic using formal mathematics: [Oxide: The Essence of Rust](https://arxiv.org/abs/1903.00982) (arXiv:1903.00982).


## The Duality of the Linear Structures

As I have described above, both the OOP and OS both share similarities:

* Traditional-OOP: A (linear) value hierarchy of behaviour. The values act as agents.
* Ownership Semantics: A (linear) value hierarchy of responsibility. Agents are responsible for values.

In the the OOP case, the value/object is the agent. In the OS case, the agent is whatever has responsibility for it (e.g. another object, function, block, etc). Both have linear value hierarchies which are quite strict and singular.

## Singular Holistic World-View

Both are singular in nature in that they deal with singular forms of values rather than groups of values. They are both (traditionally) very hierarchical, and place emphasis on the system as a way to control the processes rather than the algorithms directing the processes. Objects and Owned-Values are fundamentally "nouns", but programs are "verbs".

Dealing with singular values can be very useful, but not everything is a value. Some things are fundamentally "non-values" e.g. instructions/control-flow/declarations. It is a similar holistic world-view as OOP where everything must be X(, or produce X).

_Ownership Semantics_ are separate from _Lifetime Semantics_, but they are both required to be useful in more complex problems, and are usually coupled; naturally because of the singular-value-based nature.

## External Arguments for Ownership Semantics

* [Chromium Security Bugs](https://www.chromium.org/Home/chromium-security/memory-safety)
* [Microsoft: 70 percent of all security bugs are memory safety issues](https://www.zdnet.com/article/microsoft-70-percent-of-all-security-bugs-are-memory-safety-issues/)
* [Introduction to Memory Unsafety for VPs of Engineering](https://alexgaynor.net/2019/aug/12/introduction-to-memory-unsafety-for-vps-of-engineering/)

From these articles, many others have argued that languages like Rust would solve many of these problems, such as [_use-after-free_](https://en.wikipedia.org/wiki/Use_after_free). However this may not be necessarily true. It is correct that ownership semantics would solve _some_ problems that cause things like _use-after-free_ but that does not mean it will solve most of them. Even if things like _use-after-free_ are security/memory bugs, they are usually a symptom of another larger problem than it itself being the root cause.

## Alternatives to Ownership Semantics

One thing many people will ask whilst reading this article is "if Ownership Semantics are bad, what do you propose as a replacement?"

In general, most hard problems cannot be solved at compile time; because of this, adding more and more concepts to the type system of the language will not help without adding extra costs. This does not mean ownership semantics is bad but not a solution for many problems in that domain.

A lot of the problems related to responsibility are better solved with forms of "subsystems" within programs which handle groups of "things" and give out _handles_ of the "thing" instead of a direct reference. This is related to the approach many people use already to bypass the borrow checker through using indices/handles. Handles can contain a lot more information than a singular number. A common approach is to store a generation number alongside the index in the handle. If a generation has died, but the handle is asked to be used, the subsystem can give out a dummy sentinel value and report an error.

Other approaches are to reduce the need for responsibility in the first place. By keeping data structures [POD](https://en.wikipedia.org/wiki/Passive_data_structure), trivially copyable, and the zero value of it useful, can help you change the way you think about the problem at hand and simplify code. It places more emphasis on the data and algorithms themselves rather than the relationships between objects and types.

### Useful resources regarding these alternative approaches

* [Handles are the better pointers](https://floooh.github.io/2018/06/17/handles-vs-pointers.html) - André Weißflog
* Bitsquid Articles
    * <http://bitsquid.blogspot.com/2011/09/managing-decoupling-part-4-id-lookup.html>
    * <http://bitsquid.blogspot.com/2014/09/building-data-oriented-entity-system.html>
* Making the Zero Value Useful:
    * [Default to Zero](https://ourmachinery.com/post/defaulting-to-zero/)
    * [Go Proverbs Illustrated](https://www.gregosuri.com/2015/12/04/go-proverbs-illustrated/#make-the-zero-value-useful)

## Conclusion

Ownership semantics are a way to handle the responsibility of values in a hierarchical fashion Orientation around responsibility of values in a hierarchical fashion. This results in a (linear) value hierarchy of responsibility, where agents are responsible for values. The issues of ownership semantics parallel the same structural issues that Traditional-OOP has which results in a (linear) value hierarchy of behaviour, where the values act as agents.

Ownership semantics can be a useful tool for certain problems, but due to their underlying linear logic, they __cannot__ be use to express _non-linear_ problems which resorts people to try and bypass the concept entirely.
