---
{
    "title": "Memory Allocation Strategies - Part 4",
    "description": "Pool Allocators",
    "slug": "memory-allocation-strategies-004",
    "author": "Ginger Bill",
    "date": "2019-02-16",
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


# Pool-Based Allocation

In the previous article, we looked at the [stack allocator](/article/2019/02/15/memory-allocation-strategies-003/), which was the natural evolution of the [linear/arena allocator](/article/2019/02/08/memory-allocation-strategies-002/). In this article, I will cover the fixed-sized _pool allocator_.

A pool allocator is a bit different from the previous allocation strategies that I have covered. A pool splits the supplied backing buffer into _chunks_ of equal size and keeps track of which of the chunks are free. When an allocation is wanted, a free chunk is given. When a chunk is wanted to be freed, it adds that chunk to the list of free chunks.

Pool allocators are extremely useful when you need to allocate chunks of memory of the same size which need are created and destroy dynamically, especially in a random order. Pools also have the benefit that arenas and stacks have in that they provide very little fragmentation and allocate/free in constant time _**O(1)**_.

Pool allocators are usually used to allocate _groups_ of "things" at once which share the same lifetime. An example could be within a game that creates and destroys entities in batches where each entity within a batch share the same lifetime.

# Basic Logic

A pool allocator takes a backing buffer and divides that buffer into pools/slots/bins/chunks[^terms] of all the same size.

[^terms]: What's in a name? That which we call a rose. By any other name would smell as sweet. [Romeo and Juliet (II, ii, 1-2)](https://www.owleyes.org/text/romeo-and-juliet/read/act-ii-scene-ii)

![Pool Allocator Layout](/images/memory-allocation-strategies/pool_allocator.svg#center)

The question is how are these allocations and frees determined? And how do they provide very little fragmentation with allocations that can be made in any order?

## Free Lists

A [free list](https://wikipedia.org/wiki/Free_list) is a data structure that internally stores a [linked-list](https://wikipedia.org/wiki/Linked_list) of the free slots/chunks within the memory buffer. The nodes of the list are stored in-place as this means that there does not need to be another data structure (e.g. array, list, etc) to keep track of the free slots. The data is _only_ stored _within_ the backing buffer of the pool allocator.

![Pool Allocator List](/images/memory-allocation-strategies/pool_allocator_list.svg#center)

The general approach is to store a header at the beginning of the chunk (not before the chunk like with the stack allocator) which _points_ to the next available free chunk[^free-chunk].
[^free-chunk]: If there is not an available free chunk, it will point to nothing (`NULL`).

![Pool Allocator List In-Place](/images/memory-allocation-strategies/pool_allocator_list_inplace.svg#center)

## Allocate and Free

To allocate a chunk, just pop off the head (first element) from the free list. In [Big-O notation](https://wikipedia.org/wiki/Big_O_notation), the allocation has complexity of _**O(1)**_ (constant).

![Pool Allocator Alloc](/images/memory-allocation-strategies/pool_allocator_alloc.svg#center)

**Note**: The free list does not need to be ordered as its order is determined by how chunks are allocated and freed.

![Pool Allocator Alloc Unordered](/images/memory-allocation-strategies/pool_allocator_alloc_unordered.svg#center)

To free a chunk, just push the freed chunk as the head of the free list. In Big-O notation, the freeing of this memory has complexity of _**O(1)**_ (constant).


# Implementation


The pool allocator requires less code than the arena and stack allocator as there is no logic required for different sized/aligned allocations and resize allocations. The complete pool allocator will have the following procedures:

* `pool_init` initialize the pool with a pre-allocated memory buffer
* `pool_alloc` pops off the head from the free list
* `pool_free` pushes on the freed chunk as the head of the free list
* `pool_free_all` pushes every chunk in the pool onto the free list


## Data Structures

The pool data structure contains a backing buffer, the size of each chunk, and the head to the free list.

```c
typedef struct Pool Pool;
struct Pool {
	unsigned char *buf;
	size_t buf_len;
	size_t chunk_size;

	Pool_Free_Node *head; // Free List Head
};
```

Each node in the free list just contains a pointer to the next free chunk, which could be `NULL` if it is the _tail_ (last element).

```c
typedef struct Pool_Free_Node Pool_Free_Node;
struct Pool_Free_Node {
	Pool_Free_Node *next;
};
```

## Init

Initializing a pool is pretty simple however, because each chunk has the same size and alignment, this logic can be done now rather than later.


```c
void pool_free_all(Pool *p); // This procedure will be covered later in this article

void pool_init(Pool *p, void *backing_buffer, size_t backing_buffer_length,
               size_t chunk_size, size_t chunk_alignment) {
	// Align backing buffer to the specified chunk alignment
	uintptr_t initial_start = (uintptr_t)backing_buffer;
	uintptr_t start = align_forward_uintptr(initial_start, (uintptr_t)chunk_alignment);
	backing_buffer_length -= (size_t)(start-initial_start);

	// Align chunk size up to the required chunk_alignment
	chunk_size = align_forward_size(chunk_size, chunk_alignment);

	// Assert that the parameters passed are valid
	assert(chunk_size >= sizeof(Pool_Free_Node) &&
	       "Chunk size is too small");
	assert(backing_buffer_length >= chunk_size &&
	       "Backing buffer length is smaller than the chunk size");

	// Store the adjusted parameters
	p->buf = (unsigned char *)backing_buffer;
	p->buf_len = backing_buffer_length;
	p->chunk_size = chunk_size;
	p->head = NULL; // Free List Head

	// Set up the free list for free chunks
	pool_free_all(p);
}
```

## Alloc

The `pool_alloc` procedure is a lot simpler than other allocators as each chunk has the same size and alignment and thus these parameters do not need to be passed to the procedure. The latest free chunk from the free list is popped off and is then used as the new allocation.

```c
void *pool_alloc(Pool *p) {
	// Get latest free node
	Pool_Free_Node *node = p->head;

	if (node == NULL) {
		assert(0 && "Pool allocator has no free memory");
		return NULL;
	}

	// Pop free node
	p->head = p->head->next;

	// Zero memory by default
	return memset(node, 0, p->chunk_size);
}
```

## Free

Freeing an allocation is pretty much the opposite of an allocation. The chunk to be freed is pushed onto the free list.

```c
void pool_free(Pool *p, void *ptr) {
	Pool_Free_Node *node;

	void *start = p->buf;
	void *end = &p->buf[p->buf_len];

	if (ptr == NULL) {
		// Ignore NULL pointers
		return;
	}

	if (!(start <= ptr && ptr < end)) {
		assert(0 && "Memory is out of bounds of the buffer in this pool");
		return;
	}

	// Push free node
	node = (Pool_Free_Node *)ptr;
	node->next = p->head;
	p->head = node;
}
```

## Free All

Freeing all the memory is equivalent of pushing all the chunks onto the free list.

```c
void pool_free_all(Pool *p) {
	size_t chunk_count = p->buf_len / p->chunk_size;
	size_t i;

	// Set all chunks to be free
	for (i = 0; i < chunk_count; i++) {
		void *ptr = &p->buf[i * p->chunk_size];
		Pool_Free_Node *node = (Pool_Free_Node *)ptr;
		// Push free node onto thte free list
		node->next = p->head;
		p->head = node;
	}
}
```

# Conclusion

The pool allocator is a very useful allocator for when you need to allocator "things" in _chunks_ and the things within those chunks share the same lifetime. The full source code is [available here](/code/memory-allocation-strategies/part004.c).

In the next article, I will discuss [free list memory allocators](/article/2021/11/30/memory-allocation-strategies-005/).
