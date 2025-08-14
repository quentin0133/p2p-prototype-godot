class_name HostManager
extends Node

signal error_occurred(lobby_id: String);

var rtc_peer: WebRTCMultiplayerPeer;
var peers_data := {};
var lobby: Lobby;
var ICE_SERVERS := {
	"iceServers": [
		{"urls": "stun:stun.l.google.com:19302"},
		{"urls": "stun:stun1.l.google.com:19302"},
		{"urls": "stun:stun2.l.google.com:19302"},
		{"urls": "stun:stun3.l.google.com:19302"},
		{"urls": "stun:stun4.l.google.com:19302"},
		{
			"urls": 'turn:stun.cloudflare.com:3478',
			"username": '7a3c2cb4852413e8165119521f37ba97d43b3aadbdaa112786800ce4da709db1515ffc983b934d29d8d4c2c6a6cea24f78b5d8132979eb6b65e7860e5e1ea8a3',
			"credential": 'aba9b169546eb6dcc7bfb1cdf34544cf95b5161d602e3b5fa7c8342b2e9802fb='
		},
	]
}

var ice_candidate_timeout = 8.0;

func _ready() -> void:
	set_process(false);

func _exit_tree() -> void:
	if (LobbyWebSocket.update_lobby.is_connected(on_update_lobbies)):
		LobbyWebSocket.update_lobby.disconnect(on_update_lobbies);

func host_game(lobby: Lobby):
	rtc_peer = WebRTCMultiplayerPeer.new();	
	
	self.lobby = lobby;
	
	GameManager.players[1] = lobby.host_player;
	
	set_process(true);
	
	rtc_peer.create_server();
	multiplayer.multiplayer_peer = rtc_peer;
	
	rtc_peer.peer_connected.connect(_on_peer_connected);
	rtc_peer.peer_disconnected.connect(_on_peer_disconnected);
	LobbyWebSocket.update_lobby.connect(on_update_lobbies);

func on_update_lobbies(lobby: Lobby):
	if (LobbyWebSocket.websocket_user_id != lobby.host_player.id):
		return;
	
	self.lobby = lobby;
	
	for player_id in lobby.connections.keys():
		var connection_info: PeerConnectionInfo = lobby.connections[player_id];
		match connection_info.state:
			"want_join":
				print("New player to join : ", player_id)
				handle_incoming_join_request(player_id, lobby.id, connection_info);
			"answer":
				print("Receipt of answer from : ", player_id);
				handle_incoming_answer(player_id, lobby.id, connection_info);

func handle_incoming_join_request(player_id: String, lobby_id: String, connection_info: PeerConnectionInfo):
	var peer := WebRTCPeerConnection.new();
	var err_init := peer.initialize(ICE_SERVERS);
	if err_init != OK:
		print("Error WebRTC init for ", player_id);
		return;
	
	if rtc_peer.has_peer(connection_info.id):
		print("Failed to add peer because peer already added");
		return;
	
	print("connection_info.id : ", connection_info.id);
	print("type connection_info.id : ", typeof(connection_info.id));
	
	var err_peer = rtc_peer.add_peer(peer, connection_info.id);
	if err_peer != OK:
		print("Failed to add peer: ", err_peer);
		error_occurred.emit(lobby.id);
		return;
	
	print("Host added peer ", connection_info.id);
	
	# Store peer dans un dictionnaire si tu veux le garder :
	peers_data[player_id] = PeerData.new(peer);
	
	# Connecter les signaux
	peers_data[player_id].ice_candidates_callback = ice_candidate_created.bind(player_id);
	peers_data[player_id].session_description_created_callback = offer_created.bind(player_id);
	peer.ice_candidate_created.connect(peers_data[player_id].ice_candidates_callback);
	peer.session_description_created.connect(peers_data[player_id].session_description_created_callback);
	
	# Créer une offer
	var error = peer.create_offer();
	if (error != OK):
		print("Error generating offer : ", error);
	
	var start_time := Time.get_ticks_msec();
	while peers_data.has(player_id) && peers_data[player_id].peer.get_gathering_state() != WebRTCPeerConnection.GatheringState.GATHERING_STATE_COMPLETE:
		await get_tree().process_frame;
		var elapsed_time = (Time.get_ticks_msec() - start_time) / 1000.0;
		if elapsed_time > ice_candidate_timeout:
			if (peers_data[player_id].ice_candidates.size() > 0):
				break;
			print("Timeout ICE gathering Client and still no ice candidate : ");
			error_occurred.emit(lobby.id);
			return;
	
	if (!peers_data.has(player_id)):
		return;
	
	await get_tree().process_frame;
	
	peer.ice_candidate_created.disconnect(peers_data[player_id].ice_candidates_callback);
	
	print("Host ice candidate gathering completed");
	
	# Push des ice candidate accumulé
	LobbyWebSocket.ice_candidate_put(player_id, lobby.id, peers_data[player_id].ice_candidates, true);

func handle_incoming_answer(player_id: String, lobby_id: String, connection_info: PeerConnectionInfo):
	if !peers_data.has(player_id):
		print("No WebRTC connection for ", player_id);
		error_occurred.emit(lobby_id);
		return;
	
	var peer: WebRTCPeerConnection = peers_data[player_id].peer;
	var answer = connection_info.answer;
	
	if (peers_data[player_id].remote_description_set):
		print("Remote description already set for ", player_id);
		error_occurred.emit(lobby_id);
		return;
	
	if (peers_data[player_id].last_answer_sdp == answer):
		print("Same SDP for ", player_id);
		error_occurred.emit(lobby_id);
		return;
	
	var err := peer.set_remote_description("answer", answer);
	if err != OK:
		print("Error set_remote_description : ", err);
		return;
	else:
		peers_data[player_id].last_answer_sdp = answer;
		peers_data[player_id].remote_description_set = true;
	
	var ice_candidates_client := connection_info.ice_candidates_client;
	for ice in ice_candidates_client:
		peer.add_ice_candidate(
			ice.sdp_mid,
			ice.sdp_mline_index,
			ice.candidate
		);

func offer_created(type: String, sdp: String, player_id: String):
	if type != "offer":
		print("The host should receive an offer");
		return;
	if sdp == null || sdp == "":
		print("SDP empty for : ", player_id);
		return;
	
	var err = peers_data[player_id].peer.set_local_description(type, sdp);
	if err != OK:
		print("Failed to set local description: ", err);
		return;
	
	peers_data[player_id].peer.session_description_created.disconnect(
		peers_data[player_id].session_description_created_callback
	);
	
	print("sended offer to Client in Host");
	
	LobbyWebSocket.sdp_put(player_id, lobby.id, sdp, "offer");

func ice_candidate_created(sdp_mid: String, index: int, candidate: String, player_id: String):
	peers_data[player_id].ice_candidates.append(IceCandidate.new(candidate, sdp_mid, index));
	print("ICE candidate from host : ", candidate);

func _on_peer_connected(peer_id: int):
	for player_id in lobby.connections.keys():
		var peer_connection: PeerConnectionInfo = lobby.connections[player_id];
		if (peer_connection.id == peer_id):
			print("Connection established HOST")
			LobbyWebSocket.established_connection(player_id, lobby.id);

func _on_peer_disconnected(peer_id: int):
	print("Peer disconnected");
	GameManager.remove_player_data(peer_id);

func _process(_delta):
	for player_id  in peers_data.keys():
		var peer: WebRTCPeerConnection = peers_data[player_id].peer;
		peer.poll();

func clear_peer_connection(player_id: String):
	var peer_data: PeerData = peers_data[player_id];
	var peer: WebRTCPeerConnection = peer_data.peer;
	if (peer.ice_candidate_created.is_connected(peer_data.ice_candidates_callback)):
		peer.ice_candidate_created.disconnect(peer_data.ice_candidates_callback);
	if (peer.session_description_created.is_connected(peer_data.session_description_created_callback)):
		peer.session_description_created.disconnect(peer_data.session_description_created_callback);
	peer.close();
	peer = null;
	peers_data.erase(player_id);

func quit_lobby():
	print("Host manager quit lobby")
	if (LobbyWebSocket.update_lobby.is_connected(on_update_lobbies)):
		LobbyWebSocket.update_lobby.disconnect(on_update_lobbies);
	if (rtc_peer.peer_disconnected.is_connected(_on_peer_disconnected)):
		rtc_peer.peer_disconnected.disconnect(_on_peer_disconnected);
	for player_id in peers_data.keys():
		var peer_data: PeerData = peers_data[player_id];
		var peer: WebRTCPeerConnection = peer_data.peer;
		if (peer.ice_candidate_created.is_connected(peer_data.ice_candidates_callback)):
			peer.ice_candidate_created.disconnect(peer_data.ice_candidates_callback);
		if (peer.session_description_created.is_connected(peer_data.session_description_created_callback)):
			peer.session_description_created.disconnect(peer_data.session_description_created_callback);
		peer.close();
		peer = null;
	peers_data.clear();
	if (rtc_peer):
		rtc_peer.close();
		rtc_peer = null;
	if (lobby != null):
		LobbyWebSocket.quit_lobby_post(lobby.id);
		lobby = null;
	set_process(false);
