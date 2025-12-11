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
	BlockFace()





func point_in_triangle(p: Vector2, a: Vector2, b:Vector2, c:Vector2) -> bool:
	var w1 = ((c.x - a.x) * (p.y - a.y) - (c.y - a.y) * (p.x - a.x)) / \
			((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x))
	
	var w2 = ((b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)) / \
			((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x))
	
	return w1 >= 0.0 and w2 >= 0.0 and (w1 + w2) <= 1.0

func BlockPosition():
	#Master Tilemap
	var tile_position = tilemap_master.local_to_map(get_local_mouse_position())
	var mouse_position = get_global_mouse_position()
	#Triangle Positions Left
	var AL : Vector2 = Vector2((tile_position.x * 16) + (tile_position.y * 16), 8 + (tile_position.y * 8) - (tile_position.x * 8)) #Checked
	var BL : Vector2 = Vector2(16 + (tile_position.x * 16) + (tile_position.y * 16), (tile_position.y * 8) - (tile_position.x * 8)) #Checked
	var CL : Vector2 = Vector2(16 + (tile_position.x * 16) + (tile_position.y * 16), 16 + (tile_position.y * 8) - (tile_position.x * 8)) #Checked
	#Determine Which Side of Tileface
	var side_triangle = point_in_triangle(mouse_position, AL, BL, CL) # True == Left : False == Right
	$Label.text = str(side_triangle)
	#Checks for which tilemap and Triangle being Determined
	for z in range(max_height - 1, -1, -1):
		#grab the base tilemap
		var target_tilemap = tilemap_layers[z]
		var target_pos = Vector2i(tile_position.x - z, tile_position.y + z)
		#Do the Position Checks
		if z == (max_height - 1) && target_tilemap.get_cell_source_id(target_pos)!=-1:
			print("Max Height Limit")
			return [null, "NULL"]
		#elif z != (max_height - 1) && target_tilemap.get_cell_source_id(target_pos)!=-1: #Check tile Center
		# 	return [Vector3i(target_pos.x, target_pos.y, z+1), "CENTER"]
		elif target_tilemap.get_cell_source_id(Vector2i(target_pos.x - 1, target_pos.y + 1))!=-1:
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

func BlockAdd(block_pos: Vector3i):
	tilemap_layers[block_pos.z].set_cell(Vector2i(block_pos.x, block_pos.y), 1, Vector2i(0,0))
	world_data[block_pos] = "block"
	print("block at : " + str(block_pos))


func BlockFace():
	#Variables
	var data = BlockPosition()
	var block_pos = data[0]
	var block_side = data[1]
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
	$Label2.text = str(block_pos)
	$Label3.text = str(get_global_mouse_position())
