extends Node2D

var max_height = 5
var tile_width = 32
var tile_height = 16

var tileset = preload("res://Textures/tilesets/tileset.tres")
@export var tilemap_master : TileMapLayer
@export var tilemap_layers = {}

var world_data = {} #Vector3 [x,y,z]


func _ready():
	GenerateTileMapLayers()

func GenerateTileMapLayers():
	#Adding all the tilemaps to the tilemap group
	for z in range(max_height):
		var refmap = TileMapLayer.new()
		#setting the tilemap data
		refmap.name = str("TileMapLayer_" + str(z))
		refmap.tile_set = tileset
		refmap.y_sort_enabled = true
		#sorting the tilemaps above each other
		refmap.position.y = -z * (tile_height)
		refmap.z_index = z
		#add as child and to database
		add_child(refmap)
		tilemap_layers[z] = refmap

func _process(_delta: float):
	Blockface()





func point_in_triangle(p: Vector2, a: Vector2, b:Vector2, c:Vector2) -> bool:
	var w1 = ((c.x - a.x) * (p.y - a.y) - (c.y - a.y) * (p.x - a.x)) / \
			((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x))
	
	var w2 = ((b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)) / \
			((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x))
	
	return w1 >= 0.0 and w2 >= 0.0 and (w1 + w2) <= 1.0

func BlockPlacement():
	#Master Tilemap
	var tile_position = tilemap_master.local_to_map(get_local_mouse_position())
	var mouse_position = get_global_mouse_position()
	#Triangle Positions Left
	var AL : Vector2 = Vector2((tile_position.x * 16) + (tile_position.y * 16), 8 + (tile_position.y * 8) - (tile_position.x * 8)) #Checked
	var BL : Vector2 = Vector2(16 + (tile_position.x * 16) + (tile_position.y * 16), (tile_position.y * 8) - (tile_position.x * 8)) #Checked
	var CL : Vector2 = Vector2(16 + (tile_position.x * 16) + (tile_position.y * 16), 16 + (tile_position.y * 8) - (tile_position.x * 8)) #Checked
	#Determine Which Side of Tileface
	var side_triangle = point_in_triangle(mouse_position, AL, BL, CL) # True == Left : False == Right
	#Checks for which tilemap and Triangle being Determined
	for z in range(max_height - 1, -1, -1):
		#grab the base tilemap
		var target_tilemap = tilemap_layers[z]
		var target_pos = Vector2i(tile_position.x - z, tile_position.y + z)
		#Do the Position Checks
		if z == (max_height - 1) && target_tilemap.get_cell_source_id(target_pos)!=-1:
			print("Max Height Limit")
			return
		if z != (max_height - 1) && target_tilemap.get_cell_source_id(target_pos)!=-1: #Check tile Center
			BlockAdd(Vector3i(target_pos.x, target_pos.y, z+1))
			return
		elif side_triangle && target_tilemap.get_cell_source_id(Vector2i(target_pos.x, target_pos.y - 1))!=-1: #Check Left
			BlockAdd(Vector3i(target_pos.x, target_pos.y, z))
			return
		elif !side_triangle && target_tilemap.get_cell_source_id(Vector2i(target_pos.x + 1, target_pos.y))!=-1: #Check Right
			BlockAdd(Vector3i(target_pos.x, target_pos.y, z))
			return
		elif target_tilemap.get_cell_source_id(Vector2i(target_pos.x + 1, target_pos.y - 1))!=-1:
			if side_triangle: # Check left Back
				BlockAdd(Vector3i(target_pos.x, target_pos.y - 1, z))
				return
			elif !side_triangle: #Check Right Back
				BlockAdd(Vector3i(target_pos.x + 1, target_pos.y, z))
				return
		elif z==0 && target_tilemap.get_cell_source_id(target_pos)==-1:
			BlockAdd(Vector3i(target_pos.x, target_pos.y, z))
			return
		elif z==0:
			print("Error Placing Block")
			return

func BlockAdd(block_pos: Vector3i):
	tilemap_layers[block_pos.z].set_cell(Vector2i(block_pos.x, block_pos.y), 0, Vector2i(0,0))
	world_data[block_pos] = "block"
	print("block at : " + str(block_pos))

func Blockface():
	#Grid and Mouse position
	var tile_position = tilemap_master.local_to_map(get_local_mouse_position())
	var mouse_position = get_global_mouse_position()
	var target_tilemap = tilemap_master
	#Triangle Positions Left
	var AL : Vector2 = Vector2((tile_position.x * 16) + (tile_position.y * 16), 8 + (tile_position.y * 8) - (tile_position.x * 8)) #Checked
	var BL : Vector2 = Vector2(16 + (tile_position.x * 16) + (tile_position.y * 16), (tile_position.y * 8) - (tile_position.x * 8)) #Checked
	var CL : Vector2 = Vector2(16 + (tile_position.x * 16) + (tile_position.y * 16), 16 + (tile_position.y * 8) - (tile_position.x * 8)) #Checked
	#Determine Which Side of Tileface
	var side_triangle = point_in_triangle(mouse_position, AL, BL, CL) # True == Left : False == Right
	var side_tile = ""
	#Determing the Tilemap On Top
	#Side right and block left
	#Side left and block right
	#Elif block in pos (1,-1) according
	#AS LONG AS there isnt a block in tile pos
	
	#Determine Once Have Target Tilemap
	if side_triangle: #Left
		if target_tilemap.get_cell_source_id(tile_position)!=-1: 
			side_tile = "Center"
		elif target_tilemap.get_cell_source_id(Vector2(tile_position.x, tile_position.y - 1))!=-1: 
			side_tile = "Right"
		elif target_tilemap.get_cell_source_id(Vector2(tile_position.x + 1, tile_position.y - 1))!=-1: 
			side_tile = "Left"
		else: 
			side_tile = "None"
	elif !side_triangle: #Right
		if target_tilemap.get_cell_source_id(tile_position)!=-1: side_tile = "Center"
		elif target_tilemap.get_cell_source_id(Vector2(tile_position.x + 1, tile_position.y))!=-1: side_tile = "Left"
		elif target_tilemap.get_cell_source_id(Vector2(tile_position.x + 1, tile_position.y - 1))!=-1: side_tile = "Right"
		else: side_tile = "None"
	#Display
	$Label.text = str(tilemap_master.local_to_map(get_local_mouse_position()))
	$Label2.text = str(get_local_mouse_position())
	$Label3.text = side_tile
	
#####################################################################


func determine_blockface(mouse_pos : Vector2):
	var tile_pos = tilemap_master.local_to_map(mouse_pos)
	
	for z in range(max_height, 0, -1):
		z=z-1
		#setting the new tilemap and pos
		@warning_ignore("narrowing_conversion")
		var temp_pos = Vector2i(tile_pos.x - z, tile_pos.y + z)
		var temp_map = tilemap_layers[z]
		#Grabbing tile data
		var tile_data_center = temp_map.get_cell_source_id(temp_pos)
		var tile_data_right = temp_map.get_cell_source_id(Vector2i(temp_pos.x + 1, temp_pos.y))
		var tile_data_left = temp_map.get_cell_source_id(Vector2i(temp_pos.x, temp_pos.y - 1))
		print("Checking Pos : " + str(Vector3i(temp_pos.x,temp_pos.y,z)))

		if (tile_data_left!=-1) || (tile_data_right!=-1):
			temp_map.set_cell(temp_pos, 0, Vector2i(0,0))
			world_data[Vector3i(temp_pos.x,temp_pos.y,z)] = "block"
			print("block at : " + str(Vector3i(temp_pos.x,temp_pos.y,z)))
			return

		if z != (max_height - 1) && (tile_data_center!=-1): #Trys to place a block even if block above
			var temp_map_above = tilemap_layers[z + 1]
			temp_map_above.set_cell(Vector2i(temp_pos.x, temp_pos.y), 0 , Vector2i(0,0))
			world_data[Vector3i(temp_pos.x - 1,temp_pos.y + 1,z + 1)] = "block"
			print("block at : " + str(Vector3i(temp_pos.x - 1,temp_pos.y + 1,z + 1)))
			return

		if (z==0) && (tile_data_center==-1):
			temp_map.set_cell(temp_pos, 0, Vector2i(0,0))
			world_data[Vector3i(temp_pos.x,temp_pos.y,z)] = "block"
			print("block at : " + str(Vector3i(temp_pos.x,temp_pos.y,z)))
			return
			
			

		



func place_block_at_mouse(mouse_pos : Vector2):
	var tile_pos = tilemap_master.local_to_map(mouse_pos)
	determine_blockface(tile_pos)
	# Final Position = (-1, -1, 1)
	# Possible = (-1, -2, 0) (0, -2, 0)

	# Final Position = (-1, -1, 2)
	# possible = (0, -3, 0) (1, -3, 0)

	# Final position = (-1, -1, 3)
	# possible = (1, -4, 0) (2, -4, 0)

	####### wanted (-1, 0, 2) got (0, -1, 2) ## not flip but add 1 to each
	# Do for loop backwards with negative
	
	#check tiles left and right, and above Z
	#this way incase theres not one left or right, the tile position is the same as the next level check, so just check above
	#solves the two possible solution with one being infront


	# for z in range(max_height):
	# 	##check where block clicked is
	# 	var tilemap = tilemap_layers[z]
	# 	var tile_data = tilemap.get_cell_source_id(tile_pos)

	# 	if tile_data==-1:
	# 		tilemap.set_cell(tile_pos, 0, Vector2i(0,0))
	# 		world_data[Vector3i(tile_pos.x,tile_pos.y,z)] = "block"
	# 		print("block at : " + str(Vector3i(tile_pos.x,tile_pos.y,z)))
	# 		return


# func world_to_tile(world_pos: Vector2, tilemap_node: TileMapLayer) -> Vector2i:
# 	"""Convert global mouse position to tile grid coordinates (isometric)."""
# 	var local_pos = world_pos - tilemap_node.global_position
	
# 	var x = (local_pos.x / TILE_WIDTH + local_pos.y / TILE_HEIGHT) / 2.0
# 	var y = (local_pos.y / TILE_HEIGHT - local_pos.x / TILE_WIDTH) / 2.0
	
# 	return Vector2i(int(round(x)), int(round(y)))

# func tile_to_world(tile_coords: Vector2i, tilemap_node: TileMapLayer) -> Vector2:
# 	"""Convert tile grid coordinates back to world position (center)."""
# 	var x = (tile_coords.x - tile_coords.y) * TILE_WIDTH / 2.0
# 	var y = (tile_coords.x + tile_coords.y) * TILE_HEIGHT / 2.0
	
# 	return Vector2(x, y) + tilemap_node.global_position
