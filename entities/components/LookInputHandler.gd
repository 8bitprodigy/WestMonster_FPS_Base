extends InputHandler
class_name LookInputHandler


var         look_vector        : Vector2
var         look_basis         : Basis
var         look_pitch         : float = 0.0

@export_category("Node Setup")
@export  var camera             : Camera3D

@export_category("Look Settings")
@export  var height             : float = 1.6
@export  var eye_forward_offset : float = 0.1
@export  var sensitivity        : float =  1.0
@export  var max_look_pitch     : float =  90.0
@onready var MAX_LOOK_PITCH     : float =  deg_to_rad(max_look_pitch)
@export  var min_look_pitch     : float = -90.0
@onready var MIN_LOOK_PITCH     : float = deg_to_rad(min_look_pitch)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	parent.add_user_signal( "request_look", [ { "name" : "look_vector", "type" : TYPE_VECTOR2 } ])
	if !(camera is Camera3D):
		prints("LookInputHandler Error: Camera variable not set!")
		set_enabled(false)
		return
	camera.position   = Vector3.ZERO
	camera.position.y = height
	set_enabled(enabled)


func _process(_delta) -> void:
	camera.position   = Vector3( 0, height, 0 )
	camera.transform = camera.transform.translated_local( Vector3( 0, 0, eye_forward_offset ) )
	camera.basis = look_basis


func handle_input( event : InputEvent ) -> void:
	if !(event is InputEventMouseMotion): return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: return
	var looking_vector : Vector2 = event.get_relative() 
	look_vector   += Vector2( deg_to_rad( looking_vector.x ), deg_to_rad( looking_vector.y ) ) * -sensitivity
	look_vector.x  = fmod(    look_vector.x,                  TAU                            )
	look_vector.y  = clampf(  look_vector.y,                  MIN_LOOK_PITCH, MAX_LOOK_PITCH )
	
	look_basis = Basis.IDENTITY
	look_basis = look_basis.rotated( Vector3.RIGHT,  look_vector.y )
	look_basis = look_basis.rotated( Vector3.UP,     look_vector.x )
	
	super.handle_input(event)
