extends ColorRect


func _on_Player_player_stats_changed(player):
	$Label.text = str(player.health_potions)
