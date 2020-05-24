extends Spatial


# loads and hides used shaders at the start of the scene so they don't cause lag later
# just add a MeshInstance with a Material that uses the shader you want to cache as a child node to this
class_name ShaderCache


var count_down = 5

onready var all_meshes = get_children()


func _process(delta):
	if count_down == -1:
		return
	
	if count_down == 0:
		for m in all_meshes:
			m.visible = false
	
	count_down -= 1
