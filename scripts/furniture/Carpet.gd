class_name Carpet
extends Furniture

const _SPRITE_W := 128.0
const _SPRITE_H := 42.0

func _apply_variant() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	sprite.region_rect = Rect2((variant % 2) * _SPRITE_W, (variant / 2) * _SPRITE_H, _SPRITE_W, _SPRITE_H)

func _init_hotspots() -> void:
	var sit := FurnitureHotspot.new()
	sit.action = FurnitureHotspot.ActionType.SIT
	sit.slots = [Vector2(0, 0)]

	var lay := FurnitureHotspot.new()
	lay.action = FurnitureHotspot.ActionType.LAY
	lay.slots = [Vector2(-32, 0), Vector2(32, 0)]

	var sniff := FurnitureHotspot.new()
	sniff.action = FurnitureHotspot.ActionType.SNIFF
	sniff.slots = [Vector2(48, 10)]

	_hotspots = [sit, lay, sniff]

func get_footprint_rect() -> Rect2:
	return Rect2(global_position - Vector2(_SPRITE_W / 2.0, _SPRITE_H / 2.0), Vector2(_SPRITE_W, _SPRITE_H))
