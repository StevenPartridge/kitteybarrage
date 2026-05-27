# Kitty Barrage — Domain Vocabulary

## Core Entities

**CharacterBase** — The typed seam between `State` and the concrete character hierarchy (`extends CharacterBody2D`, `class_name CharacterBase`, defined in `CharacterBase.gd`). Owns the fields all states read: `anim`, `personality`, `speed`, `facing_direction`, `navigation_target`, and the `set_target` / `clear_target` methods. `State.entity` is typed as `CharacterBase` to break the parse-time circular dependency between `State` and `Character`.

**Character** — The playable character base class (`extends CharacterBase`, `class_name Character`, defined in `Character.gd`). Owns `FiniteStateMachine` and all state control logic. Public interface: `change_state`, `begin_activity`, `begin_walk`, `begin_run`, `begin_sprint`, `apply_decision`, `set_target`, `set_highlight`. `begin_walk/run/sprint` are named wrappers over `begin_activity`. All transition logic lives in the private `_plan_transition` / `_plan_movement` methods — adding a new activity means adding one entry there. All autonomous behavior data lives in `CharacterPersonality` and `ActivityBrain`, not on the character itself.

**Kitty** — A `Character` subclass (`extends Character`, `class_name Kitty`). No additional logic — exists as a named type so scenes and type-checks can reference kitties specifically.

**WorldDirector** — Drives all characters in the world. Owns the `Dictionary[Character, ActivityBrain]` mapping (`brains`) and is the sole source of truth for which character is `controlled_character`. Handles player focus cycling, spawning, and applying `ActivityDecision` results to autonomous characters. Owns `SeparationSystem` as a child node.

**SeparationSystem** — A `Node` child of `WorldDirector` (`class_name SeparationSystem`, defined in `SeparationSystem.gd`) that owns all character collision-avoidance physics. Runs at `process_physics_priority = 1` (after character FSMs at priority 0). Each frame: computes pairwise separation forces into a local `Dictionary`, then for mobile characters (`WALK`, `RUN`, `SPRINT`, `STANDUP`, `SITUP`) adds the force to `velocity` and calls `move_and_slide()`; for resting characters nudges `position` directly. Mobility weights scale force distribution so high-mobility characters absorb less push. Config: `separation_radius`, `separation_strength`, `rest_push_strength` (all `@export`). States never call `move_and_slide()` — `SeparationSystem` is the sole caller.

## Behavior System

**Activity** — An autonomous behavior mode: `WALK`, `SIT`, `LAY`, `RUN`, `LOOK_AROUND`, `SPRINT`. Each character has per-activity preference weights and time budgets, owned by its `ActivityBrain`.

**ActivityBrain** — A `RefCounted` module, one per autonomous character, that encapsulates all autonomous behavior logic: timer ticking, rest-threshold check, and weighted random sampling. `brain.tick(delta)` returns `null` most frames and an `ActivityDecision` when the current activity expires. Owns its own `RandomNumberGenerator` for per-character personality variation.

**CharacterPersonality** — A `Resource` base class holding a character's autonomous behavior profile as inspector-editable data: per-activity preference weights, per-activity durations in seconds, `rest_threshold` (fatigue accumulation before forced rest), `walk_target_chance` (probability a movement decision gets a specific target), and speed multipliers. Passed to `ActivityBrain` at construction. Extend this for each character type.

**KittyPersonality** — Extends `CharacterPersonality`. Adds kitty-specific look-around parameters: `look_around_direction`, `look_around_speed`, `look_around_pause_right/left/center`, `look_around_repetitions`. These are accessed in `LookAroundState` via an `as KittyPersonality` cast — non-kitty characters fall back to defaults.

**ActivityDecision** — A `RefCounted` value returned by `ActivityBrain.tick()`. Fields: `activity: Global.StateName`, `walk_target: Variant`. `Character.apply_decision()` reads it and drives the character's state and navigation target.

**controlled character** — The single character currently receiving player input. Tracked as `WorldDirector.controlled_character`. All other characters run autonomously under `WorldDirector`.

## State Machine

**State** — A `Node` subclass that owns entity control for one activity. States implement `tick(delta) -> State`: return `null` to stay, return a `State` instance to transition. States never call `entity.change_state()` directly — the FSM owns all transitions. `var entity` is intentionally untyped (duck-typed to `Character` at runtime) to avoid a parse-time circular dependency. Concrete states: `SitState`, `LayState`, `StandUpState`, `SitUpState`, `LayDownState`, `LookAroundState`, `MovementState`.

**FiniteStateMachine** — Manages the current `State` for a `Character`. Owns all state transitions — the sole caller of `change_state`. Calls `state.tick(delta)` each frame; if a non-null `State` is returned, transitions immediately. States are added to the scene tree with `set_physics_process(false)` so the engine does not drive them directly — only the FSM does.

## Input

**InputHandler** — Reads movement input each frame via an injected `InputSource`. Exposes `input_vector: Vector2`, `is_moving() -> bool`, and `is_running() -> bool`. One instance per `WorldDirector`, not per character. Created as `InputHandler.new(GodotInputSource.new())` in production.

**InputSource** — Abstract base (`RefCounted`) with two methods: `get_input_vector() -> Vector2` and `is_running() -> bool`. The seam between input logic and the Godot `Input` global. `GodotInputSource` is the production adapter. Swap the adapter in tests to replay input without a running engine.

**Focus cycling** — `WorldDirector` tracks `_focus_index` and cycles `controlled_character` on the `change_focus` input action. The previously controlled character loses its highlight; the new one gains it.

## Spatial

**Direction** — 8-directional enum: `NORTH`, `NORTHEAST`, `EAST`, `SOUTHEAST`, `SOUTH`, `SOUTHWEST`, `WEST`, `NORTHWEST`. Used for both facing and animation name selection. Canonical conversion: `Global.direction_from_vector(vec)`.

**NavigationTarget** — An abstract `RefCounted` base with two methods: `get_position() -> Vector2` and `is_valid() -> bool`. The seam between "what a character is moving toward" and how that target is represented. Concrete adapters: `PositionTarget` (wraps a fixed `Vector2`, always valid) and `NodeTarget` (wraps a `Node2D`, valid while the node exists in the scene tree). `Character.navigation_target` is null when the character has no target; set via `set_target(target)`, cleared via `clear_target()`.

## Furniture

**Furniture** — Base class for all furniture pieces (`extends Node2D`, `class_name Furniture`, defined in `Furniture.gd`). Reads a `FurnitureDefinition` resource at `_ready()` to apply sprite variant and construct runtime `FurnitureHotspot` instances. Owns `get_hotspots()` and `get_footprint_rect()`. All furniture types share this single script — no subclasses.

**FurnitureDefinition** — A `Resource` holding all static config for a furniture type (`class_name FurnitureDefinition`, defined in `FurnitureDefinition.gd`). Fields: `sprite_w`, `sprite_h`, `columns` (0 = horizontal strip, 1 = vertical strip, N = N-column grid), `footprint_size` (non-zero enables `get_footprint_rect()` for floor detection), and `hotspot_specs`. One `.tres` file per furniture type lives in `resources/furniture/`.

**HotspotSpec** — A `Resource` holding the static definition of one hotspot on a piece of furniture (`class_name HotspotSpec`, defined in `HotspotSpec.gd`). Fields: `action: FurnitureHotspot.ActionType` and `slots: Array[Vector2]`. Stored in `FurnitureDefinition.hotspot_specs`. `Furniture._ready()` reads each spec and constructs a fresh `FurnitureHotspot` instance from it, so runtime state (`_claimed`, `knocked`) is always per-instance and never shared across furniture pieces.

**FurnitureHotspot** — A `Resource` holding the runtime state of one hotspot (`class_name FurnitureHotspot`, defined in `FurnitureHotspot.gd`). Manages slot reservation (`claim`, `release`) and the `knocked` flag. Constructed at runtime by `Furniture._ready()` from `HotspotSpec` data — never shared between furniture instances.

## Rendering

**WorldLayer** — A `Node2D` with `y_sort_enabled = true` that parents all characters in the scene. Ensures characters lower on screen render in front of those higher up, simulating a top-down oblique perspective. All spawned characters are added here by `WorldDirector`. Future character types automatically get depth sorting by being added to `WorldLayer`.

## Animation

**StateAnimator** — The testability seam between states and Godot's animation engine (`extends Node`, `class_name StateAnimator`, defined in `StateAnimator.gd`). Declares the full animation interface as stub methods: `play_transition`, `play_loop`, `play_once`, `play_pose`, `hold_frame`, `cancel`, `pause`, `get_frame_count`, `get_playback_progress`, `change_direction_while_playing`, `set_modulate`, and the `animation_finished` signal. `CharacterBase.anim` is typed as `StateAnimator` so states depend only on this interface. In production, `anim` is an `AnimationController`. In tests, swap in a mock that extends `StateAnimator`.

**AnimationController** — The production adapter (`extends StateAnimator`, `class_name AnimationController`, defined in `AnimationController.gd`). Owns an `AnimatedSprite2D` reference and implements all `StateAnimator` methods against the Godot engine. Initialized via `setup(player: AnimatedSprite2D)`, called only from `Character._ready()`. `play_transition` is the preferred method for states that play a one-shot animation and need a callback on completion — it owns the `CONNECT_ONE_SHOT` signal connection so callers never manage signals directly. States with complex animation sequences (e.g., `LookAroundState`) may call `play_once` directly.

## Animation Convention

All character types must provide animations named: `"Sit"`, `"Walk"`, `"Run"`, `"Sprint"`, `"Lay"`, `"LookAround"`. States hardcode these names and rely on the convention being followed. A character that doesn't use certain activities sets their preference weight to 0 in its personality — the states are never entered. Future characters may provide a `get_anim_name(state)` virtual override if they need different names, but this is not yet implemented.
