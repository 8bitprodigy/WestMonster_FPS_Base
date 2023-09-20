extends Interactable
class_name SwitchObject

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("Switch")
	super._ready()
