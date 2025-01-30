class_name FocusInputManager
extends Node

# A simple manager to cycle input focus among nodes that have an InputHandler-like trait.
# 1. Attach this script to a node in your scene (or make it an Autoload).
# 2. Each object that wants to be focusable calls register_input_handler(self) on this manager.
# 3. Press the 'change_focus' action (Tab, for example) to cycle focus.
# 4. Only the active handler receives input; others are inactive.
# 5. Active handler can show a "shine/foil" effect by calling a highlight method.

var handlers: Array = []
var active_index: int = -1

func register_input_handler(handler):
	handlers.append(handler)
	# If this is the first registered handler, activate it immediately
	if active_index == -1:
		active_index = 0
		set_active_handler(active_index)

func _unregister_input_handler(handler):
	# Call this if a handler is removed from the scene.
	var idx = handlers.find(handler)
	if idx != -1:
		handlers.remove_at(idx)
		if active_index == idx:
			# If the removed handler was active, deactivate
			set_active_handler(-1)
		if active_index >= handlers.size():
			active_index = handlers.size() - 1
			set_active_handler(active_index)

func _input(event):
	# Make sure you have "change_focus" mapped to Tab (or any key you prefer) in Project Settings > Input Map
	if event.is_action_pressed("change_focus"):
		cycle_focus()

func cycle_focus():
	if handlers.size() < 1:
		return
	# Deactivate current
	if active_index != -1:
		set_active_handler(-1)
	# Cycle index
	active_index = (active_index + 1) % handlers.size()
	# Activate new
	set_active_handler(active_index)

func set_active_handler(index: int):
	# If index is -1, it means we're disabling the currently active handler
	if index == -1:
		if active_index >= 0 and active_index < handlers.size():
			disable_handler(handlers[active_index])
			handlers[active_index].set_highlight(false)
		return

	# Otherwise, enable the handler at 'index'
	if index >= 0 and index < handlers.size():
		enable_handler(handlers[index])
		handlers[index].set_highlight(true)
	else:
		push_warning("Invalid handler index: " + str(index))

func enable_handler(handler):
	# Example: Let the handler receive input events and highlight its sprite
	# Implementation depends on how your InputHandler or sprite highlight logic is written
	if handler.has_method("set_input_active"):
		handler.set_input_active(true)

func disable_handler(handler):
	# Example: Disallow input events and remove highlight from its sprite
	if handler.has_method("set_input_active"):
		handler.set_input_active(false)
