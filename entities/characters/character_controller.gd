extends CharacterBody3D

class_name CharacterController


@export var max_health = 3
@onready var health = max_health

@export var max_walk_speed: float = 6.0
@export var max_run_speed: float = 12.0
@export var max_sneak_speed: float = 3.0
var max_speed: float = 6.0 # Meters per second
@export var accel: float = 200.0 # or max_speed * 10 : Reach max speed in 1 / 10th of a second
@export var ground_friction: float = 15.0
@export var water_friction: float = 5.0
var friction: float = 10.0 # Higher friction = less slippery. In quake-based games, usually between 1 and 5

@export var max_air_speed: float = 0.6
@export var air_accel : float = 3.0
@export var air_friction : float = 3.0

@export var max_fly_speed : float = 12.0
@export var fly_accel : float = 5.0
@export var max_water_speed : float = 3.0
@export var water_gravity : float = 15.0

@export var max_clamber_speed : float = 1.0
@export var climb_accel : float = 10.0
@export var max_clamber_height : float = 2.0
@export var min_clamber_height : float = 1.125
var clamber_target : Vector3 = Vector3.ZERO
@onready var interact_tween : Tween

@export var max_ladder_speed : float = 150.0
var ladder_top: float = 0.0
var ladder_bottom: float = 0.0
var ladder_rotation: float = 0.0

@export var lean_speed : float = 5.0
@export var LEAN_ANGLE : float = PI/8
@onready var lean_angle : float = deg_to_rad(35) # Angle in degrees.
@export var AIM_LEAN_ANGLE : float = 28.0 # Angle in degrees.
@onready var aim_lean_angle = deg_to_rad(AIM_LEAN_ANGLE)

@export var height : float = 1.75
@export var eye_margin : float = 0.15
@export var crouch_height : float = 0.75
@export var crouch_speed : float = 5.0
@export var max_crouch_speed : float = 2.5
@export var max_crouch_run_speed : float = 4.5

@export var max_ramp_angle: float = 45 # Max angle that the player can go upwards at full speed

@export var max_step_height: float = 0.5
@onready var step_vector = Vector3(0,max_step_height,0)

@export var jump_height : float = 2.0
@export var jump_time_to_peak : float = 0.4
@export var jump_time_to_descent: float = 0.35

@onready var jump_impulse : float = (2.0 * jump_height) / jump_time_to_peak
@onready var jump_gravity : float = (-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
@onready var fall_gravity : float = (-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)
@onready var terminal_velocity : float = fall_gravity * 5 # When this is reached, we stop increasing falling speed

@onready var max_water_swim_depth : float = 1.25

var wishdir: Vector3 = Vector3.ZERO # Desired travel direction of the player

var vertical_velocity: float = 0 # Vertical component of our velocity. 
# We separate it from 'velocity' to make calculations easier, then join both vectors before moving the player

var wish_jump: bool = false # If true, player has queued a jump : the jump key can be held down before hitting the ground to jump.
@export var auto_jump: bool = false # Auto bunnyhopping

var aim_lean : float = 0
var vertical_look_scalar : float = 1.0
var prev_aim_lean : float = 0
var temp_lean_rotation : float = 0
var cam_accel = 40
var air_crouch_amt = 0
var climb_target_Y = 0

@onready var delta = get_process_delta_time()

# Actions
var is_sprinting : bool = false
var is_sneaking : bool = false
var is_leaning : bool = false
var is_crouching : bool = false
var is_jumping : bool = false
var is_aiming : bool = false
var is_stepping : bool = false
var is_swimming : bool = false

var is_using : bool = false
var previous_using : bool = false

# The next two variables are used to display corresponding vectors in game world.
# This is probably not the best solution and will be removed in the future.
var debug_horizontal_velocity: Vector3 = Vector3.ZERO
var accelerate_return: Vector3 = Vector3.ZERO

var relative_move_direction
var aim_blocked : bool = false

var _phys_delta

enum { 
	AIR, 
	WALK, 
	RUN,
	CROUCH,
	SNEAK,
	AIM,
	LEAN,
	CLAMBER,
	LADDER,
	DEAD, 
	FLY, 
	SWIM,
	CLAMBER_RISE,
	CLAMBER_LEDGE,
	CLAMBER_VENT, 
}
var state : int = AIR : set = set_state
signal state_changed

@onready var decal_ray = $decal_ray
@onready var swim_ray = $swim_ray
@onready var use_ray = $torso/head/use_ray
@onready var torso = $torso
@onready var head = $torso/head
@onready var shoulder = $torso/shoulder
@onready var collider = $CollisionShape3D
@onready var mesh = $CollisionShape3D/MeshInstance3D

signal health_changed(health_value)

# State functions
func set_state(new_state : int):
	prints("New State: ", new_state)
	if state != new_state:
		var old_state = state
		state = new_state
		emit_signal("state_changed", new_state, old_state)

func _can_aim():
	#prints("Aim Blocked: ", aim_blocked)
	return [WALK,AIR,SWIM,AIM,SNEAK,CROUCH,LEAN].has(state) and !aim_blocked

func _ready():
	floor_constant_speed = true
	mesh.mesh.height = height
	collider.shape.size.y = clamp(collider.shape.size.y, crouch_height,height)
	collider.position.y = collider.shape.size.y/2
	torso.global_position = collider.global_position
	head.position.y = collider.position.y - eye_margin
	
	interact_tween = create_tween()
	interact_tween.tween_property(self,"",null,0)

#func _physics_process(_delta):
#	$CollisionShape3D.global_rotation = Vector3.ZERO

@rpc("any_peer")
func receive_damage():
	health -= 1
	if health <= 0:
		health = 3
		position = Vector3.ZERO
	health_changed.emit(health)

func get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func _is_on_floor() -> bool:
	var collision_info = move_and_collide(Vector3(0,-0.1,0),true)
	if !collision_info: return false
	if collision_info.get_collision_count() == 0: return false
	if collision_info.get_angle() > floor_max_angle: return false
	if global_position.y - collision_info.get_position().y < 0: return false
	return true

func _is_in_water() -> bool:
	if !swim_ray.is_colliding(): return false
	return swim_ray.get_collider().is_in_group("water")

func _get_relative_water_depth() -> float:
	if _is_in_water():
		return height+swim_ray.to_local(swim_ray.get_collision_point()).y
	else: return 0.0

# This is were we calculate the speed to add to current velocity
func accelerate( input_velocity: Vector3, _accel: float, _max_speed: float, _delta: float)-> Vector3:
	# Current speed is calculated by projecting our velocity onto wishdir.
	# We can thus manipulate our wishdir to trick the engine into thinking we're going slower than we actually are, allowing us to accelerate further.
	var current_speed: float = input_velocity.dot(wishdir)
	
	# Next, we calculate the speed to be added for the next frame.
	# If our current speed is low enough, we will add the max acceleration.
	# If we're going too fast, our acceleration will be reduced (until it evenutually hits 0, where we don't add any more speed).
	var add_speed: float = clamp(_max_speed - current_speed, 0, _accel * _delta)
	
	# Put the new velocity in a variable, so the vector can be displayed.
	accelerate_return = input_velocity + wishdir * add_speed
	return accelerate_return

func water_accelerate( input_velocity: Vector3, _accel: float, _max_speed: float, _delta: float)-> Vector3:
	var new_dir = Vector3.ZERO
	new_dir.x = wishdir.x * (1-abs(vertical_look_scalar))
	new_dir.y = vertical_look_scalar
	new_dir.z = wishdir.z * (1-abs(vertical_look_scalar))
	# Current speed is calculated by projecting our velocity onto wishdir.
	# We can thus manipulate our wishdir to trick the engine into thinking we're going slower than we actually are, allowing us to accelerate further.
	var current_speed: float = input_velocity.dot(new_dir)
	
	# Next, we calculate the speed to be added for the next frame.
	# If our current speed is low enough, we will add the max acceleration.
	# If we're going too fast, our acceleration will be reduced (until it evenutually hits 0, where we don't add any more speed).
	var add_speed: float = clamp(_max_speed - current_speed, 0, _accel * _delta)
	
	# Put the new velocity in a variable, so the vector can be displayed.
	accelerate_return = input_velocity + new_dir * add_speed
	return accelerate_return

# Scale down horizontal velocity
func _friction(input_velocity: Vector3, _delta: float)-> Vector3:
	var speed: float = input_velocity.length()
	var scaled_velocity: Vector3
	
	# Check that speed isn't 0, this is to avoid divide by zero errors
	if speed != 0:
		var drop = speed * friction * _delta # Amount of speed to be reduced by friction
		# ((max(speed - drop, 0) / speed) will return a number between 0 and 1, this is our speed multiplier from friction
		# The max() is there to avoid anything from happening in the case where the user sets friction to a negative value
		scaled_velocity = input_velocity * max(speed - drop, 0) / speed
	# Stop altogether if we're going too slow to notice
	if speed < 0.1:
		return scaled_velocity * 0
	return scaled_velocity

# Apply friction, then accelerate
func move_ground(input_velocity: Vector3, _delta: float)-> void:
	# We first work on only on the horizontal components of our current velocity
	
	var nextVelocity: Vector3 = Vector3.ZERO
	nextVelocity.x = input_velocity.x
	nextVelocity.z = input_velocity.z
	nextVelocity = _friction(nextVelocity, delta) #Scale down velocity
	nextVelocity = accelerate(nextVelocity, accel, max_speed, _delta)
	
	var start_position = global_position
	var temp_position
	
	# Then get back our vertical component, and move the player
	velocity = nextVelocity
	velocity.y = vertical_velocity
	move_and_slide()
	
	temp_position = global_position
	global_position = start_position
	
	
	move_and_collide(step_vector)
	#prints("Step Up Pos: ", global_position)
	velocity = Vector3(nextVelocity.x,0.0,nextVelocity.z)
	move_and_slide()
	#prints("step forward pos: ", global_position)
	move_and_collide(-step_vector)
	if test_move(global_transform,-step_vector):
		move_and_collide(-step_vector)
	
	var walk_distance = start_position.distance_to(temp_position)
	var step_distance = start_position.distance_to(global_position)
	if walk_distance > step_distance or !_is_on_floor():
		global_position = temp_position
	
	if is_on_wall() and state == WALK: test_clamber()

# Accelerate without applying friction (with a lower allowed max_speed)
func move_air(input_velocity: Vector3, _delta: float)-> void:
	# We first work on only on the horizontal components of our current velocity
	var nextVelocity: Vector3 = Vector3.ZERO
	nextVelocity.x = input_velocity.x
	nextVelocity.z = input_velocity.z
	nextVelocity = accelerate( nextVelocity, accel, max_air_speed, _delta)
	
	# Then get back our vertical component, and move the player
	nextVelocity.y = vertical_velocity
	velocity = nextVelocity
	move_and_slide()

func move_swim(input_velocity: Vector3, _delta: float)-> void:
	# We first work on only on the horizontal components of our current velocity
	var nextVelocity: Vector3 = Vector3.ZERO
	nextVelocity.x = input_velocity.x * (1-abs(vertical_look_scalar))
	nextVelocity.z = input_velocity.z * (1-abs(vertical_look_scalar))
	nextVelocity.y = 1.0 if wish_jump else vertical_look_scalar
	#prints("Swim Velocity: ", nextVelocity)
	nextVelocity = _friction(nextVelocity, _delta)
	nextVelocity = water_accelerate(nextVelocity, accel, max_water_speed, _delta)
	
	nextVelocity.y = -water_gravity * delta if wishdir == Vector3.ZERO and !wish_jump else nextVelocity.y
	nextVelocity.y += -water_gravity * delta * 2.0 if is_crouching else 0.0
	# Then get back our vertical component, and move the player
	velocity = nextVelocity
	move_and_slide()

# Set wish_jump depending on player input.
func queue_jump()-> void:
	# If auto_jump is true, the player keeps jumping as long as the key is kept down
	if auto_jump:
		wish_jump = true if Input.is_action_pressed("jump") else false
		return
	
	if Input.is_action_just_pressed("jump") and !wish_jump:
		wish_jump = true
	if Input.is_action_just_released("jump"):
		wish_jump = false

func jump():
	if _is_on_floor() and wish_jump and [WALK,RUN].has(state):
		vertical_velocity = jump_impulse
		move_air(velocity, _phys_delta) # Mimic Quake's way of treating first frame after landing as still in the air
		wish_jump = false # We have jumped, the player needs to press jump key again
		is_jumping = true
		set_state(AIR)

func crouch(crouching: bool, _delta : float):
	var start_collider_height = collider.shape.size.y
	if crouching:
		collider.shape.size.y -= crouch_speed * _delta
	elif !test_move(global_transform,Vector3(0,height-collider.shape.size.y,0)):
		collider.shape.size.y += crouch_speed * _delta
	
	if collider.shape.size.y < height: is_crouching = true
	
	$CollisionShape3D/MeshInstance3D.scale.y = collider.shape.size.y/height
	$CollisionShape3D/MeshInstance3D.position.y = -(height/2-collider.shape.size.y/2)
	
	swim_ray.position.y = collider.shape.size.y
	swim_ray.target_position.y = -collider.shape.size.y
	
	collider.shape.size.y = clamp(collider.shape.size.y, crouch_height,height)
	collider.position.y = collider.shape.size.y/2
	torso.global_position = collider.global_position
	head.position.y = collider.position.y - eye_margin
	shoulder.position.y = head.position.y*0.65
	max_speed = lerp(max_walk_speed,max_crouch_speed,inverse_lerp(height,crouch_height,collider.shape.size.y))
	if !_is_on_floor() and crouching: # pulls your legs up when you crouch in mid-air
		global_position.y += start_collider_height - collider.shape.size.y

func test_clamber():
	#prints("Starting Clamber.")
	if !(relative_move_direction.z == -1 and relative_move_direction.x == 0): return
	#prints("Checked Movement Direction.")
	var temp_position = global_position
	var temp_velocity = velocity
	velocity = wishdir
	move_and_slide()
	var test_velocity = velocity
	velocity = temp_velocity
	var test_dot = wishdir.normalized().dot(test_velocity.normalized())
	if test_dot > 0.05: return
	move_and_collide(Vector3(0,max_clamber_height,0))
	move_and_collide(wishdir)
	var _test_move = move_and_collide(Vector3(0,-max_clamber_height,0))
	if (global_position.y - temp_position.y) > min_clamber_height and _test_move.get_angle() <= deg_to_rad(5): 
		#prints("Clamber Check Success!")
		clamber_target = global_position
		global_position = temp_position
		var clamber_height = clamber_target.y - temp_position.y
		interact_tween = create_tween()
		interact_tween.tween_property(self,"global_position:y",clamber_target.y+0.1,clamber_height / max_clamber_speed)
		interact_tween.tween_property(self,"global_position",clamber_target,0.25)
		set_state(CLAMBER)
		return
	#prints("Clamber Check Failure.")
	global_position = temp_position
	return

func test_ladder(ladder):
	#if is_using and previous_using:return
	if !ladder.has_node("CollisionShape3D"): return
	ladder.monitoring = true
	var shape = ladder.get_node("CollisionShape3D")
	#prints("Shape: ", shape)
	ladder_top = shape.global_position.y + (shape.shape.size.y/2)
	ladder_bottom = shape.global_position.y - (shape.shape.size.y/2)
	ladder_rotation = ladder.global_rotation.y
	var temp_position = global_position
	var target_point = Vector3(shape.global_position.x,global_position.y,shape.global_position.z)
	var target_entry_point = target_point + Vector3(0,0,$CollisionShape3D.shape.size.x*2).rotated(Vector3.UP,ladder_rotation)
	var test_vector = target_entry_point - global_position
	
	move_and_collide(test_vector)
	test_vector = target_point - global_position
	move_and_collide(test_vector)
	var goal_point = global_position
	
	var dir_dot = torso.transform.basis.z.dot(ladder.transform.basis.z)
	var facing_ladder_from_front_or_back = dir_dot > 0.5 or dir_dot < -0.5
	
	if ladder_bottom < global_position.y + height and ladder_top > global_position.y \
		and facing_ladder_from_front_or_back:
		set_state(LADDER)
		global_position = temp_position
		interact_tween = create_tween()
		interact_tween.tween_property(self,"global_position",goal_point+Vector3(0,0.1,0),0.25)
	global_position = temp_position

func move_ladder(_delta):
	if relative_move_direction.x != 0:
		if _is_on_floor(): set_state(WALK)
		else: set_state(AIR)
		return
	if relative_move_direction.z == 0: return
	
	velocity = Vector3(0,vertical_look_scalar * max_ladder_speed * _delta,0)
	#prints("Ladder Velocity: ", velocity)
	move_and_slide()
	
	if ladder_bottom > global_position.y + height:
		if _is_on_floor():
			set_state(WALK)
		else:
			set_state(AIR)
	if ladder_top < global_position.y:
		set_state(AIR)
		interact_tween = create_tween()
		interact_tween.tween_property(self,"global_position",global_position+Vector3(0,0.1,-1).rotated(Vector3.UP,ladder_rotation),0.25)
	return

func lean(direction: float, _delta: float):
	#torso.rotation_degrees.z = lerp(torso.rotation_degrees.z, direction * lean_angle, lean_speed * _delta)
	var target_basis = Basis.IDENTITY.rotated(Vector3.UP,torso.rotation.y)
	torso.transform.basis = torso.transform.basis.slerp(target_basis.rotated(target_basis.z,direction*lean_angle),lean_speed*_delta)

@rpc("call_local")
func _use():
	use_ray.force_raycast_update()
	var interactable = use_ray.get_collider()
	if !interactable: return
	if interactable.get_groups().size() == 0: return
	var interactable_group = interactable.get_groups()[0]
	prints("Interactable: ", interactable, " | Interactable Group: ", interactable_group)
	match interactable_group:
		"ladder":
			if is_using and previous_using:return
			if state != LADDER: test_ladder(interactable)
			else:
				if _is_on_floor(): set_state(WALK)
				else: set_state(AIR)
		"Switch":
			if is_using and previous_using:return
			if interactable.has_method("use"):
				interactable.use(self)
		"Dial":
			if interactable.has_method("use"):
				interactable.use(self)
		"interactable":
			if interactable.has_method("use"):
				#prints("Using Door")
				interactable.use(self)
