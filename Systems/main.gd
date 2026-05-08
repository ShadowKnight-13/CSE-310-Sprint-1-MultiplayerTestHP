extends Node2D

@export var level_scene: PackedScene
@export var default_spawn_position: Vector2 = Vector2(200, 200)
@export var default_spawn_health: int = 3

var current_level_instance: Node = null
@onready var _level_container: Node = $Level
@onready var _wrapper_player_1: Node2D = get_node_or_null("Player")
@onready var _wrapper_player_2: Node2D = get_node_or_null("Player2")
var _active_level_resolved_path: String = ""
var _current_level_path: String = ""
const TEAM_RESPAWN_OFFSETS := [Vector2(-24, 0), Vector2(24, 0)]

func _ready() -> void:
	add_to_group("GameMain")

	# Start with whatever `Main_*.tscn` wrapper provided as `level_scene`.
	if level_scene and level_scene.resource_path != "":
		load_level(level_scene.resource_path)
	else:
		# Still ensure the wrapper player has correct initial health/state.
		respawn_players()


func set_font_size_recursive(node: Node, size: int) -> void:
	if node is Control:
		node.add_theme_font_size_override("font_size", size)
	
	for child in node.get_children():
		set_font_size_recursive(child, size)


func load_level(level_ref: String) -> void:
	var resolved_path := _resolve_level_ref_to_path(level_ref)
	if resolved_path == "":
		push_error("Main.load_level: Could not resolve level_ref: %s" % level_ref)
		return

	_current_level_path = resolved_path

	# Switch music based on the level being loaded.
	if has_node("/root/Music"):
		var music := get_node("/root/Music")
		var track_id := ""
		if resolved_path == "res://Levels/DesertCave.tscn" or resolved_path == "res://Levels/Desert.tscn":
			track_id = "protocol2"
		elif resolved_path == "res://Levels/Lab.tscn":
			track_id = "protocol"
		if track_id != "":
			music.call("play", track_id, 1.0)

	# Checkpoints are stored globally in the CheckpointManager autoload.
	# When switching levels, clear the previous level's checkpoint so spawning
	# uses the new level's SpawnPoint unless the player reaches a checkpoint there.
	if resolved_path != _active_level_resolved_path:
		CheckpointManager.clear_checkpoint()
		_active_level_resolved_path = resolved_path
	# CollectibleManager (people saved count) is run-wide across levels; call CollectibleManager.reset_run() if you want a reset.

	var packed_scene: PackedScene = load(resolved_path)
	if packed_scene == null:
		push_error("Main.load_level: Failed to load PackedScene: %s" % resolved_path)
		return

	_clear_current_level()

	current_level_instance = packed_scene.instantiate()
	current_level_instance.name = "Level"

	# Remove level-local Player instances to avoid duplicates with the wrapper player.
	_remove_player_nodes_recursive(current_level_instance)

	_level_container.add_child(current_level_instance)
	respawn_players()
	set_font_size_recursive(self, UiGlobals.text_size)

func reset_current_level_on_death() -> void:
	# Recreate the current level instance so enemies/hazards reset,
	# but keep checkpoint data so respawn still uses it.
	if _current_level_path == "":
		respawn_players(true)
		return

	var packed_scene: PackedScene = load(_current_level_path)
	if packed_scene == null:
		push_error("Main.reset_current_level_on_death: Failed to load PackedScene: %s" % _current_level_path)
		respawn_players(true)
		return

	_clear_current_level()

	current_level_instance = packed_scene.instantiate()
	current_level_instance.name = "Level"
	_remove_player_nodes_recursive(current_level_instance)
	_level_container.add_child(current_level_instance)

	respawn_players(true)

func respawn_players(full_health: bool = false) -> void:
	var spawn_pos: Vector2 = default_spawn_position
	var spawn_health_p1: int = default_spawn_health
	var spawn_health_p2: int = default_spawn_health

	if CheckpointManager.has_checkpoint():
		spawn_pos = CheckpointManager.get_spawn_position()
		spawn_health_p1 = default_spawn_health if full_health else CheckpointManager.get_spawn_health(1)
		spawn_health_p2 = default_spawn_health if full_health else CheckpointManager.get_spawn_health(2)
	else:
		# Prefer a per-level SpawnPoint marker if it exists.
		var spawn_node := _find_spawn_point_node(current_level_instance)
		if spawn_node:
			spawn_pos = spawn_node.global_position

		# If no spawn node exists, keep defaults.
		spawn_health_p1 = default_spawn_health
		spawn_health_p2 = default_spawn_health

	var players := _get_wrapper_players()
	for i in range(players.size()):
		var wrapper_player := players[i]
		var player_id := _get_player_id(wrapper_player, i + 1)
		var player_spawn_health := spawn_health_p1 if player_id == 1 else spawn_health_p2
		var spawn_offset := Vector2.ZERO
		if players.size() > 1:
			spawn_offset = TEAM_RESPAWN_OFFSETS[min(i, TEAM_RESPAWN_OFFSETS.size() - 1)]

		wrapper_player.global_position = spawn_pos + spawn_offset
		wrapper_player.health = player_spawn_health

		# Reset internal movement/dash/crouch/collision state for consistent respawns.
		if wrapper_player.has_method("reset_for_respawn"):
			wrapper_player.call("reset_for_respawn")
		else:
			# Minimal fallback in case the method isn't present.
			wrapper_player.velocity = Vector2.ZERO
			wrapper_player.set_physics_process(true)

		wrapper_player.emit_signal("health_changed", wrapper_player.health)

func respawn_player(full_health: bool = false) -> void:
	respawn_players(full_health)

func _clear_current_level() -> void:
	if current_level_instance and is_instance_valid(current_level_instance):
		current_level_instance.queue_free()
	current_level_instance = null

	# Clear any stray children under the container (defensive).
	for child in _level_container.get_children():
		child.queue_free()

func _resolve_level_ref_to_path(level_ref: String) -> String:
	if level_ref == "":
		return ""

	# door.tscn currently stores `uid://...` in its exported `level`.
	if level_ref.begins_with("uid://"):
		var uid_id := ResourceUID.text_to_id(level_ref)
		if ResourceUID.has_id(uid_id):
			return ResourceUID.get_id_path(uid_id)
		return ""

	# Most of the time we pass `res://...`.
	if level_ref.begins_with("res://"):
		return level_ref

	return ""

func _remove_player_nodes_recursive(root: Node) -> void:
	for child in root.get_children():
		if child is CharacterBody2D and child.is_in_group("player"):
			# The level scene is currently not in the main tree yet, so free immediately.
			child.free()
		else:
			_remove_player_nodes_recursive(child)

func _get_wrapper_players() -> Array[Node2D]:
	var players: Array[Node2D] = []
	if _wrapper_player_1 and is_instance_valid(_wrapper_player_1):
		players.append(_wrapper_player_1)
	if _wrapper_player_2 and is_instance_valid(_wrapper_player_2):
		players.append(_wrapper_player_2)
	return players

func _get_player_id(player: Node, fallback: int) -> int:
	if player:
		var player_id_value = player.get("player_id")
		if player_id_value is int:
			return player_id_value
	return fallback

func _find_spawn_point_node(root: Node) -> Node2D:
	if root == null:
		return null

	if root is Node2D:
		# Some levels use names like `Level#SpawnPoint`, so we match by suffix.
		if root.name == "SpawnPoint" or root.name.ends_with("SpawnPoint"):
			return root

	for child in root.get_children():
		var result := _find_spawn_point_node(child)
		if result:
			return result

	return null

func _process(delta: float) -> void:
	pass
