extends BuildingBlock


class_name GhostBlock


#var instantiating := false
#var prev_overlapping_size := 0
#
#onready var area := $Area
#onready var all_building_blocks = get_node(global_vars.ALL_BUILDING_BLOCKS_PATH)
#onready var controller_grab = get_node(global_vars.CONTR_RIGHT_PATH + "/controller_grab") 

#export(PackedScene) var block_scene

#
#func _process(delta):
#	if not instantiating and prev_overlapping_size > 0 and block_scene and area.get_overlapping_bodies().size() == 0:
#		instantiating = true
#		var new_block = block_scene.instance()
#		all_building_blocks.add_child(new_block)
#		new_block.global_transform = global_transform
#		controller_grab.start_grab_hinge_joint(new_block)
#		queue_free()
#
#	prev_overlapping_size = area.get_overlapping_bodies().size()
