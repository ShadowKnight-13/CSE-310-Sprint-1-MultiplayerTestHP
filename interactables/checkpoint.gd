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
	if body == null or not body.is_in_group("player"):
		return

	_activated = true
	set_deferred("monitoring", false)

	var team_health: int = DEFAULT_HEALTH

	for player in get_tree().get_nodes_in_group("player"):
		if player == null:
			continue

		var health_value = player.get("health")
		if not (health_value is int):
			continue

		team_health = max(team_health, health_value)

	CheckpointManager.set_checkpoint(global_position, team_health, team_health)
	$AnimationPlayer.play("Get")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Get":
		$AnimationPlayer.play("Wave2")
