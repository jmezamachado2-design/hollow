class_name ChaseState
extends EnemyState


func physics_update(_delta: float) -> void:
	if not enemy.is_player_in_detection_range():
		enemy.state_machine.change_state("patrol")
		return

	if enemy.is_player_in_attack_range() and enemy.can_attack():
		enemy.state_machine.change_state("attack")
		return

	var player := enemy.get_player()
	if player == null:
		enemy.state_machine.change_state("patrol")
		return

	var direction := signf(player.global_position.x - enemy.global_position.x)
	if direction != 0.0:
		enemy.facing = int(direction)

	enemy.velocity.x = direction * enemy.speed * enemy.chase_speed_multiplier
