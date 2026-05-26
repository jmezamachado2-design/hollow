class_name Enemy
extends CharacterBody2D
## Enemigo base con máquina de estados (FSM) y HealthComponent.
##
## ============================================================================
## DIAGRAMA DE LA MÁQUINA DE ESTADOS
## ============================================================================
##
##                         ┌─────────────┐
##                         │    IDLE     │  Espera breve en punto de patrulla
##                         └──────┬──────┘
##                                │ timer agotado
##                                ▼
##              ┌─────────────────────────────────────┐
##              │              PATROL                 │  Camina entre límites
##              └─────────┬───────────────────┬───────┘
##                        │ jugador ≤ det.    │ llega a marcador
##                        ▼                   ▼
##              ┌─────────────────┐      ┌─────────┐
##              │     CHASE       │◄─────│  IDLE   │
##              └────────┬────────┘      └─────────┘
##                       │ jugador ≤ atk + CD listo
##                       ▼
##              ┌─────────────────┐
##              │    ATTACK       │  Golpe + cooldown (1.5s Crawler)
##              └────────┬────────┘
##                       │ CD terminado
##                       └──────────► CHASE o PATROL (según distancia)
##
##   Cualquier estado vivo ──(HealthComponent.damaged)──► ┌────────┐
##                                                          │  HURT  │ knockback + i-frames
##                                                          └───┬────┘
##                                                              │ timer / knockback fin
##                                                              └──► CHASE | ATTACK | PATROL
##
##   Cualquier estado ──(HealthComponent.died)──► ┌────────┐
##                                                 │  DEAD  │ animación → soul → queue_free
##                                                 └────────┘
##
## ============================================================================
## Leyenda de transiciones rápidas:
##   PATROL  → CHASE   si distancia ≤ detection_range
##   CHASE   → PATROL  si jugador sale de detection_range
##   CHASE   → ATTACK  si distancia ≤ attack_range y attack_cooldown ≤ 0
##   ATTACK  → CHASE   si sigue en detección tras cooldown
##   *       → HURT    al recibir daño (si sigue vivo)
##   *       → DEAD    al llegar HP a 0
## ============================================================================

const GRAVITY := 1200.0

@export_group("Movement")
@export var patrol_distance: float = 48.0
@export var speed: float = 60.0
@export var chase_speed_multiplier: float = 1.35

@export_group("Combat")
@export var detection_range: float = 200.0
@export var attack_range: float = 40.0
@export var damage: int = 1
@export var attack_cooldown: float = 1.5

@export_group("Reactions")
@export var hurt_duration: float = 0.3
@export var death_animation_duration: float = 0.55

@onready var health: HealthComponent = $HealthComponent
@onready var state_machine: EnemyStateMachine = $StateMachine
@onready var sprite: CanvasItem = $Sprite

var facing: int = 1
var initial_state: String = "patrol"

var _attack_cooldown_timer: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_time_left: float = 0.0


func _ready() -> void:
	add_to_group("enemy")
	state_machine.setup(self)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	state_machine.change_state(initial_state)


func _physics_process(delta: float) -> void:
	if state_machine.current_name == "dead":
		state_machine.physics_update(delta)
		return

	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta

	if _knockback_time_left > 0.0:
		_apply_knockback_physics(delta)
	else:
		state_machine.physics_update(delta)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

	move_and_slide()
	_update_sprite_facing()


# --- Detección y patrulla (sobrescribir en subclases como Crawler) ---

func get_patrol_bounds() -> Vector2:
	var center := global_position.x
	return Vector2(center - patrol_distance, center + patrol_distance)


func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func get_distance_to_player() -> float:
	var player := get_player()
	if player == null:
		return INF
	return global_position.distance_to(player.global_position)


func is_player_in_detection_range() -> bool:
	return get_distance_to_player() <= detection_range


func is_player_in_attack_range() -> bool:
	return get_distance_to_player() <= attack_range


func can_attack() -> bool:
	return _attack_cooldown_timer <= 0.0


func is_knockback_active() -> bool:
	return _knockback_time_left > 0.0


# --- Combate y reacciones ---

func perform_attack() -> void:
	_attack_cooldown_timer = attack_cooldown
	var player := get_player()
	if player == null or not is_player_in_attack_range():
		return
	if player.has_method("take_damage"):
		player.take_damage(damage, self)


func apply_knockback(direction: Vector2, distance: float) -> void:
	var dir := direction.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2(-facing, 0.0)
	const KNOCKBACK_TIME := 0.14
	_knockback_velocity = dir * (distance / KNOCKBACK_TIME)
	_knockback_time_left = KNOCKBACK_TIME


func _apply_knockback_physics(delta: float) -> void:
	velocity = _knockback_velocity
	_knockback_time_left -= delta


func _on_damaged(_amount: int, source: Node) -> void:
	if not health.is_alive():
		return
	if source is Node2D:
		var knock_dir: Vector2 = (global_position - (source as Node2D).global_position).normalized()
		apply_knockback(knock_dir, 80.0)
	if state_machine.current_name != "dead":
		state_machine.change_state("hurt")


func _on_died() -> void:
	state_machine.change_state("dead")


# --- Muerte y soul ---

func spawn_soul() -> void:
	var soul := SOUL_SCENE.instantiate() as Soul
	if soul == null:
		return
	get_tree().current_scene.add_child(soul)
	soul.global_position = global_position + Vector2(0.0, -10.0)


func set_collision_active(enabled: bool) -> void:
	set_collision_layer_value(2, enabled)
	set_collision_mask_value(1, enabled)
	set_collision_mask_value(3, enabled)


func play_animation(_anim_name: String) -> void:
	pass


func _update_sprite_facing() -> void:
	if sprite == null:
		return
	sprite.scale.x = absf(sprite.scale.x) * facing


# Precargado por DeadState; expuesto aquí para spawn desde subclases.
const SOUL_SCENE := preload("res://scenes/enemies/Soul.tscn")
