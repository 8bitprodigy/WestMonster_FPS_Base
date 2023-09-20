@icon("res://sprites/icons/swinging_door.svg")
extends Door

@export_enum("Front", "Back") var open_direction : int = 0
@export_range(0, 180) var open_angle : float = 90.0
@export var latch_on_close : bool = true
@export var spring_loaded : bool = false
@export var collision_force_factor : float = 50.0

var _interact_tween = null
var _spring_load_interrupted : bool = false
var _colliding_bodies : Array[PhysicsBody3D] = []


func get_open_angle() -> float:
	return open_angle if open_direction == 0 else -open_angle


func is_ajar() -> bool:
	if not door_moving: return state == 0
	else: return abs($door.rotation_degrees.y) >= open_angle


# Called when the node enters the scene tree for the first time.
func _ready():
	var hinge_shift_amount = $door/CollisionShape3D.shape.size.z/2
	if latch_on_close: $door.freeze = true
	if open_direction == 0:
		$HingeJoint3D.position.z = -hinge_shift_amount
		_update_hinge_angle_limit(0, open_angle)
	else:
		$HingeJoint3D.position.z = hinge_shift_amount
		_update_hinge_angle_limit(-open_angle, 0)
	
	super._ready()


func _physics_process(_delta):
	# NOTE: there is a bug in the engine or somehow with our configuration,
	# where the player is not considered colliding with the door if they move
	# against it in the same direction it is moving. I.E. not in opposite
	# directions, but the same directions. No contacts/collisions occur.
	# 03/08/23 Godot 4.0
	if not _colliding_bodies.is_empty():
		for body in _colliding_bodies:
			# Use the character's intended movement as velocity so they can move doors.
			var body_velocity = Vector3()
			if body is CharacterController: body_velocity = body.wishdir + body.velocity
			else: body_velocity = body.velocity
			
			# I just use the door/CollisionShape3D because it's origin is in the center of the door
			var dir = body.global_position.direction_to($door/CollisionShape3D.global_position)
			var force = dir*body_velocity.length()*collision_force_factor
#			prints(force, $door.sleeping, $door.freeze, $door.get_contact_count())
			$door.apply_central_force(force)
	
	if !door_moving: return
	
	if is_zero_approx($door.rotation.y) and latch_on_close and state == 1:
		$door.freeze = true


func use(body):
	super.use(body)


func try_locked():
	$AnimationPlayer.play("jiggle")


func unlock():
	super.unlock()


func open():
	$door.freeze = false # Enable physics/collision detection
	$door/open_sound.play()
	_start_door_tween(get_open_angle(), open_time)
	super.open()


func close():
	# $door.freeze = false in open, so it must still be unfrozen
	if spring_loaded: # Shuts like a porch storm door
		_start_door_tween(0, close_time, _play_close_sound, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	else:
		_start_door_tween(0, open_time, _play_close_sound)
	super.close()


func _play_close_sound() -> void:
	$door/close_sound.play()


func _stop_door_tween() -> void:
	if _interact_tween: _interact_tween.kill()


func _start_door_tween(target_y_rot: float, duration: float, end_callback=null, trans=null, _ease=null) -> void:
	# Stop whatever Tween might currently be running
	_stop_door_tween()
	_interact_tween = create_tween()
	
	if trans: _interact_tween.set_trans(trans)
	if _ease: _interact_tween.set_ease(_ease)
	_interact_tween.tween_property($door, "rotation_degrees:y", target_y_rot, duration)
	if end_callback: _interact_tween.tween_callback(end_callback)


func _update_hinge_angle_limit(from: float, to: float) -> void:
	$HingeJoint3D.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(from))
	$HingeJoint3D.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(to))


func _on_door_body_entered(body):
	if !(body is CharacterBody3D or body is StaticBody3D): return
	_stop_door_tween()
	
#	print("Adding body")
	
	if spring_loaded and not _spring_load_interrupted:
		_spring_load_interrupted = true
		_start_door_tween(get_open_angle(), open_time)
	
	door_moving = false
	if body not in _colliding_bodies:
		_colliding_bodies.append(body)


func _on_door_body_exited(body):
	if !(body is CharacterBody3D or body is StaticBody3D): return
	
#	print("Removing body")
	
	if _spring_load_interrupted:
		if _colliding_bodies.is_empty():
			close()
			_spring_load_interrupted = false
	
	_colliding_bodies.erase(body)
