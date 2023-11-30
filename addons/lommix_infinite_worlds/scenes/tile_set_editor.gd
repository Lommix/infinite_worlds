@tool
extends HBoxContainer

@onready var socket_label: Label = %socket_label
@onready var name_input: TextEdit = %name_input
@onready var weight_input: SpinBox = %weight_input
@onready var tile_set_list: GridContainer = %tile_set_list
@onready var cursor: ColorRect = %cursor
@onready var r: Button = %R
@onready var g: Button = %G
@onready var b: Button = %B
@onready var w: Button = %W


const MAX_DETAIL_SIZE = 160
const MAX_LIST_SIZE = 80

var detail_scale:float
var list_scale:float
var current_detail:WfcTile
var current_wfc_tile_set:WfcTileSet
var current_button : BaseButton
var current_color_mode : String = ""

func _ready() -> void:
	name_input.text_changed.connect(set_tile_name)
	weight_input.value_changed.connect(set_tile_weight)
	r.pressed.connect(func(): set_color_mode("red"))
	g.pressed.connect(func(): set_color_mode("green"))
	b.pressed.connect(func(): set_color_mode("blue"))
	w.pressed.connect(func(): set_color_mode("white"))

func set_tile_name() -> void:
	if current_detail:
		current_detail.name = name_input.text


func set_color_mode(color : String):
	current_color_mode = color
	pass


func set_tile_weight(value:float) -> void:
	if current_detail:
		current_detail.weight = value
#tile_set, quad_size
func load_tile_set(tile_set: WfcTileSet):
	unload()
	detail_scale = MAX_DETAIL_SIZE as float / (tile_set.quad_size as float * tile_set.pattern_size.x as float)
	list_scale = MAX_LIST_SIZE as float / (tile_set.quad_size as float * tile_set.pattern_size.x as float)
	current_wfc_tile_set = tile_set
	for child in tile_set_list.get_children():
		child.free()
	for tile in tile_set.wfc_tiles:
		add_list_item(tile)
		
func _physics_process(delta: float) -> void:
	if current_detail && current_button:
		cursor.visible = true
		cursor.global_position = current_button.global_position + Vector2(-2,-2)
	else :
		cursor.visible = false

func unload():
	current_detail = null
	socket_label.text = ""
	weight_input.value = 0
	name_input.text = ""
	cursor.visible = false
	current_button = null
	for child in tile_set_list.get_children():
		child.free()

func on_tile_click(tile: WfcTile, button : BaseButton):
	if current_color_mode:
		button.modulate = Color(current_color_mode)
		if current_color_mode == "white":
			tile.group = ""
		else:
			tile.group = current_color_mode
	
	current_detail = tile
	socket_label.text = "Used Layers: %s \n\n" % (tile.additional_layers.size() + 1)
	socket_label.text += "UP: %s\n" % tile.sockets[Vector2i.UP]
	socket_label.text += "DOWN: %s\n" % tile.sockets[Vector2i.DOWN]
	socket_label.text += "LEFT: %s\n" % tile.sockets[Vector2i.LEFT]
	socket_label.text += "RIGHT: %s\n" % tile.sockets[Vector2i.RIGHT]
	socket_label.text += "HASH: %s\n\n" % tile.hash
	weight_input.value = tile.weight
	name_input.text = tile.name
	current_button = button
	#group_input.select(tile.group)

func calculate_scale_factor() -> Vector2:
	return Vector2.ONE

func add_list_item(tile:WfcTile):
	var button = BaseButton.new()
	button.custom_minimum_size = Vector2i(MAX_LIST_SIZE,MAX_LIST_SIZE)
	var tilemap = TileMap.new()
	WfcTileSet.load_layers(tilemap,current_wfc_tile_set)
	tilemap.tile_set = current_wfc_tile_set.tile_set
	tilemap.cell_quadrant_size = current_wfc_tile_set.quad_size
	tilemap.scale = Vector2(self.list_scale,self.list_scale)
	tilemap.set_pattern(0, Vector2i.ZERO, tile.pattern)
	for i in tile.additional_layers.size():
		tilemap.set_pattern(i+1, Vector2i.ZERO, tile.additional_layers[i])
	button.add_child(tilemap)
	button.connect("pressed", func(): on_tile_click(tile, button))
	tile_set_list.add_child(button)


