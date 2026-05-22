class_name FurnitureHotspot
extends Resource

enum ActionType { SIT, LAY, SNIFF, KNOCK }

@export var action: ActionType
@export var slots: Array[Vector2]

var _claimed: Dictionary = {}
var knocked := false

func claim(character: CharacterBase) -> int:
	if knocked:
		return -1
	for i in slots.size():
		if not _claimed.has(i):
			_claimed[i] = character
			return i
	return -1

func release(character: CharacterBase) -> void:
	for key in _claimed.keys():
		if _claimed[key] == character:
			_claimed.erase(key)
			return

func has_available_slot() -> bool:
	return not knocked and _claimed.size() < slots.size()

func is_slot_claimed(idx: int) -> bool:
	return _claimed.has(idx)
