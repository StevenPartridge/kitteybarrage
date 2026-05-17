extends CharacterBody2D
class_name CharacterBase

var anim: StateAnimator

@export var personality: CharacterPersonality
@export var speed := 150

var facing_direction: Global.Direction = Global.Direction.SOUTH
var navigation_target: NavigationTarget = null

func set_target(target: NavigationTarget) -> void:
	navigation_target = target

func clear_target() -> void:
	navigation_target = null
