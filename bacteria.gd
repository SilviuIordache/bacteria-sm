extends Node2D

const GRID_WIDTH = 140
const GRID_HEIGHT =70
const CELL_SIZE = 12
const GAME_TICK_SPEED = 0.4
const BACTERIA_CELL_DEATH_CHANCE = 0.2

var is_drawing_block := false  # Tracks whether mouse is held down
var last_drawn_cell: Vector2i = Vector2i(-1, -1)  # sentinel value meaning "none"



enum CellType {
	EMPTY,
	BACTERIA_RED,
	BACTERIA_GREEN,
	BLOCK
}

const CELL_INFO = {
	CellType.EMPTY: { "value": 1, "color": Color.WHITE, "infectable": true },
	CellType.BACTERIA_RED: { "value": 2, "color": Color.RED, "infectable": false },
	CellType.BACTERIA_GREEN: { "value": 3, "color": Color.GREEN, "infectable": false },
	CellType.BLOCK: { "value": 4, "color": Color.BLACK, "infectable": false },
}

var grid = []

func _handle_user_draw():
	var mouse_pos = get_viewport().get_mouse_position()
	var cell_x = int(mouse_pos.x / CELL_SIZE)
	var cell_y = int(mouse_pos.y / CELL_SIZE)
	var current_cell = Vector2i(cell_x, cell_y)

	if cell_x >= 0 and cell_x < GRID_WIDTH and cell_y >= 0 and cell_y < GRID_HEIGHT:
		if last_drawn_cell == Vector2i(-1, -1) or last_drawn_cell == current_cell:
			_draw_cell(current_cell)
		else:
			# Bresenham's line algorithm for smoother drawing
			var points = _get_line_cells(last_drawn_cell, current_cell) if last_drawn_cell.distance_to(current_cell) > 1 else [current_cell]

			for p in points:
				_draw_cell(p)

		last_drawn_cell = current_cell

func _draw_cell(cell: Vector2i):
	if grid[cell.y][cell.x] != CellType.BLOCK:
		grid[cell.y][cell.x] = CellType.BLOCK
		queue_redraw()

func _get_line_cells(start: Vector2i, end: Vector2i) -> Array:
	var points = []
	var dx = abs(end.x - start.x)
	var dy = -abs(end.y - start.y)
	var sx = 1 if start.x < end.x else -1
	var sy = 1 if start.y < end.y else -1
	var err = dx + dy
	var x = start.x
	var y = start.y

	while true:
		points.append(Vector2i(x, y))
		if x == end.x and y == end.y:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy

	return points

func get_random_coord() -> Vector2i:
	return Vector2i(
		randi() % GRID_WIDTH,
		randi() % GRID_HEIGHT
	)
	
func set_random_cell(cell_type: CellType) -> void:
	var coord = get_random_coord()
	grid[coord.y][coord.x] = cell_type

func _init_grid():
	grid.clear()
	for y in range(GRID_HEIGHT):
		var row = []
		for x in range(GRID_WIDTH):
			row.append(CellType.EMPTY)
		grid.append(row)
		
	
	set_random_cell(CellType.BACTERIA_RED)
	set_random_cell(CellType.BACTERIA_RED)
	set_random_cell(CellType.BACTERIA_GREEN)
	set_random_cell(CellType.BACTERIA_GREEN)

func _draw_cells():
	# Draw live cells
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell_type = grid[y][x]
			var cell_data = CELL_INFO.get(cell_type, null)
			if cell_data:
				draw_rect(Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE), cell_data.color)
				
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
	if event is InputEventMouseButton:
		is_drawing_block = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
		if not is_drawing_block:
			last_drawn_cell = Vector2i(-1, -1)
				
func _spread_bacteria():
	
	var snapshot = []
	for row in grid:
		snapshot.append(row.duplicate())  # Deep copy each row
		
	var to_infect = []

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var current = snapshot[y][x]
			if current in [CellType.BACTERIA_RED, CellType.BACTERIA_GREEN]:
				if randf() < BACTERIA_CELL_DEATH_CHANCE:
					grid[y][x] = CellType.EMPTY
					continue

				var candidates = []
				var directions = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]  # Only cardinal directions


				for dir in directions:
					var nx = x + dir.x
					var ny = y + dir.y
						
					if nx >= 0 and nx < GRID_WIDTH and ny >= 0 and ny < GRID_HEIGHT:
						var target = snapshot[ny][nx] 

						if current == CellType.BACTERIA_RED and target in [CellType.EMPTY, CellType.BACTERIA_GREEN]:
							candidates.append(Vector2i(nx, ny))
						elif current == CellType.BACTERIA_GREEN and target in [CellType.EMPTY, CellType.BACTERIA_RED]:
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

func _process(_delta):
	if is_drawing_block:
		_handle_user_draw()
