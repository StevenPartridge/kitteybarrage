# Global.gd

extends Node  # Can also extend Reference if not needed in the scene tree

enum StateName {
    SIT,
    WALK,
	STANDUP,
	SITUP,
    LAY,
    RUN
}

func state_name_to_state(state_name: StateName, extra: bool = false, extra2 = false) -> State:
	match state_name:
		StateName.SIT:
			return SitState.new(extra, extra2)
		StateName.WALK:
			return WalkState.new()
		StateName.STANDUP:
			return StandUpState.new()
		# StateName.SITUP:
		# 	return SitUpState.new()
		# StateName.LAY:
		# 	return LayState.new()
		# StateName.RUN:
		# 	return RunState.new()
		_:
			push_error("State not found: " + str(state_name))
			return null

# Enums
enum Direction {
	NORTH,
	NORTHEAST,
	EAST,
	SOUTHEAST,
	SOUTH,
	SOUTHWEST,
	WEST,
	NORTHWEST
}

# Constants
const SPEED := 200
const RUN_SPEED := 300
const SIT_DELAY := 0.5

static func direction_to_string(direction: Direction) -> String:
	match direction:
		Direction.NORTH:
			return "North"
		Direction.NORTHEAST:
			return "Northeast"
		Direction.EAST:
			return "East"
		Direction.SOUTHEAST:
			return "Southeast"
		Direction.SOUTH:
			return "South"
		Direction.SOUTHWEST:
			return "Southwest"
		Direction.WEST:
			return "West"
		Direction.NORTHWEST:
			return "Northwest"
		_:
			return "Unknown"

func get_full_animation_name(state_name: String, direction: Global.Direction):
	var direction_suffix = ""
	match direction:
		Global.Direction.NORTH:
			direction_suffix = "_North"
		Global.Direction.NORTHEAST:
			direction_suffix = "_Northeast"
		Global.Direction.EAST:
			direction_suffix = "_East"
		Global.Direction.SOUTHEAST:
			direction_suffix = "_Southeast"
		Global.Direction.SOUTH:
			direction_suffix = "_South"
		Global.Direction.SOUTHWEST:
			direction_suffix = "_Southwest"
		Global.Direction.WEST:
			direction_suffix = "_West"
		Global.Direction.NORTHWEST:
			direction_suffix = "_Northwest"
	return state_name + direction_suffix


func direction_from_vector(input_vector: Vector2) -> Global.Direction:
	var angle = input_vector.angle()
	var eight_directions = [
		Global.Direction.EAST,
		Global.Direction.SOUTHEAST,
		Global.Direction.SOUTH,
		Global.Direction.SOUTHWEST,
		Global.Direction.WEST,
		Global.Direction.NORTHWEST,
		Global.Direction.NORTH,
		Global.Direction.NORTHEAST
	]
	var index = int(round(angle / (PI / 4))) % 8
	return eight_directions[index]