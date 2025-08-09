class_name PlayerItemUI
extends ColorRect

@export var username: Label;
@export var host_icon: TextureRect;
@export_color_no_alpha var deactivate_color: Color;

var id = null;

func set_active(player: Player, is_host: bool, is_current_player: bool) -> void:
	id = player.id;
	username.text = player.name;
	host_icon.visible = is_host;
	modulate = Color(1.0, 1.0, 1.0);
	if (is_current_player):
		username.modulate = Color(0.75, 0.25, 0.25);
	else:
		username.modulate = Color(1.0, 1.0, 1.0);

func set_deactivate():
	id = null;
	username.text = "";
	host_icon.visible = false;
	modulate = deactivate_color;
