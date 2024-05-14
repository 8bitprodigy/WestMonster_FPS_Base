extends Node
class_name WM_Component

@export var enabled : bool = true :
	set(value):
		set_enabled(value)
		enabled = value

@onready var parent : Node = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !parent:
		enabled = false
		set_enabled(false)
		return
	


func set_enabled( enabled_status : bool ) -> void:
	set_process(enabled_status)
	set_physics_process(enabled_status)
	set_process_input(enabled_status)
