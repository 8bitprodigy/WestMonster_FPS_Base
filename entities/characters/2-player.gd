extends CharacterController

#class_name player

signal health_changed(health_value)

@onready var torso = $torso
@onready var head = $torso/head
@onready var camera = $torso/head/Camera3D
@onready var loadout = $torso/loadout
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $torso/loadout/mountPoint/gun/muzzle_flash
@onready var raycast = $torso/head/Camera3D/RayCast3D

var health = 3

enum { 
	AIR, 
	WALK, 
	RUN,
	CROUCH,
	SNEAK,
	AIM,
	LEAN,
	WATER, 
	CLIMB, 
	DEAD, 
	FLY, 
	CLAMBER_RISE,
	CLAMBER_LEDGE,
	CLAMBER_VENT, 
}
var state : int = AIR : set = set_state
signal state_changed

# State functions
func set_state(new_state : int):
	prints("New State: ", new_state)
	if state != new_state:
		var old_state = state
		state = new_state
		emit_signal("state_changed", new_state, old_state)

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		head.rotate_x(-event.relative.y * 0.005*0.8)
		head.rotation.x = clamp(head.rotation.x,-PI/2*0.8,PI/2*0.8)
		loadout.rotate_x(-event.relative.y * 0.005*0.8)
		loadout.rotation.x = clamp(loadout.rotation.x,-PI/2*0.8,PI/2*0.8)
		torso.rotate_x(-event.relative.y * 0.005*0.2)
		torso.rotation.x = clamp(torso.rotation.x,-PI/2*0.2,PI/2*0.2)
	

func _physics_process(delta):
	"""if not is_multiplayer_authority(): return
	
	if anim_player.current_animation == "shoot":
		pass
	elif velocity != Vector3.ZERO and is_on_floor():
		anim_player.play("move")
	elif is_on_floor():
		anim_player.play("idle")
	else:
		anim_player.play("RESET")
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_SPEED
	
	if Input.is_action_just_pressed("primary_fire") and anim_player.current_animation != "shoot":
		play_shoot_effects.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")#.normalized()
	#direction += global_transform.basis.z * input_dir.y
	#direction += global_transform.basis.x * input_dir.x
	#direction.y = 0
	#direction = direction.normalized()
	#prints("Global Position: ", global_position)
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#prints("Input Direction: ", input_dir)
	if direction:
		velocity.x = direction.x * max_speed
		velocity.z = direction.z * max_speed
	else:
		velocity.x = move_toward(velocity.x, 0, max_speed)
		velocity.z = move_toward(velocity.z, 0, max_speed)
	
	move(delta)"""
	process_input(delta)
	prints("Jump Velocity: ", velocity.y, " | Is jumping: ", jumping)
	process_movement(delta)


func process_input(delta):
	dir = Vector3()
	"""var input_vector = Vector3()
	
	if Input.is_action_pressed("forward"):
		input_vector.z = -1
	if Input.is_action_pressed("backward"):
		input_vector.z += 1
	if Input.is_action_pressed("left"):
		input_vector.x = -1
	if Input.is_action_pressed("right"):
		input_vector.x += 1
	input_vector = input_vector.normalized()"""
	var input_vector = Input.get_vector("left", "right", "forward", "backward").normalized()
	
	var cam_xform = camera.get_global_transform()
	dir += cam_xform.basis.z * input_vector.y
	dir += cam_xform.basis.x * input_vector.x
	
	if is_on_floor():
		if Input.is_action_pressed("jump"):
			vel.y = JUMP_SPEED
			jumping = true
		else:
			jumping = false
	
	if Input.is_action_pressed("crouch"):
		eye_height = lerp(eye_height, DUCK_EYE_HEIGHT, DUCK_TRANSITION_SPEED * delta)
		ducking = true
	else:
		if !is_on_ceiling(): # Don't come out of duck when head is blocked
			if eye_height < 0.95:
				print_debug(eye_height)
				eye_height = lerp(eye_height, 1.0, DUCK_TRANSITION_SPEED * delta)
			else:
				eye_height = 1.0
				ducking = false


@rpc("call_local")
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true
	pass

@rpc("any_peer")
func receive_damage():
	health -= 1
	if health <= 0:
		health = 3
		position = Vector3.ZERO
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
	pass # Replace with function body.
