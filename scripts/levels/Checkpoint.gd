class_name Checkpoint
extends Area2D
## Interactúa con E para guardar sala, Entry Point y vida actual.

@export var entry_point_id: String = "default"
@export var interact_radius: float = 28.0

## Hijo "Sprite" en la escena: ColorRect (CanvasItem), no Node2D.
@onready var sprite: CanvasItem = $Sprite

var _player_in_range: bool = false
var _activated: bool = false

const COLOR_NORMAL := Color(0.45, 0.7, 0.95)
const COLOR_PROMPT := Color(0.95, 0.85, 0.25)
const COLOR_ACTIVATED := Color(0.35, 0.95, 0.55)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 0
	collision_mask = 1


func _process(_delta: float) -> void:
	if not _player_in_range or _activated:
		return
	if InputHandler.is_interact_just_pressed():
		_activate()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_show_prompt(true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_show_prompt(false)


func _activate() -> void:
	var room_path := GameManager.get_current_room_path()
	var health := GameManager.current_health
	GameManager.save_checkpoint(room_path, entry_point_id, health)
	_activated = true
	_show_prompt(false)
	sprite.modulate = COLOR_ACTIVATED


func _show_prompt(show: bool) -> void:
	sprite.modulate = COLOR_PROMPT if show else COLOR_NORMAL
