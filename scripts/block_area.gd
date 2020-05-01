extends Area


# this is attached to Areas in AllBlockAreas
class_name BlockArea

var collision_shape
var building_block_scene

var all_building_blocks
var multi_mesh

# we don't use _ready because this script is set from another script and _ready is not called

func _init():
	building_block_scene = preload("res://scenes/building_blocks/block_base_cube.tscn")
	all_building_blocks = get_node(global_vars.ALL_BUILDING_BLOCKS_PATH)
	multi_mesh = get_node(global_vars.MULTI_MESH_PATH)


func remove_from_multi_mesh(controller_grab) -> void:
	# removes this "Block" from MultiMesh
	# instance new building block at this position
	var new_bb = building_block_scene.instance()
	all_building_blocks.add_child(new_bb)
	
	# position
	new_bb.global_transform = global_transform

	# grab
	controller_grab.start_grab_hinge_joint(new_bb)
	
	multi_mesh.remove_area(self)
	
	# free this area
	queue_free()


func calc_snap_vec(intersection_point : Vector3, normal : Vector3) -> Vector3:
	# calculates snap vector based on intersection point and normal
	# this is vector goes from the block's origin through the mid-point of the area where the intersection
	# point lies
	# returned snap vec is normalized
	var col_shape_extents = collision_shape.shape.extents
	
#	var return_vec = intersection_point + ( -1 * normal * col_shape_extents / 2 - global_transform.origin)
	var return_vec =  global_transform.origin + normal
	
	return return_vec.normalized()
