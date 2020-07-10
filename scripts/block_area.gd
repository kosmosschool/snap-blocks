extends Area


# this is attached to Areas in AllBlockAreas
class_name BlockArea

var building_block_scene
var mm_indices : Array

var all_building_blocks
var block_chunks_controller
#var multi_mesh
#var all_block_areas
var color_name : String setget set_color_name, get_color_name


func set_color_name(new_value):
	color_name = new_value


func get_color_name():
	return color_name


# we don't use _ready because this script is set from another script and _ready is not called
func _init():
	building_block_scene = preload("res://scenes/building_blocks/block_base_cube.tscn")
	all_building_blocks = get_node(global_vars.ALL_BUILDING_BLOCKS_PATH)
	block_chunks_controller = get_node(global_vars.BLOCK_CHUNKS_CONTROLLER_PATH)
#	all_block_areas = get_node(global_vars.ALL_BLOCK_AREAS_PATH)
#	multi_mesh = get_node(global_vars.MULTI_MESH_PATH)


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
	
	block_chunks_controller.remove_block(self)


func delete_from_multi_mesh() -> void:
	block_chunks_controller.remove_block(self)


func recolor(controller_side_string : String) -> void:
	# changes color to currently selected color
	color_name = color_system.get_current_color_name(controller_side_string)
#	multi_mesh.recolor_area(self)
	block_chunks_controller.recolor_block(self)


func clear_mm_indices() -> void:
	# pretty self-explanatory, isn't it?
	mm_indices.clear()


func append_mm_index(new_index : int) -> void:
	# keeps track of which indices on multi mesh are currently assigned to this one
	# e.g., useful for recoloring
	mm_indices.append(new_index)


func serialize_for_save() -> Dictionary:
	
	var save_dict = {
		"global_transform_serialized": global_functions.transform_to_array(global_transform),
		"color_name": color_name
	}
	
	return save_dict



