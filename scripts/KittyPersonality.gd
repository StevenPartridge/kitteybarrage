extends CharacterPersonality
class_name KittyPersonality

@export_group("Look Around")
@export var look_around_direction: Global.LookDirection = Global.LookDirection.BOTH
@export var look_around_speed: float = 1.0
@export var look_around_pause_right: float = 0.0
@export var look_around_pause_left: float = 0.0
@export var look_around_pause_center: float = 0.0
@export var look_around_repetitions: int = 1

# Produces a coherent randomized personality from three underlying axes:
#   energy    (0=lazy, 1=energetic) — drives rest vs. movement balance
#   curiosity (0=calm, 1=curious)   — drives look_around frequency
#   speed     (0=walker, 1=runner)  — splits movement budget toward run/sprint
static func randomized(rng: RandomNumberGenerator) -> KittyPersonality:
	var p := KittyPersonality.new()
	var energy    := rng.randf()
	var curiosity := rng.randf()
	var speed     := rng.randf()

	# Rest preferences — lazy cats sit and lay a lot
	p.preference_sit = lerp(0.6, 0.2, energy)
	p.preference_lay = lerp(0.4, 0.05, energy)

	# Movement preferences — energetic cats move more, fast cats run/sprint more
	var movement_budget: float = lerp(0.3, 1.2, energy)
	p.preference_walk   = movement_budget * lerp(1.0, 0.4, speed)
	p.preference_run    = movement_budget * lerp(0.05, 0.5, speed)
	p.preference_sprint = movement_budget * lerp(0.0, 0.15, speed)

	# Curiosity drives look-around
	p.preference_look_around = lerp(0.05, 0.6, curiosity)

	# Durations — lazier cats linger longer in each state
	p.duration_sit         = lerp(6.0, 2.0, energy)
	p.duration_lay         = lerp(18.0, 6.0, energy)
	p.duration_walk        = lerp(3.0, 8.0, energy)
	p.duration_run         = lerp(2.0, 5.0, energy)
	p.duration_sprint      = lerp(1.0, 3.0, energy)
	p.duration_look_around = lerp(3.5, 1.5, curiosity)

	# Energetic cats almost always walk to a destination
	p.walk_target_chance = lerp(0.55, 0.95, energy)

	# Lazier cats fatigue faster and need to rest more often
	p.rest_threshold = lerp(12.0, 35.0, energy)

	# Look-around style varies independently
	p.look_around_repetitions  = rng.randi_range(1, 3)
	p.look_around_speed        = lerp(0.5, 1.8, rng.randf())
	p.look_around_pause_right  = lerp(0.0, 0.5, rng.randf())
	p.look_around_pause_left   = lerp(0.0, 0.5, rng.randf())
	p.look_around_pause_center = lerp(0.0, 0.3, rng.randf())

	return p
