#ifndef LEVEL_HPP
#define LEVEL_HPP

#include "math.hpp"

constexpr int MAX_ENTITIES = 64;

enum Tile_Type : u8 {
	TILE_FLOOR      = 1,
	TILE_WALL       = 2,
	TILE_FALSE_WALL = 4 | TILE_FLOOR,
	TILE_BOOKCASE   = 8 | TILE_WALL,
	TILE_BARS       = 16 | TILE_WALL | TILE_FLOOR,
};

struct Tile {
	u8 floor;
	u8 ceiling;
	Tile_Type type;
	u8 id; // NOTE(bill): Used to get info for other types
};

#define BIT(x) (1 << (x))

enum Entity_Type {
	ENTITY_NONE          = 0,
	ENTITY_THING         = BIT(0),
	ENTITY_MOB           = BIT(1),
	ENTITY_PORTAL        = BIT(2) | ENTITY_THING, // Teleporting
	ENTITY_SCROLL        = BIT(3) | ENTITY_THING, // Gain Spell
	ENTITY_HEALTH_POTION = BIT(4) | ENTITY_THING, // Increase Health
	ENTITY_MANA_POTION   = BIT(5) | ENTITY_THING, // Increase Mana

	ENTITY_PRISONER     = BIT(6) | ENTITY_MOB, // Random
	ENTITY_PRISON_GUARD = BIT(7) | ENTITY_MOB, // Move back and forth
	ENTITY_MAGE         = BIT(8) | ENTITY_MOB, // Magic, AI, Random
	ENTITY_BOSS         = BIT(9) | ENTITY_MOB, // Magic, AI, Random, Fast
};

#undef BIT

struct Entity {
	Entity_Type type;
	union {
		u32 data;
		u32 state;
		struct {
			u16 portal_id;
			u16 connected_portal_id;
		};
	};

	Vector3 position;
	Vector2 velocity;

	f32 health;
	f32 max_health;

	f32 mana;
	f32 max_mana;

	f32 earth_cooldown;
	f32 water_cooldown;
};

struct Level {
	int width;
	int height;
	Tile* grid;

	Vector2 init_position;

	f32 portal_cooldown;

	int entity_count;
	Entity entities[MAX_ENTITIES];
};

inline Tile
get_tile(const Level& l, int x, int y)
{
	if (x < 0 || y < 0 || x >= l.width || y >= l.height)
		return {};

	return l.grid[x + y * l.width];
}

inline void
set_tile(Level& l, Tile tile, int x, int y)
{
	if (x < 0 || y < 0 || x >= l.width || y >= l.height)
		return;

	l.grid[x + y * l.width] = tile;
}

Level
load_level_from_file(const char* filename);

void
add_entity(Level& level, const Entity& entity);

Entity
create_prisoner(const Vector3& position);
Entity
create_scroll(const Vector3& position);
Entity
create_mage(const Vector3& position);
Entity
create_portal(const Vector3& position, u16 portal_id, u16 other_portal_id);
Entity
create_boss(const Vector3& position);

Entity
create_health_potion(const Vector3& position);
Entity
create_mana_potion(const Vector3& position);
#endif
