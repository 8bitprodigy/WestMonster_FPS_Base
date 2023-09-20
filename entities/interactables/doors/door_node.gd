extends Interactable
class_name DoorObject


func _ready():
	super._ready()


func receive_damage():
	if handler_node.health < 0: return
	handler_node.health -= 1
