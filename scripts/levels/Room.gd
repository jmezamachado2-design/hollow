class_name Room
extends Node2D
## Escena base de sala metroidvania: TileMap, límites, entradas y transiciones.

@export var room_scene_path: String = ""
@export var room_display_name: String = "Room"
@export var default_entry_id: String = "default"
@export var music_track: String = "room_explore"

@onready var tile_map: TileMap = $TileMap
@onready var camera_limit: CameraLimit = $CameraLimit
@onready var entry_points: Node2D = $EntryPoints
@onready var transitions: Node2D = $Transitions
@onready var entities: Node2D = $Entities


func _ready() -> void:
	if room_scene_path.is_empty():
		room_scene_path = scene_file_path
	GameManager.register_current_room(self)
	if not music_track.is_empty():
		AudioManager.reproduce_musica(music_track, 1.0)


func get_entry_point(entry_id: String) -> Node2D:
	if entry_points == null:
		return null
	var node := entry_points.get_node_or_null(entry_id) as Node2D
	if node != null:
		return node
	return entry_points.get_node_or_null(default_entry_id) as Node2D


func apply_camera_limits(camera: Camera2D) -> void:
	if camera_limit != null:
		camera_limit.apply_to_camera(camera)
