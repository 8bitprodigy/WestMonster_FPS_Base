extends Interactable
class_name Dial

@export var MAX_ROTATIONS : float = TAU
@export var ROTATION_SPEED : float = PI/5
@export var STARTING_ROTATION : float = 0.0
var dial_rotation : float = STARTING_ROTATION
enum{CLOCKWISE=1,COUNTER_CLOCKWISE=-1}
@export_enum("Clockwise:1", "Counter-Clockwise:-1") var STARTING_ROTATION_DIRECTION : int = COUNTER_CLOCKWISE
var rotation_direction : int = STARTING_ROTATION_DIRECTION
enum{OFF=0,CLOSE=1,OPEN=-1}
@export_enum("Off:0", "Close:1", "Open:-1") var AUTO_RESET : int = 0
@export var _DELAY_BEFORE_RESET : float = 0.0
@onready var delay_before_reset : float = (_DELAY_BEFORE_RESET * 1000) + 25

signal Rotating
signal Reset_Started
signal Closed
signal Opened
enum{
	CLOSED,
	OPENED,
	MIDWAY
}
var state : int = CLOSED
var tween : Tween

var last_use_time : int = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	$Area3D/CollisionShape3D/knob.rotation.y = dial_rotation
	if dial_rotation == 0:state = OPENED
	elif dial_rotation == MAX_ROTATIONS:state = CLOSED
	else: state = MIDWAY
	emit_signal("Rotating",dial_rotation/MAX_ROTATIONS)
	$Timer.connect("timeout",_on_timer_timeout)
	tween = create_tween()
	prints("Delay Before Reset: ", delay_before_reset)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if tween.is_running():
		emit_signal("Rotating",dial_rotation/MAX_ROTATIONS)
		$Area3D/CollisionShape3D/knob.rotation.y = dial_rotation
	

func use(user):
	if AUTO_RESET != OFF:
		#if !$Timer.is_stopped(): $Timer.wait_time = (delay_before_reset)/1000.0
		#else: 
		$Timer.start((delay_before_reset)/1000.0)
		#$Timer.connect("timeout",_on_timer_timeout)
		prints("Timer: ", $Timer.time_left)
	if tween.is_running(): tween.stop()
	#prints("Dial being used by ", user)
	var new_time = Time.get_ticks_msec()
	if new_time > last_use_time+25:
		rotation_direction = -rotation_direction
		#prints("Rotation direction: ", rotation_direction)
	last_use_time = new_time
	dial_rotation += rotation_direction * ROTATION_SPEED * get_physics_process_delta_time()
	
	#prints("Dial rotation: ", dial_rotation)
	if dial_rotation <= 0: 
		dial_rotation = 0
		#rotation_direction = CLOCKWISE
		emit_signal("Opened")
	elif dial_rotation >= MAX_ROTATIONS:
		dial_rotation = MAX_ROTATIONS
		#rotation_direction = COUNTER_CLOCKWISE
		emit_signal("Closed")
	else:
		emit_signal("Rotating",dial_rotation/MAX_ROTATIONS)
	
	$Area3D/CollisionShape3D/knob.rotation.y = dial_rotation

func _on_timer_timeout():
	if Time.get_ticks_msec() < last_use_time+25: return
	prints("Timeout!")
	var reset_value = 0 if AUTO_RESET == CLOSE else MAX_ROTATIONS
	var time = abs(reset_value-dial_rotation)/ROTATION_SPEED
	rotation_direction = -AUTO_RESET
	tween = create_tween()
	tween.tween_property(self,"dial_rotation",reset_value,time)
