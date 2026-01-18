---
{
    "title": "Memory Allocation Strategies - Part 1",
    "description": "Thinking About Memory and Allocation",
    "slug": "memory-allocation-strategies-001",
    "author": "Ginger Bill",
    "date": "2019-02-01",
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

Memory allocation seems to be something many people struggle with. Many languages try to automatically handle memory for you using different strategies: garbage collection (GC), automatic reference counting (ARC), resource acquisition is initialization (RAII), and ownership semantics. However, trying to abstract away memory allocation comes at a higher cost than most people realize.

Most people are taught to think of memory in terms of the stack and the heap, where the stack is automatically grown for a procedure call, and the heap is some magical thing that you can use to get memory that needs to live longer than the stack. This dualistic approach to memory is the wrong way to think about it. It gives the programmer the mental model that the stack is a special form of memory[^stack-pointer] and that the heap is magical in nature.
[^stack-pointer]: Most architectures have register dedicated as a pointer to the stack, that is added because it is used frequently and pragmatically makes sense to do so.

Modern operating systems virtualize memory on a per-process basis. This means that the addresses used within your program/process are specific to that program/process only. Due to operating systems virtualizing the memory space for us, this allows us to think about memory in a completely different way. Memory is not longer this dualistic model of _the stack_ and _the heap_ but rather a monistic model where everything is virtual memory. Some of that virtual address space is reserved for procedure stack frames, some of it is reserved for things required by the operating system, and the rest we can use for whatever we want. This may sound similar to original dualistic model that I stated previously, however, the biggest difference is realizing that the memory is virtually-mapped and linear, and that you can split that linear memory space in sections.

![Virtual Memory](/images/memory-allocation-strategies/virtual_memory.svg#center)

# Thinking About Allocation

When it comes to allocation, there are three main aspects to think about[^fourth-aspect]:
[^fourth-aspect]: Memory safety is another aspect to think about but I will not cover that in this series as that requires a separate set of solutions and trade-offs. In the domains that I deal with, memory safety is not a huge concern.

* The size of the allocation
* The lifetime of that memory
* The usage of that memory

I usually imagine the first two aspects in the following table, for most problem domains, where the percentages signify what proportion of allocations fall into that category:

<table>
  <thead>
      <tr>
          <th style="text-align: right"></th>
          <th style="text-align: center">Size Known</th>
          <th style="text-align: center">Size Unknown</th>
      </tr>
  </thead>
  <tbody>
      <tr>
          <td style="text-align: right"><strong>Lifetime Known</strong></td>
          <td style="text-align: center">95%</td>
          <td style="text-align: center">~4%</td>
      </tr>
      <tr>
          <td style="text-align: right"><strong>Lifetime Unknown</strong></td>
          <td style="text-align: center">~1%</td>
          <td style="text-align: center">&lt;1%</td>
      </tr>
  </tbody>
</table>


In the top-left category (Size Known + Lifetime Known), this is the area in which I will be covering the most in this series. Most of the time, you do know the size of the allocation, or the upper bounds at least, and the lifetime of the allocation in question.

In the top-right category (Size Unknown + Lifetime Known), this is the area in which you may not know how much memory you require but you do know how long you will be using it. The most common examples of this are loading a file into memory at runtime and populating a hash table of unknown size. You may not know the amount of memory you will need a priori and as a result, you may need to "resize/realloc" the memory in order to fit all the data required. In C, `malloc` et al is a solution to this domain of problems.

In the bottom-left category (Size Known + Lifetime Unknown), this is the area in which you may not know how long that memory needs to be around but you do know how much memory is needed. In this case, you could say that the "ownership" of that memory across multiple systems is ill-defined. A common solution for this domain of problems is reference counting or ownership semantics.

In the bottom-right category (Size Unknown + Lifetime Unknown), this is the area in which you have literally no idea how much memory you need nor how long it will be needed for. In practice, this is quite rare and you _ought_ to try and avoid these situations when possible. However, the general solution for this domain of problems is garbage collection[^garbage-collection].

[^garbage-collection]: Garbage collection is one of the only terms in computers science where the term actually reflects its real world counter part.

Please note that in domain specific areas, these percentages will be completely different. For instance, a web server that may be handling an unknown amount of requests may require a form of garbage collection if the memory is limited or it may be cheaper to just buy more memory.


# Generations of Lifetimes

For the common category, the general approach that I take is to think about memory lifetimes in terms of generations. An _allocation generation_ is a way to organize memory lifetimes into a hierarchical structure[^generation-cut-and-dry].
[^generation-cut-and-dry]: These generations are not cut-and-dry and allocations can span across this spectrum of lifetimes (like in real life).
Memory within these generations usually get allocated and freed at the same time (born, live, and die together).

* **Permanent Allocation**: Memory that is never freed until the end of the program. This memory is persistent during program lifetime.

* **Transient Allocation**: Memory that has a cycle-based lifetime. This memory only persists for the "cycle" and is freed at the end of this cycle. An example of a cycle could be a frame within a graphical program (e.g. a game) or an update loop.

* **Scratch/Temporary Allocation**: Short lived, quick memory that I just want to allocate and forget about. A common case for this is when I want to generate a string and output it to a log.


## Memory Hierarchies

As I previously stated, the monistic model of memory is the preferred model of memory (on modern systems). This generational approach to memory orders the lifetime of memory in a hierarchical fashion. You could still have pseudo-permanent memory within a transient allocator or a scratch allocator, as the difference is thinking about the relative usage of that memory with respect to its lifetime. Thinking locally about how memory is used aids with conceptualizing and managing memory --- the human brain can only hold so much.

The same localist thought process can be applied to the memory-space/size of which I will be discussing in later articles in this series.


# The Compiler's Knowledge of the Program

In languages with automatic memory management, many people assume that the compiler knows a lot about the usage and lifetimes of your program. __This is false__. You know much more about your program than the compiler could ever know. In the case of languages with ownership semantics (e.g. Rust, C++11), the language may aid you in certain cases, but it struggles to know (if it is at all possible) when it should pre-allocate or free in bulk. This is compiler ignorance can lead to a lot of performance issues.

My personal issue with regards to ownership semantics is that it naturally focuses on the ownership of single objects rather than in systems[^ownership-systems]. Such languages also have the tendency to couple the concept of ownership with the concept of lifetime, which are not necessarily linked.

[^ownership-systems]: I know in languages such as Rust, you can describe the lifetime of an object to be linked to a system however, with the memory allocation strategies I will be discussing later, the Rust code that would be required pretty much acts as if you will bypass the ownership semantics entirely and have a liberal use of `unsafe`.


# Coming Next

In this series, I will discuss the different kinds of memory models and allocation strategies that can be used. These are the topics that will be covered:

* Sequential (Contiguous) Allocations
* Virtual Memory
* Out of Order Allocators and Fragmentation
* `malloc`
* Hierarchies of Allocators
* Automatic Lifetime Allocations
* Allocation Grouping and Mental Models
