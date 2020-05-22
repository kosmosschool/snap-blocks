extends Spatial


# tooltip. e.g, used for tutorial
class_name Tooltip


var attach_to_node : Node
var spheres_array : Array
var secondary_spheres_array : Array
var sphere_distance := 0.02
var prev_secondary_dist : float

onready var bubble = $Bubble
onready var line = $Line
onready var text_label = get_node("Bubble/2DTextLabel")
onready var camera = get_node(global_vars.AR_VR_CAMERA_PATH)
onready var tooltip_sphere_scene = preload("res://scenes/tooltip_sphere.tscn")

export(NodePath) var attach_to_path setget set_attach_to_path
export(Vector3) var bubble_offset = Vector3(-0.15, 0.1, -0.03)
export(Vector3) var line_attach_to_offset = Vector3(0, -0.02, -0.03) setget set_line_attach_to_offset
export(Vector3) var line_bubble_offset = Vector3(0.05, -0.05, 0)
export(bool) var secondary_line = false setget set_secondary_line
export(Vector3) var secondary_line_bubble_offset = Vector3(-0.05, -0.05, 0)
export(Vector3) var secondary_line_start_pos = Vector3(0, 0, 0)


func set_attach_to_path(new_value):
	attach_to_path = new_value
	if attach_to_path != "":
		attach_to_node = get_node(attach_to_path)
		update_position()
		create_primary_spheres(true)


func set_line_attach_to_offset(new_value):
	line_attach_to_offset = new_value


func set_secondary_line(new_value):
	secondary_line = new_value
	if secondary_line:
		update_position()
		create_secondary_spheres(true)


func _ready():
#	attach_to_path = global_vars.CONTR_RIGHT_PATH
	
	# get attach_to_node and calculate line length
	if attach_to_path != "":
		attach_to_node = get_node(attach_to_path)
		update_position()
		spheres_array = create_primary_spheres()
		if secondary_line:
			create_secondary_spheres()


func _process(delta):
	if not attach_to_node:
		return
	
	# update rotation and position
	update_position()
	
	# update mesh instance line position, size and rotation
	var attach_to_position = attach_to_node.global_transform.origin
	var line_start_pos = attach_to_position + attach_to_node.transform.basis * line_attach_to_offset
	var line_end_pos = bubble.global_transform.origin + bubble.transform.basis * line_bubble_offset
	
	update_spheres_pos(spheres_array, line_start_pos, line_end_pos)
	
	if secondary_line:
		var secondary_line_end_pos = bubble.global_transform.origin + bubble.transform.basis * secondary_line_bubble_offset
		# check if distance changed (because it's not fixed)
		var secondary_dist = secondary_line_start_pos.distance_to(secondary_line_end_pos)
		if abs(secondary_dist - prev_secondary_dist) > sphere_distance:
			create_secondary_spheres(true)
			prev_secondary_dist = secondary_dist
		update_spheres_pos(secondary_spheres_array, secondary_line_start_pos, secondary_line_end_pos)


func update_position():
	var new_pos = attach_to_node.global_transform.origin + camera.transform.basis * bubble_offset
	global_transform.origin = new_pos
	
	bubble.look_at(camera.global_transform.origin, Vector3(0, 1, 0))
	bubble.rotate_object_local(Vector3(0, 1, 0), PI)


func update_spheres_pos(current_array, line_start_pos, line_end_pos) -> void:
	for i in range(current_array.size()):
		var curr_pos = line_start_pos.linear_interpolate(
			line_end_pos,
			float(i + 1) / current_array.size()
		)
		current_array[i].global_transform.origin = curr_pos


func set_text(new_text):
	text_label.set_text(new_text)


func create_primary_spheres(recreate = false):
	if recreate:
		# delete first
		for s in spheres_array:
			s.queue_free()
			
	# calculate line length and spawn spheres
	var attach_to_position = attach_to_node.global_transform.origin
	var line_start_pos = attach_to_position + attach_to_node.transform.basis * line_attach_to_offset
	var line_end_pos = bubble.global_transform.origin + bubble.transform.basis * line_bubble_offset
	spheres_array = create_spheres(line_start_pos, line_end_pos)


func create_secondary_spheres(recreate = false):
	if recreate:
		# delete first
		for s in secondary_spheres_array:
			s.queue_free()
		
	var line_end_pos = bubble.global_transform.origin + bubble.transform.basis * secondary_line_bubble_offset
	secondary_spheres_array = create_spheres(secondary_line_start_pos, line_end_pos)


func create_spheres(line_start_pos, line_end_pos) -> Array:
	var line_distance = line_start_pos.distance_to(line_end_pos)
	var n_spheres = int(line_distance / sphere_distance)
	var return_array : Array
	
	for i in range(n_spheres):
		var sphere_instance = tooltip_sphere_scene.instance()
		line.add_child(sphere_instance)
		return_array.append(sphere_instance)
	
	return return_array
