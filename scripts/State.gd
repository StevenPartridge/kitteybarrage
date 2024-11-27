extends Node
class_name State

#signal state_finished

var entity  # Reference to the Kitty node

func name():
	return "StateName"

func _init():
	pass

func _enter_state():
	pass

func _exit_state():
	pass


# Play a callback on the entity's AnimationPlayer
func listen_for_animation_end(callback: Callable):
	if entity:
		if entity.animation_player.is_connected("animation_finished", callback):
			entity.animation_player.disconnect("animation_finished", callback)  # Avoid duplicates
		entity.animation_player.connect("animation_finished", callback)
		if entity.animation_player.is_connected("animation_changed", callback):
			entity.animation_player.disconnect("animation_changed", callback)
		entity.animation_player.connect("animation_changed", callback)