extends Area2D

#needs code to play idle wave anim before & after collection

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$AnimationPlayer.play("Wave1")

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	var player_1_health := 3
	var player_2_health := 3
	for player in get_tree().get_nodes_in_group("player"):
		var player_id_value = player.get("player_id")
		var health_value = player.get("health")
		if player_id_value == null or health_value == null:
			continue
		var player_id: int = int(player_id_value)
		if player_id == 1:
			player_1_health = int(health_value)
		elif player_id == 2:
			player_2_health = int(health_value)

	CheckpointManager.set_checkpoint(global_position, player_1_health, player_2_health)
	set_deferred("monitoring", false)
	$AnimationPlayer.play("Get")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Get":
		$AnimationPlayer.play("Wave2")
