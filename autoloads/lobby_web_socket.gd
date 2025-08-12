extends Node

signal init_lobbies(lobbies: Array[Lobby]);
signal add_lobby(lobby: Lobby);
signal update_lobby(lobby: Lobby);
signal remove_lobby(lobby_id: String);

#const WS_URL = "ws://localhost:3000";
#const HTTP_URL = "http://localhost:3000/lobbies";
const WS_URL = "wss://p2p-prototype-api-production.up.railway.app";
const HTTP_URL = "https://p2p-prototype-api-production.up.railway.app/lobbies";

var socket := WebSocketPeer.new();
var http := HttpService.new();
var websocket_user_id: String;
var current_lobbies_version: int;

func _ready() -> void:
	add_child(http);

func connect_socket():
	var state = socket.get_ready_state();
	if (state != WebSocketPeer.STATE_CLOSED): return;
	
	var err = socket.connect_to_url(WS_URL);
	if err != OK:
		print("Unable to connect");
	set_process(err == OK);

func disconnect_socket():
	var state = socket.get_ready_state();
	if (state != WebSocketPeer.STATE_OPEN): return;
	
	var disconnect_msg = { "type": "disconnect", "user_id": websocket_user_id };
	socket.send_text(JSON.stringify(disconnect_msg));
	
	await get_tree().create_timer(0.1).timeout;
	
	set_process(false);
	socket.close();

func _process(delta: float) -> void:
	socket.poll();
	var state = socket.get_ready_state();
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var data = socket.get_packet().get_string_from_utf8();
			handle_message(JSON.parse_string(data));
	elif state == WebSocketPeer.STATE_CLOSING:
		pass;
	elif state == WebSocketPeer.STATE_CLOSED:
		# The code will be -1 if the disconnection was not properly notified by the remote peer.
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false);

func handle_message(data):
	var ws_msg = parse_websocket_message(data);
	if ws_msg == null:
		print("Data invalid or malformed")
		return;
	
	if (ws_msg.payload.has("to_id") && ws_msg.payload.to_id != websocket_user_id):
		current_lobbies_version = ws_msg.payload.lobbies_version;
		return;
	
	match ws_msg.type:
		WebSocketMessage.MessageType.INIT:
			var lobbies = Lobby.from_dict_array(ws_msg.payload.lobbies);
			init_lobbies.emit(lobbies);
			websocket_user_id = ws_msg.payload.user_id;
			current_lobbies_version = ws_msg.payload.lobbies_version;
		WebSocketMessage.MessageType.LOBBY_UPDATE:
			#print("Version correspond, patch");
			#print("Payload : ", ws_msg.payload);
			
			var lobbies_version = ws_msg.payload.lobbies_version;
			
			if (lobbies_version != current_lobbies_version + 1):
				print("Version not corresponding, refresh");
				var lobbies = await retrieve_lobbies_get();
				init_lobbies.emit(lobbies);
				return;
			
			current_lobbies_version = lobbies_version;
			
			if (ws_msg.payload.has("added") && len(ws_msg.payload.added) > 0):
				var added_lobby = Lobby.from_dict(ws_msg.payload.added);
				print("Added detected");
				add_lobby.emit(added_lobby);
			if (ws_msg.payload.has("removed") && len(ws_msg.payload.removed) > 0):
				var removed_lobby_id: String = ws_msg.payload.removed;
				print("Removed detected");
				remove_lobby.emit(removed_lobby_id);
			if (ws_msg.payload.has("updated") && len(ws_msg.payload.updated) > 0):
				var updated_lobby = Lobby.from_dict(ws_msg.payload.updated);
				print("Updated detected");
				update_lobby.emit(updated_lobby);
			print("");
		_:
			print("Unknown message type: ", data.type)

func parse_websocket_message(data: Dictionary) -> WebSocketMessage:
	var msg = WebSocketMessage.new();
	
	# Validate that the dict does indeed have a “type” and “payload” key
	if not data.has("type") or not data.has("payload"):
		return null;
	
	# Convertir type en enum
	var type_val: int = data["type"];
	if type_val in WebSocketMessage.MessageType.values():
		msg.type = type_val;
	else:
		return null; # Invalid type
	
	msg.payload = data["payload"];
	return msg;

func retrieve_lobbies_get():
	var response = await http.request_json(HTTP_URL, HTTPClient.Method.METHOD_GET);
	
	if !response.error:
		return response.data;
	return null;

func host_lobby_post(player: Player, max_player: int, pwd: String):
	var host_player = {
		"id": websocket_user_id,
		"name": player.name
	};
	
	var json_data := {
		"host_player": host_player,
		"players": [host_player],
		"max_player": max_player,
		"pwd": pwd
	};
	
	return await http.request_json(HTTP_URL, HTTPClient.Method.METHOD_POST, json_data);

func join_lobby_post(lobby_id: String, player: Player, pwd: String):
	var data := {
		"player": {
			"id": websocket_user_id,
			"name": player.name
		},
		"lobby_id": lobby_id,
		"pwd": pwd
	}
	
	return await http.request_json(HTTP_URL + "/join-lobby", HTTPClient.Method.METHOD_POST, data, false);

func broadcast_lobby(lobby_id: String, to_id: String):
	var data := {
		"lobby_id": lobby_id,
		"from_id": websocket_user_id,
		"to_id": to_id
	}
	
	return await http.request_json(HTTP_URL + "/broadcast-lobby", HTTPClient.Method.METHOD_POST, data, false);

func quit_lobby_post(lobby_id: String, player_id: String = websocket_user_id):
	var data := {
		"player_id": player_id,
		"lobby_id": lobby_id
	}
	
	return await http.request_json(HTTP_URL + "/quit-lobby", HTTPClient.Method.METHOD_POST, data, false);

func sdp_put(player_id: String, lobby_id: String, sdp: String, type: String):
	var data := {
		"player_id": player_id,
		"lobby_id": lobby_id,
		"sdp": sdp,
		"type": type
	}
	
	await http.request_json(HTTP_URL + "/send-sdp", HTTPClient.Method.METHOD_PUT, data, false);

func ice_candidate_put(player_id: String, lobby_id: String, ice_candidates: Array, is_host: bool):
	var ice_candidates_serialized = [];
	for ice_candidate in ice_candidates:
		ice_candidates_serialized.append({
			"candidate": ice_candidate.candidate,
			"sdp_mid": ice_candidate.sdp_mid,
			"sdp_mline_index": ice_candidate.sdp_mline_index
		})
	
	var data := {
		"player_id": player_id,
		"lobby_id": lobby_id,
		"ice_candidates": ice_candidates_serialized,
		"is_host": is_host
	}
	
	return await http.request_json(HTTP_URL + "/send-ice-candidates", HTTPClient.Method.METHOD_PUT, data, false);

func established_connection(player_id, lobby_id):
	var data := {
		"player_id": player_id,
		"lobby_id": lobby_id
	};
	
	return await http.request_json(HTTP_URL + "/connection-established", HTTPClient.Method.METHOD_PUT, data, false);
