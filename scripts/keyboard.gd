extends Spatial


class_name Keyboard


var keyboard_layout = [
	["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
	["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
	["a", "s", "d", "f", "g", "h", "j", "k", "l"],
	["shift", "z", "x", "c", "v", "b", "n", "m"],
	["space"],
]

var start_offset = Vector3(-0.175, 0.05, 0.0)
var x_offset = 0.04
var y_offset = -0.04

onready var buttons_node = $Buttons
onready var key_button_scene = preload("res://scenes/ks_button_keyboard.tscn")

func _ready():
	init_keyboard()

func key_pressed(key_value : String):
	# called by individual keys
	pass


func init_keyboard():
	# initialize keyboard
	for row in range(keyboard_layout.size()):
		for col in range(keyboard_layout[row].size()):
			var keyboard_button = key_button_scene.instance()
			keyboard_button.transform.origin = start_offset + Vector3(col * x_offset, row * y_offset, 0)
			keyboard_button.set_key_value(keyboard_layout[row][col])
			
			buttons_node.add_child(keyboard_button)
			
