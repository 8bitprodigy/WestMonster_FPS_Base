@tool
#@icon("res://sprites/icons/delay_node.svg")
extends Node3D
class_name Interactable

@export_node_path var _handler_node
@onready var handler_node #= get_node(_handler_node) if _handler_node != null else null
@export var HEALTH : float = -1.0
var health : float = HEALTH

# Called when the node enters the scene tree for the first time.
func _ready():
	if _handler_node: handler_node = get_node(_handler_node)
	add_to_group("interactable")


func use(user):
	handler_node.use(user)
	
