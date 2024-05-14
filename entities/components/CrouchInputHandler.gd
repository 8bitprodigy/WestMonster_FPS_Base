extends InputHandler
class_name CrouchInputHandler


var         stand_height           : float
var         standing_eye_height    : float
var         crouch_tween           : Tween

@export_category("Node Setup")
@export var character_bounding_box : CollisionShape3D
@export var look_input_handler     : LookInputHandler
@export var jump_input_handler     : JumpInputHandler
@export var movement_input_handler : MovementInputHandler

@export_category("Crouch Settings")
@export var crouch_height          : float = 0.5
@export var eye_margin             : float = 0.1
@export var time_to_crouch         : float = 0.25
@export var time_to_stand          : float = 0.5


signal crouched
signal crouching
signal standing
signal upright

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	if !(character_bounding_box and look_input_handler):
		set_enabled(false)
		return
	stand_height        = character_bounding_box.shape.size.y
	standing_eye_height = look_input_handler.height
	set_enabled(enabled)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta) -> void:
	
	pass

func handle_input( event : InputEvent ) -> void:
	if !(event is InputEventKey and character_bounding_box): return
	if Input.is_action_just_pressed("crouch"):
		emit_signal("crouching")
		#jump_input_handler.set_enabled(false)
		#jump_input_handler.set_physics_process(true)
		crouch_tween = create_tween().set_parallel(true)
		crouch_tween.tween_property(character_bounding_box, "shape/size/y", crouch_height,              time_to_crouch)
		crouch_tween.tween_property(character_bounding_box, "position/y",   crouch_height/2,            time_to_crouch)
		crouch_tween.tween_property(look_input_handler,     "height",       crouch_height - eye_margin, time_to_crouch)
		await crouch_tween.finished
		emit_signal("crouched")
		
	if Input.is_action_just_released("crouch"):
		emit_signal("standing")
		#jump_input_handler.set_enabled(true)
		crouch_tween = create_tween().set_parallel(true)
		crouch_tween.tween_property(character_bounding_box, "shape/size/y", stand_height,        time_to_crouch)
		crouch_tween.tween_property(character_bounding_box, "position/y",   stand_height/2,      time_to_crouch)
		crouch_tween.tween_property(look_input_handler,     "height",       standing_eye_height, time_to_crouch)
		await crouch_tween.finished
		emit_signal("upright")
	
	super.handle_input(event)
