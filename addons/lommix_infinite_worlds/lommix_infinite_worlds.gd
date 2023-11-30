@tool
extends EditorPlugin

const tab_scene : PackedScene = preload("res://addons/lommix_infinite_worlds/scenes/wfc_slicer_tab.tscn")
const preset_editor_scene : PackedScene = preload("res://addons/lommix_infinite_worlds/scenes/wfc_preset_editor.tscn")

var wfc_tab : Control
var wfc_preset_editor : Control

func _enter_tree():
	# Initialization of the plugin goes here.
	add_autoload_singleton('wfc_map',"res://addons/lommix_infinite_worlds/singletons/wfc_map_container.gd")
	get_editor_interface().get_selection().connect("selection_changed", update_ui)
	wfc_tab = tab_scene.instantiate()
	wfc_preset_editor = preset_editor_scene.instantiate()
	add_control_to_bottom_panel(wfc_tab, "Wfc Slicer")
	#äget_editor_interface().get_viewport().call_deferred("add_child",wfc_preset_editor)
	get_editor_interface().get_editor_main_screen().call_deferred("add_child",wfc_preset_editor)
	_make_visible(false)

func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_autoload_singleton('wfc_map')
	get_editor_interface().get_selection().disconnect("selection_changed", update_ui)
	remove_control_from_bottom_panel(wfc_tab)
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU,wfc_preset_editor)
	if wfc_tab:
		wfc_tab.free()
	if wfc_preset_editor:
		wfc_preset_editor.free()

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if wfc_preset_editor:
		wfc_preset_editor.visible = visible

func update_ui():
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	if selection.size() == 0:
		return
	if selection[0] is TileMap:
		wfc_tab.inject_target_tilemap(selection[0])

func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcon")

func _get_plugin_name() -> String:
	return "Wfc Preset"
