extends CanvasLayer

# Update the emplacement of the pop_up scene
var pop_up_text_container: PackedScene = preload("res://scenes/prefabs/pop_up.tscn");

# Update the emplacement of the pop_up_loading scene
var pop_up_loading_container: PackedScene = preload("res://scenes/prefabs/pop_up_loading.tscn");

var current_pop_up;

func _ready() -> void:
	layer = 50

func show_pop_up(title: String, message: String, btn_text: String)-> PopUp:
	if (current_pop_up != null): remove_pop_up();
	current_pop_up = pop_up_text_container.instantiate();
	add_child(current_pop_up);
	current_pop_up.title.text = title;
	current_pop_up.message.text = message;
	current_pop_up.button.text = btn_text;
	current_pop_up.button.pressed.connect(current_pop_up.queue_free);
	return current_pop_up;

func show_pop_up_loading():
	if (current_pop_up != null): remove_pop_up();
	current_pop_up = pop_up_loading_container.instantiate();
	add_child(current_pop_up);
	return current_pop_up;

func remove_pop_up():
	if (current_pop_up == null): return;
	current_pop_up.queue_free();
	current_pop_up = null;
