extends Resource
class_name ImpactMaterialData

@export_category("Material Info")
@export var impact_material_name : String = ""
@export var impact_material_path_pattern : Array[String]

@export_category("Decal Data")
@export var decal_material : Array[DecalMaterial]
@export var impact_audio : Array[AudioStream]
@export var impact_audio_min_pitch : float = 1.0
@export var impact_audio_max_pitch : float = 1.0
@export var particle_bits : Mesh
@export var particle_dust : Mesh

@export_category("Footstep Data")
@export var footstep_audio : Array[AudioStream]
@export var footstep_audio_min_pitch : float = 1.0
@export var footstep_audio_max_pitch : float = 1.0

func apply_impact(audio_stream_player:AudioStreamPlayer3D,gpu_particles_3d:GPUParticles3D,decal:Decal):
	decal_material[randi_range(0,decal_material.size()-1)].apply(decal)
	
	audio_stream_player.stream = impact_audio[randi_range(0,impact_audio.size()-1)]
	audio_stream_player.pitch_scale = randf_range(impact_audio_min_pitch,impact_audio_max_pitch)
	audio_stream_player.play()
	
	gpu_particles_3d.draw_pass_1 = particle_bits
	if gpu_particles_3d.draw_passes > 1:
		gpu_particles_3d.draw_pass_2 = particle_dust
	gpu_particles_3d.emitting = true

func play_step(audio_stream_player:AudioStreamPlayer3D):
	audio_stream_player.stream = footstep_audio[randi_range(0,footstep_audio.size()-1)]
	audio_stream_player.pitch_scale = randf_range(footstep_audio_min_pitch,footstep_audio_max_pitch)
	audio_stream_player.play()

