class_name IceCandidate
extends RefCounted

var candidate: String;
var sdp_mid: String;
var sdp_mline_index: int;

func _init(candidate: String = "", sdp_mid: String = "", sdp_mline_index: int = -1):
	self.candidate = candidate;
	self.sdp_mid = sdp_mid;
	self.sdp_mline_index = sdp_mline_index;

static func from_dict(data: Dictionary) -> IceCandidate:
	var ice = IceCandidate.new()
	ice.candidate = data.get("candidate", "")
	ice.sdp_mid = data.get("sdp_mid", "")
	ice.sdp_mline_index = data.get("sdp_mline_index", 0)
	return ice
