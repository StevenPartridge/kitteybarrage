class_name TableRound
extends Furniture

func _apply_variant() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	sprite.region_rect = Rect2((variant % 3) * 16, (variant / 3) * 32, 16, 32)

func _init_hotspots() -> void:
	var sniff := FurnitureHotspot.new()
	sniff.action = FurnitureHotspot.ActionType.SNIFF
	sniff.slots = [Vector2(10, 8)]

	var knock := FurnitureHotspot.new()
	knock.action = FurnitureHotspot.ActionType.KNOCK
	knock.slots = [Vector2(0, -4)]

	_hotspots = [sniff, knock]
