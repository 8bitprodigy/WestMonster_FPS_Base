extends Node3D
class_name ProjectileTerminatorScene

var projectile_transform : Transform3D
var collision_position : Vector3
var collision_normal : Vector3
var collider : Object

func terminate_projectile(_projectile_transform:Transform3D,_collision_position:Vector3,_collision_normal:Vector3,_collider:Object):
	projectile_transform = _projectile_transform
	collision_normal = _collision_normal
	collision_position = _collision_position
	collider = _collider
	global_transform = Transform3D(projectile_transform.basis,collision_position)
	look_at(collision_position+collision_normal, global_transform.basis.z)
	reparent(collider,true)
