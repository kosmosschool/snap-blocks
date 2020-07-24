extends Spatial


var start := false
var timer := 0.0


onready var animation = $AnimationPlayer
onready var camera = $OQ_ARVROrigin/OQ_ARVRCamera
onready var screen = $MeshInstance
onready var y_value = 1.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not start:
		# create starting cube after a certain time to make sure it's aligned with the user height
		if timer > 0.3:
			start_animation()
			start = true
			timer = 0.0
			return
		
		timer += delta

func start_animation():
	
	if camera:
		if not is_nan(camera.transform.basis.x.x):
			y_value = camera.global_transform.origin.y - 0.1
				
		screen.global_transform.origin = Vector3(0, y_value, -1.4)
		screen.look_at(camera.global_transform.origin, Vector3(0, 1, 0))
		screen.rotate_y(PI)
		animation.play("SplashScreen") 
