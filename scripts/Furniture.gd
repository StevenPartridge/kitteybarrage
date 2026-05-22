class_name Furniture
extends Node2D

@export var variant: int = 0

var _hotspots: Array[FurnitureHotspot] = []

func _ready() -> void:
	_apply_variant()
	_init_hotspots()

func _apply_variant() -> void:
	pass

func _init_hotspots() -> void:
	pass

func get_hotspots() -> Array[FurnitureHotspot]:
	return _hotspots

func get_footprint_rect() -> Rect2:
	return Rect2()
