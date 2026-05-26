class_name Crawler
extends Enemy
## Enemigo "Crawler": patrulla entre marcadores Left/Right en el suelo.
## detection_range=200, attack_range=40, attack_cooldown=1.5 por defecto en escena.

@onready var patrol_left: Marker2D = $Patrol/Left
@onready var patrol_right: Marker2D = $Patrol/Right
@onready var sprite_rect: ColorRect = $Sprite


func _ready() -> void:
	initial_state = "patrol"
	super._ready()


func get_patrol_bounds() -> Vector2:
	if patrol_left != null and patrol_right != null:
		var left_x := patrol_left.global_position.x
		var right_x := patrol_right.global_position.x
		if left_x > right_x:
			return Vector2(right_x, left_x)
		return Vector2(left_x, right_x)
	return super.get_patrol_bounds()


func play_animation(anim_name: String) -> void:
	if sprite_rect == null:
		return
	match anim_name:
		"attack":
			sprite_rect.color = Color(1.0, 0.45, 0.35)
		"hurt":
			sprite_rect.color = Color(1.0, 0.85, 0.4)
		"death":
			sprite_rect.color = Color(0.35, 0.35, 0.4, 0.6)
		_:
			sprite_rect.color = Color(0.85, 0.25, 0.3)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state_machine.current_name == "dead":
		sprite_rect.modulate.a = maxf(sprite_rect.modulate.a - delta * 1.8, 0.0)
