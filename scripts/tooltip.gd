extends Spatial


# tooltip. e.g, used for tutorial
class_name Tooltip


var attach_to_node : Node
var spheres_array : Array

onready var bubble = $Bubble
onready var line = $Line
onready var text_label = get_node("Bubble/2DTextLabel")
onready var camera = get_node(global_vars.AR_VR_CAMERA_PATH)

export(NodePath) var attach_to_path setget set_attach_to_path
export(Vector3) var bubble_offset = Vector3(-0.15, 0.1, -0.03)
export(Vector3) var line_attach_to_offset = Vector3(0, -0.02, -0.03) setget set_line_attach_to_offset
export(Vector3) var line_bubble_offset = Vector3(0.05, -0.05, 0)


func set_attach_to_path(new_value):
	attach_to_path = new_value
	if attach_to_path != "":
		attach_to_node = get_node(attach_to_path)


func set_line_attach_to_offset(new_value):
	line_attach_to_offset = new_value


func _ready():
#	attach_to_path = global_vars.CONTR_RIGHT_PATH
	
	# get attach_to_node and calculate line length
	if attach_to_path != "":
		attach_to_node = get_node(attach_to_path)
	
	spheres_array = [
		$Line/MeshInstanceSphere1,
		$Line/MeshInstanceSphere2,
		$Line/MeshInstanceSphere3,
		$Line/MeshInstanceSphere4,
		$Line/MeshInstanceSphere5,
	]


func _process(delta):
	if not attach_to_node:
		return
	
	# update rotation and position
	var new_pos = attach_to_node.global_transform.origin + camera.transform.basis * bubble_offset
	
	global_transform.origin = new_pos
	
	bubble.look_at(camera.global_transform.origin, Vector3(0, 1, 0))
	bubble.rotate_object_local(Vector3(0, 1, 0), PI)
	
	# update mesh instance line position, size and rotation
	var attach_to_position = attach_to_node.global_transform.origin
	var line_start_pos = attach_to_position + attach_to_node.transform.basis * line_attach_to_offset
	var line_end_pos = bubble.global_transform.origin + bubble.transform.basis * line_bubble_offset
	for i in range(spheres_array.size()):
		var curr_pos = line_start_pos.linear_interpolate(
			line_end_pos,
			float(i + 1) / spheres_array.size()
		)
		spheres_array[i].global_transform.origin = curr_pos
	

func set_text(new_text):
	text_label.set_text(new_text)
