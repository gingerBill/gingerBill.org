#include "bitmap.hpp"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

Bitmap
create_bitmap(u32 width, u32 height)
{
	Bitmap bitmap = {};
	bitmap.width  = width;
	bitmap.height = height;
	bitmap.pitch  = sizeof(Color) * width;
	bitmap.pixels = (Color*)malloc(bitmap.pitch * height);

	return bitmap;
}

void
destroy_bitmap(Bitmap* bitmap)
{
	if (bitmap) {
		free(bitmap->pixels);
		*bitmap = {}; // Why not?
	}
}

void
draw_bitmap_to_bitmap(const Bitmap& source, Bitmap& target, int x_pos, int y_pos)
{
	if ((source.width == 0) ||
	    (source.height == 0) ||
	    (target.width == 0) ||
	    (target.height == 0)) {
		return;
	}

	for (int y = 0; y < source.height; y++) {
		for (int x = 0; x < source.width; x++) {
			const Color pixel = get_bitmap_pixel(source, x, y);
			if (pixel.a > 0)
				set_bitmap_pixel(target, pixel, x + x_pos, y + y_pos);
		}
	}
}

Bitmap
load_bitmap_from_file(const char* filename)
{
	Bitmap bitmap = {};
	u8* pixels = stbi_load(filename, &bitmap.width, &bitmap.height, nullptr, 4);
	defer(stbi_image_free(pixels));

	if (pixels == nullptr) {
		printf("Could not load \"%s\" from file\n", filename);
		return {};
	}

	const u32 num_bytes = bitmap.width * bitmap.height * 4;
	bitmap.pixels       = (Color*)malloc(num_bytes);

	memcpy(bitmap.pixels, pixels, num_bytes);

	return bitmap;
}
