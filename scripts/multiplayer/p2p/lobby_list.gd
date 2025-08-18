extends Node

signal want_join_lobby(lobby_id: String, is_private: bool);

@export var lobby_item_UI: PackedScene;
@export var container: Control;

var lobby_instances: Array[LobbyItemUI] = [];

func _ready() -> void:
	LobbyWebSocket.connect_socket();
	
	LobbyWebSocket.init_lobbies.connect(init_lobbies);
	LobbyWebSocket.add_lobby.connect(add_lobby);
	LobbyWebSocket.remove_lobby.connect(remove_lobby);
	LobbyWebSocket.update_lobby.connect(update_lobby);

func _exit_tree() -> void:
	if (LobbyWebSocket.init_lobbies.is_connected(init_lobbies)):
		LobbyWebSocket.init_lobbies.disconnect(init_lobbies);
	if (LobbyWebSocket.add_lobby.is_connected(add_lobby)):
		LobbyWebSocket.add_lobby.disconnect(add_lobby);
	if (LobbyWebSocket.remove_lobby.is_connected(remove_lobby)):
		LobbyWebSocket.remove_lobby.disconnect(remove_lobby);
	if (LobbyWebSocket.update_lobby.is_connected(update_lobby)):
		LobbyWebSocket.update_lobby.disconnect(update_lobby);

func init_lobbies(lobbies: Array[Lobby]):
	var target_count = lobbies.size()
	var current_count = lobby_instances.size()

	# Balancing between what the server has and what we have in number of instances
	# Doens't matter what they have, we will override after
	if current_count < target_count:
		for i in range(target_count - current_count):
			lobby_instances.append(instantiate_lobby())
	elif current_count > target_count:
		for i in range(current_count - target_count):
			var instance = lobby_instances.pop_back();
			instance.queue_free();
	
	# Override the instances
	for i in range(target_count):
		var lobby_instance = lobby_instances[i]
		var lobby_data = lobbies[i]
		
		lobby_instance.init(lobby_data)
		
		if lobby_instance.join_btn.pressed.is_connected(want_join_lobby.emit):
			lobby_instance.join_btn.pressed.disconnect(want_join_lobby.emit)
		lobby_instance.join_btn.pressed.connect(want_join_lobby.emit.bind(lobby_data.id, lobby_data.pwd != ""))

func add_lobby(lobby: Lobby):
	print(lobby.id)
	var lobby_instance = instantiate_lobby();
	lobby_instance.init(lobby);
	if lobby_instance.join_btn.pressed.is_connected(want_join_lobby.emit):
		lobby_instance.join_btn.pressed.disconnect(want_join_lobby.emit)
	lobby_instance.join_btn.pressed.connect(want_join_lobby.emit.bind(lobby.id, lobby.pwd != ""))

func remove_lobby(lobby_id: String):
	var lobby_deleted: LobbyItemUI = get_lobby_by_id(lobby_id);
	if (lobby_deleted != null):
		lobby_instances.erase(lobby_deleted);
		lobby_deleted.queue_free();

func update_lobby(lobby: Lobby):
	if (lobby == null): return;
	var lobby_updated: LobbyItemUI = get_lobby_by_id(lobby.id);
	if (lobby_updated != null):
		lobby_updated.init(lobby);

func instantiate_lobby()-> LobbyItemUI:
	var lobby_item_UI_instance = lobby_item_UI.instantiate() as LobbyItemUI;
	lobby_instances.append(lobby_item_UI_instance);
	container.add_child(lobby_item_UI_instance);
	return lobby_item_UI_instance;

func get_lobby_by_id(lobby_id: String):
	var index = lobby_instances.find_custom(
		func(lobby_instance):
			return is_instance_valid(lobby_instance) && lobby_instance.current_lobby.id == lobby_id;
	);
	if (index != -1):
		return lobby_instances[index];
	print("The lobby id ", lobby_id," was not found");
	return null;
