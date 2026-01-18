---
{
    "title": "Exceptions&mdash;And Why Odin Will Never Have Them",
    "slug": "exceptions---and-why-odin-will-never-have-them",
    "author": "Ginger Bill",
    "date": "2018-09-05",
    "categories": [
        "odin",
        "programming language theory"
    ],
    "tags": [
        "odin"
    ]
}
---

Article was originally posted here: <https://odin.handmade.network/blogs/p/3372-exceptions_-_and_why_odin_will_never_have_them>


Original Comments:

* <https://github.com/odin-lang/Odin/issues/256#issuecomment-418073701>
* <https://github.com/odin-lang/Odin/issues/256#issuecomment-418289626>

There will never be software exceptions in the traditional sense. I hate the entire philosophy behind the concept.
Go does have exceptions with the defer, panic, recover approach. They are weird on purpose. Odin could have something similar for exceptional cases.
You can the exact same semantics as a try except block by using a switch in statement. The same is true in Go. The difference is that the stack does not need to be unwinded and it's structural control flow.
Odin has discriminated unions, enums, bit sets, distinct type definitions, any type, and more. Odin also have multiple return values. Use the type system to your advantage.
I do hate how most languages handle "errors". Treat errors like any other piece of code. Handle errors there and then and don't pass them up the stack. You make your mess; you clean it.

---------

To expand on what I mean by this statement:

> You can the exact same semantics as a try except block by using a switch in statement.

Python:
```python
try:
	x = foo()
except ValueError as e:
	pass # Handle error
except BarError as e:
	pass # Handle error
except (BazError, PlopError) as e:
	pass # Handle errors
```

Odin:
```odin
Error :: union {
	ValueError,
	BarError,
	BazError,
	PlopError,
}

foo :: proc() -> (Value_Type, Error) { ... }

x, err := foo();
switch e in err {
case ValueError:
	// Handle error
case BarError:
	// Handle error
case BazError, PlopError:
	// Handle errors
}
```


The semantics are very similar in this case however the control flow is completely different. In the exceptions case (shown with Python), you enclose a block of code and catch any exceptions that have been raised. In the return value case (shown with Odin), you test the return value explicitly from the call.
Exceptions require unwinding the stack; this can be slower[^slower] when an exception happens compared to the fixed small cost of a return value.

[^slower]: Theoretically exceptions can be just as fast a return statement because that's effectively what it is. However, most modern languages do a lot more than that to implement exceptions and they can be a lot slower in pratice.


In both cases, a "catch all" is possible:

Python:
```python
try:
	x = foo()
except Exception:
	pass # An error has happened
```

Odin:
```odin
x, err := foo();
if err != nil {
	// An error has happened
}
```

One "advantage" many people like with exceptions is the ability to catch any error from a block of code:
```python
try:
	x = foo()
	y = bar(x)
	z = baz(y)
except SomeError as e:
	pass
```


I personally see this as a huge vice, rather than a virtue. From reading the code, you cannot know where the error comes from. Return values are explicit about this and you know exactly what and where has caused the error.

One of the consequences of exceptions is that errors can be raised anywhere and caught anywhere. This means that the culture of pass the error up the stack for "someone else" to handle. I hate this culture and I do not want to encourage it at the language level. Handle errors there and then and don't pass them up the stack. You make your mess; you clean it.


Go's built-in `error` type has the exact same tendency of people return errors up the stack:
```go
if err != nil {
	return nil, err
}
```
From what I have read, most people's complaints about the Go error handling system is the if err != nil, and not the return nil, err aspect. Another complain people have is that this idiom is repeated a lot, that the Go team think it is necessary to add a construct to the language reduce typing in the draft [Go 2 proposal](https://go.googlesource.com/proposal/+/master/design/go2draft-error-handling-overview.md).


-----------------


I hope this has cleared up a lot of the questions regarding Odin's take on error handling. I think error handling ought to be treated like any other piece of code.


> With many rules, there will be unexpected emergent behaviour.

P.S. If you really want "exceptions", you can `longjmp` until the cows come home.
