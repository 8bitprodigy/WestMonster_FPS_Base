extends Resource
class_name DecalMaterial

@export var size : Vector3 = Vector3(0.25,0.25,0.25)

@export var albedo : Texture2D
@export var normal : Texture2D
@export var orm : Texture2D
@export var emission : Texture2D

@export_range(0,128) var emission_energy : float = 0.0
@export var modulate : Color = Color.WHITE
@export_range(0,1) var albedo_mix : float = 1.0
@export_range(0,0.999) var normal_fade : float = 0.0

func apply(decal:Decal):
	
	decal.size = size
	
	decal.texture_albedo = albedo
	decal.texture_normal = normal
	decal.texture_orm = orm
	decal.texture_emission = emission
	
	decal.albedo_mix = albedo_mix
	decal.modulate = modulate
	decal.normal_fade = normal_fade
	decal.emission_energy = emission_energy
