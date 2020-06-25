extends KSGrabbableRigidBody


# this building block can snap!
class_name BuildingBlockSnappable


enum SnapAxis {X, Y, Z}

var moving_to_snap := false
var snap_speed := 10.0
var snap_timer := 0.0
var snap_start_transform : Transform
var snap_end_transform : Transform
var interpolation_progress : float
var ray_length := 0.2
var snap_cand
var snap_cand_normal : Vector3
var snap_axis : int
var snap_vec : Vector3
var snap_ghost_spatial
var ray_dir : Vector3
var color_name : String
var set_to_free := false
var set_to_free_staged := false
var free_timer := 0.0
var free_time := 2.0
var free_time_staging := 1.0

onready var collision_shape := $CollisionShape
onready var mesh_instance := $MeshInstance
onready var audio_player := $AudioStreamPlayer3D
onready var particles := $Particles
onready var ghost_block_scene = preload("res://scenes/building_blocks/ghost_block_base.tscn")
#onready var multi_mesh := get_node(global_vars.MULTI_MESH_PATH)
#onready var all_block_areas := get_node(global_vars.ALL_BLOCK_AREAS_PATH)
onready var block_chunks_controller = get_node(global_vars.BLOCK_CHUNKS_CONTROLLER_PATH)
onready var movable_world := get_node(global_vars.MOVABLE_WORLD_PATH)


# this is a hacky workaround because of this issue: https://github.com/godotengine/godot/issues/25252
func is_class(type):
	return type == "BuildingBlockSnappable" or .is_class(type)


func _ready():
	connect("grab_ended", self, "_on_Building_Block_Snappable_grab_ended")
	
#	set_color(color_system.get_current_color_name())
	
#	var mdt = MeshDataTool.new()
#	mdt.create_from_surface(mesh_instance.mesh, 0)
#	print("mdt.get_vertex_count() 0: ", mdt.get_vertex_count())
#	mdt.create_from_surface(mesh_instance.mesh, 1)
#	print("mdt.get_vertex_count() 1: ", mdt.get_vertex_count())


func _process(delta):
	if moving_to_snap:
		update_pos_to_snap(delta)
	
	if set_to_free:
		# we have to free in two stages, else the audio will be cut off
		if not set_to_free_staged and free_timer > free_time_staging:
			audio_player.global_transform.origin = global_transform.origin
			audio_player.play()
			particles.set_emitting(true)
			mesh_instance.visible = false
			set_to_free_staged = true
			
			
		if free_timer > free_time:
			set_to_free = false
			queue_free() 
		
		free_timer += delta


func _physics_process(delta):
	if not is_grabbed:
		return
	
	if moving_to_snap:
		return
	
	var distances_array = [10, 10, 10, 10, 10, 10]
	var results_array = [null, null, null, null, null, null]
	
	var space_state = get_world().direct_space_state
	var ray_dest_z = global_transform.origin + transform.basis.z * ray_length
	var ray_dest_zm = global_transform.origin - transform.basis.z * ray_length
	var ray_dest_x = global_transform.origin + transform.basis.x * ray_length
	var ray_dest_xm = global_transform.origin - transform.basis.x * ray_length
	var ray_dest_y = global_transform.origin + transform.basis.y * ray_length
	var ray_dest_ym = global_transform.origin - transform.basis.y * ray_length
	
	# set collision mask to 4 (i.e. second bit only so that it only collides with other blocks)
	var result_z = space_state.intersect_ray(global_transform.origin, ray_dest_z, [self], 2, false, true)
	var result_zm = space_state.intersect_ray(global_transform.origin, ray_dest_zm, [self], 2, false, true)
	var result_x = space_state.intersect_ray(global_transform.origin, ray_dest_x, [self], 2, false, true)
	var result_xm = space_state.intersect_ray(global_transform.origin, ray_dest_xm, [self], 2, false, true)
	var result_y = space_state.intersect_ray(global_transform.origin, ray_dest_y, [self], 2, false, true)
	var result_ym = space_state.intersect_ray(global_transform.origin, ray_dest_ym, [self], 2, false, true)
	
	if not result_z.empty():
		distances_array[0] = global_transform.origin.distance_to(result_z["position"])
		result_z["snap_axis"] = SnapAxis.Z
		result_z["ray_dir"] = transform.basis.z
		results_array[0] = result_z

	if not result_zm.empty():
		distances_array[1] = global_transform.origin.distance_to(result_zm["position"])
		result_zm["snap_axis"] = SnapAxis.Z
		result_zm["ray_dir"] = -transform.basis.z
		results_array[1] = result_zm

	if not result_x.empty():
		distances_array[0] = global_transform.origin.distance_to(result_x["position"])
		result_x["snap_axis"] = SnapAxis.X
		result_x["ray_dir"] = transform.basis.x
		results_array[0] = result_x

	if not result_xm.empty():
		distances_array[0] = global_transform.origin.distance_to(result_xm["position"])
		result_xm["snap_axis"] = SnapAxis.X
		result_xm["ray_dir"] = -transform.basis.x
		results_array[0] = result_xm
	
	if not result_y.empty():
		distances_array[0] = global_transform.origin.distance_to(result_y["position"])
		result_y["snap_axis"] = SnapAxis.Y
		result_y["ray_dir"] = transform.basis.y
		results_array[0] = result_y
	
	if not result_ym.empty():
		distances_array[0] = global_transform.origin.distance_to(result_ym["position"])
		result_ym["snap_axis"] = SnapAxis.Y
		result_ym["ray_dir"] = -transform.basis.y
		results_array[0] = result_ym
	
	# find ray with closest collision
	var min_dist = distances_array.min()
	var min_index = distances_array.find(min_dist)
	
	if min_index == -1:
		return
	
	if min_dist < 10:
		# take the closest hit
		snap_cand = results_array[min_index]["collider"]
		snap_cand_normal = results_array[min_index]["normal"]
		snap_axis = results_array[min_index]["snap_axis"]
		ray_dir = results_array[min_index]["ray_dir"]
		
		# prevent snapping to block which is held on other hand
#		if snap_cand as BuildingBlockSnappable and snap_cand.is_grabbed:
#			snap_cand = null
#			return
		
		# check angle between normal and ray
		var angle = ray_dir.angle_to(snap_cand_normal)
		if angle < 2.2:
			snap_cand = null
			if snap_ghost_spatial:
				snap_ghost_spatial.queue_free()
				snap_ghost_spatial = null
			return
		
		if not snap_ghost_spatial:
			create_ghost()
		
		position_ghost()
	else:
		# no hit found
		snap_cand = null
		if snap_ghost_spatial:
			snap_ghost_spatial.queue_free()
			snap_ghost_spatial = null


func _on_Building_Block_Snappable_grab_ended():
	if snap_cand:
		snap_to_cand()
	else:
		# free after x seconds
		set_to_free = true


func set_color(new_color_name : String) -> void:
	color_name = new_color_name
	var color_vec3 = color_system.get_color_by_name(new_color_name)
	mesh_instance.get_surface_material(0).set_shader_param("color", color_vec3)
	
	# set particle system color
	particles.draw_pass_1.get_material().set_shader_param("color", color_vec3)


func create_ghost():
	snap_ghost_spatial = ghost_block_scene.instance()
	movable_world.add_child(snap_ghost_spatial)
	snap_ghost_spatial.set_color(mesh_instance.get_surface_material(0).get_shader_param("color"))


func position_ghost():
	snap_ghost_spatial.global_transform = snap_cand.global_transform
	var vec_to_basis_res = vec_to_basis(snap_cand_normal, snap_cand.transform.basis)
	var snap_dir = vec_to_basis_res["dir_vec"]
	var move_by_vec = snap_dir * collision_shape.shape.extents * 2
	snap_ghost_spatial.global_transform.origin += move_by_vec


func vec_to_basis(input_vec : Vector3, input_basis : Basis) -> Dictionary:
	# match an input vector to a basis
	# necessary because normal returned by raycast is not exactly reliable
	
	var orth_x = input_vec.cross(input_basis.x)
	var orth_y = input_vec.cross(input_basis.y)
	var orth_z = input_vec.cross(input_basis.z)
	var dir_vec : Vector3
	
	var final_orth = orth_x
	var basis_dir = input_basis.x
	var return_snap_axis = SnapAxis.X
	
	if orth_y.length() < final_orth.length():
		final_orth = orth_y
		basis_dir = input_basis.y
		return_snap_axis = SnapAxis.Y
	
	if orth_z.length() < final_orth.length():
		final_orth = orth_z
		basis_dir = input_basis.z
		return_snap_axis = SnapAxis.Z
	
	# find out sign
	dir_vec = basis_dir
	if input_vec.dot(basis_dir) < 0:
		dir_vec *= -1
	
	return {"dir_vec": dir_vec, "basis_dir": basis_dir, "snap_axis": return_snap_axis}


func snap_to_cand():
	snap_start_transform = global_transform
	
	if snap_cand is RigidBody:
		var snap_cand_rigid_body = snap_cand
		block_chunks_controller.add_block(snap_cand.global_transform, snap_cand.color_name, false, true)
#		snap_cand = all_block_areas.add_block_area(
#			snap_cand.global_transform, 
#			snap_cand.color_name,
#			false
#		)
#		multi_mesh.add_recreate(snap_cand)
		snap_cand_rigid_body.queue_free()
	
	# find one orthogonal vector to normal that we can use to calculate the angles
	# this works because the normal is one of the three local direction vectors
	var vec_to_basis_res = vec_to_basis(snap_cand_normal, snap_cand.transform.basis)
	var normal_dir_vec = vec_to_basis_res["dir_vec"]
	var normal_snap_axis  = vec_to_basis_res["snap_axis"]
	var snap_candid_current_basis_dir  = vec_to_basis_res["basis_dir"]
	
	var angle_y := 0.0
	var angle_x := 0.0
	var angle_z := 0.0
	
	if snap_axis == SnapAxis.Z:
		var same_dir := true
		
		var angle_y_diff = snap_vecs_angle(
			transform.basis.z,
			snap_candid_current_basis_dir,
			transform.basis.y
		)
		
		var y_z_diff_vec = -transform.basis.y
		if abs(angle_y_diff) > (PI / 2):
			same_dir = false
			y_z_diff_vec = transform.basis.y
		
		var y_y_diff = snap_vecs_angle(
			transform.basis.y,
			snap_cand.transform.basis.y,
			transform.basis.z
		)
		
		var y_z_diff = snap_vecs_angle(
			y_z_diff_vec,
			snap_cand.transform.basis.z,
			transform.basis.z
		)
		
		if normal_snap_axis == SnapAxis.X:
			angle_y = PI / 2
			if not same_dir:
				angle_y *= -1
			
			angle_z = snap_rotation(y_y_diff)
		
		if normal_snap_axis == SnapAxis.Y:
			angle_x = - PI / 2
			angle_z = snap_rotation(y_z_diff)
			
			if not same_dir:
				angle_x *= -1

		if normal_snap_axis == SnapAxis.Z:
			if not same_dir:
				angle_y = PI
			
			angle_z = snap_rotation(y_y_diff)
		
		# set basis to snap_cand's and apply rotation
		transform.basis = snap_cand.transform.basis
		rotate_object_local(Vector3(1, 0, 0), angle_x)
		rotate_object_local(Vector3(0, 1, 0), angle_y)
		rotate_object_local(Vector3(0, 0, 1), angle_z)
	
	if snap_axis == SnapAxis.X:
		var same_dir := true
		
		var angle_y_diff = snap_vecs_angle(
			transform.basis.x,
			snap_candid_current_basis_dir,
			transform.basis.y
		)
		
		var y_z_diff_vec = -transform.basis.y
		if abs(angle_y_diff) > (PI / 2):
			same_dir = false
			y_z_diff_vec = transform.basis.y
		
		var y_y_diff = snap_vecs_angle(
			transform.basis.y,
			snap_cand.transform.basis.y,
			transform.basis.x
		)
		
		var y_z_diff = snap_vecs_angle(
			y_z_diff_vec,
			snap_cand.transform.basis.x,
			transform.basis.x
		)
		
		angle_x = snap_rotation(y_y_diff)
		
		if normal_snap_axis == SnapAxis.Z:
			angle_y = - PI / 2
			if not same_dir:
				angle_y *= -1
			
		if normal_snap_axis == SnapAxis.Y:
			angle_z = PI / 2
			angle_x = snap_rotation(y_z_diff)
			
			if not same_dir:
				angle_z *= -1
		
		if normal_snap_axis == snap_axis:
			if not same_dir:
				angle_y = PI
		
		
		# set basis to snap_cand's and apply rotation
		transform.basis = snap_cand.transform.basis
		rotate_object_local(Vector3(0, 1, 0), angle_y)
		rotate_object_local(Vector3(0, 0, 1), angle_z)
		rotate_object_local(Vector3(1, 0, 0), angle_x)
	
	
	if snap_axis == SnapAxis.Y:
		var same_dir := true
		
		var angle_y_diff = snap_vecs_angle(
			transform.basis.y,
			snap_candid_current_basis_dir,
			transform.basis.z
		)
		
		if abs(angle_y_diff) > (PI / 2):
			same_dir = false
		
		var y_y_diff = snap_vecs_angle(
			transform.basis.z,
			snap_cand.transform.basis.z,
			transform.basis.y
		)
		
		var y_z_diff = snap_vecs_angle(
			transform.basis.x,
			snap_cand.transform.basis.x,
			transform.basis.y
		)
		
		angle_y = snap_rotation(y_y_diff)
		
		if normal_snap_axis == SnapAxis.X:
			angle_z = - PI / 2
			if not same_dir:
				angle_z *= -1
			
		if normal_snap_axis == SnapAxis.Z:
			angle_x = PI / 2
			angle_y = snap_rotation(y_z_diff)

			if not same_dir:
				angle_x *= -1
		
		if normal_snap_axis == snap_axis:
			if not same_dir:
				angle_z = PI
		
		
		# set basis to snap_cand's and apply rotation
		transform.basis = snap_cand.transform.basis
		rotate_object_local(Vector3(0, 0, 1), angle_z)
		rotate_object_local(Vector3(1, 0, 0), angle_x)
		rotate_object_local(Vector3(0, 1, 0), angle_y)
	
	snap_end_transform.basis = global_transform.basis

	snap_end_transform.origin = snap_ghost_spatial.global_transform.origin
	
#	snap_end_transform.origin = global_transform.origin + move_by_vec
	global_transform = snap_start_transform
	
	snap_ghost_spatial.queue_free()
	snap_ghost_spatial = null
	
	set_mode(RigidBody.MODE_KINEMATIC)
	moving_to_snap = true


func snap_rotation(angle_to_snap) -> float:
	# snaps rotation to next 90° angle and returns new angle
	var new_angle
	if abs(angle_to_snap) >= 0 and abs(angle_to_snap) < (PI / 4):
		new_angle = 0
	elif abs(angle_to_snap) >= (PI / 4) and abs(angle_to_snap) < (PI / 2):
		new_angle = PI / 2
	elif abs(angle_to_snap) >= (PI / 2) and abs(angle_to_snap) < (PI * 3 / 4):
		new_angle = PI / 2
	elif abs(angle_to_snap) >= (PI * 3 / 4):
		new_angle = PI
	
	# sign angle again
	if angle_to_snap < 0:
		new_angle *= -1
	
	return new_angle


func snap_vecs_angle(vec_a, vec_b, vec_n) -> Array:
	# this method calculates the signed angle between vec_a and vec_b on the plane with normal vec_n
	#
	# where
	# vec_a: first vector for angle
	# vec_b: second vector for angle
	# vec_n: normal of the plane that vec a and vec b are on
	
	# here's a good explanation on why getting the signed alpha with atan2 works:
	# https://stackoverflow.com/questions/5188561/signed-angle-between-two-3d-vectors-with-same-origin-within-the-same-plane

	# calculate signed angle
	var this_basis_vec_comp = vec_a.slide(vec_n)
	var cross = vec_b.cross(this_basis_vec_comp)
	
	var dot = this_basis_vec_comp.dot(vec_b)
	var final_angle = atan2(cross.dot(vec_n), dot)
	
	return final_angle


# snaps to the other block over time, updating position and rotation
func update_pos_to_snap(delta: float) -> void:
	snap_timer += delta
	interpolation_progress = snap_timer * snap_speed
	
	if interpolation_progress > 1.0:
		# set final pos
		global_transform = snap_end_transform
		moving_to_snap = false
		snap_timer = 0.0
		block_chunks_controller.add_block(global_transform, color_name, true, true)
#		var transferred_area = all_block_areas.add_block_area(
#			global_transform,
#			color_name
#		)
#		multi_mesh.add_recreate(transferred_area)
		queue_free()
		return
	
	global_transform = snap_start_transform.interpolate_with(snap_end_transform, interpolation_progress)
