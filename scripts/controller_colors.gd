extends Spatial


class_name ControllerColors


var current_color_name : String

var ALL_COLORS = {
	"violet": Vector3(0.6, 0.55, 0.9),
	"blue": Vector3(0.55, 0.75, 0.9),
	"blue_dark": Vector3(0.15, 0.4, 0.7),
	"black": Vector3(0.05, 0.05, 0.05),
	"grey": Vector3(0.6, 0.6, 0.6),
	"green": Vector3(0.2, 0.6, 0.5),
	"green_dark": Vector3(0.1, 0.45, 0.4),
	"olive": Vector3(0.4, 0.5, 0.4),
	"brown_dark": Vector3(0.45, 0.25, 0.125),
	"brown": Vector3(0.71, 0.41, 0.23),
	"orange": Vector3(1.0, 0.6, 0.25),
	"red": Vector3(0.85, 0.25, 0.25),
	"yellow": Vector3(0.95, 0.95, 0.5),
	"white": Vector3(1.0, 1.0, 1.0)
}


onready var mesh_instance = $MeshInstance


func _ready():
	current_color_name = ALL_COLORS.keys()[0]
	update_mini_block()


# called by ControllerDefault
func rotate_material(dir : int) -> void:
	var keys = ALL_COLORS.keys()
	var i = keys.find(current_color_name)
	var new_i
	
	if dir == 0:
		# next color
		if i + 1 == ALL_COLORS.size():
			new_i = 0
		else:
			new_i = i + 1
	elif dir == 1:
		# previous color
		if i == 0:
			new_i = ALL_COLORS.size() - 1
		else:
			new_i = i - 1
		
	current_color_name = keys[new_i]
	
	update_mini_block()


func update_mini_block() -> void:
	mesh_instance.get_surface_material(0).set_shader_param("color", get_current_color())


func get_current_color() -> Vector3:
	return ALL_COLORS[current_color_name]


func get_current_color_name() -> String:
	return current_color_name


func get_color_by_name(c_name) -> Vector3:
	if ALL_COLORS.has(c_name):
		return ALL_COLORS[c_name]
	
	# if not found return first color
	print("get_color_by_name not found, returning first color")
	return ALL_COLORS[ALL_COLORS.keys()[0]]
