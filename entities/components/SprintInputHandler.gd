extends InputHandler


@export_category("Node Setup")
@export var movement_input_handler : MovementInputHandler
@export_category("Crouch Settings")
@export var SPRINT_SPEED         : float = 1000
@export var SPRINT_ACCELLERATION : float = 200
@export var SPRINT_FRICTION      : float = 7.5
# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	if !movement_input_handler:
		set_enabled(false)
		return
	set_enabled(enabled)



func handle_input( event : InputEvent ) -> void:
	if !(event is InputEventKey): return
	prints("Sprint handle_input entered!")
	if Input.is_action_just_pressed("sprint"):
		movement_input_handler.speed = SPRINT_SPEED
	if Input.is_action_just_released("sprint"):
		movement_input_handler.speed = movement_input_handler.SPEED
	super.handle_input(event)
