class_name AttackState
extends EnemyState

var _cooldown_timer: float = 0.0


func enter() -> void:
	enemy.velocity.x = 0.0
	_cooldown_timer = enemy.attack_cooldown
	enemy.perform_attack()
	enemy.play_animation("attack")


func physics_update(delta: float) -> void:
	enemy.velocity.x = 0.0
	_cooldown_timer -= delta

	if _cooldown_timer > 0.0:
		return

	if enemy.is_player_in_attack_range() and enemy.is_player_in_detection_range():
		enemy.state_machine.change_state("chase")
	elif enemy.is_player_in_detection_range():
		enemy.state_machine.change_state("chase")
	else:
		enemy.state_machine.change_state("patrol")
