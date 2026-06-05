class_name FurnitureHotspot
extends Resource

enum ActionType { SIT, LAY, SNIFF, KNOCK }

@export var action: ActionType
@export var actions: Array[int] = []
@export var slots: Array[Vector2]

const _ACTION_ORDER: Array[int] = [
	ActionType.SIT,
	ActionType.LAY,
	ActionType.SNIFF,
	ActionType.KNOCK,
]

var source_furniture: Furniture = null
var approach_slots: Array[Vector2] = []
var dismount_slots: Array[Vector2] = []
var _claimed: Dictionary = {}
var knocked := false

static func actions_from_flags(flags: int) -> Array[int]:
	var result: Array[int] = []
	for action_type: int in _ACTION_ORDER:
		if flags & (1 << action_type):
			result.append(action_type)
	return result

func set_actions(action_list: Array) -> void:
	actions.clear()
	for action_type_raw in action_list:
		var action_type := int(action_type_raw)
		if not actions.has(action_type):
			actions.append(action_type)
	if not actions.is_empty():
		action = actions[0]

func get_actions() -> Array[int]:
	var result: Array[int] = []
	if actions.is_empty():
		result.append(int(action))
	else:
		for action_type: int in actions:
			if not result.has(action_type):
				result.append(action_type)
	return result

func supports_action(action_type: int) -> bool:
	return get_actions().has(int(action_type))

func get_default_action() -> int:
	var action_list := get_actions()
	if action_list.has(int(action)):
		return int(action)
	if not action_list.is_empty():
		return action_list[0]
	return int(action)

func get_action_label() -> String:
	var labels: Array[String] = []
	var keys := ActionType.keys()
	for action_type: int in get_actions():
		if action_type >= 0 and action_type < keys.size():
			labels.append(keys[action_type])
		else:
			labels.append(str(action_type))
	return "/".join(labels)

func claim(character: CharacterBase) -> int:
	if knocked:
		return -1
	for i in slots.size():
		if claim_slot(character, i):
			return i
	return -1

func claim_slot(character: CharacterBase, idx: int) -> bool:
	if knocked or idx < 0 or idx >= slots.size() or _claimed.has(idx):
		return false
	_claimed[idx] = character
	return true

func release(character: CharacterBase) -> void:
	for key in _claimed.keys():
		if _claimed[key] == character:
			_claimed.erase(key)
			return

func has_available_slot() -> bool:
	return not knocked and _claimed.size() < slots.size()

func is_slot_claimed(idx: int) -> bool:
	return _claimed.has(idx)

func has_approach_slot(idx: int) -> bool:
	return idx >= 0 and idx < approach_slots.size()

func get_approach_slot(idx: int) -> Vector2:
	if has_approach_slot(idx):
		return approach_slots[idx]
	return slots[idx]

func get_dismount_slot(idx: int) -> Vector2:
	if idx >= 0 and idx < dismount_slots.size():
		return dismount_slots[idx]
	return get_approach_slot(idx)
