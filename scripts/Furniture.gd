class_name Furniture
extends Node2D

static var debug_hotspots: bool = false

# Integer keys because GDScript const dicts can't reliably reference external class enums at parse time.
# Order matches FurnitureHotspot.ActionType: SIT=0, LAY=1, SNIFF=2, KNOCK=3.
const _HS_COLORS: Dictionary = {
	0: Color(1.0, 0.85, 0.1),
	1: Color(0.9, 0.4,  0.8),
	2: Color(0.3, 0.9,  0.3),
	3: Color(0.9, 0.3,  0.3),
}

@export var variant: int = 0
@export var definition: FurnitureDefinition
@export var apply_definition_sprite_region: bool = false
@export var auto_sync_collision_to_sprite: bool = true
@export var apply_y_sort_pivot_from_marker: bool = true
@export var y_sort_pivot_marker_path: NodePath = ^"YSortOrigin"
@export var surface_mount_enabled: bool = false
@export var mounted_character_z_index: int = 1

var _hotspots: Array[FurnitureHotspot] = []
var _y_sort_pivot_offset := Vector2.ZERO

func _ready() -> void:
	if apply_definition_sprite_region and definition != null:
		_apply_variant()
	_apply_y_sort_pivot_from_marker()
	_init_hotspots()
	_sync_collision_to_sprite()

func _process(_delta: float) -> void:
	if debug_hotspots:
		queue_redraw()

func _draw() -> void:
	if not debug_hotspots:
		return
	_draw_y_sort_pivot_debug()
	for hs: FurnitureHotspot in _hotspots:
		var color: Color = _HS_COLORS.get(hs.get_default_action(), Color.WHITE)
		for i in hs.slots.size():
			var pos: Vector2 = hs.slots[i]
			if hs.knocked:
				draw_line(pos + Vector2(-3, -3), pos + Vector2(3,  3), Color.RED, 1.5)
				draw_line(pos + Vector2(-3,  3), pos + Vector2(3, -3), Color.RED, 1.5)
			elif hs.is_slot_claimed(i):
				draw_circle(pos, 4.0, color * Color(0.35, 0.35, 0.35))
			else:
				draw_circle(pos, 4.0, color)
			if uses_surface_mount_rendering() and hs.has_approach_slot(i):
				var approach_pos := hs.get_approach_slot(i)
				draw_line(approach_pos, pos, Color(color.r, color.g, color.b, 0.45), 1.0)
				draw_circle(approach_pos, 2.0, Color(color.r, color.g, color.b, 0.65))

func _apply_variant() -> void:
	if definition == null:
		return
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null or sprite.texture == null:
		return
	sprite.region_enabled = true
	if definition.columns == 0:
		sprite.region_rect = Rect2(variant * definition.sprite_w, 0, definition.sprite_w, definition.sprite_h)
	else:
		sprite.region_rect = Rect2(
			(variant % definition.columns) * definition.sprite_w,
			floori(float(variant) / float(definition.columns)) * definition.sprite_h,
			definition.sprite_w,
			definition.sprite_h
		)

func _apply_y_sort_pivot_from_marker() -> void:
	if not apply_y_sort_pivot_from_marker:
		return
	var marker := get_node_or_null(y_sort_pivot_marker_path) as Node2D
	if marker == null:
		return
	var pivot_offset := to_local(marker.global_position)
	if pivot_offset.is_zero_approx():
		return
	_y_sort_pivot_offset = pivot_offset
	global_position = marker.global_position
	for child_raw in get_children():
		var child := child_raw as Node2D
		if child != null:
			child.position -= pivot_offset

func _draw_y_sort_pivot_debug() -> void:
	var marker := get_node_or_null(y_sort_pivot_marker_path) as Node2D
	if marker == null:
		return
	var y := to_local(marker.global_position).y
	draw_line(Vector2(-10, y), Vector2(10, y), Color(0.2, 0.75, 1.0, 0.9), 1.0)
	draw_line(Vector2(0, y - 3), Vector2(0, y + 3), Color(0.2, 0.75, 1.0, 0.9), 1.0)

func _init_hotspots() -> void:
	_hotspots.clear()
	if _init_hotspots_from_markers():
		return
	if definition == null:
		return
	for spec: HotspotSpec in definition.hotspot_specs:
		var hs := FurnitureHotspot.new()
		hs.action = spec.get_default_action()
		hs.set_actions(spec.get_actions())
		hs.slots = spec.slots.duplicate()
		hs.approach_slots = spec.approach_slots.duplicate()
		hs.dismount_slots = spec.dismount_slots.duplicate()
		hs.source_furniture = self
		_hotspots.append(hs)

func _init_hotspots_from_markers() -> bool:
	var root := get_node_or_null("Hotspots") as Node2D
	if root == null:
		return false
	var found := false
	for action_node_raw in root.get_children():
		var action_node := action_node_raw as Node2D
		if action_node == null:
			continue
		var actions := _actions_from_marker_name(action_node.name)
		if actions.is_empty():
			continue
		var hs := FurnitureHotspot.new()
		hs.set_actions(actions)
		for slot_raw in action_node.get_children():
			var slot_marker := slot_raw as Node2D
			if slot_marker == null or not String(slot_marker.name).begins_with("Slot"):
				continue
			var slot_pos := to_local(slot_marker.global_position)
			var approach_pos := _named_marker_position(slot_marker, "Approach", slot_pos)
			hs.slots.append(slot_pos)
			hs.approach_slots.append(approach_pos)
			hs.dismount_slots.append(_named_marker_position(slot_marker, "Dismount", approach_pos))
		if not hs.slots.is_empty():
			hs.source_furniture = self
			_hotspots.append(hs)
			found = true
	return found

func _actions_from_marker_name(action_name: StringName) -> Array[int]:
	var normalized := String(action_name).to_upper()
	for separator in ["+", ",", "|", "/", "-", " "]:
		normalized = normalized.replace(separator, "_")
	var actions: Array[int] = []
	for token in normalized.split("_", false):
		match String(token).strip_edges():
			"SIT":
				_append_unique_action(actions, FurnitureHotspot.ActionType.SIT)
			"LAY":
				_append_unique_action(actions, FurnitureHotspot.ActionType.LAY)
			"SNIFF":
				_append_unique_action(actions, FurnitureHotspot.ActionType.SNIFF)
			"KNOCK":
				_append_unique_action(actions, FurnitureHotspot.ActionType.KNOCK)
	return actions

func _append_unique_action(actions: Array[int], action_type: int) -> void:
	if not actions.has(action_type):
		actions.append(action_type)

func _named_marker_position(parent: Node2D, marker_name: String, fallback: Vector2) -> Vector2:
	for child_raw in parent.get_children():
		var child := child_raw as Node2D
		if child != null and String(child.name).to_lower() == marker_name.to_lower():
			return to_local(child.global_position)
	return fallback

func _sync_collision_to_sprite() -> void:
	if not auto_sync_collision_to_sprite:
		return
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null or sprite.texture == null:
		return
	var body := get_node_or_null("StaticBody2D") as StaticBody2D
	if body == null:
		return
	var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var rect_shape := shape_node.shape as RectangleShape2D
	if rect_shape == null:
		return
	var region_size: Vector2
	if sprite.region_enabled and sprite.region_rect.size != Vector2.ZERO:
		region_size = sprite.region_rect.size
	else:
		region_size = Vector2(sprite.texture.get_width(), sprite.texture.get_height())
	var scaled_size := region_size * sprite.scale
	# Compute the sprite's draw center in this node's local space.
	# centered=true  → center is at sprite.position + sprite.offset
	# centered=false → top-left is at sprite.position + sprite.offset; center adds half size
	var draw_center: Vector2
	if sprite.centered:
		draw_center = sprite.position + sprite.offset
	else:
		draw_center = sprite.position + sprite.offset + scaled_size / 2.0
	body.position = Vector2.ZERO
	shape_node.position = draw_center
	rect_shape.size = scaled_size

func get_hotspots() -> Array[FurnitureHotspot]:
	return _hotspots

func uses_surface_mount_rendering() -> bool:
	return surface_mount_enabled

func get_hotspot_slot_plan(hs: FurnitureHotspot, idx: int) -> Dictionary:
	var occupy_world_pos := to_global(hs.slots[idx])
	var approach_world_pos := to_global(hs.get_approach_slot(idx))
	var dismount_world_pos := to_global(hs.get_dismount_slot(idx))
	var uses_surface_points := uses_surface_mount_rendering() and hs.has_approach_slot(idx)
	return {
		"hotspot": hs,
		"index": idx,
		"uses_surface_points": uses_surface_points,
		"target_world_pos": approach_world_pos if uses_surface_points else occupy_world_pos,
		"approach_world_pos": approach_world_pos,
		"occupy_world_pos": occupy_world_pos,
		"dismount_world_pos": dismount_world_pos,
		"default_action": hs.get_default_action(),
	}

func get_footprint_rect() -> Rect2:
	if definition == null or definition.footprint_size == Vector2.ZERO:
		return Rect2()
	var footprint_center := global_position - _y_sort_pivot_offset
	return Rect2(footprint_center - definition.footprint_size / 2.0, definition.footprint_size)
