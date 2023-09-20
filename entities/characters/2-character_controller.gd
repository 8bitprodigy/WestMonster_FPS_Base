extends CharacterBody3D

#class_name CharacterController



const FRICTION = 6.0 # Deacceleration when walking
const GROUND_ACCEL = 10.0
const MAX_VEL_GROUND = 200.0 # Affected by ground friction
const AIR_ACCEL = 1.0
const MAX_VEL_AIR = 25.0 # Unaffected by friction or other forces
const JUMP_SPEED = 14.0
const GRAVITY = -40.0
const DUCK_EYE_HEIGHT = 0.2
const DUCK_TRANSITION_SPEED = 13.0 # Speed to enter duck state
const DUCK_SPEED_MULTIPLIER = 0.8
const MAX_STEP_HEIGHT = 0.9 # Any step under this height we can step up to

const STOP_ON_SLOPE = true
const MAX_SLOPE_ANGLE = 44.5
const MAX_SLIDES = 4

@export var MOUSE_SENSITIVITY = .1 # TODO: make user setting # EDIT: Done
@export var LEAN_ANGLE = 35


var dir = Vector3()
var vel = Vector3()
var jumping = false # True to prevent snapping
var ducking = false
var eye_height = 1.0

#@onready var rotation_helper = $RotationHelper
#@onready var camera = $RotationHelper/Camera
@onready var cylinder_shape = $CollisionShape3D.shape
@onready var normal_cylinder_height = cylinder_shape.height
#@onready var normal_camera_height = camera.translation.y

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20.0 #ProjectSettings.get_setting("physics/3d/default_gravity")
var direction = Vector3.ZERO
var acceleration = GROUND_ACCEL
var deceleration = FRICTION
var max_speed = MAX_VEL_GROUND


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


#func _process(delta):
#	# Update ducking height
#	if ducking:
#		var new_camera_translation = camera.translation
#		new_camera_translation.y = normal_camera_height * eye_height
#		camera.translation = new_camera_translation
#		cylinder_shape.height = normal_cylinder_height * eye_height

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()
	
	if !jumping and is_on_floor():
		if (dir.x != 0 or dir.z != 0) and can_step(dir): # Stepping
			var step_height = step_height(dir)
			global_position.y += step_height
		
		var movement = move_on_floor(dir, vel, delta)
		if ducking:
			movement *= DUCK_SPEED_MULTIPLIER
		
		#vel = move_and_slide_with_snap(movement, Vector3.DOWN * 1.5, Vector3.UP, STOP_ON_SLOPE, MAX_SLIDES, deg2rad(MAX_SLOPE_ANGLE))
		velocity = movement
		move_and_slide()
	else:
		vel.y += GRAVITY * delta # apply gravity
		#vel = move_and_slide(move_in_air(dir, vel, delta), Vector3.UP, STOP_ON_SLOPE, MAX_SLIDES, deg2rad(MAX_SLOPE_ANGLE))
		velocity = move_in_air(dir, vel, delta)
		move_and_slide()


func accelerate(accel_dir: Vector3, prev_vel: Vector3, accel: float, max_vel: float, delta: float) -> Vector3:
	var proj_vel = prev_vel.dot(accel_dir) # Vector projection of current velocity onto acceleration direction
	var accel_vel = accel * delta          # Accelerated velocity in direction of movement
	
	# Truncate accelerated velocity so proj_vel does not exceed max_vel
	if proj_vel + accel_vel > max_vel:
		accel_vel = max_vel - proj_vel
	
	return prev_vel + accel_dir * accel_vel


func move_on_floor(accel_dir: Vector3, prev_vel: Vector3, delta: float) -> Vector3:
	# Apply friction
	var speed = prev_vel.length()
	if speed != 0:
		var drop = speed * FRICTION * delta
		prev_vel *= max(speed - drop, 0) / speed
	
	return accelerate(accel_dir, prev_vel, GROUND_ACCEL, MAX_VEL_GROUND, delta)


func move_in_air(accel_dir: Vector3, prev_vel: Vector3, delta: float) -> Vector3:
	return accelerate(accel_dir, prev_vel, AIR_ACCEL, MAX_VEL_AIR, delta)


func can_step(dir: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	
	var feet_pos = to_global(Vector3(0, -cylinder_shape.height/2 + 0.0001, 0))
	var feet_query = PhysicsRayQueryParameters3D.create(feet_pos, feet_pos + dir)
	var feet_ray = space_state.intersect_ray(feet_query)
	if feet_ray.is_empty():
		return false # Did not find a step
	
	var max_step_pos = to_global(Vector3(0, -cylinder_shape.height/2 + MAX_STEP_HEIGHT, 0))
	var max_step_query = PhysicsRayQueryParameters3D.create(max_step_pos,max_step_pos+dir)
	var max_step_ray = space_state.intersect_ray(max_step_query)
	if not max_step_ray.is_empty():
		return false # Step is at or above the MAX_STEP_HEIGHT
	
	return true


#
# step_height takes a global direction
#
func step_height(dir: Vector3) -> float:
	var space_state = get_world_3d().direct_space_state
	# space uses global coordinates
	
	# The max_step_pos ray from the can_step() function is inherited here
	var ray_pos = to_global(Vector3(0, -cylinder_shape.height/2 + MAX_STEP_HEIGHT, 0)) + dir
	var ray_to = ray_pos + Vector3.DOWN * MAX_STEP_HEIGHT
	var ray_query = PhysicsRayQueryParameters3D.create(ray_pos, ray_to)
	var result = space_state.intersect_ray(ray_query)
	if result.empty(): # Ray did not collide
		printerr("Player.gd: step_height(): ray did not hit... should be impossible") 
		return 0.0
	
	# Return the height above the feet of our player this collision happened
	return to_local(result.position).y + cylinder_shape.height/2

func crouch():
	pass

func lean():
	pass
