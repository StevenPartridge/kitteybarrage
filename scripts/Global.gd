# Global.gd

extends Node

enum StateName {
    SIT,
    WALK,
	STANDUP,
	SITUP,
    LAY,
    LAY_DOWN,
    RUN,
    LOOK_AROUND,
	SPRINT,
    LOOK_TRACK,
	EXPLORE,
	SURFACE_MOUNT,
	SURFACE_DISMOUNT,
	MANUAL_MOVE,
	STAND_IDLE,
}

enum FloorType { NONE, WOOD, STONE, CHECKER, RUG }

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

enum LookDirection { BOTH, LEFT_ONLY, RIGHT_ONLY }

func direction_to_string(direction: Direction) -> String:
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

func get_full_animation_name(state_name: String, direction: Global.Direction) -> String:
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

func direction_to_angle(direction: Direction) -> float:
	var angle := (int(direction) - 2) * PI / 4.0
	while angle > PI:
		angle -= TAU
	while angle <= -PI:
		angle += TAU
	return angle

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
