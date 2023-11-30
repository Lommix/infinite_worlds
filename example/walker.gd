extends Node2D


## This is a demo walker. This Node acts as a center for the infinite generated wave function collapse Tilemap


@export var speed : float = 500.
@onready var camera : Camera2D = $Camera2D


func _physics_process(delta: float) -> void:
	var direction := Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	global_position += direction * speed * delta


func _input(event: InputEvent) -> void:
	if event.is_action("zoom_in"):
		camera.zoom *= 1.1
	if event.is_action("zoom_out"):
		camera.zoom *= 0.9
