class_name HurtState
extends EnemyState

var _hurt_timer: float = 0.0


func enter() -> void:
	_hurt_timer = enemy.hurt_duration
	enemy.play_animation("hurt")


func physics_update(delta: float) -> void:
	_hurt_timer -= delta

	if enemy.is_knockback_active():
		return

	if _hurt_timer > 0.0:
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, enemy.speed * 4.0 * delta)
		return

	if not enemy.health.is_alive():
		return

	if enemy.is_player_in_attack_range() and enemy.can_attack():
		enemy.state_machine.change_state("attack")
	elif enemy.is_player_in_detection_range():
		enemy.state_machine.change_state("chase")
	else:
		enemy.state_machine.change_state("patrol")
