class_name Bookcase
extends Furniture

func _apply_variant() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	sprite.region_rect = Rect2(variant * 32, 0, 32, 64)

func _init_hotspots() -> void:
	var sniff := FurnitureHotspot.new()
	sniff.action = FurnitureHotspot.ActionType.SNIFF
	sniff.slots = [Vector2(0, 24)]

	var knock := FurnitureHotspot.new()
	knock.action = FurnitureHotspot.ActionType.KNOCK
	knock.slots = [Vector2(0, 0)]

	_hotspots = [sniff, knock]
