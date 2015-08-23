#ifndef COMMON_HPP
#define COMMON_HPP

////////////////////////////////
// Common Headers
////////////////////////////////
#include <emscripten/emscripten.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>
#include <functional> // Needed for `defer`
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

////////////////////////////////
// `static` means many things
////////////////////////////////
#define global static
#define internal static
#define local_persist static

////////////////////////////////
// Integral types
////////////////////////////////
using u8  = uint8_t;
using u16 = uint16_t;
using u32 = uint32_t;
using u64 = uint64_t;

using s8  = int8_t;
using s16 = int16_t;
using s32 = int32_t;
using s64 = int64_t;

using f32 = float;
using f64 = double;

using b8  = s8;
using b32 = s32;

////////////////////////////////
// `defer` implementation
// defer a statement to the end of its scope
////////////////////////////////
namespace impl
{
template <typename Fn>
struct Defer {
	Fn fn;

	Defer(Fn&& fn)
	: fn{std::forward<Fn>(fn)}
	{
	}
	~Defer() { fn(); }
};

template <typename Fn>
Defer<Fn>
deferFn(Fn&& fn)
{
	return Defer<Fn>(std::forward<Fn>(fn));
}
} // namespace impl

#define DEFER_1(x, y) x##y
#define DEFER_2(x, y) DEFER_1(x, y)
#define DEFER_3(x) DEFER_2(x, __COUNTER__)

#define defer(code) auto DEFER_3(_defer_) = impl::deferFn([&]() { code; });

////////////////////////////////
// SDL error handler
////////////////////////////////
inline void
sdl_error(const char* str)
{
	fprintf(stderr, "Error at %s: %s\n", str, SDL_GetError());
	emscripten_force_exit(1);
}

#endif
