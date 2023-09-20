@icon("res://sprites/icons/delay_node.svg")
extends Node
class_name DelayNode

@export var delay_time : float = 1.0

@export_node_path("Door", "Button", "Interactable") var listen_to_node_for_activate
@export_enum("Up", "Down", "Activated", "Deactivated", "Unlocked", "Opened", "Closed", "Destroyed") var signal_for_activate : String
var delay_timer

signal activated

# Called when the node enters the scene tree for the first time.
func _ready():
	if listen_to_node_for_activate:
		get_node(listen_to_node_for_activate).connect(signal_for_activate, activate)

func activate():
	delay_timer = get_tree().create_timer(delay_time)
	delay_timer.timeout.connect(timeout)

func timeout():
	emit_signal("activated")
