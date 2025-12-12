extends Node2D

@export var tilemap_script : Node2D
@export var tilemap_master : TileMapLayer
var camera_center_pos : Vector2

func CursorLocation():
	var block_pos = tilemap_script.BlockPosition()
	$Sprite2D.position = Vector2(block_pos.x, block_pos.y)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			#Place the block 
			var block_pos = tilemap_script.BlockPosition()
			if block_pos[0]!=null:
				tilemap_script.BlockAdd(block_pos[0])
	if event.is_action_released("rot_left"): #Rotate Left
		print("Rotate Left")
		tilemap_script.world_rot += 90
		tilemap_script.WorldRotate()

	elif event.is_action_released("rot_right"): #Rotate Right
		print("Rotate Right")
		tilemap_script.world_rot -= 90
		tilemap_script.WorldRotate()
		
