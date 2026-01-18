---
{
    "title": "A Defer Statement For C++11",
    "slug": "defer-in-cpp",
    "author": "Ginger Bill",
    "date": "2015-08-19",
    "categories": [
        "C++"
    ],
    "tags": [
        "C++"
    ],
    "aliases": [
        "/article/defer-in-cpp.html"
    ]
}
---


One of my favourite things about [Go](https://golang.org/) is the `defer` statement. The `defer` statement pushes a function call onto a list; the list of saved calls in called when the function returns.

Imitating this is C++ is impossible. Instead of calling when the function calls, you can call at the end of scope; this is a better approach for C++. This is similar to how [D has scope(exit)](http://dlang.org/statement.html#ScopeGuardStatement).

## C++11 Implementation

```cpp
template <typename F>
struct privDefer {
	F f;
	privDefer(F f) : f(f) {}
	~privDefer() { f(); }
};

template <typename F>
privDefer<F> defer_func(F f) {
	return privDefer<F>(f);
}

#define DEFER_1(x, y) x##y
#define DEFER_2(x, y) DEFER_1(x, y)
#define DEFER_3(x)    DEFER_2(x, __COUNTER__)
#define defer(code)   auto DEFER_3(_defer_) = defer_func([&](){code;})
```

## Explanation

One of the most common examples for this in Go is files.

```go
import "os"

func someFunc() {
	file, err := os.Open("filename.ext", os.O_RDONLY, 0)
	if err != nil {
		// handle error
		return
	}
	defer os.Close(file)
	// Do whatever

	return // No need to close file explicitly
}
```

In C/C++, before every return, `fclose` must be called.

```cpp
void some_func(void) {
	FILE *file = fopen("filename.ext", "rb");
	if (file == NULL) {
		// handle error
		return;
	}

	if (someTest) {
		// ...
		fclose(file); // Have to explicitly close file
		return;
	}


	fclose(file); // Have to explicit close file
}
```

You may say that RAII in C++ solves this issue but this would require a class wrapper. `defer` allows for the same thing as RAII but without manually creating a wrapper type. Also, `defer` conceptually links the creation with the destruction without hiding it.

## Examples In C++ Code

```cpp
void some_func(void) {
	FILE *file = fopen("filename.ext", "rb");
	if (file == NULL)
		return;
	defer (fclose(file));

	u8 *buffer = (u8 *)allocate(64 * sizeof(u8));
	if (buffer == NULL)
		return; // fclose is called automatically
	defer (deallocate(buffer));

	defer ({
		printf("You can even defer ");
		printf("an entire block too!");
	});

	// Do whatever...
}
```

I use this regularly within C++ code as it is very useful when dealing with C code bases.

There are numerous other implementations of this too and I have linked to these below.


## Other Implementations

* [Ignacio Castaño](http://the-witness.net/news/2012/11/scopeexit-in-c11/)
* [~~Kristoffer Grönlund~~](http://kri.gs/2013/01/20/defer-cpp/) (Page is missing)

## Caveat

Because the `defer` statement is called at the end of scope rather than function return, a Go programmer for example would do something like this:

```c
void another_func(void) {
	for (int i = 0; i < 4; i++)
		defer (printf(" %d", i));
	printf(" Hello");
}
```

to return ` Hello 3 2 1 0`. However, it will return ` 0 1 2 3 Hello`. I personally prefer the scope behaviour but that is just a matter of opinion.
