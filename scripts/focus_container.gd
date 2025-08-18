extends Control

@export var focused_node: Control;

func _process(_delta: float) -> void:
	if (focused_node):
		position = focused_node.position
		size = focused_node.size
