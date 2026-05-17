extends Resource
class_name CharacterPersonality

@export_group("Activity Weights")
@export var preference_walk: float = 0.5
@export var preference_sit: float = 0.5
@export var preference_lay: float = 0.0
@export var preference_run: float = 0.0
@export var preference_look_around: float = 0.3
@export var preference_sprint: float = 0.0

@export_group("Activity Durations (seconds)")
@export var duration_walk: float = 5.0
@export var duration_sit: float = 3.0
@export var duration_lay: float = 4.0
@export var duration_run: float = 2.0
@export var duration_look_around: float = 2.0
@export var duration_sprint: float = 1.5

@export_group("Fatigue")
@export var rest_threshold: float = 10.0
@export var walk_target_chance: float = 0.4

@export_group("Movement")
@export var run_speed_multiplier: float = 1.6
@export var sprint_speed_multiplier: float = 2.4
