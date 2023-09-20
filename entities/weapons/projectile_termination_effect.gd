'''extends Resource
class_name ProjectileTerminator

@export var termination_scene : PackedScene

var projectile_transform : Transform3D
var collision_transform : Transform3D
var collision_normal : Vector3
var collider : Object

var node = Node.new()


func terminate(projectile_transform:Transform3D,collision_position:Vector3,collision_normal:Vector3,collider:Object):
	var scene = termination_scene.instantiate()
	node.get_node("/root/game/entities").add_child(scene)
	if scene is ProjectileTerminatorScene:
		scene.terminate_projectile(projectile_transform,collision_position,collision_normal,collider)
	else:
		scene.global_transform = Transform3D(projectile_transform.basis,collision_position)
	pass'''
