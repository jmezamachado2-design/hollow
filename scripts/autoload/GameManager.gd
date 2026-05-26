extends Node
## Estado global: salud, transiciones de sala, fade, checkpoint y respawn.

signal health_changed(current: int, maximum: int)
signal souls_changed(current: float, maximum: float)
signal player_died
signal game_paused(is_paused: bool)
signal room_changed(room_path: String)
signal checkpoint_saved

const MAX_HEALTH_DEFAULT := 5
const MAX_SOUL_DEFAULT := 99.0
const SOUL_PER_HIT := 11.0
const FADE_DURATION := 0.35

var max_health: int = MAX_HEALTH_DEFAULT
var current_health: int = MAX_HEALTH_DEFAULT
var max_souls: float = MAX_SOUL_DEFAULT
var current_souls: float = 0.0
var is_paused: bool = false

var player: CharacterBody2D
var _main: Node2D
var _room_container: Node
var current_room: Room
var current_room_path: String = ""

var is_transitioning: bool = false

# Checkpoint persistente
var has_checkpoint: bool = false
var checkpoint_room_path: String = ""
var checkpoint_entry_id: String = "default"
var checkpoint_health: int = MAX_HEALTH_DEFAULT

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_health()
	_setup_fade_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if InputHandler.is_pause_just_pressed() and not is_transitioning:
		toggle_pause()


# --- Inicialización (llamado desde Main.gd) ---

func setup_main(main: Node2D, room_container: Node, player_node: CharacterBody2D) -> void:
	_main = main
	_room_container = room_container
	player = player_node
	player_died.connect(_on_player_died)


func load_initial_room(room_path: String, entry_id: String) -> void:
	current_room_path = room_path
	if _fade_rect != null:
		_fade_rect.modulate.a = 1.0
	_load_room_scene(room_path)
	_place_player_at_entry(entry_id)
	_apply_room_camera_limits()
	room_changed.emit(room_path)
	await _fade_in(0.5)


# --- Salud ---

func reset_health() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func reset_souls() -> void:
	current_souls = 0.0
	souls_changed.emit(current_souls, max_souls)


func add_souls(amount: float) -> void:
	if amount <= 0.0:
		return
	var previous := current_souls
	current_souls = minf(max_souls, current_souls + amount)
	if not is_equal_approx(previous, current_souls):
		souls_changed.emit(current_souls, max_souls)


func take_damage(amount: int = 1) -> void:
	if amount <= 0 or current_health <= 0:
		return
	current_health = maxi(0, current_health - amount)
	_sync_player_health()
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		player_died.emit()


func heal(amount: int = 1) -> void:
	if amount <= 0:
		return
	current_health = mini(max_health, current_health + amount)
	_sync_player_health()
	health_changed.emit(current_health, max_health)


func is_alive() -> bool:
	return current_health > 0


func toggle_pause() -> void:
	if is_transitioning:
		return
	is_paused = not is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)
	if is_paused:
		AudioManager.reproduce_sfx("ui", 0.05)


func restart_game() -> void:
	get_tree().paused = false
	is_paused = false
	is_transitioning = false
	game_paused.emit(false)
	get_tree().reload_current_scene()


func quit_game() -> void:
	get_tree().quit()


func _sync_player_health() -> void:
	if player == null:
		return
	var hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if hc != null:
		hc.current_health = current_health
		hc.max_health = max_health


# --- Transición de sala ---

func transition_to_room(target_room_path: String, target_entry_id: String) -> void:
	if is_transitioning or target_room_path.is_empty():
		return
	is_transitioning = true
	get_tree().paused = false
	is_paused = false

	await _fade_out()
	_load_room_scene(target_room_path)
	_place_player_at_entry(target_entry_id)
	_apply_room_camera_limits()
	await _fade_in()

	is_transitioning = false
	room_changed.emit(target_room_path)


func register_current_room(room: Room) -> void:
	current_room = room
	if not room.room_scene_path.is_empty():
		current_room_path = room.room_scene_path


# --- Checkpoint ---

func save_checkpoint(room_path: String, entry_id: String, health: int) -> void:
	checkpoint_room_path = room_path
	checkpoint_entry_id = entry_id
	checkpoint_health = clampi(health, 1, max_health)
	has_checkpoint = true
	checkpoint_saved.emit()


func get_current_room_path() -> String:
	if current_room != null and not current_room.room_scene_path.is_empty():
		return current_room.room_scene_path
	return current_room_path


# --- Muerte y respawn ---

func _on_player_died() -> void:
	await handle_player_death()


func kill_player_from_hazard() -> void:
	if player == null or is_transitioning:
		return
	current_health = 0
	_sync_player_health()
	player.set_physics_process(false)
	player_died.emit()


func handle_player_death() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	get_tree().paused = false

	if player != null:
		player.set_physics_process(false)

	await _fade_out(0.28)

	if has_checkpoint:
		if current_room_path != checkpoint_room_path:
			_load_room_scene(checkpoint_room_path)
		_place_player_at_entry(checkpoint_entry_id)
		_apply_room_camera_limits()
		_revive_player(checkpoint_health)
	else:
		if current_room != null:
			_place_player_at_entry(current_room.default_entry_id)
		_revive_player(max_health)

	reset_souls()
	await _fade_in(0.35)
	is_transitioning = false


func _revive_player(health_amount: int) -> void:
	current_health = clampi(health_amount, 1, max_health)
	_sync_player_health()
	if player == null:
		return
	player.velocity = Vector2.ZERO
	if player.has_method("on_respawn"):
		player.on_respawn()
	player.set_physics_process(true)
	health_changed.emit(current_health, max_health)


# --- Carga de salas ---

func _load_room_scene(room_path: String) -> void:
	if _room_container == null:
		return

	for child in _room_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	var packed: PackedScene = load(room_path) as PackedScene
	if packed == null:
		push_error("No se pudo cargar la sala: %s" % room_path)
		return

	current_room = packed.instantiate() as Room
	if current_room == null:
		push_error("La escena no usa Room.gd: %s" % room_path)
		return

	_room_container.add_child(current_room)
	current_room_path = room_path
	if current_room.room_scene_path.is_empty():
		current_room.room_scene_path = room_path


func _place_player_at_entry(entry_id: String) -> void:
	if player == null or current_room == null:
		return
	var entry: Node2D = current_room.get_entry_point(entry_id)
	if entry == null:
		push_warning("Entry Point '%s' no encontrado en %s" % [entry_id, current_room.name])
		entry = current_room.get_entry_point(current_room.default_entry_id)
	if entry != null:
		player.global_position = entry.global_position


func _apply_room_camera_limits() -> void:
	if player == null or current_room == null:
		return
	var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		current_room.apply_camera_limits(cam)


# --- Fade (CanvasLayer) ---

func _setup_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	_fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_layer.add_child(_fade_rect)


func _fade_out(duration: float = FADE_DURATION) -> void:
	await _fade_to(1.0, duration)


func _fade_in(duration: float = FADE_DURATION) -> void:
	await _fade_to(0.0, duration)


func _fade_to(target_alpha: float, duration: float) -> void:
	if _fade_rect == null:
		return
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", target_alpha, duration)
	await tween.finished
