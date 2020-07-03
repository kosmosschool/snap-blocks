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
var queue_batch_size := 200
var bg_counter := 0
var batch_counter := 1
var add_recreate_counter := 0
var update_count := 0
var n_placeholders := 30

var thread
var mutex
var semaphore
var exit_thread

onready var block_chunks_controller = get_node(global_vars.BLOCK_CHUNKS_CONTROLLER_PATH)


func _ready():
	# _add_area_thread
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
		
		bg_thread_in_progress = true
		
		mutex.lock()
		
		while true:
			if bg_counter == batch_counter * queue_batch_size:
				mutex.unlock()
				batch_finished()
				break
			
			if bg_counter == areas_to_recreate.size():
#				multimesh.set_visible_instance_count(current_visibility_intance_count)
				mutex.unlock()
				creation_finished()
				break
				
			add_area(areas_to_recreate[bg_counter], bg_check_neighbors)
			bg_counter += 1


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
	
	handle_next_area_queue()


func handle_next_area_queue():
	process_remove_queue()
	multimesh.set_visible_instance_count(current_visibility_intance_count)
	
	if area_queue.empty():
		bg_thread_in_progress = false
		block_chunks_controller.clear_placeholders(n_placeholders)
		
		# run recolor queue
		for r in recolor_queue:
			for i in r["indices"]:
				multimesh.set_instance_custom_data(i, r["color"])
		
		recolor_queue.clear()
		
		return
	
	# if there is still something in the queue, process it
	create(area_queue[0]["areas"], area_queue[0]["reset"], true)
	area_queue.remove(0)
	

func process_remove_queue():
	if not remove_queue.empty():
		# remove from multi mesh
		var tiny_transform = Transform()
		tiny_transform = tiny_transform.scaled(Vector3(0, 0, 0))
		mutex.lock()
		for r in remove_queue:
			# check if area in placeholder queue or already on multi mesh instance
			if block_chunks_controller.remove_placeholder(r):
				block_chunks_controller.delete_origins(r)
				r.queue_free()
				continue
				
			# we only update the mesh instances if their transform was already set by the current bg thread
			if r.get_update_count() < update_count:
				# in this case we see some flicker in the mehsh instances and i'm not sure why ¯\_(ツ)_/¯
				# it seems to be related to the delete_origins method below
				block_chunks_controller.delete_origins(r)
				r.queue_free()
				continue
				
			for i in r.mm_indices:
				multimesh.set_instance_transform(i, tiny_transform)
			
			# we need to add back some of the cube sides, sides that did have neighbors before will be missing otherwise
			var n_result = check_neighbors(r)
			for i in range(n_result.size()):
				if n_result[i]["area"]:
					var area_color = color_system.get_color_by_name(n_result[i]["area"].get_color_name())
					var new_color = Color(area_color.x, area_color.y, area_color.z, 1.0)
					
					# we need to rotate by 180° on local y axis
					var rot_trans = n_result[i]["transform"]
					rot_trans.basis = rot_trans.basis.rotated(rot_trans.basis.y, PI)

					current_visibility_intance_count += 1

					var curr_index = current_visibility_intance_count - 1
					multimesh.set_instance_transform(curr_index, rot_trans)
					multimesh.set_instance_custom_data(curr_index, new_color)

					n_result[i]["area"].append_mm_index(curr_index)
			
			block_chunks_controller.delete_origins(r)
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

		for n in n_result:
			if not n["area"]:
				side_transforms.append(n["transform"])
	else:
		side_transforms = get_cube_side_transforms(area)
	
	# increment visibility 
	var new_count = current_visibility_intance_count + side_transforms.size()
	current_visibility_intance_count = new_count
	
	area.increment_update_count()
	
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
	
	var s_1_n = block_chunks_controller.get_block_with_orig(s_1_neighbor_orig)
	var s_2_n = block_chunks_controller.get_block_with_orig(s_2_neighbor_orig)
	var s_3_n = block_chunks_controller.get_block_with_orig(s_3_neighbor_orig)
	var s_4_n = block_chunks_controller.get_block_with_orig(s_4_neighbor_orig)
	var s_5_n = block_chunks_controller.get_block_with_orig(s_5_neighbor_orig)
	var s_6_n = block_chunks_controller.get_block_with_orig(s_6_neighbor_orig)
	
	var cube_side_transforms = get_cube_side_transforms(area)
	
	return [
		{"area": s_1_n, "transform": cube_side_transforms[0]},
		{"area": s_2_n, "transform": cube_side_transforms[1]},
		{"area": s_3_n, "transform": cube_side_transforms[2]},
		{"area": s_4_n, "transform": cube_side_transforms[3]},
		{"area": s_5_n, "transform": cube_side_transforms[4]},
		{"area": s_6_n, "transform": cube_side_transforms[5]},
	]


func get_cube_side_transforms(area : Area) -> Array:
	var area_global_trans = area.get_global_transform()
	var area_local_trans = area.get_transform()
	var half_length = area.get_node("CollisionShape").shape.get_extents().x
	
	var trans_1 = area_global_trans
	trans_1.origin += area_local_trans.basis.z * half_length
	
	var trans_2 = area_global_trans
	trans_2.origin -= area_local_trans.basis.z * half_length
	trans_2.basis = trans_2.basis.rotated(trans_2.basis.y, PI)
	
	var trans_3 = area_global_trans
	trans_3.origin += area_local_trans.basis.y * half_length
	trans_3.basis = trans_3.basis.rotated(trans_3.basis.x, - PI / 2)
	
	var trans_4 = area_global_trans
	trans_4.origin -= area_local_trans.basis.y * half_length
	trans_4.basis = trans_4.basis.rotated(trans_4.basis.x, PI / 2)
	
	var trans_5 = area_global_trans
	trans_5.origin += area_local_trans.basis.x * half_length
	trans_5.basis = trans_5.basis.rotated(trans_5.basis.y, PI / 2)
	
	var trans_6 = area_global_trans
	trans_6.origin -= area_local_trans.basis.x * half_length
	trans_6.basis = trans_6.basis.rotated(trans_6.basis.y, - PI / 2)
	
	return [trans_1, trans_2, trans_3, trans_4, trans_5, trans_6]


func remove_area(area : Area) -> void:
	# remove block from MultiMeshInstance
	remove_queue.append(area)
	
	if not bg_thread_in_progress:
		process_remove_queue()
		multimesh.set_visible_instance_count(current_visibility_intance_count)

	emit_signal("area_deleted")


func create(new_areas : Array, reset : bool = true, skip_bg : bool = false) -> void:
	# we need to check if bg process is currently running. if yes, we need to queue this.
	if bg_thread_in_progress and not skip_bg:
		area_queue.append({"areas": new_areas.duplicate(true), "reset": reset})
		return
	
	bg_thread_in_progress = true
	
	mutex.lock()
	areas_to_recreate = new_areas.duplicate(true)
#	print("reset ", reset)
	if reset:
		current_visibility_intance_count = 0
		update_count += 1
	elif update_count == 0:
		update_count += 1
	bg_check_neighbors = reset
	mutex.unlock()
	semaphore.post()


# called by SaveSystem or BlockChunksController
func clear() -> void:
	mutex.lock()
	current_visibility_intance_count = 0
	mutex.unlock()
	multimesh.set_visible_instance_count(0)
	
	block_chunks_controller.clear_placeholders()


func add_recreate(added_area : Area):
	# first add a new area without checking for neighbors, and then do the whole thing again in the background thread
	# if we only do the bg thread, the newely added cube flickers
	block_chunks_controller.add_placeholder(added_area)
	
#	create(get_parent().get_all_blocks())
	add_recreate_counter += 1

	if add_recreate_counter == n_placeholders:
		# run bg thread to recrate all of multi mesh
		create(get_parent().get_all_blocks())
		add_recreate_counter = 0
	

func recolor_block(area : Area) -> void:
	var area_color = color_system.get_color_by_name(area.get_color_name())
	var new_color = Color(area_color.x, area_color.y, area_color.z, 1.0)
	
	if bg_thread_in_progress:
		block_chunks_controller.add_placeholder(area, true)
		recolor_queue.append({"indices" : area.mm_indices, "color" : new_color})
	else:
		for i in area.mm_indices:
			multimesh.set_instance_custom_data(i, new_color)
	
	emit_signal("area_recolored")
	
