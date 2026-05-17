extends Character
class_name Kitty

func _build_posture_groups() -> Dictionary:
	var groups := super._build_posture_groups()
	groups[Global.StateName.SIT]         = PostureGroup.SITTING
	groups[Global.StateName.LOOK_AROUND] = PostureGroup.SITTING
	groups[Global.StateName.LAY]         = PostureGroup.LYING
	groups[Global.StateName.LAY_DOWN]    = PostureGroup.LYING
	return groups

func _build_transition_table() -> Dictionary:
	var table := super._build_transition_table()
	table[PostureGroup.SITTING] = {
		Global.StateName.WALK:        func(): return StandUpState.new(MovementState.walk()),
		Global.StateName.RUN:         func(): return StandUpState.new(MovementState.run()),
		Global.StateName.SPRINT:      func(): return StandUpState.new(MovementState.sprint()),
		Global.StateName.SIT:         func(): return SitState.new(true, true),
		Global.StateName.LAY:         func(): return LayDownState.new(LayState.new()),
		Global.StateName.LOOK_AROUND: func(): return LookAroundState.new(),
	}
	table[PostureGroup.LYING] = {
		Global.StateName.WALK:        func(): return SitUpState.new(StandUpState.new(MovementState.walk())),
		Global.StateName.RUN:         func(): return SitUpState.new(StandUpState.new(MovementState.run())),
		Global.StateName.SPRINT:      func(): return SitUpState.new(StandUpState.new(MovementState.sprint())),
		Global.StateName.SIT:         func(): return SitUpState.new(SitState.new(true, true)),
		Global.StateName.LAY:         null,
		Global.StateName.LOOK_AROUND: null,
	}
	return table
