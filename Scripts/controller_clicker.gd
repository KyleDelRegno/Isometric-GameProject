extends Node2D

@export var tilemap_script : Node2D
@export var tilemap_master : TileMapLayer

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			var mouse_pos = get_global_mouse_position()
			mouse_pos = to_local(mouse_pos)
			tilemap_script.BlockPlacement()
