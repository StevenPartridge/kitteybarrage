extends Resource
class_name ColorVariantPool

const _KITTY_FAMILIES: Dictionary = {
	"black":            ["res://assets/sprites/cats/black_0.png",
	                     "res://assets/sprites/cats/black_1.png",
	                     "res://assets/sprites/cats/black_2.png",
	                     "res://assets/sprites/cats/black_3.png",
	                     "res://assets/sprites/cats/black_4.png"],
	"blue":             ["res://assets/sprites/cats/blue_0.png",
	                     "res://assets/sprites/cats/blue_1.png",
	                     "res://assets/sprites/cats/blue_2.png",
	                     "res://assets/sprites/cats/blue_3.png"],
	"brown":            ["res://assets/sprites/cats/brown_0.png",
	                     "res://assets/sprites/cats/brown_1.png",
	                     "res://assets/sprites/cats/brown_2.png",
	                     "res://assets/sprites/cats/brown_3.png",
	                     "res://assets/sprites/cats/brown_4.png",
	                     "res://assets/sprites/cats/brown_5.png",
	                     "res://assets/sprites/cats/brown_6.png",
	                     "res://assets/sprites/cats/brown_7.png",
	                     "res://assets/sprites/cats/brown_8.png"],
	"calico":           ["res://assets/sprites/cats/calico_0.png"],
	"cotton_candy_blue":["res://assets/sprites/cats/cotton_candy_blue_0.png"],
	"cotton_candy_pink":["res://assets/sprites/cats/cotton_candy_pink_0.png"],
	"creme":            ["res://assets/sprites/cats/creme_0.png",
	                     "res://assets/sprites/cats/creme_1.png"],
	"dark":             ["res://assets/sprites/cats/dark_0.png"],
	"game_boy":         ["res://assets/sprites/cats/game_boy_0.png",
	                     "res://assets/sprites/cats/game_boy_1.png",
	                     "res://assets/sprites/cats/game_boy_2.png"],
	"ghost":            ["res://assets/sprites/cats/ghost_0.png"],
	"gold":             ["res://assets/sprites/cats/gold_0.png"],
	"grey":             ["res://assets/sprites/cats/grey_0.png",
	                     "res://assets/sprites/cats/grey_1.png",
	                     "res://assets/sprites/cats/grey_2.png"],
	"hairless":         ["res://assets/sprites/cats/hairless_0.png",
	                     "res://assets/sprites/cats/hairless_1.png"],
	"indigo":           ["res://assets/sprites/cats/indigo_0.png"],
	"orange":           ["res://assets/sprites/cats/orange_0.png",
	                     "res://assets/sprites/cats/orange_1.png",
	                     "res://assets/sprites/cats/orange_2.png",
	                     "res://assets/sprites/cats/orange_3.png"],
	"peach":            ["res://assets/sprites/cats/peach_0.png"],
	"pink":             ["res://assets/sprites/cats/pink_0.png"],
	"radioactive":      ["res://assets/sprites/cats/radioactive_0.png"],
	"red":              ["res://assets/sprites/cats/red_0.png",
	                     "res://assets/sprites/cats/red_1.png"],
	"seal_point":       ["res://assets/sprites/cats/seal_point_0.png"],
	"teal":             ["res://assets/sprites/cats/teal_0.png"],
	"white":            ["res://assets/sprites/cats/white_0.png"],
	"white_grey":       ["res://assets/sprites/cats/white_grey_0.png",
	                     "res://assets/sprites/cats/white_grey_1.png"],
	"yellow":           ["res://assets/sprites/cats/yellow_0.png"],
}

var _families: Dictionary = {}
var _enabled: Dictionary = {}

static func build_kitty_pool() -> ColorVariantPool:
	var pool := ColorVariantPool.new()
	for family: String in _KITTY_FAMILIES:
		pool._families[family] = _KITTY_FAMILIES[family].duplicate()
		pool._enabled[family] = true
	return pool

func get_families() -> Array:
	var keys := _families.keys()
	keys.sort()
	return keys

func set_enabled(family: String, on: bool) -> void:
	_enabled[family] = on

func is_enabled(family: String) -> bool:
	return _enabled.get(family, false)

func set_all_enabled(on: bool) -> void:
	for family: String in _families:
		_enabled[family] = on

func pick_random(rng: RandomNumberGenerator) -> Texture2D:
	var paths: Array = []
	for family: String in _families:
		if _enabled.get(family, false):
			paths.append_array(_families[family])
	if paths.is_empty():
		return null
	return load(paths[rng.randi() % paths.size()])
