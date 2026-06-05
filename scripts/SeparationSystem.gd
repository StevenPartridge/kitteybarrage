extends Node
class_name SeparationSystem

@export var separation_radius: float = 32.0
@export var separation_strength: float = 120.0
@export var rest_push_strength: float = 20.0
@export var max_speed_nudge_fraction: float = 0.1

var _characters: Array[Character] = []

func _ready() -> void:
	process_physics_priority = 1

func setup(characters: Array[Character]) -> void:
	_characters = characters

func _physics_process(delta: float) -> void:
	if _characters.is_empty():
		return
	var forces := _compute_forces()
	_apply_forces(forces, delta)

func _compute_forces() -> Dictionary:
	var forces: Dictionary = {}
	for character in _characters:
		forces[character] = Vector2.ZERO
	for i in _characters.size():
		for j in range(i + 1, _characters.size()):
			var a: Character = _characters[i]
			var b: Character = _characters[j]
			var diff: Vector2 = a.position - b.position
			var dist: float = diff.length()
			if dist >= separation_radius or dist < 0.01:
				continue
			var push: Vector2 = diff.normalized() * (1.0 - dist / separation_radius) * separation_strength
			var ma := _mobility(a)
			var mb := _mobility(b)
			var total := ma + mb
			if total == 0.0:
				continue
			forces[a] += push * ma / total
			forces[b] -= push * mb / total
	return forces

func _apply_forces(forces: Dictionary, delta: float) -> void:
	for character in _characters:
		var force: Vector2 = forces.get(character, Vector2.ZERO)
		match character.state_machine.current_state_name():
			Global.StateName.WALK, Global.StateName.RUN, Global.StateName.SPRINT, Global.StateName.MANUAL_MOVE, \
			Global.StateName.STANDUP, Global.StateName.SITUP:
				character.velocity += force.limit_length(character.speed * max_speed_nudge_fraction)
				character.move_and_slide()
			_:
				if force == Vector2.ZERO:
					continue
				var nudge: Vector2 = force.normalized() \
					* minf(force.length(), rest_push_strength) * delta
				character.position += nudge

func _mobility(character: Character) -> float:
	match character.state_machine.current_state_name():
		Global.StateName.WALK, Global.StateName.RUN, Global.StateName.SPRINT, Global.StateName.MANUAL_MOVE:
			return 1.0
		Global.StateName.STANDUP, Global.StateName.SITUP:
			return 0.8
		Global.StateName.SIT, Global.StateName.LOOK_AROUND, Global.StateName.STAND_IDLE:
			return 0.0
		Global.StateName.LAY, Global.StateName.LAY_DOWN, \
		Global.StateName.SURFACE_MOUNT, Global.StateName.SURFACE_DISMOUNT:
			return 0.0
		_:
			return 0.4
