extends LoadoutEntity
class_name Gun

@export var gun_name : String = ""

@export_category("Special Nodes")
#@export_node_path("CharacterController") var _controller
#@onready var controller = get_node(_controller)
@export_node_path("Marker3D") var _muzzle
@onready var muzzle = get_node(_muzzle)
@export_node_path("Marker3D") var _right_hand
@onready var right_hand = get_node(_right_hand)
@export_node_path("Marker3D") var _left_hand
@onready var left_hand = get_node(_left_hand)
@export_node_path("GPUParticles3D") var _muzzle_flash
@onready var muzzle_flash = get_node(_muzzle_flash)
@export_node_path("Marker3D") var _ADS
@onready var ADS = get_node(_ADS)
@export_node_path("Timer") var _ADS_TIMER
@onready var ads_timer = get_node(_ADS_TIMER)
@export_node_path("Skeleton3D") var _skeleton
@onready var skeleton = get_node(_skeleton)
@export_node_path("MeshInstance3D") var _first_person_gun_mesh
@onready var first_person_gun_mesh = get_node(_first_person_gun_mesh)
@export_node_path("MeshInstance3D") var _world_gun_mesh
@onready var world_gun_mesh = get_node(_world_gun_mesh)
@export_node_path("Node3D") var _sounds_node
@onready var sounds = get_node(_sounds_node)
@export_node_path("Timer") var _fire_timer
@onready var fire_timer = get_node(_fire_timer)
@export_node_path("AnimationPlayer") var _animator
@onready var animator = get_node(_animator)

#@export_category("Action requests")
var request_primary : bool = false
var request_secondary : bool = false
var request_reload : bool = false
var request_switch_out : bool = false

#@export_category("Various operational states")
var chamber_loaded : bool = true
var bolt_locked_back : bool = false
var has_mag_inserted : bool = true
var can_fire : bool = true
var firing : bool = false
var can_secondary : bool = true
var secondary_firing : bool = false

@export var default_position : Vector3 = Vector3(0.25,0,-0.5)
@export_category("Gun features")
@export var ADS_IN_TIME : float = 0.5
@export var ADS_OUT_TIME : float = 0.5
@export var refactory_time : float = 0.1
@export var projectile_info : ProjectileInfo
@export var has_last_round_bolt_hold_open : bool = false
@export var is_select_fire : bool = true
@export_flags("Safe","Semi Automatic","Full Automatic","Burst-Fire") var fire_selections : int = 6
const SAFE = 1
const SEMI = 2
const AUTO = 4
const BURST = 8
@export_enum("Safe:1","Semi Automatic:2","Full Automatic:4","Burst-Fire:8") var fire_position : int = 2
@export var is_auto_loader : bool = true
@export var is_handgun : bool = false
@onready var has_secondary_fire : bool = false


var first_person_animations : bool = false
var anim_tree : AnimationTree
var anim_state_machine : AnimationNodeStateMachinePlayback
var busy : bool = false

var _delta : float = 0.0

var time : float = 0.0
var current_time : float = 0.0
var shooter_spd : float = 0.0

const RAY_LENGTH : float = 1000.0

## How tight the shot grouping
@export_category("Barrel Precision") 
@export var MIN_SPREAD_X : float = 0.01
@export var MAX_SPREAD_X : float = 0.025
@export var MUZZLE_SPREAD_CURVE_X : Curve

@export var MIN_SPREAD_Y : float = 0.01
@export var MAX_SPREAD_Y : float = 0.025
@export var MUZZLE_SPREAD_CURVE_Y : Curve
@onready var spread_heat : float = 0.0
@onready var spread_delta : float = 1.0

@export var SHOTS_TO_MAX_SPREAD : int = 50
@onready var spread_step = 1.0/SHOTS_TO_MAX_SPREAD
@export var SPREAD_COOLDOWN_TIME : float = 5.0
@onready var last_shot_time : float = 0.0

@onready var spread_tween : Tween


@export_category("Barrel Accuracy") ## Placement of the shot grouping
@export var MIN_BIAS : float = 0.0
@export var MAX_BIAS : float = 0.125
@export_range(0,TAU) var BIAS_ANGLE : float = 1.5708

@onready var MIN_BIAS_X : float = cos(BIAS_ANGLE)*MIN_BIAS
@onready var MAX_BIAS_X : float = cos(BIAS_ANGLE)*MAX_BIAS
@onready var MIN_BIAS_Y : float = sin(BIAS_ANGLE)*MIN_BIAS
@onready var MAX_BIAS_Y : float = sin(BIAS_ANGLE)*MAX_BIAS

@export var MUZZLE_BIAS_CURVE_X : Curve
@export var MUZZLE_BIAS_CURVE_Y : Curve
@onready var bias_heat : float = 0.0

@export var SHOTS_TO_MAX_BIAS : int = 50
@onready var bias_step = 1.0/SHOTS_TO_MAX_BIAS
@export var BIAS_COOLDOWN_TIME : float = 5.0

@onready var bias_tween : Tween 


@export_category("Recoil") ## How far rearward the gun moves as it fires
@export var SHOTS_TO_MAX_RECOIL : int = 10
@onready var recoil : float = 0.0
@export var MAX_RECOIL : float = -0.05
@onready var _recoil_step = MAX_RECOIL/SHOTS_TO_MAX_RECOIL


@export_category("Muzzle Climb")
@export var MAX_MUZZLE_CLIMB : float = PI/3
@export var MAX_MUZZLE_CLIMB_ADS : float = PI/6
@export var SHOTS_TO_MAX_CLIMB : int = 8
@onready var _climb_step = MAX_MUZZLE_CLIMB/SHOTS_TO_MAX_CLIMB
@onready var _climb_step_ads = MAX_MUZZLE_CLIMB_ADS/SHOTS_TO_MAX_CLIMB


@export_category("Sway") ## How far laterally the gun moves as it fires
@export var MAX_MUZZLE_SWAY : float = PI/4
@export var SHOTS_TO_MAX_SWAY : int = 8
@onready var _sway_step = MAX_MUZZLE_SWAY/SHOTS_TO_MAX_SWAY


@export var _projectile = preload("res://entities/weapons/projectile.tscn")


# States and state-related variables
enum {
	SWITCH_IN,
	IDLE,
	PRIMARY,
	SECONDARY,
	MAG_DROP,
	RELOAD,
	CHARGE,
	SWITCH_OUT,
}
var state : int = IDLE
signal state_changed
signal switched_out
var temp_muzzle_blast1 : Mesh
var temp_muzzle_blast2 : Mesh

func set_weapon_state(new_state : int):
	if state != new_state:
		var old_state = state
		state = new_state
		emit_signal("state_changed", new_state, old_state)

# Called when the node enters the scene tree for the first time.
func _ready():
	fire_timer.connect("timeout",refactory)
	MUZZLE_SPREAD_CURVE_X.bake()
	MUZZLE_SPREAD_CURVE_Y.bake()
	MUZZLE_BIAS_CURVE_X.bake()
	MUZZLE_BIAS_CURVE_Y.bake()
	prints("Max X Bias: ", MAX_BIAS_X, " | Y: ", MAX_BIAS_Y)
	
	temp_muzzle_blast1 = muzzle_flash.draw_pass_1
	temp_muzzle_blast2 = muzzle_flash.draw_pass_2
	
	spread_tween = create_tween()
	spread_tween.tween_property(self,"",null,0)
	bias_tween = create_tween()
	bias_tween.tween_property(self,"",null,0)
	
	
	#for i in gun_mesh.get_
	#muzzle_flash.layers = 2
	if is_multiplayer_authority():
		world_gun_mesh.hide()
		first_person_gun_mesh.show()
	else:
		world_gun_mesh.show()
		first_person_gun_mesh.hide()
	pass # Replace with function body.

func _process(delta):
	_delta = delta
	current_time = float(Time.get_ticks_msec())/1000.0
	primary_action(controller.primary_pressed,controller.primary_just_pressed,controller.primary_just_released)
	secondary_action(controller.secondary_pressed,controller.secondary_just_pressed,controller.secondary_just_released)
	if controller.reload_just_pressed:
		request_reload = true

func _physics_process(delta):
	process_state(delta)

func process_state(delta):
	_delta = delta
	match state:
		SWITCH_IN:
			if !animator.is_playing():
				set_weapon_state(IDLE)
		IDLE:
			if request_primary and chamber_loaded:
				request_primary = false
				#prints("Shot Count: ", temp)
				#temp = temp+1 if temp<10 else 0
				set_weapon_state(PRIMARY)
			elif has_secondary_fire and request_secondary:
				request_secondary = false
				set_weapon_state(SECONDARY)
			elif request_reload:
				set_weapon_state(MAG_DROP)
			elif !has_mag_inserted:
				set_weapon_state(RELOAD)
			elif !chamber_loaded:
				set_weapon_state(CHARGE)
			elif request_switch_out:
				set_weapon_state(SWITCH_OUT)
			
			_weapon_bob()
			pass
		PRIMARY:
			if controller._can_aim() and controller.is_aiming:
				_weapon_bob()
			pass
		SECONDARY:
			_weapon_bob()
			pass
		MAG_DROP:
			_weapon_bob()
			drop_mag()
			pass
		RELOAD:
			_weapon_bob()
			insert_mag()
			pass
		CHARGE:
			_weapon_bob()
			pass
		SWITCH_OUT:
			if !animator.is_playing():
				emit_signal("switched_out")
				set_process(false)
				set_physics_process(false)
			pass
	
	request_primary = false
	request_secondary = false
	request_reload = false
	request_switch_out = false


# Weapon bob variables
@export_category("Weapon Bob Variables.") ## How the gun moves around as the player moves
@export var weapon_bob : bool = true
@export var weapon_run_bob : bool = true
@export var WEAPON_BOB_FREQUENCY : float = 0.5
@export var WEAPON_BOB_AIM_FREQUENCY : float = 0.75
@onready var wpn_bob_freq : float = WEAPON_BOB_FREQUENCY
@export var WEAPON_BOB_HEIGHT : float = 0.05125
@export var WEAPON_BOB_AIM_HEIGHT : float = 0.025/2
@onready var wpn_bob_y : float = WEAPON_BOB_HEIGHT
@export var WEAPON_BOB_WIDTH : float = 0.05
@export var WEAPON_BOB_AIM_WIDTH : float = 0.025/2
@onready var wpn_bob_x : float = WEAPON_BOB_WIDTH
@export var WEAPON_BOB_PITCH : float = 0.05
@export var WEAPON_BOB_AIM_PITCH : float = 0.02/2
@onready var wpn_bob_rx : float = WEAPON_BOB_PITCH
@export var WEAPON_BOB_YAW : float = 0.05
@export var WEAPON_BOB_AIM_YAW : float = 0.025/2
@onready var wpn_bob_ry : float = WEAPON_BOB_YAW
@export var WEAPON_BOB_ROLL : float = 0.25
@export var WEAPON_BOB_AIM_ROLL : float = 0.125/2
@onready var wpn_bob_rz : float = WEAPON_BOB_ROLL
# Weapon sway variables
@export_category("Weapon Sway Variables.")
@export var weapon_sway : bool = true
@export var sway_move : Vector2 = Vector2(PI/24,PI/24)
@export var sway_move_ADS : Vector2 = Vector2(PI/32,PI/32)
@export var sway_aim : Vector2 = Vector2(PI/6,PI/6)
@export var sway_aim_ADS : Vector2 = Vector2(PI/12,PI/12)
var current_sway : Vector2 = Vector2.ZERO
@export var sway_lerp : float = 8
@export var sway_aim_lerp : float = 8
@export var sway_frequency : float = 1.25
var sway_amount = Vector2.ZERO

@export_category("Weapon Lean Variables.")
@export var weapon_lean_rotation : float = PI/12
@export var weapon_lean_lerp : float = 4.0
var lean_rotation : float = 0.0

var controller_x_rotation : float = 0.0
var controller_y_rotation : float = 0.0
var prev_controller_x_rotation : float = 0.0
var prev_controller_y_rotation : float = 0.0

@rpc("call_local")
func _weapon_bob():
	if controller == null: return
	# Get the character's look rotations
	controller_x_rotation = controller.shoulder.rotation.x
	controller_y_rotation = controller.torso.rotation.y
	
	current_sway -= Vector2(lerp_angle(prev_controller_y_rotation,controller_y_rotation,1.0)-prev_controller_y_rotation, lerp_angle(prev_controller_x_rotation,controller_x_rotation,1.0)-prev_controller_x_rotation)
	var wpn_sway_move : Vector2
	var wpn_sway_aim : Vector2
	var target_transform : Transform3D = Transform3D.IDENTITY
	if controller._can_aim() and controller.is_aiming and !has_secondary_fire:
		busy = true
		#controller.is_aiming = true
		wpn_bob_freq = WEAPON_BOB_AIM_FREQUENCY
		wpn_bob_x = WEAPON_BOB_AIM_WIDTH
		wpn_bob_y = WEAPON_BOB_AIM_HEIGHT
		wpn_bob_rz = WEAPON_BOB_AIM_ROLL
		wpn_sway_move = sway_move_ADS
		wpn_sway_aim = sway_aim_ADS
		
		var weight = (ADS_IN_TIME - ads_timer.time_left)/ADS_IN_TIME
		target_transform = controller.head.global_transform.translated(controller.head.global_transform.basis.z*-controller.eye_relief)
		target_transform.origin = target_transform.origin - (ADS.global_position - global_position)
		global_transform = global_transform.interpolate_with(target_transform,weight)
		#prints("ADS in weight: ", weight)
	else:
		if can_fire:
			busy = false
		#controller.is_aiming = false
		wpn_bob_freq = WEAPON_BOB_FREQUENCY
		wpn_bob_x = WEAPON_BOB_WIDTH
		wpn_bob_y = WEAPON_BOB_HEIGHT
		wpn_bob_rz = WEAPON_BOB_ROLL
		wpn_sway_move = -sway_move
		wpn_sway_aim = sway_aim
		
		var weight = (ADS_OUT_TIME - ads_timer.time_left)/ADS_IN_TIME
		target_transform = Transform3D(controller.shoulder.basis,controller.shoulder.basis*default_position)#.rotated(,controller.shoulder.rotation.x)
		transform = transform.interpolate_with(target_transform,weight)
		#prints("ADS out weight: ", weight)
	
	if weapon_sway:
		var temp_x_sway = Common.sig(sway_frequency*current_sway.y,2*wpn_sway_move.y,-wpn_sway_move.y)
		var temp_y_sway = Common.sig(sway_frequency*current_sway.x,2*wpn_sway_move.x,-wpn_sway_move.x)
		
		transform = transform.rotated(transform.basis.x,temp_x_sway)
		transform = transform.rotated(transform.basis.y,temp_y_sway)
	
	if weapon_run_bob:
		if controller.state == controller.RUN and controller.velocity.length() > 0.0 and !is_handgun:
			skeleton.basis = skeleton.basis.slerp(Basis.IDENTITY.rotated(skeleton.basis.y,2.35619),_delta*8.0)
		else: 
			skeleton.basis = skeleton.basis.slerp(Basis.IDENTITY,_delta*8.0)
	
	
	if weapon_bob:
		var shtr_vel = controller.velocity.length() if controller._is_on_floor() else 0.0
		shooter_spd = lerp(shooter_spd, shtr_vel, 5.0*_delta)#shooter.vel.length()#*0.5#
		var shtr_spd = (shooter_spd*1.5) + 1
		
		time = fmod(time+(_delta*shtr_spd),PI*8)
		
		var trans_y_mod = sin(time*(wpn_bob_freq*2))*0.025*(wpn_bob_y/2)*shtr_spd
		var trans_x_mod = cos(time*wpn_bob_freq)*0.025*wpn_bob_x*shtr_spd
		var rot_x_mod = sin(time*wpn_bob_freq*2)*0.1*(wpn_bob_rx*shtr_spd)
		var rot_y_mod = cos(time*wpn_bob_freq)*0.1*(wpn_bob_ry*shtr_spd)
		var rot_z_mod = -sin(time*wpn_bob_freq)*0.1*(wpn_bob_rz)
		#prints("Rotation, Y: ", wpn_bob_rx*shtr_spd)
		$gun.position = Vector3.ZERO
		$gun.position += Vector3(trans_x_mod,trans_y_mod,0)*basis
		
		$gun.basis = Basis.IDENTITY
		$gun.basis = $gun.basis.rotated($gun.basis.x,rot_x_mod+Common.sig(sway_frequency*current_sway.y,2*wpn_sway_aim.y,-wpn_sway_aim.y))
		$gun.basis = $gun.basis.rotated($gun.basis.y,rot_y_mod+Common.sig(sway_frequency*current_sway.x,2*wpn_sway_aim.x,-wpn_sway_aim.x))
		$gun.basis = $gun.basis.rotated($gun.basis.z, rot_z_mod)
	
	lean_rotation = lerp_angle(lean_rotation,weapon_lean_rotation*controller.lean_strength,weapon_lean_lerp*_delta)
	$gun.basis = $gun.basis.rotated($gun.basis.z, lean_rotation)
	skeleton.basis = skeleton.basis.slerp(Basis.IDENTITY,_delta*5.0) if !firing else skeleton.basis
	skeleton.position = skeleton.position.lerp(Vector3(0,0,0),_delta*5.0)
	
	current_sway = current_sway.lerp(Vector2.ZERO,sway_lerp * _delta)
	controller.relative_mouse_movement = Vector2.ZERO
	prev_controller_x_rotation = controller_x_rotation
	prev_controller_y_rotation = controller_y_rotation
	pass

func handle_state(_new_state, _old_state):
	if controller.secondary_pressed:
		ads_timer.stop()
		ads_timer.start(ADS_IN_TIME)
		prints("start aim in")
	else:
		ads_timer.stop()
		ads_timer.start(ADS_OUT_TIME)
	pass

func set_controller(_controller : CharacterController):
	controller = _controller
	controller.connect("state_changed",handle_state)

func refactory():
	can_fire = true
	firing = false
	chamber_loaded = true
	#spread_delta = 0

@rpc
func primary_action(pressed:bool,just_pressed:bool,just_released:bool):
	if just_released:
		animator.play("release_trigger")
	if not fire_selections & fire_position:
		if just_pressed:
			fire_position = SEMI
			printerr("gun.gd: fire_position must be equal to one of the available fire_selections.")
		return
	
	if !can_fire: return
	if !just_pressed and fire_selections & fire_position == SEMI: return
	if !pressed and fire_selections & fire_position == AUTO: return
	
	#prints("Pressed: ", pressed)
	firing = true
	can_fire = false
	chamber_loaded = false
	fire_timer.start(refactory_time)
	play_primary_effects.rpc()
	
	var muzzle_spread_x = lerp_angle(MIN_SPREAD_X , MAX_SPREAD_X , MUZZLE_SPREAD_CURVE_X.sample_baked(spread_heat))
	var muzzle_spread_y = lerp_angle(MIN_SPREAD_Y , MAX_SPREAD_Y , MUZZLE_SPREAD_CURVE_Y.sample_baked(spread_heat))
	
	var muzzle_bias_x = lerp_angle(MIN_BIAS_X , MAX_BIAS_X , MUZZLE_BIAS_CURVE_X.sample_baked(bias_heat))
	var muzzle_bias_y = lerp_angle(MIN_BIAS_Y , MAX_BIAS_Y , MUZZLE_BIAS_CURVE_Y.sample_baked(bias_heat))
	prints("Bias X: ", muzzle_bias_x, " | Y: ",muzzle_bias_y)
	
	for i in projectile_info.number_of_pellets:
		muzzle.basis = Basis.IDENTITY
		muzzle.basis = muzzle.basis.rotated(muzzle.basis.y, randf_range(-muzzle_spread_x/2.0,muzzle_spread_x/2.0) + muzzle_bias_x)
		muzzle.basis = muzzle.basis.rotated(muzzle.basis.x, randf_range(-muzzle_spread_y/2.0,muzzle_spread_y/2.0) + muzzle_bias_y)
		
		var projectile = _projectile.instantiate()
		#get_node("/root/game/entities").add_child(projectile,true)
		add_child(projectile,true)
		projectile.top_level = true
		projectile.launch(muzzle.get_node("muzzle_y").global_transform,projectile_info,controller)
	
	spread_heat = clamp(spread_heat + spread_step, 0.0, 1.0)
	bias_heat = clamp(bias_heat + bias_step, 0.0, 1.0)
	
	last_shot_time = current_time
	
	var gun_z = skeleton.position.z + _recoil_step
	var _max_recoil = _recoil_step if secondary_firing else MAX_RECOIL
	var recoil_z = gun_z if gun_z < _max_recoil else _max_recoil
	#prints("Recoil Z: ", recoil_z)
	var recoil_tween = create_tween()
	recoil_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	recoil_tween.tween_property(skeleton,"position:z",skeleton.position.z-recoil_z,refactory_time/3.0)
	prints("Skeleton Z position: ", skeleton.position.z-recoil_z)
	var climb_step = _climb_step
	if controller._can_aim() and controller.is_aiming: climb_step = _climb_step_ads
	recoil_tween.tween_property(skeleton,"transform:basis",skeleton.basis.rotated(skeleton.basis.x,climb_step),refactory_time/4.0)
	
	spread_tween.stop()
	spread_tween = create_tween()
	spread_tween.tween_property(self,"spread_heat",0.0,spread_heat*SPREAD_COOLDOWN_TIME).set_delay(refactory_time+0.125)
	
	bias_tween.stop()
	bias_tween = create_tween()
	bias_tween.tween_property(self,"bias_heat",0.0,spread_heat*BIAS_COOLDOWN_TIME).set_delay(refactory_time+0.125)


@rpc("call_local")
func play_primary_effects():
	muzzle_flash.emitting = true
	sounds.play("fire")
	sounds.sound("fire").pitch_scale = randf_range(0.9,1.1)
	animator.play("fire")

func secondary_action(pressed:bool,just_pressed:bool,just_released:bool):
	secondary_firing = pressed
	if just_pressed:
		muzzle_flash.draw_pass_2 = temp_muzzle_blast1
	elif just_released:
		secondary_firing = pressed
		muzzle_flash.draw_pass_2 = temp_muzzle_blast2

func set_magazine_insertion_status(insertion_status : bool):
	has_mag_inserted = insertion_status

func drop_mag():
	if animator.is_playing() and animator.current_animation == "drop_magazine":
		return
	if has_mag_inserted:
		animator.play("drop_magazine")
	else:
		set_weapon_state(IDLE)
	pass

func insert_mag():
	if animator.is_playing() and animator.current_animation == "insert_magazine":
		return
	if !has_mag_inserted:
		animator.play("insert_magazine")
	else:
		set_weapon_state(IDLE)
	pass

func charge_bolt():
	if animator.is_playing() and animator.current_animation == "charge_gun":
		return
	if !chamber_loaded:
		animator.play("charge_gun")
	else:
		set_weapon_state(IDLE)
	pass

func reload(requested):
	if requested:
		request_reload = true
	pass

func switch_in():
	set_weapon_state(SWITCH_IN)
	transform = Transform3D(controller.shoulder.basis,controller.shoulder.basis*default_position)

func switch_out():
	request_switch_out = true
	pass

func _on_fire_timer_timeout():
	refactory()
