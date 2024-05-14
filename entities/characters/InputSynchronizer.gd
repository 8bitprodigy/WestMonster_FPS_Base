extends MultiplayerSynchronizer
class_name InputSynchronizer


signal input_ready
signal handled_input(event:InputEvent)


@export_category("Node Setup")
@export var character          : CharacterBody3D

# Called when the node enters the scene tree for the first time.
func _ready():
	emit_signal("ready")


@rpc("call_local")
func _input(event):
	emit_signal( "handled_input", event )
