extends Node2D
class_name SeparationDebugDraw

var director: WorldDirector

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	if director == null:
		return
	for character in director.characters:
		var col := Color(0.3, 0.9, 1.0, 0.35) if character != director.controlled_character \
			else Color(1.0, 0.85, 0.3, 0.45)
		draw_arc(character.position, director.separation_radius, 0.0, TAU, 48, col, 1.5)
