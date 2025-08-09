extends Node

var players := {};

func _process(delta):
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.poll()

@rpc("any_peer", "reliable")
func add_player_data(player_data: Dictionary):
	var player = Player.from_dict(player_data);
	var sender_id = multiplayer.get_remote_sender_id();
	print("player added host side : ", player_data, ", sender : ", sender_id);
	players[sender_id] = player;

func remove_player_data(peer_id: int):
	players.erase(peer_id);

@rpc("authority", "reliable")
func sync_all_players(player_datas: Dictionary):
	print("sync players");
	var new_players = {};
	for peer_id in player_datas.keys():
		var player_data = player_datas[peer_id];
		new_players[peer_id] = Player.from_dict(player_data);
	players = new_players;
	launch_game();

func launch_game():
	LobbyWebSocket.disconnect_socket();
	print("Game starting, switching scene...")
	get_tree().change_scene_to_file("res://scenes/levels/level.tscn")
