class_name PeerConnectionInfo
extends RefCounted

var id: int;
var state: String;
var offer: String;
var answer: String;
var ice_candidates_host: Array;
var ice_candidates_client: Array;

static func from_dict(data: Dictionary) -> PeerConnectionInfo:
	var info = PeerConnectionInfo.new();
	info.id = data.get("id", -1);
	info.state = data.get("state", "want_join");
	info.offer = data.get("offer", "");
	info.answer = data.get("answer", "");

	info.ice_candidates_host = [];
	for c in data.get("ice_candidates_host", []):
		info.ice_candidates_host.append(IceCandidate.from_dict(c));

	info.ice_candidates_client = [];
	for c in data.get("ice_candidates_client", []):
		info.ice_candidates_client.append(IceCandidate.from_dict(c));
	
	return info;
