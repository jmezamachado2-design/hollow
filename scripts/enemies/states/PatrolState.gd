class_name PatrolState
extends EnemyState

const ARRIVE_THRESHOLD := 4.0

var _heading_right: bool = true


func enter() -> void:
	var bounds := enemy.get_patrol_bounds()
	_heading_right = enemy.global_position.x < (bounds.x + bounds.y) * 0.5


func physics_update(_delta: float) -> void:
	if enemy.is_player_in_detection_range():
		enemy.state_machine.change_state("chase")
		return

	var bounds := enemy.get_patrol_bounds()
	var left_x: float = bounds.x
	var right_x: float = bounds.y
	var target_x := right_x if _heading_right else left_x
	var direction := signf(target_x - enemy.global_position.x)

	if direction == 0.0:
		_heading_right = not _heading_right
		enemy.state_machine.change_state("idle")
		return

	enemy.facing = int(direction)
	enemy.velocity.x = direction * enemy.speed

	if absf(enemy.global_position.x - target_x) <= ARRIVE_THRESHOLD:
		_heading_right = not _heading_right
		enemy.velocity.x = 0.0
		enemy.state_machine.change_state("idle")
