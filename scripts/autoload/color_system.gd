extends Node


class_name ColorSystem


var current_color_names : Dictionary

var ALL_COLORS = {
	"violet": Vector3(0.3250, 0.2684, 0.7931),
	"blue": Vector3(0.2684, 0.5310, 0.7931),
	"blue_dark": Vector3(0.0154, 0.1332, 0.4563),
	"black": Vector3(0.007, 0.007, 0.007),
	"grey": Vector3(0.3250, 0.3250, 0.3250),
	"green": Vector3(0.0290, 0.3250, 0.2176),
	"green_dark": Vector3(0.0063, 0.1726, 0.1332),
	"olive": Vector3(0.1332, 0.2176, 0.1332),
	"brown_dark": Vector3(0.1, 0.0474, 0.0103),
	"brown": Vector3(0.2317, 0.105, 0.020),
	"orange": Vector3(1.0000, 0.3250, 0.0474),
	"red": Vector3(0.6994, 0.0474, 0.0474),
	"rose": Vector3(0.6994, 0.3250, 0.3250),
	"yellow": Vector3(0.8933, 0.8933, 0.2176),
	"white": Vector3(1.0, 1.0, 1.0)
}


func _ready():
	current_color_names = {
		"right": ALL_COLORS.keys()[0],
		"left":  ALL_COLORS.keys()[0]
	}


# called by BaseController
func rotate_material(dir : int, side : String) -> void:
	if not current_color_names.has(side):
		print("rotate_material error: side must be right or left")
		return
	
	var keys = ALL_COLORS.keys()
	var i = keys.find(current_color_names[side])
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
		
	current_color_names[side] = keys[new_i]


func get_current_color(side : String) -> Vector3:
	if not current_color_names.has(side):
		print("get_current_color error: side must be right or left")
		return Vector3()
		
	return ALL_COLORS[current_color_names[side]]


func get_current_color_name(side : String) -> String:
	if not current_color_names.has(side):
		print("get_current_color_name error: side must be right or left")
		return ""
	
	return current_color_names[side]


func get_color_by_name(c_name) -> Vector3:
	if ALL_COLORS.has(c_name):
		return ALL_COLORS[c_name]
	
	# if not found return first color
	print("get_color_by_name not found, returning first color")
	return ALL_COLORS[ALL_COLORS.keys()[0]]
