#include "game.hpp"

Framebuffer
create_framebuffer(int width, int height)
{
	Framebuffer fb = {};

	fb.surface = SDL_CreateRGBSurface(SDL_HWSURFACE,
	                                  width, height, 32,
	                                  0x000000ff,
	                                  0x0000ff00,
	                                  0x00ff0000,
	                                  0xff000000);
	if (fb.surface == nullptr)
		sdl_error("SDL_CreateRGBSurface");

	fb.width  = width;
	fb.height = height;
	fb.pitch = width * 4;
	SDL_LockSurface(fb.surface);
	fb.pixels = (Color*)fb.surface->pixels;
	SDL_UnlockSurface(fb.surface);

	fb.depth_buffer = (f32*)calloc(width * height, sizeof(f32));

	return fb;
}

b32
init(Game& game)
{
	srand(time(nullptr));

	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) {
		sdl_error("SDL_Init");
		return false;
	}
	printf("[SDL] Init\n");

	if (Mix_OpenAudio(48000, MIX_DEFAULT_FORMAT, 2, 4096) != 0) {
		sdl_error("Mix_OpenAudio");
		return false;
	}

	game.window = SDL_SetVideoMode(SCREEN_WIDTH, SCREEN_HEIGHT, 32, SDL_HWSURFACE);
	if (game.window == nullptr) {
		sdl_error("SDL_SetVideoMode");
		return false;
	}
	printf("[SDL] SetVideoMode\n");

	game.display = create_framebuffer(SCREEN_WIDTH, SCREEN_HEIGHT);
	printf("[Game] Create Framebuffer\n");

	game.player.fov   = 1.0f / (f32)game.display.height;
	game.player.z     = 0.1f;
	game.player.pitch = -0.1f;
	game.player.yaw   = -TAU / 4;

	game.player.max_health = game.player.health = 4.0f;
	game.player.max_mana = game.player.mana = 20.0f;
	printf("[Game] player Init\n");

	art::title_screen = load_bitmap_from_file("title_screen.png");
	art::floors       = load_bitmap_from_file("floors.png");
	art::sprites      = load_bitmap_from_file("sprites.png");
	art::particles    = load_bitmap_from_file("particles.png");
	art::font = load_bitmap_from_file("font.png");
	printf("[Game] Load Art\n");

	sound::power_up = Mix_LoadWAV("Powerup.wav");
	sound::hit0     = Mix_LoadWAV("Hit_Hurt0.wav");
	sound::hit1     = Mix_LoadWAV("Hit_Hurt1.wav");
	sound::fire     = Mix_LoadWAV("Fire.wav");
	printf("[Game] Load Sounds\n");

	music::main = Mix_LoadMUS("main_music.ogg");
	printf("[Game] Load Music\n");

	game.level001   = load_level_from_file("level001.png");
	game.curr_level = &game.level001;
	printf("[Game] Load Levels\n");

	if (!Mix_PlayingMusic()) {
		Mix_PlayMusic(music::main, -1);
	}

	game.player.x = game.curr_level->init_position.x;
	game.player.y = game.curr_level->init_position.y;

	game.player.spell_count = 0;
	game.player.curr_spell  = SPELL_NONE;

	game.particle_count = 0;

	game.has_focus = true;
	game.running = true;
	printf("[Game] Init\n");
	return true;
}

internal Particle
create_smoke_particle(int tex, const Vector3& position)
{
	Particle p = {};
	p.position = position;

	p.velocity.x = 0.2f * sinf(rand());
	p.velocity.y = 0.2f * sinf(rand());
	p.velocity.z = 0.2f * sinf(rand());

	p.scale = {0.25f, 0.25f};
	p.scale *= ((rand() % 8 - 4) / 16.0f + 1.0f);
	p.tex  = tex;
	p.life = 1.0f + (rand() % 8 - 4) / 64.0f;

	return p;
}

void
play_sound(Mix_Chunk* s, f32 volume)
{
	volume = clamp(volume, 0, 1);
	// Mix_VolumeChunk(s, volume * MIX_MAX_VOLUME);
	Mix_PlayChannel(-1, s, 0);
}

internal void
update_player(Game& game, f32 dt)
{
	constexpr f32 MOVE_SPEED = 2.0f;
	constexpr f32 YAW_SPEED  = 3.0f;

	const u8* keys = game.keys;
	auto& player   = game.player;

	if (keys[SDLK_LEFT])
		player.yaw -= YAW_SPEED * dt;
	if (keys[SDLK_RIGHT])
		player.yaw += YAW_SPEED * dt;

	// NOTE(bill): No need to normalize as c^2 + s^2 = 1
	const Vector2 forwards  = {sinf(player.yaw), cosf(player.yaw)};
	const Vector2 sidewards = {cosf(player.yaw), -sinf(player.yaw)};

	if (keys[SDLK_UP]) {
		player.x += MOVE_SPEED * forwards.x * dt;
		player.y += MOVE_SPEED * forwards.y * dt;
		player.steps += 1;
	}

	if (keys[SDLK_DOWN]) {
		player.x -= MOVE_SPEED * forwards.x * dt;
		player.y -= MOVE_SPEED * forwards.y * dt;
		player.steps -= 1;
	}

	player.z = 0.1f - 0.01 + 0.02f * abs(sinf(player.steps / 8.0f));

	// Health and Mana Regen
	player.health += 1.0f * dt;
	player.mana += 1.0f * dt;
	player.new_spell_cooldown -= dt;

	player.health = clamp(player.health, 0, player.max_health);
	player.mana = clamp(player.mana, 0, player.max_mana);
	if (player.new_spell_cooldown < 0)
		player.new_spell_cooldown = 0;
}

internal void
update_spells(Game& game, f32 dt)
{
	const u8* keys = game.keys;
	auto& player   = game.player;
	auto& level    = *game.curr_level;

	// NOTE(bill): No need to normalize as c^2 + s^2 = 1
	const Vector2 forwards  = {sinf(player.yaw), cosf(player.yaw)};
	const Vector2 sidewards = {cosf(player.yaw), -sinf(player.yaw)};

	player.spell_cooldown -= dt;

	if (keys[SDLK_1] && player.spell_count >= 1)
		player.curr_spell = SPELL_FIRE;
	if (keys[SDLK_2] && player.spell_count >= 2)
		player.curr_spell = SPELL_EARTH;
	if (keys[SDLK_3] && player.spell_count >= 3)
		player.curr_spell = SPELL_WATER;
	if (keys[SDLK_4] && player.spell_count >= 4)
		player.curr_spell = SPELL_AIR;

	player.spell_active = false;
	if (keys[SDLK_SPACE]) { // Use spells
		f32 health_usage = 0;
		f32 mana_usage = 0;
		switch (player.curr_spell) {
		case SPELL_FIRE: {
			health_usage = 1.5;
			mana_usage   = 5;
		} break;

		case SPELL_EARTH: {
			health_usage = 0.5;
			mana_usage   = 8;
		} break;

		case SPELL_WATER: {
			health_usage = 0.5;
			mana_usage   = 7;
		} break;

		case SPELL_AIR: {
			health_usage = 0.5;
			mana_usage   = 7;
		} break;

		default:
			break;
		}

		if (player.mana >= mana_usage * dt * 10 && mana_usage > 0 && player.spell_cooldown <= 0) {
			Vector3 pos = player.position;
			pos.xy += forwards * dt;
			pos.xy += 0.1f * sidewards;
			pos.z   = 0.1f;
			int tex = 0x10 * (player.curr_spell - 1);
			tex += rand() & 7;
			Particle p = create_smoke_particle(tex, pos);
			p.velocity.xy += 3.0f * forwards;
			add_particle(game, p);

			player.health -= health_usage * dt;
			player.mana -= mana_usage * dt;

			player.spell_active = true;
			if (random(0, 1) < 0.2) {
				play_sound(sound::fire);
			}

		} else {
			player.spell_active = false;
		}

		if (player.mana <= 0)
			player.spell_cooldown = 3.0f;
	}

	if (player.spell_active) {
		switch (player.curr_spell) {
		// case SPELL_AIR: {
		default: {
			player.position.xy -= 0.5f * forwards * dt;
		} break;
		}

		for (int i = 0; i < level.entity_count; i++) {
			Entity& e = level.entities[i];
			if (!(e.type & ENTITY_MOB))
				continue;

			Vector2 dpos       = e.position.xy - player.position.xy;
			const f32 distance = length(dpos);

			if (distance > 6.0f)
				continue;
			const f32 cos_theta = dot(dpos, forwards);

			f32 affect = cos_theta / (distance * distance + 1.0f);

			switch (player.curr_spell) {

			case SPELL_FIRE: {
				e.position.xy += 10.0f * forwards * affect * dt;
				e.health -= 10.0f * affect * dt;
			} break;

			case SPELL_EARTH: {
				e.position.xy += 5.0f * forwards * affect * dt;
				e.health -= 5.0f * affect * dt;
				if (e.earth_cooldown <= 0)
					e.earth_cooldown = 2.0f;
			} break;

			case SPELL_WATER: {
				e.position.xy += 8.0f * forwards * affect * dt;
				e.health -= 7.0f * affect * dt;

				if (e.water_cooldown <= 0)
					e.water_cooldown = 3.0f;

			} break;

			case SPELL_AIR: {
				e.position.xy += 20.0f * forwards * affect * dt;
				e.health -= 3.0f * affect * dt;
			} break;

			default:
				break;
			}

			if (e.type == ENTITY_BOSS) {
				// printf("Boss: %f hp\n", e.health);
			}
		}
	}
}

void
add_particle(Game& game, const Particle& particle)
{
	if (game.particle_count == MAX_PARTICLES) // Don't add any more
		return;

	game.particles[game.particle_count] = particle;
	game.particle_count++;
}

internal void
update_particles(Game& game, f32 dt)
{
	for (int i = 0; i < game.particle_count; i++) {
		Particle& p = game.particles[i];
		p.life -= dt;
		p.position += p.velocity * dt;
	}

	for (int i = 0; i < game.particle_count;) {
		Particle& p = game.particles[i];
		if (p.life <= 0) {
			game.particles[i] = game.particles[game.particle_count - 1];
			game.particle_count--;
			continue;
		}
		i++;
	}

	Level& level       = *game.curr_level;
	Vector3 player_pos = {game.player.x, game.player.y, game.player.z};
	for (int i = 0; i < level.entity_count; i++) {

		const Entity& e = level.entities[i];

		Vector3 dpos  = player_pos - e.position;
		Vector2 dside = normalize(Vector2{-dpos.y, dpos.x});
		if (length(dpos) > 6.0f)
			continue;
		dpos = normalize(dpos);

		switch (e.type) {
		case ENTITY_MAGE: {
			if ((rand() % 8) != 0)
				continue;

			Vector3 p_pos = e.position + 0.1f * dpos;
			p_pos.xy += 0.3f * dside;
			p_pos.z += 0.2f;
			add_particle(game, create_smoke_particle(0x10 + (rand() & 7), p_pos));
		} break;
		case ENTITY_BOSS: {
			if ((rand() % 8) != 0)
				continue;
			Vector3 p_pos = e.position + 0.1f * dpos;
			p_pos.xy -= 0.3f * dside;
			p_pos.z += 0.2f;
			Particle p = create_smoke_particle(0x50 + (rand() & 7), p_pos);
			p.velocity *= 2.0f;
			add_particle(game, p);
		} break;

		case ENTITY_PORTAL: {
			Vector3 pos = e.position;
			pos.x += ((rand() & 15) / 32.0f) - 0.25f;
			pos.y += ((rand() & 15) / 32.0f) - 0.25f;
			pos.z += ((rand() & 15) / 32.0f) - 0.25f;
			Particle p = create_smoke_particle(0x40 + (rand() & 7), pos);
			p.velocity *= 3;
			add_particle(game, p);
		} break;

		default:
			break;
		}
	}
}

internal void
render_particles(Game& game)
{
	constexpr f32 radius     = 12.0f;
	const Vector3 player_pos = {game.player.x, game.player.y, game.player.z};
	for (int i = 0; i < game.particle_count; i++) {
		const Particle& p = game.particles[i];
		f32 d = length(p.position - player_pos);
		if (d < radius)
			render_sprite(game, art::particles, p.tex, p.position, p.scale);
	}
}

internal Entity
get_portal_entity(Level& level, u16 portal_id)
{
	for (int i = 0; i < level.entity_count; i++) {
		const Entity& e = level.entities[i];
		if (e.type != ENTITY_PORTAL)
			continue;
		if (e.portal_id == portal_id)
			return e;
	}

	return {};
}

internal void
update_entities(Game& game, Level& level, f32 dt)
{
	level.portal_cooldown -= dt;
	if (level.portal_cooldown < 0)
		level.portal_cooldown = 0;
	game.killed_a_prisoner_cooldown -= dt;
	if (game.killed_a_prisoner_cooldown < 0)
		game.killed_a_prisoner_cooldown = 0;

	const Vector2 forwards = {sinf(game.player.yaw), cosf(game.player.yaw)};

	for (int i = 0; i < level.entity_count; i++) {
		Entity& e = level.entities[i];
		e.earth_cooldown -= dt;
		e.water_cooldown -= dt;

		Vector3 dpos = game.player.position - e.position;
		f32 distance = length(dpos);
		if (distance > 8)
			continue; // NOTE(bill): Don't update far things
		dpos = normalize(dpos);

		switch (e.type) {
		case ENTITY_MAGE: {
			f32 speed = 2.0f;
			if (e.earth_cooldown > 0)
				speed *= 0.2f;
			if (distance > 1.0f)
				e.position += speed * dpos * dt;
			if (e.water_cooldown > 0) {
				if ((rand() & 31) == 0) {
					e.velocity.x = random(-1, 1);
					e.velocity.y = random(-1, 1);
					e.velocity *= 3.0f;
				}
			}

			if (distance < 10.0f && random(0, 1) < 0.1) {

				Vector3 pos = e.position;
				pos.z       = 0.1f;
				int tex = 0x10; // GREEN!
				tex += rand() & 7;
				for (int i = 0; i < 3; i++) {
					Particle p = create_smoke_particle(tex, pos);
					p.velocity += 10.0f * dpos;
					p.velocity.z += random(-0.5, 0.5);
					add_particle(game, p);
				}
				f32 damage = random(3, 6) * dt;
				game.player.health -= damage;
			}

		} break;

		case ENTITY_BOSS: {
			if (distance < 1.0f)
				e.position.xy -= 2.0f * dpos.xy * dt;
			if ((rand() & 31) == 0) {
				e.velocity.x = random(-1, 1);
				e.velocity.y = random(-1, 1);
				e.velocity *= 2.0f;
			}

			if (e.water_cooldown > 0) {
				if ((rand() & 31) == 0) {
					e.velocity.x = random(-1, 1);
					e.velocity.y = random(-1, 1);
					e.velocity *= 2.0f;
				}
			}

			e.position.xy += e.velocity * dt;
			e.position.xy += 0.5f * dpos.xy * dt;

			if (distance < 10.0f && random(0, 1) < 0.1) {
				e.mana -= 1 * dt;
				if (e.mana > 0) {
					Vector3 pos = e.position;
					pos.z       = 0.1f;
					int tex = 0x50; // RED!
					tex += rand() & 7;
					for (int i = 0; i < 10; i++) {
						Particle p = create_smoke_particle(tex, pos);
						p.velocity += 10.0f * dpos;
						p.velocity.z += random(-0.5, 0.5);
						add_particle(game, p);
					}
					f32 damage = random(10, 15) * dt;
					game.player.health -= damage;
					if (random(0, 1) < 0.2) {
						if (rand() & 1)
							play_sound(sound::hit0);
						else
							play_sound(sound::hit1);
					}
				}
			}

			e.mana += 2 * dt;
			e.mana = clamp(e.mana, 0, e.max_mana);
		}

		case ENTITY_PORTAL: {
			if (distance < 0.5f && level.portal_cooldown <= 0) {
				Entity portal        = get_portal_entity(level, e.connected_portal_id);
				game.player.position = portal.position;
				play_sound(sound::fire); // TODO

				level.portal_cooldown = 3.0f;
			}
		} break;

		case ENTITY_SCROLL: {
			if (distance < 0.5f) {
				e.health = -1000; // KILL IT
				game.player.spell_count++;
				game.player.curr_spell         = (Spell_Type)((int)(game.player.curr_spell) + 1);
				game.player.new_spell_cooldown = 3.0f;
				game.player.max_health += 4;
				game.player.max_mana += 4;
				play_sound(sound::power_up);
			}
			e.position.z = 0.05f * sinf(game.curr_time / 600.0f);
		} break;

		case ENTITY_HEALTH_POTION: {
			e.position.z = 0.05f * sinf(game.curr_time / 600.0f);
			if (distance < 0.5f) {
				e.health = -1000; // KILL IT
				game.player.health += 5;
				play_sound(sound::power_up);
			}
		} break;

		case ENTITY_MANA_POTION: {
			e.position.z = 0.05f * sinf(game.curr_time / 600.0f);
			if (distance < 0.5f) {
				e.health = -1000; // KILL IT
				game.player.mana += 5;
				play_sound(sound::power_up);
			}
		} break;

		default:
			break;
		}
	}
}

internal void
remove_dead_entities(Game& game, Level& level)
{
	for (int i = 0; i < level.entity_count;) {
		if (level.entities[i].health <= 0) {
			const Entity& e = level.entities[i];
			if (e.type == ENTITY_MAGE)
				printf("Mage died\n");
			if (e.type == ENTITY_BOSS)
				game.has_finished = true;
			if (e.type == ENTITY_PRISONER)
				game.killed_a_prisoner_cooldown = 2.0f;
			if (i != level.entity_count - 1)
				level.entities[i] = level.entities[level.entity_count - 1];
			level.entity_count--;
			continue;
		}
		i++;
	}
}

void
update_game(Game& game, f32 dt)
{
	if (!Mix_PlayingMusic()) {
		Mix_PlayMusic(music::main, -1);
	}

	if (game.player.health <= 0)
		game.has_finished = true;
	if (game.has_finished)
		return;

	Level& level = *game.curr_level;

	update_player(game, dt);
	update_spells(game, dt);
	update_particles(game, dt);
	update_entities(game, level, dt);

	remove_dead_entities(game, level);

	handle_collisions(game, dt);
}

internal Vector2
collision_adjustment(Rect a, Rect b)
{
	Vector2 depth = {};

	Vector2 a_min = {a.x, a.y};
	Vector2 b_min = {b.x, b.y};
	Vector2 a_max = {a.x + a.width, a.y + a.height};
	Vector2 b_max = {b.x + b.width, b.y + b.height};

	f32 left   = b_min.x - a_max.x;
	f32 right  = b_max.x - a_min.x;
	f32 top    = b_min.y - a_max.y;
	f32 bottom = b_max.y - a_min.y;

	if (left > 0 || right < 0)
		return {};
	if (top > 0 || bottom < 0)
		return {};

	if (abs(left) < right)
		depth.x = left;
	else
		depth.x = right;

	if (abs(top) < bottom)
		depth.y = top;
	else
		depth.y = bottom;

	if (abs(depth.x) < abs(depth.y))
		depth.y = 0;
	else
		depth.x = 0;

	return depth;
}

internal Vector2
check_collision(const Level& level, Rect rect)
{
	Vector2 adjustment = {0, 0};
	const int radius   = 2;
	const int x_center = (int)round(rect.x);
	const int y_center = (int)round(rect.y);

	for (int y = y_center - radius; y <= y_center + radius; y++) {
		for (int x = x_center - radius; x <= x_center + radius; x++) {
			Tile t = get_tile(level, x, y);
			if (!(t.type & TILE_WALL))
				continue;

			Rect tile_rect = {x, y, 1, 1};

			if (intersect(rect, tile_rect))
				adjustment += collision_adjustment(rect, tile_rect);
		}
	}

	return adjustment;
}

inline Rect
entity_rect(const Vector2& pos)
{
	return {pos.x + 0.3f, pos.y + 0.3f, 0.4f, 0.4f};
}

void
handle_collisions(Game& game, f32 dt)
{
	Level& level = *game.curr_level;

	Vector3& player_pos = game.player.position;
	player_pos.xy += check_collision(level, entity_rect(player_pos.xy));

	for (int i = 0; i < level.entity_count; i++) {
		Entity& e = level.entities[i];

		if (length(e.position - player_pos) > 6)
			continue;
		e.position.xy += check_collision(level, entity_rect(e.position.xy));
	}

	// NOTE(bill): If the player goes off the map, go to the spawn
	if (game.player.x < 0 || game.player.y < 0 ||
	    game.player.x >= level.width || game.player.y >= level.height) {
		game.player.x = level.init_position.x;
		game.player.y = level.init_position.y;
		printf("[ERROR] Player when out of bounds\n");
		printf("Player is has been teleported to the beginning");
	}
}

void
clear_buffers(Framebuffer& display, Color clear_color)
{
	memset(display.depth_buffer, 0, display.width * display.height * sizeof(f32));

	for (int i = 0; i < display.width * display.height; i++)
		display.pixels[i] = clear_color;
}

void
render_entities(Game& game)
{
	f32 radius         = 6.0f;
	Vector3 player_pos = {game.player.x, game.player.y, game.player.z};
	Level& level       = *game.curr_level;

	for (int i = 0; i < level.entity_count; i++) {
		const Entity& e = level.entities[i];

		if (length(e.position - player_pos) > radius)
			continue;

		int tex = 0;
		switch (e.type) {
		case ENTITY_PORTAL:
			tex = 0x00;
			break;
		case ENTITY_MAGE:
			tex = 0x10;
			break;
		case ENTITY_PRISONER:
			tex = 0x20;
			break;
		case ENTITY_SCROLL:
			tex = 0x30;
			break;
		case ENTITY_BOSS:
			tex = 0x40;
			break;
		case ENTITY_HEALTH_POTION:
			tex = 0x31;
			break;
		case ENTITY_MANA_POTION:
			tex = 0x32;
			break;
		default:
			break;
		}
		render_sprite(game, art::sprites, tex, e.position);
	}
}

void
render_spells(Game& game)
{
#if 0
	f32 radius = 6.0f;
	Vector3 player_pos = {game.player.x, game.player.y, game.player.z};
	Level& level = *game.curr_level;

	for (int spell_index = 0; spell_index < level.spell_count; spell_index++) {
		const Spell& s = level.spells[spell_index];

		if (s.direction.z > 0.7)
			continue;

		if (length(s.position - player_pos) > radius)
			continue;

	}
#endif
}

internal int
get_wall_tex(Tile_Type t, int offset)
{
	switch (t) {
	case TILE_WALL:
		return 0x20 + offset % 2;
	case TILE_FALSE_WALL:
		return 0x22;
	case TILE_BOOKCASE:
		return 0x30 + offset % 4;
	case TILE_BARS:
		return 0x40;
	default:
		return 0x20;
	}
}

internal void
render_walls(Game& game, Level& level)
{
	int radius   = 6;
	int x_center = (int)game.player.x;
	int y_center = (int)game.player.y;

	for (int y = y_center - radius; y <= y_center + radius; y++) {
		for (int x = x_center - radius; x <= x_center + radius; x++) {
			const Tile center = get_tile(level, x, y);
			const Tile east   = get_tile(level, x + 1, y);
			const Tile west   = get_tile(level, x - 1, y);
			const Tile north  = get_tile(level, x, y - 1);
			const Tile south  = get_tile(level, x, y + 1);

			if (center.type == TILE_FLOOR || center.type == TILE_FALSE_WALL) {
				const int offset = (((x + 1) * (y + 1)) + x * 7 + y * 6 - 7) & 31;
				if (east.type != TILE_FLOOR)
					render_wall(game, get_wall_tex(east.type, offset), {x + 1, y + 1}, {x + 1, y});

				if (west.type != TILE_FLOOR)
					render_wall(game, get_wall_tex(west.type, offset), {x, y}, {x, y + 1});

				if (north.type != TILE_FLOOR)
					render_wall(game, get_wall_tex(north.type, offset), {x + 1, y}, {x, y});

				if (south.type != TILE_FLOOR)
					render_wall(game, get_wall_tex(south.type, offset), {x, y + 1}, {x + 1, y + 1});
			}
		}
	}
}

void
render_level(Game& game)
{
	Level& level = *game.curr_level;

	render_floors(game, true);
	render_walls(game, level);

	render_entities(game);

	render_particles(game);
}

internal void
render_ui_sprite(Framebuffer& display, const Bitmap& spritesheet, Vector2 pos, Rect rect)
{
	for (int y = rect.y; y < rect.y + rect.height; y++) {
		for (int x = rect.x; x < rect.x + rect.width; x++) {

			Color src = get_bitmap_pixel(spritesheet, x, y);
			if (src.a == 0)
				continue;

			const int xx = pos.x + x - rect.x;
			const int yy = pos.y + y - rect.y;

			// NOTE(bill): Cool blending!
			const Color dst = display.pixels[xx + yy * display.width];

			f32 a = src.a / 255.0f;
			src.r = src.r * a + dst.r * (1.0f - a);
			src.g = src.g * a + dst.g * (1.0f - a);
			src.b = src.b * a + dst.b * (1.0f - a);
			src.a = src.a + dst.a * (1.0f - a);

			set_bitmap_pixel(display, src, xx, yy);
		}
	}
}

void
render_ui(Game& game)
{
#if 0
	local_persist char buffer[256] = {0};
	snprintf(buffer, sizeof(buffer),
	         // "%d", game.fps);
	         "%d", game.fps);

	render_text(game, buffer, {0, 0}, WHITE);
#endif

	// render_ui_sprite(game.display, art::sprites, 0xf0,
	//                  {0, 76}, {0, 2, 16, 14});

	constexpr int TSD = 3000;

	if (game.curr_time < TSD) {
		render_ui_sprite(game.display, art::title_screen, {0, 0}, {0, 0, 160, 90});
		return;
	}

	if (game.player.health <= 0) {
		int xx0 = (game.display.width - (23 * CHAR_WIDTH)) / 2;
		render_text(game, "You have been defeated!", {xx0, 30}, WHITE);
		int xx1 = (game.display.width - (20 * CHAR_WIDTH)) / 2;
		render_text(game, "Refresh to try again", {xx1, 60}, WHITE);
		return;
	}

	if (game.has_finished) {
		int xx0 = (game.display.width - (24 * CHAR_WIDTH)) / 2;
		render_text(game, "You killed to high mage,", {xx0, 10}, WHITE);

		int xx1 = (game.display.width - (12 * CHAR_WIDTH)) / 2;
		render_text(game, "you monster!", {xx1, 19}, WHITE);

		int xx2 = (game.display.width - (19 * CHAR_WIDTH)) / 2;
		render_text(game, "Thanks for playing!", {xx2, 40}, WHITE);

		int xx3 = (game.display.width - (26 * CHAR_WIDTH)) / 2;
		render_text(game, "Please vote for this entry", {xx3, 49}, WHITE);

		int xx4 = (game.display.width - (22 * CHAR_WIDTH)) / 2;
		render_text(game, "Handmade by gingerBill", {xx4, 58}, WHITE);

		return;
	}

	// Health
	f32 ss   = sinf(game.curr_time / 400.0f);
	int hp   = (1.0f - game.player.health / game.player.max_health) * 17;
	int mana = (1.0f - game.player.mana / game.player.max_mana) * 17;
	render_ui_sprite(game.display, art::sprites, {40, 74 + hp}, {0, 240 + hp, 16, 16 - hp});
	// Mana
	render_ui_sprite(game.display, art::sprites, {103, 74 + mana}, {16, 240 + mana, 16, 16 + mana});
	// Bar
	render_ui_sprite(game.display, art::sprites, {35, 77}, {60, 243, 89, 13});

	// Spells
	if (game.player.spell_count >= 1)
		render_ui_sprite(game.display, art::sprites, {57, 80},
		                 {0, 192 + (game.player.curr_spell == SPELL_FIRE ? 16 : 0), 8, 8});
	if (game.player.spell_count >= 2)
		render_ui_sprite(game.display, art::sprites, {69, 80},
		                 {16, 192 + (game.player.curr_spell == SPELL_EARTH ? 16 : 0), 8, 8});
	if (game.player.spell_count >= 3)
		render_ui_sprite(game.display, art::sprites, {81, 80},
		                 {32, 192 + (game.player.curr_spell == SPELL_WATER ? 16 : 0), 8, 8});
	if (game.player.spell_count >= 4)
		render_ui_sprite(game.display, art::sprites, {93, 80},
		                 {48, 192 + (game.player.curr_spell == SPELL_AIR ? 16 : 0), 8, 8});

	if (game.player.new_spell_cooldown > 0) {
		local_persist char spell_buffer[256] = {0};
		const char* spell_name               = "Ignis Flamma";
		Color spell_color = {200, 150, 0, 255};
		if (game.player.spell_count == 2) {
			spell_name  = "Terra Mot";
			spell_color = {0, 200, 50, 255};
		} else if (game.player.spell_count == 3) {
			spell_name  = "Aquis Merg";
			spell_color = {0, 20, 200, 255};
		} else if (game.player.spell_count == 4) {
			spell_name  = "Aeris Fus";
			spell_color = {0xee, 0xee, 0xee, 255};
		}

		snprintf(spell_buffer, sizeof(spell_buffer),
		         "New Spell: %s", spell_name);
		int xx = game.display.width - ((11 + strlen(spell_name)) * CHAR_WIDTH);
		xx /= 2;
		int yy = game.display.height - CHAR_HEIGHT;
		yy /= 3;

		render_text(game, spell_buffer, {xx, yy}, spell_color);
	}

	if (game.killed_a_prisoner_cooldown) {
		int xx1 = (game.display.width - (12 * CHAR_WIDTH)) / 2;
		render_text(game, "You monster!", {xx1, 19}, WHITE);
	}

	if (length(game.player.position.xy - game.curr_level->init_position) > 6)
		return;

	if (game.curr_time > TSD + 3000 && game.curr_time < TSD + 6000) {
		int xx1 = (game.display.width - (15 * CHAR_WIDTH)) / 2;
		render_text(game, "Want to escape?", {xx1, 19}, WHITE);
	} else if (game.curr_time > TSD + 6000 && game.curr_time < TSD + 9000) {
		int xx1 = (game.display.width - (24 * CHAR_WIDTH)) / 2;
		render_text(game, "I've been digging a hole", {xx1, 19}, WHITE);
	} else if (game.curr_time > TSD + 9000 && game.curr_time < TSD + 12000) {
		int xx1 = (game.display.width - (18 * CHAR_WIDTH)) / 2;
		render_text(game, "I'm too weak to go", {xx1, 19}, WHITE);
	} else if (game.curr_time > TSD + 12000 && game.curr_time < TSD + 15000) {
		int xx1 = (game.display.width - (24 * CHAR_WIDTH)) / 2;
		render_text(game, "But I've placed a portal", {xx1, 19}, WHITE);
	} else if (game.curr_time > TSD + 15000 && game.curr_time < TSD + 18000) {
		int xx1 = (game.display.width - (25 * CHAR_WIDTH)) / 2;
		render_text(game, "With the magic I had left", {xx1, 19}, WHITE);
	} else if (game.curr_time > TSD + 18000 && game.curr_time < TSD + 21000) {
		int xx1 = (game.display.width - (21 * CHAR_WIDTH)) / 2;
		render_text(game, "Go kill the high mage", {xx1, 19}, WHITE);
	}
	// Hand
	// render_ui_sprite(game.display, art::sprites, {120, 40}, {163, 200, 33, 56});
}

void
render_floors(Game& game, b32 draw_ceiling)
{
	const int width    = game.display.width;
	const int height   = game.display.height;
	const f32 x_center = 0.5f * width;
	const f32 y_center = (0.5f + game.player.pitch) * height;
	const f32 cos_yaw  = cosf(game.player.yaw);
	const f32 sin_yaw  = sinf(game.player.yaw);
	const Level& level = *game.curr_level;

	Color* row = (Color*)game.display.pixels - game.display.width;
	for (u32 y = 0; y < height; y++) {
		row += game.display.width; // NOTE(bill): preincrement row - not need for defer
		const f32 dy = ((y + 0.5f) - y_center) * game.player.fov;

		f32 dd = 0;

		b32 ceiling_mode = false;
		if (dy > 0) { // NOTE(bill): Render Floor
			dd = TILE_SIZE * (game.player.z + 0.5f) / dy;
		} else { // NOTE(bill): Render Ceiling
			dd = TILE_SIZE * (game.player.z - 0.5f) / dy;

			ceiling_mode = true;
		}

		f32 depth = 1.0f / dd;
		for (u32 x = 0; x < width; x++) {
			if (game.display.depth_buffer[x + y * width] > depth)
				continue;

			const f32 dx = dd * (x - x_center) * game.player.fov;

			// NOTE(bill): 0.5f is to center player
			const f32 xx = (dx * cos_yaw + dd * sin_yaw) + ((game.player.x + 0.5f) * TILE_SIZE);
			const f32 yy = (dd * cos_yaw - dx * sin_yaw) + ((game.player.y + 0.5f) * TILE_SIZE);

			int xp = xx;
			int yp = yy;

			int xtile = xp >> (LOG2_TILE_SIZE);
			int ytile = yp >> (LOG2_TILE_SIZE);

			if (xx < 0)
				xp--;
			if (yy < 0)
				yp--;

			int tex = 0;
			int xtt = xp & (TILE_SIZE - 1);
			int ytt = yp & (TILE_SIZE - 1);

			if (xtile >= 0 && ytile >= 0 &&
			    xtile < level.width && ytile < level.height) {
				Tile tile = level.grid[xtile + ytile * level.width];
				if (tile.type != TILE_FLOOR && tile.type != TILE_BARS) {
					continue;
				}
				if (ceiling_mode)
					tex = tile.ceiling;
				else {
					tex = tile.floor;
					if (((xtile * ytile + xtile * 3 - 7) & 7) == 0)
						tex += 1;
				}
			}

			int x_tex = (tex % 16) * TILE_SIZE;
			int y_tex = (tex / 16) * TILE_SIZE;

			Color color = get_bitmap_pixel(art::floors, x_tex + xtt, y_tex + ytt);

			row[x] = color;

			game.display.depth_buffer[x + y * width] = (TILE_SIZE / 2) * depth;
		}
	}
}

void
render_wall(Game& game, int tex, const Vector2& p0, const Vector2& p1)
{
	const int width     = game.display.width;
	const int height    = game.display.height;
	const f32 x_center  = 0.5f * width;
	const f32 y_center  = (0.5f + game.player.pitch) * height;
	const f32 cos_theta = cosf(game.player.yaw);
	const f32 sin_theta = sinf(game.player.yaw);

	////////////////

	// NOTE(bill): -1.0f is to center player
	const f32 xc0 = 2 * (p0.x - game.player.x) - 1.0f;
	const f32 yc0 = 2 * (p0.y - game.player.y) - 1.0f;

	f32 xx0 = xc0 * cos_theta - yc0 * sin_theta;
	f32 u0  = 2 * game.player.z - 1;
	f32 l0  = 2 * game.player.z + 1;
	f32 zz0 = yc0 * cos_theta + xc0 * sin_theta;

	// NOTE(bill): -1.0f is to center player
	f32 xc1 = 2 * (p1.x - game.player.x) - 1.0f;
	f32 yc1 = 2 * (p1.y - game.player.y) - 1.0f;

	f32 xx1 = xc1 * cos_theta - yc1 * sin_theta;
	f32 u1  = 2 * game.player.z - 1;
	f32 l1  = 2 * game.player.z + 1;
	f32 zz1 = yc1 * cos_theta + xc1 * sin_theta;

	f32 xt0 = 0;
	f32 xt1 = TILE_SIZE;

	const f32 depth_clip = 0.001f;
	if (zz0 < depth_clip && zz1 < depth_clip)
		return;

	if (zz0 < depth_clip) {
		const f32 t = (depth_clip - zz0) / (zz1 - zz0);
		zz0         = lerp(zz0, zz1, t);
		xx0         = lerp(xx0, xx1, t);
		xt0         = lerp(xt0, xt1, t);
	}

	if (zz1 < depth_clip) {
		const f32 t = (depth_clip - zz0) / (zz1 - zz0);
		zz1         = lerp(zz0, zz1, t);
		xx1         = lerp(xx0, xx1, t);
		xt1         = lerp(xt0, xt1, t);
	}

	f32 xpixel0 = (xx0 / zz0 / game.player.fov) + x_center;
	f32 xpixel1 = (xx1 / zz1 / game.player.fov) + x_center;
	if (xpixel0 >= xpixel1)
		return;

	int xp0 = ceil(xpixel0);
	int xp1 = ceil(xpixel1);
	if (xp0 < 0)
		xp0 = 0;
	if (xp1 >= width)
		xp1 = width - 1;

	f32 ypixel00 = (u0 / zz0 / game.player.fov) + y_center;
	f32 ypixel01 = (l0 / zz0 / game.player.fov) + y_center;

	f32 ypixel10 = (u1 / zz1 / game.player.fov) + y_center;
	f32 ypixel11 = (l1 / zz1 / game.player.fov) + y_center;

	f32 iz0 = 1.0f / (f32)zz0;
	f32 iz1 = 1.0f / (f32)zz1;

	for (int x = xp0; x <= xp1; x++) {
		f32 tx = (x - xpixel0) / (xpixel1 - xpixel0);

		f32 depth = lerp(iz0, iz1, tx);

		int x_tex = lerp(xt0 * iz0, xt1 * iz1, tx) / depth;

		f32 ypixel0 = lerp(ypixel00, ypixel10, tx);
		f32 ypixel1 = lerp(ypixel01, ypixel11, tx);

		int yp0 = ypixel0;
		int yp1 = ypixel1;
		if (yp0 < 0)
			yp0 = 0;
		if (yp1 >= height)
			yp1 = height - 1;

		for (int y = yp0; y <= yp1; y++) {
			f32 ty    = (y - ypixel0) / (ypixel1 - ypixel0);
			int y_tex = ty * TILE_SIZE;

			if (game.display.depth_buffer[x + y * width] > depth)
				continue;

			const Color color = get_bitmap_pixel(art::floors,
			                                     (x_tex % TILE_SIZE) + (tex % 16) * TILE_SIZE,
			                                     (y_tex % TILE_SIZE) + (tex / 16) * TILE_SIZE);
			if (color.a < 128)
				continue;
			game.display.pixels[x + y * width]       = color;
			game.display.depth_buffer[x + y * width] = depth;
		}
	}
}

void
apply_post_fx(Framebuffer& display, f32 fog_strength)
{
	for (int i = 0; i < display.width * display.height; i++) {
		const Color color = display.pixels[i];
		if (color.a == 0)
			continue;

		const f32 depth = display.depth_buffer[i];

		constexpr int DEPTH_VALUES = 1 << 5;

		f32 brightness = DEPTH_VALUES * exp2(-fog_strength / depth);
		brightness     = (int)(clamp(brightness, 0, DEPTH_VALUES) + 0.5f) / (f32)DEPTH_VALUES;

		Color c = color;
		c.r *= brightness;
		c.g *= brightness;
		c.b *= brightness;

#if 0
		int grain = rand() & 7;
		if (c.r > 8 && c.g > 8 && c.b > 8) {
			c.r -= grain;
			c.g -= grain;
			c.b -= grain;
		}
#endif

		display.pixels[i] = c;
	}
}

void
render_sprite(Game& game, const Bitmap& spritesheet, int tex, const Vector3& position, const Vector2& scale)
{
	const int width     = game.display.width;
	const int height    = game.display.height;
	const f32 x_center  = 0.5f * width;
	const f32 y_center  = (0.5f + game.player.pitch) * height;
	const f32 cos_theta = cosf(game.player.yaw);
	const f32 sin_theta = sinf(game.player.yaw);

	////////////////

	f32 xc = +2 * (game.player.x - position.x);
	f32 yc = -2 * (game.player.y - position.y);
	f32 yy = +2 * (game.player.z - position.z);

	f32 xx = xc * cos_theta + yc * sin_theta;
	f32 zz = yc * cos_theta - xc * sin_theta;

	if (zz < 0.001f)
		return;

	f32 fz = 1.0f / (game.player.fov * zz);

	f32 xpixel = x_center - xx * fz;
	f32 ypixel = y_center + yy * fz;

	f32 xpixel0 = xpixel - scale.x * fz;
	f32 xpixel1 = xpixel + scale.x * fz;

	f32 ypixel0 = ypixel - scale.y * fz;
	f32 ypixel1 = ypixel + scale.y * fz;

	int xp0 = clamp(ceil(xpixel0), 0, width);
	int xp1 = clamp(ceil(xpixel1), 0, width);

	int yp0 = clamp(ceil(ypixel0), 0, height);
	int yp1 = clamp(ceil(ypixel1), 0, height);

	f32 depth = 1.0f / zz;

	for (int yp = yp0; yp < yp1; yp++) {
		f32 ypt = (yp - ypixel0) / (ypixel1 - ypixel0);
		int yt = TILE_SIZE * ypt + TILE_SIZE * (tex / 16);
		for (int xp = xp0; xp < xp1; xp++) {
			// NOTE(bill): Depth Testing
			if (game.display.depth_buffer[xp + yp * width] > depth)
				continue;

			f32 xpt = (xp - xpixel0) / (xpixel1 - xpixel0);

			int xt = TILE_SIZE * xpt + TILE_SIZE * (tex % 16);

			Color src = get_bitmap_pixel(spritesheet, xt, yt);
			if (src.a < 128)
				continue;

			// NOTE(bill): Cool blending!
			const Color dst = game.display.pixels[xp + yp * width];

			f32 a = src.a / 255.0f;
			src.r = src.r * a + dst.r * (1.0f - a);
			src.g = src.g * a + dst.g * (1.0f - a);
			src.b = src.b * a + dst.b * (1.0f - a);
			src.a = src.a + dst.a * (1.0f - a);

			game.display.pixels[xp + yp * width]       = src;
			game.display.depth_buffer[xp + yp * width] = depth;
		}
	}
}

void
render_text(Game& game, const char* str, const Vector2& position, Color color)
{
	const int length = strlen(str);
	for (int i = 0; i < length; i++) {

		int ch = get_char_index(str[i]);
		if (ch < 0)
			continue;
		int xx = ch % 26;
		int yy = ch / 26;

		for (int y = 0; y < CHAR_HEIGHT; y++) {
			for (int x = 0; x < CHAR_WIDTH - 1; x++) {
				const Color pixel = get_bitmap_pixel(art::font,
				                                     xx * CHAR_WIDTH + x,
				                                     yy * CHAR_HEIGHT + y);
				if (pixel.rgba != WHITE.rgba) // NOTE(bill): Anything but white is alpha
					continue;

				set_bitmap_pixel(game.display, color,
				                 x + position.x + i * CHAR_WIDTH,
				                 y + position.y);
			}
		}
	}
}
