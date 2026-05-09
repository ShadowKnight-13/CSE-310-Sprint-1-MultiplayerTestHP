extends Area2D

const DEFAULT_HEALTH := 3
var _activated: bool = false

#needs code to play idle wave anim before & after collection

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	$AnimationPlayer.play("Wave1")

func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
<<<<<<< Updated upstream

	var player_1_health := 3
	var player_2_health := 3
	for player in get_tree().get_nodes_in_group("player"):
		var player_id_value = player.get("player_id")
		var health_value = player.get("health")
		if not (player_id_value is int) or not (health_value is int):
			continue
		var player_id: int = player_id_value
		if player_id == 1:
			player_1_health = health_value
		elif player_id == 2:
			player_2_health = health_value

	CheckpointManager.set_checkpoint(global_position, player_1_health, player_2_health)
=======
	if body == null or not body.is_in_group("player"):
		return

	_activated = true
>>>>>>> Stashed changes
	set_deferred("monitoring", false)

	var player_1_health: int = DEFAULT_HEALTH
	var player_2_health: int = DEFAULT_HEALTH

	for player in get_tree().get_nodes_in_group("player"):
		if player == null:
			continue

		var player_id_value = player.get("player_id")
		var health_value = player.get("health")

		if not (player_id_value is int) or not (health_value is int):
			continue

		var player_id: int = player_id_value
		if player_id == 1:
			player_1_health = health_value
		elif player_id == 2:
			player_2_health = health_value

	CheckpointManager.set_checkpoint(global_position, player_1_health, player_2_health)
	$AnimationPlayer.play("Get")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Get":
		$AnimationPlayer.play("Wave2")
