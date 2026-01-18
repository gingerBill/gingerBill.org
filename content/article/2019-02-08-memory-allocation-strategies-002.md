---
{
    "title": "Memory Allocation Strategies - Part 2",
    "description": "Linear/Arena Allocators",
    "slug": "memory-allocation-strategies-002",
    "author": "Ginger Bill",
    "date": "2019-02-08",
    "series": [
        "Memory Allocation Strategies"
    ],
    "categories": [
        "memory allocation theory"
    ],
    "tags": [
        "memory allocation theory odin c"
    ]
}
---


# Linear Allocation

The first memory allocation strategy that I will cover is also one of the simplest ones: linear allocation. As the name suggests,  memory is allocated linearly. Throughout this series, I will be using the concept of an _allocator_ as a means to allocate this memory. A linear allocator, is also known by other names such as an Arena or Region-based allocator. In this article, I will refer to this allocator an a _Arena_.

## Basic Logic

The arena's logic only requires an offset (or pointer) to state the end of the last allocation[^other-data].
[^other-data]: Other data may stored such as the offset of the beginning of the previous allocation or allocation count.

![Linear Allocator Layout](/images/memory-allocation-strategies/linear_allocator.svg#center)

To allocate some memory from the arena, it is as simple as moving the offset (or pointer) forward. In [Big-O notation](https://wikipedia.org/wiki/Big_O_notation), the allocation has complexity of _**O(1)**_ (constant).

![Linear Allocator Alloc](/images/memory-allocation-strategies/linear_allocator_alloc.svg#center)

Due to being the simplest allocator possible, the arena allocator does not allow the user to free certain blocks of memory. The memory is usually freed all at once.


## Basic Implementation


**Note:** The following code examples will be in written in C.


The simplest arena allocator _could_ look like this:

```c
static unsigned char *arena_buffer;
static size_t arena_buffer_length;
static size_t arena_offset;

void *arena_alloc(size_t size) {
	// Check to see if the backing memory has space left
	if (arena_offset+size <= arena_buffer_length) {
		void *ptr = &arena_buffer[arena_offset];
		arena_offset += size;
		// Zero new memory by default
		memset(ptr, 0, size);
		return ptr;
	}
	// Return NULL if the arena is out of memory
	return NULL;
}
```

As you may be able to tell, this is as simple as it gets. There are two issues with this basic approach:

* You cannot reuse this procedure for different arenas
* The pointer returned may not be aligned correctly for the data you need

The first issue can be easily solved by coupling that global data into a structure and passing that to the procedure `arena_alloc`. As for the second issue, this requires understanding about the basic issues of _unaligned memory_.

# Memory Alignment

Modern computer architectures will always read memory at its "word size" (4 bytes on a 32 bit machine, 8 bytes on a 64 bit machine). If you have an unaligned memory access (on a processor that allows for that), the processor will have to read multiple "words". This means that an unaligned memory access _may_ be much slower than an aligned memory access.
I will not write too much about memory alignment in this series. If you would like to learn more, I recommend the following articles:

* [IBM - Data alignment: Straighten up and fly right](https://developer.ibm.com/technologies/systems/articles/pa-dalign/)
* [Gallery of Processor Cache Effects](http://igoro.com/archive/gallery-of-processor-cache-effects/)
* [x86 Protected Mode Basics](http://www.rcollins.org/articles/pmbasics/tspec_a1_doc.html)

## Aligning a Memory Address

On virtually all architectures, the amount of bytes that something must be aligned by must be a power of two (1, 2, 4, 8, 16, etc). This means we should create procedure to assert that the alignment is a power of two:

```c
bool is_power_of_two(uintptr_t x) {
	return (x & (x-1)) == 0;
}
```

To align a memory address to the specified alignment is simple modulo arithmetic. You are looking to find how many bytes forward you need to go in order for the memory address is a multiple of the specified alignment.

```c
uintptr_t align_forward(uintptr_t ptr, size_t align) {
	uintptr_t p, a, modulo;

	assert(is_power_of_two(align));

	p = ptr;
	a = (uintptr_t)align;
	// Same as (p % a) but faster as 'a' is a power of two
	modulo = p & (a-1);

	if (modulo != 0) {
		// If 'p' address is not aligned, push the address to the
		// next value which is aligned
		p += a - modulo;
	}
	return p;
}
```


Now that we know how to align memory, that means we can update our original `arena_alloc` to support alignment properly and store the arena data within a structure.

```c
typedef struct Arena Arena;
struct Arena {
	unsigned char *buf;
	size_t         buf_len;
	size_t         prev_offset; // This will be useful for later on
	size_t         curr_offset;
};

void *arena_alloc_align(Arena *a, size_t size, size_t align) {
	// Align 'curr_offset' forward to the specified alignment
	uintptr_t curr_ptr = (uintptr_t)a->buf + (uintptr_t)a->curr_offset;
	uintptr_t offset = align_forward(curr_ptr, align);
	offset -= (uintptr_t)a->buf; // Change to relative offset

	// Check to see if the backing memory has space left
	if (offset+size <= a->buf_len) {
		void *ptr = &a->buf[offset];
		a->prev_offset = offset;
		a->curr_offset = offset+size;

		// Zero new memory by default
		memset(ptr, 0, size);
		return ptr;
	}
	// Return NULL if the arena is out of memory (or handle differently)
	return NULL;
}

#ifndef DEFAULT_ALIGNMENT
#define DEFAULT_ALIGNMENT (2*sizeof(void *))
#endif

// Because C doesn't have default parameters
void *arena_alloc(Arena *a, size_t size) {
	return arena_alloc_align(a, size, DEFAULT_ALIGNMENT);
}
```

# Implementing the Rest


The arena allocator is usable for basic things now but it is missing a few features that would make it practical for everyday use. The complete arena allocator will have the following procedures:

* `arena_init` initialize the arena with a pre-allocated memory buffer
* `arena_alloc` simply increments an offset to indicate the current buffer offset
* `arena_free` does absolutely nothing (just there for completeness)
* `arena_resize` first checks to see if the allocation being resized was the previously performed allocation and if so, the same pointer will be returned and the buffer offset is changed. Otherwise, `arena_alloc` will be called instead.
* `arena_free_all` is used to free all the memory within the allocator by setting the buffer offsets to zero.

## Init

The `arena_init` procedure just initializes the parameters for the given arena.

```c
void arena_init(Arena *a, void *backing_buffer, size_t backing_buffer_length) {
	a->buf = (unsigned char *)backing_buffer;
	a->buf_len = backing_buffer_length;
	a->curr_offset = 0;
	a->prev_offset = 0;
}
```

## Free

As I previously stated, `arena_free` does absolutely nothing. It exists purely for completeness.

```c
void arena_free(Arena *a, void *ptr) {
	// Do nothing
}
```

## Resize

Resizing an allocation is sometimes useful in an arena. To reduce waste of memory, it is useful to track the `prev_offset` and if the `old_memory` passed in equals the offset provided, just resize that memory block.

```c
void *arena_resize_align(Arena *a, void *old_memory, size_t old_size, size_t new_size, size_t align) {
	unsigned char *old_mem = (unsigned char *)old_memory;

	assert(is_power_of_two(align));

	if (old_mem == NULL || old_size == 0) {
		return arena_alloc_align(a, new_size, align);
	} else if (a->buf <= old_mem && old_mem < a->buf+buf_len) {
		if (a->buf+a->prev_offset == old_mem) {
			a->curr_offset = a->prev_offset + new_size;
			if (new_size > old_size) {
				// Zero the new memory by default
				memset(&a->buf[a->curr_offset], 0, new_size-old_size);
			}
			return old_memory;
		} else {
			void *new_memory = arena_alloc_align(a, new_size, align);
			size_t copy_size = old_size < new_size ? old_size : new_size;
			// Copy across old memory to the new memory
			memmove(new_memory, old_memory, copy_size);
			return new_memory;
		}

	} else {
		assert(0 && "Memory is out of bounds of the buffer in this arena");
		return NULL;
	}

}

// Because C doesn't have default parameters
void *arena_resize(Arena *a, void *old_memory, size_t old_size, size_t new_size) {
	return arena_resize_align(a, old_memory, old_size, new_size, DEFAULT_ALIGNMENT);
}
```


## Free All

Finally, `arena_free_all` is used to free all the memory within the allocator by setting the buffer offsets to zero. This is very useful for when you want to reset on a per cycle/frame basis.

```c
void arena_free_all(Arena *a) {
	a->curr_offset = 0;
	a->prev_offset = 0;
}
```

# Using the Allocator

To use the allocator, you need to provide some backing memory. A simple approach is to provide an array:
```c
unsigned char backing_buffer[256];
Arena a = {0};
arena_init(&a, backing_buffer, 256);
```

Another approach is to use `malloc`:
```c
void *backing_buffer = malloc(256);
Arena a = {0};
arena_init(&a, backing_buffer, 256);
```

# Conclusion

You have now implemented your very first custom allocator! The full source code is [available here](/code/memory-allocation-strategies/part002.c).

In the next article, I will be talking about the basic evolution of the _arena allocator_ in to a [_stack allocator_](/article/2019/02/15/memory-allocation-strategies-003/).

# Extra Features

One extra feature you could add is a temporary arena memory _savepoint_. This is extremely useful for when you just want to use some memory in an arena for a very short period and then reset to the previously saved point.

```c
typedef struct Temp_Arena_Memory Temp_Arena_Memory;
struct Temp_Arena_Memory {
	Arena *arena;
	size_t prev_offset;
	size_t curr_offset;
};

Temp_Arena_Memory temp_arena_memory_begin(Arena *a) {
	Temp_Arena_Memory temp;
	temp.arena = a;
	temp.prev_offset = a->prev_offset;
	temp.curr_offset = a->curr_offset;
	return temp;
}

void temp_arena_memory_end(Temp_Arena_Memory temp) {
	temp.arena->prev_offset = temp.prev_offset;
	temp.arena->curr_offset = temp.curr_offset;
}
```
