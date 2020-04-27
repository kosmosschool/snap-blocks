extends BuildingBlock


# this building block can snap!
class_name BuildingBlockSnappable


signal block_snapped_updated

enum SnapAxis {X, XM, Y, YM, Z, ZM}

var moving_to_snap := false setget set_moving_to_snap, get_moving_to_snap
var snapped := false setget set_snapped, get_snapped
var overlapping := false setget set_overlapping, get_overlapping
var snap_speed := 10.0
var snap_timer := 0.0
var snap_start_transform : Transform
var snap_end_transform : Transform
var interpolation_progress : float
var volt_measure_points : Dictionary
#var other_area_parent
var on_multi_mesh := false
var ray_length := 0.2
var snap_cand
var snap_cand_inter_point : Vector3
var snap_cand_normal : Vector3
var snap_axis : int
var snap_vec : Vector3
var snap_ghost_spatial
var ray_dir : Vector3
#var ready_to_snap := false
#var collision_switching := false
#var collision_switch_timer := 0.0
#var prev_collision_mask


#onready var held_snap_areas = $HeldSnapAreas
#onready var held_snap_areas_children = held_snap_areas.get_children()
#onready var snap_areas = $SnapAreas
#onready var snap_areas_children = snap_areas.get_children()
#onready var all_children = get_children()
onready var audio_stream_player := $AudioStreamPlayer3D
onready var collision_shape := $CollisionShape
onready var snap_sound := preload("res://sounds/magnetic_click.wav")
onready var ghost_block_scene = preload("res://scenes/building_blocks/ghost_block_base.tscn")
onready var all_measure_points := get_node(global_vars.ALL_MEASURE_POINTS_PATH)
onready var multi_mesh := get_node(global_vars.MULTI_MESH_PATH)
onready var measure_point_scene = load(global_vars.MEASURE_POINT_FILE_PATH)
onready var all_snap_areas := get_node(global_vars.ALL_SNAP_AREAS_PATH)
onready var all_block_areas := get_node(global_vars.ALL_BLOCK_AREAS_PATH)
onready var movable_world := get_node(global_vars.MOVABLE_WORLD_PATH)

export(PackedScene) var snap_particles_scene


# setter and getter functions
func set_moving_to_snap(new_value):
	moving_to_snap = new_value


func get_moving_to_snap():
	return moving_to_snap


func set_snapped(new_value):
	snapped = new_value


func get_snapped():
	return snapped


func set_overlapping(new_value):
	overlapping = new_value


func get_overlapping():
	return overlapping


# this is a hacky workaround because of this issue: https://github.com/godotengine/godot/issues/25252
func is_class(type):
	return type == "BuildingBlockSnappable" or .is_class(type)


func _ready():
	connect_to_snap_area_signals()
	connect("grab_started", self, "_on_Building_Block_Snappable_grab_started")
	connect("grab_ended", self, "_on_Building_Block_Snappable_grab_ended")
	
#	prev_collision_mask = get_collision_mask()
	
#	if !is_grabbed:
#		show_held_snap_areas(false)
#		set_process(false)
#		set_physics_process(false)
	
#	if is_grabbed and vr.button_pressed(vr.BUTTON.B):
#		# start timer to change collision layesr because this means that it has been duplicated
#		collision_switching = true
#		set_collision_mask_bit(4, true)


func _process(delta):
	if moving_to_snap:
		update_pos_to_snap(delta)
	
#	if collision_switching:
#		collision_switch_timer += delta
#
#		if collision_switch_timer > 1.0:
#			set_collision_mask(prev_collision_mask)
#			collision_switching = false
		

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
	
	# set collision mask to 4 (i.e. second bit only so that it only collides with other blocks)
	var result_z = space_state.intersect_ray(global_transform.origin, ray_dest_z, [self], 2, true, true)
	var result_zm = space_state.intersect_ray(global_transform.origin, ray_dest_zm, [self], 2, true, true)
	
	if not result_z.empty():
		distances_array[0] = global_transform.origin.distance_to(result_z["position"])
		result_z["snap_axis"] = SnapAxis.Z
		result_z["ray_dir"] = transform.basis.z
		results_array[0] = result_z
		
	if not result_zm.empty():
		distances_array[1] = global_transform.origin.distance_to(result_zm["position"])
		result_zm["snap_axis"] = SnapAxis.ZM
		result_zm["ray_dir"] = -transform.basis.z
		results_array[1] = result_zm
	
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


func _on_Building_Block_Snappable_grab_started():
	pass
#	show_held_snap_areas(true)
#	set_process(true)
#	set_physics_process(true)
#	multi_mesh_remove()


func _on_Building_Block_Snappable_grab_ended():
#	if !overlapping:
#		set_process(false)
#		set_physics_process(false)
#		show_held_snap_areas(false)
	if snap_cand:
		snap_to_cand()
#	else:
#		set_process(false)
#		set_physics_process(false)


func _on_SnapArea_area_snapped():
	update_snapped_status()


func _on_SnapArea_area_unsnapped():
	update_snapped_status()
	

func update_snapped_status():
	# update status if all areas are unsnapped or min. 1 is snapped
#	var snapped_status = false
#
#	for child in all_children:
#		if child is SnapArea:
#			if child.get_snapped():
#				snapped_status = true
#				break
#
#	snapped = snapped_status
	pass


func show_held_snap_areas(show: bool) -> void:
#	for held_snap_area in held_snap_areas_children:
#		if held_snap_area is HeldSnapArea:
#			held_snap_area.visible = show
	pass


func connect_to_snap_area_signals():	
#	for child in snap_areas_children:
#		if child is SnapArea:
#			child.connect("area_snapped", self, "_on_SnapArea_area_snapped")
#			child.connect("area_unsnapped", self, "_on_SnapArea_area_unsnapped")
	pass


# after it moved to position, we need to check with snap areas are now overlapping
func check_snap_areas() -> void:
#	for child in snap_areas_children:
#		if child is SnapArea:
#			if !child.get_snapped():
#				child.start_double_check_snap()
	pass


# unsnaps all areas (needed for deleting block)
func unsnap_all() -> void:
#	for child in snap_areas_children:
#		if child is SnapArea:
#			child.unsnap_both()
	pass


#func calc_snap_vec(intersection_point : Vector3, normal : Vector3) -> Vector3:
#	# calculates snap vector based on intersection point and normal
#	# this is vector goes from the block's origin through the mid-point of the area where the intersection
#	# point lies
#	# returned snap vec is normalized
#	var col_shape_extents = collision_shape.shape.extents
#
#	var return_vec = intersection_point + ( -1 * normal * col_shape_extents - global_transform.origin)
#
#	return return_vec.normalized()


#func snap_rotation2(angle_to_snap) -> float:
#	# snaps rotation to next 90° angle and returns new angle
#	var new_angle
#	var angle_to_snap_abs = abs(angle_to_snap)
#	if angle_to_snap_abs >= 0 and angle_to_snap_abs < (PI / 4):
#		new_angle = (PI / 4) - angle_to_snap_abs
#	elif angle_to_snap_abs >= (PI / 4) and angle_to_snap_abs < (PI / 2):
#		new_angle = (PI / 2) - angle_to_snap_abs
#	elif angle_to_snap_abs >= (PI / 2) and angle_to_snap_abs < (PI * 3 / 4):
#		new_angle = (PI * 3 / 4) - angle_to_snap_abs
#	elif angle_to_snap_abs >= (PI * 3 / 4):
#		new_angle = PI - angle_to_snap_abs
#
#	# sign angle again
#	if angle_to_snap < 0:
#		new_angle *= -1
#
#	return new_angle


func snap_to_90(angle_to_snap) -> float:
	# snaps rotation to lowest 90° angle and returns new angle
	var new_angle
#	var multiplier
#	if angle_to_snap < 0:
#		multiplier = floor(angle_to_snap / (PI / 2))
#	else:
#		multiplier = ceil(angle_to_snap / (PI / 2))
	
	var multiplier = round(angle_to_snap / (PI / 2))

	new_angle = angle_to_snap - (multiplier * (PI / 2))
	
	return new_angle


func create_ghost():
	snap_ghost_spatial = ghost_block_scene.instance()
	movable_world.add_child(snap_ghost_spatial)


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
	
	
	var final_orth = orth_x
	var snap_dir = input_basis.x
	var return_snap_axis = SnapAxis.X
	
	if orth_y.length() < final_orth.length():
		final_orth = orth_y
		snap_dir = input_basis.y
		return_snap_axis = SnapAxis.Y
	
	if orth_z.length() < final_orth.length():
		final_orth = orth_z
		snap_dir = input_basis.z
		return_snap_axis = SnapAxis.Z
	
	# find out sign
	if input_vec.dot(snap_dir) < 0:
		snap_dir *= -1
	
	return {"dir_vec": snap_dir, "snap_axis": return_snap_axis}


func snap_to_cand():
	snap_start_transform = global_transform
	
	if snap_cand is RigidBody:
		snap_cand = snap_cand.transfer_col_shape()
		multi_mesh.add_area(snap_cand)
	
	# find one orthogonal vector to normal that we can use to calculate the angles
	# this works because the normal is one of the three local direction vectors
	var vec_to_basis_res = vec_to_basis(snap_cand_normal, snap_cand.transform.basis)
	var normal_dir_vec = vec_to_basis_res["dir_vec"]
	var normal_snap_axis  = vec_to_basis_res["snap_axis"]
	
#	var this_angle_z_vec
#	var snap_cand_angle_z_vec
	
	var angle_y := 0.0
	var angle_x := 0.0
	var angle_z := 0.0
	
	var angle_y_add := 0.0
	
	if snap_axis == SnapAxis.Z or snap_axis == SnapAxis.ZM:
		var same_dir := true
#		this_angle_z_vec = transform.basis.y
#		snap_cand_angle_z_vec = snap_cand.transform.basis.y
		
		var angle_y_diff = snap_vecs_angle(
			transform.basis.z,
			normal_dir_vec.abs(),
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
		
	
#	var snap_cand_orth = normal_dir_vec.cross(snap_cand.transform.basis.x)
#	if snap_cand_orth.length() < 0.001:
#		snap_cand_orth = normal_dir_vec.cross(snap_cand.transform.basis.y)
#	if snap_cand_orth.length() < 0.001:
#		snap_cand_orth = normal_dir_vec.cross(snap_cand.transform.basis.z)
	
#	var angle_x = snap_vecs_angle(
#		ray_dir,
#		normal_dir_vec,
#		transform.basis.x
#	)
#
#	var angle_y = snap_vecs_angle(
#		ray_dir,
#		normal_dir_vec,
#		transform.basis.y
#	)
#
#	var angle_z = snap_vecs_angle(
#		this_angle_z_vec,
#		snap_cand_angle_z_vec,
###		snap_cand_orth,
##		snap_cand.transform.basis.y,
#		ray_dir
#	)
	
#	print("angle_x", angle_x)
#	print("angle_y", angle_y)
#	print("angle_z", angle_z)
	
#	angle_x = snap_to_90(angle_x)
#	angle_y = snap_to_90(angle_y)
#	angle_z = snap_to_90(angle_z)
	
#	print("angle_x snapped", angle_x)
#	print("angle_y snapped", angle_y)
#	print("angle_z snapped", angle_z)
	
	# reset transform
	transform.basis = snap_cand.transform.basis
	
	rotate_object_local(Vector3(1, 0, 0), angle_x)
	rotate_object_local(Vector3(0, 1, 0), angle_y)
	rotate_object_local(Vector3(0, 0, 1), angle_z)
	
	snap_end_transform.basis = global_transform.basis
	
	# get this again because of the rotation that happened
#	if snap_axis == SnapAxis.Z:
#		ray_dir = transform.basis.z
	
#	var col_shape_extents = collision_shape.shape.extents
	
	# just take one extent, it's a cube and all are the same size for now
#	var this_surface_pos = global_transform.origin + ray_dir * col_shape_extents.x
#	var other_surface_pos = snap_cand.global_transform.origin + normal_dir_vec * col_shape_extents.x
#
#	var move_by_vec = other_surface_pos - this_surface_pos

	snap_end_transform.origin = snap_ghost_spatial.global_transform.origin
	
#	snap_end_transform.origin = global_transform.origin + move_by_vec
	global_transform = snap_start_transform
	
	snap_ghost_spatial.queue_free()
	snap_ghost_spatial = null
	
	set_mode(RigidBody.MODE_KINEMATIC)
	moving_to_snap = true


#func snap_to_block():
#	# note that this_snap_area is a HeldSnapArea and other_snap_area is a SnapArea
#	snap_start_transform = global_transform
#
##	var other_snap_axis = snap_cand.calc_axis(snap_cand_inter_point)
#
#	var other_snap_vec = snap_cand.calc_snap_vec(snap_cand_inter_point)
#
#	# get other area's parent transform
#	var other_area_parent_transform = all_snap_areas.get_parent_transform(other_snap_area)
#
##	var add_other_parent := false
##	var other_snap_area_parent
##	if not other_area_parent_transform:
##		# in this case the parent block is probably not part of a multi mesh, so add it
##		other_snap_area_parent = other_snap_area.get_parent().get_parent()
##		if not other_snap_area_parent as BuildingBlockSnappable:
##			return
##
##		other_area_parent_transform = other_snap_area_parent.get_transform()
##		add_other_parent = true
#
##	other_area_parent = other_snap_area.get_parent()
##	var start_rotation = rotation
#
#	# orthonormalize just to be sure
#	var this_basis = transform.basis.orthonormalized()
##	var other_block_basis = other_area_parent.transform.basis.orthonormalized()
##	var other_block_basis = other_area_parent_transform.basis.orthonormalized()
#	var other_block_basis = snap_cand.transform.basis.orthonormalized()
#
#	# we need to find out the local x rotation of the this block
#	# it depends on the relative difference to the x rotation of the other block
##	var x_rotation_new : float
##	var y_rotation_new : float
##	var z_rotation_new : float
##	var x_rotation_extra : float
##	var y_rotation_extra : float
##	var z_rotation_extra : float
##
#
#	snap_end_transform.basis = global_transform.basis
#
#	var col_shape_extents = get_node("CollisionShape").shape.extents
#
#	# just take one extent, it's a cube and all are the same size for now
#	var this_surface_pos = snap_vec.normalized() * col_shape_extents.x
#	var other_surface_pos = other_snap_vec.normalized() * col_shape_extents.x
#
##	var other_snap_area_ext = other_snap_area.get_node("CollisionShape").shape.extents
##	var extra_move_by = this_snap_area.global_transform.basis.z * this_snap_area_ext.z
#	var move_by_vec = snap_cand.global_transform.origin + other_surface_pos - global_transform.origin - this_surface_pos
#	snap_end_transform.origin = global_transform.origin + move_by_vec
#
#	global_transform = snap_start_transform
#
#	set_mode(RigidBody.MODE_KINEMATIC)
#	moving_to_snap = true
##	overlapping = false
##	show_held_snap_areas(false)
#
#
#
#	if (this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH):
#
#		# for a width-to-width snap, we use the angle between the local bases y vectors to accomplish this
#		# we need to make sure that we get the two y vectors on a y-z plane, so we take the x vector component
#		# of this block
#		var angles = blocks_angle(
#			this_basis.y,
#			other_block_basis.y,
#			other_block_basis.x,
#			this_basis.x,
#			other_block_basis.x,
#			other_block_basis.y
#		)
#
#		x_rotation_new = snap_rotation(angles[0])
#		y_rotation_extra = angles[1]
#
#
#	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A) or
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C)):
#		# for width-to-length_a snap, we again need the angle between the y vectors, but this time on the y-x plane
#
#		var angles = blocks_angle(
#			this_basis.y,
#			other_block_basis.y,
#			other_block_basis.z,
#			this_basis.x,
#			other_block_basis.z,
#			other_block_basis.y
#		)
#
#		x_rotation_new = snap_rotation(angles[0])
#		y_rotation_extra = angles[1]
#
#		# we need to add the rotation extra beause this snap is always at a 90° (width to length)
#		y_rotation_extra -= (PI / 2)
#
#	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B) or
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D)):
#		# for width-to-length_b snap, we again need the angle between the y vectors, but this time on the y-x plane
#
#		var angles = blocks_angle(
#			this_basis.z,
#			other_block_basis.z,
#			other_block_basis.y,
#			this_basis.x,
#			other_block_basis.y,
#			other_block_basis.z
#		)
#
#		x_rotation_new = snap_rotation(angles[0])
#		z_rotation_extra = angles[1]
#
#		# we need to add the rotation extra beause this snap is always at a 90° (width to length)
#		z_rotation_extra += (PI / 2)
#
#	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH) or
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH)):
#		# for width-to-length_a snap, we again need the angle between the y vectors, but this time on the y-x plane
#
#		var angles = blocks_angle(
#			this_basis.y,
#			other_block_basis.y,
#			other_block_basis.x,
#			this_basis.z,
#			other_block_basis.x,
#			other_block_basis.y
#		)
#
#		z_rotation_new = snap_rotation(angles[0])
#		y_rotation_extra = angles[1]
#
#		# we need to add the rotation extra beause this snap is always at a 90° (width to length)
#		y_rotation_extra += (PI / 2)
#
#	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH) or
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH)):
#		# for width-to-length_a snap, we again need the angle between the y vectors, but this time on the y-x plane
#
#		var angles = blocks_angle(
#			this_basis.z,
#			other_block_basis.y,
#			other_block_basis.x,
#			this_basis.y,
#			other_block_basis.x,
#			other_block_basis.y
#		)
#
#		y_rotation_new = snap_rotation(angles[0])
#		z_rotation_extra = angles[1]
#
#		# we need to add the rotation extra beause this snap is always at a 90° (width to length)
#		x_rotation_extra -= (PI / 2)
#		z_rotation_extra -= (PI / 2)
#
#	if (this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D):
#		# for width-to-length_d snap, we again need the angle between the y vectors, but this time on the y-z plane
#
#		var angles = blocks_angle(
#			this_basis.z,
#			other_block_basis.z,
#			other_block_basis.y,
#			this_basis.x,
#			other_block_basis.y,
#			other_block_basis.z
#		)
#
#		x_rotation_new = snap_rotation(angles[0])
#
#		z_rotation_extra = angles[1]
#		# we need to add the rotation extra beause this snap is always at a 90° (width to length)
#		z_rotation_extra += (PI / 2)
#
#	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A) or
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A) or 
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C) or
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C)):
#
#		var angles = blocks_angle(
#			this_basis.y,
#			other_block_basis.y,
#			other_block_basis.z,
#			this_basis.z,
#			other_block_basis.z,
#			other_block_basis.y
#		)
#
#		z_rotation_new = snap_rotation(angles[0])
#		y_rotation_extra = angles[1]
#
#	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A) or
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A) or
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C) or
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C)):
#
#		var angles = blocks_angle(
#			this_basis.x,
#			other_block_basis.x,
#			other_block_basis.z,
#			this_basis.y,
#			other_block_basis.z,
#			other_block_basis.y
#		)
#
#		y_rotation_new = snap_rotation(angles[0])
#		x_rotation_extra = angles[1]
#
#		x_rotation_extra += (PI / 2)
#
#	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D) or
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D) or
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B) or 
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B)):
#
#		var angles = blocks_angle(
#			this_basis.x,
#			other_block_basis.x,
#			other_block_basis.y,
#			this_basis.z,
#			other_block_basis.y,
#			other_block_basis.z
#		)
#
#		z_rotation_new = snap_rotation(angles[0])
#		x_rotation_extra = angles[1]
#
#		x_rotation_extra -= (PI / 2)
#
#	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D) or
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D) or
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B) or 
#			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D
#			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B)):
#
#		var angles = blocks_angle(
#			this_basis.x,
#			other_block_basis.x,
#			other_block_basis.y,
#			this_basis.y,
#			other_block_basis.y,
#			other_block_basis.z
#		)
#
#		y_rotation_new = snap_rotation(angles[0])
#		x_rotation_extra = angles[1]
#
#
#	transform.basis = other_block_basis
#
#	rotate_object_local(Vector3(1, 0, 0), x_rotation_extra)
#	rotate_object_local(Vector3(0, 1, 0), y_rotation_extra)
#	rotate_object_local(Vector3(0, 0, 1), z_rotation_extra)
#
#	rotate_object_local(Vector3(1, 0, 0), x_rotation_new)
#	rotate_object_local(Vector3(0, 1, 0), y_rotation_new)
#	rotate_object_local(Vector3(0, 0, 1), z_rotation_new)
#
#	snap_end_transform.basis = global_transform.basis
#
#	var this_snap_area_ext = this_snap_area.get_node("CollisionShape").shape.extents
##	var other_snap_area_ext = other_snap_area.get_node("CollisionShape").shape.extents
#	var extra_move_by = this_snap_area.global_transform.basis.z * this_snap_area_ext.z
#	var move_by_vec = other_snap_area.global_transform.origin - this_snap_area.global_transform.origin + extra_move_by
#	snap_end_transform.origin = global_transform.origin + move_by_vec
#
#	global_transform = snap_start_transform
#
#	set_mode(RigidBody.MODE_KINEMATIC)
#	moving_to_snap = true
#	overlapping = false
#	show_held_snap_areas(false)
#
#	if add_other_parent:
#		# also add other parent ot multi_mesn
#		other_snap_area_parent.multi_mesh_add()
#		other_snap_area_parent.free_and_transfer()


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
	# it also calculates the "moving_to_snap angle" vec_flip_a and vec_flip_b
	# on the plane vec_flip_n, which is either PI or 0.
	#
	# where
	# vec_a: first vector for angle
	# vec_b: second vector for angle
	# vec_n: normal of the plane that vec a and vec b are on
	# vec_flip_a: first vector for flip angle
	# vec_flip_b: second vector for flip angle
	# vec_flip_n: normal of the plane that vec flip a and vec flip b are on
	
	# here's a good explanation on why getting the signed alpha with atan2 works:
	# https://stackoverflow.com/questions/5188561/signed-angle-between-two-3d-vectors-with-same-origin-within-the-same-plane

	# calculate signed angle
	var this_basis_vec_comp = vec_a.slide(vec_n)
	var cross = vec_b.cross(this_basis_vec_comp)
	
	var dot = this_basis_vec_comp.dot(vec_b)
	var final_angle = atan2(cross.dot(vec_n), dot)
	
	return final_angle


func blocks_angle(vec_a, vec_b, vec_n, vec_flip_a = Vector3(), vec_flip_b = Vector3(), vec_flip_n = Vector3()) -> Array:
	# this method calculates the signed angle between vec_a and vec_b on the plane with normal vec_n
	# it also calculates the "flip angle" vec_flip_a and vec_flip_b
	# on the plane vec_flip_n, which is either PI or 0.
	#
	# where
	# vec_a: first vector for angle
	# vec_b: second vector for angle
	# vec_n: normal of the plane that vec a and vec b are on
	# vec_flip_a: first vector for flip angle
	# vec_flip_b: second vector for flip angle
	# vec_flip_n: normal of the plane that vec flip a and vec flip b are on
	
	# here's a good explanation on why getting the signed alpha with atan2 works:
	# https://stackoverflow.com/questions/5188561/signed-angle-between-two-3d-vectors-with-same-origin-within-the-same-plane

	var flip_angle := 0.0
	var cross : Vector3
	
	# calculate flip angle
	var this_basis_vec_flip_comp = vec_flip_a.slide(vec_flip_n)
	var flip_cos = this_basis_vec_flip_comp.dot(vec_flip_b)
	
	# calculate signed angle
	var this_basis_vec_comp = vec_a.slide(vec_n)
	if flip_cos < 0:
		cross = this_basis_vec_comp.cross(vec_b)
		flip_angle = PI
	else:
		cross = vec_b.cross(this_basis_vec_comp)
	
	var dot = this_basis_vec_comp.dot(vec_b)
	var final_angle = atan2(cross.dot(vec_n), dot)
	
	return [final_angle, flip_angle]


# snaps to the other block over time, updating position and rotation
func update_pos_to_snap(delta: float) -> void:
	snap_timer += delta
	interpolation_progress = snap_timer * snap_speed
	
	if interpolation_progress > 1.0:
		# set final pos
		global_transform = snap_end_transform
		moving_to_snap = false
		snap_timer = 0.0
#		check_snap_areas()
		play_snap_sound()
#		multi_mesh_add()
		var transfered_area = transfer_col_shape()
		multi_mesh.add_area(transfered_area)
		queue_free()
#		if other_area_parent:
#			other_area_parent.multi_mesh_add()
#			other_area_parent.queue_free()
#		other_area_parent = null
#		snap_cand = null
		return
	
	global_transform = snap_start_transform.interpolate_with(snap_end_transform, interpolation_progress)


func transfer_col_shape() -> Area:
	# frees this node and transfers SnapAreas to AllSnapAreas and creates an Area with CollisionShape
	# transfer SnapAreas
#	for s in snap_areas_children:
#		all_snap_areas.add_snap_area(s)
	
	# create Area with CollisionShape
	return all_block_areas.add_block_area($CollisionShape)

	

func multi_mesh_add():
	multi_mesh.add_area(self)
	on_multi_mesh = true
#	visible = false
#	set_process(false)
#	set_physics_process(false)


#func multi_mesh_remove():
#	if on_multi_mesh:
#		multi_mesh.remove_block(self)
#		on_multi_mesh = false
#		visible = true
#		set_process(true)
#		set_physics_process(true)
	

func play_snap_sound():
	if snap_sound and audio_stream_player:
		audio_stream_player.set_stream(snap_sound)
		audio_stream_player.play()


# checks if there are still overlapping children or not
func update_overlapping():
#	var overlapping_status = false
#
#	for child in held_snap_areas_children:
#		if child is HeldSnapArea:
#			if child.get_overlapping():
#				overlapping_status = true
#				break
#
#	overlapping = overlapping_status
	pass


#func spawn_measure_point(
#	connection_side : int,
#	connection_id : String,
#	other_block : BuildingBlockSnappable,
#	other_connection_side: int,
#	snap_area_pos : Vector3
#) -> void:
#
#	# check if there's already a measure point in this block
#	if volt_measure_points.has(connection_side):
#		# if yes, add connection id
#		volt_measure_points[connection_side].add_connection_id(connection_id)
#		update_measure_point_pos(connection_side, snap_area_pos)
#		return
#
#	# or the other block
#	if other_block.volt_measure_points.has(other_connection_side):
#		volt_measure_points[connection_side] = other_block.volt_measure_points[other_connection_side]
#		volt_measure_points[connection_side].add_connection_id(connection_id)
#		update_measure_point_pos(connection_side, snap_area_pos)
#		return
#
#	# if not, create a new one
#	var current_mp = measure_point_scene.instance()
#	all_measure_points.add_child(current_mp)
#	volt_measure_points[connection_side] = current_mp
#
#	current_mp.global_transform.origin = snap_area_pos + Vector3(0, 0.15, 0)
#	current_mp.global_transform.basis = global_transform.basis
#
#	# update connection_id
#	current_mp.set_measure_point_type(MeasurePoint.MeasurePointType.CONNECTION)
#	current_mp.add_connection_id(connection_id)
#
#	# add reference to other block, too
#	other_block.add_measure_point_ref(other_connection_side, current_mp)


# called after the other block spawned the measure point
#func add_measure_point_ref(connection_side : int, measure_point: MeasurePoint) -> void:
#	volt_measure_points[connection_side] = measure_point
#
#
#func destroy_measure_point(
#	connection_side : int,
#	connection_id : String,
#	other_block : BuildingBlockSnappable,
#	other_connection_side: int
#):
#
#	# destroy if one connection id, else remove connection id
#	if !volt_measure_points.has(connection_side):
#		print("Wanted to destroy Measure Point, but none found")
#		return
#
#	var current_mp = volt_measure_points[connection_side]
#
#	if current_mp.connection_ids.size() > 1:
#		current_mp.remove_connection_id(connection_id)
#	else:
#		current_mp.queue_free()
#		volt_measure_points.erase(connection_side)
#		other_block.volt_measure_points.erase(other_connection_side)
#
#
#func update_measure_point_pos(connection_side : int, snap_area_pos : Vector3):
#	if !volt_measure_points.has(connection_side):
#		return
#	var old_pos = volt_measure_points[connection_side].global_transform.origin
#	var new_pos = lerp(old_pos, snap_area_pos + Vector3(0, 0.15, 0), 0.5)
#	volt_measure_points[connection_side].global_transform.origin = new_pos
