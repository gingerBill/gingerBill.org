---
{
    "title": "Markup Languages as ",
    "slug": "domain-specific-markup-languages",
    "author": "Ginger Bill",
    "date": "2026-01-21",
    "categories": [
        "programming language theory",
        "programming language design",
    ],
}
---

In the previous article, [The Only Two Markup Languages](/article/2026/01/19/two-families-of-markup-languages/), I discuss how there are only two syntactic families of _proper arbitrary_ markup languages: TeX and SGML. In this article, I want to discuss how many of the popular alternatives nowadays are not necessarily even _markup_ languages in the first place, but rather domain specific structured text formats (DSSTFs).

**To be clear from the start:** this is not a criticism of them in the slightest, and I will state that most of these DSSTFs are superior for most people's needs.



LuaX: <https://bvisness.me/luax/>


<https://en.wikipedia.org/wiki/Lightweight_markup_language>


Document

* Markdown
 * CommonMark
 * GitHub Flavoured Markdown (GFM) (An extension to CommonMark)
 * Markdown Extra
* reStructuredText (RST, ReST, reST)
* Wiki
* Org-mode
* POD

## Annotation vs Generation

* Distinction between markup languages used for annotating plain text to add extra information (e.g. bibles), and markup languages for generating strings, articles/documents, etc.

## Core Calculus for Documents

The Paper: <https://dl.acm.org/doi/epdf/10.1145/3632865>

@@youtube:yC4ja0Zines

Nota Language: <https://nota-lang.org/>


<table>
<thead>
    <tr>
        <th>Domain</th>
        <th>Ctors</th>
        <th>Model</th>
        <th>Example Languages</th>
        <th>Example Syntax</th>
    </tr>
</thead>
<tbody>
    <tr>
        <th rowspan="4" scope="rowgroup">String</th>
        <td>Literal</td>
        <td>$$\mathfrak{D}^{String}_{Lit}$$</td>
        <td>Text files, quotes strings</td>
        <td><pre><code>"Hello World"</code></pre></td>
    </tr>
    <tr>
        <td>Program</td>
        <td>$$\mathfrak{D}^{String}_{Prog}$$</td>
        <td>PLs with string APIs, such as Javascript</td>
        <td><pre><code>"Hello" + "World"</code></pre></td>
    </tr>
    <tr>
        <td>Template Literal</td>
        <td>$$\mathfrak{D}^{String}_{TLit}$$</td>
        <td>C <code>printf</code>, Python f-strings, Javascript template literals, Perl interpolated strings</td>
        <td><pre><code>let world = "World";
`Hello ${world}`</code></pre></td>
    </tr>
    <tr>
        <td>Template Program</td>
        <td>$$\mathfrak{D}^{String}_{TProg}$$</td>
        <td>C preprocessor, PHP, La-TeX, Jinja (Python), Liquid (Ruby), Handlebars (Js)</td>
        <td><pre><code>{% set world = "World" %}
Hello {{ world }}</code></pre></td>
    </tr>
    <tr>
        <th rowspan="4" scope="rowgroup">Article</th>
        <td>Literal</td>
        <td>$$\mathfrak{D}^{Article}_{Lit}$$</td>
        <td>CommonMark, Markdown, Pandoc Markdown, HTML, XML</td>
        <td><pre><code>- Hello **World**</code></pre></td>
    </tr>
    <tr>
        <td>Program</td>
        <td>$$\mathfrak{D}^{Article}_{Prog}$$</td>
        <td>PLs with document APIs,such as Javascript</td>
        <td><pre><code>val ul =
  document.createElement("ul");
  // ...</code></pre></td>
    </tr>
    <tr>
        <td>Template Literal</td>
        <td>$$\mathfrak{D}^{Article}_{TLit}$$</td>
        <td>JSX Javascript, Scala 2, VB.NET, Scribble Racket, MDX Markdown, Lisp quasiquotes</td>
        <td><pre><code>@(define world "World")
@itemlist{@list{
  Hello @bold{@world}}}</code></pre></td>
    </tr>
    <tr>
        <td>Template Program</td>
        <td>$$\mathfrak{D}^{Article}_{TProg}$$</td>
        <td>Typst, Razor C#, Svelte Javascript, Markdoc Mark-down</td>
        <td><pre><code>#let world = [World]
- Hello *#world*</code></pre></td>
    </tr>
</tbody>
</table>