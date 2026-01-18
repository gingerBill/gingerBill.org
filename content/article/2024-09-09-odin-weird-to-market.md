---
{
    "title": "Marketing the Odin Programming Language is Weird",
    "slug": "odin-weird-to-market",
    "author": "Ginger Bill",
    "date": "2024-09-08",
    "categories": [
        "software",
        "design",
        "marketing",
        "advertising"
    ],
    "tags": [
        "odin"
    ]
}
---

**[Originally from a Twitter Thread]**

[Original Twitter Post](https://x.com/TheGingerBill/status/1832797478728433873)

## "Killer Feature"

Odin is a weird programming language to advertise/market for.

Odin is very pragmatic in terms of its design and overall philosophy. Unlike all popular languages out there, it has no "killer feature". I've tried to design it to solve actual problems with actual solutions.

Those languages with a "killer feature" to them do make them "standout" and consequentially more "hypeable". The problem is that those "killer features" are usually absolute nonsense, very niche, or they rarely have any big benefit. Hype doesn't make software better. Odin isn't a "big idea" language but rather make an alternative to C on modern systems; it tries to solve the problems that other systems languages have failed to address. The problems are usually small but unrelated to each other; not solveable with a single "big idea"[^big-idea].

[^big-idea]: [This bit is rhetorical; I won't reply to it]. Name a popular language out here today, and I can name the "killer feature" for that language and why it became popular because of it. People maybe complain about the "feature" after many years but it's what brought them to it.

And before people say: "Odin's 'killer feature' is that it has none", how the heck do you market that? That seems like an anti-marketing feature. There isn't an example of a popular programming language out there which hasn't got a "killer feature", even C's was that in many way it is a "portable assembly" (even if that is not actually true).

## Hypeability

I know I have a bad habit when people ask me "why should I use Odin?": I ask them what their actual needs are, and then tell them to try Odin as well as the other "competition" to see which they prefer. I know that's honest English politeness to a tee, but that's me as a man.

I want Odin to be as best as it can be, but without trying to sell the world to someone in the process. I want to show people the trade-offs that each design has, even in other languages, and not ignore those trade-offs. There are no solutions, only trade-offs.

The lack of "hypeableness" that Odin offers is kind of reflected in the people that seem to be attracted to Odin in the first place. They seem very pragmatic, and just want to get on with programming. And as such, they are the kind of people who don't even share/hype Odin. I guess I don't want to easily attract the people who are more driven by hype the pragmatic concerns. I want to make software a better place, and attracting such people is detrimental to that endeavour in the  first place.

Just look at all the hyped JavaScript frameworks out there, and do they really make better software? Or do they just optimize for a mythical "Developer Experience (DX)"[^dx] which just results in more crap which gets slower, bulkier, and offer less for the actual user?

[^dx]: Developer Experience (DX) is probably a [psyop](https://www.wordnik.com/words/psyops) that makes software even worse; at expense of making the programmer think he is being more productive when in reality he is being less so because the DX is optimizing for that dopamine hit of "felt-productivity" than actual productivity and quality.


This is probably why some of my "hot takes" have been doing the rounds every now and then. I am trying to find out what the actual problems are and see what possible options there are to either solve or mitigate them on a case-by-case basis. A lot of those "hot takes" have been a form of marketing, and I am trying to at least give myself some exposure. Every single of them is just my opinion, which I usually think is quite mundane too. The web is huge, and thus there will be people who think those takes are shocking.

And to be clear I don't want to make Odin "hypeable" in the first place. I am glad with the steady, stable, and albeit slow, growth that Odin has been getting. The people who try Odin out, pretty much always stay for the longhaul as they fall in love with the language since it does bring them the "joy of programming" back. Something which I do advertise on the [Odin website](https://odin-lang.org/) is the "joy of programming" aspect, but that is something that cannot be explained in words, but rather has to be experienced to believe.

## Target Audience

Another issue with advertising/marketing a systems-level programming language is that it is niche. It has manual memory management, high control over memory layout, [S](https://pkg.odin-lang.org/core/simd/)I[M](https://pkg.odin-lang.org/core/simd/x86/)D and [SOA](https://odin-lang.org/docs/overview/#soa-data-types) support, etc. Great for people who need that level of control, but not needed for the general webdev. Obviously that isn't the intended audience for Odin, but the problem is that in the social media landscape, those voices are the loudest and many will actually shutdown the voices of people who disagree with them just because they are not in the webdev domain.

A minor issue that people are starting to think that Odin is "just" for gamedev. It makes me laugh because gamedev is pretty much the most wide domain possible where you will do virtually every area of programming possible. So "just" is a huge compliment but clearly the wrong image. It's like saying C++ is "just" for gamedev, when obviously it can be used for anything. The same as Odin, because it's a systems programming language. Odin does bundle with many game/application oriented packages but they are just that: packages.

## Conceptual Thinking

This is another problem. "Odin" can be thought of in a few different ways:

* The language itself
* The language+the compiler
* The language+the+compiler+core library+vendor library
* The entire ecosystem

When people speak of Python, they usually think of the entire ecosystem. I've worked with people who honestly thought Python was Numpy etc, and that you just had to download them. They had no distinction between any of the concepts, "Python" was just the "tool itself". Since I am an originally C programmer (and language designer), all of those distinctions are made obviously clear to me. There is no single C compiler, and they are all different. There stdlib is dreadful and you want to replace it with your own thing straightaway. But C still prevails.

I make those distinctions because I believe it makes things a lot clearer about programming itself, and helps you understand what the flaws are in the tool; thus know what you can do to mitigate/workaround those issues. But this does require a higher quality standard that than of the norm.


## Funding

Another issue is that Odin is _free_.

As weird as it sounds but since about 20 years ago, it's nigh impossible to sell a compiler. People expect a programming language and compiler to be free; without caring how much time, money, and effort that goes into building a tool.


Odin does have a GitHub Sponsors page (https://github.com/sponsors/odin-lang/) but we make very little, and definitely not enough to pay anyone full-time yet. We will pay for the odd paid work when we have the money, but only for a few weeks here and there.


I would love to have a few people working full-time on Odin, but it's something we cannot afford. It's also one of the main motivations too: to actually pay people for their work.

## Open Question

So I ask you fellow internet users:

How the heck do you advertise/market Odin (a systems-level programming language) when it does not have a discernable "killer feature" nor is "hypeable" by its very nature of being a pragmatic language?