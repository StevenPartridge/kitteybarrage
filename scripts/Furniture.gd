class_name Furniture
extends Node2D

static var debug_hotspots: bool = false

# Integer keys because GDScript const dicts can't reliably reference external class enums at parse time.
# Order matches FurnitureHotspot.ActionType: SIT=0, LAY=1, SNIFF=2, KNOCK=3
const _HS_COLORS: Dictionary = {
	0: Color(1.0, 0.85, 0.1),
	1: Color(0.9, 0.4,  0.8),
	2: Color(0.3, 0.9,  0.3),
	3: Color(0.9, 0.3,  0.3),
}

@export var variant: int = 0

var _hotspots: Array[FurnitureHotspot] = []

func _ready() -> void:
	_apply_variant()
	_init_hotspots()
	_sync_collision_to_sprite()

func _process(_delta: float) -> void:
	if debug_hotspots:
		queue_redraw()

func _draw() -> void:
	if not debug_hotspots:
		return
	for hs: FurnitureHotspot in _hotspots:
		var color: Color = _HS_COLORS.get(int(hs.action), Color.WHITE)
		for i in hs.slots.size():
			var pos: Vector2 = hs.slots[i]
			if hs.knocked:
				draw_line(pos + Vector2(-3, -3), pos + Vector2(3,  3), Color.RED, 1.5)
				draw_line(pos + Vector2(-3,  3), pos + Vector2(3, -3), Color.RED, 1.5)
			elif hs.is_slot_claimed(i):
				draw_circle(pos, 4.0, color * Color(0.35, 0.35, 0.35))
			else:
				draw_circle(pos, 4.0, color)

func _apply_variant() -> void:
	pass

func _init_hotspots() -> void:
	pass

func _sync_collision_to_sprite() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null or sprite.texture == null:
		return
	var body := get_node_or_null("StaticBody2D") as StaticBody2D
	if body == null:
		return
	var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var size: Vector2
	if sprite.region_enabled and sprite.region_rect.size != Vector2.ZERO:
		size = sprite.region_rect.size
	else:
		size = Vector2(sprite.texture.get_width(), sprite.texture.get_height())
	var rect_shape := shape_node.shape as RectangleShape2D
	if rect_shape == null:
		return
	rect_shape.size = size

func get_hotspots() -> Array[FurnitureHotspot]:
	return _hotspots

func get_footprint_rect() -> Rect2:
	return Rect2()
