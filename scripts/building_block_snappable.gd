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


onready var held_snap_areas = $HeldSnapAreas
onready var held_snap_areas_children = held_snap_areas.get_children()
onready var all_children = get_children()
onready var snap_sound := $AudioStreamPlayer3DSnap
onready var all_measure_points := get_node(global_vars.ALL_MEASURE_POINTS_PATH)
onready var measure_point_scene = load(global_vars.MEASURE_POINT_FILE_PATH)

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
	if !is_grabbed:
		show_held_snap_areas(false)


func _process(delta):
	
	if is_grabbed:
		show_held_snap_areas(true)
	elif !is_grabbed and !overlapping:
		show_held_snap_areas(false)
	
	if moving_to_snap:
		update_pos_to_snap(delta)


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
	for child in all_children:
		if child is SnapArea:
			child.connect("area_snapped", self, "_on_SnapArea_area_snapped")
			child.connect("area_unsnapped", self, "_on_SnapArea_area_unsnapped")


# after it moved to position, we need to check with snap areas are now overlapping
func check_snap_areas() -> void:
	for child in all_children:
		if child is SnapArea:
			if !child.get_snapped():
				child.start_double_check_snap()


# unsnaps all areas (needed for deleting block)
func unsnap_all() -> void:
	var all_children = get_children()
	
	for child in all_children:
		if child is SnapArea:
			child.unsnap_both()


func snap_to_block(this_snap_area: Area, other_snap_area: Area):
	# note tht this_snap_area is a HeldSnapArea and other_snap_area is a SnapArea
	snap_start_transform = global_transform

	var other_area_parent = other_snap_area.get_parent()
	# move to far position but in right direction
	#global_transform.origin += other_snap_area.global_transform.basis.z.normalized() * 1000

	# rotate it so that this z-vector is aligned with other areas
	# z-vector, but in the opposite direction
	#global_transform = this_snap_area.global_transform.looking_at(other_snap_area.global_transform.origin, Vector3(0, 1, 0))
	
#	global_transform.basis = other_snap_area.global_transform.basis
	# rotate by 180° degrees
#	rotate_y(PI)

	# rotate by local y transform also
#	rotate_y(-this_snap_area.rotation.y)

	# move to close pos
	# assuming other area's has a CollisionShape child and parent has CollisionShape child
#	var this_snap_area_extents = this_snap_area.get_node("CollisionShape").shape.extents
#	var other_snap_area_extents = other_snap_area.get_node("CollisionShape").shape.extents
#
#	var move_by_vec = other_snap_area.global_transform.origin - this_snap_area.global_transform.origin
#	move_by_vec -= other_snap_area.global_transform.basis.z.normalized() * (this_snap_area_extents.z - 0.001)
#	global_transform.origin += move_by_vec

	# assign back
#	snap_end_transform = global_transform
#	global_transform = snap_start_transform
#	var other_block_rotation = current_other_area_parent_block.rotation
	var start_rotation = rotation
	
	# start with other block's rotation
	var new_rotation = other_area_parent.rotation
	
	# orthonormalize just to be sure
	var this_basis = transform.basis.orthonormalized()
	var other_block_basis = other_area_parent.transform.basis.orthonormalized()
	
#	this_snap_global_basis.z.x = 0
#	other_snap_global_basis.z.x = 0

#	var projection = transform.basis.y.project(other_area_parent.transform.basis.y)
#	var new_point = transform.basis.y - projection

#	print("other_area_parent.transform.basis.y ", other_area_parent.transform.basis.y)
#	print("new_point ", new_point)
	
#	new_point.x = 0
#	other_area_parent.transform.basis.y.x = 0
	
	# we need to find out the local x rotation of the this block
	# it depends on the relative difference to the x rotation of the other block
	var x_rotation_diff : float
	var y_rotation_diff : float
	var z_rotation_diff : float
	var y_rotation_extra : float
	var angle_sign_indicator : float
	
	if (this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
		and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH):
		# for a width-to-width snap, we use the angle between the local bases y direction to accomplish this
		# to make sure we are not affected by other rotation, we take the other block's basis' x component
		# of this basis
		var this_basis_y_comp = this_basis.y.slide(other_block_basis.x)
	
		# the angle we're getting here is unsigned
		x_rotation_diff = this_basis_y_comp.angle_to(other_block_basis.y)
		# we need this to figure out the sign of the angle
		angle_sign_indicator = this_basis_y_comp.z - other_block_basis.y.z
	
	
	if (this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
		and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH):
		# for a width-to-length snap, we use the angle between the local bases y direction to accomplish this
		# to make sure we are not affected by other rotation, we take the other block's basis' x component
		# of this basis
		rotate_object_local(Vector3(1, 0, 0), - (PI / 2))
		this_basis = transform.basis.orthonormalized()
		var this_basis_y_comp = this_basis.y.slide(other_block_basis.z)
		
		# we need this to figure out the sign of the angle
		angle_sign_indicator = this_basis_y_comp.y - other_block_basis.x.y
#		print("angle_sign_indicator ", this_basis_y_comp - other_block_basis.x)
		
		# the angle we're getting here is unsigned
		x_rotation_diff = this_basis_y_comp.angle_to(other_block_basis.x)
		print("first  angle ", x_rotation_diff)
#		if angle_sign_indicator > 0:
#			x_rotation_diff -= (PI / 2)
#		else:
#			x_rotation_diff += (PI / 2)
#		x_rotation_diff -= (PI / 2)
		
		rotate_object_local(Vector3(1, 0, 0), (PI / 2))
		y_rotation_extra = - (PI / 2)
	
	
	print("angle ", x_rotation_diff)
	# figure out x rotation snap
	if abs(x_rotation_diff) >= 0 and abs(x_rotation_diff) < (PI / 4):
		print("1")
		x_rotation_diff = 0
	elif abs(x_rotation_diff) >= (PI / 4) and abs(x_rotation_diff) < (PI / 2):
		print("2")
		x_rotation_diff = PI / 2
	elif abs(x_rotation_diff) >= (PI / 2) and abs(x_rotation_diff) < (PI * 3 / 4):
		print("3")
		x_rotation_diff = PI / 2
	elif abs(x_rotation_diff) >= (PI * 3 / 4):
		print("4")
		x_rotation_diff = PI
	
	# sign angle
	if angle_sign_indicator < 0:
		x_rotation_diff *= -1
	
	print("x_rotation_diff ", x_rotation_diff)
	
	# update new_rotation
#	new_rotation.x = x_rotation_diff
	
	
#	if (this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH
#		and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH):
#		# add 90°
#		new_rotation.y += (PI / 2)
#
#	if (this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
#		and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.LENGTH):
#			# add 90°
#			new_rotation.y += (PI / 2)
#
#	# this is for top and bottom snap areas
#	if (this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.TOP
#		and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.TOP):
#			if abs(new_rotation.y) > PI / 4 and abs(new_rotation.y) <= PI / 2:
#				# add 90°
#				new_rotation.y += (PI / 2)
#			elif abs(new_rotation.y) > PI / 2 and abs(new_rotation.y) < PI * 3 / 4:
#				new_rotation.y -= (PI / 2)
#
#	if (this_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.WIDTH
#		and other_snap_area.location_on_block == HeldSnapArea.LocationOnBlock.TOP):
#		new_rotation.z -= (PI / 2)
#
#		if abs(new_rotation.y) > PI / 4 and abs(new_rotation.y) <= PI / 2:
#			# add 90°
#			new_rotation.y += (PI / 2)
#		elif abs(new_rotation.y) > PI / 2 and abs(new_rotation.y) < PI * 3 / 4:
#			new_rotation.y -= (PI / 2)
	
	# to make sure that it doesn't do a full 180° when snapping the other side
#	if abs(new_rotation.y) > PI / 2:
#		new_rotation.y -= PI
#
#	# to make sure that it doesn't do a full 180° when snapping the other side
#	if abs(new_rotation.z) > PI / 2:
#		new_rotation.z -= PI
#
#	# to make sure that it doesn't do a full 180° when snapping the other side
#	if abs(new_rotation.x) > PI / 2:
#		new_rotation.x -= PI
	
	
	transform.basis = other_block_basis
	
	rotate_object_local(Vector3(0, 1, 0), y_rotation_extra)
	
	rotate_object_local(Vector3(1, 0, 0), x_rotation_diff)
	
#	print("new rotation ", rotation)
	
	
	snap_end_transform.basis = global_transform.basis
	
	var move_by_vec = other_snap_area.global_transform.origin - this_snap_area.global_transform.origin
	snap_end_transform.origin = global_transform.origin + move_by_vec
	
	global_transform = snap_start_transform
	
	set_mode(RigidBody.MODE_KINEMATIC)
	moving_to_snap = true
	overlapping = false
	show_held_snap_areas(false)


# snaps to the other block over time, updating position and rotation
func update_pos_to_snap(delta: float) -> void:
	snap_timer += delta
	interpolation_progress = snap_timer * snap_speed
	
	if interpolation_progress > 1.0:
		# set final pos
		global_transform = snap_end_transform
		moving_to_snap = false
		snap_timer = 0.0
		check_snap_areas()
		if snap_sound:
			snap_sound.play()
#		set_mode(RigidBody.MODE_RIGID)
		return
	
	global_transform = snap_start_transform.interpolate_with(snap_end_transform, interpolation_progress)


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
