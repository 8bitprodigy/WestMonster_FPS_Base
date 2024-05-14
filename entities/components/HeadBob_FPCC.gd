extends WM_Component
class_name HeadBob_FPCC


@export_category("Node Setup")
@export var character : CharacterBody3D

# Called when the node enters the scene tree for the first time.
func _ready():
	if !character or !(parent is FirstPersonCameraController):
		set_enabled(false)
		return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
