@icon("res://sprites/icons/repeat_node.svg")
extends Node
class_name RepeatNode

@export var repeat_time : float = 1.0
@export var repeat_number_of_times : int = -1

@export_node_path("Door", "Button", "Interactable") var listen_to_node_for_activate
@export_enum("Up", "Down", "Activated", "Deactivated", "Unlocked", "Opened", "Closed", "Destroyed") var signal_for_activate : String
var repeat_timer

signal activated

# Called when the node enters the scene tree for the first time.
func _ready():
	if listen_to_node_for_activate:
		get_node(listen_to_node_for_activate).connect(signal_for_activate, activate)


func activate():
	if repeat_number_of_times == 0: return
	emit_signal("activated")
	repeat_number_of_times -= 1 if repeat_number_of_times > 0 else -1
	repeat_timer = get_tree().create_timer(repeat_time)
	repeat_timer.timeout.connect(activate)
