extends BuildingBlockSnappable

class_name Resistor

# in ohm
export var resistance := 0.0

var current := 0.0
var potential := 0.0
var superposition := {"connections": [], "direction": ""}

func _ready():
	pass

# children can implement this method
func refresh():
	pass


func get_class():
	return "Resistor"
