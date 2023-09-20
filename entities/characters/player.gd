extends CharacterController

class_name Player

@export var mouse_sensitivity = 5.0
@export var ladder_change_dir_curve : Curve
@export var eye_relief : float = 0.3

# Head bob stuff

@onready var loadout = $torso/loadout
@onready var camera = $torso/head/Camera3D
@onready var anim_player = $AnimationPlayer
@onready var raycast = $torso/head/Camera3D/RayCast3D
@onready var right_hand = $torso/shoulder/hands/right_hand
@onready var right_hand_point = $torso/shoulder/hands/right_hand_point
@onready var left_hand = $torso/shoulder/hands/left_hand
@onready var left_hand_point = $torso/shoulder/hands/left_hand_point
@onready var ADS_point = $torso/head/ADS_point

var is_firing : bool = false

var primary_pressed : bool = false
var primary_just_pressed : bool = false
var primary_just_released : bool = false

var secondary_pressed : bool = false
var secondary_just_pressed : bool = false
var secondary_just_released : bool = false

var next_weapon : bool = false
var previous_weapon : bool = false
var recall_weapon : bool = false

var reload_just_pressed : bool = false

var prev_firing : bool = false
var can_fire : bool = true
var rotations : Vector2 = Vector2.ZERO
var relative_mouse_movement : Vector2 = Vector2.ZERO
var _vertical_look_scalar : float = 0.0
var head_rotation_x : float = 0.0
var torso_rotation_x : float = 0.0
var current_aim_lean_angle : float = 0.0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())


func _ready():
	super._ready()
	if not is_multiplayer_authority(): return
	
	ADS_point.position.z = camera.position.z - eye_relief
	
	$CollisionShape3D/MeshInstance3D.hide()
	prints("Jump Impulse: ", jump_impulse)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	camera.get_node("HUD/SubViewportContainer").show()
	
	#loadout.global_transform = right_hand.global_transform


func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		torso.rotate_y(-event.relative.x * 0.005)
		
		head_rotation_x += -event.relative.y * 0.005*0.8
		head_rotation_x = clamp(head_rotation_x,-PI/2*0.8,PI/2*0.8)
		torso_rotation_x += -event.relative.y * 0.005*0.2
		torso_rotation_x = clamp(torso_rotation_x,-PI/2*0.2,PI/2*0.2)
		
		_vertical_look_scalar = inverse_lerp(0,PI/2, head.rotation.x+torso.rotation.x)
		
		relative_mouse_movement = event.relative


func _process_rotations(_delta):
	#use_ray.top_level = true
	var temp_ray_pos = global_position + Vector3(0,head.global_position.y,0)
	use_ray.global_position = temp_ray_pos
	use_ray.global_rotation = Vector3(0,global_rotation.y,0)
	use_ray.force_raycast_update()
	
	var ray_collision_distance = temp_ray_pos.distance_to(use_ray.get_collision_point())
	
	var head_distance = Vector2(head.global_position.x,head.global_position.z).distance_to(Vector2(global_position.x,global_position.z))
	
	var lean_forward_conditions = true if (state == AIM or state == RUN) and state != CROUCH and ray_collision_distance > $CollisionShape3D.shape.size.x+0.25 else false
	
	
	current_aim_lean_angle = lerp_angle(current_aim_lean_angle,aim_lean_angle,lean_speed*_delta) if lean_forward_conditions  else lerp(current_aim_lean_angle,0.0,lean_speed*_delta)
	head.position.z = head_distance - (ray_collision_distance+0.15) if lean_forward_conditions and head_distance >= ray_collision_distance else 0.0 # the intended fix code
	
	use_ray.position = Vector3.ZERO
	use_ray.rotation = Vector3.ZERO
	
	head.rotation.x = head_rotation_x + current_aim_lean_angle
	shoulder.rotation.x = head_rotation_x + current_aim_lean_angle
	torso.rotation.x = torso_rotation_x - current_aim_lean_angle


func _process(_delta):
	if not is_multiplayer_authority(): return
	delta = _delta
	_process_rotations(_delta)
	
	
	#if relative_move_direction != Vector3.ZERO:
	'''emit_signal("update_crosshairs", {
		"velocity": velocity,
		"gun heat": loadout.gun_heat,
		"aiming": _can_aim() and is_aiming,
		"state": state,
		"delta": delta
	})'''

var lean_strength : float
func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	_phys_delta = _delta
	var forward_input: float = Input.get_action_strength("backward") - Input.get_action_strength("forward")
	var strafe_input: float = Input.get_action_strength("right") - Input.get_action_strength("left")
	relative_move_direction = Vector3(strafe_input,0,forward_input)
	wishdir = Vector3(strafe_input, 0, forward_input).rotated(Vector3.UP, torso.global_transform.basis.get_euler().y).normalized() 
	# wishdir is our normalized horizontal input
	
	
	#----- Check Swim -----
	#prints("Water Depth: ", _get_relative_water_depth())
	is_swimming = true if _get_relative_water_depth() > max_water_swim_depth else false
	if is_swimming and state != SWIM: set_state(SWIM)
	
	#----- Jumping -----
	queue_jump()
	jump()
	
	
	if is_on_ceiling(): #We've hit a ceiling, usually after a jump. Vertical velocity is reset to cancel any remaining jump momentum
		vertical_velocity = 0
	
	debug_horizontal_velocity = Vector3(velocity.x, 0, velocity.z) # Horizontal velocity to be displayed
	
	#----- Sprinting -----
	is_sprinting = Input.is_action_pressed("sprint")and !Input.is_action_pressed("backward")
	
	#----- Sneaking -----
	is_sneaking = Input.is_action_pressed("sneak")
	
	#----- Aiming -----
	is_aiming = Input.is_action_pressed("secondary_fire") and _can_aim()
	
	#----- Crouching -----
	is_crouching = Input.is_action_pressed("crouch")# and state != LADDER
	
	#----- Leaning -----
	lean_strength = Input.get_action_strength("lean_left") - Input.get_action_strength("lean_right")
	is_leaning = true if abs(lean_strength)>0 else false
	
	#----- Use -----
	is_using = Input.is_action_pressed("use")
	if is_using: _use.rpc()
	
	
	#----- firing -----
	primary_pressed = Input.is_action_pressed("primary_fire")
	primary_just_pressed = Input.is_action_just_pressed("primary_fire")
	primary_just_released = Input.is_action_just_released("primary_fire")
	
	secondary_pressed = Input.is_action_pressed("secondary_fire")
	secondary_just_pressed = Input.is_action_just_pressed("secondary_fire")
	secondary_just_released = Input.is_action_just_released("secondary_fire")
	
	next_weapon = Input.is_action_just_pressed("next_weapon")
	previous_weapon = Input.is_action_just_pressed("previous_weapon")
	recall_weapon = Input.is_action_just_pressed("recall_weapon")
	#prints("Next Weapon: ", next_weapon, " | Previous Weapon: ", previous_weapon, " | Recall Weapon: ", recall_weapon)
	
	reload_just_pressed = Input.is_action_pressed("reload")
	
	prev_firing = is_firing
	
	crouch(is_crouching, _delta)
	lean(lean_strength, _delta)
	#loadout.position.y = shoulder.position.y
	#prints("Gravity: ", vertical_velocity)
	# PROCESS MOVEMENT:
	match state:
		WALK:
			if is_sprinting and !is_firing and velocity.length() >= max_walk_speed:# and Input.is_action_pressed("move_forward"):
				prev_aim_lean = aim_lean
				aim_lean = aim_lean_angle
				set_state(RUN)
			if is_leaning:
				aim_lean = 0
				set_state(LEAN)
				return
			if is_crouching:
				set_state(CROUCH)
				return
			if is_aiming and !is_sprinting:
				prev_aim_lean = aim_lean
				aim_lean = aim_lean_angle
				set_state(AIM)
			if is_sneaking:
				set_state(SNEAK)
			if !_is_on_floor() or is_jumping:
				set_state(AIR)
			if is_swimming:
				friction = water_friction
				set_state(SWIM)
			
			friction = ground_friction
			max_speed = max_walk_speed
			move_ground(velocity,_delta)
		AIR:
			var loadout_tween
			if _is_on_floor():
				is_jumping = false
				
				prints("Vertical Velocity: ",velocity.y*0.025)
				loadout_tween = create_tween()
				loadout_tween.tween_property(loadout,"position:y",shoulder.position.y+velocity.y*0.0125, 0.125).set_ease(Tween.EASE_OUT)
				loadout_tween.tween_property(loadout,"position:y",shoulder.position.y,0.35).set_ease(Tween.EASE_IN)
				
				vertical_velocity = 0.0
				if is_sprinting:
					prev_aim_lean = aim_lean
					aim_lean = aim_lean_angle
					set_state(RUN)
				elif is_sneaking:
					prev_aim_lean = aim_lean
					aim_lean = aim_lean_angle
					set_state(SNEAK)
				else:
					set_state(WALK)
			
			vertical_velocity = clamp(vertical_velocity + (get_gravity()*_delta),terminal_velocity,jump_impulse) # Stop adding to vertical velocity once terminal velocity is reached
			#prints("Vertical Velocity: ",vertical_velocity)
			loadout.position.y = lerp(loadout.position.y, shoulder.position.y - (vertical_velocity*0.025),_delta*5.0)
			move_air(velocity, _delta)
			
		RUN:
			if !is_sprinting or velocity.length() == 0:
				aim_lean = 0
				set_state(WALK)
			if is_leaning:
				aim_lean = 0
				set_state(LEAN)
				#return
			if is_crouching:
				aim_lean = 0
				set_state(CROUCH)
				#return
			if is_aiming and velocity.length() <= max_sneak_speed:
				prev_aim_lean = aim_lean
				aim_lean = aim_lean_angle
				set_state(AIM)
				#return"""
			if is_firing:
				aim_lean = 0
				set_state(WALK)
			if !_is_on_floor() or is_jumping:
				set_state(AIR)
				#return
			
			friction = ground_friction
			max_speed = max_run_speed
			move_ground(velocity, _delta)
		SNEAK:
			if !is_sneaking:
				set_state(WALK)
			if is_aiming:
				prev_aim_lean = aim_lean
				aim_lean = aim_lean_angle
				set_state(AIM)
			if !_is_on_floor():
				set_state(AIR)
			
			friction = ground_friction
			max_speed = max_sneak_speed
			move_ground(velocity, _delta)
		AIM:
			if !is_aiming:
				prev_aim_lean = aim_lean
				aim_lean = 0
				set_state(WALK)
			if is_sprinting and velocity.length() >= max_sneak_speed:
				
				set_state(RUN)
			if !_is_on_floor():
				set_state(AIR)
			
			friction = ground_friction
			max_speed = max_sneak_speed
			move_ground(velocity, _delta)
		CROUCH:
			#is_aiming = true
			if !is_crouching and !is_on_ceiling():
				prev_aim_lean = aim_lean
				aim_lean = 0
				set_state(WALK)
			if !_is_on_floor():
				set_state(AIR)
			
			max_speed = max_crouch_run_speed if is_sprinting else max_crouch_speed
			move_ground(velocity, _delta)
		LEAN:
			if !is_leaning:
				set_state(WALK)
			if !_is_on_floor():
				set_state(AIR)
			
			friction = ground_friction
			max_speed = max_sneak_speed
			move_ground(velocity, _delta)
		SWIM:
			if _get_relative_water_depth() < max_water_swim_depth:
				friction = ground_friction
				set_state(WALK)
			vertical_look_scalar = _vertical_look_scalar * (-forward_input)
			max_speed = max_water_speed
			friction = water_friction
			move_swim(velocity, _delta)
			pass
		CLAMBER:
			#prints("Climb Tween progress: ",CLIMB_TWEEN.is_running(), " | Y-Val: ", global_translation.y)
			if !(interact_tween.is_running() and Input.is_action_pressed("forward")): # and global_translation.y < climb_target_Y:
				#move_and_slide_with_snap(Vector3.UP+dir*4,Vector3.UP,Vector3.UP,STOP_ON_SLOPE,MAX_SLIDES,deg2rad(MAX_SLOPE_ANGLE))
				#var temp_position = global_position
				interact_tween.kill()
				#move_and_slide()
				#global_position = temp_position
				if _is_on_floor():
					set_state(WALK)
				else:
					set_state(AIR)
		LADDER:
			if !interact_tween.is_running():
				vertical_look_scalar = ladder_change_dir_curve.sample((_vertical_look_scalar+1)/2)
				vertical_look_scalar *= -forward_input
				move_ladder(_delta)
		DEAD:
			pass
		FLY:
			"""# Flying
			dir = dir.normalized()
			var target = dir
			target *= MAX_FLY_SPEED
			vel = vel.linear_interpolate(target, FLY_ACCEL * _delta)
			vel = move_and_slide(vel)"""
			pass
	
	if state != AIR:
		loadout.position.y = lerp(loadout.position.y, shoulder.position.y, _delta * 5.0)
	previous_using = is_using

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
	pass # Replace with function body.
