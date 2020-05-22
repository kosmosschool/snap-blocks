extends Spatial


class_name ControllerColors


var current_color_name : String

var ALL_COLORS = {
	"violet": Vector3(0.3250, 0.2684, 0.7931),
	"blue": Vector3(0.2684, 0.5310, 0.7931),
	"blue_dark": Vector3(0.0154, 0.1332, 0.4563),
	"black": Vector3(0.0014, 0.0014, 0.0014),
	"grey": Vector3(0.3250, 0.3250, 0.3250),
	"green": Vector3(0.0290, 0.3250, 0.2176),
	"green_dark": Vector3(0.0063, 0.1726, 0.1332),
	"olive": Vector3(0.1332, 0.2176, 0.1332),
	"brown_dark": Vector3(0.1726, 0.0474, 0.0103),
	"brown": Vector3(0.4707, 0.1406, 0.0394),
	"orange": Vector3(1.0000, 0.3250, 0.0474),
	"red": Vector3(0.6994, 0.0474, 0.0474),
	"yellow": Vector3(0.6994, 0.3250, 0.3250),
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
