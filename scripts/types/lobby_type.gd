class_name Lobby
extends RefCounted

var id: String;
var host_player: Player;
var players: Array[Player] = [];
var max_player: int;
var pwd: String;
var connections: Dictionary = {};

static func from_dict(data: Dictionary) -> Lobby:
	var lobby = Lobby.new()
	lobby.id = data.get("id", "");
	
	# Conversion host_player (attention à créer aussi la méthode from_dict dans Player)
	lobby.host_player = Player.from_dict(data.get("host_player", {}))
	
	for p in data.get("players", []):
		lobby.players.append(Player.from_dict(p))
		
	lobby.max_player = data.get("max_player", 0)
	lobby.pwd = data.get("pwd", "")
	
	var raw_connections: Dictionary = data.get("connections", {})
	for key in raw_connections.keys():
		var conn_data = raw_connections[key]
		var conn = PeerConnectionInfo.from_dict(conn_data)
		lobby.connections[key] = conn
	
	return lobby

static func from_dict_array(datas: Array) -> Array[Lobby]:
	var lobbies: Array[Lobby] = [];
	for data in datas:
		lobbies.append(from_dict(data));
	return lobbies

func equals(lobby: Lobby)-> bool:
	if (lobby == null):
		return false;
	return lobby.id == id;
