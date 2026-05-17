class_name ActivityDecision
extends RefCounted

var activity: Global.StateName
var walk_target: Variant

func _init(a: Global.StateName, target: Variant = null) -> void:
	activity = a
	walk_target = target
