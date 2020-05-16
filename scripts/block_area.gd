extends Area


# this is attached to Areas in AllBlockAreas
class_name BlockArea

var collision_shape
var building_block_scene
var mm_indices : Array

var all_building_blocks
var multi_mesh
var all_block_areas
var color_name : String setget set_color_name, get_color_name


func set_color_name(new_value):
	color_name = new_value


func get_color_name():
	return color_name


# we don't use _ready because this script is set from another script and _ready is not called
func _init():
	building_block_scene = preload("res://scenes/building_blocks/block_base_cube.tscn")
	all_building_blocks = get_node(global_vars.ALL_BUILDING_BLOCKS_PATH)
	all_block_areas = get_node(global_vars.ALL_BLOCK_AREAS_PATH)
	multi_mesh = get_node(global_vars.MULTI_MESH_PATH)


func remove_from_multi_mesh(controller_grab) -> void:
	# removes this "Block" from MultiMesh
	# instance new building block at this position
	var new_bb = building_block_scene.instance()
	all_building_blocks.add_child(new_bb)
	
	# set material
	new_bb.set_color(color_name)
	
	# position
	new_bb.global_transform = global_transform

	# grab
	controller_grab.start_grab_hinge_joint(new_bb)
	
	all_block_areas.remove_origin(global_transform.origin)
	multi_mesh.remove_area(self)
	
	# free this area
	queue_free()


func delete_from_multi_mesh() -> void:
	all_block_areas.remove_origin(global_transform.origin)
	multi_mesh.remove_area(self)
	
	# free this area
	queue_free()


func recolor() -> void:
	# changes color to currently selected color
	var controller_colors := get_node(global_vars.CONTR_RIGHT_PATH + "/KSControllerRight/ControllerColors")
	color_name = controller_colors.get_current_color_name()
	multi_mesh.recolor_area(self)


func clear_mm_indices() -> void:
	# pretty self-explanatory, isn't it?
	mm_indices.clear()


func append_mm_index(new_index : int) -> void:
	# keeps track of which indices on multi mesh are currently assigned to this one
	# e.g., useful for recoloring
	mm_indices.append(new_index)


func calc_snap_vec(intersection_point : Vector3, normal : Vector3) -> Vector3:
	# calculates snap vector based on intersection point and normal
	# this is vector goes from the block's origin through the mid-point of the area where the intersection
	# point lies
	# returned snap vec is normalized
	var col_shape_extents = collision_shape.shape.extents
	
#	var return_vec = intersection_point + ( -1 * normal * col_shape_extents / 2 - global_transform.origin)
	var return_vec = global_transform.origin + normal
	
	return return_vec.normalized()


func serialize_for_save() -> Dictionary:
	
	var save_dict = {
		"global_transform_serialized": transform_to_array(global_transform),
		"color_name": color_name
	}
	
	return save_dict


func transform_to_array(input_trans : Transform) -> Array:
	return [
		input_trans.basis.x.x,
		input_trans.basis.x.y,
		input_trans.basis.x.z,
		input_trans.basis.y.x,
		input_trans.basis.y.y,
		input_trans.basis.y.z,
		input_trans.basis.z.x,
		input_trans.basis.z.y,
		input_trans.basis.z.z,
		input_trans.origin.x,
		input_trans.origin.y,
		input_trans.origin.z
	]
	
