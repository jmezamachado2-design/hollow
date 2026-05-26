class_name Hitbox
extends Area2D
## Hitbox de ataque: activa solo en el frame de impacto. Daña enemigos del grupo "enemy".

signal hit_landed(target: Node)

const DAMAGE := 10
const KNOCKBACK_DISTANCE := 150.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var knockback_direction: Vector2 = Vector2.RIGHT
var _already_hit: Array[Node] = []
var _strike_active: bool = false

var _attacker: Node2D


func _ready() -> void:
	monitoring = false
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func setup(attacker: Node2D) -> void:
	_attacker = attacker


func set_direction(direction: Vector2) -> void:
	knockback_direction = direction.normalized()
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.RIGHT
	_align_hitbox_to_direction()


func activate_strike() -> void:
	_strike_active = true
	monitoring = true
	_already_hit.clear()


func _physics_process(_delta: float) -> void:
	if _strike_active:
		_strike_active = false
		monitoring = false


func _align_hitbox_to_direction() -> void:
	var offset := Vector2(14, 0)
	var shape_size := Vector2(14, 12)

	if knockback_direction == Vector2.UP:
		offset = Vector2(0, -14)
		shape_size = Vector2(12, 14)
	elif knockback_direction == Vector2.DOWN:
		offset = Vector2(0, 14)
		shape_size = Vector2(12, 14)
	elif knockback_direction == Vector2.LEFT:
		offset = Vector2(-14, 0)

	position = offset
	if collision_shape.shape is RectangleShape2D:
		var rect := collision_shape.shape as RectangleShape2D
		rect.size = shape_size
		collision_shape.position = Vector2(
			signf(knockback_direction.x) * 4.0 if knockback_direction.x != 0.0 else 0.0,
			signf(knockback_direction.y) * 4.0 if knockback_direction.y != 0.0 else 0.0,
		)


func _on_body_entered(body: Node2D) -> void:
	_try_hit(body)


func _on_area_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy is Node2D:
		_try_hit(enemy as Node2D)


func _try_hit(target: Node2D) -> void:
	if not target.is_in_group("enemy"):
		return
	if target in _already_hit:
		return

	_already_hit.append(target)

	var health := _find_health_component(target)
	if health != null:
		health.take_damage(DAMAGE, _attacker)

	_apply_knockback(target)
	hit_landed.emit(target)


func _find_health_component(target: Node) -> HealthComponent:
	if target.has_node("HealthComponent"):
		return target.get_node("HealthComponent") as HealthComponent
	return target.get_node_or_null("HealthComponent") as HealthComponent


func _apply_knockback(target: Node2D) -> void:
	var dir := knockback_direction
	if _attacker != null:
		dir = (target.global_position - _attacker.global_position).normalized()
		if dir == Vector2.ZERO:
			dir = knockback_direction

	if target.has_method("apply_knockback"):
		target.apply_knockback(dir, KNOCKBACK_DISTANCE)
