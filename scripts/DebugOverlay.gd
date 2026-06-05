extends CanvasLayer
class_name DebugOverlay

const ALLOWED: Dictionary = {
	"SIT":         ["look_around", "lay_down", "stand_up", "walk", "run", "sprint"],
	"STANDUP":     ["sit"],
	"WALK":        ["sit", "run", "sprint"],
	"RUN":         ["sit", "walk", "sprint"],
	"SPRINT":      ["sit", "walk", "run"],
	"STAND_IDLE":  ["sit", "walk", "run", "sprint"],
	"LAY_DOWN":    ["sit_up", "walk", "run", "sprint"],
	"LAY":         ["sit_up", "walk", "run", "sprint"],
	"SITUP":       [],
	"LOOK_AROUND": ["stand_up", "walk", "run", "sprint"],
	"LOOK_TRACK":  ["stand_up", "walk", "run", "sprint"],
	"TURN":        [],
}

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
		["Walk dur",        "duration_walk",        "slider", 0.5, 15.0, 0.5],
		["Sit dur",         "duration_sit",         "slider", 0.5, 15.0, 0.5],
		["Lay dur",         "duration_lay",         "slider", 0.5, 15.0, 0.5],
		["Run dur",         "duration_run",         "slider", 0.5, 10.0, 0.5],
		["Look Around dur", "duration_look_around", "slider", 0.5, 10.0, 0.5],
		["Sprint dur",      "duration_sprint",      "slider", 0.5,  5.0, 0.25],
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
		["Direction",    "look_around_direction",   "option",  ["Both", "Left only", "Right only"]],
		["Speed",        "look_around_speed",        "slider",  0.2, 3.0, 0.1],
		["Pause right",  "look_around_pause_right",  "slider",  0.0, 5.0, 0.1],
		["Pause left",   "look_around_pause_left",   "slider",  0.0, 5.0, 0.1],
		["Pause center", "look_around_pause_center", "slider",  0.0, 5.0, 0.1],
		["Repetitions",  "look_around_repetitions",  "spinbox", 1.0, 10.0, 1.0],
	],
]

var _director: WorldDirector
var _last_state: String = ""
var _log_lines: Array[Dictionary] = []
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
var _tab_container: TabContainer
var _char_val: Label
var _state_val: Label
var _facing_val: Label
var _target_val: Label
var _log_edit: TextEdit
var _buttons: Dictionary = {}
var _kitty_controls: Array = []
var _last_kitty: Character = null
var _char_tab_header: Label
var _palette_checks: Dictionary = {}
var _marking_checks: Dictionary = {}
var _sep_draw: SeparationDebugDraw
var _furniture_text: TextEdit

func _ready() -> void:
	layer = 100
	_director = get_tree().root.find_child("WorldDirector", true, false) as WorldDirector
	if _director == null:
		push_error("DebugOverlay: WorldDirector not found in scene tree")
	_sep_draw = SeparationDebugDraw.new()
	_sep_draw.director = _director
	_sep_draw.visible = false
	add_child(_sep_draw)
	_build_ui()
	_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT:
			_panel.visible = not _panel.visible
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not _panel.visible or _director == null or _director.controlled_character == null:
		return
	var character := _director.controlled_character
	var state_str: String = Global.StateName.keys()[character.state_machine.current_state_name()]

	_char_val.text   = character.name
	_state_val.text  = state_str
	_facing_val.text = Global.Direction.keys()[character.facing_direction]
	if character.navigation_target != null and character.navigation_target.is_valid():
		var p := character.navigation_target.get_position()
		_target_val.text = "(%d, %d)" % [int(p.x), int(p.y)]
	else:
		_target_val.text = "—"

	if state_str != _last_state:
		var elapsed := "%.1fs" % (Time.get_ticks_msec() / 1000.0)
		var source := "player" if (_director.input_handler != null and _director.input_handler.is_moving()) else "ai"
		_append_log("[%s]  %s  →  %s" % [elapsed, _last_state if _last_state != "" else "START", state_str], source)
		_last_state = state_str

	_refresh_buttons(state_str)

	if _tab_container != null and _tab_container.current_tab == 1:
		var cur := _director.controlled_character
		if cur != _last_kitty:
			_last_kitty = cur
			_rebind_character_tab()

	if _tab_container != null and _tab_container.current_tab == 4:
		_refresh_furniture_tab(character)

# ── UI construction ───────────────────────────────────────────────

func _build_ui() -> void:
	_panel = ColorRect.new()
	_panel.color = Color(0.04, 0.04, 0.09, 0.93)
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.custom_minimum_size = Vector2(0, 420)
	_panel.offset_top    = -420
	_panel.offset_bottom = 0
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	margin.add_child(root)

	root.add_child(_build_status_strip())
	root.add_child(HSeparator.new())

	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.add_theme_font_size_override("font_size", 10)
	_tab_container.tab_changed.connect(_on_tab_changed)
	root.add_child(_tab_container)

	_tab_container.add_child(_build_control_tab())
	_tab_container.add_child(_build_character_tab())
	_tab_container.add_child(_build_spawn_tab())
	_tab_container.add_child(_build_world_tab())
	_tab_container.add_child(_build_furniture_tab())

func _build_status_strip() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	_char_val   = _stat_block(row, "Character")
	_state_val  = _stat_block(row, "State")
	_facing_val = _stat_block(row, "Facing")
	_target_val = _stat_block(row, "Target")
	return row

# ── Control tab ───────────────────────────────────────────────────

func _build_control_tab() -> HBoxContainer:
	var tab := HBoxContainer.new()
	tab.name = "Control"
	tab.add_theme_constant_override("separation", 12)
	tab.add_child(_build_trigger_column())
	tab.add_child(VSeparator.new())
	tab.add_child(_build_log_column())
	return tab

func _build_trigger_column() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(165, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	scroll.add_child(vbox)

	vbox.add_child(_label("FORCE TRIGGER", 9, Color(0.5, 0.5, 0.75)))

	for d: Array in [
		["sit",      "Sit",              _on_btn_sit],
		["lay_down", "Lay Down",         _on_btn_lay_down],
		["sit_up",   "Sit Up",           _on_btn_sit_up],
		["stand_up", "Stand Up",         _on_btn_stand_up],
		["walk",     "Walk to random",   _on_btn_walk],
		["run",      "Run to random",    _on_btn_run],
		["sprint",   "Sprint to random", _on_btn_sprint],
	]:
		var btn := Button.new()
		btn.text = d[1]
		btn.pressed.connect(d[2])
		btn.add_theme_font_size_override("font_size", 11)
		btn.disabled = true
		vbox.add_child(btn)
		_buttons[d[0]] = btn

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
	var la_loop := CheckBox.new()
	la_loop.text = "loop"
	la_loop.add_theme_font_size_override("font_size", 10)
	la_loop.toggled.connect(func(on: bool) -> void: _look_around_loop = on)
	la_row.add_child(la_loop)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_label("LOOK AROUND", 8, Color(0.4, 0.4, 0.55)))

	var dir_row := HBoxContainer.new()
	dir_row.add_theme_constant_override("separation", 4)
	vbox.add_child(dir_row)
	dir_row.add_child(_label("Dir", 9, Color(0.4, 0.4, 0.55)))
	var dir_opt := OptionButton.new()
	dir_opt.add_item("Both",       Global.LookDirection.BOTH)
	dir_opt.add_item("Left only",  Global.LookDirection.LEFT_ONLY)
	dir_opt.add_item("Right only", Global.LookDirection.RIGHT_ONLY)
	dir_opt.add_theme_font_size_override("font_size", 10)
	dir_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dir_opt.item_selected.connect(func(idx: int) -> void: _la_direction = dir_opt.get_item_id(idx))
	dir_row.add_child(dir_opt)

	for sr: Array in [
		["Speed",    0.2, 3.0, 0.1, 1.0, func(v: float) -> void: _la_speed        = v],
		["P.Right",  0.0, 3.0, 0.1, 0.0, func(v: float) -> void: _la_pause_right  = v],
		["P.Left",   0.0, 3.0, 0.1, 0.0, func(v: float) -> void: _la_pause_left   = v],
		["P.Center", 0.0, 3.0, 0.1, 0.0, func(v: float) -> void: _la_pause_center = v],
	]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		vbox.add_child(row)
		row.add_child(_label(sr[0], 9, Color(0.4, 0.4, 0.55)))
		var sl := HSlider.new()
		sl.min_value = sr[1]; sl.max_value = sr[2]; sl.step = sr[3]; sl.value = sr[4]
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.custom_minimum_size = Vector2(0, 16)
		var vl := Label.new()
		vl.text = "%.1f" % sr[4]
		vl.add_theme_font_size_override("font_size", 9)
		vl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
		vl.custom_minimum_size = Vector2(24, 0)
		var cb: Callable = sr[5]
		sl.value_changed.connect(func(v: float) -> void: cb.call(v); vl.text = "%.1f" % v)
		row.add_child(sl)
		row.add_child(vl)

	var reps_row := HBoxContainer.new()
	reps_row.add_theme_constant_override("separation", 4)
	vbox.add_child(reps_row)
	reps_row.add_child(_label("Reps", 9, Color(0.4, 0.4, 0.55)))
	var reps_spin := SpinBox.new()
	reps_spin.min_value = 1; reps_spin.max_value = 10; reps_spin.value = 1
	reps_spin.add_theme_font_size_override("font_size", 10)
	reps_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reps_spin.value_changed.connect(func(v: float) -> void: _la_reps = int(v))
	reps_row.add_child(reps_spin)

	return scroll

func _build_log_column() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)

	var log_row := HBoxContainer.new()
	vbox.add_child(log_row)
	var log_lbl := _label("TRANSITION LOG", 9, Color(0.5, 0.5, 0.75))
	log_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_row.add_child(log_lbl)
	log_row.add_child(_small_button("Copy",  _on_copy))
	log_row.add_child(_small_button("Clear", _on_clear))
	for f: Array in [
		["AI",     func(on: bool) -> void: _filter_ai     = on; _refresh_log_display()],
		["Player", func(on: bool) -> void: _filter_player = on; _refresh_log_display()],
		["Btn",    func(on: bool) -> void: _filter_btn    = on; _refresh_log_display()],
	]:
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

# ── Character tab ─────────────────────────────────────────────────

func _build_character_tab() -> VBoxContainer:
	var tab := VBoxContainer.new()
	tab.name = "Character"
	tab.add_theme_constant_override("separation", 4)

	var header_row := HBoxContainer.new()
	tab.add_child(header_row)
	_char_tab_header = _label("No character selected", 9, Color(0.4, 0.75, 0.4))
	_char_tab_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(_char_tab_header)
	header_row.add_child(_small_button("Copy", _copy_personality))
	tab.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab.add_child(scroll)

	var scroll_vbox := VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 3)
	scroll.add_child(scroll_vbox)

	for group_def: Array in _FIELDS:
		scroll_vbox.add_child(_label(group_def[0], 8, Color(0.5, 0.75, 0.5)))
		for i in range(1, group_def.size()):
			var field: Array  = group_def[i]
			var prop: String  = field[1]
			var ftype: String = field[2]
			var prop_captured: String = prop

			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			scroll_vbox.add_child(row)
			var lbl := _label(field[0], 9, Color(0.5, 0.6, 0.5))
			lbl.custom_minimum_size = Vector2(110, 0)
			row.add_child(lbl)

			if ftype == "slider":
				var sl := HSlider.new()
				sl.min_value = field[3]; sl.max_value = field[4]; sl.step = field[5]
				sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				sl.custom_minimum_size = Vector2(0, 16)
				var vl := Label.new()
				vl.add_theme_font_size_override("font_size", 9)
				vl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.6))
				vl.custom_minimum_size = Vector2(30, 0)
				vl.text = "—"
				sl.value_changed.connect(func(v: float) -> void:
					vl.text = "%.2f" % v
					_set_personality_prop(prop_captured, v)
				)
				row.add_child(sl)
				row.add_child(vl)
				_kitty_controls.append({prop=prop, type="slider", widget=sl, val_label=vl})

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
				for idx in (field[3] as Array).size():
					opt.add_item(field[3][idx], idx)
				opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				opt.add_theme_font_size_override("font_size", 10)
				opt.item_selected.connect(func(idx: int) -> void:
					_set_personality_prop(prop_captured, opt.get_item_id(idx))
				)
				row.add_child(opt)
				_kitty_controls.append({prop=prop, type="option", widget=opt, val_label=null})

	return tab

func _rebind_character_tab() -> void:
	var character: Character = _director.controlled_character if _director != null else null
	if character == null or character.personality == null:
		_char_tab_header.text = "No character selected"
		return
	_char_tab_header.text = "%s  —  Tab to switch" % character.name
	var p := character.personality
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

# ── Spawn tab ─────────────────────────────────────────────────────

func _build_spawn_tab() -> HBoxContainer:
	var tab := HBoxContainer.new()
	tab.name = "Spawn"
	tab.add_theme_constant_override("separation", 16)

	# Colors — left, expands
	var cv := VBoxContainer.new()
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.add_theme_constant_override("separation", 4)
	tab.add_child(cv)

	cv.add_child(_label("COLOR VARIANTS", 8, Color(0.4, 0.55, 0.4)))
	var c_btns := HBoxContainer.new()
	c_btns.add_theme_constant_override("separation", 4)
	cv.add_child(c_btns)
	c_btns.add_child(_small_button("All", func() -> void:
		if _director and _director.color_pool:
			_director.color_pool.set_all_enabled(true)
			for cb: CheckBox in _palette_checks.values(): cb.button_pressed = true
	))
	c_btns.add_child(_small_button("None", func() -> void:
		if _director and _director.color_pool:
			_director.color_pool.set_all_enabled(false)
			for cb: CheckBox in _palette_checks.values(): cb.button_pressed = false
	))

	var c_scroll := ScrollContainer.new()
	c_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cv.add_child(c_scroll)
	var c_grid := GridContainer.new()
	c_grid.columns = 4
	c_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_grid.add_theme_constant_override("h_separation", 2)
	c_grid.add_theme_constant_override("v_separation", 1)
	c_scroll.add_child(c_grid)

	if _director != null and _director.color_pool != null:
		for family: String in _director.color_pool.get_families():
			var family_captured: String = family
			var cb := CheckBox.new()
			cb.text = family.replace("_", " ")
			cb.button_pressed = true
			cb.add_theme_font_size_override("font_size", 9)
			cb.toggled.connect(func(on: bool) -> void:
				if _director and _director.color_pool:
					_director.color_pool.set_enabled(family_captured, on)
			)
			c_grid.add_child(cb)
			_palette_checks[family] = cb

	tab.add_child(VSeparator.new())

	# Markings — right, fixed width
	var mv := VBoxContainer.new()
	mv.custom_minimum_size = Vector2(190, 0)
	mv.add_theme_constant_override("separation", 4)
	tab.add_child(mv)

	mv.add_child(_label("MARKING OVERLAY", 8, Color(0.4, 0.55, 0.4)))

	var prob_row := HBoxContainer.new()
	prob_row.add_theme_constant_override("separation", 4)
	mv.add_child(prob_row)
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

	var m_btns := HBoxContainer.new()
	m_btns.add_theme_constant_override("separation", 4)
	mv.add_child(m_btns)
	m_btns.add_child(_small_button("All", func() -> void:
		if _director and _director.marking_pool:
			_director.marking_pool.set_all_enabled(true)
			for cb: CheckBox in _marking_checks.values(): cb.button_pressed = true
	))
	m_btns.add_child(_small_button("None", func() -> void:
		if _director and _director.marking_pool:
			_director.marking_pool.set_all_enabled(false)
			for cb: CheckBox in _marking_checks.values(): cb.button_pressed = false
	))

	var m_scroll := ScrollContainer.new()
	m_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	m_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mv.add_child(m_scroll)
	var m_grid := GridContainer.new()
	m_grid.columns = 2
	m_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_grid.add_theme_constant_override("h_separation", 2)
	m_grid.add_theme_constant_override("v_separation", 1)
	m_scroll.add_child(m_grid)

	if _director != null and _director.marking_pool != null:
		for path: String in _director.marking_pool.get_all():
			var path_captured: String = path
			var cb := CheckBox.new()
			cb.text = _director.marking_pool.get_label(path)
			cb.button_pressed = true
			cb.add_theme_font_size_override("font_size", 9)
			cb.toggled.connect(func(on: bool) -> void:
				if _director and _director.marking_pool:
					_director.marking_pool.set_enabled(path_captured, on)
			)
			m_grid.add_child(cb)
			_marking_checks[path] = cb

	return tab

# ── Furniture tab ────────────────────────────────────────────────

func _build_furniture_tab() -> VBoxContainer:
	var tab := VBoxContainer.new()
	tab.name = "Furniture"
	tab.add_theme_constant_override("separation", 4)
	tab.add_child(_label("HOTSPOT DETECTION  (focused kitty)", 9, Color(0.5, 0.5, 0.75)))
	_furniture_text = TextEdit.new()
	_furniture_text.editable = false
	_furniture_text.selecting_enabled = true
	_furniture_text.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_furniture_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_furniture_text.add_theme_font_size_override("font_size", 11)
	_furniture_text.add_theme_color_override("font_color", Color(0.65, 0.9, 0.65))
	tab.add_child(_furniture_text)
	return tab

func _refresh_furniture_tab(character: Character) -> void:
	var lines: Array[String] = []
	var nearby := character.get_nearby_furniture()
	lines.append("NEARBY FURNITURE (%d)" % nearby.size())
	lines.append("─────────────────────────────────")
	if nearby.is_empty():
		lines.append("  (none — is the DetectionArea collision layer set correctly?)")
	else:
		for f: Furniture in nearby:
			var hotspots := f.get_hotspots()
			if hotspots.is_empty():
				lines.append("  [%s]  —  no hotspots  (script missing or _init_hotspots not overridden)" % f.name)
			else:
				lines.append("  [%s]" % f.name)
				for hs: FurnitureHotspot in hotspots:
					var action := hs.get_action_label()
					var status: String
					if hs.knocked:
						status = "KNOCKED"
					elif hs.has_available_slot():
						status = "available  (%d slots)" % hs.slots.size()
					else:
						status = "FULL"
					lines.append("    %-10s  %s" % [action, status])
	lines.append("")
	lines.append("CLAIMED HOTSPOT")
	lines.append("─────────────────────────────────")
	var claimed := character.get_claimed_hotspot()
	if claimed == null:
		lines.append("  (none)")
	else:
		var action := claimed.get_action_label()
		lines.append("  %s  —  slot held" % action)
	_furniture_text.text = "\n".join(lines)

# ── World tab ─────────────────────────────────────────────────────

func _build_world_tab() -> VBoxContainer:
	var tab := VBoxContainer.new()
	tab.name = "World"
	tab.add_theme_constant_override("separation", 6)

	var hs_check := CheckBox.new()
	hs_check.text = "Show hotspots"
	hs_check.add_theme_font_size_override("font_size", 10)
	hs_check.toggled.connect(func(on: bool) -> void: Furniture.debug_hotspots = on)
	tab.add_child(hs_check)

	var sep_check := CheckBox.new()
	sep_check.text = "Show separation radius"
	sep_check.add_theme_font_size_override("font_size", 10)
	sep_check.toggled.connect(func(on: bool) -> void: _sep_draw.visible = on)
	tab.add_child(sep_check)

	tab.add_child(_label("SEPARATION", 8, Color(0.4, 0.4, 0.55)))

	for ss: Array in [
		["Radius",    16.0, 256.0, 4.0,  32.0,  "%.0f",  func(v: float) -> void: if _director: _director.separation_system.separation_radius        = v],
		["Strength",  0.0,  400.0, 10.0, 120.0, "%.0f",  func(v: float) -> void: if _director: _director.separation_system.separation_strength      = v],
		["Rest Push", 0.0,  100.0, 5.0,  20.0,  "%.0f",  func(v: float) -> void: if _director: _director.separation_system.rest_push_strength       = v],
		["Nudge %",   0.0,  0.5,   0.01, 0.1,   "%.2f",  func(v: float) -> void: if _director: _director.separation_system.max_speed_nudge_fraction = v],
	]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		tab.add_child(row)
		var lbl := _label(ss[0], 9, Color(0.4, 0.4, 0.55))
		lbl.custom_minimum_size = Vector2(60, 0)
		row.add_child(lbl)
		var sl := HSlider.new()
		sl.min_value = ss[1]; sl.max_value = ss[2]; sl.step = ss[3]; sl.value = ss[4]
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.custom_minimum_size = Vector2(0, 16)
		var fmt: String = ss[5]
		var vl := Label.new()
		vl.text = fmt % ss[4]
		vl.add_theme_font_size_override("font_size", 9)
		vl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
		vl.custom_minimum_size = Vector2(32, 0)
		var cb: Callable = ss[6]
		sl.value_changed.connect(func(v: float) -> void: vl.text = fmt % v; cb.call(v))
		row.add_child(sl)
		row.add_child(vl)

	return tab

# ── Helpers ───────────────────────────────────────────────────────

func _on_tab_changed(tab_idx: int) -> void:
	if tab_idx == 1:
		_last_kitty = null
		_rebind_character_tab()

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
		lines.append(match_source_prefix(src) + entry.text)
	_log_edit.text = "\n".join(lines)
	_log_edit.set_caret_line(_log_edit.get_line_count())

func match_source_prefix(src: String) -> String:
	match src:
		"ai":     return "[AI]     "
		"player": return "[PLAYER] "
		"btn":    return "[BTN]    "
		_:        return "[SYS]    "

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
		_append_log("[COPY] No character selected", "btn")
		return
	var p := k.personality
	var lines: Array[String] = []
	lines.append("# Personality profile: %s" % k.name)
	lines.append("")
	for group_def: Array in _FIELDS:
		lines.append("[%s]" % group_def[0])
		for i in range(1, group_def.size()):
			var field: Array = group_def[i]
			var prop: String  = field[1]
			var val: Variant  = p.get(prop)
			if field[2] == "option":
				var items: Array = field[3]
				var idx: int = int(val)
				lines.append("  %s = %s" % [prop, items[idx] if idx < items.size() else str(val)])
			elif field[2] == "spinbox":
				lines.append("  %s = %d" % [prop, int(val)])
			else:
				lines.append("  %s = %.3f" % [prop, float(val)])
		lines.append("")
	DisplayServer.clipboard_set("\n".join(lines).strip_edges())
	_append_log("[COPY] %s personality copied to clipboard" % k.name, "btn")

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

func _character() -> Character:
	return _director.controlled_character if _director != null else null

func _random_pos() -> Vector2:
	var t := get_viewport().get_canvas_transform().affine_inverse()
	var sz := get_viewport().get_visible_rect().size
	return t * Vector2(randf_range(80.0, sz.x - 80.0), randf_range(80.0, sz.y - 80.0))

func _force(label: String, state: State) -> void:
	var k: Character = _character()
	if k == null:
		return
	_append_log("[BTN] %s" % label, "btn")
	k.change_state(state)

# ── Button handlers ───────────────────────────────────────────────

func _on_btn_sit()       -> void: _force("→ Sit",           SitState.new())
func _on_btn_lay_down()  -> void: _force("→ LayDown → Lay", LayDownState.new(LayState.new()))
func _on_btn_sit_up()    -> void: _force("→ SitUp → Sit",   SitUpState.new(SitState.new(true, true)))
func _on_btn_stand_up()  -> void: _force("→ StandUp → Sit", StandUpState.new(SitState.new()))

func _on_btn_look_around() -> void:
	var k: Character = _character()
	if k == null: return
	var loop_label := " (loop)" if _look_around_loop else ""
	_append_log("[BTN] → LookAround%s  dir=%s  speed=%.1f  reps=%d" % [
		loop_label, Global.LookDirection.keys()[_la_direction], _la_speed, _la_reps], "btn")
	k.change_state(LookAroundState.new(
		null, _look_around_loop, _la_direction,
		_la_speed, _la_pause_right, _la_pause_left, _la_pause_center, _la_reps))

func _on_btn_walk() -> void:
	var k: Character = _character()
	if k == null: return
	_append_log("[BTN] → Walk to random", "btn")
	k.set_target(PositionTarget.new(_random_pos()))
	k.begin_walk()

func _on_btn_run() -> void:
	var k: Character = _character()
	if k == null: return
	_append_log("[BTN] → Run to random", "btn")
	k.set_target(PositionTarget.new(_random_pos()))
	k.begin_run()

func _on_btn_sprint() -> void:
	var k: Character = _character()
	if k == null: return
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
