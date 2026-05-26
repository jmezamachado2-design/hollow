extends CanvasLayer
## HUD: máscaras de vida + medidor de almas con transiciones suaves.

const HEART_SCENE := preload("res://scenes/ui/HeartSlot.tscn")
const HEART_SIZE := Vector2(11, 10)

@onready var hearts_row: HBoxContainer = $Margin/Column/HeartsRow
@onready var soul_bar: ProgressBar = $Margin/Column/SoulRow/SoulBar
@onready var soul_label: Label = $Margin/Column/SoulRow/SoulLabel

var _heart_slots: Array[HeartSlot] = []
var _displayed_health: int = -1
var _displayed_souls: float = -1.0
var _soul_tween: Tween = null


func _ready() -> void:
	layer = 10
	_setup_soul_bar_style()
	_build_hearts(GameManager.max_health)
	_sync_health(GameManager.current_health, GameManager.max_health, false)
	_sync_souls(GameManager.current_souls, GameManager.max_souls, false)

	GameManager.health_changed.connect(_on_health_changed)
	GameManager.souls_changed.connect(_on_souls_changed)


func _on_health_changed(current: int, maximum: int) -> void:
	if maximum != _heart_slots.size():
		_build_hearts(maximum)
	_sync_health(current, maximum, true)


func _on_souls_changed(current: float, maximum: float) -> void:
	_sync_souls(current, maximum, true)


func _build_hearts(count: int) -> void:
	for child in hearts_row.get_children():
		child.queue_free()
	_heart_slots.clear()

	for i in count:
		var slot: HeartSlot = HEART_SCENE.instantiate()
		hearts_row.add_child(slot)
		slot.custom_minimum_size = HEART_SIZE
		_heart_slots.append(slot)


func _sync_health(current: int, maximum: int, animate: bool) -> void:
	for i in _heart_slots.size():
		var filled := i < current
		_heart_slots[i].set_filled(filled, animate)

	if animate and _displayed_health >= 0:
		if current < _displayed_health:
			var lost_index := clampi(current, 0, _heart_slots.size() - 1)
			if lost_index < _heart_slots.size():
				_heart_slots[lost_index].pulse_damage()
			AudioManager.reproduce_sfx("hurt", 0.08)
		elif current > _displayed_health:
			var gained_index := clampi(current - 1, 0, _heart_slots.size() - 1)
			if gained_index < _heart_slots.size():
				_heart_slots[gained_index].pulse_heal()
			AudioManager.reproduce_sfx("heal", 0.06)

	_displayed_health = current


func _sync_souls(current: float, maximum: float, animate: bool) -> void:
	soul_bar.max_value = maximum
	soul_label.text = "%d" % int(current)

	if _soul_tween != null and _soul_tween.is_valid():
		_soul_tween.kill()

	if animate and _displayed_souls >= 0.0:
		_soul_tween = create_tween()
		_soul_tween.tween_method(
			func(v: float) -> void:
				soul_bar.value = v
				_update_soul_bar_color(v / maximum if maximum > 0.0 else 0.0),
			_displayed_souls,
			current,
			0.25,
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		soul_bar.value = current
		_update_soul_bar_color(current / maximum if maximum > 0.0 else 0.0)

	_displayed_souls = current


func _setup_soul_bar_style() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.1, 0.16, 0.9)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.4, 0.65, 1.0, 1.0)
	fill.set_corner_radius_all(2)
	soul_bar.add_theme_stylebox_override(&"background", bg)
	soul_bar.add_theme_stylebox_override(&"fill", fill)


func _update_soul_bar_color(ratio: float) -> void:
	var t := clampf(ratio, 0.0, 1.0)
	var col := Color(0.35, 0.55, 0.95).lerp(Color(0.55, 0.82, 1.0), t)
	var fill := soul_bar.get_theme_stylebox(&"fill") as StyleBoxFlat
	if fill != null:
		fill.bg_color = col
