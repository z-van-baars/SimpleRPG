extends Area2D

func _on_Gem_body_entered(body):
	if body.name == "Player":
		body.add_gem()
		get_tree().queue_delete(self)
