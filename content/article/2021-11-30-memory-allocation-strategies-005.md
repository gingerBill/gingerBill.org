---
{
    "title": "Memory Allocation Strategies - Part 5",
    "description": "Free List Allocators",
    "slug": "memory-allocation-strategies-005",
    "author": "Ginger Bill",
    "date": "2021-11-30",
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

# Free List Based Allocation

In the previous article, we looked at the [pool allocator](/article/2019/02/16/memory-allocation-strategies-004/), which splits the supplied backing buffer into _chunks_ of equal size and keeps track of which of the chunks are free. Pool allocators are fast allocators that allow for out of order free in constant time _**O(1)**_ whilst keeping very little fragmentation. The main restriction of a pool allocator is that every memory allocation must be of the same size.



A free list is a general purpose allocator which, compared to the other allocators that we previously looked at, does not impose any restrictions. It allows allocations and deallocations to be out of order and of any size. Due to its nature, the allocator's performance is not as good as the others previously discussed in this series. 

There are two common approaches to implementing a free list allocator: one using a [linked list](https://wikipedia.org/wiki/Linked_list) and one use a [red black tree](https://wikipedia.org/wiki/Red%E2%80%93black_tree). Using a linked list approach is the most common approach and what we'll look at first.

# Linked List Approach

As the title of this section suggests, we'll be using a linked list to store the address of free contiguous blocks in the memory along with its size. When the user requests memory, it searches in the linked list for a block where the data can fit. It then removes the element from the linked list and places an allocation header (which is required on free) just before the data (similar to what we used in the article on [stack allocators](/article/2019/02/15/memory-allocation-strategies-003/#data-structures)).

For freeing memory, we recover the allocation header (stored before the allocation) to know the size of the block we want to free. Once that block has been freed, it is inserted into the linked list, and then we try to _coalescence_ contiguous blocks of memory together to create larger blocks.

![Free List Allocator](/images/memory-allocation-strategies/free_list_allocator.svg#center)

# Linked List Free List Implementation

**n.b.** The following implementation does provide some constraints on the size and alignment of requested allocations with this particular allocator. The minimum size of an allocation must be at least the size of the free list node data structure, and the alignment has similar requirements.

## Data Structures

These are the data structures that are required to implement the linked list based free list allocator.

```c
// Unlike our trivial stack allocator, this header needs to store the 
// block size along with the padding meaning the header is a bit
// larger than the trivial stack allocator
typedef struct Free_List_Allocation_Header Free_List_Allocation_Header;
struct Free_List_Allocation_Header {
    size_t block_size;
    size_t padding;
};

// An intrusive linked list for the free memory blocks
typedef struct Free_List_Node Free_List_Node;
struct Free_List_Node {
    Free_List_Node *next;
    size_t block_size;
};

typedef Placement_Policy Placement_Policy;
enum Placement_Policy {
    Placement_Policy_Find_First,
    Placement_Policy_Find_Best
};

typedef struct Free_List Free_List;
struct Free_List {
    void *           data;
    size_t           size;
    size_t           used;
    
    Free_List_Node * head;
    Placement_Policy policy;
};
```

## Initialization

```c
void free_list_free_all(Free_List *fl) {
    fl->used = 0;
    Free_List_Node *first_node = (Free_List_Node *)fl->data;
    first_node->block_size = fl->size;
    first_node->next = NULL;
    f->head = first_node;
}

void free_list_init(Free_List *fl, void *data, size_t size) {
    fl->data = data;
    fl->size = size;
    free_list_free_all(fl);
}
```

## Allocation

To allocate a block of memory within this allocator, we need to look for a block in the memory in which to fit our data. This means iterating across our linked list of free memory blocks until a block has at least the size requested, and then remove it from the linked list of free memory. Finding the first block is called a _first-fit_ placement policy as it stops at the _first_ block which fits the requested memory size. Another placement policy is called the _best-fit_ which looks for a free block of memory which is the smallest available which fits the memory size. The latter option reduces memory fragmentation within the allocator. 


In the diagram there three free memory blocks, but not all are appropriate for the size of the memory allocation that is requested (plus the header)
![Free List Allocator Allocate Search](/images/memory-allocation-strategies/free_list_allocator_alloc.svg#center)

When an allocation has been made, the free list will then be corrected to remove the used node.
![Free List Allocator Allocate Store](/images/memory-allocation-strategies/free_list_allocator_alloc2.svg#center)

This algorithm has a time complexity of _**O(N)**_, where N is the number of free blocks in the free list.


```c
// Defined Memory Allocation Strategies Part 3: /article/2019/02/15/memory-allocation-strategies-003/#alloc
size_t calc_padding_with_header(uintptr_t ptr, uintptr_t alignment, size_t header_size);

Free_List_Node *free_list_find_first(Free_List *fl, size_t size, size_t alignment, size_t *padding_, Free_List_Node **prev_node_) {
    // Iterates the list and finds the first free block with enough space 
    Free_List_Node *node = fl->head;
    Free_List_Node *prev_node = NULL;
    
    size_t padding = 0;
    
    while (node != NULL) {
        padding = calc_padding_with_header((uintptr_t)node, (uintptr_t)alignment, sizeof(Free_List_Allocation_Header));
        size_t required_space = size + padding;
        if (node->block_size >= required_space) {
            break;
        }
        prev_node = node;
        node = node->next;
    }
    if (padding_) *padding_ = padding;
    if (prev_node_) *prev_node_ = prev_node;
    return node;
}
Free_List_Node *free_list_find_best(Free_List *fl, size_t size, size_t alignment, size_t *padding_, Free_List_Node **prev_node_) {
    // This iterates the entire list to find the best fit
    // O(n)
    size_t smallest_diff = ~(size_t)0;
    
    Free_List_Node *node = fl->head;
    Free_List_Node *prev_node = NULL;
    Free_List_Node *best_node = NULL;
    
    size_t padding = 0;
    
    while (node != NULL) {
        padding = calc_padding_with_header((uintptr_t)node, (uintptr_t)alignment, sizeof(Free_List_Allocation_Header));
        size_t required_space = size + padding;
        if (node->block_size >= required_space && (it.block_size - required_space < smallest_diff)) {
            best_node = node;
        }
        prev_node = node;
        node = node->next;
    }
    if (padding_) *padding_ = padding;
    if (prev_node_) *prev_node_ = prev_node;
    return best_node;
}
```

```c
void *free_list_alloc(Free_List *fl, size_t size, size_t alignment) {
    size_t padding = 0;
    Free_List_Node *prev_node = NULL;
    Free_List_Node *node = NULL;
    size_t alignment_padding, required_space, remaining;
    Free_List_Allocation_Header *header_ptr;
    
    if (size < sizeof(Free_List_Node)) {
        size = sizeof(Free_List_Node);
    }
    if (alignment < 8) {
        alignment = 8;
    }
    
    
    if (fl->policy == Placement_Policy_Find_Best) {
        node = free_list_find_best(fl, size, alignment, &padding, &prev_node);
    } else {
        node = free_list_find_first(fl, size, alignment, &padding, &prev_node);
    }
    if (node == NULL) {
        assert(0 && "Free list has no free memory");
        return NULL;
    }
    
    alignment_padding = padding - sizeof(Free_List_Allocation_Header);
    required_space = size + padding;
    remaining = node->block_size - required_space;
    
    if (remaining > 0) {
        Free_List_Node *new_node = (Free_List_Node *)((char *)node + required_space);
        new_node->block_size = rest;
        free_list_node_insert(&fl->head, node, new_node);
    }
    
    free_list_node_remove(&fl->head, prev_node, node);
    
    header_ptr = (Free_List_Allocation_Header *)((char *)node + alignment_padding);
    header_ptr->block_size = required_space;
    header_ptr->padding = alignment_padding;
    
    fl->used += required_space;
    
    return (void *)((char *)header_ptr + sizeof(Free_List_Allocation_Header));
}
```

## Free and Coalescence

When freeing a memory block that was allocated with our free list allocator, we need to retrieve the allocation header and that memory block to be treated as a free memory block now. We then need to iterate across the linked list of free memory blocks until will get to the right position in memory order (as the link list is sorted), and then insert new at that position. This can be achieved by looking at the previous and next nodes in the list since they are already sorted by address.

When the insert of the free list, we want to coalescence any free memory blocks which are contiguous. When we were iterating across linked list we had to store both the previous and next free nodes, this means that we may be able to merge these blocks together if possible. 

This algorithm has a time complexity of _**O(N)**_, where N is the number of free blocks in the free list.

![Free List Allocator Free and Coalescence](/images/memory-allocation-strategies/free_list_allocator_free.svg#center)


```c
void free_list_coalescence(Free_List *fl, Free_List_Node *prev_node, Free_List_Node *free_node);

void *free_list_free(Free_List *fl, void *ptr) {
    Free_List_Allocation_Header *header;
    Free_List_Node *free_node;
    Free_List_Node *node;
    Free_List_Node *prev_node = NULL;
    
    if (ptr == NULL) {
        return;
    }
    
    header = (Free_List_Allocation_Header *)((char *)ptr - sizeof(Free_List_Allocation_Header));
    free_node = (Free_List_Node *)header;
    free_node->block_size = header->block_size + header->padding;
    free_node->next = NULL;
    
    node = fl->head;
    while (node != NULL) {
        if (ptr < node) {
            free_list_node_insert(&fl->head, prev_node, free_node);
            break;
        }
        prev_node = node;
        node = node->next;
    }
    
    fl->used -= free_node->block_size;
    
    free_list_coalescence(fl, prev_node, free_node);
}

void free_list_coalescence(Free_List *fl, Free_List_Node *prev_node, Free_List_Node *free_node) {
    if (free_node->next != NULL && (void *)((char *)free_node + free_node->block_size) == free_node->next) {
        free_node->block_size += free_node->next->block_size;
        free_list_node_remove(&fl->head, free_node, free_node->next);
    }
    
    if (prev_node->next != NULL && (void *)((char *)prev_node + prev_node->block_size) == free_node) {
        prev_node->block_size += free_node->next->block_size;
        free_list_node_remove(&fl->head, prev_node, free_node);
    }
}
```

## Utilities

General utilities needed for free list insertion, removal, and calculating the padding required for the header.

```c
void free_list_node_insert(Free_List_Node **phead, Free_List_Node *prev_node, Free_List_Node *new_node) {
    if (prev_node == NULL) {
        if (*phead != NULL) {
            new_node->next = *phead;
        } else {
            *phead = new_node;
        }
    } else {
        if (prev_node->next == NULL) {
            prev_node->next = new_node;
            new_node->next  = NULL;
        } else {
            new_node->next  = prev_node->next;
            prev_node->next = new_node;
        }
    }
}

void free_list_node_remove(Free_List_Node **phead, Free_List_Node *prev_node, Free_List_Node *del_node) {
    if (prev_node == NULL) { 
        *phead = del_node->next; 
    } else { 
        prev_node->next = del_node->next; 
    } 
}
```


# Red Black Tree Approach

The other way of implementing a free list is with a [red black tree](https://wikipedia.org/wiki/Red%E2%80%93black_tree); the purpose of which is to improve the speed at which allocations and deallocations can be done in. The linked list from above, any operation made is needed to be iterated across linearly (_**O(N)**_). A red black reduces its time complexity to _**O(log(N))**_, whilst keeping the space complexity relatively low (using the same trick as before by storing the tree data within the free memory blocks). And as a consequence of this data-structure approach, a _best-fit_ algorithm may be taken always (in order to reduce fragmentation whilst keeping the allocation/deallocation speed).

The minor increase in space complexity is due to instead of using a singly linked list, a (sorted) doubly linked is required, but as a consequence, it allows coalescence operations in __*O(1)*__ time. 

This implementation is a common aspect in many `malloc` implementations, but note that most `malloc`s utilize multiple different memory allocation strategies that complement each other.

I will not demonstrate how to implement this approach in this article and leave it as an small exercise for the reader. The following diagram may help:

![Free List Red-Black Tree](/images/memory-allocation-strategies/free_list_allocator_red_black_tree.svg#center)


# Conclusion

The free list allocator is a very useful allocator for when you need to general purpose allocator that requires allocations of arbitrary size and out of order deallocations. 

In the next article, I will discuss the [buddy memory allocator](/article/2021/12/02/memory-allocation-strategies-006/).

