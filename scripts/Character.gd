extends CharacterBase
class_name Character

enum PostureGroup { STANDING, SITTING, LYING, TRANSITIONING }

var state_machine: FiniteStateMachine
var _posture_groups: Dictionary
var _transition_table: Dictionary

@export var initial_activity: Global.StateName = Global.StateName.SIT
@export var color_variant: Texture2D

const WALL_PHYSICS_LAYER := 1
const HOTSPOT_CLICK_RADIUS := 14.0
const SURFACE_MOUNT_STATE := preload("res://scripts/kitty_states/SurfaceMountState.gd")
const SURFACE_DISMOUNT_STATE := preload("res://scripts/kitty_states/SurfaceDismountState.gd")
const TIMED_SIT_STATE := preload("res://scripts/kitty_states/TimedSitState.gd")

var current_floor_type: Global.FloorType = Global.FloorType.NONE
var _floor_check_timer: float = 0.0
const _FLOOR_CHECK_INTERVAL := 0.5

var _nearby_furniture: Array[Furniture] = []
var _interest_zone: Area2D = null
var _claimed_hotspot: FurnitureHotspot = null
var _claimed_furniture: Furniture = null
var _floor_layer: TileMapLayer = null
var nav_agent: NavigationAgent2D = null
var _surface_mount_rendering_active := false
var _normal_z_index := 0
var _normal_z_as_relative := true
var _pending_surface_occupy_position := Vector2.INF
var _pending_surface_dismount_position := Vector2.INF
var _hotspot_claim_reserved_for_arrival := false
var _surface_dismount_release_pending := false
var _surface_rng := RandomNumberGenerator.new()

func _ready() -> void:
	state_machine = FiniteStateMachine.new()
	add_child(state_machine)
	var ctrl := AnimationController.new()
	ctrl.setup($AnimatedSprite2D)
	anim = ctrl
	add_child(anim)
	_posture_groups = _build_posture_groups()
	_transition_table = _build_transition_table()
	if color_variant != null:
		_swap_atlas(color_variant)
	_surface_rng.randomize()
	state_machine.change_state(_state_for_activity(initial_activity))
	_interest_zone = get_node_or_null("InterestZone") as Area2D
	if _interest_zone:
		_interest_zone.area_entered.connect(_on_interest_area_entered)
		_interest_zone.area_exited.connect(_on_interest_area_exited)
	_floor_layer = get_tree().get_first_node_in_group("floor_layer") as TileMapLayer
	nav_agent = get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	if nav_agent != null:
		nav_agent.path_desired_distance = 2.0
		nav_agent.target_desired_distance = 2.0

func _build_posture_groups() -> Dictionary:
	return {
		Global.StateName.WALK:    PostureGroup.STANDING,
		Global.StateName.RUN:     PostureGroup.STANDING,
		Global.StateName.SPRINT:  PostureGroup.STANDING,
		Global.StateName.STANDUP: PostureGroup.TRANSITIONING,
		Global.StateName.SITUP:   PostureGroup.TRANSITIONING,
		Global.StateName.SURFACE_MOUNT: PostureGroup.TRANSITIONING,
		Global.StateName.SURFACE_DISMOUNT: PostureGroup.TRANSITIONING,
	}

func _build_transition_table() -> Dictionary:
	return {
		PostureGroup.STANDING: {
			Global.StateName.WALK:        func(): return _surface_dismount_state(MovementState.walk()),
			Global.StateName.RUN:         func(): return _surface_dismount_state(MovementState.run()),
			Global.StateName.SPRINT:      func(): return _surface_dismount_state(MovementState.sprint()),
			Global.StateName.SIT:         func(): return SitState.new(),
			Global.StateName.LAY:         null,
			Global.StateName.LOOK_AROUND: null,
		},
		PostureGroup.TRANSITIONING: {
			Global.StateName.WALK:        null,
			Global.StateName.RUN:         null,
			Global.StateName.SPRINT:      null,
			Global.StateName.SIT:         null,
			Global.StateName.LAY:         null,
			Global.StateName.LOOK_AROUND: null,
		},
	}

# ----------------------------------------------------------------
# State control
# ----------------------------------------------------------------

func change_state(state: State) -> void:
	state_machine.change_state(state)

func begin_activity(activity: Global.StateName) -> void:
	var next := _plan_transition(state_machine.current_state_name(), activity)
	if next:
		state_machine.change_state(next)

func begin_walk() -> void:
	begin_activity(Global.StateName.WALK)

func begin_run() -> void:
	begin_activity(Global.StateName.RUN)

func begin_sprint() -> void:
	begin_activity(Global.StateName.SPRINT)

func set_highlight(enable: bool) -> void:
	anim.set_modulate(Color(1.4, 1.4, 1.0, 1.0) if enable else Color.WHITE)

func apply_color_variant(atlas: Texture2D) -> void:
	if atlas == null:
		return
	color_variant = atlas
	_swap_atlas(atlas)

func apply_marking_variant(texture: Texture2D) -> void:
	if texture != null:
		anim.set_marking(texture)
	else:
		anim.clear_marking()

func _swap_atlas(atlas: Texture2D) -> void:
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	sprite.sprite_frames = sprite.sprite_frames.duplicate(true) as SpriteFrames
	for anim_name: String in sprite.sprite_frames.get_animation_names():
		for i: int in sprite.sprite_frames.get_frame_count(anim_name):
			var tex := sprite.sprite_frames.get_frame_texture(anim_name, i)
			if tex is AtlasTexture:
				(tex as AtlasTexture).atlas = atlas

# ----------------------------------------------------------------
# Physics
# ----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_floor_check_timer += delta
	if _floor_check_timer >= _FLOOR_CHECK_INTERVAL:
		_floor_check_timer = 0.0
		_update_floor_type()
	queue_redraw()

func _draw() -> void:
	if navigation_target != null and navigation_target.is_valid():
		draw_circle(to_local(navigation_target.get_position()), 4.0, Color.RED)

# ----------------------------------------------------------------
# AI decision dispatch
# ----------------------------------------------------------------

func apply_decision(decision: ActivityDecision) -> void:
	if _surface_dismount_release_pending:
		return
	if is_surface_mounted() and decision.activity in [
		Global.StateName.SIT,
		Global.StateName.LAY,
		Global.StateName.LOOK_AROUND,
	]:
		begin_activity(decision.activity)
		return
	if not is_surface_mounted():
		release_hotspot()

	if decision.activity == Global.StateName.EXPLORE:
		var door_pos := _find_nearby_door()
		if door_pos != Vector2.INF:
			set_target(PositionTarget.new(door_pos))
		elif decision.walk_target != null:
			set_target(PositionTarget.new(decision.walk_target))
		begin_walk()
		return

	if decision.activity == Global.StateName.SIT:
		var slot := find_nearby_hotspot(FurnitureHotspot.ActionType.SIT)
		if not slot.is_empty():
			_begin_hotspot_walk(slot, _arrival_factory_for_hotspot_action(slot["requested_action"]))
			return
		elif decision.walk_target != null:
			set_target(PositionTarget.new(decision.walk_target))
	elif decision.activity == Global.StateName.LAY:
		var slot := find_nearby_hotspot(FurnitureHotspot.ActionType.LAY)
		if not slot.is_empty():
			_begin_hotspot_walk(slot, _arrival_factory_for_hotspot_action(slot["requested_action"]))
			return
		elif decision.walk_target != null:
			set_target(PositionTarget.new(decision.walk_target))
	else:
		if decision.walk_target != null:
			set_target(PositionTarget.new(decision.walk_target))

	begin_activity(decision.activity)

# ----------------------------------------------------------------
# Furniture & hotspot system
# ----------------------------------------------------------------

func _on_interest_area_entered(area: Area2D) -> void:
	var f := area.get_parent() as Furniture
	if f and not _nearby_furniture.has(f):
		_nearby_furniture.append(f)

func _on_interest_area_exited(area: Area2D) -> void:
	var f := area.get_parent() as Furniture
	if f:
		_nearby_furniture.erase(f)

func _has_line_of_sight(target_pos: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position, target_pos, WALL_PHYSICS_LAYER
	)
	query.exclude = [get_rid()]
	return space.intersect_ray(query).is_empty()

func find_nearby_hotspot(action: FurnitureHotspot.ActionType) -> Dictionary:
	for furniture in _nearby_furniture:
		if furniture is Door:
			continue
		for hs: FurnitureHotspot in furniture.get_hotspots():
			if not hs.supports_action(action) or not hs.has_available_slot():
				continue
			for i in hs.slots.size():
				if hs.is_slot_claimed(i):
					continue
				var slot := _get_hotspot_slot_positions(hs, i)
				if not _has_line_of_sight(slot.target_world_pos):
					continue
				if _claim_hotspot_slot(hs, i):
					slot["requested_action"] = int(action)
					return slot
	return {}

func occupy_hotspot_at(world_pos: Vector2, radius: float = HOTSPOT_CLICK_RADIUS) -> bool:
	if is_surface_mounted():
		begin_walk()
		return true

	var slot := _find_hotspot_under_point(world_pos, radius)
	if slot.is_empty():
		return false

	release_hotspot()
	var hs := slot["hotspot"] as FurnitureHotspot
	var idx: int = slot["index"]
	if not _claim_hotspot_slot(hs, idx):
		return false

	slot["requested_action"] = int(slot.get("requested_action", hs.get_default_action()))
	_begin_hotspot_walk(slot, _arrival_factory_for_hotspot_action(slot["requested_action"]))
	return true

func _find_hotspot_under_point(world_pos: Vector2, radius: float) -> Dictionary:
	var best := {}
	var best_dist := radius
	for furniture in _nearby_furniture:
		if furniture is Door:
			continue
		for hs: FurnitureHotspot in furniture.get_hotspots():
			if not hs.has_available_slot():
				continue
			for i in hs.slots.size():
				if hs.is_slot_claimed(i):
					continue
				var slot := _get_hotspot_slot_positions(hs, i)
				var dist: float = world_pos.distance_to(slot.occupy_world_pos)
				if dist > best_dist or not _has_line_of_sight(slot.target_world_pos):
					continue
				slot["requested_action"] = hs.get_default_action()
				best_dist = dist
				best = slot
	return best

func _find_nearby_door() -> Vector2:
	for f in _nearby_furniture:
		if f is Door and _has_line_of_sight(f.global_position):
			return f.global_position
	return Vector2.INF

func release_hotspot(snap_to_dismount: bool = true) -> void:
	if snap_to_dismount and _surface_mount_rendering_active and _pending_surface_dismount_position != Vector2.INF:
		global_position = _pending_surface_dismount_position
	_deactivate_surface_mount_rendering()
	if _claimed_hotspot:
		_claimed_hotspot.release(self)
		_claimed_hotspot = null
	_claimed_furniture = null
	_clear_pending_surface_points()
	_hotspot_claim_reserved_for_arrival = false
	_surface_dismount_release_pending = false
	_arrival_state_factory = Callable()

func release_hotspot_from_rest_state() -> void:
	if _hotspot_claim_reserved_for_arrival or _surface_mount_rendering_active:
		return
	release_hotspot()

func release_hotspot_for_floor_movement() -> void:
	if _surface_mount_rendering_active or _surface_dismount_release_pending:
		return
	release_hotspot()

func _claim_hotspot_slot(hs: FurnitureHotspot, idx: int) -> bool:
	if not hs.claim_slot(self, idx):
		return false
	_claimed_hotspot = hs
	_claimed_furniture = hs.source_furniture
	_hotspot_claim_reserved_for_arrival = true
	return true

func _get_hotspot_slot_positions(hs: FurnitureHotspot, idx: int) -> Dictionary:
	var furniture := hs.source_furniture
	if furniture != null:
		return furniture.get_hotspot_slot_plan(hs, idx)
	var occupy_world_pos := hs.slots[idx]
	return {
		"hotspot": hs,
		"index": idx,
		"uses_surface_points": false,
		"target_world_pos": occupy_world_pos,
		"approach_world_pos": occupy_world_pos,
		"occupy_world_pos": occupy_world_pos,
		"dismount_world_pos": occupy_world_pos,
		"default_action": hs.get_default_action(),
	}

func _begin_hotspot_walk(slot: Dictionary, arrival_factory: Callable = Callable()) -> void:
	set_target(PositionTarget.new(slot.target_world_pos))
	_prepare_hotspot_arrival(slot, arrival_factory)
	begin_walk()

func _prepare_hotspot_arrival(slot: Dictionary, arrival_factory: Callable) -> void:
	_clear_pending_surface_points()
	if slot.uses_surface_points:
		_pending_surface_occupy_position = slot.occupy_world_pos
		_pending_surface_dismount_position = slot.dismount_world_pos
		_arrival_state_factory = func() -> State:
			var next_state := _build_surface_arrival_state(slot, arrival_factory)
			return SURFACE_MOUNT_STATE.new(_pending_surface_occupy_position, next_state)
	else:
		_arrival_state_factory = func() -> State:
			_mark_claimed_hotspot_occupied()
			if arrival_factory.is_valid():
				return arrival_factory.call() as State
			return SitState.new()

func _arrival_factory_for_hotspot_action(action_type: int) -> Callable:
	if action_type == FurnitureHotspot.ActionType.LAY:
		return func() -> State: return LayDownState.new(LayState.new())
	return Callable()

func complete_surface_mount(occupy_position: Vector2) -> void:
	if occupy_position != Vector2.INF:
		global_position = occupy_position
	_mark_claimed_hotspot_occupied()

func complete_surface_dismount(dismount_position: Vector2) -> void:
	if dismount_position != Vector2.INF:
		global_position = dismount_position
	release_hotspot(false)

func _mark_claimed_hotspot_occupied() -> void:
	_hotspot_claim_reserved_for_arrival = false

func _build_surface_arrival_state(_slot: Dictionary, arrival_factory: Callable) -> State:
	var target_state: State = arrival_factory.call() as State if arrival_factory.is_valid() else SitState.new(true, true)
	var look_direction := _pick_surface_rest_direction()
	var look_state := _build_surface_lookaround_state(target_state, look_direction)
	return TIMED_SIT_STATE.new(look_state, _surface_rng.randf_range(0.08, 0.18))

func _build_surface_lookaround_state(next_state: State, finish_direction: int) -> State:
	return LookAroundState.new(
		next_state,
		false,
		Global.LookDirection.BOTH,
		_surface_rng.randf_range(0.9, 1.25),
		0.06,
		0.06,
		0.04,
		1,
		finish_direction,
		0.07
	)

func _pick_surface_rest_direction() -> int:
	var directions := [
		Global.Direction.NORTH,
		Global.Direction.NORTHEAST,
		Global.Direction.EAST,
		Global.Direction.SOUTHEAST,
		Global.Direction.SOUTH,
		Global.Direction.SOUTHWEST,
		Global.Direction.WEST,
		Global.Direction.NORTHWEST,
	]
	return int(directions[_surface_rng.randi_range(0, directions.size() - 1)])

func _clear_pending_surface_points() -> void:
	_pending_surface_occupy_position = Vector2.INF
	_pending_surface_dismount_position = Vector2.INF

func is_surface_mounted() -> bool:
	return _surface_mount_rendering_active and _pending_surface_dismount_position != Vector2.INF

func _surface_dismount_state(next_state: State) -> State:
	if not is_surface_mounted() or _pending_surface_dismount_position == Vector2.INF:
		return next_state
	_surface_dismount_release_pending = true
	return SURFACE_DISMOUNT_STATE.new(_pending_surface_dismount_position, next_state)

func _surface_departure_state(next_state: State) -> State:
	if not is_surface_mounted() or _pending_surface_dismount_position == Vector2.INF:
		return StandUpState.new(next_state)
	var dismount_state := _surface_dismount_state(next_state)
	var standup_state := StandUpState.new(dismount_state)
	if state_machine.current_state_name() == Global.StateName.LOOK_AROUND:
		return standup_state
	return _build_surface_lookaround_state(standup_state, _surface_dismount_direction())

func _surface_lay_from_sit_state() -> State:
	var lay_state := LayDownState.new(LayState.new())
	if not is_surface_mounted():
		return lay_state
	return _build_surface_lookaround_state(lay_state, _pick_surface_rest_direction())

func _surface_dismount_direction() -> int:
	if _pending_surface_dismount_position == Vector2.INF:
		return int(facing_direction)
	var delta := _pending_surface_dismount_position - global_position
	if delta.length_squared() < 4.0:
		return int(facing_direction)
	return int(Global.direction_from_vector(delta))

func activate_claimed_surface_rendering() -> void:
	if _claimed_furniture == null or not _claimed_furniture.uses_surface_mount_rendering():
		return
	if not _surface_mount_rendering_active:
		_normal_z_index = z_index
		_normal_z_as_relative = z_as_relative
		_surface_mount_rendering_active = true
	z_as_relative = _normal_z_as_relative
	z_index = _claimed_furniture.mounted_character_z_index

func _deactivate_surface_mount_rendering() -> void:
	if not _surface_mount_rendering_active:
		return
	z_index = _normal_z_index
	z_as_relative = _normal_z_as_relative
	_surface_mount_rendering_active = false

func get_nearby_furniture() -> Array[Furniture]:
	return _nearby_furniture

func get_claimed_hotspot() -> FurnitureHotspot:
	return _claimed_hotspot

# ----------------------------------------------------------------
# Floor type
# ----------------------------------------------------------------

func _update_floor_type() -> void:
	for f in _nearby_furniture:
		var rect := f.get_footprint_rect()
		if rect.size != Vector2.ZERO and rect.has_point(global_position):
			current_floor_type = Global.FloorType.RUG
			return
	if _floor_layer == null:
		current_floor_type = Global.FloorType.NONE
		return
	var cell := _floor_layer.local_to_map(_floor_layer.to_local(global_position))
	var td := _floor_layer.get_cell_tile_data(cell)
	if td == null:
		current_floor_type = Global.FloorType.NONE
		return
	var raw: String = td.get_custom_data("floor_type")
	if Global.FloorType.has(raw):
		current_floor_type = Global.FloorType[raw]
	else:
		current_floor_type = Global.FloorType.NONE

# ----------------------------------------------------------------
# State topology
# ----------------------------------------------------------------

func _plan_transition(from: Global.StateName, to: Global.StateName) -> State:
	if from == to:
		return null
	var posture: int = _posture_groups.get(from, PostureGroup.STANDING)
	var row: Dictionary = _transition_table.get(posture, {})
	if not row.has(to):
		push_error("Character._plan_transition: no entry for " + str(from) + " -> " + str(to))
		return null
	var factory: Variant = row[to]
	return factory.call() if factory != null else null

# ----------------------------------------------------------------
# Initialisation
# ----------------------------------------------------------------

func _state_for_activity(activity: Global.StateName) -> State:
	match activity:
		Global.StateName.LAY:
			return LayState.new()
		Global.StateName.WALK:
			return MovementState.walk()
		Global.StateName.RUN:
			return MovementState.run()
		Global.StateName.SPRINT:
			return MovementState.sprint()
		_:
			return SitState.new(true, true)
