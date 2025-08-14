extends Control

const margin = Vector2(10, 10);

@export var bubble_chat_scene: PackedScene;
@export var offset: Vector2;

var camera: Camera2D;
var players: Array[PlayerInstance];
var tracked_player = [];
var tracked_bubbles = [];

func _on_level_players_ready(players: Array[PlayerInstance]) -> void:
	self.players = players;
	camera = get_viewport().get_camera_2d();
	for player in players:
		var bubble_chat = bubble_chat_scene.instantiate() as BubbleChat;
		add_child(bubble_chat);
		bubble_chat.visible = false;
		player.dialogue_container = bubble_chat;
		player.dialogue_label = bubble_chat.chat_label;
		bubble_chat.username_label.text = player.username_label.text;
		player.dialogue_container.size.x = 0;

func track_dialogue_position_player(player: PlayerInstance):
	var bubble = player.dialogue_container;
	
	var camera_bound = UIUtils.get_camera_world_bound(camera);
	var bubble_bound = UIUtils.get_group_bounds(bubble);
	
	var text_size = player.dialogue_label.get_text_size(player.current_message);
	if (text_size.y > player.dialogue_label.default_size_container.y):
		text_size.x = player.dialogue_label.max_expand_x;
	bubble_bound.top_left.x = bubble.global_position.x - (text_size.x + player.dialogue_label.default_size_container.x) / 2 * bubble.scale.x;
	bubble_bound.bot_right.x = bubble.global_position.x + (text_size.x + player.dialogue_label.default_size_container.x) / 2 * bubble.scale.x;
	bubble_bound.size = abs(bubble_bound.top_left - bubble_bound.bot_right);
	
	var bubble_target_point = player.position + offset;
	
	var clamped_target_point = Vector2();
	clamped_target_point.x = clamp(
		bubble_target_point.x,
		camera_bound.top_left.x + bubble_bound.size.x / 2 + margin.x,
		camera_bound.bot_right.x - bubble_bound.size.x / 2 - margin.x
	);
	
	clamped_target_point.y = clamp(
		bubble_target_point.y,
		camera_bound.top_left.y + bubble_bound.size.y + margin.y,
		camera_bound.bot_right.y - margin.y
	);
	
	bubble.global_position = clamped_target_point

func _on_chat_on_message_sended(peer_id: int, message: String) -> void:
	for player in players:
		if (player.get_multiplayer_authority() == peer_id && !tracked_player.has(peer_id)):
			process_track_position(peer_id, player);

func process_track_position(peer_id: int, player: PlayerInstance):
	tracked_player.append(peer_id);
	var highest_z_index = get_highest_z_index(tracked_bubbles);
	player.dialogue_container.z_index = highest_z_index + 1;
	tracked_bubbles.append(player.dialogue_container);
	
	while (!player.is_dialoguing):
		await get_tree().process_frame;
	
	while (player.is_dialoguing):
		track_dialogue_position_player(player);
		await get_tree().process_frame;
	
	tracked_player.erase(peer_id);

func get_highest_z_index(bubbles: Array[BubbleChat]):
	if (bubbles.size() == 0):
		return 0;
	
	return bubbles.map(func(bubble): return bubble.z_index).max();
