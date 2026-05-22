class_name FurnitureWindow
extends Furniture

func _apply_variant() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	sprite.region_rect = Rect2((variant % 4) * 32, (variant / 4) * 64, 32, 64)

func _init_hotspots() -> void:
	var sit := FurnitureHotspot.new()
	sit.action = FurnitureHotspot.ActionType.SIT
	sit.slots = [Vector2(0, 24)]

	var lay := FurnitureHotspot.new()
	lay.action = FurnitureHotspot.ActionType.LAY
	lay.slots = [Vector2(0, 24)]

	_hotspots = [sit, lay]
