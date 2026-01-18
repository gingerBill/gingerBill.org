---
{
    "title": "Structured Control Flow (Brain Dump)",
    "slug": "structured-control-flow",
    "author": "Ginger Bill",
    "date": "2021-02-02",
    "categories": [
        "philosophy",
        "psychology",
        "ontology",
        "programming philosophy",
        "programming languages"
    ],
    "tags": [
        "philosophy",
        "programming",
        "brain dump"
    ]
}
---


**Note:** This is a "brain dump" article, and subject to be cleaned up.

## Categories of Structured Control Flow

* Procedure call
	* `foo(123, true)`
* Terminating
	* `return`
* Conditional
	* `if`, `if-else`, `switch`
* Looping
	* `for` - loop with initial statement, condition, post statement, and body
	* `for-in` - loop with a value to be iterated over
	* `while` - loop with condition then body
	* `do-while` - loop with body then condition
* Branching
	* `break` - go to end outside of the control statement
	* `continue` - skip to the end of a loop
	* `fallthrough` - merge two switch case bodies, to have multiple entry points to the merged body
	* Labels on other control flow statements
* Deferred
	* `defer`/`scope(exit)`


### Pseudo/Partial Categories

* Structured Exception Handling (not specifically [Microsoft's SEH](https://docs.microsoft.com/en-us/cpp/cpp/structured-exception-handling-c-cpp)
	* `try`, `catch`
* Default (named) return values
	* `foo :: proc(x: int) -> (val: int, err: Error) { ... }`
* `async`/`await`
* `yield`/`resume`


### Examples of Extensions

Examples in Odin

```odin
foo :: proc(x: int) -> (val: int, err: Error) {
	defer if err != nil {
		// handle clean up
	}

	if x > 0 {
		err = .Bad_Error;
	} else {
		val = -x*2 + 1;
	}

	// returns all the named return values without having the manual specify them
	return;
}
```

```odin
the_cases: switch x {
case 1:
	loop: for y > 0 {
		do_thing(&y);
		if y == 3 {
			break the_cases;
		} else if y == 2 {
			continue loop;
		}
		do_other_thing(&y);
	}
case 2, 3:
	do_thing(&y);
	fallthrough;
case 4:
	do_other_thing(&y);
}
```

## Categories of Unstructured Control Flow

* Procedure call
	* [x86: Call instruction](https://en.wikibooks.org/wiki/X86_Assembly/Control_Flow#Function_Calls)
* Terminating
	* [x86: Return instruction](https://en.wikibooks.org/wiki/X86_Assembly/Control_Flow#Function_Calls)
* Comparison
	- [x86: Comparison instructions](https://en.wikibooks.org/wiki/X86_Assembly/Control_Flow#Comparison_Instructions)
* Jump
	- [x86: Unconditional jump instructions](https://en.wikibooks.org/wiki/X86_Assembly/Control_Flow#Unconditional_Jumps)
	- [x86: Conditional jump instructions](https://en.wikibooks.org/wiki/X86_Assembly/Control_Flow#Jump_Instructions)
	- [goto](https://en.wikipedia.org/wiki/Goto)
* Indirect Jump (goto by value)
	- [GNU C: Labels as values (jump tables)](https://gcc.gnu.org/onlinedocs/gcc-3.4.0/gcc/Labels-as-Values.html
)
* Stack Unwinding (exceptions)
	- [longjmp/setjmp](https://en.wikipedia.org/wiki/Setjmp.h)
	- [Interrupts](https://en.wikipedia.org/wiki/Interrupt)
