class_name Player
extends RefCounted

var id;
var name;

func _init(id: String = "", name: String = "") -> void:
	self.id = id
	self.name = name

static func from_dict(data: Dictionary) -> Player:
	var player = Player.new()
	player.id = data.get("id", "")
	player.name = data.get("name", "")
	return player

#static func from_dict_array(datas: Array[Dictionary]) -> Array[Player]:
	#var players: Array[Player] = [];
	#for data in datas:
		#players.append(from_dict(data));
	#return players;

static func to_dict(player: Player) -> Dictionary:
	var data := {};
	data["id"] = player.id;
	data["name"] = player.name;
	return data;

#static func to_dict_array(players: Array[Player]) -> Array[Dictionary]:
	#var datas: Array[Dictionary] = [];
	#for player in players:
		#datas.append(to_dict(player));
	#return datas;
