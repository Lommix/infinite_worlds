@tool
extends Control

@onready var tile_set_container: PanelContainer = %tile_set_container
@onready var draw_surface: GridContainer = %draw_surface
@onready var tile_select: GridContainer = %tile_select
@onready var save_button: Button = %save_button
@onready var save_container: PanelContainer = %save_container
@onready var clear: Button = %clear

var draw_buttons := {}
var preset_grid := {}
var tile_set_picker : EditorResourcePicker
var preset_save_picker : EditorResourcePicker
var tileset : WfcTileSet
var current_selection : WfcTile


func _ready() -> void:
	for y in 10:
		for x in 10:
			var button = Button.new()
			button.custom_minimum_size = Vector2(80,80)
			var coord = Vector2i(x, y)
			draw_buttons[coord] = button
			button.pressed.connect(func(): on_draw_input(coord, button))
			draw_surface.add_child(button)

	if !Engine.is_editor_hint():
		return
	tile_set_picker = EditorResourcePicker.new()
	tile_set_container.add_child(tile_set_picker)
	tile_set_picker.custom_minimum_size = Vector2(200,30)
	tile_set_picker.resource_changed.connect(on_tile_set_change)
	preset_save_picker = EditorResourcePicker.new()
	save_container.add_child(preset_save_picker)
	preset_save_picker.custom_minimum_size = Vector2(200,30)
	preset_save_picker.resource_changed.connect(on_tile_set_change)
	save_button.pressed.connect(save_as_resource)
	clear.pressed.connect(func(): current_selection = null)

func save_as_resource():
	var preset = WfcPreset.new()
	for coord in preset_grid:
		if preset_grid[coord]:
			preset.tiles[coord] = preset_grid[coord].hash
	preset_save_picker.edited_resource = preset

func on_draw_input(coords: Vector2i, button : Button):
	for child in button.get_children():
		child.free()
	preset_grid[coords] = current_selection
	if current_selection:
		var icon = create_icon(current_selection)
		button.add_child(icon)

func on_tile_set_change(res):
	if !res || !res is WfcTileSet:
		clear_draw_set()
		return
	load_draw_set(res)

func on_preset_save_change(res):
	if !res || !res is WfcPreset:
		return
	for child in draw_surface.get_children():
		if child.get_child(0):
			child.get_child(0).free()
	if !tileset:
		push_error("no tileset")
		return
	for coord in res.tiles:
		var icon = create_icon(res.tiles[coord])
		preset_grid[coord] = tileset.find_tile(res.tiles[coord].hash)
		draw_buttons[coord].add_child(icon)

func clear_draw_set():
	for child in tile_select.get_children():
		child.free()
	for child in draw_surface.get_children():
		if child.get_child(0):
			child.get_child(0).free()

func load_draw_set(tileset : WfcTileSet):
	clear_draw_set()
	self.tileset = tileset
	for tile in tileset.wfc_tiles:
		add_list_item(tile)

func create_icon(tile:WfcTile) -> TileMap:
	var tilemap = TileMap.new()
	tilemap.tile_set = tileset.tile_set
	tilemap.cell_quadrant_size = tileset.quad_size
	WfcTileSet.load_layers(tilemap,tileset)
	var scale = 80.0/(tileset.quad_size as float * tileset.pattern_size.x as float)
	tilemap.scale = Vector2(scale,scale)
	for i in tile.additional_layers.size():
		tilemap.set_pattern(i, Vector2i.ZERO, tile.additional_layers[i])
	return tilemap

func add_list_item(tile:WfcTile):
	var button = BaseButton.new()
	button.custom_minimum_size = Vector2i(80,80)
	var icon = create_icon(tile)
	button.add_child(icon)
	button.connect("pressed", func(): current_selection = tile)
	tile_select.call_deferred("add_child",button)
