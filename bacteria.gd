extends Node2D

const GRID_WIDTH = 140
const GRID_HEIGHT =70
const CELL_SIZE = 12
const GAME_TICK_SPEED = 0.1
const BACTERIA_CELL_DEATH_CHANCE = 0.2

var grid = []

func get_random_coord() -> Vector2i:
	return Vector2i(
		randi() % GRID_WIDTH,
		randi() % GRID_HEIGHT
	)

func _init_grid():
	grid.clear()
	for y in range(GRID_HEIGHT):
		var row = []
		for x in range(GRID_WIDTH):
			row.append(1)  # make all cells white

		grid.append(row)
		
	
	var red_pos_1 = get_random_coord()
	var red_pos_2 = get_random_coord()
	var green_pos_1 = get_random_coord()
	var green_pos_2 = get_random_coord()
	
	
	grid[red_pos_1.y][red_pos_1.x] = 2
	grid[red_pos_2.y][red_pos_2.x] = 2
	grid[green_pos_1.y][green_pos_1.x] = 3
	grid[green_pos_2.y][green_pos_2.x] = 3

func _draw_cells():
	# Draw live cells
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var value = grid[y][x]
			if value == 1:
				draw_rect(Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE), Color.WHITE)
			elif value == 2:
				draw_rect(Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE), Color.RED)
			elif value == 3:
				draw_rect(Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE), Color.GREEN)
				
func _draw_grid_lines():
	# Draw vertical lines
	for x in range(GRID_WIDTH + 1):
		draw_line(
			Vector2(x * CELL_SIZE, 0),
			Vector2(x * CELL_SIZE, GRID_HEIGHT * CELL_SIZE),
			Color(0.2, 0.2, 0.2),
			1
		)

	# Draw horizontal lines
	for y in range(GRID_HEIGHT + 1):
		draw_line(
			Vector2(0, y * CELL_SIZE),
			Vector2(GRID_WIDTH * CELL_SIZE, y * CELL_SIZE),
			Color(0.2, 0.2, 0.2),
			1
		)
		
func _draw():
	_draw_cells();
	_draw_grid_lines();
		
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var cell_x = int(event.position.x / CELL_SIZE)
		var cell_y = int(event.position.y / CELL_SIZE)

		if cell_x >= 0 and cell_x < GRID_WIDTH and cell_y >= 0 and cell_y < GRID_HEIGHT:
			grid[cell_y][cell_x] = 2  # Mark as red "bacteria" cell
			queue_redraw()
				
func _spread_bacteria():
	var to_infect = []

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var current = grid[y][x]
			if current in [2, 3]:
				if randf() < 0.3:
					grid[y][x] = 1
					continue

				var candidates = []

				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue

						var nx = x + dx
						var ny = y + dy

						if nx >= 0 and nx < GRID_WIDTH and ny >= 0 and ny < GRID_HEIGHT:
							var target = grid[ny][nx]

							if current == 2 and target in [1, 3]:
								candidates.append(Vector2i(nx, ny))
							elif current == 3 and target in [1, 2]:
								candidates.append(Vector2i(nx, ny))

				if candidates.size() > 0:
					var chosen = candidates[randi() % candidates.size()]
					to_infect.append({ "pos": chosen, "type": current })

	for entry in to_infect:
		var p = entry["pos"]
		var t = entry["type"]
		grid[p.y][p.x] = t

	queue_redraw()


func _ready():
	_init_grid()
	queue_redraw()
	await get_tree().create_timer(0.2).timeout
	_start_spread_loop()


func _start_spread_loop() -> void:
	while true:
		await get_tree().create_timer(GAME_TICK_SPEED).timeout
		_spread_bacteria()
