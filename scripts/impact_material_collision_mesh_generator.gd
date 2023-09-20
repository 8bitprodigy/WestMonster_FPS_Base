@tool
extends Node3D
class_name ImpactMaterialCollisionGenerator


@export_node_path("Node3D") var _level_node : NodePath
@onready var level_node = get_node(_level_node)

@export var impact_materials : Array[ImpactMaterialData]
@export var default_impact_material : ImpactMaterialData

@export_category("Click to generate Impact Material collisions.")
@export var generate_impact_material_collisions : bool = false:
	set(_i):
		generate()
@export var generate_on_runtime : bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		impact_materials.push_front(default_impact_material)
		Common.setup_impact_materials(impact_materials)
		if generate_on_runtime: generate()
	pass # Replace with function body.


var world_surfaces : Array[Dictionary] = []
func generate():
	prints("Starting Impact Material Collider generation...")
	if _level_node == null and get_child_count() == 0: 
		prints("Generation failed!")
		return
	
	var impact_material_colliders = Node.new()
	impact_material_colliders.name = "impact material colliders"
	add_child(impact_material_colliders)
	
	level_node = get_node(_level_node) if _level_node != null else null
	var children : Array[Node]
	if level_node == null:
		children = get_children()
	else:
		children = level_node.get_children()
	
	recursive_search_children(children)
	
	for impact_material in impact_materials:
		var impact_material_body = StaticBody3D.new()
		impact_material_body.set_collision_layer_value(1, false)
		impact_material_body.set_collision_mask_value(1, false)
		impact_material_body.set_collision_layer_value(32, true)
		impact_material_body.name = impact_material.impact_material_name
		impact_material_body.set_meta("impact_material",impact_material.impact_material_name)
		impact_material_colliders.add_child(impact_material_body)
		
		var surface_counter = 0
		for mesh_surface in world_surfaces:
			#var surface_material = world_mesh.mesh.surface_get_material(surface_index)
			var texture_path : String
			
			if mesh_surface["material"]:
				texture_path = mesh_surface["material"].resource_path
			if mesh_surface["material"] is BaseMaterial3D:
				texture_path = mesh_surface["material"].albedo_texture.resource_path
			
			prints("Texture Path: ", texture_path)
			for path_pattern in impact_material.impact_material_path_pattern:
				if texture_path.contains(path_pattern):
					var array_mesh = ArrayMesh.new()
					array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_surface["arrays"])
					var mesh = Mesh.new()
					mesh = array_mesh
					var collider = CollisionShape3D.new()
					collider.shape = mesh.create_trimesh_shape()
					collider.global_transform = mesh_surface["transform"]
					impact_material_body.add_child(collider)
					
					if Engine.is_editor_hint():
						collider.set_owner(get_tree().edited_scene_root)
					pass
					world_surfaces.pop_at(surface_counter)
					prints("Popped surface at index ", surface_counter)
					break
					
				else:
					prints("No path pattern matched!")
				pass
			surface_counter += 1
			pass
		
		
		if Engine.is_editor_hint():
			impact_material_body.set_owner(get_tree().edited_scene_root)
		pass
	pass
	
	var impact_material_body = StaticBody3D.new()
	impact_material_body.set_collision_layer_value(1, false)
	impact_material_body.set_collision_layer_value(32, true)
	impact_material_body.name = "default"
	impact_material_colliders.add_child(impact_material_body)
	
	
	for surface in world_surfaces:
		var array_mesh = ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,surface["arrays"])
		var mesh = Mesh.new()
		mesh = array_mesh
		var collider = CollisionShape3D.new()
		collider.shape = mesh.create_trimesh_shape()
		collider.global_transform = surface["transform"]
		impact_material_body.add_child(collider)
		if Engine.is_editor_hint():
			collider.set_owner(get_tree().edited_scene_root)
		
	
	if Engine.is_editor_hint():
		impact_material_body.set_owner(get_tree().edited_scene_root)
		impact_material_colliders.set_owner(get_tree().edited_scene_root)
	prints("Impact Material Collider generation complete!")
	
	world_surfaces.clear()
	pass


func recursive_search_children(children:Array[Node]):
	for node in children:
		if node.get_child_count() > 0:
			recursive_search_children(node.get_children())
		if node is MeshInstance3D and is_static_mesh(node):
			for surface_index in node.mesh.get_surface_count():
				world_surfaces.push_back({
					"RID" : node.mesh.get_rid(),
					"index" : surface_index,
					"arrays" : node.mesh.surface_get_arrays(surface_index),
					"transform" : node.global_transform,
					"material" : node.mesh.surface_get_material(surface_index)
					})
				
				if node.has_meta("no_impact"):
					if node.get_meta("no_impact") & (2^surface_index) == 0:
						prints("Popped surface: ", world_surfaces.back())
						world_surfaces.pop_back()

func is_static_mesh(mesh):
	if mesh.get_parent() is StaticBody3D: return true
	for i in mesh.get_children():
		if i is StaticBody3D: return true
	return false
