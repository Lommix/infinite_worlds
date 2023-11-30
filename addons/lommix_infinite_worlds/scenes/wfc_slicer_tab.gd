@tool
extends Control

@onready var pattern_y: SpinBox = %pattern_y
@onready var pattern_x: SpinBox = %pattern_x
@onready var region_y: SpinBox = %region_y
@onready var region_x: SpinBox = %region_x
@onready var tile_set_editor: HBoxContainer = $tile_set_editor
@onready var slice_btn: Button = %slice_btn
@onready var grid_show: Button = %grid_show
@onready var actions: HBoxContainer = %Actions
@onready var border: SpinBox = %border
@onready var render: MenuButton = %render

var tilemap : TileMap
var draw_agent : Node2D
var wfc_tile_set : WfcTileSet
var slice_region_size: Vector2i = Vector2i(5,5)
var pattern_size: Vector2i = Vector2i(3,3)
var border_size:int = 3
var picker: EditorResourcePicker

func _ready() -> void:
	pattern_x.value_changed.connect(func(value): pattern_size.x = value; draw_agent.queue_redraw())
	pattern_y.value_changed.connect(func(value): pattern_size.y = value; draw_agent.queue_redraw())
	region_y.value_changed.connect(func(value): slice_region_size.y = value; draw_agent.queue_redraw())
	region_x.value_changed.connect(func(value): slice_region_size.x = value; draw_agent.queue_redraw())
	border.value_changed.connect(func(value): border_size = value; draw_agent.queue_redraw())
	grid_show.pressed.connect(func(): if draw_agent: draw_agent.visible = true)
	slice_btn.pressed.connect(slice)
	
	if !Engine.is_editor_hint():
		return
	picker = EditorResourcePicker.new()
	actions.add_child(picker)
	picker.custom_minimum_size = Vector2(200,50)
	picker.resource_changed.connect(on_resource_change)

func toggle_layer_state(id : int):
	wfc_tile_set.original_layers[id]["render"] = !wfc_tile_set.original_layers[id]["render"]
	render.get_popup().set_item_checked(id,wfc_tile_set.original_layers[id]["render"])

func load_render_layer_menu():
	render.get_popup().clear()
	for i in wfc_tile_set.original_layers.size():
		render.get_popup().add_check_item(wfc_tile_set.original_layers[i]["name"],i)
		render.get_popup().set_item_checked(i,wfc_tile_set.original_layers[i]["render"])
	render.get_popup().index_pressed.connect(toggle_layer_state)

func on_resource_change(res):
	if !res || !res is WfcTileSet:
		tile_set_editor.unload()
		render.get_popup().clear()
		return
	wfc_tile_set = res
	tile_set_editor.load_tile_set(res)
	load_render_layer_menu()
	
func inject_target_tilemap(target: TileMap):
	if draw_agent:
		draw_agent.free()
	tilemap = target
	draw_agent = Node2D.new()
	draw_agent.top_level = true
	draw_agent.visible = false
	draw_agent.connect("draw", draw_grid)
	tilemap.add_child(draw_agent)

func _exit_tree() -> void:
	if draw_agent:
		draw_agent.queue_free()

#draw slice grid to editor window
func draw_grid():
	var tile_size = tilemap.tile_set.tile_size.x
	var slice_width = pattern_size.x * tile_size * slice_region_size.x
	var slice_height = pattern_size.y * tile_size * slice_region_size.y
	for i in slice_region_size.x:
		draw_agent.draw_line(Vector2(tile_size * i * pattern_size.x,0), Vector2(tile_size * i * pattern_size.x,slice_height), Color.LIGHT_BLUE, border_size)
	for i in slice_region_size.y:
		draw_agent.draw_line(Vector2(0,tile_size * i * pattern_size.y), Vector2(slice_width,tile_size * i * pattern_size.y), Color.LIGHT_BLUE, border_size)
	var rect := Rect2(Vector2.ZERO, Vector2(slice_width,slice_height))
	draw_agent.draw_rect(rect,Color.LIGHT_BLUE,false,border_size)

#slice tilemap
func slice():
	wfc_tile_set = Slicer.slice(tilemap, pattern_size, slice_region_size)
	tile_set_editor.load_tile_set(wfc_tile_set)
	picker.edited_resource = wfc_tile_set
	load_render_layer_menu()
