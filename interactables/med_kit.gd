extends StaticBody2D

@onready var interactable: Area2D = $interactable
@onready var sprite_2d: Sprite2D = $"Med Animator/Sprite2D"

@export var heal_amount: int = 1

var has_been_used: bool = false

func _ready() -> void:
	interactable.interacted.connect(_on_interact)
	CheckpointManager.checkpoint_reached.connect(_on_checkpoint_reached)

func _on_interact():
	if has_been_used:
		return
	for player in get_tree().get_nodes_in_group("player"):
		if player and player.has_method("heal"):
			player.heal(heal_amount)
	has_been_used = true
	sprite_2d.visible = false
	print("Med kit used! Team healed for ", heal_amount, " health")

func _on_checkpoint_reached(_position: Vector2, _health_by_player: Dictionary):
	has_been_used = false
	sprite_2d.visible = true
	print("Med kit reset at checkpoint")
