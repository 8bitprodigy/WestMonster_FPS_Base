extends ProjectileTerminatorScene
class_name DecalSelector

@export_category("Integral Nodes")
@export_node_path("Decal") var _decal : NodePath
@onready var decal = get_node(_decal)
@export_node_path("AudioStreamPlayer3D") var _audio : NodePath
@onready var audio = get_node(_audio)
@export_node_path("GPUParticles3D") var _particles : NodePath
@onready var particles = get_node(_particles)
@export_node_path("Timer") var _timer : NodePath
@onready var timer = get_node(_timer)
@export var timeout : float = 10.0

@export_category("Surface impact materials")
@export_enum("Dirt","Flesh","Glass","Metal","Polymer","Stone","Wood") var default_impact_material : int = 0
@export var dirt_impact_material : ImpactMaterial
@export var flesh_impact_material : ImpactMaterial
@export var glass_impact_material : ImpactMaterial
@export var metal_impact_material : ImpactMaterial
@export var polymer_impact_material : ImpactMaterial
@export var stone_impact_material : ImpactMaterial
@export var wood_impact_material : ImpactMaterial

@onready var impact_materials = [
	dirt_impact_material,
	flesh_impact_material,
	glass_impact_material,
	metal_impact_material,
	polymer_impact_material,
	stone_impact_material,
	wood_impact_material
]


func terminate_projectile(_projectile_transform:Transform3D,_collision_position:Vector3,_collision_normal:Vector3,_collider:Object):
	super.terminate_projectile(_projectile_transform,_collision_position,_collision_normal,_collider)
	
	timer.one_shot = true
	timer.connect("timeout",queue_free)
	timer.start(timeout)
	
	#var impact_index:int = default_impact_material #randi_range(0,6) #
		
	if _collider is PhysicsBody3D and not _collider is StaticBody3D:
		if _collider is Player:
			# Update later
			Common.default_impact_material.apply_impact(audio,particles,decal)
		else:
			Common.default_impact_material.apply_impact(audio,particles,decal)
		return
	prints(_collider.get_meta_list())
	if !_collider.has_meta("impact_material"): 
		Common.default_impact_material.apply_impact(audio,particles,decal)
		return
	Common.impact_materials[_collider.get_meta("impact_material")].apply_impact(audio,particles,decal)

