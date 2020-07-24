extends Spatial


# Called when the node enters the scene tree for the first time.
func _ready():
	# initiliaze OQ Toolkit
	vr.initialize();
	
	vr.scene_switch_root = self
	vr.switch_scene("res://scenes/splash_screen.tscn", 0.0, 0.0)
	vr.switch_scene("res://scenes/game.tscn", 0.0, 5.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


