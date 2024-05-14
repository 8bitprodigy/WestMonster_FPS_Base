extends Camera3D
class_name HeadBob


# Head bob stuff
@export_node_path("Player") var _handler : NodePath
@onready var handler = get_node(_handler)
var bob_reset : float = 0.0
var bob_time : float = 0.0
@export_node_path("Camera3D") var _viewmodel_camera : NodePath
@onready var viewmodel_camera = get_node(_viewmodel_camera)
@export_node_path("Node3D") var _mount_point : NodePath
@onready var mount_point = get_node(_mount_point)
@export_node_path("Crosshairs") var _crosshairs : NodePath
@onready var crosshairs = get_node(_crosshairs)
@export var view_bob : bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	if !handler:
		set_process(false)
		return
	
	viewmodel_camera.set_environment(get_environment())
	if !is_multiplayer_authority():
		set_process(false)
		if crosshairs.show_crosshairs:
			crosshairs.show_crosshairs = false
			crosshairs.set_process(false)
			crosshairs.setup()
	else:
		if crosshairs.show_crosshairs:
			crosshairs.set_process(true)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_transform = mount_point.global_transform
	
	if view_bob: _head_bob(handler.velocity.length(),delta)
	viewmodel_camera.global_transform = global_transform
	
	pass


func _head_bob(movement_speed : float = 0.0, delta : float = 0.0) -> void:
	#if handler.velocity.length() == 0.0:
	#	get_parent().rotation.z = lerp(get_parent().rotation.z, bob_reset, delta/10)

	bob_time += delta
	var z_bob_amp = 0.2
	var z_bob_freq = 2
	var y_bob_amp = 1
	if handler.state==handler.CROUCH and handler._is_on_floor():
		z_bob_amp = 0.8
		z_bob_freq = 3.5
		y_bob_amp = 4

	if abs(handler.wishdir.length()) > 0.0 and handler._is_on_floor():
		var y_bob = sin(bob_time * (4 * PI)) * handler.velocity.length() * (movement_speed / 125.0) * y_bob_amp
		var z_bob = sin(bob_time * (z_bob_freq * PI)) * handler.velocity.length() * z_bob_amp
		#prints("Y-Bob: ", y_bob)
		rotation_degrees.x = y_bob
		rotation_degrees.z = z_bob
	else:
		rotation = rotation.lerp(Vector3(0,rotation.y,0), delta*5)
