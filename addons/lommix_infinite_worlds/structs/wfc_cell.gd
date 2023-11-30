class_name WfcCell
extends RefCounted

var possible_tiles: Array[WfcTile]
var collapsed_to: WfcTile

#gloabl position in the cell grid!
var cell_grid_position : Vector2i
var global_position : Vector2
var global_center : Vector2
var wfc_tile_set : WfcTileSet

func _init(set : WfcTileSet, cell_pos : Vector2i) -> void:
	possible_tiles = set.wfc_tiles.duplicate()
	cell_grid_position = cell_pos
	wfc_tile_set = set
	global_position = cell_pos * wfc_tile_set.pattern_size * wfc_tile_set.quad_size
	global_center = global_position + wfc_tile_set.pattern_size * wfc_tile_set.quad_size * 0.5


func get_layer_used_tiles(layer : String) -> Array:
	var positions = []
	for i in collapsed_to.additional_layers_name.size():
		if collapsed_to.additional_layers_name[i] == layer:
			for pos in collapsed_to.additional_layers[i].get_used_cells():
				positions.append(global_position + Vector2(pos.x,pos.y) * wfc_tile_set.quad_size + Vector2(0.5,0.5) * wfc_tile_set.quad_size)
	return positions


func collapse() -> WfcTile:
	if possible_tiles.size() == 0:
		wfc_map.on_contradiction.emit(self)
	collapsed_to = get_weighted_random()
	return collapsed_to 

func get_weighted_random() -> WfcTile:
	var total_weight : float = 0
	var accumlation := []
	for i in possible_tiles.size():
		total_weight += possible_tiles[i].weight
		accumlation.insert(i, total_weight)
		
	var roll := randf_range(0.0,total_weight)
	for i in possible_tiles.size():
		if accumlation[i] > roll:
			return possible_tiles[i]

	if possible_tiles.size() > 0:
		return possible_tiles[randi() % possible_tiles.size()]
	return null

func is_collapsed() -> bool:
	return collapsed_to != null

#get by socket rule
func get_possible_sockets(direction: Vector2i) -> Array:
	if collapsed_to:
		return [collapsed_to.sockets[direction]]
	var possible := []
	for tile in possible_tiles:
		if !possible.has(tile.sockets[direction]):
			possible.append(tile.sockets[direction])
	return possible

#remove by socket rule
func reduce_possible_sockets(direction: Vector2i, allowed: Array) -> bool:
	var to_remove := []
	for tile in possible_tiles:
		if !allowed.has(tile.sockets[direction]):
			to_remove.append(tile)
	for tile in to_remove:
		possible_tiles.erase(tile)
	if possible_tiles.size() == 1:
		return true
	return false
