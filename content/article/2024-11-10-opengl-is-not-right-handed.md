---
{
    "title": "OpenGL is not Right-Handed",
    "slug": "opengl-is-not-right-handed",
    "author": "Ginger Bill",
    "date": "2024-11-10",
    "categories": [
        "software",
        "design",
        "mathematics",
        "opengl"
    ],
    "tags": [
        "opengl",
        "odin",
        "glsl"
    ]
}
---


The original Twitter thread: https://x.com/TheGingerBill/status/1508833104567414785

----

I have a huge gripe when I read articles/tutorials on OpenGL: most people have no idea what they are talking about when it comes to coordinate systems and matrices.

Specifically: OpenGL is **NOT** right-handed; the confusion over column-major "matrices".

Let's clear up the first point. Many people will say OpenGL uses a right-handed coordinate system. Loads of articles/tutorials will keep repeating the view that OpenGL uses a right-handed coordinate system. So the question is, why do people think this?

Modern OpenGL only knows about the _Normalized Device Coordinates (NDC)_, which is treated as if it is a left-handed 3D coordinate space. This means that OpenGL "is" left-handed, not right-handed as many articles will tell you.

The origin of "right-handed" comes from the fixed-function days, where Z entries in the functions `glOrtho` and `glFrustum` were negated, which flips the handedness. Back in those days, it forced users to pretty much had to use a right-handed world space coordinate system.
The Z-axis flip is to convert from the _conventional_ world/entity space to the left handed Normalized Device Coordinates (NDC). And modern OpenGL only knowns the NDC.

![image](/images/proj_to_ndc.jpg)

## So why has this false idea persisted?

* It __"was"__ true.
* It distinguishes it from Direct3D.
* People just repeat things w/o understanding it.
* Most who use OpenGL don't really know anything about the GPU nor what the NDC is.

**PLEASE READ THE SPEC BEFORE MAKING TUTORIALS!**

Now for the **"column-major"** part.

This part is actually overloaded and means two things: what is the default vector kind (column-vector vs row-vector), and what is the internal memory layout of a matrix (array-of-column-vectors vs array-of-row-vectors).

A good article on this has been written by [@rygorous](https://x.com/rygorous) regarding this so I won't repeat it too much. [Row major vs. column major, row vectors vs. column vectors](https://fgiesen.wordpress.com/2012/02/12/row-major-vs-column-major-row-vectors-vs-column-vectors/).

It works because (A B)^T = B^T A^T (where T is the transpose). But where does this difference in convention come from? My best hypothesis is the physics vs mathematics distinction (just like everything else). In physics you default to using column-vectors and in mathematics you default to using row-vectors. It's just a convention.

It's just another distinction between OpenGL and Direct3D which makes very little difference at the end of the day, especially since in both GLSL and HLSL, you can specify whether a matrix is `row_major` or `column_major` if necessary.

I personally prefer column-vectors because of my background in physics but all that is important is that you are consistent/coherent in your codebase, and make sure that all conventions are make extremely clear: handedness, axis direction, "Euler"-angle conventions, units, etc.

GLSL also doesn't help it in that the matrix types are written "backwards" to most other conventions. `mat2x3` in GLSL means a 3 row by 2 column matrix.

GLSL does not work for this well known mnemonic:

* (A, B) x (B, C) = (A, C)
* e.g. (3 by 4) x (4 by 1) = (3 by 1)

Then there is the other related issue of having matrices that are stored in the array-of-column-vector layout: many programming languages don't have a built-in concept of a matrix & an array-of-row-vectors will be easier to write as an array-of-column-vectors because it is text.

It is common to write a matrix in a language like the following `float x[3][3] = {...};` and if you are trying to adhere to "column-major" memory layout, then you will have to write it down transposed compared to how you would write it down on paper.

The [Odin](https://odin-lang.org/) programming language has both built-in array programming (vectors & swizzling) and matrices, and as a result, this textual issue is completely removed! It even allows you to treat vectors as if they are column-vectors or row-vectors, and things will "just work"! You can even specify the memory layout of the matrices if needed too with `#column_major matrix[R, C]T` (the default) or `#row_major matrix[R, C]T`.