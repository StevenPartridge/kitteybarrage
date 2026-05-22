extends State
class_name LayState

func name() -> Global.StateName:
	return Global.StateName.LAY

func _enter_state(_from: Global.StateName) -> void:
	assert(entity != null, "LayState requires a Kitty entity — FSM must be a child of Kitty")
	entity.velocity = Vector2.ZERO
	entity.anim.play_once("Lay", entity.facing_direction, true, true)

func tick(_delta: float) -> State:
	return null

func _exit_state() -> void:
	entity.release_hotspot()
	entity.anim.cancel()
