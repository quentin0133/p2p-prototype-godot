class_name LobbyItemUI
extends Node

@export var private_icon: TextureRect;
@export var players_label: Label;
@export var host_label: Label;
@export var join_btn: Button;

var current_nb_player = 0;
var current_lobby: Lobby;

func init(lobby: Lobby) -> void:
	current_lobby = lobby;
	host_label.text = lobby.host_player.name;
	players_label.text = str(len(lobby.players)) + " / " + str(lobby.max_player);
	private_icon.visible = lobby.pwd != "";
	
	if (len(lobby.players) < lobby.max_player):
		join_btn.text = "Join lobby";
		join_btn.disabled = false;
	else:
		join_btn.text = "Full";
		join_btn.disabled = true;
