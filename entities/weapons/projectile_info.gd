extends Resource
class_name ProjectileInfo

@export_placeholder("EG '9mm', '5.56', '30-06', etc.") var cartridge_name : String = ""

@export var projectile_mesh : ArrayMesh
@export var audio : AudioStream

@export var max_damage : float = 1.0
@export var min_damage : float = 0.5
@export_range(1,100) var number_of_pellets : int = 1
@export var damage_falloff : Curve
@export var speed : float = 10.0
@export var gravity : Vector3 = Vector3(0.0,9.82,0.0)
@export var time_increment : float = 1.0 # Measure of time by which the projectile's trajectory will be segmented.
@export var max_distance : float = 1000.0 # Max cumulative distance of bullet's path.

@export var projectile_terminator_scene : PackedScene
