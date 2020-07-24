extends Spatial



# Called when the node enters the scene tree for the first time.
func _ready():
	movement_system.initialize_movement()
	save_system.initialize_save()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
