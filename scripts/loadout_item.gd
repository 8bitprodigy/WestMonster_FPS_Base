extends Resource
class_name LoadoutItem

@export var slot_name : String = ""
@export var slot_category : String = ""
@export var slot_icon : ImageTexture
@export var start_picked_up : bool = false
@export var skip_selection : bool = false
@export var hide_in_menu : bool = false
@export var item_scene : PackedScene
