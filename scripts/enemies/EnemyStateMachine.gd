class_name EnemyStateMachine
extends Node
## Gestiona transiciones entre estados del enemigo.

var enemy: Enemy
var states: Dictionary = {}
var current: EnemyState
var current_name: String = ""


func setup(host: Enemy) -> void:
	enemy = host
	_register_states()


func _register_states() -> void:
	states = {
		"idle": IdleState.new(enemy),
		"patrol": PatrolState.new(enemy),
		"chase": ChaseState.new(enemy),
		"attack": AttackState.new(enemy),
		"hurt": HurtState.new(enemy),
		"dead": DeadState.new(enemy),
	}


func change_state(state_name: String) -> void:
	if not states.has(state_name):
		push_warning("Estado desconocido: %s" % state_name)
		return
	if current_name == state_name:
		return

	if current != null:
		current.exit()

	current = states[state_name]
	current_name = state_name
	current.enter()


func physics_update(delta: float) -> void:
	if current != null:
		current.physics_update(delta)
