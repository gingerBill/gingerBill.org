---
{
	"title": "Free Software, Per Accidens",
	"slug": "free-software-per-accidens",
	"author": "Ginger Bill",
	"date": "2026-10-28",
	"categories": [
		"software",
		"philosophy",
		"oss",
		"foss",
		"open source",
		"free software"
	],
}
---

Recently I have been thinking now that LLMs/AI have made it relatively "simple" to decompile just about anything, doesn't that suggest many of the core "principled/idealistic" arguments for OSS/FOSS were never fundamental to begin with?

I know you don't get back what was actually written, especially with optimized binaries, but that gap keeps shrinking in terms of usefulness. From a philosophical standpoint, doesn't it show that many (not all) of the foundations of movements like FOSS (especially GNU) were _per accidens_[^per-accidens] rather than _per se_?

[^per-accidens]: *Per accidens* means _incidental_ (a product of circumstance), as opposed to *per se*, meaning essential, true by its very nature.

## Origin Stories

All of this makes me wonder how much of the FOSS movement was just post-hoc justification. Part of the origin story is Stallman being annoyed that he couldn't get the source for a Xerox printer to add a paper jam notification[^printer]. I completely sympathize with the frustration (I still have printer problems to this day), but the origin alone doesn't prove anything.

[^printer]: Sam Williams, [*Free as in Freedom: Richard Stallman's Crusade for Free Software*](https://oreilly.com/openbook/freedom/) (O'Reilly, 2002), chapter 1, "For Want of a Printer".

The other part of the origin story is Unix being locked behind expensive licences once AT&T could commercialize it. I'm not disputing any of that context. But being a response to circumstances doesn't make an argument per accidens; depending on those circumstances does.

## Open vs Free(dom)

Most of the framework of the Free Software Movement still assumes source code is hard to get or that binaries are hard to modify. GNU's [Freedom 1](https://www.gnu.org/philosophy/free-sw.html#make-changes) (study) even lists access to source as a precondition[^free-software-definition]. If anyone can recover readable code from a binary, in any language of their choosing, that precondition matters a lot less, and with LLMs/AI it's already close to being met.

[^free-software-definition]: GNU Project, ["What is Free Software?"](https://www.gnu.org/philosophy/free-sw.html) (The Free Software Definition). The same precondition is also listed for Freedom 3.

My argument is mostly about the open side of Free Software, which is really just [Freedom 1](https://www.gnu.org/philosophy/free-sw.html#make-changes), the freedom to study and change a program. [Freedom 0](https://www.gnu.org/philosophy/free-sw.html#run-the-program) (run it for any purpose) is a pure permission, as are [Freedoms 2 and 3](https://www.gnu.org/philosophy/free-sw.html#redistribute) (share copies and modified versions); GNU even says Freedom 0 has nothing to do with whether a program is "technically capable of functioning in any given environment".

GNU lists access to source as a precondition for both Freedom 1 and Freedom 3, but my point about decompilation only changes one of them: it gives you the ability to study and modify a program, not the permission to distribute the result. Which means in both cases, source access is per accidens, and the permission is what's per se. If anything, I think the heart of the Free Software Movement was always the permission to share (Freedoms 2 and 3), and never really the source.

The obvious objection is that the [four freedoms](https://www.gnu.org/philosophy/free-sw.html#four-freedoms) are permissions, not capabilities: being *able* to decompile something doesn't mean you're *allowed* to. I agree, but I'm not arguing about the _permission_. I'm arguing about the technical premise GNU attached to it: "Access to the source code is a precondition for this". [Freedom 1](https://www.gnu.org/philosophy/free-sw.html#make-changes) is really two claims bundled together: that you need access to the source, and that there shouldn't be any secrets in the first place. And "cheap" decompilation takes care of the first, because that part was always per accidens. The second is the actual moral claim, and that's the one I actually disagree with.

To be clear, I'm not claiming decompiled code is as good as the original source. The GPL even defines source as "the preferred form of the work for making modifications to it"[^gpl-source], and the original is virtually always preferred over a decompilation[^decompilation-exception]. But a preference is not a precondition. A precondition is something you can't do without, and the lack of source never strictly prevented anything; it just made it expensive. People were decompiling entire programs by hand long before LLMs: [Super Mario 64 was decompiled](https://github.com/n64decomp/sm64) by hand back into C that compiles to a byte-identical ROM, which is what then made the native PC ports possible; what LLMs/AI change is the cost of this process. Even if the original source has extra information (e.g. comments and names), decompiling with tools like [Ghidra](https://ghidra-sre.org/) + LLMs has made the whole process a heck of a lot simpler (for personal use). It's still harder and messier than having the original source, but it's possible, which makes source access a convenience rather than a requirement.

[^decompilation-exception]: Except when you want it in a different language, or the original source wasn't readable to begin with. Most open source code is hard to read, so even with the original source, you're still doing your own decompilation, from text to text.

[^gpl-source]: [GNU General Public License, version 3](https://www.gnu.org/licenses/gpl-3.0.html), section 1, "Source Code". GPLv2 uses the same wording in section 3.

And "preferred" is already a matter of degree. Original source, decompiled code, disassembly, and the raw binary are all points on the same gradient. Some things (build scripts, or code behind `#ifdef`s for other platforms) aren't in the binary at all, so you'd have to recreate them rather than read them, but that's a difference in effort. And if decompilation makes auditing possible without the source, then the source itself isn't doing the essential work.

## Source Was Never a Guarantee

Even with the source, you could never really know what was running on a remote server. And even locally, Thompson's "Reflections on Trusting Trust"[^trusting-trust] showed you can't fully trust code you compiled yourself.

[^trusting-trust]: Ken Thompson, ["Reflections on Trusting Trust"](http://doi.acm.org/10.1145/358198.358210), *Communications of the ACM* 27(8), August 1984, pp. 761–763. Originally his Turing Award lecture.

The FSF knows both of these: the AGPL exists for the server case[^agpl] (though few projects use it, and many companies refuse to touch AGPL code at all; Google bans it outright[^google-agpl]), and from what I've discussed with others, the answers to Thompson are reproducible builds and diverse double-compiling[^ddc], both of which need the source. It does kind of make source necessary for those "solutions", but they are not sufficient, and very few people actually run them; in practice you're still trusting someone else's build. And even in those cases, you still need to trust the bootstrapping stage. There is always a place where you just have to "trust". And sadly, that means source alone can't be the guarantee; at best, it's a mere convenience.

[^agpl]: [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.html), which requires offering the source to users who interact with the software over a network.

[^google-agpl]: Google's [AGPL Policy](https://opensource.google/documentation/reference/using/agpl-policy): code licensed under the AGPL "MUST NOT be used at Google".

[^ddc]: David A. Wheeler, ["Fully Countering Trusting Trust through Diverse Double-Compiling"](https://dwheeler.com/trusting-trust/), PhD dissertation, George Mason University, 2009. See also [Reproducible Builds](https://reproducible-builds.org/).

The FSF would say source isn't about trust at all but about control: without it, the program controls the user. But control is a gradient too, for the same reason trust is. Source, reproducible builds, inspecting the binary, decompiling it: none of these is a guarantee, and each gives you some control over what runs on your machine. The FSF draws a categorical line at one point on that gradient, and my question is why that point?---especially now that the other points keep getting cheaper. Yes, the strongest checks need the source, which makes it the best point on the gradient, but still only a point on it.

## Open Source Is Not a Business Model

If the technical case for source access is mostly per accidens, the pragmatic case has to carry the weight, and pragmatically, open source has a funding problem.

[Eric S. Raymond](http://www.catb.org/~esr/), who wrote down much of the original "theory" of _open source_[^cathedral-and-bazaar], in my opinion made an engineering argument rather than a moral one: "given enough eyeballs, all bugs are shallow". In a way, that's the main distinction between open source and Free Software. But more eyeballs only make bugs more likely to be found, not certain to be: Heartbleed sat in OpenSSL, one of the most widely used libraries around, for about two years before anyone noticed[^heartbleed]. And not to mention, eyeballs aren't free. Reliability and reusability do not come from merely having source availability; they come from people being paid to maintain and improve the software---an actual incentive. Unfortunately, that is not the _reality_ of open source.

[^cathedral-and-bazaar]: Eric S. Raymond, [*The Cathedral and the Bazaar*](http://www.catb.org/~esr/writings/cathedral-bazaar/) (O'Reilly, 1999).
[^heartbleed]: ["The Heartbleed Bug"](https://heartbleed.com/). It shipped in OpenSSL 1.0.1 in March 2012 and was disclosed in April 2014.

To be clear, the distinction I'm drawing between Free and **open** is about motivations and business logic, not licences. The licences mostly overlap, and even GNU says "nearly all open source software is free software"[^misses-the-point].

[^misses-the-point]: GNU Project, ["Why Open Source Misses the Point of Free Software"](https://www.gnu.org/philosophy/open-source-misses-the-point.html).

Personally, I think **open** source is antithetical to "selling software" as a business. Most open source projects can't really make money from the software itself, so in practice they're effectively charities. **Open** source was never "free as in beer" or even "free as in freedom". It has always been "free as in puppy": free to get, but the maintenance cost falls on the users as well as the people who made it[^free-as-in-puppy].

[^free-as-in-puppy]: The origin of the phrase is disputed. From what I can tell, it has been attributed to Sun's Scott McNealy, and Nadia Eghbal's *Working in Public: The Making and Maintenance of Open Source Software* (Stripe Press, 2020) quotes Bootstrap co-creator Jacob Thornton using it. So I have no idea of the actual origin.

For context, I've run multiple open source projects for over a decade, the largest being the [Odin](https://odin-lang.org/) compiler. However, I'd never license any of them under the GPL or want to run anything under it. If I want something open, I want it permissive, not viral. Both the Odin compiler and its core library are under the [zlib licence](https://zlib.net/zlib_license.html), which is effectively one step above public domain[^public-domain-zlib].

[^public-domain-zlib]: Public domain isn't legally recognized everywhere, so zlib is about as close as you can get, as well as a few other similar licences.

Odin itself is free precisely because you can't really sell a compiler anymore: the expected price of a compiler nowadays is zero. Even Intel gave up and made its compilers free. The compilers you can still pay for either have decades of precedent behind them, and thus the inertia (e.g. [IAR](https://www.iar.com/) and [Green Hills](https://www.ghs.com/) in embedded, or [Matlab](https://www.mathworks.com/products/matlab.html) and [Mathematica](https://www.wolfram.com/mathematica/) in the sciences), or they aren't really sold as compilers at all but as entire suites (IDE, debugger, profiler, certification, support), which do far more than a mere language and its core library. And I'd sell Odin if I could, because profit is what pays for making it better. Making a living is not a vice.

And if the authors have no funding, what incentive do they have to keep improving it, the way any business would, other than the kindness of their hearts? To be clear, this isn't a criticism of permissive licences (I am a user of them), rather neither permissive nor copyleft licensing is a business model in itself.

Most of the open source projects I've dealt with aren't actually good in the slightest, because the people developing them have had no incentive to make them better[^roads-and-bridges]. They're effectively charities, and even the popular ones are. Blender is one of the most popular open source projects around, and it's paid for by donations to the Blender Development Fund from thousands of individuals and dozens of companies, such as NVIDIA and Netflix[^blender-fund], and at the end of the day, that's still charity even if it's just at scale. A profit motive isn't a bad thing at all[^adam-smith]; prices are just a signal mechanism, and they're what allow for rational calculation in the first place[^hayek][^sowell]; without those signals, you're kind of just screwed.

[^roads-and-bridges]: Nadia Eghbal, [*Roads and Bridges: The Unseen Labor Behind Our Digital Infrastructure*](https://www.fordfoundation.org/work/learning/research-reports/roads-and-bridges-the-unseen-labor-behind-our-digital-infrastructure/) (Ford Foundation, 2016), which covers underfunded projects like OpenSSL and the Heartbleed bug.

[^blender-fund]: The [Blender Development Fund](https://fund.blender.org/). At the time of writing, around €280,000 a month from roughly 7,600 individuals and 46 corporate members.

[^adam-smith]: Adam Smith, [*The Wealth of Nations*](https://www.gutenberg.org/ebooks/3300) (1776), on self-interest rather than benevolence.

[^hayek]: F. A. Hayek, ["The Use of Knowledge in Society"](https://www.econlib.org/library/Essays/hykKnw.html), *American Economic Review*, 1945, on prices as signals.

[^sowell]: Thomas Sowell, *Knowledge and Decisions* (1980), an accessible treatment of prices as information.

The usual objection is that money corrupts priorities: managers reward adding features, never removing them, and so commercial software bloats. That does happen, but it's an organisational problem, not a money problem. It's just Conway's law: a system's design ends up copying the communication structure of the organisation that built it[^conways-law][^unbreakable-law]. And open source isn't immune to any of this either. A feature is far easier to get merged than a removal. And (unfortunately) most large open source projects are funded by the same huge corporations, with the same performance reviews. At least when customers can leave (assuming an alternative exists), bloat costs you something.

[^conways-law]: Melvin E. Conway, ["How Do Committees Invent?"](http://www.melconway.com/Home/Committees_Paper.html), *Datamation*, April 1968.
[^unbreakable-law]: Casey Muratori, ["The Only Unbreakable Law"](https://www.youtube.com/watch?v=5IUj1EZwpJY), a talk on Conway's law and why it can't be avoided.

Those same corporations are behind most of the big successful (non-copyleft) **open** source projects, done in "goodwill" because they can afford to be "kind". And I'd easily argue that a lot of the time it isn't kindness at all, but a way to undercut commercial competition and dominate a market, simply because they can afford to give it away.

And the companies that did try to build a business directly on open source show it best. When the "open source companies" of the last decade (MongoDB, Elastic, HashiCorp, and Redis) needed revenue, they all moved to source-available licences, mostly to stop cloud providers selling their own work back to their customers[^relicensing]. Open source was the marketing, not the business model, because it can't sustain one.

[^relicensing]: [MongoDB](https://www.mongodb.com/press/mongodb-issues-new-server-side-public-license-for-mongodb-community-server) moved from the AGPL to the SSPL in 2018, [Elastic](https://www.elastic.co/blog/licensing-change) from Apache 2.0 to the SSPL and Elastic License in 2021, [HashiCorp](https://www.hashicorp.com/en/blog/hashicorp-adopts-business-source-license) from the MPL to the BSL in 2023, and [Redis](https://redis.io/blog/redis-adopts-dual-source-available-licensing/) from BSD to the RSAL and SSPL in 2024. [Elastic](https://www.elastic.co/blog/elasticsearch-is-open-source-again) and [Redis](https://redis.io/blog/agplv3/) later added the AGPL back as an option.

## The Exceptions That Prove the Rule

Linux is effectively the canonical exception, since much of it is written by developers paid by companies that depend on it. But I'd argue that's because of the sheer scale of building a kernel/OS, not anything inherent to the GPL. The usual counter I have seen is that the GPL is precisely *why* those companies cooperate: none of them can take the shared work private, meaning contributing is safe. There's some truth to that, but permissively licensed projects like LLVM[^no-love-llvm] get the same kind of corporate cooperation without it, so the GPL isn't necessary for it.

And even Linux doesn't follow the FSF's intent. Linus kept it on GPLv2 because it only asks for "tit-for-tat", which he called "totally independent of any moral judgement"[^ode-to-gplv2], and he objected to GPLv3's anti-Tivoization clause, the requirement to let users run modified versions on the device itself. That's why vendors can still lock down the devices Linux ships in. It's an engineering argument for sharing code, not the FSF's moral one.

[^ode-to-gplv2]: Linus Torvalds, ["An Ode to GPLv2"](https://lkml.iu.edu/hypermail/linux/kernel/0609.3/0248.html), Linux kernel mailing list, September 2006.

[^no-love-llvm]: As people who know me know, I have no love for LLVM whatsoever, and it has been the bane of my existence for over a decade now.

The same pattern shows up in the other big GPL successes: GCC succeeded through scale too, and WordPress makes its money through other means[^wordpress-money]. GCC also helped make everyone expect a compiler to cost nothing, which effectively killed an entire software business model for many people. Its main competitors, Clang and MSVC, are backed by Apple and Microsoft, who can afford to give them away.

[^wordpress-money]: WordPress makes its money from everything around the code: Automattic sells hosting (WordPress.com and enterprise hosting) and WooCommerce extensions, and the premium plugin and theme market really sells updates and support.

MySQL, Qt, and wolfSSL are the interesting cases, since they make money through dual licensing: selling a proprietary licence to anyone who doesn't want the GPL's terms. These are business models which seem to depend on copyleft, but look at what's actually being sold: an exemption from the GPL. Nobody pays to escape a zlib licence. The GPL is the "stick" and the non-free licence is the product. And even that didn't keep MySQL independent: Sun bought it in 2008, and it came to Oracle along with Sun in 2010. Oracle makes its money through other means, not least its own proprietary database. In other words, the GPL's successes are _per accidens_ as well, not _per se_.

## Copyleft Needs Copyright

Red Hat is one of the rare companies to build a sustainable business on GPL software, mainly because of when they started and because what customers really pay for is the support, certification, and enterprise trust, not the code. And even then, RHEL isn't really **open**. It's closer to source-available on purchase, since they limit the source to paying customers and use their subscription terms to discourage redistribution[^centos-stream][^the-register]. I'd argue this is effectively a loophole around the GPL, since the GPL lets anyone who receives the source redistribute it, which normally makes selling it hard to sustain. Whether those terms actually comply with the GPL is disputed. Like MySQL, Red Hat sells something the GPL leaves room for, in their case support, certification, and controlled access to the source; neither generalizes into a business model for software as a whole.

[^centos-stream]: Mike McGrath, ["Furthering the evolution of CentOS Stream"](https://www.redhat.com/en/blog/furthering-evolution-centos-stream), Red Hat blog, June 2023. It made CentOS Stream the sole public source for RHEL-related code, with RHEL sources available to customers under their subscription agreements.
[^the-register]: [The Register's coverage](https://www.theregister.com/2023/06/23/red_hat_centos_move/) of Red Hat's source change, June 2023.

And in many ways, it also shows the movement doesn't really _subvert_ IP. In GNU's own words, copyleft "uses copyright law, but flips it over to serve the opposite of its usual purpose"[^copyleft]. But RHEL shows how easily that flip is undone. The GPL only works because copyright exists (as do permissive licences, of course), and Red Hat simply layers contracts on top to stop people redistributing source they legally received. So copyleft doesn't escape IP; it depends on it, and loses to the very same legal tools.

[^copyleft]: Richard Stallman, ["The GNU Project"](https://www.gnu.org/gnu/thegnuproject.html), "Copyleft and the GNU GPL". See also GNU's ["What is Copyleft?"](https://www.gnu.org/copyleft/copyleft.html).

Many (not all) Free Software advocates are anti-IP, and would happily see copyright, and copyleft with it, abolished. But without copyright, [Freedoms 2 and 3](https://www.gnu.org/philosophy/free-sw.html#redistribute) are only worth whatever you can get your hands on, because nothing forces anyone to hand over the source. Businesses would fall back on trade secrets, contracts, and DRM, which is exactly what I expect them to do anyway. And that's not a rare fallback: the vast majority of businesses already work this way. A recipe, a manufacturing process, a customer list, or just knowing how to do something others don't, is what most businesses are built on, not copyright. Software is no different.

To be clear, I'm not advocating for abolishing IP. Parts of it are flawed ([software patents](https://caseymuratori.com/blog_0027) especially), but it exists for a reason: it protects the work and investment that went into making something---so that it's worth making in the first place. Take it away and that protection doesn't disappear; it just moves into secrecy, contracts, and DRM.

## What I Expect to Happen

If decompilation keeps getting easier, I do expect the industry to respond in a few ways:

- Hardware DRM that protects binaries and process memory from even being read.
- More use of kernel-level DRM, similar to anti-cheat software.
- A legal hellscape where everyone is suing everyone all the time.

Unfortunately, I expect all of them to happen. I am very conflicted about this, because it's very similar to the idea behind signed binaries and TPMs, which end up becoming "we decide what software will run on your machine". I know it doesn't have to be like that at all, but it could be.

Some will say this proves the FSF right all along, since this is exactly the lockdown they've warned about[^right-to-read][^trust-your-computer]. But predicting an outcome isn't the same as being right about its cause. The FSF movement is effectively anti-trade-secret to begin with. In their view, if you distribute software in any form, even compiled and obfuscated, the source should be shared with the world. Their reasoning is about control: without the source, the user doesn't control the program, the program controls the user. But "trivial" decompilation now gives you most of that control without the source, so what's left of the demand is simply that a secret must not stay a secret. And a lot of businesses, especially small ones, exist precisely because of their trade secrets, so why the heck should they ever release any of that?

[^right-to-read]: Richard Stallman, ["The Right to Read"](https://www.gnu.org/philosophy/right-to-read.html), *Communications of the ACM*, February 1997.
[^trust-your-computer]: Richard Stallman, ["Can You Trust Your Computer?"](https://www.gnu.org/philosophy/can-you-trust) (2002), on "treacherous computing".

Compiled binaries used to be a cheap form of protection. If decompilation removes that, companies won't go the FSF route. They'll reach for the expensive forms instead: hardware, kernel-level DRM, and lawyers, and the FSF's dream wouldn't be any better. If in this "future" all software had to be free, most of it would be the charity I described above, with little incentive to improve. Either way, it would be a dark age for software.

But there is another option, and it isn't a new idea: stay closed, but make the closed version worth paying for. Piracy has always been a problem, and decompilation only makes it easier. Yet Steam and Netflix are both closed source, and they made piracy matter a lot less not by opening up, nor by locking things down harder, but by being more convenient than the pirates. As Gabe Newell put it:

> Piracy is almost always a service problem and not a pricing problem. <footer>Gabe Newell, interviewed by *The Cambridge Student*, November 2011, as reported by [MCV](https://mcvuk.com/business-news/consoles/newell-piracy-is-a-non-issue-for-valve/).</footer>

Neither Steam nor Netflix would ever open up the software their business runs on (the Steam client and store, or Netflix's apps and recommendations), even though both happily open source the parts that aren't their business. That software _is_ the business; the service is what makes paying for it easier than pirating it.

And yes, this means the ability to decompile is contingent too: it lasts only as long as hardware and law allow it, but that's my point. None of the technical conditions, source, or binary, were ever per se. The real question is who draws the line: hardware vendors, the FSF's demand that all source be shared, or ordinary markets and contracts. Personally I usually prefer to pick the last one. Paid, closed software with clear legal terms protects a company's work without locking down your machine, and it gives developers a price signal and a reason/incentive to keep improving the software.

The FSF route turns software into a form of forced-charity, and the hardware vendors' route turns your computer into someone else's. Paid closed software with clear legal terms is the least bad option, and we should stop treating it as if it was the villain.

## Conclusion

LLMs have made decompilation a lot simpler. I'm not saying that makes Free Software necessarily wrong, but it does show which parts of it were per accidens. The technical premise behind GNU's Freedom 1 (that you need the source to study or change a program) was always about cost and never a principle.

What remains as _per se_ are Freedoms 2 and 3 (the permission to share copies and modified versions) and the moral claim that software shouldn't have secrets, but neither of these points is technical. The first is a question of copyright, which copyleft depends on as much as anything proprietary does; the second is a claim against trade secrets, which is what most businesses are built on. I don't think either aspect holds up in the reality of business.

Open source was never a business model in the first place. If decompilation makes binaries a weaker protection, the answer isn't to give everything away, but to make the closed thing worth paying for, or keep it on a server where it never leaves your hands.

The "essential" arguments for OSS/FOSS/Free-Software might be a lot smaller than even their advocates realized.
