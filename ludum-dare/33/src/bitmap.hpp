#ifndef BITMAP_HPP
#define BITMAP_HPP

#include "common.hpp"

constexpr int BYTES_PER_PIXEL = 4;

union Color {
	struct {
		u8 r, g, b, a;
	};
	u32 rgba;
};

constexpr bool
operator==(Color a, Color b)
{
	return a.rgba == b.rgba;
}

constexpr bool
operator!=(Color a, Color b)
{
	return a.rgba != b.rgba;
}

constexpr Color TRANSPARENT = {0x00, 0x00, 0x00, 0x00};
constexpr Color BLACK       = {0x00, 0x00, 0x00, 0xff};
constexpr Color WHITE       = {0xff, 0xff, 0xff, 0xff};
constexpr Color RED         = {0xff, 0x00, 0x00, 0xff};
constexpr Color ORANGE      = {0xff, 0x99, 0x00, 0xff};
constexpr Color YELLOW      = {0xff, 0xff, 0x00, 0xff};
constexpr Color GREEN       = {0x00, 0xff, 0x00, 0xff};
constexpr Color CYAN        = {0x00, 0xff, 0xff, 0xff};
constexpr Color BLUE        = {0x00, 0x00, 0xff, 0xff};
constexpr Color MAGENTA     = {0xff, 0x00, 0xff, 0xff};

struct Bitmap {
	int width;
	int height;
	int pitch;
	Color* pixels;

	static_assert(sizeof(Color) == 4, "sizeof(Color) != 4");
};

struct Rect {
	f32 x;
	f32 y;
	f32 width;
	f32 height;
};

struct Int_Rect {
	int x;
	int y;
	int width;
	int height;
};

inline bool
intersect(const Int_Rect& a, const Int_Rect& b)
{
	return (abs(a.x - b.x) * 2 < (a.width + b.width)) &&
	       (abs(a.y - b.y) * 2 < (a.height + b.height));
}

inline bool
intersect(const Rect& a, const Rect& b)
{
	return (abs(a.x - b.x) * 2 < (a.width + b.width)) &&
	       (abs(a.y - b.y) * 2 < (a.height + b.height));
}


Bitmap
create_bitmap(u32 width, u32 height);

void
destroy_bitmap(Bitmap* bitmap);

inline Color
get_bitmap_pixel(const Bitmap& bitmap, int x, int y)
{
	if (x < 0 || x >= bitmap.width || y < 0 || y >= bitmap.height)
		return TRANSPARENT;

	return bitmap.pixels[x + y * bitmap.width];
}

inline void
set_bitmap_pixel(Bitmap& bitmap, Color color, int x, int y)
{
	if (x < 0 || x >= bitmap.width || y < 0 || y >= bitmap.height)
		return;

	bitmap.pixels[x + y * bitmap.width] = color;
}

void
draw_bitmap_to_bitmap(const Bitmap& source, Bitmap& target, int x_pos, int y_pos);

Bitmap
load_bitmap_from_file(const char* filename);

#endif
