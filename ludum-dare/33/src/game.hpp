#ifndef GAME_HPP
#define GAME_HPP

#include "common.hpp"
#include "math.hpp"
#include "bitmap.hpp"
#include "level.hpp"

constexpr int SCREEN_WIDTH   = 160;
constexpr int SCREEN_HEIGHT  = 90;
constexpr f32 TIME_STEP      = 1.0f / 60.0f;
constexpr int LOG2_TILE_SIZE = 4;
constexpr int TILE_SIZE      = 1 << LOG2_TILE_SIZE;

constexpr const char* CHARS =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "abcdefghijklmnopqrstuvwxyz"
    "0123456789_+-=*           "
    ".,;:!?\"/\\<>()[]{}        ";
constexpr int CHARS_LENGTH = 104;
constexpr int CHAR_WIDTH   = 6;
constexpr int CHAR_HEIGHT  = 8;

constexpr int MAX_PARTICLES = 256;

inline int
get_char_index(char c)
{
	for (int i = 0; i < CHARS_LENGTH; i++) {
		if (CHARS[i] == c)
			return i;
	}

	return -1;
}


struct Framebuffer : Bitmap { // Embed Bitmap
	SDL_Surface* surface;

	f32* depth_buffer; // width * height
};

enum Spell_Type {
	SPELL_NONE,
	SPELL_FIRE,
	SPELL_EARTH,
	SPELL_WATER,
	SPELL_AIR,
};

struct Player {
	Vector3 position;
	f32& x = position.x;
	f32& y = position.y;
	f32& z = position.z;

	f32 pitch, yaw;
	f32 fov;

	s32 steps;

	f32 health;
	f32 max_health;

	f32 mana;
	f32 max_mana;


	int spell_count;
	Spell_Type curr_spell;
	b32 spell_active;
	f32 spell_cooldown;
	f32 new_spell_cooldown;

};

struct Particle {
	Vector3 position;
	Vector3 velocity;
	Vector2 scale;
	int tex;
	f32 life;
};


struct Game {
	SDL_Surface* window;

	Framebuffer display;
	Player player;

	Level level001;
	Level* curr_level;

	b32 running;
	b32 has_focus;
	b32 has_finished;

	const u8* keys;

	u32 start_time;
	u32 prev_time;
	u32 curr_time;
	f32 accumulator;

	u32 frame_time;
	u32 frame_count;
	u32 fps;

	f32 killed_a_prisoner_cooldown;

	int particle_count;
	Particle particles[MAX_PARTICLES];
};

namespace art
{
Bitmap title_screen;
Bitmap floors;
Bitmap sprites;
Bitmap particles;
Bitmap font;
} // namespace art

namespace sound
{
Mix_Chunk* power_up = nullptr;
Mix_Chunk* hit0 = nullptr;
Mix_Chunk* hit1 = nullptr;
Mix_Chunk* fire = nullptr;
} // namespace sound

namespace music
{
Mix_Music* main = nullptr;
} // namespace music

void
play_sound(Mix_Chunk* sound, f32 volume = 1.0f);

Framebuffer
create_framebuffer(int width, int height);

b32
init(Game& game);

void
add_particle(Game& game, const Particle& particle);

void
clear_buffers(Framebuffer& display, Color clear_color);

void
update_game(Game& game, f32 dt);

void
handle_collisions(Game& game, f32 dt);

void
render_floors(Game& game, b32 draw_ceiling);

void
render_wall(Game& game, int tex, const Vector2& p0, const Vector2& p1);

void
apply_post_fx(Framebuffer& display, f32 fog_strength);

void
render_sprite(Game& game, const Bitmap& spritesheet, int tex, const Vector3& position, const Vector2& scale = {1, 1});

void
render_text(Game& game, const char* str, const Vector2& position, Color color);

void
render_ui(Game& game);

void
render_level(Game& game);

#endif
