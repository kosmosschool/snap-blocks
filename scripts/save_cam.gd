extends Spatial


# logic for the camera that we use to take pics when saving Creations
class_name SaveCam


var z_offset = -0.05

onready var viewport = $Viewport
onready var camera = $Viewport/Camera
onready var mesh_instance = $MeshInstance
onready var cam_screen = get_parent().get_parent()


func _ready():
	connect("visibility_changed", self, "_on_Save_Cam_visibility_changed")


func _process(delta):
	# move camera with the MeshInstance
	camera.global_transform = mesh_instance.global_transform
	camera.global_transform.origin += mesh_instance.transform.basis.z * z_offset


func _on_Save_Cam_visibility_changed():
	if !is_visible_in_tree():
		set_process(false)
	else:
		set_process(true)


func save_picture():
	var img = viewport.get_texture().get_data()
	
	img.save_png(save_system.open_cover_pic_path)
	
	cam_screen.show_pic_confirmation()
