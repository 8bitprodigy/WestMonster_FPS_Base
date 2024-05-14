extends InputHandler
class_name JumpInputHandler


var          queue_jump          : bool  = false

@export_category("Jump Settings")
@export  var auto_jump            : bool  = false

@export  var jump_height          : float = 1.5
@export  var jump_time_to_peak    : float = 0.5
@export  var jump_time_to_descend : float = 0.4

@onready var jump_gravity      : float = ( ( 2.0 * jump_height ) / pow( jump_time_to_peak, 2    ) )
@onready var fall_gravity      : float = ( ( 2.0 * jump_height ) / pow( jump_time_to_descend, 2 ) )
@onready var jump_velocity     : float = (   1.5 * jump_height ) / jump_time_to_peak # temporary fix
@onready var terminal_velocity : float = fall_gravity * 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	prints("Jump Gravity: ", jump_gravity, " | Fall Gravity: ", fall_gravity)
	parent.add_user_signal( "request_jump")
	set_enabled(enabled)


func _physics_process(delta) -> void:
	character.velocity.y -= get_gravity() * delta
	process_jump()

'''
func set_enabled( enabled_status : bool ) -> void:
	set_process_input(enabled_status)
	if !parent: return
	if enabled_status:
		parent.input_event.connect( handle_input, 1 )
	else:
		parent.input_event.disconnect( handle_input )
'''

func handle_input( event : InputEvent ) -> void:
	if !(event is InputEventKey): return
	if auto_jump:
		queue_jump = true if Input.is_action_pressed("jump") else false
		return
	
	if Input.is_action_just_pressed("jump"):
		queue_jump = true
	if Input.is_action_just_released("jump"):
		queue_jump = false
	
	super.handle_input(event)


func get_gravity() -> float:
	if character.is_on_floor(): return 0.0
	return jump_gravity if character.velocity.y > 0.0 else fall_gravity

func process_jump() -> void:
	if character.is_on_floor() and queue_jump:
		character.velocity.y = jump_velocity
		queue_jump = false


func is_jumping() -> bool:
	return character.is_on_floor() and character.velocity.y > 0.0
