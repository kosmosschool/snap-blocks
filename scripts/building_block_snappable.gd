extends BuildingBlock


# this building block can snap!
class_name BuildingBlockSnappable


signal block_snapped_updated

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
#var collision_switching := false
#var collision_switch_timer := 0.0
#var prev_collision_mask


onready var held_snap_areas = $HeldSnapAreas
onready var held_snap_areas_children = held_snap_areas.get_children()
onready var snap_areas = $SnapAreas
onready var snap_areas_children = snap_areas.get_children()
onready var all_children = get_children()
onready var audio_stream_player := $AudioStreamPlayer3D
onready var snap_sound := preload("res://sounds/magnetic_click.wav")
onready var all_measure_points := get_node(global_vars.ALL_MEASURE_POINTS_PATH)
onready var multi_mesh := get_node(global_vars.MULTI_MESH_PATH)
onready var measure_point_scene = load(global_vars.MEASURE_POINT_FILE_PATH)
onready var all_snap_areas := get_node(global_vars.ALL_SNAP_AREAS_PATH)
onready var all_block_areas := get_node(global_vars.ALL_BLOCK_AREAS_PATH)

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
	
	if !is_grabbed:
		show_held_snap_areas(false)
		set_process(false)
		set_physics_process(false)
	
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
		


func _on_Building_Block_Snappable_grab_started():
	show_held_snap_areas(true)
	set_process(true)
	set_physics_process(true)
#	multi_mesh_remove()


func _on_Building_Block_Snappable_grab_ended():
	if !overlapping:
		set_process(false)
		set_physics_process(false)
		show_held_snap_areas(false)
	


func _on_SnapArea_area_snapped():
	update_snapped_status()


func _on_SnapArea_area_unsnapped():
	update_snapped_status()


func update_snapped_status():
	# update status if all areas are unsnapped or min. 1 is snapped
	var snapped_status = false
	
	for child in all_children:
		if child is SnapArea:
			if child.get_snapped():
				snapped_status = true
				break
	
	snapped = snapped_status


func show_held_snap_areas(show: bool) -> void:
	for held_snap_area in held_snap_areas_children:
		if held_snap_area is HeldSnapArea:
			held_snap_area.visible = show


func connect_to_snap_area_signals():	
	for child in snap_areas_children:
		if child is SnapArea:
			child.connect("area_snapped", self, "_on_SnapArea_area_snapped")
			child.connect("area_unsnapped", self, "_on_SnapArea_area_unsnapped")


# after it moved to position, we need to check with snap areas are now overlapping
func check_snap_areas() -> void:
	for child in snap_areas_children:
		if child is SnapArea:
			if !child.get_snapped():
				child.start_double_check_snap()


# unsnaps all areas (needed for deleting block)
func unsnap_all() -> void:
	for child in snap_areas_children:
		if child is SnapArea:
			child.unsnap_both()


func snap_to_block(this_snap_area: Area, other_snap_area: Area):
	# note tht this_snap_area is a HeldSnapArea and other_snap_area is a SnapArea
	snap_start_transform = global_transform
	
	# get other area's parent transform
	var other_area_parent_transform = all_snap_areas.get_parent_transform(other_snap_area)
	
	var add_other_parent := false
	var other_snap_area_parent
	if not other_area_parent_transform:
		# in this case the parent block is probably not part of a multi mesh, so add it
		other_snap_area_parent = other_snap_area.get_parent().get_parent()
		if not other_snap_area_parent as BuildingBlockSnappable:
			return
		
		other_area_parent_transform = other_snap_area_parent.get_transform()
		add_other_parent = true

#	other_area_parent = other_snap_area.get_parent()
	var start_rotation = rotation
	
	# orthonormalize just to be sure
	var this_basis = transform.basis.orthonormalized()
#	var other_block_basis = other_area_parent.transform.basis.orthonormalized()
	var other_block_basis = other_area_parent_transform.basis.orthonormalized()
	
	# we need to find out the local x rotation of the this block
	# it depends on the relative difference to the x rotation of the other block
	var x_rotation_new : float
	var y_rotation_new : float
	var z_rotation_new : float
	var x_rotation_extra : float
	var y_rotation_extra : float
	var z_rotation_extra : float

	
	if (this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH):
		
		# for a width-to-width snap, we use the angle between the local bases y vectors to accomplish this
		# we need to make sure that we get the two y vectors on a y-z plane, so we take the x vector component
		# of this block
		var angles = blocks_angle(
			this_basis.y,
			other_block_basis.y,
			other_block_basis.x,
			this_basis.x,
			other_block_basis.x,
			other_block_basis.y
		)
		
		x_rotation_new = snap_rotation(angles[0])
		y_rotation_extra = angles[1]


	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A) or
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C)):
		# for width-to-length_a snap, we again need the angle between the y vectors, but this time on the y-x plane

		var angles = blocks_angle(
			this_basis.y,
			other_block_basis.y,
			other_block_basis.z,
			this_basis.x,
			other_block_basis.z,
			other_block_basis.y
		)
		
		x_rotation_new = snap_rotation(angles[0])
		y_rotation_extra = angles[1]
		
		# we need to add the rotation extra beause this snap is always at a 90° (width to length)
		y_rotation_extra -= (PI / 2)
	
	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B) or
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D)):
		# for width-to-length_b snap, we again need the angle between the y vectors, but this time on the y-x plane

		var angles = blocks_angle(
			this_basis.z,
			other_block_basis.z,
			other_block_basis.y,
			this_basis.x,
			other_block_basis.y,
			other_block_basis.z
		)
		
		x_rotation_new = snap_rotation(angles[0])
		z_rotation_extra = angles[1]
		
		# we need to add the rotation extra beause this snap is always at a 90° (width to length)
		z_rotation_extra += (PI / 2)
	
	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH) or
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH)):
		# for width-to-length_a snap, we again need the angle between the y vectors, but this time on the y-x plane

		var angles = blocks_angle(
			this_basis.y,
			other_block_basis.y,
			other_block_basis.x,
			this_basis.z,
			other_block_basis.x,
			other_block_basis.y
		)
		
		z_rotation_new = snap_rotation(angles[0])
		y_rotation_extra = angles[1]
		
		# we need to add the rotation extra beause this snap is always at a 90° (width to length)
		y_rotation_extra += (PI / 2)
	
	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH) or
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH)):
		# for width-to-length_a snap, we again need the angle between the y vectors, but this time on the y-x plane

		var angles = blocks_angle(
			this_basis.z,
			other_block_basis.y,
			other_block_basis.x,
			this_basis.y,
			other_block_basis.x,
			other_block_basis.y
		)
		
		y_rotation_new = snap_rotation(angles[0])
		z_rotation_extra = angles[1]
		
		# we need to add the rotation extra beause this snap is always at a 90° (width to length)
		x_rotation_extra -= (PI / 2)
		z_rotation_extra -= (PI / 2)
	
	if (this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D):
		# for width-to-length_d snap, we again need the angle between the y vectors, but this time on the y-z plane
		
		var angles = blocks_angle(
			this_basis.z,
			other_block_basis.z,
			other_block_basis.y,
			this_basis.x,
			other_block_basis.y,
			other_block_basis.z
		)
		
		x_rotation_new = snap_rotation(angles[0])
		
		z_rotation_extra = angles[1]
		# we need to add the rotation extra beause this snap is always at a 90° (width to length)
		z_rotation_extra += (PI / 2)
	
	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A) or
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A) or 
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C) or
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C)):
		
		var angles = blocks_angle(
			this_basis.y,
			other_block_basis.y,
			other_block_basis.z,
			this_basis.z,
			other_block_basis.z,
			other_block_basis.y
		)
		
		z_rotation_new = snap_rotation(angles[0])
		y_rotation_extra = angles[1]

	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A) or
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A) or
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C) or
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C)):
		
		var angles = blocks_angle(
			this_basis.x,
			other_block_basis.x,
			other_block_basis.z,
			this_basis.y,
			other_block_basis.z,
			other_block_basis.y
		)
		
		y_rotation_new = snap_rotation(angles[0])
		x_rotation_extra = angles[1]
		
		x_rotation_extra += (PI / 2)
	
	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D) or
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D) or
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_A
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B) or 
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_C
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B)):
		
		var angles = blocks_angle(
			this_basis.x,
			other_block_basis.x,
			other_block_basis.y,
			this_basis.z,
			other_block_basis.y,
			other_block_basis.z
		)
		
		z_rotation_new = snap_rotation(angles[0])
		x_rotation_extra = angles[1]
		
		x_rotation_extra -= (PI / 2)
	
	if ((this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D) or
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D) or
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B) or 
			(this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_D
			and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH_B)):
		
		var angles = blocks_angle(
			this_basis.x,
			other_block_basis.x,
			other_block_basis.y,
			this_basis.y,
			other_block_basis.y,
			other_block_basis.z
		)
		
		y_rotation_new = snap_rotation(angles[0])
		x_rotation_extra = angles[1]

	
	transform.basis = other_block_basis
	
	rotate_object_local(Vector3(1, 0, 0), x_rotation_extra)
	rotate_object_local(Vector3(0, 1, 0), y_rotation_extra)
	rotate_object_local(Vector3(0, 0, 1), z_rotation_extra)
	
	rotate_object_local(Vector3(1, 0, 0), x_rotation_new)
	rotate_object_local(Vector3(0, 1, 0), y_rotation_new)
	rotate_object_local(Vector3(0, 0, 1), z_rotation_new)
	
	snap_end_transform.basis = global_transform.basis
	
	var this_snap_area_ext = this_snap_area.get_node("CollisionShape").shape.extents
#	var other_snap_area_ext = other_snap_area.get_node("CollisionShape").shape.extents
	var extra_move_by = this_snap_area.global_transform.basis.z * this_snap_area_ext.z
	var move_by_vec = other_snap_area.global_transform.origin - this_snap_area.global_transform.origin + extra_move_by
	snap_end_transform.origin = global_transform.origin + move_by_vec
	
	global_transform = snap_start_transform
	
	set_mode(RigidBody.MODE_KINEMATIC)
	moving_to_snap = true
	overlapping = false
	show_held_snap_areas(false)
	
	if add_other_parent:
		# also add other parent ot multi_mesn
		other_snap_area_parent.multi_mesh_add()
		other_snap_area_parent.free_and_transfer()


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
		multi_mesh_add()
		free_and_transfer()
#		if other_area_parent:
#			other_area_parent.multi_mesh_add()
#			other_area_parent.queue_free()
#		other_area_parent = null
		return
	
	global_transform = snap_start_transform.interpolate_with(snap_end_transform, interpolation_progress)


func free_and_transfer() -> void:
	# frees this node and transfers SnapAreas to AllSnapAreas and creates an Area with CollisionShape
	# transfer SnapAreas
	for s in snap_areas_children:
		all_snap_areas.add_snap_area(s)
	
	# create Area with CollisionShape
	all_block_areas.add_block_area($CollisionShape)
	
	# ademässi
	queue_free()
	

func multi_mesh_add():
	multi_mesh.add_block(self)
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
	var overlapping_status = false
	
	for child in held_snap_areas_children:
		if child is HeldSnapArea:
			if child.get_overlapping():
				overlapping_status = true
				break
	
	overlapping = overlapping_status


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
