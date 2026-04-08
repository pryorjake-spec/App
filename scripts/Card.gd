extends PanelContainer
## Card — a single playable card node displayed in the player's hand.
## Uses card type image as background with text overlaid on top.

signal card_clicked(card_data: Dictionary)

var card_data: Dictionary = {}
var _is_playable: bool = true
var _is_hovered:  bool = false

const COL_DISABLED := Color(1.0, 1.0, 1.0, 0.4)

var _bg_texture:  TextureRect
var _name_label:  Label
var _cost_label:  Label
var _desc_label:  Label
var _type_bar:    ColorRect

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

	# Transparent panel — image is the background
	var blank := StyleBoxFlat.new()
	blank.bg_color = Color(0, 0, 0, 0)
	add_theme_stylebox_override("panel", blank)

	# Background image (fills the whole card)
	_bg_texture = TextureRect.new()
	_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_texture.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_bg_texture)

	# Text overlay on top of the image
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Top row: name + cost
	var top_row := HBoxContainer.new()
	vbox.add_child(top_row)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	_name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_row.add_child(_name_label)

	_cost_label = Label.new()
	_cost_label.add_theme_font_size_override("font_size", 14)
	_cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))
	_cost_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_cost_label.add_theme_constant_override("shadow_offset_x", 1)
	_cost_label.add_theme_constant_override("shadow_offset_y", 1)
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cost_label.custom_minimum_size = Vector2(22, 0)
	top_row.add_child(_cost_label)

	# Thin colour bar under the name (attack=red, defend=blue, mystery=gold)
	_type_bar = ColorRect.new()
	_type_bar.custom_minimum_size = Vector2(0, 3)
	vbox.add_child(_type_bar)

	# Spacer pushes description to the bottom
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Description at the bottom
	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", 9)
	_desc_label.add_theme_color_override("font_color", Color.WHITE)
	_desc_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_desc_label.add_theme_constant_override("shadow_offset_x", 1)
	_desc_label.add_theme_constant_override("shadow_offset_y", 1)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_desc_label)

func _refresh_display() -> void:
	if card_data.is_empty():
		return

	_name_label.text = card_data.get("name", "?")
	_cost_label.text = str(card_data.get("cost", 0))
	_desc_label.text = card_data.get("description", "")

	var card_type: String = card_data.get("type", "skill")
	match card_type:
		"attack":  _type_bar.color = Color(0.9, 0.2, 0.2)
		"defend":  _type_bar.color = Color(0.2, 0.5, 0.95)
		"mystery": _type_bar.color = Color(0.85, 0.7, 0.1)
		_:         _type_bar.color = Color(0.5, 0.3, 0.8)

	# Set background image based on card type
	var img_path: String
	match card_type:
		"attack":  img_path = "res://Assets/attack.png"
		"defend":  img_path = "res://Assets/build.png"
		"mystery": img_path = "res://Assets/mystery.png"
		_:         img_path = "res://Assets/mystery.png"

	var tex = load(img_path)
	if tex:
		_bg_texture.texture = tex

	modulate = Color.WHITE if _is_playable else COL_DISABLED

func _on_hover_enter() -> void:
	_is_hovered = true
	if _is_playable:
		position.y -= 10
	_refresh_display()

func _on_hover_exit() -> void:
	_is_hovered = false
	position.y = 0
	_refresh_display()

func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and _is_playable:
			card_clicked.emit(card_data)
