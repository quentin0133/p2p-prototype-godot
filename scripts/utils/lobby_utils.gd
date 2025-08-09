class_name LobbyUtils

static func is_player_in_lobby(player_id: String, lobby: Lobby) -> bool :
	var index_player = lobby.players.find_custom(
		func(player: Player):
			return player.id == player_id;
	);
	return index_player != -1;

static func is_player_connecting(player_id: String, lobby: Lobby) -> bool :
	return lobby.connections.has(player_id);

static func has_player_in(player_id: String, lobby: Lobby) -> bool :
	if (lobby.connections.has(player_id)):
		return true;
	var index_player = lobby.players.find_custom(
		func(player: Player):
			return player.id == player_id;
	);
	return index_player != -1;

static func has_player_in_array(player_id: String, lobbies: Array[Lobby]) -> bool :
	for lobby in lobbies:
		if (lobby.connections.has(player_id)):
			return true;
		var index_player = lobby.players.find_custom(
			func(player: Player):
				return player.id == player_id;
		);
		if (index_player != -1):
			return true;
	return false

static func get_by_id(lobby_id: String, lobbies: Array[Lobby]) -> Lobby:
	var index_lobby = lobbies.find_custom(
		func(lobby: Lobby):
			return lobby.id == lobby_id;
	);
	if (index_lobby != -1):
		return lobbies[index_lobby];
	return null;
