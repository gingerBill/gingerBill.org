---
{
    "title": "Reverse Engineering Alembic",
    "slug": "reverse-engineering-alembic",
    "author": "Ginger Bill",
    "date": "2022-07-11",
    "categories": [
        "reverse engineering",
        "software",
        "file format"
    ],
    "tags": [
        "reverse engineering",
        "odin",
        "c",
        "c++",
        "alembic",
        "interchange",
        "format"
    ]
}
---

For my work at [JangaFX](https://jangafx.com/), we require the use of the [Alembic](http://www.alembic.io/) interchange file format. We have been using other libraries which wrap reading the Alembic file format but because it is not the native library, it has numerous issues due to the generic interface.

I spent nearly 4 days trying to get the official Alembic C++ API, <https://github.com/alembic/alembic/>, to compile correctly and then use the API itself. Numerous times the compilation would get corrupted (it compiled but none of the tests even ran) and when I got it work (on another machine), the API itself was a labyrinth to navigate. After this ordeal I decided to see how difficult it would be to create my own reader, and then writer, for the format from scratch.

I don't really like to "reinvent the wheel" when I don't have to, but in this case, the C++ API was an absolute nightmare and I've spent more time trying to get that to work rather than actually solving the problem I had.

Making my own library for Alembic turned out to be a little more work than I expected. Even though it is an "open source" format, it is effectively completely undocumented, and the bits that are documented refer mostly to specific (not all of them) schemas rather than the internal format.

This article will be a basic document of the internals of the Alembic file format.

## What Actually is Alembic?

Through my journey into "discovering" the Alembic format, I found out that _Alembic_ is not actually a file format but masquerades as one. It is in fact two file formats with different memory layouts which can be determined based on the [magic file signature](https://en.wikipedia.org/wiki/List_of_file_signatures):

* [HDF5](https://www.hdfgroup.org/)
* Ogawa[^ogawa-flavour]


[^ogawa-flavour]: Technically it's Ogawa-Flavour Alembic with its own specific meta-schema, of which I will get to that later in the article.

### HDF5

HDF5 is a hierarchical data format which is commonly used to store and organize large amounts of data in a _hierarchical_ fashion. It's commonly used in the scientific field rather than the visual effects industry, and as such, this internal format is rarely used for storing data that would be useful for our tasks for importing (e.g. meshes, cameras, animations, etc). HDF5 is effectively a storage format for database-like data, it's a very good format in terms of usage (I will admit I have no idea about its internal design).

It appears that the vast majority of "Alembic" files are not in the HDF5 format but in Ogawa.

### Ogawa

The main format of concern is named _Ogawa_. It's a little-endian binary format (thank goodness) which was designed to be readable in-place for efficient multi-threaded data reading. This part of the file format is luckily documented[^ogawa-spec], and small enough that I could write it in a [single tweet](https://twitter.com/TheGingerBill/status/1536484140006227968).

[^ogawa-spec]: <https://github.com/alembic/alembic/wiki/Ogawa-Specification>

Similar to HDF5, Ogawa is a hierarchical data format that is simple to read, but differing from HDF5, it is completely uncompressed.


**Note:** When decoding binary formats, it is very useful if have a _hex-viewer_ to see the bytes in a readable way. On Windows, I would recommend either [Hex Editor Neo](https://www.hhdsoftware.com/free-hex-editor) or [010 Editor](https://www.sweetscape.com/010editor/). Even though the Ogawa format is mostly documented on that GitHub Wiki page, I still required a _hex-viewer_ from time to time to ensure everything was laid out as I expected, especially for the more complex embedded data.

Its header is very simple:

```odin
MAGIC :: "Ogawa"

File_Header :: struct {
	magic:   [5]byte, // "Ogawa"
	wflag:   enum byte { writing = 0x00, closed = 0xff },
	version: [2]byte, // {0, 1}
	root_group_offset: u64le,
}
```

The magic signature is just 5 bytes containing the ASCII characters `Ogawa`, followed by a byte-wide flag which states whether the file is open or closed to writing, followed by 2 bytes specifying the version of the format (of which will always be `[2]byte{0, 1}`), and finally followed by an offset to the root "group".

The `wflag` is there to allow writing to the file and prevent other applications from trying to read it whilst it is not finished. It begins off as `0x00` and then once the file is finished, it becomes `0xff`. For my Alembic writer, I was storing the data in a memory buffer and then writing the entire data to the file at once, meaning this byte-wide flag was not that useful.

All grouped-based offsets in the Ogawa format are stored in a 64-bit unsigned little endian integer (`u64le`) representing the number of bytes from the base of the file[^offset-design].

[^offset-design]: I'm a huge fan of file binary formats designed this way where they use effectively internal [relative pointers](/article/2020/05/17/relative-pointers/), of which I should explain my preferred approach to designing binary file format in the future.

These group-based offsets come in two different flavours: an _Ogawa Group_ or an _Ogawa Data (byte stream)_. The offset encodes a flag in its highest bit (63rd bit) to indicate which flavour: Group if 0 and Data if 1. The remaining 63-bits represent the offset to this specific kind of value; if the remaining 63-bits are all zero, it means it is a terminating value (not pointing to any actual memory).

A _Group_ begins with a `u64le` representing the number of children following it in memory (of which all are another offset, `u64le`). If the value is 0, this represents an empty group that has no children.
```odin
// Pseudo-Odin
Group :: struct {
	num_children: u64le,
	children:     [num_children]u64le,
}
```

A _Byte-Stream_ begins with a `u64le` representing the number of bytes following it in memory.
```odin
// Pseudo-Odin
Data :: struct {
	num_bytes: u64le,
	bytes:     [num_bytes]byte,
}
```

This basic file format is very simple to read but it has zero semantic information to make it useful for something like an interchange format. The semantic structure is what I am calling the _Meta-Schema for Alembic_.


## The Meta-Schema of Alembic on top of Ogawa

To begin decoding the format, I created a basic Ogawa to JSON viewer to see the tree structure of the file format. As I began to understand more of the format, the JSON structure became much more complex but richer in semantic data.

**Note:** I highly recommend converting any hierarchical format into something like JSON just as a debug view alone, since there are many tools such as [Dadroit](https://dadroit.com/) that allow for easy viewing. But if you want to make your own format and viewer with your own tools, go ahead!

After a bit of exploring, the meta-schema begins with the following data for the root group:

* 6 children minimum
	* Every file that I tested always began with 6 children
* Child `0` is a byte-stream which stores an `i32le` containing something akin to the archive version (always appeared to `0`)
* Child `1` is a byte-stream which stores an `i32le` containing the file version which must be `>=10000`
	* From the reverse engineering, it appears that the value stored in decimal represents the file format: e.g. `10505` represents `Alembic 1.5.5`
* Child `2` is a group to the first _Objects_ based at the root
* Child `3` is a byte-stream which stores the file's _metadata_
* Child `4` is a byte-stream which stores the time samples and max samples information
* Child `5` is a byte-stream which stores indexed _metadata_ which nested _properties_ may use later
	* In my Alembic writer, I never used any _indexed metadata_ and just did everything inline since it was easier to handle

From this point on, it can be assumed that a lot of the data is unaligned to its natural alignment and must be read accordingly.


### Time Samples and Max Sample

This data is only stored at the root group (child `4`) and referenced elsewhere by index.

Each value containing the samples is stored in contiguous memory:
```odin
// Pseudo-Odin
Chrono :: distinct f64le

Time_Samples :: struct #packed {
	max_sample:     u32le,
	time_per_cycle: Chrono,
	num_samples:    u32le,
	samples:        [num_samples]Chrono,
}
```

This memory needs to be read in order in order to determine the number of samples.

### Metadata

All metadata is stored as a string. Each entry is a key and value separated by the ASCII character `=`, and each entry is separated by `;`. Deserializing this is a very simple operation to do in most languages.
These strings are _NOT_ **NUL** terminated like in C because they are bounded by a length that usually prefixes it. As I am using [Odin](https://odin-lang.org/), its `string` type is length-bounded making this process a lot easier to use compared to C.

The indexed metadata is only stored at the root group (child `5`) and referenced elsewhere by index.

Each value is stored in contiguous memory:
```odin
// Pseudo-Odin
Index_Metadata_Entry :: struct {
	metadata_size:   u8,
	metadata_string: [metadata_size]u8,
}
```

The maximum number of index metadata entries allowed is `254` (`0xfe`).

### Object Data

The root group stores an offset to the first group (child `2`) representing _Object Data_.

Object data contains a list of the nested children as well properties for its "this" _Object_.

* Child `0` stores the data for the properties in the form of _Compound Property Data_
* Children `1..<n-1` stores the objects
* Child `n-1` stores the data for the child _Object Headers_

### Object Headers

The Object Header are stored in contiguous memory for each entry but depending on the value of its `metadata_index` (see below) will determine whether the metadata value is stored inline or stored in the indexed metadata at the root group.

* If `metadata_index` is equal to `0xff`, the metadata is stored directly after it
* If `metadata_index` is any other value, it represents the index to the metadata stored at the root group (this value must be less than the number of index metadata entries otherwise it is a invalid file)

```odin
// Pseudo-Odin
Object_Header :: struct #packed {
	name_size:      u32le,
	name:           [name_size]u8,
	metadata_index: u8,
}

Object_Header_Inline :: struct #packed {
	using header:    Object_Header,
	metadata_size:   u32le,
	metadata_string: [metadata_size]u8,
}
```

### Property Data

There are three different forms of properties that may be stored within Alembic: Scalar, Array, and Compound.

Child `0` of the _Object Data_ group must represent a _Compound_ property data.

#### Compound Property Data

_Compound property data_ is a group which stores `N` children for `N-1` properties. It's effectively a hash map (like a JSON object) containing a keys, properties, and the values of more property data.

* Children `0..<N-1` represent the nested property data which is denoted by the property headers
* Child `N-1` is a byte-stream which contains the compound property headers

In the _compound property headers_ byte-stream, it contains a list of the nested of each property header.

**n.b.** The property headers are the weirdest aspect of the entire format and not simply expressible in terms of basic data structures and require a lot of logic for the encoding.

```odin
// Pseudo-Odin
Property_Header :: struct #packed {
	info: u32le,
	when Compound { // determined from info
		next_sample_index: INT_BASED_ON_SIZE_HINT,
		if info & 0x0200 != 0 {
			first_changed_index: INT_BASED_ON_SIZE_HINT,
			last_changed_index:  INT_BASED_ON_SIZE_HINT,
		}
		if info & 0x0100 != 0 {
			time_sampling_index: INT_BASED_ON_SIZE_HINT,
		}
	}

	name_size: INT_BASED_ON_SIZE_HINT,
	name: [name_size]u8,
}
```

`info` is an `u32le` which encodes information about the property:

* Bits `0..<2` : represents the property type:
	* `0` = `Compound`
	* `1` = `Scalar`
	* `2` = `Array`
* Bits `2..<4` : represents the size hint `INT_BASED_ON_SIZE_HINT`
	* `0` = `u8`
	* `1` = `u16le`
	* `2` = `u32le`
* Bits `4..<8` : represents the plain old data type:
	* `0` = `bool` (byte)
	* `1` = `u8`
	* `2` = `i8`
	* `3` = `u16le`
	* `4` = `i16le`
	* `5` = `u32le`
	* `6` = `i32le`
	* `7` = `u64le`
	* `8` = `i64le`
	* `9` = `f16le`
	* `10` = `f32le`
	* `11` = `f64le`
	* `12` = `u8` string
	* `13` = `wchar_t` string
		* I am yet to see this in the wild yet
* Bit `9` states whether the `first_changed_index` and `last_changed_index` is set for a Compound type
* Bit `11` if set, `first_changed_index` and `last_changed_index` equal `0`
* If bits `9` and `11` are not set, `first_changed_index = 1`, `last_changed_index = next_sample_index-1`
* Bit `10` states if the property data is homogenous
* Bits `12..<20` : represents the "extent" of the value. e.g. `[][extent]type`
* Bits `20..<28` : represents the `metadata_index`. This follows the same rules as _Object Headers_
	* If `metadata_index` is equal to `0xff`, the metadata is stored directly after it
	* If `metadata_index` is any other value, it represents the index to the metadata stored at the root group (this value must be less than the number of index metadata entries otherwise it is a invalid file)
* Bits `28..<32` : I have no idea what these represent, if anything

For the property headers containing inline metadata:

```odin
// Pseudo-Odin
Property_Header_Inline :: struct #packed {
	using header:    Property_Header,
	metadata_size:   INT_BASED_ON_SIZE_HINT,
	metadata_string: [metadata_size]u8,
}
```


#### Scalar Property Data

Scalar property data is constant if `first_changed_index == 0` in the property header. Number of samples is equal to the `next_sample_index`.

The indexed samples are stored in the children groups on the property data stored beginning at the relative offset 0.

Depending on the whether the samples are constant or not, the actual index needs to be mapped using the following procedure:

```odin
verify_index :: proc(p: Property, index: u32) -> u32 {
	assert(index < u32(p.next_sample_index))

	i := u32(index)
	if i < p.first_changed_index {
		return 0
	} else if p.first_changed_index == p.last_changed_index && p.first_changed_index == 0 {
		return 0
	} else if i >= p.last_changed_index {
		return u32(p.last_changed_index - p.first_changed_index + 1)
	}
	return i - p.first_changed_index + 1
}
```

The data for each sample contains both the key/hash of the data and the _uncompressed_ data.
The hash is stored at the beginning; is represented as a 16-byte (128 bit) [SpookyHash](http://burtleburtle.net/bob/hash/spooky.html).
The data after that is stored after this hash.

```odin
num_samples := u32(p.next_sample_index)
for sample_index in 0..<num_samples {
	index := verify_index(p, sample_index)
	data := get_child_data(archive.data, ph_group, index)
	sp.samples[sample_index].key = get_sample_key(data[:16])
	sp.samples[sample_index].data = data[16:]
}
```


#### Array Property Data

Array property data is constant if `first_changed_index == 0` in the property header. Number of samples is equal to the `next_sample_index`.

Indexing into the samples is a little more complex than scalar data. The number groups stored for the sample data is doubled up, where the pair of groups
represent the sample data and then the data for the dimensions. The sample data is similar to that of the scalar but the extra group that represents the dimensions
is an array of `u64le` values which represent the tensor shape of the data. Most of the time, the dimensions is just a single element represent the number
of elements in the array.

The data group has the same kind of hash prefixing the data (using SpookyHash).

```odin
Data_Type :: struct {
	pod:    Plain_Old_Data_Type,
	extent: u8,
}

get_num_bytes :: proc(dt: Data_Type) -> int {
	assert(dt.pod < .String)
	return pod_data_size[dt.pod] * int(dt.extent)
}

...

num_samples := u32(p.next_sample_index)
for sample_index in 0..<num_samples {
	// * 2 for array properties since the dimensions are also written
	index := verify_index(p, sample_index) * 2

	sample := &ap.samples[sample_index]

	dims_data, _ := get_child_data(archive.data, ph_group, index+1)
	data := get_child_data(archive.data, ph_group, index+0) or_return

	if len(data) > 0 {
		assert(len(data) >= 16)
		sample.key = get_sample_key(data[:16])
		sample.data = data[16:]
	}

	sz := get_num_bytes(p.data_type)

	dims: []u64
	if len(dims_data) == 0 {
		dims = make([]u64, 1)
		if len(data) == 0 {
			dims[0] = 0
		} else {
			dims[0] = u64((len(data)-16) / sz)
		}
	} else {
		dims = mem.slice_data_cast([]u64, dims_data)
	}
	sample.dims = dims
}
```


## Schemas of Alembic

I will discuss the schemas of Alembic at a later date since they could fill their own article. For the need we have, we only really care about reading in Cameras and Xforms (Transforms), and writing out Particles/Points.

## General Views of the Format

I think the general format _Ogawa_ format is absolute fine but because of its lack of semantic structure, it requires applying one to it. Even JSON has some semantic meaning by virtue of being a text-format (of which I have been using as a format to display to debug the Ogawa data).

**Note:** I would never recommend using JSON when another file format is better fit (especially if you have the luxury of using a custom format), JSON is too general for the vast majority of use cases. If you have the choice of using an interchange format, always use a binary one (even a custom one) since it is pretty much never the case you will need to modify the file in a text editor.

The design of the property header is very strange to me. It seems like it is trying to be as compact as possible but the reset of the file format is uncompressed. I cannot see why this bit would need to be compressed/compacted when the property data it refers to is uncompressed. The size hint bit is really bizarre and I personally would have just stuck with a single integer type (i.e. `u32le`) to keep things better.

The use of indexed metadata seems a bit bizarre since because the entire format is offset-based, the indexed stuff could have pointed to the same memory address to save memory. I know this means that the hierarchy is now not strict, but for metadata, I personally don't think it would be much of an issue.

Speaking of the offset-based file formats, one potential issue for malicious files is form cycles in the hierarchy, which could cause many readers to crash.

I am not sure why Spooky-Hash was used. It is not really an easy hashing algorithm to implement (\~330 LOC of Odin) and not necessarily better than other hashes out there. It is also not that commonly used compared to simpler (and maybe better) hashes.

## In Sum

After a lot of work, I got a fully functioning Alembic reader and writer that was \~2000 LOC of Odin (including the necessary schemas we required at [JangaFX](https://jangafx.com/)). This is a hell of a lot smaller and simpler than the official Alembic C++ API for the same amount of functionality.
