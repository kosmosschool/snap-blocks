extends Spatial


# loads and frees used shaders at the start of the scene so they don't cause lag later
# just add a Node with a Material that uses the shader you want to cache as a child node to this
class_name ShaderCache


var count_down = 5
onready var camera = get_node(global_vars.AR_VR_CAMERA_PATH)

onready var all_children = get_children()

func _ready():
	for c in all_children:
		if c is Particles:
			c.set_emitting(true)


func _process(delta):
	if count_down == -1:
		return
		
	# place in front of camera
	if not camera:
		camera = get_node(global_vars.AR_VR_CAMERA_PATH)
		return
	
	if is_nan(camera.transform.basis.z.x):
		return
		
	global_transform.origin = camera.global_transform.origin - camera.transform.basis.z * 1.0
	
	if count_down == 0:
		queue_free()
	
	count_down -= 1
