extends MultiMeshInstance


class_name KSMultiMesh


signal area_recolored
signal area_deleted

var areas_to_recreate : Array
var current_area_thread : Area
var thread_area_to_ignore : Area
var current_visibility_intance_count := 0
var bg_check_neighbors := true
var area_queue : Array
var recolor_queue : Array
var remove_queue : Array
var bg_thread_in_progress := false
var all_placeholders : Array
var queue_batch_size := 200
var bg_counter := 0
var batch_counter := 1

var thread
var mutex
var semaphore
var exit_thread


onready var block_chunks_controller = get_node(global_vars.BLOCK_CHUNKS_CONTROLLER_PATH)
onready var base_cube_mesh_instance = preload("res://scenes/base_cube_mesh_instance.tscn")
onready var movable_world = get_node(global_vars.MOVABLE_WORLD_PATH)


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
		bg_thread_in_progress = true
		
		while true:
			if bg_counter == batch_counter * queue_batch_size:
				mutex.unlock()
				batch_finished()
				break
			
			if bg_counter == areas_to_recreate.size():
				multimesh.set_visible_instance_count(current_visibility_intance_count)
				mutex.unlock()
				creation_finished()
				break
				
#			if areas_to_recreate[bg_counter] == thread_area_to_ignore:
#				continue
			add_area(areas_to_recreate[bg_counter], bg_check_neighbors)
			bg_counter += 1
		
#		multimesh.set_visible_instance_count(current_visibility_intance_count)
#		thread_area_to_ignore = null
		
		
#		print("bg_counter ", bg_counter)
#		print("areas_to_recreate.size() ", areas_to_recreate.size())
#		if bg_counter == areas_to_recreate.size():
#			creation_finished()


func _exit_tree():
	mutex.lock()
	exit_thread = true
	mutex.unlock()
	
	semaphore.post()
	thread.wait_to_finish()


func batch_finished():
	# called from bg thread after a batch is finished
	process_remove_queue()

	batch_counter += 1
	
	# continue with bg thread
	semaphore.post()
	

func creation_finished():
	# called when bg thread has finished creating
	bg_counter = 0
	batch_counter = 1
	
	process_remove_queue()
	
	if area_queue.empty():
		bg_thread_in_progress = false
		for p in all_placeholders:
			p.queue_free()
		
		# run recolor queue
		for r in recolor_queue:
			for i in r["indices"]:
				multimesh.set_instance_custom_data(i, r["color"])
		
		recolor_queue.clear()
		
		all_placeholders.clear()
		
		return
	
	# if there is still something in the queue, process it
	create(area_queue[0]["areas"], area_queue[0]["reset"], true)
	area_queue.remove(0)


func process_remove_queue():
	if not remove_queue.empty():
		# remove from multi mesh
		var tiny_transform = Transform(Basis(Vector3(0, 0, 0)), Vector3(0, 0, 0)) 
		mutex.lock()
		for r in remove_queue:
			for i in r.mm_indices:
				multimesh.set_instance_transform(i, tiny_transform)
			
			# we need to add back some of the cube sides, sides that did have neighbors before will be missing otherwise
			var n_result = check_neighbors(r)
			for n in n_result:
				if n["area"]:
					print("neigh exists")
					var area_color = color_system.get_color_by_name(n["area"].get_color_name())
					var new_color = Color(area_color.x, area_color.y, area_color.z, 1.0)
					
					# we need to rotate by 180° on local y axis
					var rot_trans = n["transform"]
					rot_trans.basis = rot_trans.basis.rotated(rot_trans.basis.y, PI)
	
					current_visibility_intance_count += 1
					
					multimesh.set_instance_transform(current_visibility_intance_count - 1, rot_trans)
					multimesh.set_instance_custom_data(current_visibility_intance_count - 1, new_color)
					multimesh.set_visible_instance_count(current_visibility_intance_count)
			
			r.queue_free()
		mutex.unlock()
		
		remove_queue.clear()


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
	
	var s_1_neighbor_exists = false
	var s_2_neighbor_exists = false
	var s_3_neighbor_exists = false
	var s_4_neighbor_exists = false
	var s_5_neighbor_exists = false
	var s_6_neighbor_exists = false
	
	
	if check_neighbors:
		var n_result = check_neighbors(area)
#		s_1_neighbor_exists = n_result[0]
#		s_2_neighbor_exists = n_result[1]
#		s_3_neighbor_exists = n_result[2]
#		s_4_neighbor_exists = n_result[3]
#		s_5_neighbor_exists = n_result[4]
#		s_6_neighbor_exists = n_result[5]
		
		for n in n_result:
			if not n["area"]:
				side_transforms.append(n["transform"])
	
	# increment visibility 
	var new_count = current_visibility_intance_count + side_transforms.size()
	current_visibility_intance_count = new_count

	for i in range(side_transforms.size()):
		var curr_index = new_count - i - 1
		
		multimesh.set_instance_transform(curr_index, side_transforms[i])
		multimesh.set_instance_custom_data(curr_index, new_color)
		area.append_mm_index(curr_index)


func check_neighbors(area : Area) -> Array:
	var area_global_trans = area.get_global_transform()
	var area_local_trans = area.get_transform()
	var half_length = area.get_node("CollisionShape").shape.get_extents().x
	
	var s_1_neighbor_orig = area_global_trans.origin + area_local_trans.basis.z * half_length * 2
	var s_2_neighbor_orig = area_global_trans.origin - area_local_trans.basis.z * half_length * 2
	var s_3_neighbor_orig = area_global_trans.origin + area_local_trans.basis.y * half_length * 2
	var s_4_neighbor_orig = area_global_trans.origin - area_local_trans.basis.y * half_length * 2
	var s_5_neighbor_orig = area_global_trans.origin + area_local_trans.basis.x * half_length * 2
	var s_6_neighbor_orig = area_global_trans.origin - area_local_trans.basis.x * half_length * 2
	
	var trans_1 = Transform()
	var trans_2 = Transform()
	var trans_3 = Transform()
	var trans_4 = Transform()
	var trans_5 = Transform()
	var trans_6 = Transform()
	
	
	# we only do these checks if check_neighbor == true
	# because they are expensive to do
	var s_1_n = block_chunks_controller.get_block_with_orig(s_1_neighbor_orig)
	var s_2_n = block_chunks_controller.get_block_with_orig(s_2_neighbor_orig)
	var s_3_n = block_chunks_controller.get_block_with_orig(s_3_neighbor_orig)
	var s_4_n = block_chunks_controller.get_block_with_orig(s_4_neighbor_orig)
	var s_5_n = block_chunks_controller.get_block_with_orig(s_5_neighbor_orig)
	var s_6_n = block_chunks_controller.get_block_with_orig(s_6_neighbor_orig)
	
	trans_1 = area_global_trans
	trans_1.origin += area_local_trans.basis.z * half_length
	
	trans_2 = area_global_trans
	trans_2.origin -= area_local_trans.basis.z * half_length
	trans_2.basis = trans_2.basis.rotated(trans_2.basis.y, PI)
	
	trans_3 = area_global_trans
	trans_3.origin += area_local_trans.basis.y * half_length
	trans_3.basis = trans_3.basis.rotated(trans_3.basis.x, - PI / 2)
	
	trans_4 = area_global_trans
	trans_4.origin -= area_local_trans.basis.y * half_length
	trans_4.basis = trans_4.basis.rotated(trans_4.basis.x, PI / 2)
	
	trans_5 = area_global_trans
	trans_5.origin += area_local_trans.basis.x * half_length
	trans_5.basis = trans_5.basis.rotated(trans_5.basis.y, PI / 2)
	
	trans_6 = area_global_trans
	trans_6.origin -= area_local_trans.basis.x * half_length
	trans_6.basis = trans_6.basis.rotated(trans_6.basis.y, - PI / 2)
		
	
	return [
		{"area": s_1_n, "transform": trans_1},
		{"area": s_2_n, "transform": trans_2},
		{"area": s_3_n, "transform": trans_3},
		{"area": s_4_n, "transform": trans_4},
		{"area": s_5_n, "transform": trans_5},
		{"area": s_6_n, "transform": trans_6},
	]

func add_placeholder(area: Area):
	# adds cube mesh as place holders until the bg mesh has finished building
	var area_color = color_system.get_color_by_name(area.get_color_name())
	var new_color = Vector3(area_color.x, area_color.y, area_color.z)
	
	var cube_instance = base_cube_mesh_instance.instance()
	cube_instance.global_transform = area.global_transform
	
	cube_instance.get_surface_material(0).set_shader_param("color", new_color)
	
	movable_world.add_child(cube_instance)
	
	all_placeholders.append(cube_instance)
	

func remove_area(area : Area) -> void:
	# remove block from MultiMeshInstance
	# first remove it directly from the multi mesh so the player doesn't need to wait until the block is gone
#	var tiny_transform = Transform(Basis(Vector3(0, 0, 0)), Vector3(0, 0, 0)) 
#	for i in area.mm_indices:
#		multimesh.set_instance_transform(i, tiny_transform)
	remove_queue.append(area)
	
	if not bg_thread_in_progress:
		process_remove_queue()
		
#	thread_area_to_ignore = area
#	create(get_parent().get_all_blocks())
	emit_signal("area_deleted")


func create(new_areas : Array, reset : bool = true, skip_bg : bool = false) -> void:
	# we need to check if bg process is currently running. if yes, we need to queue this.
	if bg_thread_in_progress and not skip_bg:
		area_queue.append({"areas": new_areas.duplicate(true), "reset": reset})
		return
	

	mutex.lock()
	areas_to_recreate = new_areas.duplicate(true)
	if reset:
		current_visibility_intance_count = 0
	bg_check_neighbors = reset
	mutex.unlock()
	semaphore.post()


# called by SaveSystem or AllBlockAreas
func clear() -> void:
	mutex.lock()
	current_visibility_intance_count = 0
	mutex.unlock()
	multimesh.set_visible_instance_count(0)


func add_recreate(added_area : Area):
	# first add a new area without checking for neighbors, and then do the whole thing again in the background thread
	# if we only do the bg thread, the newely added cube flickers
	add_placeholder(added_area)
	
	# run bg thread to recrate all of multi mesh
	create(get_parent().get_all_blocks())
	
	

func recolor_block(area : Area) -> void:
	var area_color = color_system.get_color_by_name(area.get_color_name())
	var new_color = Color(area_color.x, area_color.y, area_color.z, 1.0)
	
	if bg_thread_in_progress:
		add_placeholder(area)
		recolor_queue.append({"indices" : area.mm_indices, "color" : new_color})
	else:
		for i in area.mm_indices:
			multimesh.set_instance_custom_data(i, new_color)
	
	emit_signal("area_recolored")
	
