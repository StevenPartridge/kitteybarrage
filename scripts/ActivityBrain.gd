class_name ActivityBrain
extends RefCounted

var _rng: RandomNumberGenerator
var _preference: Dictionary
var _duration: Dictionary
var _rest_threshold: float
var _walk_target_chance: float
var _personality: CharacterPersonality
var _activity_timer: float = 0.0
var _rest_timer: float = 0.0
var _current_activity: Global.StateName

func _init(rng: RandomNumberGenerator, personality: CharacterPersonality) -> void:
	_rng = rng
	_preference = {
		Global.StateName.WALK:        personality.preference_walk,
		Global.StateName.SIT:         personality.preference_sit,
		Global.StateName.LAY:         personality.preference_lay,
		Global.StateName.RUN:         personality.preference_run,
		Global.StateName.LOOK_AROUND: personality.preference_look_around,
		Global.StateName.SPRINT:      personality.preference_sprint,
		Global.StateName.EXPLORE:     personality.preference_explore,
	}
	_duration = {
		Global.StateName.WALK:        personality.duration_walk,
		Global.StateName.SIT:         personality.duration_sit,
		Global.StateName.LAY:         personality.duration_lay,
		Global.StateName.RUN:         personality.duration_run,
		Global.StateName.LOOK_AROUND: personality.duration_look_around,
		Global.StateName.SPRINT:      personality.duration_sprint,
		Global.StateName.EXPLORE:     personality.duration_explore,
	}
	_rest_threshold = personality.rest_threshold
	_walk_target_chance = personality.walk_target_chance
	_personality = personality
	_activity_timer = 0.0
	_rest_timer = 0.0
	_current_activity = Global.StateName.SIT

func refresh_personality(p: CharacterPersonality) -> void:
	_preference[Global.StateName.WALK]        = p.preference_walk
	_preference[Global.StateName.SIT]         = p.preference_sit
	_preference[Global.StateName.LAY]         = p.preference_lay
	_preference[Global.StateName.RUN]         = p.preference_run
	_preference[Global.StateName.LOOK_AROUND] = p.preference_look_around
	_preference[Global.StateName.SPRINT]      = p.preference_sprint
	_preference[Global.StateName.EXPLORE]     = p.preference_explore
	_duration[Global.StateName.WALK]          = p.duration_walk
	_duration[Global.StateName.SIT]           = p.duration_sit
	_duration[Global.StateName.LAY]           = p.duration_lay
	_duration[Global.StateName.RUN]           = p.duration_run
	_duration[Global.StateName.LOOK_AROUND]   = p.duration_look_around
	_duration[Global.StateName.SPRINT]        = p.duration_sprint
	_duration[Global.StateName.EXPLORE]       = p.duration_explore
	_rest_threshold    = p.rest_threshold
	_walk_target_chance = p.walk_target_chance
	_personality = p

func tick(delta: float, walk_bounds: Rect2, floor_type: Global.FloorType = Global.FloorType.NONE) -> ActivityDecision:
	_activity_timer += delta
	if _activity_timer < _duration[_current_activity]:
		return null
	_activity_timer = 0.0
	return _decide(walk_bounds, floor_type)

func _decide(walk_bounds: Rect2, floor_type: Global.FloorType) -> ActivityDecision:
	if _rest_timer >= _rest_threshold:
		_current_activity = Global.StateName.LAY
		_rest_timer = 0.0
	else:
		var adjusted: Dictionary = _preference.duplicate()
		match floor_type:
			Global.FloorType.STONE:
				adjusted[Global.StateName.SIT]     *= 0.5
				adjusted[Global.StateName.LAY]     *= 0.3
				adjusted[Global.StateName.EXPLORE] *= 1.3
			Global.FloorType.WOOD:
				adjusted[Global.StateName.WALK]    *= 1.2
				adjusted[Global.StateName.RUN]     *= 1.3
				adjusted[Global.StateName.SPRINT]  *= 1.2
				adjusted[Global.StateName.EXPLORE] *= 1.1
			Global.FloorType.RUG:
				adjusted[Global.StateName.SIT]     *= 1.8
				adjusted[Global.StateName.LAY]     *= 2.5
				adjusted[Global.StateName.WALK]    *= 0.7
				adjusted[Global.StateName.RUN]     *= 0.7
				adjusted[Global.StateName.EXPLORE] *= 0.5

		var total_weight := 0.0
		for weight in adjusted.values():
			total_weight += weight

		var random_value := _rng.randf() * total_weight
		var cumulative_weight := 0.0
		for activity in adjusted.keys():
			cumulative_weight += adjusted[activity]
			if random_value <= cumulative_weight:
				_current_activity = activity
				break

	_rest_timer += _duration[_current_activity]

	var walk_target: Variant = null
	if _current_activity == Global.StateName.EXPLORE:
		walk_target = Vector2(
			_rng.randf_range(walk_bounds.position.x, walk_bounds.position.x + walk_bounds.size.x),
			_rng.randf_range(walk_bounds.position.y, walk_bounds.position.y + walk_bounds.size.y)
		)
	elif _current_activity in [Global.StateName.WALK, Global.StateName.RUN, Global.StateName.SPRINT] and _rng.randf() < _walk_target_chance:
		walk_target = Vector2(
			_rng.randf_range(walk_bounds.position.x, walk_bounds.position.x + walk_bounds.size.x),
			_rng.randf_range(walk_bounds.position.y, walk_bounds.position.y + walk_bounds.size.y)
		)

	return ActivityDecision.new(_current_activity, walk_target)
