class_name CameraShake
extends Camera2D
## Sacudida de cámara con FastNoiseLite; la intensidad decae con el tiempo.

var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_time_left: float = 0.0
var _noise: FastNoiseLite
var _rest_offset: Vector2 = Vector2.ZERO
var _noise_seed: float = 0.0


func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 0.15
	_rest_offset = offset


func _process(delta: float) -> void:
	if _shake_time_left <= 0.0:
		offset = _rest_offset
		return

	_shake_time_left -= delta
	_noise_seed += delta * 24.0

	var falloff := _shake_time_left / _shake_duration if _shake_duration > 0.0 else 0.0
	var amount := _shake_intensity * falloff

	offset = _rest_offset + Vector2(
		_noise.get_noise_1d(_noise_seed) * amount,
		_noise.get_noise_1d(_noise_seed + 42.0) * amount,
	)


## intensity: desplazamiento máximo en píxeles. duration: duración en segundos.
func shake(intensity: float, duration: float) -> void:
	if duration <= 0.0:
		return
	_shake_intensity = intensity
	_shake_duration = duration
	_shake_time_left = duration
