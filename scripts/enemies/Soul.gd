class_name Soul
extends Area2D
## Esencia liberada al morir un enemigo; se atrae hacia el jugador.

@export var attract_speed: float = 140.0
@export var collect_distance: float = 10.0
@export var lifetime: float = 8.0

@onready var sprite: ColorRect = $Sprite

var _player: Node2D
var _life_timer: float = 0.0


func _ready() -> void:
	_life_timer = lifetime
	body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_start_float_tween()


func _physics_process(delta: float) -> void:
	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()
		return

	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
		return

	global_position = global_position.move_toward(
		_player.global_position,
		attract_speed * delta,
	)

	if global_position.distance_to(_player.global_position) <= collect_distance:
		_collect()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()


func _collect() -> void:
	GameManager.add_souls(4.0)
	AudioManager.reproduce_sfx("collect", 0.1)
	queue_free()


func _start_float_tween() -> void:
	if sprite == null:
		return
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -3.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
