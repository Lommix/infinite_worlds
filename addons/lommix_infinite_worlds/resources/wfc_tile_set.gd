class_name WfcTileSet
extends Resource

## Wave function collapse Tile set
## - generate by using the Wfc Slicer!
## see : [class WfcTileMap]
## available wfc tiles
@export var wfc_tiles : Array[WfcTile]
## layer data
@export var original_layers : Array
## pixel size of a single tile
@export var quad_size : int
## pattern size
@export var pattern_size : Vector2i
## original tile set
@export var tile_set : TileSet

## find tile by hash
func find_tile(hash:int) -> WfcTile:
	for tile in wfc_tiles:
		if tile.hash == hash:
			return tile
	return null

#save layer config
static func save_layers(tile_map:TileMap, tile_set: WfcTileSet):
	tile_set.original_layers = []
	for i in tile_map.get_layers_count():
		var layer_data = {}
		layer_data["z"] = tile_map.get_layer_z_index(i)
		layer_data["name"] = tile_map.get_layer_name(i)
		layer_data["sort"] = tile_map.get_layer_y_sort_origin(i)
		layer_data["color"] = tile_map.get_layer_modulate(i)
		layer_data["render"] = true
		tile_set.original_layers.append(layer_data)

#load layer config into tilemap
static func load_layers(tile_map:TileMap, tile_set: WfcTileSet):
	assert(tile_set.original_layers, "no layer data provided")
	if tile_map.get_layers_count() > 3:
		print(tile_map)

	#clear all layers
	var start_index = tile_map.get_layers_count() - 1
	for i in tile_map.get_layers_count():
		tile_map.remove_layer(start_index - i)

	for i in tile_set.original_layers.size():
		tile_map.add_layer(i)
		tile_map.set_layer_name(i, tile_set.original_layers[i]["name"])
		tile_map.set_layer_z_index(i, tile_set.original_layers[i]["z"])
		tile_map.set_layer_y_sort_origin(i, tile_set.original_layers[i]["sort"])
		tile_map.set_layer_modulate(i, tile_set.original_layers[i]["color"])
