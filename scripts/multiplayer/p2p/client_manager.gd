class_name ClientManager
extends Node

signal error_occurred(lobby_id: String);

var rtc_peer: WebRTCMultiplayerPeer;
var connected_peer: WebRTCPeerConnection;
var answer_signal_callback;
var ice_candidates: Array[IceCandidate] = [];
var current_lobby: Lobby;
var player: Player;
var ICE_SERVERS := {
	"iceServers": [
		{"urls": "stun:stun.l.google.com:19302"},
		{"urls": "stun:stun1.l.google.com:19302"},
		{"urls": "stun:stun2.l.google.com:19302"},
		{"urls": "stun:stun3.l.google.com:19302"},
		{"urls": "stun:stun4.l.google.com:19302"},
	]
}

var timeout = 5.0;
var timeout_ice_candidate = 8.0;
var counter_timeout = 0.0;

func _ready() -> void:
	set_process(false);

func _exit_tree() -> void:
	if (LobbyWebSocket.update_lobby.is_connected(on_update_lobbies)):
		LobbyWebSocket.update_lobby.disconnect(on_update_lobbies);

func join_game(lobby: Lobby, player: Player):
	set_process(true);
	current_lobby = lobby;
	self.player = player;
	PopUpManager.show_pop_up_loading();
	
	rtc_peer = WebRTCMultiplayerPeer.new();
	rtc_peer.create_client(current_lobby.connections[LobbyWebSocket.websocket_user_id].id)
	multiplayer.multiplayer_peer = rtc_peer;
	
	LobbyWebSocket.update_lobby.connect(on_update_lobbies);

func on_update_lobbies(lobby: Lobby):
	if (!LobbyUtils.has_player_in(LobbyWebSocket.websocket_user_id, lobby)):
		return;
	
	current_lobby = lobby;
	
	if (lobby.connections.has(LobbyWebSocket.websocket_user_id)):
		match lobby.connections[LobbyWebSocket.websocket_user_id].state:
			"offer":
				print("Client received offer");
				handle_offer();
 
func handle_offer():
	var id := LobbyWebSocket.websocket_user_id;
	var connection_info: PeerConnectionInfo = current_lobby.connections[id];
	if (connection_info.state != "offer"):
		return;
	
	rtc_peer.peer_connected.connect(_on_peer_connected);
	
	var peer := WebRTCPeerConnection.new()
	var err_init := peer.initialize(ICE_SERVERS)
	if err_init != OK:
		print("Error init peer in client: ", err_init)
		error_occurred.emit(current_lobby.id);
		return;
	
	connected_peer = peer;
	
	var err_peer = rtc_peer.add_peer(connected_peer, 1)
	if err_peer != OK:
		print("Failed to add peer: ", err_peer)
		error_occurred.emit(current_lobby.id);
		return;
	else:
		print("Peer successfully added")
	
	# Connecte les signaux utiles
	answer_signal_callback = answer_created.bind(id);
	connected_peer.ice_candidate_created.connect(ice_candidate_created);
	connected_peer.session_description_created.connect(answer_signal_callback);
	
	var offer := connection_info.offer;
	if offer == null:
		print("No offers received from host")
		error_occurred.emit(current_lobby.id);
		return;
	
	var err = connected_peer.set_remote_description("offer", offer);
	if err != OK:
		print("Error set_remote_description (offer) : ", err);
		error_occurred.emit(current_lobby.id);
		return;
	
	var ice_candidates_host := connection_info.ice_candidates_host;
	for ice in ice_candidates_host:
		connected_peer.add_ice_candidate(
			ice.sdp_mid,
			ice.sdp_mline_index,
			ice.candidate
		);
	
	var start_time := Time.get_ticks_msec();
	while connected_peer != null && connected_peer.get_gathering_state() != WebRTCPeerConnection.GatheringState.GATHERING_STATE_COMPLETE:
		counter_timeout = 0;
		await get_tree().process_frame;
		var elapsed_time = (Time.get_ticks_msec() - start_time) / 1000.0;
		if elapsed_time > timeout_ice_candidate:
			if (ice_candidates.size() > 0):
				break;
			print("Timeout ICE gathering Client : ", id);
			error_occurred.emit(current_lobby.id);
			return;
	
	if (connected_peer == null):
		return;
	
	# wait for the last ice candidate
	await get_tree().process_frame;
	
	connected_peer.get_connection_state()
	connected_peer.ice_candidate_created.disconnect(ice_candidate_created);
	
	print("Client ice candidate gathering completed")
	
	await LobbyWebSocket.ice_candidate_put(LobbyWebSocket.websocket_user_id, current_lobby.id, ice_candidates, false);

func answer_created(type: String, sdp: String, player_id: String):
	if type != "answer":
		print("The client should receive an answer");
		return;
	if sdp == null || sdp == "":
		print("SDP empty for : ", player_id);
		return;
	connected_peer.set_local_description(type, sdp)
	connected_peer.session_description_created.disconnect(answer_signal_callback);
	LobbyWebSocket.sdp_put(player_id, current_lobby.id, sdp, "answer")

func ice_candidate_created(sdp_mid: String, index: int, candidate: String):
	ice_candidates.append(IceCandidate.new(candidate, sdp_mid, index))
	print("ICE candidate from host : ", candidate);

func _on_peer_connected(peer_id: int):
	print("Peer connected !");
	set_process(false);
	GameManager.players[peer_id] = player;
	GameManager.add_player_data.rpc_id(peer_id, Player.to_dict(player));
	counter_timeout = 0.0;
	rtc_peer.peer_connected.disconnect(_on_peer_connected);
	rtc_peer.peer_disconnected.connect(_on_peer_disconnected);
	PopUpManager.remove_pop_up();
	LobbyWebSocket.update_lobby.disconnect(on_update_lobbies);

func _on_peer_disconnected(peer_id: int):
	if (peer_id != 1):
		return;
	quit_lobby();

func _process(delta: float) -> void:
	if connected_peer != null:
		connected_peer.poll();
	counter_timeout += delta;
	if (counter_timeout > timeout):
		error_occurred.emit(current_lobby.id);
		set_process(false);

func quit_lobby():
	if (LobbyWebSocket.update_lobby.is_connected(on_update_lobbies)):
		LobbyWebSocket.update_lobby.disconnect(on_update_lobbies);
	if (connected_peer):
		if (connected_peer.ice_candidate_created.is_connected(ice_candidate_created)):
			connected_peer.ice_candidate_created.disconnect(ice_candidate_created);
		if (connected_peer.session_description_created.is_connected(answer_signal_callback)):
			connected_peer.session_description_created.disconnect(answer_signal_callback);
		connected_peer.close();
		connected_peer = null;
	if (rtc_peer.peer_connected.is_connected(_on_peer_connected)):
		rtc_peer.peer_connected.disconnect(_on_peer_connected);
	if (rtc_peer):
		rtc_peer.close();
		rtc_peer = null;
	current_lobby = null;
	counter_timeout = 0.0;
	set_process(false);
	if (current_lobby != null):
		LobbyWebSocket.quit_lobby_post(current_lobby.id);
