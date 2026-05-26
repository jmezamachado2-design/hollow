class_name CameraLimit
extends Node2D
## Límites de cámara para la sala actual (se aplican al Camera2D del jugador).

@export var limit_left: int = 0
@export var limit_top: int = 0
@export var limit_right: int = 320
@export var limit_bottom: int = 180
@export var limit_smoothed: bool = true


func apply_to_camera(camera: Camera2D) -> void:
	camera.limit_left = limit_left
	camera.limit_top = limit_top
	camera.limit_right = limit_right
	camera.limit_bottom = limit_bottom
	camera.limit_smoothed = limit_smoothed
