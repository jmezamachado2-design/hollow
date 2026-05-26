extends CanvasLayer
## Menú de pausa sobre todo el juego.

@onready var panel: PanelContainer = $Dim/Panel
@onready var btn_continue: Button = $Dim/Panel/VBox/BtnContinue
@onready var btn_restart: Button = $Dim/Panel/VBox/BtnRestart
@onready var btn_quit: Button = $Dim/Panel/VBox/BtnQuit


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	btn_continue.pressed.connect(_on_continue)
	btn_restart.pressed.connect(_on_restart)
	btn_quit.pressed.connect(_on_quit)

	GameManager.game_paused.connect(_on_game_paused)


func _on_game_paused(paused: bool) -> void:
	visible = paused
	if paused:
		panel.modulate.a = 0.0
		panel.scale = Vector2(0.92, 0.92)
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(panel, "modulate:a", 1.0, 0.18)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
		btn_continue.grab_focus()


func _on_continue() -> void:
	if GameManager.is_paused:
		GameManager.toggle_pause()


func _on_restart() -> void:
	GameManager.restart_game()


func _on_quit() -> void:
	GameManager.quit_game()
