extends Area


# this is attached to Areas in AllBlockAreas
class_name BlockArea


onready var building_block_scene = load(global_vars.BASIC_BUILDING_BLOCK_PATH)
onready var all_building_blocks = get_node(global_vars.ALL_BUILDING_BLOCKS_PATH)
onready var controller_grab = get_node(global_vars.CONTR_RIGHT_PATH + "/controller_grab")


func remove_from_multi_mesh() -> void:
	# removes this "Block" from MultiMesh
	# instance new building block at this position
	var new_bb = building_block_scene.instance()
	all_building_blocks.add_child(new_bb)
	
	# position
	new_bb.global_transform = global_transform

	# grab
	controller_grab.start_grab_hinge_joint(new_bb)
	
	# free this area
	queue_free()
