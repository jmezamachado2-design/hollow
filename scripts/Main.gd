extends Node2D
## Raíz del juego: jugador persistente y contenedor de salas.

const START_ROOM := "res://scenes/levels/Room_A.tscn"
const START_ENTRY := "default"
const GAME_UI_SCENE := preload("res://scenes/ui/GameUI.tscn")

@onready var room_container: Node2D = $RoomContainer
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	add_child(GAME_UI_SCENE.instantiate())
	GameManager.setup_main(self, room_container, player)
	GameManager.load_initial_room(START_ROOM, START_ENTRY)
