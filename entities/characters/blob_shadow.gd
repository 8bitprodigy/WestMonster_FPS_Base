extends RayCast3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var air_gap = (global_position.y - get_collision_point().y)/2
	$Decal.global_position.y = get_collision_point().y + air_gap
	$Decal.extents.y = air_gap + 0.1
	pass
