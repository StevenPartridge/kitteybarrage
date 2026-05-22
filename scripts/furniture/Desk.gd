class_name Desk
extends Furniture

func _apply_variant() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	sprite.region_rect = Rect2(0, variant * 32, 64, 32)

func _init_hotspots() -> void:
	var sniff := FurnitureHotspot.new()
	sniff.action = FurnitureHotspot.ActionType.SNIFF
	sniff.slots = [Vector2(0, 14)]

	var knock := FurnitureHotspot.new()
	knock.action = FurnitureHotspot.ActionType.KNOCK
	knock.slots = [Vector2(16, -4)]

	_hotspots = [sniff, knock]
