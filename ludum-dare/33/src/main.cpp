#include "game.hpp"

internal void
render(Game& game)
{
	defer({
		SDL_BlitSurface(game.display.surface, nullptr,
		                game.window, nullptr);
		SDL_UpdateRect(game.window, 0, 0, game.window->w, game.window->h);
	});

	SDL_LockSurface(game.display.surface);
	defer(SDL_UnlockSurface(game.display.surface));

	clear_buffers(game.display, BLACK);

	render_level(game);

	apply_post_fx(game.display, 0.3f);

	render_ui(game);
}

internal void
update(Game& game, f32 dt)
{
	game.keys = SDL_GetKeyboardState(nullptr);

	update_game(game, dt);
}

void
handle_events(Game& game)
{
	SDL_Event event;
	while (SDL_PollEvent(&event)) {
		if (event.type == SDL_QUIT) {
			game.running = false;
			break;
		}
		if (event.type == SDL_WINDOWEVENT) {
			switch (event.window.event) {
			case SDL_WINDOWEVENT_FOCUS_LOST: {
				game.has_focus = false;
			} break;
			case SDL_WINDOWEVENT_FOCUS_GAINED: {
				game.has_focus = true;
				game.prev_time = game.frame_time = SDL_GetTicks();
				game.frame_count = 0;
			} break;
			}
		}
	}
}

extern "C" void
main_loop(void* game_ptr)
{
	if (game_ptr == nullptr) {
		printf("[ERROR] Game pointer passed to main_loop is null\n");
		return;
	}
	Game& game = *(Game*)game_ptr;

	handle_events(game);

	if (!game.running) {
		printf("Exiting...\n");
		emscripten_force_exit(0);
		return;
	}


	if (game.has_focus || true) {
		game.prev_time = game.curr_time;
		game.curr_time = SDL_GetTicks();
		if (game.curr_time < game.prev_time)
			game.curr_time = game.prev_time;
		game.accumulator += 0.001 * (game.curr_time - game.prev_time);

		while (game.accumulator >= TIME_STEP) {
			game.accumulator -= TIME_STEP;
			handle_events(game);
			update(game, TIME_STEP);
		}
	}

	render(game);

	local_persist char fps_buffer[8] = {0};
	game.frame_count++;
	if (game.curr_time - game.frame_time >= 1000) {
		const f32 dt = (game.curr_time - game.frame_time);
		const f32 ms = dt / game.frame_count;
		snprintf(fps_buffer, 8,
		         "%.1f ms", ms);

		game.fps = game.frame_count;
		game.frame_count = 0;
		game.frame_time  = SDL_GetTicks();
	}
}

int
main(int argc, char** argv)
{
	Game game = {};

	if (!init(game)) {
		fprintf(stderr, "Game failed to initialize.\n");
		return 1;
	}

	emscripten_set_main_loop_arg(main_loop, (void*)&game, 0, true);

	return 0;
}
