class_name PlayerInstance
extends CharacterBody2D

static var can_move = true;

const SPEED = 5000.0;
const INTERPOLATION_SPEED := 10.0

@export var username_label: Label;

@onready var dialogue_sfx: AudioStreamPlayer2D = $DialogueSFX

var target_position: Vector2
var messages = [];
var is_dialoguing = false;
var dialogue_container: Control;
var dialogue_label: LabelEnhanced;
var current_message = null;
var players_id = [];

func _physics_process(delta: float) -> void:
	if (!is_multiplayer_authority()):
		global_position = global_position.lerp(target_position, INTERPOLATION_SPEED * delta);
		return;
	
	var direction;
	if (can_move):
		direction = Vector2(Input.get_vector("left", "right", "up", "down")).normalized();
	else:
		direction = Vector2.ZERO;
	
	velocity = direction * SPEED * delta;
	move_and_slide();
	
	for player_id in players_id:
		update_position.rpc_id(player_id, global_position);

func broadcast_message(message: String):
	var split_message = get_text_chunks(dialogue_label, dialogue_label.max_expand_x, message, 5);
	dialogue_container.visible = true;
	messages.append_array(split_message);
	if (!is_dialoguing):
		current_message = messages[0];
		is_dialoguing = true;
		await show_message();
		dialogue_container.visible = false;
		is_dialoguing = false;
		current_message = null;

func show_message():
	while messages.size() > 0:
		var message = messages.pop_front();
		current_message = message;
		dialogue_label.text = message;
		await TransitionUtils.fade_speed(0.0, 1.0, 20.0 / message.length(), text_chaining);
		await get_tree().create_timer(2.0).timeout;

func text_chaining(r: float):
	dialogue_label.visible_ratio = r;
	if (!dialogue_sfx.playing):
		dialogue_sfx.pitch_scale = randf_range(0.75, 1.25);
		dialogue_sfx.play();

func get_text_chunks(label: Label, label_size: float, full_text: String, max_lines: int) -> Array:
	if (full_text.is_empty()): return [];
	
	var font_size = label.theme.default_font_size;
	var font = label.theme.default_font;
	var font_height = font.get_height(font_size);
	var chunks = [];
	var chunk = "";
	
	for word in full_text.split(" "):
		if (word.is_empty()): continue;
		var temp_chunk = chunk + " " + word;
		var text_size = font.get_multiline_string_size(temp_chunk, label.horizontal_alignment, label_size, font_size);
		if (max_lines * font_height < text_size.y):
			chunks.append(chunk);
			chunk = word;
		else:
			chunk = temp_chunk;
	
	chunks.append(chunk);
	return chunks;

@rpc("any_peer", "unreliable")
func update_position(new_pos: Vector2) -> void:
	if (!is_multiplayer_authority()):
		target_position = new_pos
