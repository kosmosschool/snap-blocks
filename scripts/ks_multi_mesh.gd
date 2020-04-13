extends MultiMeshInstance


class_name KSMultiMesh


var block_index : Dictionary


func add_block(block : BuildingBlockSnappable) -> void:
	# add block to MultiMeshInstance
	# save old transforms
	# increment visibility 
	var new_count = multimesh.visible_instance_count + 1
	multimesh.set_visible_instance_count(new_count)
	
	# update position of new instance
	multimesh.set_instance_transform(new_count - 1, block.get_global_transform())
	
	# add to index
	block_index[block] = block.get_global_transform()


func remove_block(block : BuildingBlockSnappable) -> void:
	# remove block from MultiMeshInstance
	# try erasing
	if !block_index.erase(block):
		return
	
	# if erased successfully, set instances again
	
	var new_count = multimesh.visible_instance_count - 1
	multimesh.set_visible_instance_count(new_count)
	
	set_instances()


func set_instances() -> void:
	var block_index_values = block_index.values()
	for i in range(block_index_values.size()):
		multimesh.set_instance_transform(i, block_index_values[i])
