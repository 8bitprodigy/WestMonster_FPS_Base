extends InputHandler
class_name MovementInputHandler


var         velocity           : Vector3
var         movement_vector    : Vector2
var         down               : float   = 0

var         query_params       : PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()

@onready var gravity           : float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export_category("Node Setup")
@export  var look_input_handler : LookInputHandler
@export_category("Movement Settings")
@export  var SPEED              : float = 100.0
@export  var ACCELERATION       : float = 100.0
@export  var FRICTION           : float = 15.0
@export  var STEP_HEIGHT        : float = 0.5
@onready var speed              : float = SPEED


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	parent.add_user_signal( "request_move", [ { "name" : "movement_vector", "type" : TYPE_VECTOR2 } ])
	if !look_input_handler:
		set_enabled(false)
		return
	set_enabled(enabled)


func _physics_process(delta: float) -> void:
	var start_position : Vector3 
	var start_velocity : Vector3
	var walk_position  : Vector3
	var walk_velocity  : Vector3
	var step_position  : Vector3
	var step_velocity  : Vector3
	velocity.y = character.velocity.y
	handle_movement(delta)
	character.velocity.y = velocity.y
	velocity = Vector3( movement_vector.y, velocity.y, movement_vector.x )
	
	start_position = character.position
	start_velocity = character.velocity
	
	query_params.shape          = character.get_node("CollisionShape3D").shape
	query_params.collision_mask = character.collision_mask
	query_params.transform      = character.transform
	
	character.move_and_slide()
	walk_position = character.position
	"""
	walk_position = character.position
	walk_velocity = character.velocity
	
	character.position = start_position
	character.velocity = start_velocity
	"""
	


func handle_input( event : InputEvent ) -> void:
	if !(event is InputEventKey): return
	movement_vector = Input.get_vector( "forward", "backward", "left", "right" )
	
	super.handle_input(event)


func handle_movement(delta: float) -> void:
	character.velocity = velocity.rotated( Vector3.UP, look_input_handler.look_vector.x ) * speed * delta
