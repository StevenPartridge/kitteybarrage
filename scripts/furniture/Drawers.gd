class_name Drawers
extends Furniture

func _apply_variant() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	sprite.region_rect = Rect2((variant % 2) * 32, (variant / 2) * 32, 32, 32)

func _init_hotspots() -> void:
	var sniff := FurnitureHotspot.new()
	sniff.action = FurnitureHotspot.ActionType.SNIFF
	sniff.slots = [Vector2(0, 14)]

	_hotspots = [sniff]
