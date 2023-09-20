extends Node3D


@export_node_path("SkeletonIK3D") var _right_arm_ik : NodePath
@onready var right_arm_ik = get_node(_right_arm_ik)
@export_node_path("SkeletonIK3D") var _left_arm_ik : NodePath
@onready var left_arm_ik = get_node(_left_arm_ik)
@export_node_path("AnimationPlayer") var _animator : NodePath
@onready var animator = get_node(_animator)


