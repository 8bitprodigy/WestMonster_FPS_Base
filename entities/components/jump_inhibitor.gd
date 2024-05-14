extends WM_Component
class_name jump_inhibitor


@export_category("Node Setup")
@export var jump_input_handler       : JumpInputHandler
@export_category("Jump Inhibitor Settings")
@export var disable_jump_signal_name : String
@export var enable_jump_signal_name  : String


func _ready():
	super._ready()
	if !(parent is InputHandler) or !jump_input_handler:
		super.set_enabled( false )
		return 
	parent.connect(disable_jump_signal_name, disable_jump)
	parent.connect(enable_jump_signal_name,  enable_jump)
	set_enabled(enabled)


func disable_jump():
	jump_input_handler.set_enabled(false)
	jump_input_handler.set_physics_process(true)


func enable_jump():
	jump_input_handler.set_enabled(true)
