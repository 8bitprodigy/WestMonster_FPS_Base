extends Resource
class_name ImpactMaterial

@export var decal_material : Array[DecalMaterial]
@export var audio : Array[AudioStream]
@export var audio_min_pitch : float = 1.0
@export var audio_max_pitch : float = 1.0
@export var particle_bits : Mesh
@export var particle_dust : Mesh

func apply(audio_stream_player:AudioStreamPlayer3D,gpu_particles_3d:GPUParticles3D,decal:Decal):
	decal_material[randi_range(0,decal_material.size()-1)].apply(decal)
	
	audio_stream_player.stream = audio[randi_range(0,audio.size()-1)]
	audio_stream_player.pitch_scale = randf_range(audio_min_pitch,audio_max_pitch)
	audio_stream_player.play()
	
	gpu_particles_3d.draw_pass_1 = particle_bits
	gpu_particles_3d.draw_pass_2 = particle_dust
	gpu_particles_3d.emitting = true
	#if particle_material: gpu_particles_3d.draw_pass_1.surface_set_material(0,particle_material)
