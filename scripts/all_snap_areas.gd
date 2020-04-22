extends Spatial


# logic to deal with SnapAreas that have been transferred to this node
class_name AllSnapAreas


var snap_area_index : Dictionary


func add_snap_area(snap_area : SnapArea) -> void:
	# add to dictionary along with the parent blocks's transform
	snap_area_index[snap_area] = snap_area.get_parent().get_parent().get_transform()
	
	var snap_area_global_transform = snap_area.get_global_transform()
	snap_area.get_parent().remove_child(snap_area)
	add_child(snap_area)
	snap_area.global_transform = snap_area_global_transform
	
	# make sure it's not monitoring
	snap_area.monitoring = false


func get_parent_transform(snap_area : SnapArea):
	# returns input SnapArea's parent transform or null
	
	if snap_area_index.has(snap_area):
		return snap_area_index[snap_area]
	
	return null
