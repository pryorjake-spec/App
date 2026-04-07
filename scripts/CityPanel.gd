extends PanelContainer
## CityPanel — displays HP, Defense, and Infrastructure bars for one city.
## Built entirely in code so no .tscn editing is needed.

var _is_player: bool = true

var _name_label:   Label
var _hp_bar:       ProgressBar
var _hp_label:     Label
var _def_bar:      ProgressBar
var _def_label:    Label
var _infra_bar:    ProgressBar
var _infra_label:  Label
var _phase_label:  Label   # shows current enemy attack phase name

# Colours
const COL_HP    := Color(0.85, 0.2, 0.2)
const COL_DEF   := Color(0.2, 0.5, 0.9)
const COL_INFRA := Color(0.3, 0.75, 0.35)
const COL_BG    := Color(0.08, 0.08, 0.12, 0.95)

func _ready() -> void:
	_build_ui()
	GameState.city_stats_changed.connect(_refresh)
	_refresh()

func setup(is_player: bool, city_name: String) -> void:
	_is_player = is_player
	_name_label.text = city_name

func _build_ui() -> void:
	custom_minimum_size = Vector2(280, 220)

	# Panel background
	var style := StyleBoxFlat.new()
	style.bg_color = COL_BG
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.4)
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_top",    12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.add_child(vbox)
	add_child(margin)

	# City name
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_name_label)

	# HP row
	_hp_bar   = _make_bar(COL_HP, 20)
	_hp_label = _make_row_label(vbox, "HP", _hp_bar)

	# Defense row
	_def_bar   = _make_bar(COL_DEF, 20)
	_def_label = _make_row_label(vbox, "Defense", _def_bar)

	# Infrastructure row
	_infra_bar   = _make_bar(COL_INFRA, 20)
	_infra_label = _make_row_label(vbox, "Infrastructure", _infra_bar)

	# Phase label (enemy side only)
	_phase_label = Label.new()
	_phase_label.add_theme_font_size_override("font_size", 11)
	_phase_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_phase_label.visible = false
	vbox.add_child(_phase_label)

func _make_bar(color: Color, max_val: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = max_val
	bar.value = max_val
	bar.custom_minimum_size = Vector2(0, 14)
	bar.show_percentage = false

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left     = 3
	fill.corner_radius_top_right    = 3
	fill.corner_radius_bottom_left  = 3
	fill.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", fill)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.2)
	bg.corner_radius_top_left     = 3
	bg.corner_radius_top_right    = 3
	bg.corner_radius_bottom_left  = 3
	bg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg)
	return bar

func _make_row_label(parent: VBoxContainer, stat_name: String, bar: ProgressBar) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = stat_name + ":"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	lbl.custom_minimum_size = Vector2(90, 0)
	row.add_child(lbl)

	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)

	var val_lbl := Label.new()
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.add_theme_color_override("font_color", Color.WHITE)
	val_lbl.custom_minimum_size = Vector2(52, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)
	return val_lbl

func _refresh() -> void:
	if _is_player:
		_hp_bar.max_value    = GameState.player_hp_max
		_hp_bar.value        = GameState.player_hp
		_hp_label.text       = "%d / %d" % [GameState.player_hp, GameState.player_hp_max]

		_def_bar.max_value   = 20
		_def_bar.value       = GameState.player_defense
		_def_label.text      = "%d / %d" % [GameState.player_defense, GameState.player_defense_max]

		_infra_bar.max_value = 20
		_infra_bar.value     = GameState.player_infrastructure
		_infra_label.text    = "%d / 20" % GameState.player_infrastructure
	else:
		_hp_bar.max_value    = GameState.enemy_hp_max
		_hp_bar.value        = GameState.enemy_hp
		_hp_label.text       = "%d / %d" % [GameState.enemy_hp, GameState.enemy_hp_max]

		_def_bar.max_value   = 20
		_def_bar.value       = GameState.enemy_defense
		_def_label.text      = "%d / %d" % [GameState.enemy_defense, GameState.enemy_defense_max]

		_infra_bar.max_value = 20
		_infra_bar.value     = GameState.enemy_infrastructure
		_infra_label.text    = "%d / 20" % GameState.enemy_infrastructure

func show_attack_phase(phase_label: String) -> void:
	_phase_label.text    = "Incoming: " + phase_label
	_phase_label.visible = true

func hide_attack_phase() -> void:
	_phase_label.visible = false
