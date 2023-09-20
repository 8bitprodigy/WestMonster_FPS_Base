extends Node3D
class_name Projectile

@export_node_path("Marker3D") var _carrier
@onready var carrier = get_node(_carrier)
@export_node_path("RayCast3D") var _raycast
@onready var raycast = get_node(_raycast)
@export_node_path("MeshInstance3D") var _mesh
@onready var mesh = get_node(_mesh)
@export_node_path("GPUParticles3D") var _particles
@onready var particles = get_node(_particles)
@export_node_path("AudioStreamPlayer3D") var _audio
@onready var audio = get_node(_audio)

var trajectory_array : Array[Vector3] = []
var trajectory_counter : int = 0
var elapsed_distance : float = 0.0
var elapsed_time : float = 0.0
var previous_position : Vector3 = Vector3.ZERO
var velocity : Vector3 = Vector3.FORWARD

var shooter : CharacterController

@export var projectile_info : ProjectileInfo

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("projectile")
	pass # Replace with function body.

func _physics_process(_delta):
	raycast.position = previous_position
	raycast.set_target_position(mesh.position)
	elapsed_distance = raycast.position.distance_to(mesh.position)
	raycast.force_raycast_update()
	#var bullet_collisions = raycast
	if raycast.is_colliding():
		#prints("Bullet Collisions: ", raycast.get_collider())
		terminate_projectile(global_transform,raycast.get_collision_point(),raycast.get_collision_normal(),raycast.get_collider())
		#die()
	previous_position = raycast.target_position
	if elapsed_distance >= projectile_info.max_distance: die()
	pass

func trajectory(time):
	# position(time) = position + velocity * time + gravity * time^2
	return position + (velocity * time) + (projectile_info.gravity * time^2)

func launch(start_transform : Transform3D, _projectile_info : ProjectileInfo, controller : CharacterController):
	set_physics_process(true)
	
	global_transform = start_transform
	carrier.position = Vector3.ZERO
	audio.position = Vector3.ZERO
	particles.position = Vector3.ZERO
	mesh.position = Vector3.ZERO
	raycast.position = Vector3.ZERO
	
	elapsed_distance = 0.0
	elapsed_time = 0
	trajectory_array.clear()
	trajectory_counter = 0
	previous_position = Vector3.ZERO
	
	projectile_info = _projectile_info
	#mesh.mesh = projectile_info.projectile_mesh
	audio.stream = projectile_info.audio
	
	shooter = controller
	raycast.add_exception(controller)
	
	var trajectory_angle = global_rotation.x
	global_rotation = Vector3(0.0,global_rotation.y,0.0)
	var temp_vector = Common.angle_to_vec2(trajectory_angle)
	velocity = Vector3(0.0,temp_vector.y,-temp_vector.x) * projectile_info.speed
	
	var iteration : int = 0
	while elapsed_distance <= projectile_info.max_distance:
		# position(time) = position + velocity * time + gravity * time^2
		trajectory_array.append(carrier.position + (velocity * elapsed_time) + (-projectile_info.gravity * pow(elapsed_time,2)))
		elapsed_time += projectile_info.time_increment
		elapsed_distance += previous_position.distance_to(trajectory_array[iteration])
		iteration += 1
	
	#prints("Trajectory Array: ", trajectory_array)
	elapsed_distance = 0.0
	elapsed_time = 0
	audio.play()
	audio.connect("finished", audio_finished)
	iterate_trajectory()

func audio_finished():
	audio.play()

func iterate_trajectory():
	mesh.position = trajectory_array[trajectory_counter]
	raycast.position = trajectory_array[trajectory_counter+1] #give the mesh something to look_at()
	mesh.look_at(raycast.global_position)
	raycast.position = trajectory_array[trajectory_counter]
	previous_position = raycast.position
	var bullet_tween = create_tween()
	bullet_tween.tween_property(mesh,"position",trajectory_array[trajectory_counter+1],projectile_info.time_increment*1)
	#prints("Bullet moving to: ",trajectory_array[trajectory_counter])
	trajectory_counter += 1
	if trajectory_counter+2 <= trajectory_array.size():
		bullet_tween.connect("finished",iterate_trajectory)
	else:
		bullet_tween.connect("finished",die)
	pass

func terminate_projectile(projectile_transform:Transform3D,collision_position:Vector3,collision_normal:Vector3,collider:Object):
	var scene = projectile_info.projectile_terminator_scene.instantiate()
	get_node("/root/game/entities").add_child(scene)
	if scene is ProjectileTerminatorScene:
		scene.terminate_projectile(projectile_transform,collision_position,collision_normal,collider)
	else:
		scene.global_transform = Transform3D(projectile_transform.basis,collision_position)
	die()

func die():
	set_physics_process(false)
	mesh.hide()
	audio.stop()
	queue_free()
	pass
