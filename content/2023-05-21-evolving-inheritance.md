---
title: Evolving Inheritance
slug: evolving-inheritance
author: Ginger Bill
date: '2023-05-21'
categories:
  - oop
  - software
tags:
  - odin
  - c
  - oop
  - assembly
---


### Tools used in this article


I've spoken aboat Object Oriented Programming (OOP) before in a few articles[^fatal-flaw]&nbsp;[^pragmatism]. There are numerous issues with the entire paradigm, but this article will be focusing on what is commonly considered the canonical case for inheritance and showing it does not need to be, nor preferred to be, structured in the traditional memory layout.

[^fatal-flaw]: https://www.gingerbill.org/article/2020/06/21/the-ownership-semantics-flaw/#foundations-of-the-object-orientation-paradigm
[^pragmatism]: https://www.gingerbill.org/article/2020/05/31/progamming-pragmatist-proverbs/#experimentation-and-emergence

In this article, I will be us ARM64 assembly as it is a lot easier to read than AMD64/x86 assembly (AT&T or Intel) and simpler than worrying about SysV ABI madness too.

### The Traditional Approach

In most languages that support some form of inheritance, the traditional layout is to have a base type that contains a pointer to a vtable which subtypes can then easily extend. The following code example below demonstrates this traditional layout.

```c
#include <stddef.h>
#include <stdint.h>

typedef int64_t i64;

typedef i64 Seek_From;
enum Seek_From_ {
	Seek_From_Start   = 0,
	Seek_From_Current = 1,
	Seek_From_End     = 2,
};

struct Vtable {
	i64 (*read) (void *s, void *ptr, i64 n);
	i64 (*write)(void *s, void *ptr, i64 n);
	i64 (*seek) (void *s, i64 offset, Seek_From whence);
	i64 (*close)(void *s);
};

struct Traditional { // effectively a pure virtual base class
	Vtable *vtable;
};

i64 read_traditional(Traditional *t, void *ptr, i64 n) {
	return t->vtable->read(t, ptr, n);
}
i64 write_traditional(Traditional *t, void *ptr, i64 n) {
	return t->vtable->write(t, ptr, n);
}
i64 seek_traditional(Traditional *t, i64 offset, Seek_From whence) {
	return t->vtable->seek(t, offset, whence);
}
i64 close_traditional(Traditional *t) {
	return t->vtable->close(t);
}
```

Which is then used in the following fashion:

```c
void test_traditional(void) {
	Traditional *stream = create_stream(...);

	char data[1024] = {0};
	i64 res = read_traditional(stream, data, sizeof(data));
	...
}
```



Looking at the assembly tells use what exactly is going on and what costs are happening. Each call is a very similar cost, but each requires two explicit indirections (memory loads) (`ldr` in ARM64).

```
read_traditional(Traditional*, void*, long):
        ldr     x3, [x0]
        ldr     x3, [x3]
        mov     x16, x3
        br      x16
write_traditional(Traditional*, void*, long):
        ldr     x3, [x0]
        ldr     x3, [x3, 8]
        mov     x16, x3
        br      x16
seek_traditional(Traditional*, long, long):
        ldr     x3, [x0]
        ldr     x3, [x3, 16]
        mov     x16, x3
        br      x16
close_traditional(Traditional*):
        ldr     x1, [x0]
        ldr     x1, [x1, 24]
        mov     x16, x1
        br      x16
```

### The Inlined Table Approach

To remove one of these indirections at the cost of padding out the "base class" is to inline the vtable.


```c
struct Inlined {
	Vtable vtable;
};

i64 read_inlined(Inlined *i, void *ptr, i64 n) {
	return i->vtable.read(i, ptr, n);
}
i64 write_inlined(Inlined *i, void *ptr, i64 n) {
	return i->vtable.write(i, ptr, n);
}
i64 seek_inlined(Inlined *i, i64 offset, Seek_From whence) {
	return i->vtable.seek(i, offset, whence);
}
i64 close_inlined(Inlined *i) {
	return i->vtable.close(i);
}
```

As the assembly shows, it does remove an indirection (`ldr` in ARM64) and will be faster and easier to predict (and maybe easier to inline too).


```
read_inlined(Inlined*, void*, long):
        ldr     x3, [x0]
        mov     x16, x3
        br      x16
write_inlined(Inlined*, void*, long):
        ldr     x3, [x0, 8]
        mov     x16, x3
        br      x16
seek_inlined(Inlined*, long, long):
        ldr     x3, [x0, 16]
        mov     x16, x3
        br      x16
close_inlined(Inlined*):
        ldr     x1, [x0, 24]
        mov     x16, x1
        br      x16
```

### The Hybrid Approach

```c
struct Hybrid {
	Vtable *vtable;
	void *data;
};

i64 read_hybrid(Hybrid h, void *ptr, i64 n) {
	return h.vtable->read(h.data, ptr, n);
}
i64 write_hybrid(Hybrid h, void *ptr, i64 n) {
	return h.vtable->write(h.data, ptr, n);
}
i64 seek_hybrid(Hybrid h, i64 offset, Seek_From whence) {
	return h.vtable->seek(h.data, offset, whence);
}
i64 close_hybrid(Hybrid h) {
	return h.vtable->close(h.data);
}
```

```
read_hybrid(Hybrid, void*, long):
        mov     x4, x0
        mov     x0, x1
        mov     x1, x2
        mov     x2, x3
        ldr     x4, [x4]
        mov     x16, x4
        br      x16
write_hybrid(Hybrid, void*, long):
        mov     x4, x0
        mov     x0, x1
        mov     x1, x2
        mov     x2, x3
        ldr     x4, [x4, 8]
        mov     x16, x4
        br      x16
seek_hybrid(Hybrid, long, long):
        mov     x4, x0
        mov     x0, x1
        mov     x1, x2
        mov     x2, x3
        ldr     x4, [x4, 16]
        mov     x16, x4
        br      x16
close_hybrid(Hybrid):
        mov     x2, x0
        mov     x0, x1
        ldr     x1, [x2, 24]
        mov     x16, x1
        br      x16
```

### The Flat Approach

```c
typedef i64 Mode;
enum Mode_ {
	Mode_read,
	Mode_write,
	Mode_seek,
	Mode_close,
};

struct Flat {
	i64 (*proc)(void *s, Mode mode, void *ptr, i64 n_or_whence, i64 offset);
	void *data;
};

i64 read_flat(Flat f, void *ptr, i64 n) {
	return f.proc(f.data, Mode_read, ptr, n, 0);
}
i64 write_flat(Flat f, void *ptr, i64 n) {
	return f.proc(f.data, Mode_write, ptr, n, 0);
}
i64 seek_flat(Flat f, i64 offset, Seek_From whence) {
	return f.proc(f.data, Mode_seek, NULL, whence, offset);
}
i64 close_flat(Flat f) {
	return f.proc(f.data, Mode_close, NULL, 0, 0);
}
```

```
read_flat(Flat, void*, long):
        mov     x5, x0
        mov     x4, 0
        mov     x0, x1
        mov     x16, x5
        mov     x1, 0
        br      x16
write_flat(Flat, void*, long):
        mov     x5, x0
        mov     x4, 0
        mov     x0, x1
        mov     x16, x5
        mov     x1, 1
        br      x16
seek_flat(Flat, long, long):
        mov     x5, x0
        mov     x4, x2
        mov     x0, x1
        mov     x16, x5
        mov     x2, 0
        mov     x1, 2
        br      x16
close_flat(Flat):
        mov     x5, x0
        mov     x4, 0
        mov     x0, x1
        mov     x16, x5
        mov     x3, 0
        mov     x2, 0
        mov     x1, 3
        br      x16
```