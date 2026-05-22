class_name SofaSmall
extends Furniture

func _apply_variant() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	sprite.region_rect = Rect2(0, variant * 32, 32, 32)

func _init_hotspots() -> void:
	var sit := FurnitureHotspot.new()
	sit.action = FurnitureHotspot.ActionType.SIT
	sit.slots = [Vector2(0, 0)]

	_hotspots = [sit]
