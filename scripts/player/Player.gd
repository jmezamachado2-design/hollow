extends CharacterBody2D
## Movimiento metroidvania + combate direccional con Hitbox y HealthComponent.

# --- Movimiento horizontal ---
const MAX_SPEED := 200.0
const ACCEL_GROUND := 800.0
const ACCEL_AIR := 400.0
const FRICTION_GROUND := 600.0

# --- Vertical ---
const JUMP_VELOCITY := -450.0
const GRAVITY := 1200.0
const COYOTE_TIME := 0.12
# --- Combate ---
const PLAYER_KNOCKBACK_SPEED := 220.0
const ATTACK_STRIKE_FRAME := 2
const ATTACK_COOLDOWN := 0.45
const ATTACK_DIRECTION_DEADZONE := 0.35

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var hitbox: Hitbox = $Hitbox
@onready var camera: CameraShake = $Camera2D

var double_jump_enabled: bool = false

var facing: int = 1
var _coyote_timer: float = 0.0
var _air_jumps_left: int = 0
var _anim_name: String = ""

var _is_attacking: bool = false
var _attack_direction: Vector2 = Vector2.RIGHT
var _attack_cooldown: float = 0.0
var _blink_tween: Tween = null
var _was_on_floor: bool = false


func _ready() -> void:
	add_to_group("player")
	_coyote_timer = COYOTE_TIME
	health.max_health = GameManager.max_health
	health.current_health = GameManager.current_health
	health.invulnerable_duration = 1.5

	hitbox.setup(self)
	hitbox.hit_landed.connect(_on_hit_landed)

	_setup_sprite_frames_if_needed()
	animated_sprite.frame_changed.connect(_on_animation_frame_changed)

	health.damaged.connect(_on_health_damaged)
	health.died.connect(_on_health_died)
	health.health_changed.connect(_on_health_changed)
	GameManager.player_died.connect(_on_game_manager_died)
	_was_on_floor = is_on_floor()


func _physics_process(delta: float) -> void:
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta


	if not _is_attacking:
		_apply_horizontal_movement(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION_GROUND * 4.0 * delta)

	_apply_gravity(delta)
	_handle_jump()
	move_and_slide()
	_handle_landing_fx()
	_update_coyote_time(delta)
	_update_animation()


func _unhandled_input(_event: InputEvent) -> void:
	if InputHandler.is_attack_just_pressed() and _can_start_attack():
		_start_attack()


# =============================================================================
# MOVIMIENTO HORIZONTAL
# =============================================================================

func _apply_horizontal_movement(delta: float) -> void:
	var direction := InputHandler.get_move_direction().x

	if direction != 0.0:
		facing = int(sign(direction))
		var accel := ACCEL_GROUND if is_on_floor() else ACCEL_AIR
		var target_x := direction * MAX_SPEED
		velocity.x = move_toward(velocity.x, target_x, accel * delta)
	else:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, FRICTION_GROUND * delta)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0


# =============================================================================
# SALTO
# =============================================================================

func _update_coyote_time(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
		if double_jump_enabled:
			_air_jumps_left = 1
	else:
		_coyote_timer -= delta


func _handle_jump() -> void:
	if not InputHandler.is_jump_just_pressed():
		return
	if _can_perform_jump():
		_perform_jump()
		InputHandler.consume_jump_buffer()


func _can_perform_jump() -> bool:
	if _coyote_timer > 0.0:
		return true
	if double_jump_enabled and _air_jumps_left > 0:
		return true
	return false


func _perform_jump() -> void:
	if _coyote_timer <= 0.0 and double_jump_enabled and _air_jumps_left > 0:
		_air_jumps_left -= 1
	else:
		_coyote_timer = 0.0
	velocity.y = JUMP_VELOCITY


func enable_double_jump() -> void:
	double_jump_enabled = true
	if is_on_floor():
		_air_jumps_left = 1


func disable_double_jump() -> void:
	double_jump_enabled = false
	_air_jumps_left = 0


# =============================================================================
# COMBATE — Ataque en 4 direcciones según get_move_direction() (flechas / WASD parcial)
# La hitbox solo se activa en ATTACK_STRIKE_FRAME vía frame_changed.
# =============================================================================

func _can_start_attack() -> bool:
	return not _is_attacking and _attack_cooldown <= 0.0 and health.is_alive()


func _get_attack_direction() -> Vector2:
	var move := InputHandler.get_move_direction()
	if move.length() >= ATTACK_DIRECTION_DEADZONE:
		if absf(move.x) >= absf(move.y):
			return Vector2.RIGHT if move.x > 0.0 else Vector2.LEFT
		return Vector2.UP if move.y < 0.0 else Vector2.DOWN
	return Vector2.RIGHT if facing > 0 else Vector2.LEFT


func _start_attack() -> void:
	_attack_direction = _get_attack_direction()
	_is_attacking = true
	_attack_cooldown = ATTACK_COOLDOWN

	hitbox.set_direction(_attack_direction)

	var anim := _get_attack_animation_name()
	_anim_name = anim
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(anim):
		animated_sprite.play(anim)
		animated_sprite.frame = 0

	if _attack_direction.x != 0.0:
		facing = int(sign(_attack_direction.x))
		animated_sprite.flip_h = facing < 0
	elif _attack_direction == Vector2.UP:
		animated_sprite.flip_h = false


func _get_attack_animation_name() -> String:
	if _attack_direction == Vector2.UP:
		return "attack_up"
	if _attack_direction == Vector2.DOWN:
		return "attack_down"
	return "attack_side"


func _handle_landing_fx() -> void:
	var on_floor_now := is_on_floor()
	if on_floor_now and not _was_on_floor and velocity.y >= 0.0:
		ParticleEffects.spawn_landing_dust(global_position + Vector2(0.0, 8.0))
		AudioManager.reproduce_sfx("land", 0.08)
	_was_on_floor = on_floor_now


func _on_hit_landed(target: Node) -> void:
	var hit_pos := global_position
	if target is Node2D:
		hit_pos = (target as Node2D).global_position
	ParticleEffects.spawn_attack_sparks(hit_pos)
	GameManager.add_souls(GameManager.SOUL_PER_HIT)
	AudioManager.reproduce_sfx("hit", 0.12)


func _on_animation_frame_changed() -> void:
	if not _is_attacking:
		return
	if animated_sprite.frame != ATTACK_STRIKE_FRAME:
		return
	if not _is_attack_animation_playing():
		return
	hitbox.activate_strike()
	camera.shake(2.5, 0.08)


func _is_attack_animation_playing() -> bool:
	var anim := animated_sprite.animation
	return anim.begins_with("attack")


func _finish_attack() -> void:
	_is_attacking = false
	_update_animation()


# =============================================================================
# RECIBIR DAÑO — Invulnerabilidad 1.5s, parpadeo y knockback
# =============================================================================

func take_damage(amount: int = 1, source: Node = null) -> void:
	health.take_damage(amount, source)


func _on_health_damaged(_amount: int, source: Node) -> void:
	var knock_dir := Vector2(-facing, -0.35)
	if source is Node2D:
		knock_dir = (global_position - source.global_position).normalized()
	if knock_dir == Vector2.ZERO:
		knock_dir = Vector2(-facing, 0.0)

	velocity = knock_dir * PLAYER_KNOCKBACK_SPEED
	camera.shake(6.0, 0.2)
	_start_invulnerability_blink()


func _start_invulnerability_blink() -> void:
	_stop_invulnerability_blink()
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(animated_sprite, "modulate:a", 0.2, 0.07)
	_blink_tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.07)
	var timer := get_tree().create_timer(health.invulnerable_duration)
	timer.timeout.connect(_stop_invulnerability_blink, CONNECT_ONE_SHOT)


func _stop_invulnerability_blink() -> void:
	if _blink_tween != null and _blink_tween.is_valid():
		_blink_tween.kill()
		_blink_tween = null
	if animated_sprite != null:
		animated_sprite.modulate = Color(1, 1, 1, 1)


func _on_health_changed(current: int, maximum: int) -> void:
	GameManager.max_health = maximum
	GameManager.current_health = current
	GameManager.health_changed.emit(current, maximum)


func _on_health_died() -> void:
	if not GameManager.is_transitioning:
		GameManager.player_died.emit()


func _on_game_manager_died() -> void:
	if GameManager.is_transitioning:
		return
	set_physics_process(false)


func on_respawn() -> void:
	_is_attacking = false
	_attack_cooldown = 0.0
	_stop_invulnerability_blink()
	health.current_health = GameManager.current_health
	health.max_health = GameManager.max_health
	health._invuln_timer = 1.0
	_start_invulnerability_blink()


# =============================================================================
# ANIMACIONES — locomoción + ataque
# =============================================================================

func _update_animation() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return

	if _is_attacking:
		if not animated_sprite.is_playing():
			_finish_attack()
		return

	animated_sprite.flip_h = facing < 0

	var next_anim := _get_locomotion_animation_name()
	if next_anim == _anim_name:
		return

	_anim_name = next_anim
	if animated_sprite.sprite_frames.has_animation(_anim_name):
		animated_sprite.play(_anim_name)


func _get_locomotion_animation_name() -> String:
	if not is_on_floor():
		return "jump" if velocity.y < 0.0 else "fall"
	if absf(velocity.x) > 10.0:
		return "run"
	return "idle"


func _setup_sprite_frames_if_needed() -> void:
	if animated_sprite.sprite_frames != null:
		return

	var frames := SpriteFrames.new()
	var tex := _make_placeholder_texture()

	for anim_name in ["idle", "run", "jump", "fall", "attack_side", "attack_up", "attack_down"]:
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, 10.0 if anim_name.begins_with("attack") else 8.0)
		frames.set_animation_loop(anim_name, not anim_name.begins_with("attack"))
		for i in 4 if anim_name.begins_with("attack") else 1:
			frames.add_frame(anim_name, tex)

	animated_sprite.sprite_frames = frames


func _make_placeholder_texture() -> Texture2D:
	var img := Image.create(8, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.55, 0.75, 0.95))
	return ImageTexture.create_from_image(img)
