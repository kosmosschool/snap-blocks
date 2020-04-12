extends Area

# this area snaps the building block (which needs to be its parent) to another snap area
class_name SnapArea


signal area_snapped
signal area_unsnapped

var snap_area_other_area : Area
var other_area_parent_block
#var connection_id : String
var snap_speed := 10.0
var snap_timer := 0.0
var is_master := false
var start_double_check = false
var double_check_timer = 0.0
var snapped := false setget , get_snapped

onready var parent_block := get_parent()
#onready var schematic := get_node(global_vars.SCHEMATIC_PATH) 

#enum Polarity {UNDEFINED, POSITIVE, NEGATIVE}
#export (Polarity) var polarity
#enum ConnectionSide {A, B}
#export (ConnectionSide) var connection_side
enum LocationOnBlock {UNDEFINED, WIDTH, LENGTH_A, LENGTH_B, LENGTH_C, LENGTH_D}
export (LocationOnBlock) var location_on_block


func get_snapped():
	return snapped


# this is a hacky workaround because of this issue: https://github.com/godotengine/godot/issues/25252
func is_class(type):
	return type == "SnapArea" or .is_class(type)


func _ready():
	connect("area_exited", self, "_on_Snap_Area_area_exited")
	set_process(false)


func _process(delta):
#	check_for_removal()

	if start_double_check:
		double_check_timer += delta

		if double_check_timer > 0.25:
			double_check_snap()
			start_double_check = false
			double_check_timer = 0.0
			set_process(false)


func  _on_Snap_Area_area_exited(area):
	if !snap_area_other_area:
		return
	
	# we have to do this check because it's possible the other area was deleted in the meantime
	if !is_instance_valid(snap_area_other_area):
		return
	
	# if distance is greater, remove
	if is_master and snapped:
		snap_area_other_area.unsnap()
		unsnap()
	else:
		snap_area_other_area = null
		other_area_parent_block = null
	

# we use this custom method instead of the area_exited or get_overlapping_areas
# we need to do this because with the small collisionshapes we use
# the area keeps entering and exiting all the time (probably a bug in Godot)
#func check_for_removal():
#	if !snap_area_other_area:
#		return
#
#	# we have to do this check because it's possible the other area was deleted in the meantime
#	if !is_instance_valid(snap_area_other_area):
#		return
#
#
#	if other_area_distance() < 0.05:
#		return
#
#	# if distance is greater, remove
#	if is_master and snapped:
#		snap_area_other_area.unsnap()
#		unsnap()
#	else:
#		snap_area_other_area = null
#		other_area_parent_block = null


func unsnap():
#	if is_master:
#		parent_block.destroy_measure_point(
#			connection_side,
#			connection_id,
#			other_area_parent_block,
#			snap_area_other_area.connection_side
#		)
#		schematic_remove_connection()
	is_master = false
	snapped = false
	snap_area_other_area = null
	other_area_parent_block = null
#	connection_id = ""
	emit_signal("area_unsnapped")


# unsnaps this and the other block's snap area (called from parent)
func unsnap_both():
	if snap_area_other_area:
		snap_area_other_area.unsnap()
	unsnap()


# double checks if really not overlapping an area
# called from parent after every succesful snap
func start_double_check_snap():
	set_process(true)
	start_double_check = true


func double_check_snap() -> void:
	var overlapping_areas = get_overlapping_areas()
	
	for overlapping_area in overlapping_areas:
		if !(overlapping_area as SnapArea):
			continue
		
		if !overlapping_area.get_snapped():
			snapped = true
			overlapping_area.snapped = true
			snap_area_other_area = overlapping_area
			overlapping_area.snap_area_other_area = self
			other_area_parent_block = overlapping_area.get_parent()
			overlapping_area.other_area_parent_block = get_parent()
			is_master = true
			emit_signal("area_snapped")


func other_area_distance() -> float:
	return get_global_transform().origin.distance_to(snap_area_other_area.get_global_transform().origin)
	
