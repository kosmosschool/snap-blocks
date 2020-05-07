extends Area


# this is attached to Areas in AllBlockAreas
class_name BlockArea

var collision_shape
var building_block_scene

var all_building_blocks
var multi_mesh
var block_material : Material setget set_block_material
var block_material_secondary : Material setget set_block_material_secondary


func set_block_material(new_value):
	block_material = new_value


func set_block_material_secondary(new_value):
	block_material_secondary = new_value


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
	
	# set material
	new_bb.set_material(block_material)
	new_bb.set_secondary_material(block_material_secondary)
	
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


func serialize_for_save() -> Dictionary:
	
	var save_dict = {
		"global_transform_serialized": transform_to_array(global_transform),
		"material_name": block_material.resource_path.split("/")[-1].split(".")[0]
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
	
