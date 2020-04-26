extends Spatial


# logic for collection of all block areas of blocks added to MultiMesh
class_name AllBlockAreas

onready var block_area_script = load(global_vars.BLOCK_AREA_SCRIPT_PATH)
#onready var building_block_scene = preload("res://scenes/building_blocks/block_base_cube.tscn")

func add_block_area(col_shape : CollisionShape) -> Area:
	# duplicate collisionshape
#	var col_shape = block_collision_shape.duplicate()
	
	# create area
	var new_area = Area.new()
	add_child(new_area)
	new_area.global_transform = col_shape.get_global_transform()
	col_shape.get_parent().remove_child(col_shape)
	new_area.add_child(col_shape)
	new_area.monitoring = false
	new_area.set_script(block_area_script)
#	new_area.building_block_scene = building_block_scene
	new_area.set_collision_layer(2)
	new_area.collision_shape = col_shape
	
	# reset col shape's transform because it's now a child of the area which has its transform
	col_shape.transform = Transform()
	
	return new_area
	
