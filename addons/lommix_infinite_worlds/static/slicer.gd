class_name Slicer
extends Node

#offset list in clockwise order for propation
const prop_map := [
	#first ring
	[Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)],
	#second ring
	[Vector2i(0,-2), Vector2i(1,-1), Vector2i(2,0), Vector2i(1,1), Vector2i(0,2), Vector2i(-1,1), Vector2i(-2,0), Vector2i(-1,-1)],
	#third ring
	[Vector2i(0,-3),Vector2i(1,-2),Vector2i(2,-1),Vector2i(3,0),Vector2i(2,1),Vector2i(1,2),Vector2i(0,3),
	Vector2i(-1,2),Vector2i(-2,1),Vector2i(-3,0),Vector2i(-2,-1),Vector2i(-1,-2)],
	#fourth ring
	[Vector2i(0,-4),Vector2i(1,-3),Vector2i(2,-2),Vector2i(3,-1),Vector2i(4,0),
	Vector2i(4,0),Vector2i(3,1),Vector2i(2,2),Vector2i(1,3),Vector2i(0,4),
	Vector2i(0,4),Vector2i(-1,3),Vector2i(-2,2),Vector2i(-3,1),Vector2i(-4,0),
	Vector2i(-4,0),Vector2i(-3,-1),Vector2i(-2,-2),Vector2i(-1,-3)]
]
const dir_sequence := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

#starting point, slice the map, return the wfc tile set
static func slice(tilemap: TileMap, pattern_size:Vector2i, size: Vector2i) -> WfcTileSet:
	var unique_tiles := {}
	var connection_map := {}
	#var truesize = pattern_size * size
	for x in size.x:
		for y in size.y:
			var tile_position = Vector2i(x * pattern_size.x, y * pattern_size.y)
			var tile = read_tile(tilemap, pattern_size, tile_position)
			if !tile:
				continue
			var layer_tuple = find_additional_layers(tilemap,pattern_size,tile_position)
			if layer_tuple[0].size() > 0:
				tile.additional_layers = layer_tuple[0]
				#adding hashes to generate a new unique one, might cause bugs at some point
				tile.hash += layer_tuple[1]
				tile.additional_layers_name = layer_tuple[2]
				
			connection_map[Vector2i(x,y)] = tile.hash
			if unique_tiles.has(tile.hash):
				unique_tiles[tile.hash].weight += 1
			else:
				unique_tiles[tile.hash] = tile

	#generate allowed neighbors
	collect_neighbor_data(connection_map, unique_tiles)
	#cast to resource
	var wfc_tile_set = WfcTileSet.new()
	for tile in unique_tiles.values():
		wfc_tile_set.wfc_tiles.append(tile)
	WfcTileSet.save_layers(tilemap,wfc_tile_set)
	wfc_tile_set.pattern_size = pattern_size
	wfc_tile_set.tile_set = tilemap.tile_set
	wfc_tile_set.quad_size = tilemap.tile_set.tile_size.x
	return wfc_tile_set

# adding additional layers and generate combined hash
# returns tuple [Array[TileMapPattern], hash:int]
static func find_additional_layers(tilemap: TileMap, pattern_size:Vector2i, position: Vector2i) -> Array:
	var layers: Array[TileMapPattern] = []
	var names : Array[String] = []
	var hash_list : Array[int] = []
	for i in tilemap.get_layers_count():
		if i == 0: continue
		var pattern := TileMapPattern.new()
		var is_valid = false
		var tile_sequence : Array[Vector2i] = []
		for x in pattern_size.x:
			for y in pattern_size.y:
				var cell_pos =  Vector2i(x,y)
				var atlas_pos := tilemap.get_cell_atlas_coords(i,position + cell_pos)
				var source := tilemap.get_cell_source_id(i,position + cell_pos)
				var alternative := tilemap.get_cell_alternative_tile(i,position + cell_pos)
				if(atlas_pos != Vector2i(-1,-1)):
					pattern.set_cell(cell_pos, source, atlas_pos, alternative)
					is_valid = true
		if is_valid: 
			layers.append(pattern)
			names.append(tilemap.get_layer_name(i))
			hash_list.append(generate_hash_from_pattern(pattern))
	return [layers, hash_list.hash(), names]


#generating a hash from a tilemap pattern sequence
static func generate_hash_from_pattern(pattern: TileMapPattern) -> int :
	return pattern.get_used_cells().map(func(vec:Vector2): return pattern.get_cell_atlas_coords(vec)).hash()

#collection neighbor data for bitmap mode
#todo: wrap around, missing for completion.
static func collect_neighbor_data(connection_map: Dictionary, unique_tiles : Dictionary):
	for pos in connection_map:
		for dir in dir_sequence:
			if connection_map.has(pos + dir):
				if !unique_tiles[connection_map[pos]].allowed_neighbors[dir].has(connection_map[pos + dir]):
					unique_tiles[connection_map[pos]].allowed_neighbors[dir].append(connection_map[pos + dir])
	
#read a single tile from a griven tilemap and return the wfc tile resource
#can return null, if tile has empty cell
static func read_tile(tilemap: TileMap, pattern_size:Vector2i, position: Vector2i) -> WfcTile:
	var pattern := TileMapPattern.new()
	for x in pattern_size.x:
		for y in pattern_size.y:
			var cell_pos =  Vector2i(x,y)
			var atlas_pos := tilemap.get_cell_atlas_coords(0,position + cell_pos)
			var source := tilemap.get_cell_source_id(0,position + cell_pos)
			var alternative := tilemap.get_cell_alternative_tile(0,position + cell_pos)
			if atlas_pos == Vector2i(-1,-1):
				return null
			pattern.set_cell(cell_pos, source, atlas_pos, alternative)
	#read sockets
	var wfc_tile := WfcTile.new()
	wfc_tile.pattern = pattern
	var values = read_sockets(pattern)
	wfc_tile.hash = values["hash"]
	wfc_tile.sockets = values["sockets"]
	return wfc_tile

#generate socket hashes for each side of a tile map pattern
static func read_sockets(pattern:TileMapPattern)->Dictionary:
	var sockets := {}
	var width = pattern.get_size().y
	print(pattern.get_size())
	var used = pattern.get_used_cells()
	var tiles = pattern.get_used_cells().map(func(vec:Vector2): return pattern.get_cell_atlas_coords(vec))
	var up = tiles.slice(0, tiles.size() - (width -1), width)
	var down = tiles.slice(width-1, tiles.size(), width)
	var left = tiles.slice(0, width)
	var right = tiles.slice(tiles.size() - width, tiles.size())
	sockets[Vector2i.UP] = up.hash()
	sockets[Vector2i.DOWN] = down.hash()
	sockets[Vector2i.LEFT] = left.hash()
	sockets[Vector2i.RIGHT] = right.hash()
	return {"sockets": sockets, "hash": tiles.hash()}
