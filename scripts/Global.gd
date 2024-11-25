# Global.gd

extends Node  # Can also extend Reference if not needed in the scene tree

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
