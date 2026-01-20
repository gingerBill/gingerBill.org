---
{
    "title": "The Only Two Markup Languages",
    "slug": "two-families-of-markup-languages",
    "author": "Ginger Bill",
    "date": "2026-01-19",
    "categories": [
        "programming language theory",
        "programming language design",
    ],
}
---

There are only two families of _proper arbitrary_ markup languages: [TeX](https://tug.org/) and [SGML](https://en.wikipedia.org/wiki/Standard_Generalized_Markup_Language)[^sgml-link]. By _arbitrary_, I mean the grammar specifically, and how it can be used to _mark_ arbitrary plain text with information. And by _proper_, I mean the ability to have standalone nodes, user-definable nodes, nodes with attributes, and the wrapping of plain text. Everything else either lacks one of the these capabilities, or is a derivative or syntactic-makeover of TeX or SGML.

[^sgml-link]: I would normally link to official thing as reference but it's behind the "wonderful" ISO paywall: [ISO 8879:1986](https://www.iso.org/standard/16387.html).

## The Two Families

The TeX family:

```tex
\foo
\foo{wrapped text}
\foo[attrib=value]{wrapped text}
\foo[attrib=value]
```

The SGML family:

```xml
<foo />
<foo>wrapped text</foo>
<foo attrib="value">wrapped text</foo>
<foo attrib="value" />
```


This does mean I am excluding things like [Markdown](https://daringfireball.net/projects/markdown/)[^what-i-use], [troff](https://troff.org/), [IBM's GML](https://en.wikipedia.org/wiki/IBM_Generalized_Markup_Language), [Wiki](https://en.wikipedia.org/wiki/Wiki), [Emacs Org-Mode](https://orgmode.org/worg/org-syntax.html) etc. The reason for this exclusion is because they are neither _arbitrary_ nor _proper_. They have procedural semantic meaning to their syntax and it cannot be arbitrarily extended.

[^what-i-use]: I use a variant of Markdown to write these articles. I use a custom extension of Commonmark which I've added the ability to write these margin-notes and some other things like trivial YouTube video embedded.

For example in Markdown, `[text](link)` has a very specific intrinsic semantic meaning. Whilst in SGML/XML, `<foo>blah</foo>` has no intrinsic semantic meaning without some extra program to enforce that.

For other similar markup languages, things like [BBCode](https://en.wikipedia.org/wiki/BBCode) I am classing as part of the the SGML family, and [Scribe](https://en.wikipedia.org/wiki/Scribe_(markup_language)) as part of the TeX family. BBCode is effectively a near-subset of XHTML but uses `[]` instead of `<>`.

Scribe's syntax is effectively in the family of TeX but there is no need for the `{}` and either requires paired blocks (e.g. `@Begin(Quotation)` and `@End(Quotation)`) or adding the plain text as part of the attributes (e.g. `@Foo(tag=bar, title="The Title")`). This is why I think Scribe's syntax is fundamentally flawed because of the lack of `{}`-like wrapping ability, compared to actual TeX.


## Edge Cases of the Syntaxes


In the two languages, they both have means of using their specific symbols that are used for writing the mark-up. For SGML you do `&lt;`[^html-entities], and for TeX you do `\\`. The SGML approach differs to TeX as it is a different syntax than regular markup, whilst TeX unifies its syntax.

[^html-entities]: For a minimal syntax to prevent escaping issues in an SGML-like language, you need 5 escaped entities: <br>` & → &amp;`, `' → &apos; or &#39;`, `< → &lt;`, `> → &gt;`, and `" → &quot; or &#34;`. However there are literally thousands of XML/HTML entities out there, and supporting them correctly has been "fun" for [packages](https://pkg.odin-lang.org/core/encoding/entity/) in Odin.

There is also the second aspect that the TeX family of syntaxes are much easier parse than the SGML family. I've written both before and the SGML syntax requires an order of magnitude more code to write, because of the named blocks for wrapping.

To clarify, I am saying the "TeX Family" and not actual TeX itself. I know how insane TeX is and I did not want to get into how context-sensitive its grammar really is. I just wanted to focus on the _arbitrary proper markup syntax_ of it in isolation rather than the semantics of a specific language in the "TeX Family".


SGML wrapping syntax also has the flaw of allowing for overlapping hierarchies:

```xml
<a><b>text</a></b>
```

TeX syntax does not have this problem as it only uses generic brackets/braces. I cannot think of a case when overlapping hierarchies[^overlapping-hierarchies] this is desired---in fact HTML parsers have to mitigate for this possible typo. A SGML derivative could remove the overlapping hierarchy syntax flaw by having `</>` be the delimiter.

[^overlapping-hierarchies]: By this, I mean purely the syntax, and not the concept of an overlapping hierarchy, which can exist in things like marking up [Bibles](https://en.wikipedia.org/wiki/Overlapping_markup).


Real life TeX syntaxes do have their own edge cases, deviating from the general markup syntax[^tex-cheatsheet], but this is more to do with wanting to express mathematical formulations in real text rather than keep to a syntactic "purity".

[^tex-cheatsheet]: If you want a good example of this, I recommend reading this wonderful [Cheatsheet](https://quickref.me/latex.html#supported-functions) to see the numerous syntactic exceptions which exist for practical pragmatic purposes, even if that means the syntax parser is now hell of a lot more complex.


## JSON is not an Alternative

Expanding upon the proper aspect, the need for attributes is very important. It is common to see people replace XML with [JSON](https://www.json.org/json-en.html) nowadays, as JSON is easier to read, write, and parse than XML. However JSON is a strict tree with no attribute system. Attributes are a necessary aspect of a markup language as they allow for adding extra information to a node without requiring any children nor wrapped text. Many people emulate attributes in JSON with other sibling nodes, which is not equivalent at all. Attributes (or tagging) is an important thing as it adds extra information to tree-like structures, and sadly it's missed in a lot of languages. JSON is also not a markup language in that it cannot be used to markup arbitrary text, rather it is has a specific hierarchical format it requires and it cannot be placed anywhere within plain text.

I'd also argue other languages like [YAML](https://yaml.org/) or [TOML](https://toml.io/en/) are definitely not forms of Markup Languages (fun fact,  YAML was originally named ["Yet Another Markup Language"](https://yaml.org/spec/history/2001-08-01.html)). These are both forms of configuration languages. And when people have replaced XML with JSON, it's because they were used XML as a (verbose) configuration language than any kind of markup language. And I'd even argue JSON should not be used as a configuration language either and only a lightweight text-based data-interchange format, since that is its entire purpose.

**n.b.** I am still not sure why people think XML is a "human readable" language, and keep repeating this adage. Yes it is "readable" but it is not quickly comprehendible. Please use nearly anything but XML for a configuration language. [INI](https://en.wikipedia.org/wiki/INI_file) is honestly still good for most people's needs.

YAML is also a monstrosity and should never be used by anyone for any reason. It's nigh-impossible to write a parser for it and has too many syntactical ambiguities. It has lead to numerous infamous situations such as [The Norway Problem](https://hitchdev.com/strictyaml/why/implicit-typing-removed/)[^just-say-no]. Also fun fact, YAML is actually a superset of JSON which all valid JSON documents are also valid YAML documents. This is beyond cursed, but as this is not an article on YAML, I will stop with my micro-rant here.

[^just-say-no]: Just say Norway to YAML.

## Lisp is not an Arbitrary Proper Markup Language

Unfortunately, I do not class[^s-expressions] Lisp/s-expression style stuff as being an _arbitrary proper markup language_, at least by default. The main reason is that you cannot just "markup" pre-existing plain text with it that easily, you effectively have to restructure the text completely for it work. At best you'd need to add a second syntax to make it clear what are the attributes vs what is the plain-text.

[^s-expressions]: This section was not here originally but I wanted to clarify why I don't think they could be the third family in the class of _arbitrary proper markup languages_.

[Hiccup](https://github.com/weavejester/hiccup) is a common syntax for generating HTML in the [Clojure](https://clojure.org/) ecosystem, which does "solve" the "proper" aspect by having attribute syntax:

```clojure
[:span {:attrib "value"} "wrapped text"]
```

However it is still not an "arbitrary" markup language due not being able to wrap pre-existing plain text. I think the entire motivation behind the original markup languages too: marking up pre-existing plain text documents. Rather than starting from the "markup" language and adding text. This latter form is probably closer to just a structured text format rather than a markup language. Because of my clarification, S-expressions are a form of object notation, similar to JSON.

A very minor but other obvious thing is the use of parentheses `()` is a bad choice since they are commonly used within plain text, but if you just swapped it for `[]` or `{}`, it would be fine, and most people would still recognize the s-expression nature. And the need for something like backticks <code>`</code> to wrap the text might need to be there to remove the ambiguity.

Using quotes `"` are also another aspect which make it not arbitrary. However I'd argue that quotes are very common in some European languages, and thus would require a lot of corrections. One of the benefits to both TeX and SGML is that they "start" with symbols which are not commonly used in every day text. Backslash `\` seems to only exist since the dawn of computers and is never seen in actual text before (making it a near perfect choice) and less/greater-than (`<` `>`) are rarely used outside of mathematical texts making it also a good option too to use.

**n.b.** I am not saying you cannot have different syntaxes that work and have them be used for structured formatting, rather I don't class them as "arbitrary proper markup languages".


### Plain Text as a Pseudo-Grammar

In a weird way, plain text kind of does have a sort of pseudo-grammar that people assume of it and it is because of whitespace. Newlines are treated special kind of whitespace (usually multiple newlines signify a paragraph break) and general spaces are only separating other "things" (other characters).

For many people, the amount of spaces used is just for "alignment" or "stylization" and doesn't have any procedural semantic meaning. This assumption is why an arbitrary (not necessarily proper) markup language can exist.


## Applying this to Odin

[Odin](https://odin-lang.org/)[^my-language] is not a markup language, but I deliberately designed three distinct extension mechanisms so the language can grow in the future without forcing new foundational syntax. I achieve this with attributes on declarations, struct tag fields, and directives. These three different constructs have different syntaxes because they reflect different semantic meaning.

[^my-language]: The general purpose programming language that I have created. Which I hope most people who read my articles know this already.

Attributes can be applied to any declaration and have the following syntax:

```odin
@(key)
@(key=value)
@(a=b, c=d)

@key // as a minor shorthand
```

The attributes can be applied arbitrarily too for different purposes. This means if some new functionality is needed in Odin, it can be added.

The next syntax is struct field tags, which is just a string literal applied to the end of a struct field.

```odin
Foo :: struct { x: T `extra information here` }
```

This extra information is stored in RTTI and then used at runtime by the program/user to do whatever they need at runtime.


The last is the directive syntax. It's general syntax looks like this:

```odin
#key
#key(args)
```

And these can be either standalone, or applied to expressions, types, or statements. They are not applied to declarations to keep a distinct semantic meaning. These are all forms of a kind of semantic mark-up, but they exist as an escape hatch for future (or generally present) needs where the syntax might have been limiting. Attributes and directives are both TeX like whilst struct field tags are only a kind of "attribute syntax".


## Conclusion

Most of the papers[^papers-coombs][^papers-bray] I have read don't seem to talk about the syntactical distinction in this article, but rather make only semantic distinctions such as presentational, procedural, or descriptive.

[^papers-coombs]: Coombs, James H.; Renear, Allen H.; DeRose, Steven J. (November 1987). ["Markup Systems and the Future of Scholary Text Processing"](https://xml.coverpages.org/coombs.html)

[^papers-bray]:  Bray, Tim (9 April 2003). ["On Semantics and Markup, Taxonomy of Markup"](https://www.tbray.org/ongoing/When/200x/2003/04/09/SemanticMarkup#p-1)

I know this is probably a _very_ nerdy syntax post, but I do find it interesting, and I don't know if it has been talked about before by other people. If anyone knows of any other family of _proper_ _arbitrary_ markup syntaxes, please tell me as I'd love to know, but most of them seem to fall into one of these two categories. I personally prefer the TeX family because it removes the problems of overlapping hierarchies, minimizes clutter from redundant characters, and is a heck of a lot simple to parse.