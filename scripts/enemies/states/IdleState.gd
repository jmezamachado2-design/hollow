class_name IdleState
extends EnemyState

var _wait_time: float = 0.35


func enter() -> void:
	_wait_time = 0.35
	enemy.velocity.x = 0.0


func physics_update(delta: float) -> void:
	if enemy.is_player_in_detection_range():
		enemy.state_machine.change_state("chase")
		return

	_wait_time -= delta
	if _wait_time <= 0.0:
		enemy.state_machine.change_state("patrol")
