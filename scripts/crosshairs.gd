extends Control
class_name Crosshairs

@export_node_path("Player") var _handler : NodePath
@onready var handler = get_node(_handler)
@export_node_path("Loadout") var _loadout : NodePath
@onready var loadout = get_node(_loadout)

@export var show_crosshairs : bool = true

@export_range(2,50) var HAIR_LENGTH : int = 5
@export_range(1,10) var HAIR_WIDTH : int = 2
@export_range(2,50) var HAIR_RADIUS : int = 3
var hair_radius : float = float(HAIR_RADIUS)
var _hair_radius : float = float(HAIR_RADIUS)
@export_range(1,10) var HAIR_RADIUS_MOVEMENT_MULTIPLIER : int = 2
@export_color_no_alpha var HAIR_COLOR : Color = Color.WHITE
@export_range(0,1) var HAIR_ALPHA : float = 1.0
@export var HAIR_WIDTH_CURVE : Curve
@export var SHOW_TOP_HAIR : bool = true
@export var SHOW_BOTTOM_HAIR : bool = true

@export var SHOW_CENTER_DOT : bool = true
@export_range(1,10) var CENTER_DOT_RADIUS : int = 1
@export var CENTER_DOT_COLOR : Color = Color.WHITE
@export_range(0,1) var CENTER_DOT_ALPHA : float = 1.0

@onready var top_hair = $top_hair
@onready var bottom_hair = $bottom_hair
@onready var left_hair = $left_hair
@onready var right_hair = $right_hair
@onready var center_dot = $center_dot

@onready var half_size_x = size.x/2
@onready var half_size_y = size.y/2
@onready var half_size = Vector2(half_size_x,half_size_y)


var fade_tween : Tween

var _delta = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(show_crosshairs)
	setup()
	fade_tween = create_tween()
	fade_tween.stop()
	pass # Replace with function body.

func setup():
	visible = show_crosshairs
	if !show_crosshairs: return
	
	half_size_x = size.x/2
	half_size_y = size.y/2
	half_size = Vector2(half_size_x,half_size_y)

	top_hair.points[0] = half_size
	bottom_hair.points[0] = half_size
	left_hair.points[0] = half_size
	right_hair.points[0] = half_size
	
	top_hair.points[1] = top_hair.points[0] - Vector2(0,HAIR_LENGTH)
	bottom_hair.points[1] = bottom_hair.points[0] + Vector2(0,HAIR_LENGTH)
	left_hair.points[1] = left_hair.points[0] - Vector2(HAIR_LENGTH,0)
	right_hair.points[1] = right_hair.points[0] + Vector2(HAIR_LENGTH,0)
	
	_hair_radius = hair_radius * HAIR_RADIUS_MOVEMENT_MULTIPLIER
	#prints("Hair Raidus: ", _hair_radius)
	
	top_hair.position.y = -(_hair_radius+HAIR_RADIUS)
	bottom_hair.position.y = (_hair_radius+HAIR_RADIUS)
	left_hair.position.x = -(_hair_radius+HAIR_RADIUS)
	right_hair.position.x = (_hair_radius+HAIR_RADIUS)
	
	top_hair.width = HAIR_WIDTH
	bottom_hair.width = HAIR_WIDTH
	left_hair.width = HAIR_WIDTH
	right_hair.width = HAIR_WIDTH
	
	top_hair.default_color = Color(HAIR_COLOR, HAIR_ALPHA)
	bottom_hair.default_color =  Color(HAIR_COLOR, HAIR_ALPHA)
	left_hair.default_color =  Color(HAIR_COLOR, HAIR_ALPHA)
	right_hair.default_color =  Color(HAIR_COLOR, HAIR_ALPHA)
	
	if HAIR_WIDTH_CURVE:
		top_hair.width_curve = HAIR_WIDTH_CURVE
		bottom_hair.width_curve = HAIR_WIDTH_CURVE
		left_hair.width_curve = HAIR_WIDTH_CURVE
		right_hair.width_curve = HAIR_WIDTH_CURVE
	
	top_hair.visible = SHOW_TOP_HAIR
	bottom_hair.visible = SHOW_BOTTOM_HAIR
	
	center_dot.size = Vector2(2*CENTER_DOT_RADIUS,2*CENTER_DOT_RADIUS)
	center_dot.position = Vector2(half_size_x-CENTER_DOT_RADIUS,half_size_y-CENTER_DOT_RADIUS)
	center_dot.color = Color(CENTER_DOT_COLOR, CENTER_DOT_ALPHA)
	center_dot.visible = SHOW_CENTER_DOT
	
	#prints("Crosshairs set up.")
	pass

func fade(fade_out:bool):
	#if fade_tween.is_running(): return
	if fade_out:
		#fade_tween = create_tween()
		#fade_tween.tween_property(self,"modulate:a",0.0,0.125)
		modulate.a = lerp(modulate.a ,0.0,_delta*15)
	else:
		#fade_tween = create_tween()
		#fade_tween.tween_property(self,"modulate:a",1.0,0.125)
		modulate.a = lerp(modulate.a ,1.0,_delta*15)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !show_crosshairs: return
	_delta = delta
	
	hair_radius = 0
	if handler:
		hair_radius += int(handler.velocity.length())
		fade(handler._can_aim() and handler.is_aiming)
	if loadout:
		hair_radius += int(loadout.gun_heat*50)
	setup()
	pass
