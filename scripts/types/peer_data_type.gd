class_name PeerData
extends RefCounted

var peer: WebRTCPeerConnection;
var ice_candidates: Array = [];
var ice_candidates_callback: Callable = Callable();
var session_description_created_callback: Callable = Callable();
var remote_description_set: bool = false;
var last_answer_sdp: String;

func _init(peer: WebRTCPeerConnection) -> void:
	self.peer = peer;
