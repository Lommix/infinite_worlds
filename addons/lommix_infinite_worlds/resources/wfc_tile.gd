class_name WfcTile
extends Resource

## socket pattern
@export var pattern: TileMapPattern
## visual layers
@export var additional_layers : Array [TileMapPattern] = []
@export var additional_layers_name : Array[String] = []
## has of all layers
@export var hash : int
@export var width : int
@export var weight: float = 100
@export var name: String
@export var group: String

@export var sockets := {
	Vector2i.UP: 0,
	Vector2i.RIGHT: 0,
	Vector2i.DOWN: 0,
	Vector2i.LEFT: 0,
}
@export var allowed_neighbors := {
	Vector2i.UP: [],
	Vector2i.RIGHT: [],
	Vector2i.DOWN: [],
	Vector2i.LEFT: [],
}

func from_pattern(tilemap_pattern: TileMapPattern):
	pattern = tilemap_pattern
	width = pattern.get_size().x
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
	hash = tiles.hash()
