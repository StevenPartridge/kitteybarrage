extends CharacterBody2D
class_name CharacterBase

var anim: StateAnimator

@export var personality: CharacterPersonality
@export var speed := 150

var facing_direction: Global.Direction = Global.Direction.SOUTH
var navigation_target: NavigationTarget = null
var _arrival_state_factory: Callable = Callable()

func set_target(target: NavigationTarget) -> void:
	navigation_target = target

func clear_target() -> void:
	navigation_target = null

func pop_arrival_state() -> State:
	if _arrival_state_factory.is_valid():
		var s := _arrival_state_factory.call() as State
		_arrival_state_factory = Callable()
		return s
	return SitState.new()
