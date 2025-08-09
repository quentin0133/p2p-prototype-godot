class_name BubbleChat
extends Control

@export var chat_label: LabelEnhanced;
@export var username_label: LabelEnhanced;

var camera: Camera2D;
#var rect: ReferenceRect = ReferenceRect.new();

#func _ready() -> void:
	#get_node("/root/Level").add_child(rect);
	#rect.editor_only = false;
	#draw_bubble_rect();

#func draw_bubble_rect():
	#var a = UIUtils.get_group_bounds(self);
	#rect.global_position = a.top_left;
	#rect.size = a.size;
	#await get_tree().create_timer(0.2).timeout;
	#draw_bubble_rect();
