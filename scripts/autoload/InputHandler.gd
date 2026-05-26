extends Node
## Autoload central de entrada estilo Hollow Knight.
## El InputMap se registra en código (_register_input_map) al iniciar el singleton.

# =============================================================================
# REGISTRO DEL INPUTMAP (se ejecuta en _init antes que otros autoloads)
# =============================================================================
#
# move_left  → ← únicamente (A reservada para dream_nail)
# move_right → → y D
# move_up    → ↑ y W
# move_down  → ↓ y S
# jump       → Espacio
# attack     → C y clic izquierdo
# focus_spell→ X y clic derecho (held)
# dash       → Z y Shift
# dream_nail → A
# inventory  → Tab
# pause      → Escape (menú)
# interact   → E (checkpoint)

const JUMP_BUFFER_TIME := 0.1

var _jump_buffer_timer: float = 0.0


func _init() -> void:
	_register_input_map()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	elif _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta


# --- API pública ---

func get_move_direction() -> Vector2:
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down"),
	)
	if dir.length_squared() > 1.0:
		return dir.normalized()
	return dir


func is_jump_just_pressed() -> bool:
	if Input.is_action_just_pressed("jump"):
		return true
	return _jump_buffer_timer > 0.0


func consume_jump_buffer() -> void:
	_jump_buffer_timer = 0.0


func is_attack_just_pressed() -> bool:
	return Input.is_action_just_pressed("attack")


func is_focus_held() -> bool:
	return Input.is_action_pressed("focus_spell")


func is_dash_just_pressed() -> bool:
	return Input.is_action_just_pressed("dash")


func is_dream_nail_just_pressed() -> bool:
	return Input.is_action_just_pressed("dream_nail")


func is_inventory_just_pressed() -> bool:
	return Input.is_action_just_pressed("inventory")


func is_interact_just_pressed() -> bool:
	return Input.is_action_just_pressed("interact")


func is_pause_just_pressed() -> bool:
	return Input.is_action_just_pressed("pause")


# =============================================================================
# _register_input_map — definición de acciones y eventos
# =============================================================================

static func _register_input_map() -> void:
	_ensure_action("move_left", [
		_key_keycode(KEY_LEFT),
	])
	_ensure_action("move_right", [
		_key_keycode(KEY_RIGHT),
		_key_keycode(KEY_D),
	])
	_ensure_action("move_up", [
		_key_keycode(KEY_UP),
		_key_keycode(KEY_W),
	])
	_ensure_action("move_down", [
		_key_keycode(KEY_DOWN),
		_key_keycode(KEY_S),
	])
	_ensure_action("jump", [
		_key_keycode(KEY_SPACE),
	])
	_ensure_action("attack", [
		_key_keycode(KEY_C),
		_mouse_button(MOUSE_BUTTON_LEFT),
	])
	_ensure_action("focus_spell", [
		_key_keycode(KEY_X),
		_mouse_button(MOUSE_BUTTON_RIGHT),
	])
	_ensure_action("dash", [
		_key_keycode(KEY_Z),
		_key_keycode(KEY_SHIFT),
	])
	_ensure_action("dream_nail", [
		_key_keycode(KEY_A),
	])
	_ensure_action("inventory", [
		_key_keycode(KEY_TAB),
	])
	_ensure_action("pause", [
		_key_keycode(KEY_ESCAPE),
	])
	_ensure_action("interact", [
		_key_keycode(KEY_E),
	])


static func _ensure_action(action_name: String, events: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.5)
	else:
		var existing := InputMap.action_get_events(action_name)
		for ev in existing:
			InputMap.action_erase_event(action_name, ev)
	for ev in events:
		InputMap.action_add_event(action_name, ev)


static func _key_keycode(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	return event


static func _mouse_button(button_index: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	return event
