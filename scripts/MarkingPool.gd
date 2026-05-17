extends Resource
class_name MarkingPool

const _MARKINGS: Array[String] = [
	"res://assets/sprites/cats/Markings/Tabby Markings 000.png",
	"res://assets/sprites/cats/Markings/Feet 000.png",
	"res://assets/sprites/cats/Markings/Tail 000.png",
	"res://assets/sprites/cats/Markings/Face Marking 000.png",
	"res://assets/sprites/cats/Markings/Ears 000.png",
	"res://assets/sprites/cats/Markings/Left Ear 000.png",
	"res://assets/sprites/cats/Markings/Right Ear 000.png",
	"res://assets/sprites/cats/Markings/Front Left Foot 000.png",
	"res://assets/sprites/cats/Markings/Front Left Foot 001.png",
	"res://assets/sprites/cats/Markings/Front Right Foot 000.png",
	"res://assets/sprites/cats/Markings/Back Left Foot 000.png",
	"res://assets/sprites/cats/Markings/Back Left Foot 001.png",
	"res://assets/sprites/cats/Markings/Back Right Foot 000.png",
	"res://assets/sprites/cats/Markings/Back Right Foot 001.png",
]

const _LABELS: Dictionary = {
	"res://assets/sprites/cats/Markings/Tabby Markings 000.png": "Tabby",
	"res://assets/sprites/cats/Markings/Feet 000.png":           "White Paws",
	"res://assets/sprites/cats/Markings/Tail 000.png":           "Tail Tip",
	"res://assets/sprites/cats/Markings/Face Marking 000.png":   "Face Mark",
	"res://assets/sprites/cats/Markings/Ears 000.png":           "Ears",
	"res://assets/sprites/cats/Markings/Left Ear 000.png":       "Left Ear",
	"res://assets/sprites/cats/Markings/Right Ear 000.png":      "Right Ear",
	"res://assets/sprites/cats/Markings/Front Left Foot 000.png":  "FL Foot 0",
	"res://assets/sprites/cats/Markings/Front Left Foot 001.png":  "FL Foot 1",
	"res://assets/sprites/cats/Markings/Front Right Foot 000.png": "FR Foot 0",
	"res://assets/sprites/cats/Markings/Back Left Foot 000.png":   "BL Foot 0",
	"res://assets/sprites/cats/Markings/Back Left Foot 001.png":   "BL Foot 1",
	"res://assets/sprites/cats/Markings/Back Right Foot 000.png":  "BR Foot 0",
	"res://assets/sprites/cats/Markings/Back Right Foot 001.png":  "BR Foot 1",
}

var _enabled: Dictionary = {}

static func build_default() -> MarkingPool:
	var pool := MarkingPool.new()
	for path: String in _MARKINGS:
		pool._enabled[path] = true
	return pool

func get_all() -> Array[String]:
	return _MARKINGS.duplicate()

func get_label(path: String) -> String:
	return _LABELS.get(path, path.get_file().get_basename())

func set_enabled(path: String, on: bool) -> void:
	_enabled[path] = on

func is_enabled(path: String) -> bool:
	return _enabled.get(path, false)

func set_all_enabled(on: bool) -> void:
	for path: String in _MARKINGS:
		_enabled[path] = on

func pick_random(rng: RandomNumberGenerator, probability: float) -> Texture2D:
	if rng.randf() >= probability:
		return null
	var enabled: Array[String] = []
	for path: String in _MARKINGS:
		if _enabled.get(path, false):
			enabled.append(path)
	if enabled.is_empty():
		return null
	return load(enabled[rng.randi() % enabled.size()])
