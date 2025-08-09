extends Node

@export var player_prefab: PackedScene;

func _ready() -> void:
	for i in len(GameManager.players):
		var current_player = player_prefab.instantiate() as PlayerInstance;
		add_child(current_player);
