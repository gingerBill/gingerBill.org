---
{
    "title": "Relative Pointers",
    "slug": "relative-pointers",
    "author": "Ginger Bill",
    "date": "2020-05-17",
    "categories": [
        "programming language theory",
        "programming languages"
    ],
    "tags": [
        "c",
        "odin"
    ]
}
---

## Absolute Pointers

Pointers are a value type in programming languages that store a memory address. A pointer _references_ a location in memory, and obtaining the value stored at this location in memory is known as _dereferencing_ a pointer.
Pointers are part and parcel of using languages like C, and are an extremely powerful tool. Pointers can be treated as a form of reference type, a value that refers to another typed value in memory.

When most people think of a pointer, they usually treat them as if the pointer refers a physical memory address. I will call this form of pointer an _absolute_ pointer. On most modern machines with virtualized memory, this is rarely the case any more, and for good reasons[^good-reasons]. In the case of virtualized memory spaces, these pointers do not refer to a physical memory address but rather an alias to a physical memory address, in which usually the operating system handles on a per page basis[^not-discuss-virtual-memory]. In a sense, these pointers that belong to virtualized memory spaces can be classed as a form of _relative_ pointer.

At the end of the day, a pointer can be treated/encoded as if it was an integer of some form. Knowing this fact is extremely useful, not just with pointer arithmetic in C/C++, but also relative pointers.

[^good-reasons]: Virtualized memory has many security, safety, and practical benefits.

[^not-discuss-virtual-memory]: I will not discuss how virtual memory works or its benefits in this article.

## Varieties of Relative Pointers

In general, there are four forms of relative pointers:

* Virtual memory pointers---relative to the virtualized memory space
* Global-based pointers---relative to a global variable
* Offset pointers---relative to an explicitly defined base, such as the beginning of a file
* Self-Relative/Auto-Relative pointers---relative to its own memory address

## Global-Based Pointers

MSVC supports a non-official extension to C and C++, [_based pointers_](https://docs.microsoft.com/en-us/cpp/cpp/based-pointers-cpp), which allows the user to declare pointers based on pointers. They can be declared using the `__based` keyword.

```c
void *global_buffer;

struct Linked_List {
	struct Linked_List __based(global_buffer) *next;
	void __based(global_buffer) *data;
};
```

The size of a based pointer is still the same size as a regular pointer, but now the value it points to _relative_ to that value.

This form of relative pointers is useful but because it is based on a globally defined variable, it muddles the type system by coupling it with values which means it cannot be applied as generally. Based pointers can also be replicated in C++ through the use of templates and operator overloading, it also has the advantage of allowing the size of the user defined based pointer to be a different size to a regular pointer:

```c
template <typename Elem, typename Integer_Base>
struct Based_Pointer {
	static void *base = ...;
	Integer_Base offset;

	Elem *operator->() {
		return offset ? (Elem *)((char *)base + offset) : nullptr;
	}

	Elem &operator*() {
		return *this->(operator->)();
	}

	void operator=(Elem *ptr) {
		offset = ptr ? (Integer_Base)((char *)ptr - (char *)base) : 0;
	}
};
```


## Offset Pointers

Another approach which is very similar to based pointers but the base is not explicitly defined by the type itself, which I will refer to as _offset pointers_. I use this approach a lot when designing file formats, which has the base being the start of the file. I originally learnt about this trick from reading the Quake source code for the MD2/MD3/MD4 file formats which used this trick a lot, especially for _relative arrays_.

This shows one of the main advantages of relative pointers: serializeability. This means that the data structure can be `memcpy`'d and still be valid.

Offset pointers can also be replicated in C++ through the use of templates. Similar to the previous user-defined based pointers above, the size of the underlying integer can be any size. One of the cool tricks here is that the data structure's fields do not contain any type information about what data type it pointers but rather that data type is encoded in the constant parameters of the templated data structure.

```c
template <typename T>
struct Offset_Pointer {
	uint32_t offset;
};

template <typename T>
T *get_ptr(void *base, Offset_Pointer<T> ptr) {
	return (T *)((char *)base  + ptr.offset);
}

template <typename T>
struct Offset_Array {
	uint32_t offset;
	uint32_t length;
};

template <typename T>
T *get_array(void *base, Offset_Array<T> array, uint32_t *length) {
	if (length) *length = array.length;
	return (T *)((char *)base  + array.offset);
}
```

The same form of data structure can be implemented in Odin too:
```odin
Offset_Pointer :: struct(T: typeid) {
	offset: u32,
}

get_ptr :: proc(base: rawptr, ptr: $P/Offset_Pointer($T)) -> ^T {
	return (^T)(uintptr(base) + uintptr(ptr.offset));
}


Offset_Array :: struct(T: typeid) {
	offset: u32,
	length: u32,
}

get_array :: proc(base: rawptr, array: $A/Offset_Array($T)) -> []T {
	ptr := (^T)(uintptr(base) + uintptr(ptr.offset));
	return mem.slice_ptr(ptr, int(array.length));
}
```

In the above cases, the `offset` represents the number of bytes away from the _base_. It could be used to represent the number of typed-units instead, but this may require that the base pointer is correctly aligned to the referenced type on some systems.


## Self-Relative Pointers

The last approach is to define the base to be the memory address of the offset itself.

This approach has been used at [Valve](https://www.youtube.com/watch?v=Nsf2_Au6KxU&feature=youtu.be&t=1560), and in some programming languages such as Jonathan Blow's programming language[^first-language] [Jai](https://youtu.be/Z0tsNFZLxSU) and my own language [Odin](https://odin-lang.org/).

[^first-language]: Jai is also the first language I have seen implement self-relative pointers as part of the type system directly.

As with _offset pointer_, self-relative pointers have a similar main advantage: serializeability. This means that the data structure can be `memcpy`'d and still be (mostly) valid.

One issue with self-relative pointers is that for the value itself to be valid, it must be in an addressable memory space (i.e. must be an l-value and not in a register). If a language containing such a concept wanted to ensure the validity of such a data type, any other data type that contains it would also have to be addressable to. This adds a form of virality to the type system, adding a new concept of addressability to the type system directly. However, even if this was enforced, there are cases when a self-relative pointer in non-addressable memory could be perfectly valid.

Another issue is that smaller base integer types for the internal offset value means that they can only be valid over a smaller range than regular pointers.

Relative pointers can be implemented in C++ with the use of templates and operator overloading[^undefined-behaviour-self-relative]:

[^undefined-behaviour-self-relative]: Please note that this is technically undefined behaviour, even if most compilers handle it as expected.

```c
template <typename Elem, typename Integer_Base>
struct Relative_Pointer {
	Integer_Base offset;

	Elem *operator->() {
		return offset ? (Elem *)((char *)&offset + offset) : nullptr;
	}

	Elem &operator*() {
		return *this->(operator->)();
	}

	void operator=(Elem *ptr) {
		offset = ptr ? (Integer_Base)((char *)ptr - (char *)&offset) : 0;
	}
};
```

In the above cases, the `offset` represents the number of bytes away from its own memory address. It could be used to represent the number of typed-units instead, but this may require that the base pointer is correctly aligned to the referenced type on some systems. I personally find this approach less useful in practice even if a stride of greater than 1 does give a larger range to work with in theory (`stride*size_of(Elem_Type)` bytes).

It should also be noted that this implementation of a relative pointer does treat the `0` value as a sentinel value similar to regular pointers.


_Relatively_ recently, I added self-relative pointers to Odin because I found a decent use case for them compared to just using (explicit) offset pointers. I also extended the concept of relative pointers to relative slices too, similar to the _offset array_ example from above.

```odin
relative_data_types :: proc() {
	fmt.println("#relative data types");

	x: int = 123;
	ptr: #relative(i16) ^int;
	#assert(size_of(ptr) == size_of(i16));

	ptr = &x;
	fmt.println(ptr^);


	arr := [3]int{1, 2, 3};
	s := arr[:];
	rel_slice: #relative(i16) []int;
	#assert(size_of(rel_slice) == 2*size_of(i16));

	rel_slice = s;
	fmt.println(rel_slice);
	fmt.println(rel_slice[:]);
	fmt.println(rel_slice[1]);
}
```

Due to the fact that the underlying base integer of a self relative pointer can be specified by the programmer, it can be exploited for a lot of useful purposes. One basic example could be having a very small linked list where the next item in the list is defined to be within a certain range. This means you could defined a relative pointer to be stored in a single byte if necessary:

```odin
Node :: struct {
	data: u8,
	next: #relative(i8) ^Node,
}
#assert(size_of(Node) == 2);
```

## Summary

Relative pointers allow for a lot more flexibility compared to "traditional" pointers, and a godsend with regards to serialization. They do have many advantages and disadvantages compared to "traditional" pointers, and the programmer must be absolutely aware of them before using them. Relative pointers can be easily serialized making them ideal for file formats, and relative pointers can be as small as they need to be rather than taking up the same size of a regular pointer (e.g. on 64-bit platforms, a pointer is 64 bits which might be a lot more than the user requires for a specific problem).



## Relevant Videos

### Sergiy Migdalskiy - Performance Optimization, SIMD and Cache (at 26 minutes)
<div class="youtube">
	<iframe width="560" height="315" src="https://www.youtube.com/embed/Nsf2_Au6KxU?t=1560" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>

### Jonathan Blow - Demo: Relative Pointers
<div class="youtube">
	<iframe width="560" height="315" src="https://www.youtube.com/embed/Z0tsNFZLxSU" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
