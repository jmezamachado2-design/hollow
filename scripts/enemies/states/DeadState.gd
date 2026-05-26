class_name DeadState
extends EnemyState

const SOUL_SCENE := preload("res://scenes/enemies/Soul.tscn")

var _death_timer: float = 0.0


func enter() -> void:
	enemy.velocity = Vector2.ZERO
	enemy.set_collision_active(false)
	enemy.play_animation("death")
	_death_timer = enemy.death_animation_duration
	ParticleEffects.spawn_death_spores(enemy.global_position)
	AudioManager.reproduce_sfx("death", 0.1)
	enemy.spawn_soul()


func physics_update(delta: float) -> void:
	_death_timer -= delta
	if _death_timer <= 0.0:
		enemy.queue_free()
