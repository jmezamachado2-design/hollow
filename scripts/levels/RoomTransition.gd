class_name RoomTransition
extends Area2D
## Área en el borde de la sala; al entrar el jugador, GameManager cambia de escena.

@export_file("*.tscn") var target_room_path: String = ""
@export var target_entry_id: String = "default"

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 1
	monitoring = true


func _on_body_entered(body: Node2D) -> void:
	if _triggered or GameManager.is_transitioning:
		return
	if not body.is_in_group("player"):
		return
	if target_room_path.is_empty():
		push_warning("RoomTransition sin target_room_path en %s" % get_path())
		return

	_triggered = true
	GameManager.transition_to_room(target_room_path, target_entry_id)
