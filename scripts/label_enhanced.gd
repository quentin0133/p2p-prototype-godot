class_name LabelEnhanced
extends Label

@export var max_expand_x: float;
@export var container: Control;

@onready var default_autowrap := autowrap_mode;
@onready var default_custom_minimum_size = custom_minimum_size;
@onready var font_size = theme.default_font_size;
@onready var default_size_container := container.size;

var old_text = "";
var old_visible_ratio = 1.0;

func _process(delta: float) -> void:
	update_font();

func update_font():
	if (text == old_text && visible_ratio == old_visible_ratio):
		return;
	old_text = text;
	old_visible_ratio = visible_ratio;
	
	var font_height = theme.default_font.get_height(font_size);
	var text_size = get_text_size(get_visible_text(text, visible_ratio));
	if (text_size.y == font_height || text_size.y == 0):
		autowrap_mode = TextServer.AUTOWRAP_OFF;
		text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING;
		custom_minimum_size.x = 0;
		size.x = 0;
	else:
		custom_minimum_size.x = max_expand_x;
		autowrap_mode = default_autowrap;
		if (default_autowrap == TextServer.AUTOWRAP_OFF):
			text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS;

func get_text_size(text: String)-> Vector2:
	return get_theme_default_font().get_multiline_string_size(text, horizontal_alignment, max_expand_x, font_size);

func get_visible_text(text: String, visible_ratio: float) -> String:
	if visible_ratio >= 1.0:
		return text;
	if visible_ratio <= 0.0:
		return "";
	var char_count = int(text.length() * visible_ratio);
	return text.substr(0, char_count);
