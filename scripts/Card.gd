extends PanelContainer
## Card — a single playable card node displayed in the player's hand.
## Emits `card_clicked(card_data)` when the player clicks it.

signal card_clicked(card_data: Dictionary)

var card_data: Dictionary = {}
var _is_playable: bool = true
var _is_hovered: bool = false

# Style colours
const COL_ATTACK  := Color(0.75, 0.18, 0.18)
const COL_DEFEND  := Color(0.18, 0.42, 0.72)
const COL_SKILL   := Color(0.45, 0.25, 0.70)
const COL_BG      := Color(0.10, 0.10, 0.14, 0.97)
const COL_HOVER   := Color(0.18, 0.18, 0.24, 0.97)
const COL_DISABLED:= Color(0.06, 0.06, 0.08, 0.7)

var _bg_style:   StyleBoxFlat
var _name_label: Label
var _cost_label: Label
var _desc_label: Label
var _type_bar:   ColorRect

func _ready() -> void:
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)
	gui_input.connect(_on_input)
	_build_ui()

func setup(data: Dictionary) -> void:
	card_data = data
	_refresh_display()

func set_playable(can_play: bool) -> void:
	_is_playable = can_play
	_refresh_display()

func _build_ui() -> void:
	custom_minimum_size = Vector2(120, 175)

	_bg_style = StyleBoxFlat.new()
	_bg_style.bg_color = COL_BG
	_bg_style.border_width_left   = 2
	_bg_style.border_width_right  = 2
	_bg_style.border_width_top    = 2
	_bg_style.border_width_bottom = 2
	_bg_style.border_color = Color(0.3, 0.3, 0.45)
	_bg_style.corner_radius_top_left     = 8
	_bg_style.corner_radius_top_right    = 8
	_bg_style.corner_radius_bottom_left  = 8
	_bg_style.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", _bg_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   6)
	margin.add_theme_constant_override("margin_right",  6)
	margin.add_theme_constant_override("margin_top",    6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.add_child(vbox)
	add_child(margin)

	# Top row: name + cost
	var top_row := HBoxContainer.new()
	vbox.add_child(top_row)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_row.add_child(_name_label)

	_cost_label = Label.new()
	_cost_label.add_theme_font_size_override("font_size", 14)
	_cost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cost_label.custom_minimum_size = Vector2(22, 0)
	top_row.add_child(_cost_label)

	# Type colour bar
	_type_bar = ColorRect.new()
	_type_bar.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(_type_bar)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)

	# Description
	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", 10)
	_desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_desc_label)

func _refresh_display() -> void:
	if card_data.is_empty():
		return

	_name_label.text = card_data.get("name", "?")
	_cost_label.text = str(card_data.get("cost", 0))
	_desc_label.text = card_data.get("description", "")

	var card_type: String = card_data.get("type", "skill")
	match card_type:
		"attack": _type_bar.color = COL_ATTACK
		"defend": _type_bar.color = COL_DEFEND
		_:        _type_bar.color = COL_SKILL

	if _is_playable:
		_bg_style.bg_color = COL_HOVER if _is_hovered else COL_BG
		_bg_style.border_color = Color(0.5, 0.5, 0.7) if _is_hovered else Color(0.3, 0.3, 0.45)
		modulate = Color.WHITE
	else:
		_bg_style.bg_color = COL_DISABLED
		modulate = Color(0.55, 0.55, 0.55, 0.8)

	add_theme_stylebox_override("panel", _bg_style)

func _on_hover_enter() -> void:
	_is_hovered = true
	if _is_playable:
		position.y -= 10  # lift card on hover
	_refresh_display()

func _on_hover_exit() -> void:
	_is_hovered = false
	position.y = 0
	_refresh_display()

func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and _is_playable:
			card_clicked.emit(card_data)
