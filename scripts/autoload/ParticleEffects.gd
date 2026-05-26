extends Node
## Emite bursts de GPUParticles2D (polvo, chispas, esporas).

const AUTO_FREE_MARGIN := 0.15


func spawn_landing_dust(world_pos: Vector2) -> void:
	_emit_burst(world_pos, Color(0.55, 0.52, 0.5, 0.85), 8, 55.0, 0.35, Vector2(0.6, 1.2))


func spawn_attack_sparks(world_pos: Vector2) -> void:
	_emit_burst(world_pos, Color(1.0, 0.92, 0.35, 1.0), 5, 75.0, 0.28, Vector2(0.8, 0.8))


func spawn_death_spores(world_pos: Vector2) -> void:
	_emit_burst(world_pos, Color(0.45, 0.85, 0.55, 0.9), 12, 40.0, 0.55, Vector2(1.0, 1.4), true)


func _emit_burst(
	world_pos: Vector2,
	color: Color,
	count: int,
	spread_deg: float,
	lifetime: float,
	scale: Vector2,
	float_up: bool = false,
) -> void:
	var host := _get_particle_host()
	if host == null:
		return

	var particles := GPUParticles2D.new()
	particles.amount = count
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = lifetime
	particles.fixed_fps = 0
	particles.interpolate = false

	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.direction = Vector3(0.0, -1.0 if float_up else 0.2, 0.0)
	mat.spread = spread_deg
	mat.initial_velocity_min = 18.0
	mat.initial_velocity_max = 55.0
	mat.gravity = Vector3(0.0, 90.0 if not float_up else -20.0, 0.0)
	mat.scale_min = scale.x * 0.6
	mat.scale_max = scale.y
	mat.color = color

	particles.process_material = mat
	particles.global_position = world_pos
	particles.emitting = true
	host.add_child(particles)

	var timer := get_tree().create_timer(lifetime + AUTO_FREE_MARGIN)
	timer.timeout.connect(particles.queue_free, CONNECT_ONE_SHOT)


func _get_particle_host() -> Node:
	var main := get_tree().current_scene
	if main != null:
		return main
	return get_tree().root
