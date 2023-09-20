extends CharacterBody3D

#class_name CharacterController

@export var SPEED = 10.0
@export var JUMP_VELOCITY = 10.0
@export var ACCELERATION = 0.5
# Movement constants
@export var GRAVITY : float = 24.8
@export var GRAVITY_DIR : Vector3 = Vector3.DOWN
@export var MAX_SNEAK_SPEED : float = 3.0
@export var MAX_WALK_SPEED : float = 4.5
@export var MAX_RUN_SPEED : float = 10.0
@export var JUMP_FORCE : float = 8.0
@export var ACCEL : float = 200.0
@export var DECEL : float = 10.0
@export var MAX_AIR_SPEED : float = 25.0
@export var AIR_ACCEL : float = 3.0
@export var AIR_DECEL : float = 3.0
@export var MAX_FLY_SPEED : float = 12.0
@export var FLY_ACCEL : float = 5.0
@export var MAX_WATER_SPEED : float = 6.0
@export var WATER_ACCEL : float = 2.0
@onready var CLIMB_TWEEN = get_tree().create_tween()
@export var MAX_CLIMB_SPEED : float = 4.0
@export var CLIMB_ACCEL : float = 10.0
@export var MAX_CLIMB_HEIGHT : float = 2.0
@export var MIN_CLIMB_HEIGHT : float = 1.125
@export var ROT_SPEED : float = 5.0
@export var LEAN_ANGLE = 0.6108652
@export var AIM_LEAN_ANGLE : float = -30
@export var CROUCH_HEIGHT = -1.0
@export var STEP_HEIGHT = 1.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20.0 #ProjectSettings.get_setting("physics/3d/default_gravity")
var direction = Vector3.ZERO
var acceleration = ACCEL
var deceleration = DECEL
var max_speed = MAX_RUN_SPEED

func crouch():
	pass

func lean():
	pass

func _accelerate(delta: float) -> Vector3:
	var proj_vel = velocity.dot(direction) # Vector projection of current velocity onto acceleration direction
	var accel_vel = acceleration * delta          # Accelerated velocity in direction of movement
	# Truncate accelerated velocity so proj_vel does not exceed max_vel
	if proj_vel + accel_vel > max_speed:
		accel_vel = max_speed - proj_vel
	return velocity + direction * accel_vel

func move(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	var start_pos = global_position
	var test_movement

	move_and_slide()
	
	if is_on_floor():
		test_movement = global_position
		global_position = start_pos
		
		move_and_collide(Vector3(0,STEP_HEIGHT,0))
		
		move_and_slide()
		
		move_and_collide(Vector3(0,-STEP_HEIGHT*2,0))
		
		if !is_on_floor(): global_position = test_movement
