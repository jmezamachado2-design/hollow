class_name HealthComponent
extends Node
## Salud reutilizable para jugador y enemigos. Emite señales al recibir daño o morir.

signal health_changed(current: int, maximum: int)
signal damaged(amount: int, source: Node)
signal died

@export var max_health: int = 5
@export var invulnerable_duration: float = 0.0

var current_health: int = 0
var _invuln_timer: float = 0.0


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func _process(delta: float) -> void:
	if _invuln_timer > 0.0:
		_invuln_timer -= delta


func is_invulnerable() -> bool:
	return _invuln_timer > 0.0


func is_alive() -> bool:
	return current_health > 0


func take_damage(amount: int, source: Node = null) -> bool:
	if amount <= 0 or not is_alive() or is_invulnerable():
		return false

	current_health = maxi(0, current_health - amount)
	if invulnerable_duration > 0.0:
		_invuln_timer = invulnerable_duration

	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		died.emit()

	return true


func heal(amount: int) -> void:
	if amount <= 0 or not is_alive():
		return
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func reset_health() -> void:
	current_health = max_health
	_invuln_timer = 0.0
	health_changed.emit(current_health, max_health)
