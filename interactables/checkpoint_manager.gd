extends Node
# Autoload script that holds the last checkpoint reached
# a spawn point.
const DEFAULT_HEALTH: int = 3

var last_position: Vector2 = Vector2.INF
var last_health_by_player: Dictionary = {1: DEFAULT_HEALTH, 2: DEFAULT_HEALTH}

signal checkpoint_reached(position: Vector2, health_by_player: Dictionary)

func set_checkpoint(position: Vector2, player_1_health: int, player_2_health: int) -> void:
	last_position = position
	last_health_by_player[1] = clampi(player_1_health, 0, 3)
	last_health_by_player[2] = clampi(player_2_health, 0, 3)
	checkpoint_reached.emit(position, last_health_by_player.duplicate(true))

func get_spawn_position() -> Vector2:
	return last_position

func get_spawn_health(player_id: int) -> int:
	var health_value = last_health_by_player.get(player_id, DEFAULT_HEALTH)
	if health_value is int:
		return health_value
	return DEFAULT_HEALTH

func has_checkpoint() -> bool:
	return last_position != Vector2.INF

func clear_checkpoint() -> void:
	last_position = Vector2.INF
	last_health_by_player[1] = DEFAULT_HEALTH
	last_health_by_player[2] = DEFAULT_HEALTH
