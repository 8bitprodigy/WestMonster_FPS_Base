extends Node

var scene_tree = SceneTree.new()

func sig(x : float, amplitude : float, y_translate : float):
	return ( (amplitude) / (1 + exp(x)) ) + y_translate

func radius_to_cube_vertex(length:float):
	return (length/2)*sqrt(3)

func angle_to_vec2(angle : float):
	return Vector2(cos(angle),sin(angle))

var impact_materials : Dictionary
var default_impact_material : ImpactMaterialData

func setup_impact_materials(impact_materials_array:Array[ImpactMaterialData]):
	impact_materials.clear()
	default_impact_material = impact_materials_array[0]
	for im in impact_materials_array:
		impact_materials.merge({im.impact_material_name : im})
	pass

