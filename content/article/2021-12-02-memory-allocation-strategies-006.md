---
{
    "title": "Memory Allocation Strategies - Part 6",
    "description": "Buddy Allocators",
    "slug": "memory-allocation-strategies-006",
    "author": "Ginger Bill",
    "date": "2021-12-02",
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

# Buddy Memory Allocation

In the previous article, we discussed the [free list allocator](/article/2021/11/30/memory-allocation-strategies-005/) and how it is commonly implemented with a [linked list](https://www.gingerbill.org/article/2021/11/30/memory-allocation-strategies-005/#linked-list-approach) or a [red-black tree](https://www.gingerbill.org/article/2021/11/30/memory-allocation-strategies-005/#red-black-tree-approach). In this article, the Buddy Algorithm and how it applies to memory allocation strategies. 

In the previous article, the red black tree approach was briefly discussed as a way to improve the time complexity for searching for a free memory block, and get _best-fit_ as a consequence. One of the big problems with free lists is that they are _very_ susceptible to [internal memory fragmentation](https://wikipedia.org/wiki/Fragmentation_(computing)) due to allocations being of any size. If we still require the properties of free lists but want to reduce internal memory fragmentation, the [Buddy algorithm](https://wikipedia.org/wiki/Buddy_memory_allocation)[^wikipedia-warning] works in a similar principle.

[^wikipedia-warning]: The Wikipedia article is not that easy to understand, especially from the basic table diagram given in the _Example_ section. (Accessed 2021-12-01)

# The Algorithm

The _Buddy Algorithm_ assumes that the backing memory block is a power-of-two in bytes. When an allocation is requested, the allocator looks for a block whose size is at least the size of the requested allocation (similar to a free list). If the requested allocation size is less than half of the block, it is split into two (left and right), and the two resulting blocks are called "buddies"[^buddies-joke]. If this requested allocation size is still less than half the size of the left buddy, the buddy block is recursively split until the resulting buddy is as small as possible to fit the requested allocation size.

[^buddies-joke]: Just like Jackie Chan and Chris Tucker in [Rush Hour](https://www.imdb.com/title/tt0120812/).

When a block is released, we can try to performance coalescence on buddies (contiguous neighbouring blocks). Similar to [free lists](/article/2021/11/30/memory-allocation-strategies-005/#free-and-coalescence), there are particular conditions that are needed. Coalescence cannot be performed if a block is has no (free) buddy, the block is still in use, or the buddy block is partially used.

![Buddy Allocator Splitting Algorithm](/images/memory-allocation-strategies/buddy_allocator.svg#center)

# The Implementation

## Buddy Block Data Structure

Each block in the buddy allocator will have a header (similar to our free list in the previous article) which stores information about it _inline_. It stores its size and whether it is free.

```c
typedef struct Buddy_Block Buddy_Block;
struct Buddy_Block { // Allocation header (metadata)
    size_t size; 
    bool   is_free;
};
```

We do not need store a pointer to the next buddy block as we can calculate it directly from the stored size.

```c
Buddy_Block *buddy_block_next(Buddy_Block *block) {
    return (Buddy_Block *)((char *)block + block->size);
}
```

n.b. Many implementations of a buddy allocator use a doubly linked list here and store explicit pointers, which allows for easier coalescence of neighbouring buddies and forward and backwards traversal. However this does add an extra cost of increasing the size of the allocation header for the memory block.

## Recursive Split

As described above, to get the best fitting block a recursive splitting algorithm is required. We need to continually split a block until it is the optimal size for the allocation of the requested size.
```c
Buddy_Block *buddy_block_split(Buddy_Block *block, size_t size) {
    if (block != NULL && size != 0) {
        // Recursive split
        while (size < block->size) {
            size_t sz = block->size >> 1;
            block->size = sz;
            block = buddy_block_next(block);
            block->size = sz;
            block->is_free = true;
        }
        
        if (size <= block->size) {
            return block;
        }
    }
    
    // Block cannot fit the requested allocation size
    return NULL;
}
```

## Finding the Best Block

Searching for a free block that matches the requested allocation size can be achieved by traversing an (implicit) linked list bounded by `head` and `tail` pointers[^tail-definition]. If a block for the requested allocation size cannot be found, but there is a larger free block, the above splitting algorithm is used. If there is no free block available, the following procedure with return `NULL` to represent that the allocator is (possibly) out of memory[^oom-caveat].

[^tail-definition]: The tail is just `(Buddy_Block *)((char *)data + size)` of the backing memory buffer, representing a sentinel value of the memory boundary, it is not a true block.

[^oom-caveat]: The allocator may have enough memory left but none of it is contiguous due to too much internal fragmentation.

```c
Buddy_Block *buddy_block_find_best(Buddy_Block *head, Buddy_Block *tail, size_t size) {
    // Assumes size != 0
    
    Buddy_Block *best_block = NULL;
    Buddy_Block *block = head;                    // Left Buddy
    Buddy_Block *buddy = buddy_block_next(block); // Right Buddy
     
    // The entire memory section between head and tail is free, 
    // just call 'buddy_block_split' to get the allocation
    if (buddy == tail && block->is_free) {
        return buddy_block_split(block, size);
    }
    
    // Find the block which is the 'best_block' to requested allocation sized
    while (block < tail && buddy < tail) { // make sure the buddies are within the range
        // If both buddies are free, coalesce them together
        // NOTE: this is an optimization to reduce fragmentation
        //       this could be completely ignored
        if (block->is_free && buddy->is_free && block->size == buddy->size) {
            block->size <<= 1
            if (size <= block->size && (best_block == NULL || block->size <= best_block->size)) {
                best_block = block;
            }
            
            block = buddy_block_next(buddy);
            if (block < tail) {
                // Delay the buddy block for the next iteration
                buddy = buddy_block_next(block);
            }
            continue;
        }
        
                
        if (block->is_free && size <= block->size && 
            (best_block == NULL || block->size <= best_block->size)) {
            best_block = block;
        }
        
        if (buddy->is_free && size <= buddy->size &&
            (best_block == NULL || buddy->size < best_block->size)) { 
            // If each buddy are the same size, then it makes more sense 
            // to pick the buddy as it "bounces around" less
            best_block = buddy;
        }
        
        if (block->size <= buddy->size) {
            block = buddy_block_next(buddy);
            if (block < tail) {
                // Delay the buddy block for the next iteration
                buddy = buddy_block_next(block);
            }
        } else {
            // Buddy was split into smaller blocks
            block = buddy;
            buddy = buddy_block_next(buddy);
        }
    }
    
    if (best_block != NULL) {
        // This will handle the case if the 'best_block' is also the perfect fit
        return buddy_block_split(best_block, size);
    }
    
    // Maybe out of memory
    return NULL;
}
```

This algorithm can suffer from undue internal fragmentation. As an exercise for the reader, you can coalesce on neighbouring free buddies[^malkovich] as you iterate.

[^malkovich]: All becoming a single buddy, trying to be someone else: https://www.imdb.com/title/tt0120601/

## Initialization

Initialization of the buddy allocator itself is relatively simple. The allocator itself stores three pieces of information: the `head` block (same the backing memory data), a sentinel pointer `tail` which represents the upper memory boundary of the backing memory data (`(char *)head + size)`, which means it is not a "real" block), and the alignment for each allocation. The procedure `buddy_allocator_init` below does some minor checks for the data itself with `assert`ions.

n.b. This implementation of a buddy allocator does require that all allocations must have the same alignment in order to simplify the code a lot. Buddy allocators are usually a single strategy as part of a more complicated allocator and thus the assumption of alignment is less of an issue in practice.

```c
typedef struct Buddy_Allocator Buddy_Allocator;
struct Buddy_Allocator {
    Buddy_Block *head; // same pointer as the backing memory data
    Buddy_Block *tail; // sentinel pointer representing the memory boundary
    size_t alignment; 
};

void buddy_allocator_init(Buddy_Allocator *b, void *data, size_t size, size_t alignment) {
    assert(data != NULL);
    assert(is_power_of_two(size) && "size is not a power-of-two");
    assert(is_power_of_two(alignment) && "alignment is not a power-of-two");
    
    // The minimum alignment depends on the size of the `Buddy_Block` header
    assert(is_power_of_two(sizeof(Buddy_Block)) == 0);
    if (alignment < sizeof(Buddy_Block)) {
        alignment = sizeof(Buddy_Block);
    }
    assert((uintptr_t)data % alignment == 0 && "data is not aligned to minimum alignment");
    
    b->head          = (Buddy_Block *)data;
    b->head->size    = size;
    b->head->is_free = true;
    
    // The tail here is a sentinel value and not a true block
    b->tail = buddy_block_next(b->head);
    
    b->alignment = alignment;
}
```

## Allocation

Allocation is relatively straightforward since we have set everything else up already now. We first need increase requested allocation size to a fit the header and align forward before we find a best fitting block. If one is found, we then need to offset from the header to the usable data. If a block cannot be found, we can keep coalescing any free blocks until we cannot coalesce any more and then try to look for a usable block again. If not block is found, we return `NULL` to signify that we are out of memory with this particular allocator.

```c
size_t buddy_block_size_required(Buddy_Allocator *b, size_t size) {
    size_t actual_size = b->alignment;
    
    size += sizeof(Buddy_Block);
    size = align_forward_size(size, b->alignment); 
    
    while (size > actual_size) {
        actual_size <<= 1;
    }
    
    return actual_size;
}

void buddy_block_coalescence(Buddy_Block *head, Buddy_Block *tail) {
    for (;;) { 
        // Keep looping until there are no more buddies to coalesce
        
        Buddy_Block *block = head;   
        Buddy_Block *buddy = buddy_block_next(block);   
        
        bool no_coalescence = true;
        while (block < tail && buddy < tail) { // make sure the buddies are within the range
            if (block->is_free && buddy->is_free && block->size == buddy->size) {
                // Coalesce buddies into one
                block->size <<= 1;
                block = buddy_block_next(block);
                if (block < tail) {
                    buddy = buddy_block_next(block);
                    no_coalescence = false;
                }
            } else if (block->size < buddy->size) {
                // The buddy block is split into smaller blocks
                block = buddy;
                buddy = buddy_block_next(buddy);
            } else {
                block = buddy_block_next(buddy);
                if (block < tail) {
                    // Leave the buddy block for the next iteration
                    buddy = buddy_block_next(block);
                }
            }
        }
        
        if (no_coalescence) {
            return;
        }
    }
}

void *buddy_allocator_alloc(Buddy_Allocator *b, size_t size) {
    if (size != 0) {    
        size_t actual_size = buddy_block_size_required(b, size);
        
        Buddy_Block *found = buddy_block_find_best(b->head, b->tail, actual_size);
        if (found == NULL) {
            // Try to coalesce all the free buddy blocks and then search again
            buddy_block_coalescence(b->head, b->tail);
            found = buddy_block_find_best(b->head, b->tail, actual_size);
        }
            
        if (found != NULL) {
            found->is_free = false;
            return (void *)((char *)found + b->alignment);
        }
        
        // Out of memory (possibly due to too much internal fragmentation)
    }
    
    return NULL;
}
```

The general time-complexity of this allocation algorithm is _**O(N)**_ on average but a space complexity of _**O(log N)**_. 

n.b. As buddy allocators are still susceptible to internal fragmentation; it is less than a normal free list allocator but because of the power-of-two restriction, it is less severe in practice. 

## Freeing Memory

Freeing memory is very trivial with this algorithm since all we need to do is mark the header (which is stored before the passed pointer) as being free.

```c
void buddy_allocator_free(Buddy_Allocator *b, void *data) {
    if (data != NULL) {
        Buddy_Block *block;
        
        assert(b->head <= data);
        assert(data < b->tail);
        
        block = (Buddy_Block *)((char *)data - b->alignment);
        block->is_free = true;
        
        // NOTE: Coalescence could be done now but it is optional
        // buddy_block_coalescence(b->head, b->tail);
    }
}
```

The general time-complexity of freeing memory is _**O(1)**_. If you wanted to, `buddy_block_coalescence` could be performed straight after this free to aid in minimizing internal fragmentation.

# Conclusion

The buddy allocator is a powerful allocator and a conceptually simple algorithm but implementing it efficiently is a lot harder than all of the previous allocators that have been discussed in this series. 

In the next set of articles, I will discuss the a lot about virtual memory; how it works, how we can utilize it, and its benefits.