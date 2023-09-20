extends Node3D
class_name Loadout

@export_node_path("CharacterController") var _controller : NodePath
@onready var controller = get_node(_controller)
@export_node_path("Node3D") var _mount_point : NodePath
@onready var mount_point = get_node(_mount_point)
@export_node_path("Skeleton3D") var _hud_hands : NodePath
@onready var hud_hands = get_node(_hud_hands)
@export var current_item_index : int = 0
@export var previous_item_index : int = 0
var current_item : LoadoutEntity
var previous_item: LoadoutEntity
@export var loadout_categories : Array[LoadoutCategory]
var total_items : int = 0

# item sway variables
@export var horizontal_sway = 15
@export var vertical_sway = 15
@export var sway_threshold = 0.5
@export var sway_max_x : float = PI/16
@export var sway_max_y : float = PI/16
@export var sway_move : Vector2 = Vector2(PI/16,PI/16)
@export var sway_aim : Vector2 = Vector2(PI/5,PI/2)
var current_sway : Vector2 = Vector2.ZERO
@export var sway_lerp : float = 8
@export var sway_frequency : float = 1.25
@export var sway_aim_lerp : float = 8
@export var ADS_lerp : float = 20
var sway_amount = Vector2.ZERO

@onready var entities = $entities
@onready var shoulder = $shoulder
@onready var loadout_axes = $shoulder/loadout_x

var gun_heat : float

var request_primary_action : bool = false
var request_secondary_action : bool = false


enum {
	START,
	IDLE,
	BUSY,
	SWITCH_IN,
	SWITCH_OUT,
}
var state : int = START : set = set_state
signal state_changed
# State functions
func set_state(new_state : int):
	prints("Loadout New State: ", new_state)
	if state != new_state:
		var old_state = state
		state = new_state
		emit_signal("state_changed", new_state, old_state)

# Called when the node enters the scene tree for the first time.
func _ready():
	#$entities/gun.set_controller(controller)
	set_process(true)
	set_physics_process(true)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#global_transform = mount_point.global_transform
	shoulder.rotation.x = controller.shoulder.rotation.x
	gun_heat = 0.0
	
	if current_item:
		hud_hands.right_arm_ik.target = current_item.right_hand.global_transform
		hud_hands.right_arm_ik.start(true)
		hud_hands.left_arm_ik.target = current_item.left_hand.global_transform
		hud_hands.left_arm_ik.start(true)
	if entities.get_child_count()>0:
		gun_heat = current_item.spread_heat*rad_to_deg($entities/gun.MAX_SPREAD_X)
	#gun_heat = $entities/gun.spread_heat*rad_to_deg($entities/gun.MAX_SPREAD_X)

func _physics_process(_delta):
	if controller.is_multiplayer_authority():
		pass
	process_states(_delta)

func process_states(_delta):
	var current_item = get_current_item()
	match state:
		START:
			set_item_by_index(current_item_index)
			set_state(IDLE)
		IDLE:
			if controller.next_weapon:
				switch_item(1)
			if controller.previous_weapon:
				switch_item(-1)
		BUSY:
			pass
		SWITCH_IN:
			pass
		SWITCH_OUT:
			pass

func get_current_item():
	if entities.get_children().size()>0:
		return entities.get_child(entities.get_children().size()-1)
	return null

func get_total_items():
	total_items = 0
	for category in loadout_categories:
		total_items += category.loadout_items.size()
	prints("total items: ", total_items)
	return total_items

func switch_item(direction:int=0):
	prints("Direction: ", direction)
	if direction == 0: return
	previous_item_index = current_item_index
	get_total_items()
	current_item_index = (current_item_index+direction)%total_items
	prints("Current_item_index: ", current_item_index)
	set_item_by_index(current_item_index)
	

'''
func request_next_item():
	pass

func request_previous_item():
	pass

func request_recall_item():
	pass
'''
@rpc("call_local")
func set_item(item:PackedScene):
	prints("set item")
	var next_item = item.instantiate()
	#if !next_item is LoadoutEntity: return
	previous_item = current_item
	if entities.get_child_count() > 0:
		entities.remove_child(current_item)
	current_item = next_item
	current_item.set_controller(controller)
	#prints("Controller: ", current_item.controller)
	entities.add_child(current_item)
	current_item.switch_in()
	

func set_item_by_index(item_index:int=0):
	prints("set item by index")
	previous_item_index = current_item_index
	var current_category
	for category in loadout_categories:
		if item_index < category.loadout_items.size():
			current_category = category
			#prints("Current Category: ", current_category)
			break
		item_index = item_index - category.loadout_items.size()
	set_item(current_category.loadout_items[item_index].item_scene)

func set_item_by_name(item_name:String = ""):
	pass

func request_item_pushdown(item_name:String = ""):
	pass
