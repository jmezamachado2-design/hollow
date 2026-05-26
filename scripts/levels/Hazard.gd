class_name Hazard
extends Area2D
## Pinchos / vacío: muerte instantánea y respawn en el último checkpoint.

@export var kill_on_enter: bool = true

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 1
	monitoring = true


func _on_body_entered(body: Node2D) -> void:
	if _triggered or not kill_on_enter:
		return
	if not body.is_in_group("player"):
		return
	if GameManager.is_transitioning:
		return

	_triggered = true
	GameManager.kill_player_from_hazard()
