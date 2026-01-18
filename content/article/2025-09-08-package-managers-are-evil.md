---
{
    "title": "Package Managers are Evil",
    "slug": "package-managers-are-evil",
    "author": "Ginger Bill",
    "date": "2025-09-08",
    "categories": [
        "software",
        "package managers"
    ]
}
---

**n.b. This is a written version of a dialogue from a YouTube video: [2 Language Creators vs 2 Idiots | The Standup](https://www.youtube.com/watch?v=tXJfS6jI9Z0&t=3860s)**



Package managers (for programming languages) are evil[^hyperbole].

[^hyperbole]: The term "evil" is being used partially hyperbolic to make a point.

To start, I need to make a few distinctions between concepts a lot of programmers mix up:

* A package
* Package Repositories
* Build Systems
* Package Managers

These are all separate and can have no relation to one another. I have nothing wrong with packages, in fact Odin has packages built into the language. I have nothing wrong with repositories, as that's how a lot of people discover new packages—a search engine, something I think everyone uses on a daily basis[^bad-search-engines]. Build systems are usually language dependent/specific, and for Odin I have tried minimize the need for a build system entirely (at least as a separate thing) where most projects will build with `odin build .`, which works due to the linking information being defined in the source code itself with the `foreign` system. This leaves _package managers_; what do they do?

[^bad-search-engines]: I primarily use [DuckDuckGo](http://duckduckgo.com/), but I also use Google and many others because they are pretty much all bad.


## What do package managers do?

Package managers download packages from a repositories, handles the dependencies and tries to fix them, and then it downloads its dependencies, and its dependencies, and its dependencies… and you can probably see where my criticism is going.

This is the **automation of dependency hell**. The problem is that not everything needs to be automated, especially hell. [Dependency hell](https://en.wikipedia.org/wiki/Dependency_hell) is a real thing which anyone who has worked on a large project has experienced. Projects having thousands, if not tens of thousands, of dependencies where you don't know if they work properly, where are the bugs, you don't how anything is being handled—it's awful.

This is the wrong thing to automate. You can do this manually, however it doesn't stop you getting into hell, rather just slow you down, as you can put yourself into hell (in fact everyone puts themselves into hell voluntarily). The point is it makes you think how you get there, so if you have to download manually, you will start thinking "maybe I don't want this" or "maybe I can do this instead". And when you need to update packages, being manual forces you to be very careful.

That's my general criticism: the unnecessary automation.

## What package managers sadly do

Most package managers usually have to define what a package is, because the language itself does not have a well defined concept of a package in the language. JavaScript is great example of this as there are multiple different package managers for the language (`npm` being one of the most popular), but because each package manager defines the concept of a package differently, it results in the need for a **package manager manager**. Yes… this is a real thing.

This is why I am saying it is _evil_, as it will send you to hell quicker.

## Mitigations in some languages

When using some languages, such as Go, most people don't seem to need many third-party packages even though Go has a built-in package manager. The entrance to hell seems too far and hard to get to[^prime]. The reason such languages don't fall into this trap as quickly is that those languages have a really good core/standard library—batteries included. When using Go for example, you don't need any third-party libraries to make a web server, Go has it all there and you are done. Go even has Go compiler built into the standard library; in fact it has two, a [high level one](https://github.com/golang/go/tree/master/src/go) for tooling and one which is the [actual compiler itself](https://github.com/golang/go/tree/master/src/cmd/compile)[^klingon].

[^prime]: This sentence is a quote from ThePrimeagen from that video.
[^klingon]: ThePrimeagen mentioned the "Klingon Approach" as a joke. This refers to Klingons (a species of humanoids in Star Trek) which have redundant organs. A very nerdy joke.

## The meaning of dependency

In real life, when you have a dependency, you are responsible for it[^jose]. If the thing that is dependent on you does something wrong, like a child or business, you might end up in jail, as you are responsible for that. Package dependencies are not that far different but people trust them with little-to-no verification. And when something goes wrong, you are on the hook to maintain it. It is a thing you should worry about and take care of.

[^jose]: This comment was from José Valim (the creator of the [Elixir](https://en.wikipedia.org/wiki/Elixir_(programming_language)) programming language) and this was a very good point which I wanted to add to this article.


A common thing that people bring up about package managers are security risks. There are indeed serious problems, especially when you blindly trust things you have just randomly started depending from off the internet. However for my needs, those are not even the biggest worries for what I work on, but they might be for you! For me at work, we use currently use [SDL2](https://www.libsdl.org/) for our windowing stuff at work, and we have found a huge amount of bugs and we hate it to the point that I/we will probably write our own window and input handling system from scratch for each Operating System we target. At least it is our code and we can depend on it and correct it when things go wrong; we are not having an extra dependency. I know SDL2 is used by millions of people, but we keep hitting all of the bugs. "But it's great though!". [SDL3]((https://www.libsdl.org/)) might fix it all but the time to integrate SDL3 would be the same time I could write it from scratch.

I am __not__ advocating to write things from scratch. I wish there were libraries I could say that they "Just Work™", but I still have to depend on them, and they are a liability; not just security liabilities but just bug liabilities.

Each dependency is a potential liability.

## Unbacked high trust

People rarely, if ever, vet their code, especially third-party code. Most people assume random code off the internet _works_. This is a societal issue where programmers are very high trusting in a place where you should have the least amount of trust possible. To put it bluntly, a lot of programmers come from a highly developed countries which are in general high trust societies, and then they apply that to the rest of their online world. This means you only need one person to do something malicious to something millions depend on to screw everything up. It doesn't even have to be malicious but a funny bug, where if you clicked one pixel on the screen, it is [Rick Rolling](https://www.youtube.com/watch?v=dQw4w9WgXcQ) you.

## Gell-Mann amnesia effect

**n.b. This argument was made by ThePrimeagen; not myself**

We've had an explosion of engineers over the past ten years, which have come just into the advent of all of these package managers coming out, for all of these languages, all at the same time. So programming felt very daunting; when you don't know how something works, it feels very daunting, especially when you first start out. The thing that is confusing, especially the high-trust argument that was being made, there is this weird [Gell-Mann amnesia effect](https://en.wikipedia.org/wiki/Gell-Mann_amnesia_effect) going on. You read one page and it's all about horses and you feel "man I know a lot about horses". Then flip to the next page and it's about Javascript and you go "man they got everything wrong about Javascript". Then you flip the next page and "man I know a lot about beetles". You've just forgot that they are super wrong on the thing you understood, but you think everything else is correct.

You'll find engineers who will go "some of my coworkers are so horrible, hey, let me download this library off the internet, this is going to be awesome". It's crazy as if they look and go "wow, one third of our staff cannot program anything, also I am going to trust every open source package I've downloaded". So there is this Gell-Man amnesia in programming code, where people who do open source or open things are viewed as the best of the engineers when that isn't true.

## Evolutionary selection pressure

Most people assume programming is like every other industry, like actual engineering which has been around for thousands of years, or modern science which has been around for about half a millenium. People trust who they perceive to be the "experts", as you see all of these articles, books, conference videos, etc, and they all tell you stuff but for the most part which does not necessarily _seem_ true.

I remember trusting those who were perceived to be "experts" which were espousing "wisdom". However, as I have programmed more over the years, I realized there is very _very_ little wisdom in this industry. This industry is 70–75 years old at best, and that is not old enough to have any good evolutionary selection pressure. It is not old enough to get rid of the bad things—it hasn't evolved quick enough. We will find out in a few HUNDRED years, and I mean _hundreds_, what is actual good wisdom is in programming.

There are some laws we know like [Conway's Law](https://en.wikipedia.org/wiki/Conway's_law), where "organizations which design systems (in the broad sense used here) are constrained to produce designs which are copies of the communication structures of these organizations". Or to rephrase it in programming terms, the structure of the code will reflect the company that programs it. But that is one of the only laws that we know to exist.

## Conclusion

My general view is that package managers (and not the things I made distinctions about) are probably in general a net-negative for the entire programming landscape, and should be avoided if possible.

-----

## How do I manage my code without a “package manager”?

**Excerpt from the Odin FAQ:** https://odin-lang.org/docs/faq/#how-do-i-manage-my-code-without-a-package-manager

Through manual dependency management. Regardless of the language, it is a very good idea that you know what you are depending on in your project. Copying and vendoring each package manually, and fixing the specific versions down is the most practical approach to keeping a code-base stable, reliable, and maintainable. Automated systems such as generic package managers hide the complexity and complications in a project which are much better not hidden away.

Not everything that can be automated ought to be automated. The automation of dependency hell is a case which should not encouraged. People love to put themselves in hell, dragging others down with them, and a package manager enables that.

Another issue is that for other languages, the concept of a package is ill-defined in the language itself. And as such, the package manager itself is usually trying to define the concept of what a package is, which leads to many issues. Sometimes, if there are multiple competing package managers with different definitions of what a package is, the monstrosity of a package-manager-manager arises and the hell that brings with it.