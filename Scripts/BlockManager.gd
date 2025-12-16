extends Node2D

@export var resource_json : JSON
var resource_pack : Dictionary = {}

var max_height = 5
var tile_width : int
var tile_height : int
@onready var HALF_H : int
@onready var HALF_W : int
@export var tile_center = Vector2i(0,0)




var tileset = preload("res://Textures/tilesets/tileset.tres")
@export var tilemap_master : TileMapLayer
@export var tilemap_layers = {}

var world_data = {} #Vector3 [x,y,z]
var world_rot = 0;
class Block:
	var type
	var id
	var connects
	var neighbors #holds number based on NSEW  -> N = 1 E = 2 S = 4 W = 8
	func _init( _id:= 0, _type :="", _connects := false, _neighbors := 0): 
		type = _type
		id = _id
		connects = _connects
		if connects:
			neighbors = _neighbors

#Everything On Game Load
func _ready():
	#Setting up resource pack
	resource_pack = resource_json.data
	#setting tile dimensions
	tile_width = resource_pack["data"].tile_width
	tile_height = resource_pack["data"].tile_height
	HALF_H = tile_height / 2
	HALF_W = tile_width / 2

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
	BlockCursor() #Determines the Cursor


func point_in_triangle(p: Vector2, a: Vector2, b:Vector2, c:Vector2) -> bool:
	var w1 = ((c.x - a.x) * (p.y - a.y) - (c.y - a.y) * (p.x - a.x)) / \
			((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x))
	
	var w2 = ((b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)) / \
			((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x))
	
	return w1 >= 0.0 and w2 >= 0.0 and (w1 + w2) <= 1.0

func point_in_rotation(tile_pos : Vector3i, rot : float) -> Vector3i:
	var relative_pos = Vector2(tile_pos.x - tile_center.x, tile_pos.y - tile_center.y)

	var newX = round((relative_pos.x*cos(rot)) - (relative_pos.y*sin(rot)))
	var newY = round((relative_pos.x*sin(rot)) + (relative_pos.y*cos(rot)))

	
	return Vector3i(newX + tile_center.x,newY + tile_center.y, tile_pos.z)

func BlockPosition(): #Determings Block Face and New block position accordingly (BASED ON TILEMAP)
	#Master Tilemap
	var tile_position = tilemap_master.local_to_map(get_local_mouse_position())
	var mouse_position = get_global_mouse_position()
	#Triangle Positions Left
	var AL : Vector2 = Vector2((tile_position.x * HALF_W) + (tile_position.y * HALF_W), HALF_H + (tile_position.y * HALF_H) - (tile_position.x * HALF_H)) #Checked
	var BL : Vector2 = Vector2(HALF_W + (tile_position.x * HALF_W) + (tile_position.y * HALF_W), (tile_position.y * HALF_H) - (tile_position.x * HALF_H)) #Checked
	var CL : Vector2 = Vector2(HALF_W + (tile_position.x * HALF_W) + (tile_position.y * HALF_W), HALF_W + (tile_position.y * HALF_H) - (tile_position.x * HALF_H)) #Checked
	#Determine Which Side of Tileface
	var side_triangle = point_in_triangle(mouse_position, AL, BL, CL) # True == Left : False == Right
	#$Label.text = str(side_triangle)
	#Checks for which tilemap and Triangle being Determined
	for z in range(max_height - 1, -1, -1):
		#grab the base tilemap
		var target_tilemap = tilemap_layers[z]
		var target_pos = Vector2i(tile_position.x - z, tile_position.y + z)
		#Do the Position Checks
		# if z == (max_height - 1) && target_tilemap.get_cell_source_id(target_pos)!=-1:
		# 	print("Max Height Limit")
		# 	return [null, "NULL"]
		#elif z != (max_height - 1) && target_tilemap.get_cell_source_id(target_pos)!=-1: #Check tile Center
		# 	return [Vector3i(target_pos.x, target_pos.y, z+1), "CENTER"]
		if z != (max_height - 1) and target_tilemap.get_cell_source_id(Vector2i(target_pos.x - 1, target_pos.y + 1))!=-1:
			return [Vector3i(target_pos.x - 1, target_pos.y + 1, z + 1), "CENTER"]
		elif side_triangle && target_tilemap.get_cell_source_id(Vector2i(target_pos.x - 1, target_pos.y))!=-1: #Check Left
			return [Vector3i(target_pos.x - 1, target_pos.y + 1, z), "RIGHT"]
		elif !side_triangle && target_tilemap.get_cell_source_id(Vector2i(target_pos.x, target_pos.y + 1))!=-1: #Check Right
			return [Vector3i(target_pos.x - 1, target_pos.y + 1, z), "LEFT"]
		elif target_tilemap.get_cell_source_id(Vector2i(target_pos.x, target_pos.y))!=-1:
			if side_triangle:
				return [Vector3i(target_pos.x - 1, target_pos.y, z), "LEFT"]
			if !side_triangle:
				return [Vector3i(target_pos.x, target_pos.y + 1, z), "RIGHT"]
		#Just for layer One and No Tilemaps yet
		elif z==0 && target_tilemap.get_cell_source_id(target_pos)==-1:
			return [Vector3i(target_pos.x, target_pos.y, z), "CENTER"]
		elif z==0:
			print("Error Placing Block")
			return [null, "NULL"]

func BlockLookingPosition(block_pos: Vector3i, block_side : String): #Determines Block Looking At
	#Determine Target Block Position
	var target_pos : Vector3i 
	if(block_side=="CENTER" && block_pos.z!=0):
		target_pos = Vector3i(block_pos.x,block_pos.y,block_pos.z - 1)
	elif(block_side=="RIGHT"):
		target_pos = Vector3i(block_pos.x,block_pos.y - 1,block_pos.z)
	elif(block_side=="LEFT"):
		target_pos = Vector3i(block_pos.x + 1,block_pos.y,block_pos.z)
	else: 
		return null
	return target_pos; #Block Looking At

func BlockAdd(block_pos: Vector3i, block_id : int): #Adds block

	#Getting the Block Data
	var block = Block.new(block_id, resource_pack[str(block_id)].type, resource_pack[str(block_id)].connects)
	#Setting the Tile Position
	tilemap_layers[block_pos.z].set_cell(Vector2i(block_pos.x, block_pos.y), block_id, Vector2i(0,0))
	#Setting the Proper World Pos
	var rads = deg_to_rad(-world_rot)
	var rotated_block_pos = point_in_rotation(block_pos, rads)
	#setting the world data
	world_data[rotated_block_pos] = block
	#Checking connecting based on world pos
	if block.connects:
		world_data[rotated_block_pos].neighbors = BlockConnect(rotated_block_pos, true)
		BlockUpdate(rotated_block_pos) #input non rotated ( rotated here is the actual position)
	print("✅✅✅ block at : " + str(rotated_block_pos) + " | Rotated Pos : " + str(block_pos) + " | Rotation : " + str(world_rot))

func BlockUpdate(block_pos: Vector3i):
	#block pos is ACTUAL BLOCK POS

	#adjust for rotation
	var rads = deg_to_rad(world_rot)
	var rotated_block_pos = point_in_rotation(block_pos, rads)
	#Grabbing the block Data
	var data = world_data[block_pos] 
	var atlas = Vector2i(0,0)
	#gonna have to determinee new connect atlas
	if data.connects: 
		#rotation amount
		var steps = round(world_rot / 90)
		steps = (steps % 4 + 4) % 4 #normalize between 0 & 3
		#Rotate until new mask
		var mask = data.neighbors
		for i in steps:
			var n_bit = mask & 1     # 0001
			var e_bit = mask & 2     # 0010
			var s_bit = mask & 4     # 0100
			var w_bit = mask & 8     # 1000

			# Clockwise: newN = oldW, newE = oldN, newS = oldE, newW = oldS
			mask = 0
			if w_bit: mask |= 1      # new N
			if n_bit: mask |= 2      # new E
			if e_bit: mask |= 4      # new S
			if s_bit: mask |= 8      # new W
		#Sets atlas based on new mask
		atlas = Vector2i(mask, 0)
	print("Updated Position : " + str(rotated_block_pos))
	tilemap_layers[block_pos.z].set_cell(Vector2i(rotated_block_pos.x, rotated_block_pos.y), data.id, atlas)
	
func BlockRemove(target_pos: Vector3i): #Removes Block
	#Target_pos is looking at block pos NOT ROTATED
	var rads = deg_to_rad(-world_rot)
	var rotated_block_pos = point_in_rotation(target_pos, rads)
	#Checks Connecting
	if world_data[rotated_block_pos].connects: 
		BlockConnect(rotated_block_pos, false)
	#Removes the tile
	tilemap_layers[target_pos.z].set_cell(Vector2i(target_pos.x, target_pos.y), -1)
	world_data.erase(rotated_block_pos)
	print("❌❌❌ block at : " + str(rotated_block_pos) + " | Rotated Pos : " + str(target_pos) + " | Rotation : " + str(world_rot))

func BlockConnect(block_pos : Vector3i, add_block : bool):
	#inputed position is PROPERLY ROTATED
	var neighbors : int = 0
	#Checking the neighbors
	var north_pos = Vector3i(block_pos.x, block_pos.y - 1, block_pos.z)
	#Check North
	if(world_data.has(north_pos)):
		#Add Block
		if world_data[north_pos].connects and add_block:
			neighbors += 1
			world_data[north_pos].neighbors += 4
		#Remove Block
		elif world_data[north_pos].connects and !add_block:
			world_data[north_pos].neighbors -= 4
		BlockUpdate(north_pos)
	var east_pos = Vector3i(block_pos.x + 1, block_pos.y, block_pos.z)
	#Check East
	if(world_data.has(east_pos)):
		#Add Block
		if world_data[east_pos].connects and add_block:
			neighbors += 2
			world_data[east_pos].neighbors += 8
		#Remove Block
		elif world_data[east_pos].connects and !add_block:
			world_data[east_pos].neighbors -= 8
		BlockUpdate(east_pos)
	var south_pos = Vector3i(block_pos.x, block_pos.y + 1, block_pos.z)
	#Check South
	if(world_data.has(south_pos)): 
		#Add Block
		if world_data[south_pos].connects and add_block:
			neighbors += 4
			world_data[south_pos].neighbors += 1
		#Remove Block
		if world_data[south_pos].connects and !add_block:
			world_data[south_pos].neighbors -= 1
		BlockUpdate(south_pos)
	var west_pos = Vector3i(block_pos.x - 1, block_pos.y, block_pos.z)
	#Check West
	if(world_data.has(west_pos)):
		#Add block
		if world_data[west_pos].connects and add_block:
			neighbors += 8
			world_data[west_pos].neighbors += 2
		#Remove Block
		if world_data[west_pos].connects and !add_block:
			world_data[west_pos].neighbors -= 2
		BlockUpdate(west_pos)
			
	return neighbors

func BlockCursor():
	#Variables
	var data = BlockPosition()
	var block_pos = data[0]
	var block_side = data[1]
	var looking_pos = BlockLookingPosition(data[0], data[1])
	#Exceptions
	if block_pos==null: return
	if block_pos.z==0 && block_side=="CENTER": pass

	#Updates the Tile Position
	var tile_pos = Vector2i(block_pos.x + (1 * block_pos.z), block_pos.y - (1 * block_pos.z))
	tilemap_master.clear()
	tilemap_master.z_index = block_pos.z + 1
	tilemap_master.set_cell(Vector2i(tile_pos), 0, Vector2i(0,0))

	#Testing
	#$Label.text = block_side
	#$Label2.text = str(block_pos)
	#$Label3.text = str(world_rot)
	$UI/Label.text = "Cursor Position : " + str(block_pos)
	$UI/Label2.text = "Looking Position : " + str(looking_pos)
	$UI/Label4.text = "Block Side : " + str(block_side)
	$UI/Label3.text = "World Rotation : " + str(world_rot)


func WorldRotate():
	
	for z in tilemap_layers: #clears all the tilemaps
		tilemap_layers[z].clear()
	for block_pos in world_data:
		# var rads = deg_to_rad(world_rot)
		# var tile_rot = point_in_rotation(block_pos, rads)
		# tilemap_layers[block_pos.z].set_cell(Vector2i(tile_rot.x, tile_rot.y), 5, Vector2i(0,0))
		BlockUpdate(block_pos)
		#print("block at : " + str(block_pos) + " | Rotated Pos : " + str(tile_rot) + " | Rotation : " + str(world_rot))
