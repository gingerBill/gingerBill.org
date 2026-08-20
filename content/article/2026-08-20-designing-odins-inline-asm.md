---
{
    "title": "Everyone Says Assembly Is Untyped—Everyone Is Wrong",
    "slug": "designing-odins-inline-asm",
    "author": "Ginger Bill",
    "date": "2026-08-20",
    "categories": [
        "tools",
        "tooling",
        "assembly",
        "assembler",
        "syntax",
        "aesthetics",
        "ergonomics",
        "programming language theory",
        "programming languages"
    ],
     series: [
        "Syntax and how it Matters",
    ],
}
---


**TL;DR:** I believe Odin's inline assembles is currently the best out of any language.

The most important aspects are of this article listed below. I am not aware of any other assembly (GCC/Clang/Rust/Go...) that would combine all of these aspects:

* Inline assembly is organized into `asm` "templates", similar to and callable as procedures.
* `asm` templates integrate with rest of the code, through bindings specifying clobbers, pinned, tied, and scratch registers.
* Assembly syntax is unified across ISAs and consistent with Odin syntax.
* Assembly is fully type checked, just like rest of Odin code.
* Understanding that assembly is actually typed.
* Real semantic diagnostics via [`core:rexcode`](https://github.com/odin-lang/Odin/tree/master/core/rexcode) encoding tables.
* It was built in ~7 days.

--------

I have been asked why [Odin](https://odin-lang.org/) even bothers having its own [custom inline assembler](https://odin-lang.org/docs/inline-asm/) at all. Isn't inline assembly a solved problem? You take a string, you hand it to the assembler, and you let it sort out the rest. Everyone from GCC to Clang to Rust[^rust-asm] does more or less this. The wheel has been invented, right?

[^rust-asm]: Rust's [inline assembly](https://doc.rust-lang.org/reference/inline-assembly.html) is a little more sophisticated because of the macro system, but not that much more.

This is precisely the design I did *not* want, and precisely the design that most languages have settled for. My goal from the beginning was an inline assembler that actually *integrates* with the rest of the language rather than feeling bolted on the side. And I honestly believe that what Odin has ended up with is the best inline assembly system in any language right now. I don't say that lightly, and by the end of this article I hope you'll at least understand why I believe that to be true.


## The String-Based Nonsense

Let's start with the thing I was reacting against. Here is what a trivial "add one" looks like in GCC-style extended `asm` using x86 AT&T/GAS syntax:

```c
int dst;
asm ("movl %1, %0\n\t"
     "addl $1, %0"
     : "=r" (dst) // outputs
     : "r"  (src) // inputs
     : /* clobbers */);
```

Look at this and ask yourself: what does the *compiler* (as opposed to the *assembler*) understand here? The answer is "almost nothing". The body is a string. `"=r"` and `"r"` are *explicit* constraint strings, another little stringly-typed [DSL](https://en.wikipedia.org/wiki/Domain-specific_language) glued to the side of the real DSL. The `%0` and `%1` are positional references into a list you have to count by hand. And if you get any of it wrong, the error you get back is not from the compiler that knows your types and semantics; it is from the assembler, much later on, pointing at generated text that was not written by you.

This is the sort of thing that happens when a *feature* is designed as an *escape-hatch* first rather than as a *part of the language*. Nobody seems to have sat down and asked "what would inline assembly look like if it respected the type system, the calling conventions, the constant system, and other things (like multiple-return-value semantics) of the host language?". Rather, they asked "how do I bodge some assembly into this function with the least amount of compiler work?", and a string was the answer.

These kinds of inline assemblers ignore all of the aspects of the host language, and just bodge it in. I didn't; I designed one from scratch.

## A Brief History of Bolting It On

Strings are not the only way this has been done, and it is worth looking at what previous languages/compilers have done, because some of these approaches are a heck of a lot better than what GCC/Clang did, and unfortunately this development has stopped in compiler space.

### MSVC

Microsoft's C compilers had a genuinely different approach. MSVC's [`__asm` was *statement-based*](https://learn.microsoft.com/en-us/cpp/assembler/inline/asm?view=msvc-170), not string-based. You wrote a block of real instructions, and (this is the good part) you referenced your C variables and labels directly by name, and the compiler resolved them for you:

```c
int add_one(int x) {
    __asm {
        mov eax, x // 'x' is the C parameter, resolved by the compiler
        inc eax
    }              // value left in eax is the return value, by convention
}
```

No constraint strings. No `%0`. No counting operands. Compared to the GCC contraption this is honestly pleasant to read, and for a long time it was how an enormous amount of Windows systems code got written. So why did it disappear?

Firstly, it was **x86-only**. When Microsoft moved to x64 (and later ARM64) they did not port it. The official guidance became "use compiler intrinsics, or write a separate `.asm` file and run it through MASM". One of the stated constraints for the x64 compiler was to have *no* inline assembler at all. A whole approach was thrown away at the ISA boundary rather than generalized across it.

Secondly, even where it existed, the compiler did not really *understand* the block. It resolved your symbol names, but it carried no explicit clobber information; the optimizer largely treated the region as an opaque fence to be conservative around. It knew what `x` was. It did not give any feedback to the user as to what the instructions *did*.

### Turbo Pascal

If you go back further, you'll find Turbo Pascal, which I have an obvious fondness for, as I do for Pascals in general. For its inline assembly, it had *two* mechanisms, and together they bracket the entire design space quite nicely.

The first mechanism was the `inline` directive, and it is the purest possible statement of "the compiler understands nothing". You gave it machine code as a sequence of numeric constants—actual opcodes, as bytes:

```pascal
procedure Cli;  inline($FA);       { $FA = the CLI instruction }
procedure Nops; inline($90/$90);   { two NOP bytes }
```

That is not an assembler. This is *you* being the assembler, by hand, with the compiler faithfully copying your bytes into the stream. It is the ur-escape-hatch[^odin-byte-directive].

[^odin-byte-directive]: Odin keeps this exact capability as the `#byte` directive, but as *one directive among many* inside a checked template, not as the entire interface.

The second mechanism, which was added in [Turbo Pascal 6.0](https://www.scribd.com/document/550270834/Turbo-Pascal-Version-6-0-Users-Guide-1990), was the built-in assembler: the `asm ... end` block and the `assembler` procedure directive. This approach is much better as it has real mnemonics, and, like MSVC after it, you could name your Pascal variables and parameters directly:

```pascal
function AddOne(X: Word): Word; assembler;
asm
    mov ax, X    { 'X' is the Pascal parameter }
    inc ax       { result returned in AX }
end;
```

For 1990, this seems really lovely[^before-my-time], and arguably ahead of where current C compilers eventually landed. But because of its time period, the built-in assembler only ever understood up to 80286 instructions, so the day you wanted a 386 and its 32-bit registers you were sent off to an external assembler anyway.

[^before-my-time]: This is before my time as I was not even born yet.

Bolted on, and then bolted shut.

MSVC and Turbo Pascal were both better in their instinctual design compared to that of GCC, especially with the dumb constraint strings. However, both of them stopped at exactly the same place: they resolved your identifiers but never modelled the instructions—not the operand types, only limited checking on immediate ranges, no control over what got clobbered or what needed to be pinned. GCC threw away their design and forgot the aspect of letting the assembly speak for itself in its own language.

There was no conception that there is actually a type system underneath which could be generalized for the assembly. Which is the whole point of the Odin design, and it is what the rest of this article is about.

## Assembly Is Not Untyped

There is a very common belief that assembly is "untyped", and that inline assembly is therefore inherently an anything-goes affair. This isn't true, and getting past it is the single most important idea in the whole design of a universalized inline assembler.

I've [written before](https://www.gingerbill.org/article/2021/03/07/untyped-types/) about "untyped types" in the context of Odin, but those are actually [existential types](https://wiki.haskell.org/Existential_type). Conventionally, "untyped" effectively means everything is "opaque" and very weak (e.g. everything is just an int and you just assume it everywhere). Assembly is usually considered the perfect example of such an "untyped" language.

However, every instruction has a set of valid forms. Each form dictates the *kind* of each operand (register, memory, immediate, label), the *class* of each register (general-purpose, vector, mask), the *width* of each operand, the range each immediate may take, and what the instruction *clobbers* (flags, memory, particular registers). In x86, a `mulps` wants a 128-bit vector register; a `crc32` in one of its forms wants a 32-bit destination and an 8-bit memory source; `div` reads and writes `rdx:rax` whether you like it or not.

That is not the absence of a type system: that *is* a type system; a rather rich, dependent, per-instruction one. Assembly is effectively a polyadic typed algebra that everyone has agreed to pretend is a soup of bytes. Once you understand this, the design question stops being "how do I smuggle a string past the compiler?" and becomes "how do I express this algebra in the language's own terms?". And it turns out Odin already had most of the pieces lying around.

## One Syntax, Many ISAs

The first decision was the surrounding syntax. Not the mnemonics—obviously `mov` on AMD64 has nothing to say to `ldr` on arm64—but everything *around* the mnemonics: how you declare operands, how you reference registers, how you write a memory address, how you spell a label, etc.

Here I took the same lesson that [Plan 9](https://9p.io/sys/doc/asm.html) (and later [Go](https://go.dev/doc/asm)) took: pick *one* syntax and keep it consistent across every target. [Ken Thompson](https://en.wikipedia.org/wiki/Ken_Thompson)'s toolchain did this, which Go inherited, and it is genuinely nice to only have to learn the shape of the thing once. Go's assembly does have its issues (and inconsistencies), but the general idea is brilliant.

Odin itself has a context-free grammar, so for Odin's inline assembly, I wanted it to have a context-free grammar too, with the general form:

```
instruction [operand{, operand}]
```

The same grammar everywhere. The instruction has to be a valid Odin identifier or keyword. Explicit physical registers always take a `%` sigil (`%rax`, `%xmm0`, `%al`), which keeps them from colliding with your own parameter names and with any global constants from the parent scope. Parameter and scratch names are always bare (because the compiler understands the semantics). Memory operands are always Intel-style effective addresses (`[base + index*scale + disp]`). Labels are always `.name`. You learn this shape once and it carries to every ISA we ever add, even though the instructions underneath are completely different. It uses the same set of tokens as Odin: number-literals, comments, even the semicolon insertion rules.

This is the same principle I keep coming back to: **coherency over consistency**. Odin is coherent with *itself*, not GAS, NASM, or any platform's traditional assembler. This is Odin's inline assembler, nothing else.

## Intel Order, Not AT&T

There is a decision buried in that last section that deserves to be dragged into the light, because it is the one people argue about most: the body uses **Intel operand order**—destination first, `dst, src`—together with Intel-style (but slightly different) memory addressing, rather than the AT&T/GAS conventions.

It is a place where I *departed* from Plan 9 and Go, even while stealing their best idea. Plan 9's and Go's assembler writes operands source-first, left-to-right in dataflow order[^go-not-consistent], so `MOVQ $0, AX` clears `AX` with the destination on the *right*. That is the same operand order as AT&T, and the opposite of Intel. I took the one-grammar-for-every-ISA philosophy from them wholesale, but I did not want to take their operand order. It might sound like an arbitrary choice, but it isn't.

[^go-not-consistent]: Go isn't completely consistent with other conventions. Some of the ordering of the operands is just not consistent with other AT&T assemblers. Lovely, right? /s

The first reason is pure coherence with the rest of Odin. `mov dst, src` reads as `dst = src`. The destination sits on the left, exactly where the assignment target lives in every other line of Odin you will ever write: `x = y`, `x := y`, `name: type = value`[^casting-syntax]. AT&T's `movl %src, %dst` runs the dataflow backwards relative to every assignment in the language surrounding it. When you are reading a template embedded in ordinary Odin code, you should not have to flip your mental model of which way the arrow points halfway down a procedure.
[^casting-syntax]: I made [the same argument about casting](https://www.gingerbill.org/article/2026/02/23/designing-odins-casting-syntax/) where the type belongs on the left because that is how declarations read.

The second reason is the one that matters for a *universal* syntax specifically: destination-first is not an Intel quirk, it is the **majority convention across ISAs**. ARM writes `add r0, r1, r2` (destination first). RISC-V writes `add rd, rs1, rs2` (destination first). MIPS documentation does the same. Source-first ordering is really the parochial one. The x86/GAS tradition was inherited from the DEC and PDP-11 lineage.

If your entire goal is a syntax that reads the same on every target, you should pick the convention most of those targets *already* use in their own assemblers, not the one peculiar to a single toolchain's history. Plan 9, somewhat ironically, picked the parochial ordering because of its lineage.

The rest of the AT&T baggage falls away for related reasons:

### Memory Operands

AT&T writes `disp(base, index, scale)`, positional slots you simply have to memorize. Intel writes `[base + index*scale + disp]`, which reads as the address arithmetic it actually *is*. Odin uses the latter, and it extends cleanly to the forms other targets need, like `[base + index<<scale]`, or `[base + index>>scale]` on arm64.

### Operand Size

AT&T bakes the width into the mnemonic (`movb`, `movw`, `movl`, `movq`). Odin does not need to, because the operands are *typed*, the size comes from the parameter's type, and where no register pins it, from an explicit `[%rax]:u8` annotation[^intel-type-memory]. The type system already carries the information AT&T smears across the numerous different spellings of `mov`.

[^intel-type-memory]: Intel's syntax is to prefix the memory operand with `byte`, `word`, `dword`, or `qword`, but Odin's just uses the Odin type system directly.

### Sigils

AT&T decorates *every* register with `%` and *every* immediate with `$`, unconditionally. Odin's `%` looks superficially similar but is doing a completely different job: it appears only on explicit *physical* registers, and only to keep them from colliding with the namespace of the user-provided parameters and scratch names. In an idiomatic template you write bare names (e.g. `foo`, `acc`, `i`) and reach for `%rax` only when you genuinely need to pin one or refer to the register directly. The sigil marks the exception; it is not blanket decoration smeared over the common case.

Put the two styles beside each other and the difference in *readability* is not subtle. First the AT&T/GAS form:

```
movl %eax, %ebx             # ebx = eax   (source is on the LEFT)
addl $1, %ebx               # ebx += 1
movl 8(%rdi,%rsi,4), %ecx   # ecx = *(rdi + rsi*4 + 8)
```

and the same three instructions in Odin's Intel order:

```odin
mov  %ebx, %eax              // ebx = eax   (destination is on the LEFT)
add  %ebx, 1                 // ebx += 1
mov  %ecx, [%rdi + %rsi*4 + 8]
```

And remember that this is the *worst* case for Odin, written entirely in physical registers to make the syntactic contrast fair. In a real template you would be using names, not `%`-prefixed registers, and the right-hand column sheds almost all of its remaining sigils. That is the saner read I was after: one grammar, destination-first like most of the world, no suffix-mangled mnemonics, memory operands that look like arithmetic, and punctuation only where it is earning its keep. A more likely example would be using named parameters:
```odin
mov  x, y
add  x, 1
mov  z, [base + index*4 + disp]
```

## The Template Syntax

This is the general shape of an `asm` template:

```odin
name :: asm(params) -> (results) [bindings] {
    body
}
```

The `params` are your inputs, as plain names with Odin types. The `results` are your outputs, again plain names with types, sharing the same signature syntax as an Odin procedure. The `[bindings]` block holds everything that is *not* a plain input or output: the ties, the pins, the scratch registers, the width-views, the clobbers, and the effects. The `body` is the instruction stream. The params and results are optional, like with a normal procedure type, and the bindings are completely optional if they are not necessary.

The parameter types are just real Odin types: integers, floats, booleans, pointers, multi-pointers, or `#simd[N]T`. They are not for decoration. The compiler uses the type to decide the register class, the operand width, and whether a given instruction form will even accept it. A `#simd[4]f32` is a vector operand and the checker understands this.

Just like normal Odin procedures, you can declare parametric polymorphic constant parameters. A `$name` parameter is a compile-time immediate (`$ctrl: u8`), range-checked at the point of instantiation, exactly like any other Odin constant.

Here is one of the simplest examples of the `asm` syntax:

```odin
add_one :: asm(x: u64) -> (r: u64) [
    x -> r,
] {
    inc r
}
```

In the bindings block, `x -> r` means that it *ties* the input `x` and the output `r` to the same register, which lowers to a read-write operand. No stupid `%0`, no inline `"+r"`, no manually counting anything. You wrote the names; the names mean what they say.

## Multiple Return Values Fall Out For Free

I have [discussed multiple return values](https://www.gingerbill.org/article/2021/12/15/multiple-return-values-research/) for many years[^odin-foundation], and inline assembly is a place where this approach pays a dividend which I did not necessarily anticipate when I started Odin.

[^odin-foundation]: It is the foundation of Odin's type system after all.

Assembly instructions are *naturally* polyadic. `rdtsc` produces two results in `edx` and `eax`. `cpuid` produces four. `div` produces a quotient and a remainder simultaneously. In a language with a single return value you have to model all of this with out-parameters, or by stuffing things into a struct/tuple, or by some other contortion. In Odin you just... return them.

```odin
rdtsc :: asm() -> (lo, hi: u32) [
    lo = %eax,
    hi = %edx,
] {
    rdtsc
}

cpuid :: asm(leaf: u32) -> (a, b, c, d: u32) [
    leaf -> a = %eax,
    b = %ebx,
    c = %ecx,
    d = %edx,
] {
    cpuid
}

divmod_u64 :: asm(n: u64, d: u64) -> (quo, rem: u64) [
    n -> quo = %rax,
    rem      = %rdx,
    #clobber flags, // this is inferred and thus not necessary,
                    // but it's to show you can make it explicit
] {
    xor %rdx, %rdx   // clear the high half of the dividend
    div d            // rax = rdx:rax / d ; rdx = remainder
}
```

And at the call site they destructure exactly like any other Odin procedure that returns multiple values:

```odin
lo, hi := rdtsc()
quo, rem := divmod_u64(100, 7)
ea, eb, ec, ed := cpuid(0)
```

If you don't bind a result, the compiler simply ignores the unused one because you explicitly did not ask for it. A template whose outputs are just ABI artifacts does not force you to destructure them. This is the sort of thing that only feels obvious once it exists. Assembly *is* a polyadic typed algebra, so the moment your language speaks polyadic typed values fluently, the impedance mismatch that plagues every string-based assembler (or the assembly blocks) just isn't there.

## Ties, Pins, Scratch, and Width-Views

The binding block is an aspect which took a lot of design to think through, and for many people, it does not seem like it should even exist, as if it is an artificial prologue of sorts.
But this aspect is also where a lot of the explicit register-pinning lives, stuff that GCC places in its cryptic constraint string thingymabobs (technical term). I want virtually all of the clobbering to be inferred where possible, but where you need to be specific, make it explicit, readable, and named.

There are only a few things that live in the binding block, and they compose cleanly:


#### Clobbering

You can explicitly clobber registers `#clobber %rax`, flags/condition-codes `#clobber flags`, and memory `#clobber memory` within the binding block too.

#### Effects

If necessary, you can also specify the "effects" that need to happen, such as `#volatile` or `#align_stack`.

#### A Tie

`in -> out`, binds an input and an output to one register (a read-write operand). With a pin it fixes the register; without one, the allocator would choose different ones.

#### A Pin

`name = %reg`, forces a specific physical register.

#### A Scratch Register/Parameter

`name: T`, is a working register whose class comes from its type—`i64` gives you a general-purpose register, `#simd[4]f32` gives you a vector one. Unpinned scratch is early-clobbered, so it can never accidentally alias an input.

#### A Width-View

`view: T = src`, is a second name for `src`'s register seen at a narrower width. One register, two widths—the classic `setcc`-then-arithmetic idiom where you want the low 8 bits by one name and the full 64 by another. This is effectively a form of pinning anyway.


### The Usage of Binding Specification Syntax

The right-hand side of `=` is what disambiguates the last two: `= %reg` is a register, so it's a pin; `= src` is a name, so it's a width-view. The grammar itself tells you which you meant.

As an example, below is a vector kernel that uses scratch registers of a vector type, and here is exactly why typed parameters matter—the checker knows `acc` and `tmp` are xmm registers because you told it `#simd[4]f32`:

```odin
dot_f32x4 :: asm(a, b: [^]f32, n: i64) -> (result: f32) [
    acc: #simd[4]f32,
    tmp: #simd[4]f32,
    i:   i64,
    #clobber flags,  // the cmp/jl sets flags
    #clobber memory, // we read memory the compiler can't see
                     //
                     // NOTE: neither of these `#clobber` things are
                     // necessary as the compiler infers them from
                     // the usage of the instructions
] {
    xorps  acc, acc
    xor    i, i
.loop:
    movups tmp, [a + i*4]   // scale 4 = sizeof(f32)
    mulps  tmp, [b + i*4]
    addps  acc, tmp
    add    i, 4
    cmp    i, n
    jl     .loop
    haddps acc, acc
    haddps acc, acc
    movss  result, acc
}
```

One thing to note about labels such as `.loop`: they are local to the template and mangled per instantiation, so you can inline the same template a hundred times and never get a symbol collision. There are no global labels, on purpose. This is what a hygienic macro system effectively offers.

## Prefixes and Other Syntactic Quirks

There are a handful of small syntactic decisions that I had to make when designing this universal syntax for inline assembly templates. And these could easily trip up anyone who has spent years in NASM or GAS. None of them are arbitrary. Almost every one is the same rule wearing a different hat: the assembly body is tokenized and parsed by the same machinery as the rest of Odin, so anything that looks like a quirk is usually just the absence of a special case.

The clearest example is prefixes.

### A Prefix Gets Its Own Line

Instruction prefixes like `lock`, `rep`, and `repne` in x86 do not sit in front of the mnemonic the way they do everywhere else. They go on their own line:

```odin
atomic_fetch_add :: asm(p: ^i64, delta: i64) -> (old: i64) [
    delta -> old,
] {
    lock
    xadd [p], old
}

memcpy_rep :: asm(dst, src: rawptr, len: uint) -> (end_dst, end_src: rawptr, rem: uint) [
    dst -> end_dst = %rdi,
    src -> end_src = %rsi,
    len -> rem     = %rcx,
] {
    rep
    movsb
}
```

To an assembly veteran this looks wrong: surely `lock xadd` is one thing? But think about what the grammar actually says. Every line in a template is `instruction [operand{, operand}]`, and Odin (like Go or Python) has automatic semicolon insertion, so a newline terminates a statement. If a prefix shared a line with its mnemonic, I would need a special tokenizer exception: "these particular identifiers are not really instructions, they are modifiers, so don't terminate the statement after them." I did not want that exception. A prefix is simply an instruction that happens to take no operands and stand on its own line. The grammar stays uniform, and there is one fewer rule.

The obvious worry is that detaching a prefix from its instruction lets them drift apart. It does not, because the checker keeps them married even while the syntax pulls them apart. A prefix must be immediately followed by a real instruction (not a label, not another prefix) and its legality is checked against that following instruction's form: `lock` requires a memory destination; `rep`/`repne` require a string instruction. Write `lock` in front of something with no memory destination and the compiler rejects it, by name, at that token. This is the whole philosophy of the design: keep the syntax dumb and uniform, and make the semantic checker smart.

The prefix rule is really just the most visible instance of a broader principle. The body is tokenized with Odin's own tokenizer, which produces a few more things that look like quirks and are really just consistency.

### Comments are `//` and `/**/`, not `;` or `#`

In practically every traditional assembler, `;` (or `#` in GAS) begins a comment. Not here. ; is the statement separator, because that is what it is in Odin, and comments are `//` and `/**/`, because that is what they are in Odin. This is the single quirk most likely to bite someone in the arse when they write their first `asm` template—muscle memory typing `;` to start a comment and gets a syntax error instead of a remark. Odin has a comment syntax already, why should the assembly syntax get its own? Make it coherent with the parent surrounding language.

### Number Literals Are Odin's

No `0FAh`, no `$FA`, no trailing-letter radix soup. A hex literal is `0xFA`, binary is `0b1010`, and digit separators work, so you can write `rol_imm(0x0000_00FF, 8)` and have it read cleanly. The immediates in your assembly are tokenized by the same code as the integers everywhere else in your program, which means they behave identically: same bases, same separators, same overflow rules.

### Directives use `#`

The data and layout directives are `#byte`, `#skip`, `#nop`, and `#align`, not `.byte`, `.skip`, `.nops`, and `.p2align`. `#byte 0x90, 0x90` emits raw bytes; `#align 16` aligns the next instruction to a 16-byte boundary.

The `#` is not decoration for its own sake, rather it is Odin's directive sigil, the same one on `#simd`, `#clobber`, `#volatile`, and every other directive in the language. A reader who knows what `#` means everywhere else already knows what it means here. It is coherent with the rest of Odin's syntactical design choices.

### Labels Start With a Dot

A label is `.name:` to define and `.name` to reference. The leading dot marks it as being template-local, and it is mangled per instantiation, so you can inline the same template a hundred times and never collide. There are no global labels inside a template, on purpose, there is nowhere for a stray `jmp` to escape to. The compiler hypothetically parses labels without the need for a prefixed dot, but that prefixed dot also allows for the ability to keep labels in their own namespace and make it clear from a glance that they are also labels, making it familiar to other people from other assembly syntax and that they may behave slightly differently.

----

None of these are clever, and that is precisely the point. Each one is just Odin's existing lexical rule applied inside the assembly, rather than being overridden by some assembler tradition inherited from a different tool. The point is that an `asm` body reads similarly to the language it is embedded in, and the only genuinely new thing you have to learn is the instructions themselves.

## The Compiler Actually Understands It

This is the part I care about most, and the part I think virtually every other [inline] assembler has completely ignored for decades: semantic checking.

Templates are not passed through to the assembler verbatim. The frontend semantically checks every single instruction against the target's own encoding tables[^rexcode] (the same data the backend encodes from) so the overwhelming majority of mistakes are caught at compile time, at the offending token, in your source, rather than surfacing as an opaque assembler error much later against text you didn't write.

[^rexcode]: In partial preparation for this inline assembler, we have our own high-performance multi-architecture instruction encoder/decoder/printer library written in Odin: [rexcode](https://github.com/odin-lang/Odin/tree/master/core/rexcode). It has all of the encoding tables for numerous ISAs and IRs.

For each instruction, it checks the mnemonic, the operand count, the operand kind (register vs memory vs immediate vs label), the operand size and class, immediate ranges, and the full validity of memory operands. When a mnemonic has several encoding forms, and it cannot figure out what you wanted, it reports against the *closest* one (the form your operands most nearly satisfied) so the suggestion points at the encoding you actually meant:

```
movsss ...   // did you mean `movss`, `movsd`?
...          // operand 2 expected a register, got an immediate
...          // 36893488147419103232 does not fit a 32-bit immediate
```

Plenty of assemblers have been able to do a "did you mean?" typo fix; that is the bare minimum. However, my genuine complaint with the rest of the [inline] assemblers is this: given that the compiler understands *all* of the valid forms, all of the required operand kinds, and all of the clobbering information, why do so few inline assemblers offer error messages and suggestions beyond simple typo correction? The information is right there. Why don't they use it?!

And this is what I wanted for Odin's inline assembly. It can flag redundant uses of `#align_stack` when nothing in the body needs an aligned stack, because it understands the instructions. It flags a *missing* `#volatile` where the template plainly needs to be treated as volatile, because it understands the instructions. If you mark a template as diverging with `-> !` and it demonstrably never diverges in practice, it tells you, because it understands the instructions.

Most clobbers don't even need to be written—they're inferred from the instructions you used. In fact, the main reason the explicit `#clobber` and `#volatile` forms exist is for the effects the tables genuinely cannot infer, like runtime-dependent AVX-512 masking. The compiler is not a passive conduit to the assembler. It understands the algebra and gives you good error messages when you do something wrong.

This is only possible *because* the assembly is actually typed and structured rather than some dumb string. You cannot give good semantic diagnostics about a string you refused to understand.

## How the Compiler Understands It: `rexcode`

When I say the compiler *understands* an instruction, that is not a figure of speech, and it is not magic. It leans on a library.

The front-end checker and the backend—when it lowers to the internal assembler—both reference to the same thing: [`core:rexcode`](https://github.com/odin-lang/Odin/tree/master/core/rexcode), a high-performance, multi-architecture instruction encoder/decoder/printer that ships in Odin's `core` collection in part as preparation for tooling like this[^dotbmp]. Ask it whether `crc32 crc, [p + i]:u8` is a legal form—what operand kinds and widths it needs, what it clobbers—and it answers from its encoding tables, not from hand-rolled `if` statements buried in the compiler.

[^dotbmp]: `core:rexcode` is written designed and originally by [Brendan Punsky (dotbmp)](https://github.com/dotbmp/).

Encoding and decoding are table-driven from a single source of truth: each architecture has one hand-written table, and a metaprogram flattens it into committed binary blobs `#load`ed into `@(rodata)` at compile time, so lookups are O(1) against static data with zero allocation on the hot path[^odin-compiler-rexcode]. And the tables are verified, not merely asserted correct—round-tripped against `llvm-mc`, and the retro/embedded ISAs against `da65`, `ca65`, `armips`, and `binutils`. That verification is what earns the checker the right to be strict.

[^odin-compiler-rexcode]: The Odin compiler uses another metaprogram pass to convert those Odin lookup tables into C++ specific ones, since the compiler is written in C++.

`rexcode` already covers a lot:

* `x86` — x86-64 and i386, through SSE/AVX/AVX-512/BMI/FMA/AES-NI
* `arm32` and `arm64` — AArch32 (A32/T32/Thumb/VFP/NEON) and AArch64
* `mips`, `riscv`, `ppc` — including Power ISA 3.1 and its 3000-plus entries
* `ppc_vle`, `mos6502`, `mos65816`, `rsp` — embedded, retro, and the N64's vector unit
* an `ir/` layer, with `wasm` and `spirv` already in it

All behind the same API contract; change the import and your code keeps its shape.

*n.b.* For inline assembly we only care about the architectures we target, so not all of these are needed for it to work.

### Why Did This Not Exist Decades Ago?

The encoding of `x86` is a fixed, knowable, finite thing, updated only periodically. So is `arm64`, so is `RISC-V`. And yet every assembler, disassembler, JIT, debugger, emulator, and fuzzer re-derives the same knowledge from scratch; usually badly, usually welded to one tool in one language. LLVM has `TableGen`, but it is LLVM, in C++, and was never meant to be imported as a library. `binutils` has opcode tables, but they are per-tool C internals. There has never been a clean, verified, importable "here is every instruction form for a dozen architectures" that a compiler could just pick up.

I'd argue the absence of such a library is the real reason inline assemblers are so bad, as well as general compiler code-generation tooling. Semantic checking assembly isn't a hard idea; it's that without a machine-readable model of the instruction set right there, you *can't* check against it; so you give up and hand a string to the downstream assembler, and let it do the "complaining". The string-based design is downstream of the missing-table problem, and why people just bodge everything.

As far as I know, Odin is one of the first languages to ship such a library, especially with so many ISAs and IRs, in one coherent library, in its standard distribution. And because it existed before I started on the inline `asm` templates, implement was an absolute breeze to build[^implementation-time]; the hard, tedious, mistake-ridden ninety percent was already done and already verified against LLVM. I just built the nice part on top.

[^implementation-time]: It took approximately 7 days of total time to design the syntax, implement the parsing, integrate the rexcode tables, semantically check the assembly, and lower to LLVM's IR for inline assembly. I'd say I was pretty productive :D.

## Templates, Not Intrinsics

Regular readers will remember that I wrote a whole article titled [*If Odin Had Macros*](https://www.gingerbill.org/article/2025/07/31/if-odin-had-macros/) whose answer was my infamous **No**. So to address the obvious elephant in the room: these `asm` templates *are* hygienic macros. Have I contradicted myself?

I don't believe that I have, even if the distinction is a similar one I drew for iterators in that article. My objection was never to hygienic macros as such; rather, it was to a *general-purpose* macro system, because that is a slippery slope with no principled place to stop. A *restricted* hygienic macro, confined to a single well-understood domain, is a different beast entirely. An `asm` template can only do one thing: expand a typed, checked instruction stream in place, like a forced-inline procedure. It cannot rewrite your control flow, invent new syntax, or metastasize into the rest of the language. It is hygienic where it needs to be (the per-instantiation label mangling, the register scoping), and it is bounded by construction.

And you know what? It's absolutely lovely. And because they are templates, they largely *remove the need for dedicated compiler intrinsics*. A lot of what would otherwise be a hand-written builtin—`mfence`, an atomic fetch-add, a `tzcnt` that also reports whether the input was zero—you can just build directly out of the templates themselves:

```odin
mfence :: asm() [ #volatile ] { mfence }

atomic_fetch_add :: asm(p: ^i64, delta: i64) -> (old: i64) [
    delta -> old,
] {
    lock
    xadd [p], old   // [p] += old; old = previous [p]
}

tzcnt :: asm(x: u64) -> (count: u64, was_zero: bool) [
    was_zero = %flags.z,
] {
    tzcnt count, x
}
```

*Minor tangent:* `was_zero = %flags.z` is accessing a flag from the pseudo register `%flags`. The zero flag becomes a *typed boolean result* of the template, a condition-code placed into an ordinary Odin value that you destructure like any other. This is coherency and consistency, all the way down to the flags register.

Some platform-specific intrinsics will be replaced by exactly these inline `asm` templates in the near future, and good riddance too. An intrinsic is a black box the compiler hard-codes, which can be a good thing; however, for these platform-specific things, a template is something you can read, check, and write yourself.


## The Best Inline Assembler

I said right at the start, I think this is honestly the best inline assembly system in any language right now, and I want to defend that statement, rather than just idly asserting it.

It integrates with the type system instead of ignoring it. It speaks the host language's polyadic return values natively, because assembly genuinely *is* polyadic and typed. It gives you explicit, named control over ties, pins, scratch, and width-views instead of hiding intent inside constraint letters. It uses one coherent syntax across every ISA. It is hygienic, so it inlines safely and mangles its own labels. It replaces whole categories of intrinsics. And above all, the compiler *understands* what you wrote well enough to give you real diagnostics—not just typo fixes, but redundant directives, missing effects, and things which should diverge but don't.

None of this comes from a "grand type theory". It is all from the same place all of Odin's design comes from: doing the thing people actually want, not doing the thing everyone treats as a necessary evil, and asking what it would look like if it respected the language it lived in.

Assembly was typed the whole time. We just had to stop pretending it wasn't and embrace its very nature.