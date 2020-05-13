extends MultiMeshInstance


class_name KSMultiMesh

var all_origins : Array

onready var controller_colors := get_node(global_vars.CONTR_RIGHT_PATH + "/KSControllerRight/ControllerColors")
onready var all_block_areas := get_node(global_vars.ALL_BLOCK_AREAS_PATH)


func add_area(area : Area) -> void:
	# add block to MultiMeshInstance
	
	# update position of new instance
	var area_color = controller_colors.get_color_by_name(area.get_color_name())
	var new_color = Color(area_color.x, area_color.y, area_color.z, 1.0)
	
	# we need to add 6 sides for the cube
	var area_global_trans = area.get_global_transform()
	var area_local_trans = area.get_transform()
	
	var half_length = area.get_node("CollisionShape").shape.get_extents().x
	
	var side_transforms : Array
	
	# only add cube side to mesh if there's no neighbor
	var s_1_neighbor_orig = area_global_trans.origin + area_local_trans.basis.z * half_length * 2
	var s_2_neighbor_orig = area_global_trans.origin - area_local_trans.basis.z * half_length * 2
	var s_3_neighbor_orig = area_global_trans.origin + area_local_trans.basis.y * half_length * 2
	var s_4_neighbor_orig = area_global_trans.origin - area_local_trans.basis.y * half_length * 2
	var s_5_neighbor_orig = area_global_trans.origin + area_local_trans.basis.x * half_length * 2
	var s_6_neighbor_orig = area_global_trans.origin - area_local_trans.basis.x * half_length * 2
	
	
	if not all_block_areas.block_exists(s_1_neighbor_orig):
		var trans_1 = area_global_trans
		trans_1.origin += area_local_trans.basis.z * half_length
		side_transforms.append(trans_1)
	
	if not all_block_areas.block_exists(s_2_neighbor_orig):
		var trans_2 = area_global_trans
		trans_2.origin -= area_local_trans.basis.z * half_length
		trans_2.basis = trans_2.basis.rotated(trans_2.basis.y, PI)
		side_transforms.append(trans_2)
	
	if not all_block_areas.block_exists(s_3_neighbor_orig):
		var trans_3 = area_global_trans
		trans_3.origin += area_local_trans.basis.y * half_length
		trans_3.basis = trans_3.basis.rotated(trans_3.basis.x, - PI / 2)
		side_transforms.append(trans_3)
	
	if not all_block_areas.block_exists(s_4_neighbor_orig):
		var trans_4 = area_global_trans
		trans_4.origin -= area_local_trans.basis.y * half_length
		trans_4.basis = trans_4.basis.rotated(trans_4.basis.x, PI / 2)
		side_transforms.append(trans_4)
	
	if not all_block_areas.block_exists(s_5_neighbor_orig):
		var trans_5 = area_global_trans
		trans_5.origin += area_local_trans.basis.x * half_length
		trans_5.basis = trans_5.basis.rotated(trans_5.basis.y, PI / 2)
		side_transforms.append(trans_5)
	
	if not all_block_areas.block_exists(s_6_neighbor_orig):
		var trans_6 = area_global_trans
		trans_6.origin -= area_local_trans.basis.x * half_length
		trans_6.basis = trans_6.basis.rotated(trans_6.basis.y, - PI / 2)
		side_transforms.append(trans_6)
	
	# increment visibility 
	var new_count = multimesh.visible_instance_count + side_transforms.size()
	multimesh.set_visible_instance_count(new_count)
	
	for i in range(side_transforms.size()):
		multimesh.set_instance_transform(new_count - i - 1, side_transforms[i])
		multimesh.set_instance_custom_data(new_count - i - 1, new_color)


func remove_area(area : Area) -> void:
	# remove block from MultiMeshInstance
	clear()
	
	var all_block_areas = get_node(global_vars.ALL_BLOCK_AREAS_PATH).get_children()
	
	for a in all_block_areas:
		if a == area:
			# skip if there's the area that we just removed
			continue
		add_area(a)


func clear() -> void:
	# reset
	multimesh.set_visible_instance_count(0)


func recreate(new_areas : Array = get_node(global_vars.ALL_BLOCK_AREAS_PATH).get_children()):
	clear()
	for a in new_areas:
		add_area(a)
