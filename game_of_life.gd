extends Node2D

const GRID_WIDTH = 100
const GRID_HEIGHT = 100
const CELL_SIZE = 6

var grid = []


func _ready():
	_init_grid()
	queue_redraw()
	_start_loop()


func _init_grid():
	grid.clear()
	for y in range(GRID_HEIGHT):
		var row = []
		for x in range(GRID_WIDTH):
			row.append(randi() % 2)  # randomly 0 or 1
		grid.append(row)

func _draw():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid[y][x] == 1:
				draw_rect(
					Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE),
					Color.WHITE
				)

func _start_loop() -> void:
	await get_tree().create_timer(0.1).timeout
	_step_simulation()
	_start_loop()
	
	
func _step_simulation():
	var new_grid = []
	for y in range(GRID_HEIGHT):
		var new_row = []
		for x in range(GRID_WIDTH):
			var alive_neighbors = _count_alive_neighbors(x, y)
			var alive = grid[y][x]

			var next_state = 0
			if alive == 1:
				if alive_neighbors == 2 or alive_neighbors == 3:
					next_state = 1
			else:
				if alive_neighbors == 3:
					next_state = 1

			new_row.append(next_state)
		new_grid.append(new_row)

	grid = new_grid
	queue_redraw()
	
func _count_alive_neighbors(x: int, y: int) -> int:
	var count = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue  # skip the current cell

			var nx = x + dx
			var ny = y + dy

			if nx >= 0 and nx < GRID_WIDTH and ny >= 0 and ny < GRID_HEIGHT:
				count += grid[ny][nx]

	return count
