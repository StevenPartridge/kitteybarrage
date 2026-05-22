class_name Bed
extends Furniture

@export var sprite_w: int = 44
@export var sprite_h: int = 60
@export var columns: int = 2

func _apply_variant() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	sprite.region_rect = Rect2((variant % columns) * sprite_w, (variant / columns) * sprite_h, sprite_w, sprite_h)

func _init_hotspots() -> void:
	var sit := FurnitureHotspot.new()
	sit.action = FurnitureHotspot.ActionType.SIT
	sit.slots = [Vector2(-8, 0), Vector2(0, 0), Vector2(8, 0)]

	var lay := FurnitureHotspot.new()
	lay.action = FurnitureHotspot.ActionType.LAY
	lay.slots = [Vector2(0, -16), Vector2(0, 10)]

	_hotspots = [sit, lay]
