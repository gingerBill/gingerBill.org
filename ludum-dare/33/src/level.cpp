#include "level.hpp"

Level
load_level_from_file(const char* filename)
{
	Level level = {};

	Bitmap bitmap = load_bitmap_from_file(filename);
	level.width   = bitmap.width;
	level.height  = bitmap.height;

	level.grid = (Tile*)calloc(level.width * level.height, sizeof(Tile));

	for (int y = 0; y < level.height; y++) {
		for (int x = 0; x < level.width; x++) {
			Tile& tile = level.grid[x + y * level.width];

			const Color color = get_bitmap_pixel(bitmap, x, y);

			tile.type = TILE_FLOOR;

			if (color == BLACK)
				tile.type = TILE_WALL;
			if (color == Color{128, 0, 0, 255})
				tile.type = TILE_BOOKCASE;
			if (color == Color{128, 128, 128, 255})
				tile.type = TILE_BARS;
			if (color == Color{32, 32, 32, 255})
				tile.type = TILE_FALSE_WALL;

			if (color.b == 255 && color != WHITE) {
				switch (color.r) {
				case 0:
					add_entity(level, create_mage({x, y, 0}));
					break;
				case 32:
					add_entity(level, create_prisoner({x, y, 0}));
					break;
				case 128:
					add_entity(level, create_boss({x, y, 0}));
					break;
				case 255: {
					u16 portal_id = (color.g & 0xf0) / 16;
					u16 connected_portal_id = (color.g & 0x0f);
					add_entity(level, create_portal({x, y, 0}, portal_id, connected_portal_id));
				} break;
				default:
					break;
				}
			}


			if (color.r == 255 && color.b != 255) {
				if (color.b == 0) {
					add_entity(level, create_health_potion({x, y, 0}));
				} else if (color.b == 1) {
					add_entity(level, create_mana_potion({x, y, 0}));
				}
			}

			if (color == GREEN) {
				add_entity(level, create_scroll({x, y, 0}));
			}

			if (color == YELLOW) {
				level.init_position = {x, y};
			}

			tile.ceiling = 0x00;
			tile.floor   = 0x10;
		}
	}

	return level;
}

void
add_entity(Level& level, const Entity& entity)
{
	if (level.entity_count == MAX_ENTITIES)
		return;

	level.entities[level.entity_count++] = entity;
}

Entity
create_prisoner(const Vector3& position)
{
	Entity e = {};

	e.type = ENTITY_PRISONER;

	e.position = position;

	e.max_health = e.health = 4;
	e.max_mana = e.mana = 0;

	return e;
}

Entity
create_scroll(const Vector3& position)
{
	Entity e = {};

	e.type = ENTITY_SCROLL;

	e.position = position;

	e.max_health = e.health = 10000000;
	e.max_mana = e.mana = 0;

	return e;
}


Entity
create_mage(const Vector3& position)
{
	Entity e = {};

	e.type = ENTITY_MAGE;

	e.position = position;

	e.max_health = e.health = 7;
	e.max_mana = e.mana = 16;

	return e;
}

Entity
create_portal(const Vector3& position, u16 portal_id, u16 connected_portal_id)
{
	Entity e = {};

	e.type = ENTITY_PORTAL;
	e.portal_id = portal_id;
	e.connected_portal_id = connected_portal_id;

	e.position = position;

	e.max_health = e.health = 20;
	e.max_mana = e.mana = 0;

	return e;
}

Entity
create_boss(const Vector3& position)
{
	Entity e = {};

	e.type = ENTITY_BOSS;

	e.position = position;

	e.max_health = e.health = 60;
	e.max_mana = e.mana = 70;

	return e;
}

Entity
create_health_potion(const Vector3& position)
{
	Entity e = {};

	e.type = ENTITY_HEALTH_POTION;

	e.position = position;

	e.max_health = e.health = 10000000;
	e.max_mana = e.mana = 0;

	return e;
}

Entity
create_mana_potion(const Vector3& position)
{
	Entity e = {};

	e.type = ENTITY_MANA_POTION;

	e.position = position;

	e.max_health = e.health = 10000000;
	e.max_mana = e.mana = 0;

	return e;
}
