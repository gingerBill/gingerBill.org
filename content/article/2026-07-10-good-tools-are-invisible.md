---
{
    "title": "Good Tools Are Invisible",
    "slug": "good-tools-are-invisible",
    "author": "Ginger Bill",
    "date": "2026-07-10",
    "categories": [
        "tools",
        "tooling",
        "aesthetics",
        "ergonomics"
    ],
}
---

TL;DR: A good tool is and ought to be invisible—striving to make such tools is the goal of a toolmaker.

One habit I see a lot, and have to push back on, is taking a tool's shortcomings and reselling them as a "puzzle game" which is "fun" to solve.

I don't want my tools to be "fun". I want my tools to be _invisible_.

## Text Editor Wars

Let's take vim as an example[^applies-to-others]. I constantly see some people praise it not for what actually makes it good, but by taking the things it's bad at and turning them into a puzzle to have "fun" solving.

[^applies-to-others]: This is just an example, and applies to other editors too.

I've had people tell me how "fun" it was to build a macro to handle some one-off text-refactoring problem. But when I looked at what they were doing and how long it took, my honest reaction was: I could have done that in Sublime in a minute with multiple cursors, or just written a quick script.

To be clear, I'm not saying text editors don't matter to your workflow. I'm questioning the near-religious devotion people have to a tool because it gives them a "hacker vibe"—which is basically the whole appeal for newcomers to vim or emacs.

That's what I mean by "invisible tools". When you're proficient with your editor of choice—whatever it is—it disappears into the background. But the moment it cannot handle something easily, it stops being invisible. What baffles me is that so many people treat that friction—the effort of working around a tool's limitations—as the "fun" part, and then advertise it as evidence that the tool is great.

I know plenty of things wrong with my own editor of choice: Sublime. I don't dress those flaws up as fun little puzzles to solve. I just get annoyed that it lacks the tools I actually need, forcing me to write a plugin or reach for a separate program to write to transform text the way I want.

I've been using Sublime for 15 years now. It's my editor of choice for a few reasons: its shortcuts are a superset of the graphical OS environment (which minimizes the mental context-switch when moving between applications), multiple cursors really are better than macros 99.999% of the time[^macros] (since they give direct visual feedback), and it leaves me with the fewest "puzzles" to solve in my text-editing workflow. I've found something like vim to be better at basic editing but worse at bulk operations—and I don't mean grep-like operations—which is why I've stuck with Sublime for so long. I never found vim motions to be that much more productive than my Sublime workflow either, and that wasn't just down to lack of trying or familiarity[^lost]. And since I virtually never write code in a terminal, my need for a terminal-oriented editor is effectively nonexistent.

[^macros]: I think I've only "needed" a macro in Sublime twice in the past decade, and in both cases, setting up the macro took longer than if I just wrote a script to do the same thing.

[^lost]: To be honest, I have forgotten most of my "vim motions" knowledge over the years, because I don't regularly exercise it, nor do I need to.

If people find vim, emacs, or whatever genuinely good and productive, I'm not going to criticize them for using it. People are most comfortable with what they know. But for the people I am discussing, that same familiarity blinds them to their tools' flaws, and leads them to celebrate those flaws, flaunting them as _games_.

## Tools as an Identity

Part of why these debates turn religious is that a tool choice becomes a flag you plant—it says something about who you are. The "hacker vibe" isn't a _mere aesthetic_; it's tribal signaling, and that's the real trap. Once your identity is invested in a tool, admitting its flaws starts to feel like admitting something about yourself. So people don't just tolerate the flaws—they defend them, and eventually flaunt them. You cannot have an honest conversation about a tool with someone who's decided the tool is part of their personality.

## Feeling Productive versus being Productive

The text-editor-macro anecdote I mentioned is really about a gap between _feeling productive_ versus _being productive_. There's a sensation of cleverness that comes from solving a fiddly problem, and it's easy to mistake that feeling for actual output. A tool that makes hard things feel heroic and clever feel like an achievement can register as "powerful" while quietly being slow. The honest test isn't how engaged or clever you felt, it's wall-clock time and how many mistakes you made getting there. A lot of the tools people _evangelize_ would lose that test.

If productivity is actually the goal, actually question your own views on this, and try to see what makes you more productive. You will be surprised when you do.

## Terminal UIs vs GUIs

Another example in this same vein is when people advocate for terminal apps over GUIs. If you're stuck in a terminal all day, then I completely get the _obvious_ advantage, but most programmers aren't stuck in a terminal all day.

From those people who generally advocate for a TUI over a GUI, one of the criticisms of GUI apps tends to be: "I cannot navigate them with the keyboard alone".

Okay? That doesn't make GUI apps _inherently_ bad. It just means the GUIs people build aren't good enough to be keyboard-navigable. There's nothing inherently impossible about making a GUI navigable with a keyboard, rather it's just that most toolmakers never bother to implement, and usually because they don't realize how much more productive keyboard navigation is than reaching for the mouse a lot of the time. If the argument was that a specific TUI app is better than the other alternatives which are GUI based, then that is a fair argument, but arguing that TUIs are inherently better than GUIs is very misinformed.

And this is the common mistake: people look at the current state of a category of tools and assume its current limitations are inherent/essential, when really no one has put in the work to make those tools better.

## Linux's (Lack of) Popularity as a Desktop

The year of the Linux[^linux-is-a-kernel] desktop still isn't upon us (in 2026), and part of the reason why it has taken so long to get to that point is fundamental: a lot of the people who use Linux love fiddling with configuration files to reshape their system—it's their idea of "fun", their puzzle game.

[^linux-is-a-kernel]: I know I am going to get people saying "Linux is the Kernel, the OS is the [insert distro name]". I'm sorry but that's not how most people talk about Linux, and I don't really care too much for your pendantry which aids nothing. Especially since to critique it, you clearly had to understand what was being said about it.

I went through that phase myself. But after a while, I just wanted things to work. Spending hours (if not days) configuring everything isn't something I want to do any more. I want the defaults to be good and just work, and when I do need to tweak something minor, it should take seconds.

Maximal configurability shouldn't be a tool's goal, it should be an option for when it's actually necessary. Designing an ergonomic tool is fundamentally about having good defaults, while still allowing escape hatches where they're possible/needed.

The appeal of accidental[^define-accidental] complexity is something a lot of programmers/techy-folk love, giving them a weird sense of security.

[^define-accidental]: Characteristics that an object has contingently and can change without altering the object's _essential_ identity.

Having _good defaults_ is fundamentally a toolmaker's responsibility. We as toolmakers have a tendency to put the burden on the user: to configure it, to tweak it, to learn it. A lot of that burden is really a designer declining to make a decision. "Highly configurable" is often just an excuse for shipping no opinion at all and calling the resulting work your problem. Good defaults are a form of respect for the user's time: the toolmaker does the thinking once so a thousand users don't each have to. And part of designing a tool is to allow for some escape hatches tool; those escape hatches are there for the genuine minority who need something unusual; they should not be a substitute for getting the common case right.


## Steep Learning Curve as a "Feature"?

Another defence I've seen is that the difficulty is the whole point, it filters out the uncommitted, and once you're over the hump you're rewarded for life. But a learning curve is a cost, not a virtue. It could hypothetically be absolutely a cost worth paying, but the payoff has to be genuine productivity, not the satisfaction of having paid it. Too often the reasoning is just sunk-cost dressed up as merit: "I spent months learning this, so it must be worth it, and you should copy in my footsteps too". That's the puzzle game again, only now the puzzle is the tool itself.


## Conclusion

None of this is an argument against any particular tool. It's an argument against a way of thinking. Use vim, use emacs, use Sublime, but use whatever disappears into the background and lets you get on with the work. That is the whole test, and it's a personal one. What I'm pushing back on isn't the choice, it's the storytelling that grows up around the choice: the reframing of limitations as features, the effort of working around a flaw sold as the reward, the tool quietly promoted from the thing-you-use to the part-of-who-you-are.

The clearest sign a tool is serving you is that you stop noticing it—it becomes invisible. You don't celebrate its flaws because you're not turning them into a hobby, rather you just get mildly annoyed and route around them. You don't defend it because nothing about your identity is riding on it. And you don't mistake the feeling of cleverness for the fact of productivity, because you've bothered to check the difference.

So by all means, enjoy your tools, for the joy of programming itself. Just be honest about which parts are genuinely good and which parts you've talked yourself into loving. The best tool isn't the one with the best story. It's the one you forget you're using.

A good tool is and ought to be invisible—striving to make such tools is the goal of a toolmaker.