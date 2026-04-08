extends PanelContainer
## Card — image as background, small white text box at the bottom for description.

signal card_clicked(card_data: Dictionary)

var card_data: Dictionary = {}
var _is_playable: bool = true
var _is_hovered:  bool = false

const COL_DISABLED := Color(1.0, 1.0, 1.0, 0.4)

var _bg_texture: TextureRect
var _desc_label: Label

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

	# Transparent panel so image shows fully
	var blank := StyleBoxFlat.new()
	blank.bg_color = Color(0, 0, 0, 0)
	add_theme_stylebox_override("panel", blank)

	# Background image fills the whole card
	_bg_texture = TextureRect.new()
	_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_texture.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_bg_texture)

	# White text box pinned to the bottom of the card
	var text_box := PanelContainer.new()
	text_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	text_box.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(1.0, 1.0, 1.0, 0.88)
	box_style.corner_radius_bottom_left  = 6
	box_style.corner_radius_bottom_right = 6
	text_box.add_theme_stylebox_override("panel", box_style)
	add_child(text_box)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left",   6)
	inner.add_theme_constant_override("margin_right",  6)
	inner.add_theme_constant_override("margin_top",    4)
	inner.add_theme_constant_override("margin_bottom", 4)
	text_box.add_child(inner)

	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", 9)
	_desc_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(_desc_label)

func _refresh_display() -> void:
	if card_data.is_empty():
		return

	_desc_label.text = card_data.get("description", "")

	var card_type: String = card_data.get("type", "skill")
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
