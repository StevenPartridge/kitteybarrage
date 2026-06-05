class_name HotspotSpec
extends Resource

@export var action: FurnitureHotspot.ActionType
@export_flags("SIT", "LAY", "SNIFF", "KNOCK") var action_flags: int = 0
@export var slots: Array[Vector2] = []
@export var approach_slots: Array[Vector2] = []
@export var dismount_slots: Array[Vector2] = []

func get_actions() -> Array[int]:
	var action_list := FurnitureHotspot.actions_from_flags(action_flags)
	if action_list.is_empty():
		action_list.append(int(action))
	return action_list

func get_default_action() -> int:
	var action_list := get_actions()
	if action_list.has(int(action)):
		return int(action)
	if not action_list.is_empty():
		return action_list[0]
	return int(action)
