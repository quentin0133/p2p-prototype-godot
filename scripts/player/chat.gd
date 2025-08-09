extends Control

signal on_message_sended(peer_id: int, message: String);

const DURATION = 0.35;

@onready var chat_line_edit: LineEdit = $LineEdit

var is_writting = false;

func _input(event: InputEvent) -> void:
	if (event.is_action("chat") && event.is_pressed()):
		is_writting = !is_writting;
		if (is_writting):
			show_chat_edit();
		else:
			chat_line_edit.text = chat_line_edit.text.strip_edges();
			if (!chat_line_edit.text.is_empty()):
				broadcast_message.rpc(chat_line_edit.text);
			chat_line_edit.text = "";
		PlayerInstance.can_move = !is_writting;
		visible = is_writting;

func show_chat_edit():
	modulate = Color(modulate, 0.0);
	await get_tree().process_frame;
	chat_line_edit.grab_focus();
	
	await TransitionUtils.fade_time(0.0, 1.0, DURATION, func(a): modulate.a = a);

@rpc("any_peer", "reliable", "call_local")
func broadcast_message(message: String):
	var peer_id = multiplayer.get_remote_sender_id();
	on_message_sended.emit(peer_id, message);
