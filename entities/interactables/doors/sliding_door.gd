@icon("res://sprites/icons/sliding_door.svg")
extends Door

class_name Sliding_Door

@export var move_amount : float = 1.0
@export_enum("Up", "Down", "Left", "Right") var move_direction : int = 2
enum{
	UP,
	DOWN,
	LEFT,
	RIGHT
}
@export_enum("Proximity", "Front proximity", "Back proximity", "None") var proximity_behavior : int = 0
@export_enum("Use", "Use front", "Use Back") var use_behavior : int = 0


@export_node_path("Interactable") var external_controller
@export_enum("Rotating") var control_signal : String = "Rotating"

@onready var open_speed = move_amount/open_time
@onready var close_speed = move_amount/close_time

var body_in_front_trigger: bool = false
var body_in_back_trigger: bool = false

enum{
	OPEN,
	CLOSE
}

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	if external_controller:
		get_node(external_controller).connect(control_signal, control)
	pass # Replace with function body.

func _physics_process(delta):
	if !door_moving: return
	var collider : KinematicCollision3D
	if state == OPEN:
		match move_direction:
			UP:
				if $door.position.y >= move_amount:
					$door.position.y = move_amount
					door_moving = false
					return
				collider = $door.move_and_collide(global_transform.basis * Vector3(0,open_speed*delta,0))
			DOWN:
				if $door.position.y <= -move_amount:
					$door.position.y = -move_amount
					door_moving = false
					return
				collider = $door.move_and_collide(global_transform.basis * Vector3(0,-open_speed*delta,0))
			LEFT:
				if $door.position.x >= move_amount:
					$door.position.x = move_amount
					door_moving = false
					return
				collider = $door.move_and_collide(global_transform.basis * Vector3(open_speed*delta,0,0))
			RIGHT:
				if $door.position.x <= -move_amount:
					$door.position.x = -move_amount
					door_moving = false
					return
				collider = $door.move_and_collide(global_transform.basis * Vector3(-open_speed*delta,0,0))
		
	else:
		match move_direction:
			UP:
				if $door.position.y <= 0:
					$door.position.y = 0
					door_moving = false
					return
				collider = $door.move_and_collide(global_transform.basis * Vector3(0,-close_speed*delta,0))
			DOWN:
				if $door.position.y >= 0:
					$door.position.y = 0
					door_moving = false
					return
				collider = $door.move_and_collide(global_transform.basis * Vector3(0,close_speed*delta,0))
			LEFT:
				if $door.position.x <= 0:
					$door.position.x = 0
					door_moving = false
					return
				collider = $door.move_and_collide(global_transform.basis * Vector3(-close_speed*delta,0,0))
			RIGHT:
				if $door.position.x >= 0:
					$door.position.x = 0
					door_moving = false
					return
				collider = $door.move_and_collide(global_transform.basis * Vector3(close_speed*delta,0,0))
	if collider:
		if obstruction_behavior == 1:
			if state == 0:
				close()
			elif state == 1:
				open()
			return
		for i in range(0,collider.get_collision_count()):
			if collider.get_collider(i).has_method("receive_damage"):
				collider.get_collider(i).receive_damage()
		if state == 0:
			close()
		elif state == 1:
			open()

func use(user):
	match use_behavior:
		0:
			super.use(user)
		1:
			if body_in_front_trigger: super.use(user)
		2:
			if body_in_back_trigger: super.use(user)

func try_locked():
	$door/locked_sound.play()

func unlock():
	super.unlock()

func open():
	if state == 0: return
	if locked or door_fired:
		try_locked()
		return
	$door/open_sound.play()
	match interact_behavior:
			0:
				pass
			1:
				door_timer = get_tree().create_timer(delay_before_close+open_time)
				door_timer.timeout.connect(close)
			2:
				door_fired = true
	super.open()

func close():
	if state == 1: return
	if (body_in_back_trigger or body_in_front_trigger) and obstruction_behavior == 0: 
		door_timer = get_tree().create_timer(delay_before_close+open_time)
		door_timer.timeout.connect(close)
		return
	if door_fired: return
	$door/close_sound.play()
	match interact_behavior:
			0:
				pass
			1:
				pass
			2:
				door_fired = true
	super.close()


func control(open_scalar:float=0.0):
	var temp_move : float = move_amount*open_scalar
	var collider : KinematicCollision3D
	match move_direction:
		UP:
			if $door.position.y >= move_amount:
				$door.position.y = move_amount
				door_moving = false
				return
			collider = $door.move_and_collide(global_transform.basis * Vector3(0,temp_move-$door.position.y,0))
		DOWN:
			if $door.position.y <= -move_amount:
				$door.position.y = -move_amount
				door_moving = false
				return
			collider = $door.move_and_collide(global_transform.basis * Vector3(0,-(temp_move-$door.position.y),0))
		LEFT:
			if $door.position.x >= move_amount:
				$door.position.x = move_amount
				door_moving = false
				return
			collider = $door.move_and_collide(global_transform.basis * Vector3((temp_move-$door.position.x),0,0))
		RIGHT:
			if $door.position.x <= -move_amount:
				$door.position.x = -move_amount
				door_moving = false
				return
			collider = $door.move_and_collide(global_transform.basis * Vector3(-(temp_move-$door.position.x),0,0))
	if collider:
		if obstruction_behavior == 1:
			if state == 0:
				close()
			elif state == 1:
				open()
			return
		for i in range(0,collider.get_collision_count()):
			if collider.get_collider(i).has_method("receive_damage"):
				collider.get_collider(i).receive_damage()
		if state == 0:
			close()
		elif state == 1:
			open()
	pass

func destroy():
	super.destroy()

func _on_front_trigger_body_entered(body):
	if !(body is CharacterBody3D): return
	if body_in_back_trigger: return
	body_in_front_trigger = true
	if !door_moving:
		match proximity_behavior:
			0:
				open()
			1:
				open()

func _on_front_trigger_body_exited(_body):
	if $front_trigger.get_overlapping_bodies().any(obstructables):
		return
	body_in_front_trigger = false

func _on_back_trigger_body_entered(body):
	if !(body is CharacterBody3D): return
	if body_in_front_trigger: return
	body_in_back_trigger = true
	if !door_moving:
		match proximity_behavior:
			0:
				open()
			2:
				open()
			

func _on_back_trigger_body_exited(_body):
	if $back_trigger.get_overlapping_bodies().any(obstructables):
		return
	body_in_back_trigger = false
