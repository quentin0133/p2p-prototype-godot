class_name WebSocketMessage
extends RefCounted

enum MessageType {
	INIT,
	LOBBY_UPDATE,
	LOBBY_CANDIDATE,
	LOBBY_ICE_CANDIDATE,
	LOBBY_JOINED,
	SERVER_UP,
	SERVER_DOWN
}

var type: MessageType;
var payload;
