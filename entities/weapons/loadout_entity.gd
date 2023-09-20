extends Node3D
class_name LoadoutEntity

@export_node_path("CharacterController") var __controller
@export var controller = get_node(__controller) if __controller else null

func primary_function(_pressed:bool, _just_pressed:bool,_just_released:bool):
	pass

func secondary_function(_pressed:bool, _just_pressed:bool,_just_released:bool):
	pass

func _enter_tree():
	set_process(true)
	set_physics_process(true)

func _exit_tree():
	set_process(false)
	set_physics_process(false)

func set_controller(_controller : CharacterController):
	#prints("_Controller: ", _controller)
	controller = _controller
	#prints("Controller: ", controller)
