---
{
    "title": "The Essence of Programming",
    "slug": "the-essence-of-programming",
    "author": "Ginger Bill",
    "date": "2021-02-01",
    "categories": [
        "philosophy",
        "psychology",
        "ontology",
        "programming philosophy",
        "programming languages"
    ],
    "tags": [
        "philosophy",
        "psychology"
    ]
}
---

One thing I have noticed a lot when a programmer is struggling to solve a problem, especially a novice, is that he is stuck worrying about the "best way" to _implement_ the solution rather than actually understanding the problem he has. I believe a lot of this stems from not understanding the essence of what programming fundamentally is.

## Essentially Ordered Aspects

In a [previous article](https://www.gingerbill.org/article/2020/05/31/progamming-pragmatist-proverbs/) of mine, I state that "Programming is a tool to solve problems that you have in the domain of computers". At the essence of everything to do with programming, it is using and building tools with computers. My honest belief is that studying the concept of a tool itself and its essentially ordered aspects[^schema] will aid the use into correctly structuring our thinking about how we build tools in general.

The fundamental aspects of a tool are:

* Its Purpose,
* Function,
* Usage,
* And Implementation/Form.

Each following aspect/stage is a fulfilment of the previous, to which so stage can be skipped.

[^schema]: This is a [Peripatetic](https://wikipedia.org/wiki/Peripatetic_school)/[Aristotelian](https://en.wikipedia.org/wiki/Aristotle) schema.

### Purpose

A tool by its very nature is a means to achieve a particular ends. A good tool is one that fulfils its _purpose_ well, the _reason_ it was made. We use and build tools for _purposes_, there is a _why_ behind the tool.

### Function

The _function_ of a tool, is the tasks that a particular means is assigned to accomplish. Using an example, the function of hammer may be described in that it used to drive nails, but in general, it hits other lesser tools (a nail being another kind of tool). The specific function of the tool is determined by the specific problem.

**Note:** To clarify the difference, the purpose is the _why_ behind the tool and the function is the _what_ behind the tool.

### Usage

A tool is _used_ in a particular way by the user. The _usage_ is the fulfilment of its function. Most hammers will have a place for the user to hold, its handle, and a part which it can be used to hit things, its head/face. The _usage_ of a tool is restricted by what _function_ that tool has.

### Implementation/Form

Finally, how that tool is to be _implemented_ is restricted and dictated by how tool is meant to be _used_. If all of the previous aspects have been fulfilled, then the _implementation_ is most of the time not complicated (especially in programming). A hammer used for bricklaying may be implemented with a wooden handle, and a flat smooth steel head.

**Note:** _Aesthetics_ fits under this category of implementation or form. The implementation and how it appears can be separated, but rarely is in practice. How someone implements a tool is part of the aesthetic of that specific tool. Aesthetics is usually something that is evolved and discovered through tradition and not from pure reason.

## The Novice's Pitfall

For most people reading this article, most of this will seem dead obvious but they may not have seen it in this specific articulation. So why do I bring it up? Because forgetting (or not knowing of) this structure of the reality of what you are actually doing is the pitfall many novices, and even veterans, fall into when programming. Getting caught up in what is the best way to implement a program, or any problem for that matter, distracts the programmer from the problem.

For the vast majority of problems, especially the problems novices have, if you understand the purpose, function, and usage of the tool you are creating, then its implementation will be "trivial" in the sense that the previous aspects restrict how you approach the problem.

### Teaching

When teaching novices, I have found that there are usually two different kinds of people (sometimes embodied in the same person):

* Novices who are stuck worrying about how to best implement their programs, but do not actually understand what the _purpose_ of the program they are trying to do
* Novices who understand what the purpose, function, and usage, of what their program is, but do not know the tools well enough about how to implement stuff

Interestingly, the former is much more common than the latter.

In the latter case, these individuals are natural problem solvers and require only teaching the explicit thinking that goes on and the tools they require for producing their program, e.g. algorithms and data structures. In this case, practising is required to hone the skills of the novice.

In the former case, it does not matter if all the tools can be taught at all if the individual does not understand how to use them, what their function is, nor what the purpose of the problem he is trying to solve. This kind of novice needs to learn how to think like a problem solver.

Understanding this process of structuring your thinking of what a is tool, allows you to apply it further, and that can be applied to every aspect itself recursively. Each stage can be split up further into its own four-part structure. For example, there usually are many different ways to implement something to achieve the same ends which means understanding which one is the best compromise for the current situation.

Each stage can also give feedback as to whether it is possible to fulfil the previous stage, i.e. trying to implement a particular usage may unearth the impracticability or impossibility of the usage. This does not mean the process has been reversed but rather shown that the previous aspects were not stable foundations to work upon. Understanding how something is implemented can aid a lot about _why_ something is used a particular way too.

Sometimes the implementation of something is difficult to determine, as hard problems are hard. Sometimes you cannot make a problem less complicated, but you can try to make it less complex by breaking it down into smaller problems. This is a skill that is continually learnt over many years, and not something you will ever perfect but will get better at.

### "Best Way"

There is no such thing as an unqualified universal _"best way"_ to solve a given problem in the abstract. And what is needed to be done is to understand the particular situations that requires one to attend to such problems. Compromise is a given, and the only way to get better is to practice, practice, practice. Abstract solutions are called algorithms, but how that algorithm is implemented depends on what it will be implemented on---the machine.

For novices, it should be made clear that being taught tools (e.g algorithms, data structures, paradigms, idioms, etc), does not imply that the "correct way" to do things has been learnt. The "correct way" is heavily specific to the problem domain; this cannot be taught but only learnt through experience over many years. Actualizing abstract ideas into reality is difficult to do, even for veterans to programming.

Aiming to abstract/generalize a problem is a recipe for disaster, especially for novices, because it is rarely ever the case problems are abstract/general. Most problems are particular/specific, and require knowledge of the domain of that problem. Application is should not be separated from the teaching of the topic. Try to solve the _specific_ problem that is actually at hand, not a _general_ problem that _might_ exist[^previous-article]. Programming is an inherently practical endeavour rather than a theoretical one. And its teaching should reflect that. Theory is important, but most programmers do not want to, nor should they, have to become mathematicians in order to understand the application of anything.

**Note:** For novices, a good rule of thumb when implementing a program is to aim for clarity, especially for others to read and comprehend, and do not try to be clever. And novices ought not be afraid to rewrite code if needed. Getting a good (not perfect) solution the first time is not expected of a novice, and through experience, getting a good solution will come quicker. Through the habit of practice, one will become better at the art of programming.

### Process of Thinking

It should be clearly noted that this ordering only works for solving known problems, it is a way of thinking about purpose-driven domains, i.e. _engineering_. This process of structuring your thinking does not apply to exploratory things such as _research_ and _science_. _Science_ is not a purpose-driven domain but a exploration-driven domain. There is not a "goal" to the art of science, but a continuous process of discovery. As a discipline, programming is fundamentally closer to something like carpentry than a science. Programming is a craft of solving problems on computers.

## Conclusion

Understanding the essence of what a tool is helps us structure our thinking when solving problems. It gives us a language and process to understand why and how we approach building tools. Many novices fall into the same trap of not understanding the problem that is trying to be solved, and are too concerned about the implementation. Teaching novices how to think about solving problems is extremely important in improving and honing in the craft.

[^previous-article]: https://www.gingerbill.org/article/2020/05/31/progamming-pragmatist-proverbs/
