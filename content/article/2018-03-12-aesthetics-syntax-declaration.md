---
{
    "title": "On the Aesthetics of the Syntax of Declarations",
    "author": "Ginger Bill",
    "date": "2018-03-12",
    "categories": [
        "odin",
        "programming language theory"
    ],
    "tags": [
        "odin"
    ]
}
---

Article was originally posted here: <https://odin.handmade.network/blogs/p/2994-on_the_aesthetics_of_the_syntax_of_declarations>

n.b. This is a philosophical article and not a technical article. There are no correct answers to the questions that I will pose -- only compromises.

I'm considering what the "best" declaration syntax would be. Historically, there have been two categories: which I will call qualifier-focused and type-focused.
An example of qualifier-focused would be the Pascal family. An example of type-focused would be the C family. Odin, like Jai, have been experimenting with an name-focused declaration syntax. These categories place emphasis on different aspects of the declarations.

* Qualifier-focused places emphasis on the kind/qualifier of declaration (`var x = 123; const K = true;`)
* Type-focused places emphasis on the type of the declaration (`int x = 123; bool const K = true;`)
* Name-focused places emphasis on the name of the declarations and that the right hand side must be an expression (`x := 123; K :: true;`)

Some languages have a hybrid approach to the syntax of declarations. Python uses a form of name-focused for general variable declaration but qualifier-focused for function, class, and import declarations. Most modern derivatives of the C family may use type-focused for most declarations but use qualifier-focused for import declarations.

There are some issue regarding all three approaches.

## Qualifier-Focused

* Most forms of qualifier-focused require numerous keywords to specify the kind of declaration
* Qualifier-focused adds verbosity to the syntax due to the extra keywords
* Qualifier-focused declarations have a tendency to make you define all declarations at the top of a scope and/or group declarations together of the same kind together. This nudges the programmers to not intermingle declarations and assignments. Depending on the views of programmer, this can be viewed as a positive aspect.

## Type-Focused

* Every declaration must be associated with a type and thus be part of the type system. This is one of the reasons why `void` is in C. If a function must specify the return type, the solution to this is to create a "non-type", i.e. `void`. Having a `void` type does cause issues in the type system in general but I will not consider those in this article.
* In the case of C++ and others, type inference must be done through a form of qualifier-focused (e.g. `auto` or `var`)

## Name-Focused

* Name-focused has three aspects to the declaration, the left hand side (lhs), the right hand side (rhs), and the middle part. The lhs aspect are the names of the entities to be declared whilst the rhs aspect of the declaration are forms of expressions. This means that all declarations must be a declaration of an expression. This does mean that all declarations must be assigned with a form of expression. The middle part denotes the type which could be optional.
* In a self-contained language, having only expression assigned declarations is not a problem. The difficulty comes from interfacing with foreign code, such as C, and having a consistent syntax. In C, there are two forms of function declarations: function prototypes and full functions with bodies. A function prototype is not a form of expression. A function with a body which can be thought of a named lambda function.
* An inconsistency with name-focused is with variable declarations without an assignment (`x: int;`). It is implied that the declaration has an implicit rhs expression, the zero/default value. It is also implied that the declaration must be a variable declaration (and not a constant declaration).

## On the Aesthetics of Qualifier-Focused

I will be open, I have a minor bias towards qualifier-focused due to Pascal being one of my very first languages. So when I started creating Odin, the language that I am designing and making, I started with a very Pascal syntax (including `begin` and `end`) but when the language became "public", the syntax changed to be closer to that of Jonathan Blow's language, Jai. I was intrigued by the idea of the name-focused syntax with its very elegant approach to type inference. However, I have had doubts about the syntax for quite a while. At one point, I struggled to find a solution to the issue of foreign procedures and foreign variables. Originally, I solved the issue for foreign procedures with replacing the procedure body with a `#foreign` tag. However, this approach cannot be applied to a foreign variable declaration and still be consistent. On an impulsive whim, I switched the entire declaration syntax to a Go-like qualifier-focused style for 2 weeks. (I have done this switch twice.) The solution to the foreign entities was to have a procedure lambda without a body by replacing the body with `---` and surrounding all foreign declarations in a `foreign` block. In Odin, a procedure without a body cannot be distinguished from a procedure type and thus there needed to be a way to specify a procedure literal/lambda without a body.

```odin
foreign my_lib {
    some_var: i32;
    amazing_foo :: proc "c" (a, b: i32, c: f32) -> rawptr ---;
}
```

There are two reasons for this conflict that I have between qualifier-focused and name-focused. The first is that name-focused is elegant and terse to write compared to qualifier-focused. The second is the "ugliness" of qualifier-focused with conjunction with other forms of statements.

Qualifier-focused looks "ugly" when it is combined with control statements:

```go
for var x = 0; x < 10; x += 1 {
}
```

The two keywords together in the `for var` block looks "dense and wrong" to me and makes reading the construct much more difficult. However, placing an open parenthesis in between the keywords reduces some of this "density":

```go
for (var x = 0; x < 10; x += 1) {
}
```

It does look slightly better but it is still "dense". These parentheses make it less "ugly" for some reason and it's not self apparent as to why the separation between the two words by punctuation improves matters.

This is probably a reason as to why Go uses the `:=` operator, especially in this case:

```
for x := 0; x < 10; x += 1 {
}
for idx, val := range array {
}
```

`:=` is a pragmatic solution to this aesthetic problem with the qualifier-focused `var`. However, this is not to say that the `:=` operator is great. In Go, it has extra semantics to make Go feel more like a "dynamic language" (variables will be shadowed with `:=`). Even if you had both `var` and `:=`, and that they did the exact same thing, it does beg the question: why have two things that do exactly the same thing?

I have been researching the topic of syntax in language design for a long time now. It's been an interesting topic and I think I should actually write most of my findings. I hope this condensed explanation of the issues with regards to declaration syntax has aided others as to my predicament.
