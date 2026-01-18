---
{
    "title": "Unstructured Thoughts on the Problems of OSS/FOSS",
    "slug": "unstructured-thoughts-on-oss",
    "author": "Ginger Bill",
    "date": "2025-04-22",
    "categories": [
        "software",
        "philosophy",
        "oss",
        "foss",
        "open source",
        "free open source"
    ],
    "tags": [
        "oss"
    ]
}
---

**Originally from replies to a Twitter thread: <https://x.com/TheGingerBill/status/1914389352416993395>**

**This is not a structured argument against FOSS/OSS but my uncommon thoughts on the topic.**

I am not sure if I agree [that FOSS/OSS derives from the same thinking process as the ideology of communism], but I understand the sentiment. The fundamental issue is that software is trivially copyable. I have loads of issues with FOSS and OSS[^distinction]. And part of this "ideology" (as presented in the original post) is naïvety coupled with only first-order thinking and a poor understanding of _ownership_. Software isn't property in the normal sense of that word, so trying to apply the same rules to it is why it starts to break down; coupled with the first-order thinking that many FOSS advocates do, it leads to unsustainable practices and single sources of dependency failure.

[^distinction]: I am making a distinction between OSS (Open Source Software) and FOSS (Free [and] Open Source Software) in this article but most of my critiques are related to both.

## Physical Property vs Intellectual Property

However the simplest argument (which is technically wrong) is due to what I already said: it's trivially copyable, and thus not really "property" in any traditional sense of that word. Software at the end of the day is a very complicated and complex implementation of an algorithm.

[^piracy]: In the exact same way that Piracy is a different crime to Theft. Piracy is "intellectual property" infringement, and not the involuntary removal of physical property. Nor is piracy fraud nor an intentional tort (i.e. [conversion]https://en.wikipedia.org/wiki/Conversion_(law)).

It is neither _physical property_ nor _intellectual property_, the latter of which is closer to an honour system, rather than a property rights system even if has the term "property" in its phrase. So in a weird sense, it fits into a different category (or maybe a subcategory) because it's not the algorithm/idea itself which is "precious" but rather the implementation of it—the software itself. The foundations of the assumptions of FOSS/OSS about the "right" to "redistribute" is blending a few different aspects together. The licence itself is an honour system applied to the "software". But the question is, is that an applicable in the first place?

There are a lot of oddities when it comes to copyright and trademark law, which are mostly done due to practicality rather than based on principles. A good example that recipes[^patents] cannot be copyrightable, but from a principled aspect there isn't any reason why not. Recipes have been passed around all over the place by numerous people over the years, so the origins are hard to trace, and even harder to enforce. This is why many industries have "trade secrets", to protect their place in industry. Letting people know your "secrets" means that they are "secrets" no more. Even legally (secret) recipes are classed as the same as "trade secrets".

[^patents]: I'd argue [patents](https://en.wikipedia.org/wiki/Patent) are fundamentally in the same-ilk as "recipes", and software-patents even more so. I personally don't like patents that much except in a few cases, but I really do dislike software-patents with a passion. However that's a different topic for a different day.

## "Net Benefit for Society"

You could argue that letting people have more knowledge is a "net benefit for society" but that is the first-order thinking I am talking about. The assumption that "the truth with set you free" is adding the assumption that everyone should know it in the first place. I am not making a pseudo-[gnostic](https://en.wikipedia.org/wiki/Gnosticism) argument, but rather some secrets are best kept, well, secret. It also makes sense from a business sense too to not let your competitors know how you do things if you want some sort of technical advantage.

But this is still first-order thinking. To go second-order (which is still not that deep), it also means that people tend to rely on those "ideas" rather than evolving and generating more. It means that people just rely on the free things rather than trying to come up with other approaches.

To clarify further what I mean by first-order thinking, it's thinking about the immediate results rather than the long-term more complex and complicated results which require thinking in higher-orders. A good analogy would be a [Taylor series](https://en.wikipedia.org/wiki/Taylor_series). In this analogy, first-order is a linear approximation, whilst second-order would be quadratic, etc. As you add more terms, you get a more accurate approximation of the actual function, but with this fitting approach, it still has numerous limitations and flaws. And in the case of thinking, more and more orders might not be easy (or even possible) to think about.

Ideas have virtually no cost to them, or even negative cost, and as such, when something is free, people cannot rationally calculate a cost benefit analysis of such ideas. It's assuming that a "marketplace of ideas" is possible, when a market requires a price mechanism to work. A rational marketplace requires a way to rationally calculate costs from prices (as costs are determined by prices, not the other way around).

There is a reason the [XKCD 2347](https://xkcd.com/2347/) meme exists. People will rely on something just because it is free and "forget" (I am using that term loosely) that everything has a cost to it.

And I do run an Open Source (not FOSS) project: the [Odin Programming Language](https://odin-lang.org/). If there was a possibility of actually selling a compiler nowadays, I would, but because the expected price of a compiler for a new language is now free, it makes that nigh impossible. You have to either rely on charity or companies that rely on the product to pay for support. I am grateful for the amount of bug reports, Pull Requests, and general usage of Odin. It is extremely surreal that I work with a [company](https://jangafx.com/) that uses my language for all of their [products](https://jangafx.com/software/elemental-suite), and I get paid to do it. Some of my time is spent working on the Odin compiler and Odin core library, but a lot of it is actually just working on the products themselves. And that's what I made Odin for in the first place: a language I could actually program to make things in—a means to an end; not an end into itself.

## Forced "Charity"

There does seem to be a common feeling of guilt programmers have that they should give their knowledge to the world freely. But why are they feeling guilty? Is that a correctly placed emotion? Is that even valid? And why should you give your knowledge and wisdom away for free? Just because you got it for free?

I could also add, but I am not going to make this argument in general, that FOSS is specifically "forcing charity" on others, which the act itself is not virtuous but vicious. This is why I assume the original poster is kind of saying this it similar to the "ideology of communism", if I am guessing. He is viewing that as the "forced charity" aspect of the "ideology". It is also a very specific conception of _charity_, the view that charity is free-as-in-beer rather than a virtue of the friendship of man (or in the traditional theological conception, "the friendship of man for God"). A lot of _charity_ is "free" but a lot is not. You can still be beneficial to others whilst making a profit. There is nothing intrinsically wrong about making a profit in-itself[^unless]. I'd trivially argue that people who release their source code when you pay for it when they don't have to are still being charitable. Yes it does have a monetary cost, but that does not mean it isn't a form of charity. But OSS/FOSS as a practice encourages, not forces, by telling people ought to work for free and give the services for free.

[^unless]: Unless you are of course a communist which views that it is, but that's a different discussion for a different day.

To be clear, my position on this topic is far from a common one, and I don't think it's a "[strawman](https://en.wikipedia.org/wiki/Straw_man)" by any stretch of the imagination. There are many "definitions" of what OSS and FOSS are, but I'd argue most are idealistic forms which are on the whole (except in certain instances) do not bring forth the ideals that they set out.

To use a common cybernetics phrase ([POSIWID](https://en.wikipedia.org/wiki/The_purpose_of_a_system_is_what_it_does)): **The purpose of a system is what it does**, and there is not point claiming that the purpose of a system is to do what it constantly fails to do.

----

## Sustainability

"Of course" you can hypothetically make money from OSS/FOSS but that doesn't mean it is either possible nor sustainable or even desirable. And I know this from first-hand experience. I am always grateful for all of the [donations received](https://github.com/sponsors/odin-lang) for the Odin programming language through people's act of charity, and all of that money does go towards the development of Odin. However, it's not a sustainable nor maintainable model—and I'd argue has never been nor could ever be. And for every purported exception to this rule, I'd try to argue none of them are because of the OSS/FOSS model and purely to the individual programmer/developer.

The OSS/FOSS dream is that, a dream that cannot live up to its "ideals". For every hypothetical benefit it has, it should be stated that it is a hypothesis and not a theory—theories require evidence to be classed as such. Most of the benefits and freedoms of OSS/FOSS are doubled-edge swords which are also huge attack vectors. Vectors for security, sustainability, maintainability, and redistribution. Most of the industry is based on blind-faith without anyway to verify that blind-trust.

Regardless of whether I am correctly or incorrectly "defining" OSS/FOSS to your preferred "definition", the multi-order effects are rarely considered. And to bastardize [Lysander Spooner](https://en.wikipedia.org/wiki/Lysander_Spooner):

> this much is certain—that it has either authorized such a tech oligarchy as we have had, or has been powerless to prevent it. In either case, it is unfit to exist [^spooner].

[^spooner]: The original quote: "But whether the Constitution really be one thing, or another, this much is certain—that it has either authorized such a government as we have had, or has been powerless to prevent it. In either case it is unfit to exist.” — Lysander Spooner, No Treason: The Constitution of No Authority.

## Ideals are not Principles

All of these lists of ideals of essential freedoms—and I'd argue they are not principles in the slightest—have not aided in anything in the long run. To use the [GNU's list](https://en.wikipedia.org/wiki/The_Free_Software_Definition#The_Four_Essential_Freedoms_of_Free_Software) for example:


#### The freedom to run the program as you wish, for any purpose (freedom 0).
* Assuming you can even run it in the first place.
* This statement is also kind of vague but I won't go into it too much.

#### The freedom to study how the program works, and change it so it does your computing as you wish (freedom 1). Access to the source code is a precondition for this.
* This is actually two "freedoms" combined together. The first is access to source code, and the second is that "secrets" should not exist (i.e. secret sauce/source).
* And why should that be free-as-in-beer **in practice**? I understand the "ideal" here is not suggesting it ought to be free-as-in-beer but that is end-result. And I'd argue the vast majority of FOSS advocates would say paying for source (i.e. Source Available) is not _Open Source_.
#### The freedom to redistribute copies so you can help others (freedom 2).
* Why?! Do we allow this for forms of intellectual property? If software is intellectual property, why is it different?
  * I know I've made the argument it is in a separate category, but if it is actually a form of intellectual property, then our legal systems do not and should not allow for this.
* This "freedom" is probably the most egregious with respect to the "ideology of communism" proclamation.
#### The freedom to distribute copies of your modified versions to others (freedom 3). By doing this, you can give the whole community a chance to benefit from your changes. Access to the source code is a precondition for this.
* This viral nature of licences like GPL are a fundamentally pernicious aspect of the FOSS (not necessarily OSS) movement. It's this idea of "forcing" charity on others.
* Of course you are "free" to not use the software, but if there are virtually no other options, you either have to write the thing yourself, or have the potential to have virtually no business model.
* This point is also an extension of (freedom 2) and as such, not helping the case.


As to my previous statement, none of these are _principles_. "Freedom 0" the foundation for the rest isn't even foundational. It pretty much relies on time preference between using pre-made software and home-made software. Software could be a service, but it's also, again, an implementation of an algorithm/idea. Of course I know these "ideals" only apply to _some_ FOSS advocates, and not necessarily any OSS advocates, but it's still the general perception of it.

## Conclusion

To conclude from this very unstructured brain-dump, I can understand the original sentiment that a lot of the mentality of advocating for OSS/FOSS is from a similar standpoint of the "ideology of communism", but I do not conceptualize it that way. I don't think OSS nor FOSS has been a good thing for software, and probably a huge acceleration towards why software has been getting worse over the years.