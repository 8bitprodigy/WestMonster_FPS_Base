extends Interactable
class_name Door

#@export var health : float = -1.0
@export_enum("Open", "Closed") var spawn_position : int = 1
@export_enum("Open", "Closed") var state : int = 1
@export var locked : bool = false
@export var open_time : float = 1.0
@export_exp_easing var open_easing
@export var close_time : float = 1.0
@export_exp_easing var close_easing
@export var delay_before_close : float = 5.0

@export_enum("Open then wait", "Open then close", "One-shot") var interact_behavior : int = 1
@export_enum("Ignore", "Destroy","Unlock","Open","Unlock and Open") var kill_behavior : int = 0
@export_enum("Don't close", "Open on collision", "Damage obstruction") var obstruction_behavior : int = 0
@export_node_path("Interactable") var listen_to_node_for_unlock
@export_enum("Up", "Down", "Toggled", "Activated", "Deactivated", "Unlocked", "Opened", "Closed", "Destroyed") var signal_for_unlock : String
@export_node_path("Interactable") var listen_to_node_for_open
@export_enum("Up", "Down", "Toggled", "Activated", "Deactivated", "Unlocked", "Opened", "Closed", "Destroyed") var signal_for_open : String
@export_node_path("Interactable") var listen_to_node_for_close
@export_enum("Up", "Down", "Toggled", "Activated", "Deactivated", "Unlocked", "Opened", "Closed", "Destroyed") var signal_for_close : String

var door_tween
var door_timer
#@onready var door_timer = get_tree().create_timer(delay_before_close)

var door_fired = false
var door_moving = false

signal Unlocked
signal Opened
signal Closed
signal Destroyed

# Called when the node enters the scene tree for the first time.
func _ready():
	#door_timer.one_shot = true
	if listen_to_node_for_unlock:
		get_node(listen_to_node_for_unlock).connect(signal_for_unlock, unlock)
	if listen_to_node_for_open:
		get_node(listen_to_node_for_open).connect(signal_for_open, open)
	if listen_to_node_for_close:
		get_node(listen_to_node_for_close).connect(signal_for_close, close)
	super._ready()

func use(_user):
	if _user.is_using and _user.previous_using:return
	if door_fired: return
	if locked:
		try_locked()
		return
	if state == 0:
		close()
	else:
		open()

func try_locked():
	pass

func unlock():
	locked = false
	emit_signal("Unlocked")

func open():
	state = 0
	door_moving = true
	emit_signal("Opened")

func close():
	state = 1
	door_moving = true
	emit_signal("Closed")

func destroy():
	queue_free()
	emit_signal("Destroyed")

func obstructables(body):
	var test = false
	test = body is CharacterBody3D
	return test
