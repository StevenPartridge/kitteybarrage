class_name Plant
extends Furniture

func _apply_variant() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	sprite.region_rect = Rect2(variant * 16, 0, 16, 64)

func _init_hotspots() -> void:
	var sniff := FurnitureHotspot.new()
	sniff.action = FurnitureHotspot.ActionType.SNIFF
	sniff.slots = [Vector2(10, 16)]

	_hotspots = [sniff]
