---
{
    "title": "String Type Distinctions",
    "slug": "string-type-distinctions",
    "author": "Ginger Bill",
    "date": "2024-04-05",
    "categories": [
        "software"
    ],
    "tags": [
        "odin",
        "c",
        "strings"
    ]
}
---


**[Originally from a Twitter Thread]**

[Original Twitter Post](https://twitter.com/TheGingerBill/status/1542603515054497792)


One thing many languages & API designers get wrong is the concept of a string. I try to make a firm distinction between:

1) string value (`string` or `char const *`)
2) string builder (`strings.Builder` or `realloc+snprintf`)
3) Backing buffer for a string (`[]byte` or `char *`)

They are not equivalent even if you can theoretically use them as such, and so many garbage collected language use them as such.

They have different use cases which don't actually overlap in practice. Most of the issues with strings come from trying to merge concepts into one.


In [Odin](https://odin-lang.org/), the distinction between a string value and byte array is very important. `string` is semantically a string and not an array of 8-bit unsigned integers. There is an implied character encoding (UTF-8) as part of the value. `string` is also an immutable value in Odin.

Having a string be immutable allows for a lot of optimizations, but in practice, you never want to mutate the string value itself once it has been created. And when you do mutate it, it most definitely a bug.

This is why it is important to make a distinction between #1 and #3 and separate the concepts.

Another way to conceptualize the ideas is as the following:

* (3) is the "backing data", an arena of sorts (fixed or dynamic)
* (2) are the operations on that buffer (fixed or dynamic)
* (1) is the final value that points to (3) and produced by (2)

Coupled with Run-Time Type Information (RTTI), having a distinction between []byte and string allows for a lot of really decent (de)serialization tooling, especially for "magical" printing (e.g. fmt.println).

P.S. Even C makes a distinction between a string an array of integers