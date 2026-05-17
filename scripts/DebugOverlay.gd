extends CanvasLayer
class_name DebugOverlay

# Which button IDs are enabled from each state name.
const ALLOWED: Dictionary = {
	"SIT":         ["look_around", "lay_down", "stand_up", "walk", "run", "sprint"],
	"STANDUP":     ["sit"],
	"WALK":        ["sit", "run", "sprint"],
	"RUN":         ["sit", "walk", "sprint"],
	"SPRINT":      ["sit", "walk", "run"],
	"LAY_DOWN":    ["sit_up", "walk", "run", "sprint"],
	"LAY":         ["sit_up", "walk", "run", "sprint"],
	"SITUP":       [],
	"LOOK_AROUND": ["stand_up", "walk", "run", "sprint"],
	"LOOK_TRACK":  ["stand_up", "walk", "run", "sprint"],
	"TURN":        [],
}

var _director: WorldDirector
var _last_state: String = ""
var _log_lines: Array[Dictionary] = []   # {text: String, source: String}
var _filter_ai:     bool = true
var _filter_player: bool = true
var _filter_btn:    bool = true
var _look_around_loop: bool = false
var _la_direction: int = Global.LookDirection.BOTH
var _la_speed: float = 1.0
var _la_pause_right: float = 0.0
var _la_pause_left: float = 0.0
var _la_pause_center: float = 0.0
var _la_reps: int = 1

var _panel: ColorRect
var _state_val: Label
var _facing_val: Label
var _target_val: Label
var _log_edit: TextEdit
var _buttons: Dictionary = {}  # id: String → Button

var _kitty_panel: ColorRect
var _kitty_panel_header: Label
var _kitty_controls: Array = []
var _last_kitty: Character = null
var _sep_draw: SeparationDebugDraw
var _palette_checks: Dictionary = {}   # family: String → CheckBox
var _marking_checks: Dictionary = {}   # path: String → CheckBox

func _ready() -> void:
	layer = 100
	_director = get_tree().root.find_child("WorldDirector", true, false) as WorldDirector
	if _director == null:
		push_error("DebugOverlay: WorldDirector not found in scene tree")
	_sep_draw = SeparationDebugDraw.new()
	_sep_draw.director = _director
	_sep_draw.visible = false
	add_child(_sep_draw)
	_build_kitty_panel()
	_kitty_panel.visible = false
	_build_ui()
	_panel.visible = false

func _refresh_panel_width() -> void:
	if _panel == null:
		return
	_panel.offset_right = -_kitty_panel.size.x if (_kitty_panel != null and _kitty_panel.visible) else 0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT:
			_panel.visible = not _panel.visible
			if not _panel.visible and _kitty_panel != null:
				_kitty_panel.visible = false
			_refresh_panel_width()
			get_viewport().set_input_as_handled()
		if event.keycode == KEY_BACKSLASH:
			if _panel.visible and _kitty_panel != null:
				_kitty_panel.visible = not _kitty_panel.visible
			_refresh_panel_width()
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not _panel.visible or _director == null or _director.controlled_character == null:
		return
	var character := _director.controlled_character
	var state_str: String = Global.StateName.keys()[character.state_machine.current_state_name()]

	_state_val.text = state_str
	_facing_val.text = Global.Direction.keys()[character.facing_direction]
	if character.navigation_target != null and character.navigation_target.is_valid():
		var p := character.navigation_target.get_position()
		_target_val.text = "(%d, %d)" % [int(p.x), int(p.y)]
	else:
		_target_val.text = "—"

	if state_str != _last_state:
		var elapsed := "%.1fs" % (Time.get_ticks_msec() / 1000.0)
		var source := "ai"
		if character == _director.controlled_character:
			if _director.input_handler != null and _director.input_handler.is_moving():
				source = "player"
		_append_log("[%s]  %s  →  %s" % [elapsed, _last_state if _last_state != "" else "START", state_str], source)
		_last_state = state_str

	_refresh_buttons(state_str)

	if _kitty_panel != null and _kitty_panel.visible:
		var current_kitty := _director.controlled_character if _director != null else null
		if current_kitty != _last_kitty:
			_last_kitty = current_kitty
			_rebind_kitty_panel()

func _refresh_buttons(state_str: String) -> void:
	var allowed: Array = ALLOWED.get(state_str, [])
	for id: String in _buttons:
		_buttons[id].disabled = not (id in allowed)

func _append_log(text: String, source: String = "sys") -> void:
	_log_lines.append({text = text, source = source})
	if _log_lines.size() > 200:
		_log_lines.remove_at(0)
	_refresh_log_display()

func _refresh_log_display() -> void:
	var lines: Array[String] = []
	for entry: Dictionary in _log_lines:
		var src: String = entry.source
		if src == "ai"     and not _filter_ai:     continue
		if src == "player" and not _filter_player: continue
		if src == "btn"    and not _filter_btn:    continue
		var prefix: String = match_source_prefix(src)
		lines.append(prefix + entry.text)
	_log_edit.text = "\n".join(lines)
	_log_edit.set_caret_line(_log_edit.get_line_count())

func match_source_prefix(src: String) -> String:
	match src:
		"ai":     return "[AI]     "
		"player": return "[PLAYER] "
		"btn":    return "[BTN]    "
		_:        return "[SYS]    "

# ── Kitty Controls Panel ──────────────────────────────────────────

const _FIELDS: Array = [
	["Activity Weights",
		["Walk weight",        "preference_walk",        "slider",  0.0, 1.0, 0.05],
		["Sit weight",         "preference_sit",         "slider",  0.0, 1.0, 0.05],
		["Lay weight",         "preference_lay",         "slider",  0.0, 1.0, 0.05],
		["Run weight",         "preference_run",         "slider",  0.0, 1.0, 0.05],
		["Look Around weight", "preference_look_around", "slider",  0.0, 1.0, 0.05],
		["Sprint weight",      "preference_sprint",      "slider",  0.0, 1.0, 0.05],
	],
	["Activity Durations (s)",
		["Walk dur",         "duration_walk",        "slider", 0.5, 15.0, 0.5],
		["Sit dur",          "duration_sit",         "slider", 0.5, 15.0, 0.5],
		["Lay dur",          "duration_lay",         "slider", 0.5, 15.0, 0.5],
		["Run dur",          "duration_run",         "slider", 0.5, 10.0, 0.5],
		["Look Around dur",  "duration_look_around", "slider", 0.5, 10.0, 0.5],
		["Sprint dur",       "duration_sprint",      "slider", 0.5,  5.0, 0.25],
	],
	["Fatigue",
		["Rest threshold",     "rest_threshold",     "slider", 0.5, 30.0, 0.5],
		["Walk target chance", "walk_target_chance", "slider", 0.0,  1.0, 0.05],
	],
	["Movement",
		["Run speed ×",    "run_speed_multiplier",    "slider", 0.5, 5.0, 0.1],
		["Sprint speed ×", "sprint_speed_multiplier", "slider", 0.5, 5.0, 0.1],
	],
	["Look Around",
		["Direction",      "look_around_direction",    "option",  ["Both", "Left only", "Right only"]],
		["Speed",          "look_around_speed",         "slider",  0.2, 3.0, 0.1],
		["Pause right",    "look_around_pause_right",   "slider",  0.0, 5.0, 0.1],
		["Pause left",     "look_around_pause_left",    "slider",  0.0, 5.0, 0.1],
		["Pause center",   "look_around_pause_center",  "slider",  0.0, 5.0, 0.1],
		["Repetitions",    "look_around_repetitions",   "spinbox", 1.0, 10.0, 1.0],
	],
]

func _build_kitty_panel() -> void:
	_kitty_panel = ColorRect.new()
	_kitty_panel.color = Color(0.04, 0.06, 0.04, 0.95)
	_kitty_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_kitty_panel.custom_minimum_size = Vector2(260, 0)
	_kitty_panel.offset_left = -260
	_kitty_panel.offset_right = 0
	add_child(_kitty_panel)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		outer.add_theme_constant_override("margin_" + side, 8)
	_kitty_panel.add_child(outer)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	outer.add_child(vbox)

	var header_row := HBoxContainer.new()
	vbox.add_child(header_row)
	_kitty_panel_header = _label("KITTY CONTROLS  (\\)", 9, Color(0.4, 0.75, 0.4))
	_kitty_panel_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(_kitty_panel_header)
	var copy_btn := _small_button("Copy", _copy_personality)
	header_row.add_child(copy_btn)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var scroll_vbox := VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 3)
	scroll.add_child(scroll_vbox)

	for group_def: Array in _FIELDS:
		var group_name: String = group_def[0]
		var grp_label := _label(group_name, 8, Color(0.5, 0.75, 0.5))
		scroll_vbox.add_child(grp_label)

		for i in range(1, group_def.size()):
			var field: Array = group_def[i]
			var display: String = field[0]
			var prop: String    = field[1]
			var ftype: String   = field[2]

			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			scroll_vbox.add_child(row)

			var lbl := _label(display, 9, Color(0.5, 0.6, 0.5))
			lbl.custom_minimum_size = Vector2(90, 0)
			row.add_child(lbl)

			var prop_captured: String = prop

			if ftype == "slider":
				var sl := HSlider.new()
				sl.min_value = field[3]; sl.max_value = field[4]; sl.step = field[5]
				sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				sl.custom_minimum_size = Vector2(0, 16)
				var val_lbl := Label.new()
				val_lbl.add_theme_font_size_override("font_size", 9)
				val_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.6))
				val_lbl.custom_minimum_size = Vector2(30, 0)
				val_lbl.text = "—"
				sl.value_changed.connect(func(v: float) -> void:
					val_lbl.text = "%.2f" % v
					_set_personality_prop(prop_captured, v)
				)
				row.add_child(sl)
				row.add_child(val_lbl)
				_kitty_controls.append({prop=prop, type="slider", widget=sl, val_label=val_lbl})

			elif ftype == "spinbox":
				var sp := SpinBox.new()
				sp.min_value = field[3]; sp.max_value = field[4]; sp.step = field[5]
				sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				sp.add_theme_font_size_override("font_size", 10)
				sp.value_changed.connect(func(v: float) -> void:
					_set_personality_prop(prop_captured, int(v))
				)
				row.add_child(sp)
				_kitty_controls.append({prop=prop, type="spinbox", widget=sp, val_label=null})

			elif ftype == "option":
				var opt := OptionButton.new()
				var items: Array = field[3]
				for idx in items.size():
					opt.add_item(items[idx], idx)
				opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				opt.add_theme_font_size_override("font_size", 10)
				opt.item_selected.connect(func(idx: int) -> void:
					_set_personality_prop(prop_captured, opt.get_item_id(idx))
				)
				row.add_child(opt)
				_kitty_controls.append({prop=prop, type="option", widget=opt, val_label=null})

func _rebind_kitty_panel() -> void:
	var kitty: Character =_director.controlled_character if _director != null else null
	if kitty == null or kitty.personality == null:
		_kitty_panel_header.text = "KITTY CONTROLS — no kitty"
		return
	_kitty_panel_header.text = "KITTY CONTROLS — %s  (Tab)" % kitty.name
	var p := kitty.personality
	for entry: Dictionary in _kitty_controls:
		var val: Variant = p.get(entry.prop)
		if val == null:
			continue
		match entry.type:
			"slider":
				entry.widget.set_value_no_signal(float(val))
				if entry.val_label:
					entry.val_label.text = "%.2f" % float(val)
			"spinbox":
				entry.widget.set_value_no_signal(float(val))
			"option":
				var opt: OptionButton = entry.widget
				for i in opt.item_count:
					if opt.get_item_id(i) == int(val):
						opt.selected = i
						break

func _set_personality_prop(prop: String, value: Variant) -> void:
	var k: Character = _character()
	if k == null or k.personality == null:
		return
	k.personality.set(prop, value)
	var brain: ActivityBrain = _director.brains.get(k) if _director != null else null
	if brain != null:
		brain.refresh_personality(k.personality)

func _copy_personality() -> void:
	var k: Character = _character()
	if k == null or k.personality == null:
		_append_log("[COPY] No kitty selected", "btn")
		return
	var p := k.personality
	var lines: Array[String] = []
	lines.append("# Personality profile: %s" % k.name)
	lines.append("")
	for group_def: Array in _FIELDS:
		lines.append("[%s]" % group_def[0])
		for i in range(1, group_def.size()):
			var field: Array = group_def[i]
			var prop: String = field[1]
			var val: Variant = p.get(prop)
			if field[2] == "option":
				var items: Array = field[3]
				var idx: int = int(val)
				var label: String = items[idx] if idx < items.size() else str(val)
				lines.append("  %s = %s" % [prop, label])
			elif field[2] == "spinbox":
				lines.append("  %s = %d" % [prop, int(val)])
			else:
				lines.append("  %s = %.3f" % [prop, float(val)])
		lines.append("")
	var text := "\n".join(lines).strip_edges()
	DisplayServer.clipboard_set(text)
	_append_log("[COPY] %s personality copied to clipboard" % k.name, "btn")

# ── UI construction ───────────────────────────────────────────────

func _build_ui() -> void:
	_panel = ColorRect.new()
	_panel.color = Color(0.04, 0.04, 0.09, 0.93)
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.custom_minimum_size = Vector2(0, 380)
	_panel.offset_top = -380
	_panel.offset_bottom = 0
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	_panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)

	hbox.add_child(_build_buttons())
	hbox.add_child(VSeparator.new())
	hbox.add_child(_build_status_and_log())

func _build_buttons() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(165, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	scroll.add_child(vbox)
	vbox.add_child(_label("FORCE TRIGGER  (` toggle)", 9, Color(0.5, 0.5, 0.75)))

	# id, label, handler
	var defs: Array = [
		["sit",         "Sit",              _on_btn_sit],
		["lay_down",    "Lay Down",         _on_btn_lay_down],
		["sit_up",      "Sit Up",           _on_btn_sit_up],
		["stand_up",    "Stand Up",         _on_btn_stand_up],
		["walk",        "Walk to random",   _on_btn_walk],
		["run",         "Run to random",    _on_btn_run],
		["sprint",      "Sprint to random", _on_btn_sprint],
	]
	for d in defs:
		var btn := Button.new()
		btn.text = d[1]
		btn.pressed.connect(d[2])
		btn.add_theme_font_size_override("font_size", 11)
		btn.disabled = true
		vbox.add_child(btn)
		_buttons[d[0]] = btn

	# Look Around row — button + loop checkbox
	var la_row := HBoxContainer.new()
	la_row.add_theme_constant_override("separation", 4)
	vbox.add_child(la_row)

	var la_btn := Button.new()
	la_btn.text = "Look Around"
	la_btn.pressed.connect(_on_btn_look_around)
	la_btn.add_theme_font_size_override("font_size", 11)
	la_btn.disabled = true
	la_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	la_row.add_child(la_btn)
	_buttons["look_around"] = la_btn

	var la_check := CheckBox.new()
	la_check.text = "loop"
	la_check.add_theme_font_size_override("font_size", 10)
	la_check.toggled.connect(func(on: bool) -> void: _look_around_loop = on)
	la_row.add_child(la_check)

	var la_cfg := VBoxContainer.new()
	la_cfg.add_theme_constant_override("separation", 2)
	vbox.add_child(la_cfg)

	var dir_row := HBoxContainer.new()
	dir_row.add_theme_constant_override("separation", 4)
	la_cfg.add_child(dir_row)
	dir_row.add_child(_label("Dir", 9, Color(0.4, 0.4, 0.55)))
	var dir_opt := OptionButton.new()
	dir_opt.add_item("Both",       Global.LookDirection.BOTH)
	dir_opt.add_item("Left only",  Global.LookDirection.LEFT_ONLY)
	dir_opt.add_item("Right only", Global.LookDirection.RIGHT_ONLY)
	dir_opt.add_theme_font_size_override("font_size", 10)
	dir_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dir_opt.item_selected.connect(func(idx: int) -> void: _la_direction = dir_opt.get_item_id(idx))
	dir_row.add_child(dir_opt)

	var slider_rows: Array = [
		["Speed",    0.2, 3.0, 0.1, 1.0, func(v: float) -> void: _la_speed        = v],
		["P.Right",  0.0, 3.0, 0.1, 0.0, func(v: float) -> void: _la_pause_right  = v],
		["P.Left",   0.0, 3.0, 0.1, 0.0, func(v: float) -> void: _la_pause_left   = v],
		["P.Center", 0.0, 3.0, 0.1, 0.0, func(v: float) -> void: _la_pause_center = v],
	]
	for sr: Array in slider_rows:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		la_cfg.add_child(row)
		row.add_child(_label(sr[0], 9, Color(0.4, 0.4, 0.55)))
		var sl := HSlider.new()
		sl.min_value = sr[1]; sl.max_value = sr[2]; sl.step = sr[3]; sl.value = sr[4]
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.custom_minimum_size = Vector2(0, 16)
		var val_lbl := Label.new()
		val_lbl.text = "%.1f" % sr[4]
		val_lbl.add_theme_font_size_override("font_size", 9)
		val_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
		val_lbl.custom_minimum_size = Vector2(24, 0)
		var cb: Callable = sr[5]
		sl.value_changed.connect(func(v: float) -> void:
			cb.call(v)
			val_lbl.text = "%.1f" % v
		)
		row.add_child(sl)
		row.add_child(val_lbl)

	var reps_row := HBoxContainer.new()
	reps_row.add_theme_constant_override("separation", 4)
	la_cfg.add_child(reps_row)
	reps_row.add_child(_label("Reps", 9, Color(0.4, 0.4, 0.55)))
	var reps_spin := SpinBox.new()
	reps_spin.min_value = 1; reps_spin.max_value = 10; reps_spin.value = 1
	reps_spin.add_theme_font_size_override("font_size", 10)
	reps_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reps_spin.value_changed.connect(func(v: float) -> void: _la_reps = int(v))
	reps_row.add_child(reps_spin)

	vbox.add_child(HSeparator.new())
	_build_palette_section(vbox)
	vbox.add_child(HSeparator.new())
	_build_marking_section(vbox)
	vbox.add_child(HSeparator.new())

	var sep_check := CheckBox.new()
	sep_check.text = "Separation radius"
	sep_check.add_theme_font_size_override("font_size", 10)
	sep_check.toggled.connect(func(on: bool) -> void: _sep_draw.visible = on)
	vbox.add_child(sep_check)

	vbox.add_child(_label("Separation Tuning", 8, Color(0.4, 0.4, 0.55)))

	var sep_sliders: Array = [
		["Radius",    16.0, 256.0, 4.0,  32.0,  "%.0f",  func(v: float) -> void: if _director: _director.separation_system.separation_radius          = v],
		["Strength",  0.0,  400.0, 10.0, 120.0, "%.0f",  func(v: float) -> void: if _director: _director.separation_system.separation_strength        = v],
		["Rest Push", 0.0,  100.0, 5.0,  20.0,  "%.0f",  func(v: float) -> void: if _director: _director.separation_system.rest_push_strength         = v],
		["Nudge %",   0.0,  0.5,   0.01, 0.1,   "%.2f",  func(v: float) -> void: if _director: _director.separation_system.max_speed_nudge_fraction   = v],
	]
	for ss: Array in sep_sliders:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		vbox.add_child(row)
		var lbl := _label(ss[0], 9, Color(0.4, 0.4, 0.55))
		lbl.custom_minimum_size = Vector2(52, 0)
		row.add_child(lbl)
		var sl := HSlider.new()
		sl.min_value = ss[1]; sl.max_value = ss[2]; sl.step = ss[3]; sl.value = ss[4]
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.custom_minimum_size = Vector2(0, 16)
		var fmt: String = ss[5]
		var val_lbl := Label.new()
		val_lbl.text = fmt % ss[4]
		val_lbl.add_theme_font_size_override("font_size", 9)
		val_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
		val_lbl.custom_minimum_size = Vector2(28, 0)
		var cb: Callable = ss[6]
		sl.value_changed.connect(func(v: float) -> void:
			val_lbl.text = fmt % v
			cb.call(v)
		)
		row.add_child(sl)
		row.add_child(val_lbl)

	return scroll

func _build_palette_section(parent: VBoxContainer) -> void:
	parent.add_child(_label("SPAWN PALETTE", 8, Color(0.4, 0.55, 0.4)))

	var all_none_row := HBoxContainer.new()
	all_none_row.add_theme_constant_override("separation", 4)
	parent.add_child(all_none_row)

	var all_btn := _small_button("All", func() -> void:
		if _director and _director.color_pool:
			_director.color_pool.set_all_enabled(true)
			for cb: CheckBox in _palette_checks.values():
				cb.button_pressed = true
	)
	all_none_row.add_child(all_btn)

	var none_btn := _small_button("None", func() -> void:
		if _director and _director.color_pool:
			_director.color_pool.set_all_enabled(false)
			for cb: CheckBox in _palette_checks.values():
				cb.button_pressed = false
	)
	all_none_row.add_child(none_btn)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 1)
	parent.add_child(grid)

	var families: Array = []
	if _director != null and _director.color_pool != null:
		families = _director.color_pool.get_families()

	for family: String in families:
		var family_captured: String = family
		var cb := CheckBox.new()
		cb.text = family.replace("_", " ")
		cb.button_pressed = true
		cb.add_theme_font_size_override("font_size", 9)
		cb.toggled.connect(func(on: bool) -> void:
			if _director and _director.color_pool:
				_director.color_pool.set_enabled(family_captured, on)
		)
		grid.add_child(cb)
		_palette_checks[family] = cb

func _build_marking_section(parent: VBoxContainer) -> void:
	parent.add_child(_label("MARKING OVERLAY", 8, Color(0.4, 0.55, 0.4)))

	var prob_row := HBoxContainer.new()
	prob_row.add_theme_constant_override("separation", 4)
	parent.add_child(prob_row)
	prob_row.add_child(_label("Prob", 9, Color(0.4, 0.4, 0.55)))
	var prob_sl := HSlider.new()
	prob_sl.min_value = 0.0; prob_sl.max_value = 1.0; prob_sl.step = 0.05; prob_sl.value = 0.3
	prob_sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prob_sl.custom_minimum_size = Vector2(0, 16)
	var prob_lbl := Label.new()
	prob_lbl.text = "0.30"
	prob_lbl.add_theme_font_size_override("font_size", 9)
	prob_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
	prob_lbl.custom_minimum_size = Vector2(28, 0)
	prob_sl.value_changed.connect(func(v: float) -> void:
		prob_lbl.text = "%.2f" % v
		if _director: _director.marking_probability = v
	)
	prob_row.add_child(prob_sl)
	prob_row.add_child(prob_lbl)

	var all_none_row := HBoxContainer.new()
	all_none_row.add_theme_constant_override("separation", 4)
	parent.add_child(all_none_row)

	all_none_row.add_child(_small_button("All", func() -> void:
		if _director and _director.marking_pool:
			_director.marking_pool.set_all_enabled(true)
			for cb: CheckBox in _marking_checks.values():
				cb.button_pressed = true
	))
	all_none_row.add_child(_small_button("None", func() -> void:
		if _director and _director.marking_pool:
			_director.marking_pool.set_all_enabled(false)
			for cb: CheckBox in _marking_checks.values():
				cb.button_pressed = false
	))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 1)
	parent.add_child(grid)

	var markings: Array[String] = []
	if _director != null and _director.marking_pool != null:
		markings = _director.marking_pool.get_all()

	for path: String in markings:
		var path_captured: String = path
		var cb := CheckBox.new()
		cb.text = _director.marking_pool.get_label(path) if _director and _director.marking_pool else path.get_file()
		cb.button_pressed = true
		cb.add_theme_font_size_override("font_size", 9)
		cb.toggled.connect(func(on: bool) -> void:
			if _director and _director.marking_pool:
				_director.marking_pool.set_enabled(path_captured, on)
		)
		grid.add_child(cb)
		_marking_checks[path] = cb

func _build_status_and_log() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(_label("STATUS", 9, Color(0.5, 0.5, 0.75)))

	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 20)
	vbox.add_child(stat_row)
	_state_val  = _stat_block(stat_row, "State")
	_facing_val = _stat_block(stat_row, "Facing")
	_target_val = _stat_block(stat_row, "Target")

	var log_row := HBoxContainer.new()
	vbox.add_child(log_row)
	var log_lbl := _label("TRANSITION LOG", 9, Color(0.5, 0.5, 0.75))
	log_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_row.add_child(log_lbl)
	log_row.add_child(_small_button("Copy",  _on_copy))
	log_row.add_child(_small_button("Clear", _on_clear))

	var filters: Array = [
		["AI",     func(on: bool) -> void: _filter_ai     = on; _refresh_log_display()],
		["Player", func(on: bool) -> void: _filter_player = on; _refresh_log_display()],
		["Btn",    func(on: bool) -> void: _filter_btn    = on; _refresh_log_display()],
	]
	for f: Array in filters:
		var cb := CheckBox.new()
		cb.text = f[0]
		cb.button_pressed = true
		cb.add_theme_font_size_override("font_size", 9)
		cb.toggled.connect(f[1])
		log_row.add_child(cb)

	_log_edit = TextEdit.new()
	_log_edit.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_log_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_edit.editable = false
	_log_edit.selecting_enabled = true
	_log_edit.add_theme_font_size_override("font_size", 11)
	_log_edit.add_theme_color_override("font_color", Color(0.65, 0.9, 0.65))
	vbox.add_child(_log_edit)

	return vbox

func _label(txt: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _stat_block(parent: HBoxContainer, caption: String) -> Label:
	var vb := VBoxContainer.new()
	parent.add_child(vb)
	vb.add_child(_label(caption, 9, Color(0.4, 0.4, 0.55)))
	var val := Label.new()
	val.text = "—"
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", Color(0.95, 0.95, 0.6))
	vb.add_child(val)
	return val

func _small_button(txt: String, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.add_theme_font_size_override("font_size", 10)
	btn.pressed.connect(cb)
	return btn

# ── Helpers ───────────────────────────────────────────────────────

func _character() -> Character:
	return _director.controlled_character if _director != null else null

func _random_pos() -> Vector2:
	var r := get_viewport().get_visible_rect()
	return Vector2(
		randf_range(r.position.x + 80.0, r.end.x - 80.0),
		randf_range(r.position.y + 80.0, r.end.y - 80.0)
	)

func _force(label: String, state: State) -> void:
	var k: Character = _character()
	if k == null:
		return
	_append_log("[BTN] %s" % label, "btn")
	k.change_state(state)

# ── Button handlers ───────────────────────────────────────────────

func _on_btn_sit() -> void:
	_force("→ Sit", SitState.new())

func _on_btn_look_around() -> void:
	var k: Character = _character()
	if k == null:
		return
	var loop_label := " (loop)" if _look_around_loop else ""
	_append_log("[BTN] → LookAround%s  dir=%s  speed=%.1f  reps=%d" % [loop_label, Global.LookDirection.keys()[_la_direction], _la_speed, _la_reps], "btn")
	k.change_state(LookAroundState.new(null, _look_around_loop, _la_direction, _la_speed, _la_pause_right, _la_pause_left, _la_pause_center, _la_reps))

func _on_btn_lay_down() -> void:
	_force("→ LayDown → Lay", LayDownState.new(LayState.new()))

func _on_btn_sit_up() -> void:
	_force("→ SitUp → Sit", SitUpState.new(SitState.new(true, true)))

func _on_btn_stand_up() -> void:
	_force("→ StandUp → Sit", StandUpState.new(SitState.new()))

func _on_btn_walk() -> void:
	var k: Character = _character()
	if k == null:
		return
	_append_log("[BTN] → Walk to random", "btn")
	k.set_target(PositionTarget.new(_random_pos()))
	k.begin_walk()

func _on_btn_run() -> void:
	var k: Character = _character()
	if k == null:
		return
	_append_log("[BTN] → Run to random", "btn")
	k.set_target(PositionTarget.new(_random_pos()))
	k.begin_run()

func _on_btn_sprint() -> void:
	var k: Character = _character()
	if k == null:
		return
	_append_log("[BTN] → Sprint to random", "btn")
	k.set_target(PositionTarget.new(_random_pos()))
	k.begin_sprint()

func _on_copy() -> void:
	DisplayServer.clipboard_set(_log_edit.text)
	_append_log("Copied %d visible lines to clipboard" % _log_edit.get_line_count(), "btn")

func _on_clear() -> void:
	_log_lines.clear()
	_log_edit.text = ""
	_last_state = ""
