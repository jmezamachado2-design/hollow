class_name EnemyState
extends RefCounted
## Estado base de la FSM del enemigo.

var enemy: Enemy


func _init(host: Enemy) -> void:
	enemy = host


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
