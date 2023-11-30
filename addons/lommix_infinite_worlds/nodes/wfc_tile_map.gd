class_name WfcTileMap
extends TileMap

@export var wfc_tile_set: WfcTileSet
@export var loading_radius : int = 3
@export var unstable_layer_thickness : int = 3
@export_range(0, 1) var update_intervall : float = 0.1
@export var follow_path: NodePath
@export var debug : bool = false

#load around this nodes position
var follow : Node2D
var timer : float = 0.0

var draw_node : Node2D = Node2D.new()
var grid_node : Node2D = Node2D.new()
var rects : Array[Rect2] = []

#buffer for tiles to be drawn
var draw_buffer : Array[WfcCell] = []


var thread_id : int = 0
var last_pos : Vector2i

func _ready():
	if follow_path:
		follow = get_node(follow_path)

	WfcTileSet.load_layers(self,wfc_tile_set)
	add_child(draw_node)
	add_child(grid_node)
	grid_node.top_level = true
	draw_node.top_level = true
	draw_node.draw.connect(draw_loading_radius)
	grid_node.draw.connect(draw_grid)

func _physics_process(delta: float):
	if !is_instance_valid(follow):
		follow = null
		return

	draw_node.global_position = follow.global_position
	timer += delta
	if timer < update_intervall:
		return
	timer = 0.0
	last_pos = get_pattern_pos_from_global(follow.global_position)

	if thread_id && WorkerThreadPool.is_task_completed(thread_id):
		consume_draw_buffer()
		thread_id = 0

	if !thread_id:
		thread_id = WorkerThreadPool.add_task(load_and_collapse)


	# draw_node.visible = GameContext.debug_mode
	# grid_node.visible = GameContext.debug_mode
	# if debug:
	# 	draw_node.queue_redraw()
	# 	grid_node.queue_redraw()

## global position to load next
func queue_load(position : Vector2) -> bool:
	return false


func load_and_collapse():
	load_unstable_cells(last_pos)
	collapse_next(last_pos)

#draw debug radius
func draw_loading_radius():
	if !debug:
		return
	var inner_size = loading_radius * 2 + 1
	var rect_inner = Rect2(
		wfc_tile_set.pattern_size * inner_size * -0.5 * wfc_tile_set.quad_size,
		wfc_tile_set.pattern_size * inner_size * wfc_tile_set.quad_size)
	var outer_size = (loading_radius + unstable_layer_thickness) * 2 +1
	var rect_outer = Rect2(
		wfc_tile_set.pattern_size * outer_size * -0.5 * wfc_tile_set.quad_size,
		wfc_tile_set.pattern_size * outer_size * wfc_tile_set.quad_size)
	draw_node.draw_rect(rect_inner, Color.DARK_BLUE, false, wfc_tile_set.pattern_size.x * 2)
	draw_node.draw_rect(rect_outer, Color.RED, false, wfc_tile_set.pattern_size.x * 2)

#draw debug grid
func draw_grid():
	if !debug:
		return
	for rect in rects:
		grid_node.draw_rect(rect, Color.WHITE, false, wfc_tile_set.pattern_size.x)

#transform a global position to a cell on the cell grid
func get_pattern_pos_from_global(global_pos:Vector2) -> Vector2i:
	var tile_pos :=  Vector2i(global_pos.x / wfc_tile_set.quad_size, global_pos.y / wfc_tile_set.quad_size)
	var pattern_pos = Vector2i((tile_pos.x / wfc_tile_set.pattern_size.x), (tile_pos.y / wfc_tile_set.pattern_size.y))
	if global_pos.x < 0: pattern_pos.x -=1;
	if global_pos.y < 0: pattern_pos.y -=1;
	return pattern_pos

#add new unstable cells to the world map
func load_unstable_cells(center : Vector2i):
	var mean_radius = loading_radius + unstable_layer_thickness
	for x in mean_radius * 2 + 1:
		for y in mean_radius * 2 + 1:
			var offset = Vector2i(x + center.x - mean_radius, y + center.y - mean_radius)
			if wfc_map.loaded_cell.has(offset):
				continue
			wfc_map.loaded_cell[offset] = WfcCell.new(wfc_tile_set, offset)
			rects.append(Rect2(offset * wfc_tile_set.quad_size * wfc_tile_set.pattern_size, wfc_tile_set.pattern_size * wfc_tile_set.quad_size))

#load next collapse buffer from world map into array
func get_next_collapse_buffer(center : Vector2i) -> Array[WfcCell]:
	var next_to_collapse : Array[WfcCell] = []
	for x in loading_radius * 2 + 1:
		for y in loading_radius * 2 + 1:
			var offset = Vector2i(x + center.x - loading_radius, y + center.y - loading_radius)
			if wfc_map.loaded_cell.has(offset) && !wfc_map.loaded_cell[offset].is_collapsed():
				next_to_collapse.append(wfc_map.loaded_cell[offset])
	return next_to_collapse

#collapse the next buffer
func collapse_next(center : Vector2i):
	var next_array = get_next_collapse_buffer(center)
	var stable_result : Array[WfcCell] = []
	#get lowest
	for i in next_array.size():
		var lowest = get_lowest_entropy_cell(next_array)
		#collapse
		lowest.collapse()
		draw_buffer.append(lowest)
		propagate(lowest.cell_grid_position)

#empty the draw buffer by drawing the result
func consume_draw_buffer():
	for cell in draw_buffer:
		draw_pattern(cell.cell_grid_position, cell.collapsed_to)
		wfc_map.on_cell_draw.emit(cell)
	draw_buffer.clear()

#propagate cell change after collapse
func propagate(coords: Vector2i):
	for layer in Slicer.prop_map:
		for offset in layer:
			var next_eval_coord = coords + offset
			evaluate(next_eval_coord)

#evalate a given cell position
func evaluate(coords : Vector2i):
	if !wfc_map.loaded_cell.has(coords) || wfc_map.loaded_cell[coords].is_collapsed():
		return
	var current_cell = wfc_map.loaded_cell[coords]
	var cell: WfcCell = wfc_map.loaded_cell[coords]
	for direction in Slicer.dir_sequence:
		if !wfc_map.loaded_cell.has(coords + direction):
			continue
		var neighbor_cell : WfcCell = wfc_map.loaded_cell[coords + direction]
		var allowed = neighbor_cell.get_possible_sockets(direction * -1)
		#if there is only one left, collapse and propagate before contradiction
		if wfc_map.loaded_cell[coords].reduce_possible_sockets(direction, allowed):
			wfc_map.loaded_cell[coords].collapse()
			draw_buffer.append(wfc_map.loaded_cell[coords])
			propagate(coords)

#draw wfc tile to tilemap
func draw_pattern(vec:Vector2i, tile : WfcTile):
	if wfc_tile_set.original_layers[0]["render"]:
		set_pattern(0, vec * tile.pattern.get_size(), tile.pattern)
	for i in tile.additional_layers.size():
		if wfc_tile_set.original_layers[1+i]["render"]:
			set_pattern(i+1, vec * tile.pattern.get_size(), tile.additional_layers[i])

func build_preset(coord : Vector2i, preset : WfcPreset):
	for pos in preset.tiles:
		var cell := WfcCell.new(wfc_tile_set, coord + pos)
		cell.collapsed_to = wfc_tile_set.find_tile(preset.tiles[pos])
		draw_pattern(cell.cell_grid_position, cell.collapsed_to)
		wfc_map.on_cell_draw.emit(cell)
		wfc_map.loaded_cell[coord + pos] = cell

#find lowest entropy cell in collapse buffer
func get_lowest_entropy_cell(array : Array[WfcCell]) -> WfcCell:
	var lowest : WfcCell
	for cell in array:
		if !lowest:
			lowest = cell
			continue
		if lowest.possible_tiles.size() > cell.possible_tiles.size():
			lowest = cell
	array.erase(lowest)
	return lowest

