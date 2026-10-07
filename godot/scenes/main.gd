extends Node2D


func _ready() -> void:
	$Floor.texture = Assets.texture("ENV-FACTORY-FLOOR")
	$Player.state_changed.connect($HUD.set_player_state)
	# Player's _ready already entered IDLE before this connection existed.
	$HUD.set_player_state($Player.art_id())
