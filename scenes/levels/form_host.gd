extends ColorRect

signal start_hosting(username, max_player);

@onready var username: LineEdit = $Background/HBoxContainer3/UsernameTextEdit;
@onready var max_player: LineEdit = $Background/HBoxContainer2/MaxPlayerTextEdit

func submit():
	username.text = username.text.strip_edges();
	if (username.text == ""):
		# feedback error
		return;
	if (!max_player.text.is_valid_int()):
		# feedback error
		return;
	start_hosting.emit(username.text, max_player.text);
