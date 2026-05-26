class_name HeartSlot
extends Control
## Un slot de máscara estilo Hollow Knight (corazón / fragmento).

@onready var fill: ColorRect = $Mask/Fill
@onready var shine: ColorRect = $Mask/Shine

var _filled: bool = true


func _ready() -> void:
	fill.pivot_offset = Vector2(4.5, 4.0)


func set_filled(filled: bool, animate: bool = true) -> void:
	if _filled == filled and not animate:
		return
	_filled = filled

	var target_scale := 1.0 if filled else 0.0
	var target_alpha := 1.0 if filled else 0.35

	if animate:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(fill, "scale", Vector2(target_scale, target_scale), 0.22)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(fill, "modulate:a", target_alpha, 0.18)
		tween.tween_property(shine, "modulate:a", target_alpha * 0.6, 0.18)
	else:
		fill.scale = Vector2(target_scale, target_scale)
		fill.modulate.a = target_alpha
		shine.modulate.a = target_alpha * 0.6


func pulse_damage() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.06)
	tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_ELASTIC)


func pulse_heal() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
