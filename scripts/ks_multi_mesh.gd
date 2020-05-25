extends MultiMeshInstance


class_name KSMultiMesh


signal area_recolored
signal area_deleted

var areas_to_recreate : Array
var current_area_thread : Area
var thread_area_to_ignore : Area
var current_visibility_intance_count := 0

var thread
var mutex
var semaphore
var exit_thread


onready var all_block_areas := get_node(global_vars.ALL_BLOCK_AREAS_PATH)


func _ready():
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	
	exit_thread = false
	thread = Thread.new()
	thread.start(self, "_add_area_thread")


func _add_area_thread(userdata):
	while true:
		semaphore.wait()
		
		mutex.lock()
		var should_exit = exit_thread
		mutex.unlock()
		
		if should_exit:
			break
		
		mutex.lock()
		current_visibility_intance_count = 0
		for a in areas_to_recreate:
			if a == thread_area_to_ignore:
				continue
			add_area(a)
		
		multimesh.set_visible_instance_count(current_visibility_intance_count)
		thread_area_to_ignore = null
#		print("instance count ", multimesh.get_visible_instance_count())
		mutex.unlock()


func _exit_tree():
	mutex.lock()
	exit_thread = true
	mutex.unlock()
	
	semaphore.post()
	thread.wait_to_finish()
	


func add_area(area : Area, check_neighbors = true) -> void:
	# add block to MultiMeshInstance
	# update position of new instance
	area.clear_mm_indices()
	var area_color = color_system.get_color_by_name(area.get_color_name())
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
	
	var s_1_neighbor_exists = false
	var s_2_neighbor_exists = false
	var s_3_neighbor_exists = false
	var s_4_neighbor_exists = false
	var s_5_neighbor_exists = false
	var s_6_neighbor_exists = false
	
	if check_neighbors:
		# we only do these checks if check_neighbor == true
		# because they are expensive to do
		s_1_neighbor_exists = all_block_areas.block_exists(s_1_neighbor_orig)
		s_2_neighbor_exists = all_block_areas.block_exists(s_2_neighbor_orig)
		s_3_neighbor_exists = all_block_areas.block_exists(s_3_neighbor_orig)
		s_4_neighbor_exists = all_block_areas.block_exists(s_4_neighbor_orig)
		s_5_neighbor_exists = all_block_areas.block_exists(s_5_neighbor_orig)
		s_6_neighbor_exists = all_block_areas.block_exists(s_6_neighbor_orig)
	
	
	if not s_1_neighbor_exists:
		var trans_1 = area_global_trans
		trans_1.origin += area_local_trans.basis.z * half_length
		side_transforms.append(trans_1)
	
	if not s_2_neighbor_exists:
		var trans_2 = area_global_trans
		trans_2.origin -= area_local_trans.basis.z * half_length
		trans_2.basis = trans_2.basis.rotated(trans_2.basis.y, PI)
		side_transforms.append(trans_2)
	
	if not s_3_neighbor_exists:
		var trans_3 = area_global_trans
		trans_3.origin += area_local_trans.basis.y * half_length
		trans_3.basis = trans_3.basis.rotated(trans_3.basis.x, - PI / 2)
		side_transforms.append(trans_3)
	
	if not s_4_neighbor_exists:
		var trans_4 = area_global_trans
		trans_4.origin -= area_local_trans.basis.y * half_length
		trans_4.basis = trans_4.basis.rotated(trans_4.basis.x, PI / 2)
		side_transforms.append(trans_4)
	
	if not s_5_neighbor_exists:
		var trans_5 = area_global_trans
		trans_5.origin += area_local_trans.basis.x * half_length
		trans_5.basis = trans_5.basis.rotated(trans_5.basis.y, PI / 2)
		side_transforms.append(trans_5)
	
	if not s_6_neighbor_exists:
		var trans_6 = area_global_trans
		trans_6.origin -= area_local_trans.basis.x * half_length
		trans_6.basis = trans_6.basis.rotated(trans_6.basis.y, - PI / 2)
		side_transforms.append(trans_6)
	
	# increment visibility 
	var new_count = current_visibility_intance_count + side_transforms.size()
	current_visibility_intance_count = new_count
	
	for i in range(side_transforms.size()):
		var curr_index = new_count - i - 1
		multimesh.set_instance_transform(curr_index, side_transforms[i])
		multimesh.set_instance_custom_data(curr_index, new_color)
		area.append_mm_index(curr_index)


func remove_area(area : Area) -> void:
	# remove block from MultiMeshInstance
	thread_area_to_ignore = area
	recreate()
	emit_signal("area_deleted")


func recreate(new_areas : Array = get_node(global_vars.ALL_BLOCK_AREAS_PATH).get_children()):
	areas_to_recreate = new_areas
	semaphore.post()


# called by SaveSystem
func clear() -> void:
	current_visibility_intance_count = 0
	multimesh.set_visible_instance_count(0)


func add_recreate(added_area : Area, new_areas : Array = get_node(global_vars.ALL_BLOCK_AREAS_PATH).get_children()):
	# first add a new area without checking for neighbors, and then do the whole thing again in the background thread
	# if we only do the bg thread, the newely added cube flickers
	current_visibility_intance_count = multimesh.get_visible_instance_count()
	add_area(added_area, false)
	multimesh.set_visible_instance_count(current_visibility_intance_count)
	
	# run bg thread
	areas_to_recreate = new_areas
	semaphore.post()


func recolor_area(area : Area) -> void:
	var area_color = color_system.get_color_by_name(area.get_color_name())
	var new_color = Color(area_color.x, area_color.y, area_color.z, 1.0)
	
	for i in area.mm_indices:
		multimesh.set_instance_custom_data(i, new_color)
	
	emit_signal("area_recolored")
