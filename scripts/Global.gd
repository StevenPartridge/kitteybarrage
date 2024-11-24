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
