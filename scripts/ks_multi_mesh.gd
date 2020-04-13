extends MultiMeshInstance


class_name KSMultiMesh


func add_block(block : BuildingBlockSnappable) -> void:
	# add block to MultiMeshInstance
	# save old transforms
	# increment visibility 
	var new_count = multimesh.visible_instance_count + 1
	multimesh.set_visible_instance_count(new_count)
	
	# update position of new instance
	multimesh.set_instance_transform(new_count - 1, block.global_transform)
