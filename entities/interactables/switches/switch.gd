@icon("res://sprites/icons/switch.svg")
extends Interactable
class_name Switch

enum {
	MOMENTARY,
	TOGGLE
}
enum {
	UP,
	DOWN
}

#@export var _health : float = -1
#@onready var health = _health
@export var active : bool = true
@export var one_shot : bool = false
var shot = false
@export_enum("momentary", "toggle") var switch_type : int = MOMENTARY
@export_enum("Up", "Down") var state : int = 0

@export_node_path("Door", "Button", "Interactable") var listen_to_node_for_activate
@export_enum("Up", "Down", "Activated", "Deactivated", "Unlocked", "Opened", "Closed", "Destroyed") var signal_for_activate : String
@export_node_path("Door", "Button", "Interactable") var listen_to_node_for_deactivate
@export_enum("Up", "Down", "Activated", "Deactivated", "Unlocked", "Opened", "Closed", "Destroyed") var signal_for_deactivate : String
@export_node_path("Door", "Button", "Interactable") var listen_to_node_for_toggle
@export_enum("Up", "Down", "Activated", "Deactivated", "Unlocked", "Opened", "Closed", "Destroyed") var signal_for_toggle : String
@export_node_path("Door", "Button", "Interactable") var listen_to_node_for_up
@export_enum("Up", "Down", "Activated", "Deactivated", "Unlocked", "Opened", "Closed", "Destroyed") var signal_for_up : String
@export_node_path("Door", "Button", "Interactable") var listen_to_node_for_down
@export_enum("Up", "Down", "Activated", "Deactivated", "Unlocked", "Opened", "Closed", "Destroyed") var signal_for_down : String

signal Activated
signal Deactivated
signal Up
signal Down
signal Toggled
signal Destroyed

# Called when the node enters the scene tree for the first time.
func _ready():
	if listen_to_node_for_activate:
		get_node(listen_to_node_for_activate).connect(signal_for_activate, activate)
	if listen_to_node_for_deactivate:
		get_node(listen_to_node_for_deactivate).connect(signal_for_deactivate, deactivate)
	if listen_to_node_for_toggle:
		get_node(listen_to_node_for_toggle).connect(signal_for_toggle, use(self))
	if listen_to_node_for_up:
		get_node(listen_to_node_for_up).connect(signal_for_up, button_up)
	if listen_to_node_for_down:
		get_node(listen_to_node_for_down).connect(signal_for_down, button_down)
	super._ready()
	pass # Replace with function body.

func use(body):
	if body.is_using and body.previous_using: return
	if !active: return
	if one_shot and shot: return
	elif one_shot and !shot: shot = true
	if switch_type == MOMENTARY:
		button_down()
	else:
		if state == UP:
			button_down()
		else:
			button_up()
	#super.use(body)

func activate():
	active = true
	$activate_sound.play()
	emit_signal("Activated")

func deactivate():
	active = false
	$deactivate_sound.play()
	emit_signal("Deactivated")

func button_up():
	$AnimationPlayer.play("up")
	$up_sound.play()
	state = UP
	if switch_type == TOGGLE:emit_signal("Toggled")
	emit_signal("Up")

func button_down():
	if switch_type == MOMENTARY:
		$AnimationPlayer.play("press")
	else:
		$AnimationPlayer.play("down")
		$down_sound.play()
		emit_signal("Toggled")
		state = DOWN
	emit_signal("Down")

func destroy():
	active = false
	$destroy_sound.play()
	emit_signal("Destroyed")

func receive_damage():
	if health < 0: return
	health -= 1
	if health <= 0: destroy()
