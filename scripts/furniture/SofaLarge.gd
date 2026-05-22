class_name SofaLarge
extends Furniture

func _apply_variant() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	sprite.region_rect = Rect2(0, variant * 32, 64, 32)

func _init_hotspots() -> void:
	var sit := FurnitureHotspot.new()
	sit.action = FurnitureHotspot.ActionType.SIT
	sit.slots = [Vector2(-20, 0), Vector2(0, 0), Vector2(20, 0)]

	var lay := FurnitureHotspot.new()
	lay.action = FurnitureHotspot.ActionType.LAY
	lay.slots = [Vector2(0, 0)]

	_hotspots = [sit, lay]
