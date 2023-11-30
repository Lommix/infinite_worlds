extends Node2D


@onready var trees : Node2D = $trees
@onready var houses : TileMap = $houses

var tree_scene = preload("res://tree.tscn")


func _ready() -> void:
	wfc_map.on_cell_draw.connect(wfc_draw_event)
	pass


func wfc_draw_event(cell: WfcCell):
	for plot in cell.get_layer_used_tiles("house_plots"):
		if randf() < 0.4:
			spawn_house_at(plot)

	for plot in cell.get_layer_used_tiles("tree_plots"):
		if randf() < 0.4:
			spawn_tree_at(plot)


func spawn_tree_at(pos : Vector2):
	var tree = tree_scene.instantiate()
	tree.global_position = pos
	trees.add_child(tree)


func spawn_house_at(pos : Vector2):
	if pos.x < 0.0 :
		pos.x -= houses.tile_set.tile_size.x

	if pos.y < 0.0 :
		pos.y -= houses.tile_set.tile_size.y

	var tile_position = pos / houses.tile_set.tile_size.x
	houses.set_pattern(0, tile_position, houses.tile_set.get_pattern(randi() % houses.tile_set.get_patterns_count()))
