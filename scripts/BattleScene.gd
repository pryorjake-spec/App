extends Control
## BattleScene — root of the main game scene.
## Builds the entire UI in code, wires up signals, and drives the game loop.

# Load scripts as classes so .new() creates properly typed instances
const CityPanelClass   = preload("res://scripts/CityPanel.gd")
const HandClass        = preload("res://scripts/Hand.gd")
const TurnManagerClass = preload("res://scripts/TurnManager.gd")

# UI nodes — untyped so script methods/signals are accessible
var _player_panel
var _enemy_panel
var _hand
var _end_turn_btn:  Button
var _log_container: VBoxContainer
var _log_scroll:    ScrollContainer
var _hud_label:     Label
var _turn_label:    Label
var _phase_banner:  Label

var _turn_manager

# ===================================================
# _ready
# ===================================================

func _ready() -> void:
	_build_layout()
	_setup_turn_manager()
	_load_battle("north_korea")

# ===================================================
# Layout
# ===================================================

func _build_layout() -> void:
	anchor_right  = 1.0
	anchor_bottom = 1.0

	# Background image (falls back to dark colour if file not found)
	var bg_tex = load("res://assets/Background.png")
	if bg_tex:
		var bg := TextureRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(bg)
	else:
		var bg := ColorRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(0.05, 0.05, 0.09)
		add_child(bg)

	# Root VBoxContainer fills the whole window
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	# ---- Top bar ----
	var top_bar := HBoxContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 50)
	top_bar.add_theme_constant_override("separation", 16)
	var top_bg := StyleBoxFlat.new()
	top_bg.bg_color = Color(0.07, 0.07, 0.11)
	root.add_child(top_bar)

	var top_margin := MarginContainer.new()
	top_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_margin.add_theme_constant_override("margin_left",  12)
	top_margin.add_theme_constant_override("margin_right", 12)
	top_bar.add_child(top_margin)

	var top_inner := HBoxContainer.new()
	top_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_inner.add_theme_constant_override("separation", 16)
	top_margin.add_child(top_inner)

	_turn_label = Label.new()
	_turn_label.add_theme_font_size_override("font_size", 16)
	_turn_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_turn_label.custom_minimum_size = Vector2(80, 0)
	top_inner.add_child(_turn_label)

	_hud_label = Label.new()
	_hud_label.add_theme_font_size_override("font_size", 14)
	_hud_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_hud_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	top_inner.add_child(_hud_label)

	_phase_banner = Label.new()
	_phase_banner.add_theme_font_size_override("font_size", 16)
	_phase_banner.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	_phase_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_phase_banner.custom_minimum_size   = Vector2(160, 0)
	top_inner.add_child(_phase_banner)

	# ---- Middle area (cities + log) ----
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 12)
	root.add_child(middle)

	var mid_margin := MarginContainer.new()
	mid_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_margin.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	mid_margin.add_theme_constant_override("margin_left",   16)
	mid_margin.add_theme_constant_override("margin_right",  16)
	mid_margin.add_theme_constant_override("margin_top",    12)
	mid_margin.add_theme_constant_override("margin_bottom", 12)
	root.add_child(mid_margin)

	var mid_inner := HBoxContainer.new()
	mid_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_inner.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	mid_inner.add_theme_constant_override("separation", 12)
	mid_margin.add_child(mid_inner)

	# Player city panel
	_player_panel = CityPanelClass.new()
	_player_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid_inner.add_child(_player_panel)

	# Center spacer
	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_inner.add_child(spacer1)

	# Battle log
	_log_scroll = ScrollContainer.new()
	_log_scroll.custom_minimum_size   = Vector2(300, 0)
	_log_scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	mid_inner.add_child(_log_scroll)

	_log_container = VBoxContainer.new()
	_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_container.add_theme_constant_override("separation", 3)
	_log_scroll.add_child(_log_container)

	# Center spacer
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_inner.add_child(spacer2)

	# Enemy city panel
	_enemy_panel = CityPanelClass.new()
	_enemy_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid_inner.add_child(_enemy_panel)

	# ---- Bottom: hand + end turn ----
	var bottom_bg := ColorRect.new()
	bottom_bg.custom_minimum_size = Vector2(0, 200)
	bottom_bg.color = Color(0.06, 0.06, 0.10)
	root.add_child(bottom_bg)

	# We overlay the hand and button on bottom_bg using a container
	var bottom_margin := MarginContainer.new()
	bottom_margin.custom_minimum_size = Vector2(0, 200)
	bottom_margin.add_theme_constant_override("margin_left",   16)
	bottom_margin.add_theme_constant_override("margin_right",  16)
	bottom_margin.add_theme_constant_override("margin_top",    10)
	bottom_margin.add_theme_constant_override("margin_bottom", 10)
	root.add_child(bottom_margin)

	var bottom_inner := HBoxContainer.new()
	bottom_inner.add_theme_constant_override("separation", 12)
	bottom_margin.add_child(bottom_inner)

	# Hand of cards
	_hand = HandClass.new()
	_hand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_inner.add_child(_hand)

	# End Turn button
	_end_turn_btn = Button.new()
	_end_turn_btn.text = "End Turn"
	_end_turn_btn.custom_minimum_size = Vector2(130, 50)
	_end_turn_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_end_turn_btn.pressed.connect(_on_end_turn_pressed)
	bottom_inner.add_child(_end_turn_btn)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.22, 0.52, 0.22)
	btn_style.corner_radius_top_left     = 6
	btn_style.corner_radius_top_right    = 6
	btn_style.corner_radius_bottom_left  = 6
	btn_style.corner_radius_bottom_right = 6
	_end_turn_btn.add_theme_stylebox_override("normal", btn_style)

# ===================================================
# Setup
# ===================================================

func _load_battle(enemy_id: String) -> void:
	var enemy_data := CardDatabase.get_enemy_data(enemy_id)
	if enemy_data.is_empty():
		push_error("BattleScene: Could not load enemy '%s'" % enemy_id)
		return

	GameState.reset_player()
	GameState.load_enemy(enemy_data)

	var starter_deck := CardDatabase.get_starter_deck()
	GameState.player_deck = starter_deck
	GameState.shuffle_deck()

	_player_panel.setup(true,  "Your Saucer")
	_enemy_panel.setup(false, enemy_data.get("city_name", "Enemy City"))

	GameState.game_over.connect(_on_game_over)
	_turn_manager.start_battle(self)
	_refresh_hud()

func _setup_turn_manager() -> void:
	_turn_manager = TurnManagerClass.new()
	add_child(_turn_manager)

	_turn_manager.hand_updated.connect(_on_hand_updated)
	_turn_manager.log_message.connect(_on_log_message)
	_turn_manager.enemy_attacking.connect(_on_enemy_attacking)
	_turn_manager.enemy_attack_done.connect(_on_enemy_attack_done)
	_turn_manager.cards_played_updated.connect(_refresh_hud)
	GameState.city_stats_changed.connect(_refresh_hud)

# ===================================================
# Signal Handlers
# ===================================================

func _on_hand_updated() -> void:
	_hand.populate(GameState.player_hand)
	if not _hand.card_played.is_connected(_on_card_played):
		_hand.card_played.connect(_on_card_played)
	_refresh_hud()

func _on_card_played(card_data: Dictionary) -> void:
	_hand.remove_card(card_data)
	_turn_manager.player_play_card(card_data)

func _on_end_turn_pressed() -> void:
	if GameState.current_phase == "player" and not GameState.is_game_over:
		_turn_manager.player_end_turn()

func _on_enemy_attacking(phase_label: String) -> void:
	_enemy_panel.show_attack_phase(phase_label)
	_end_turn_btn.disabled = true
	_phase_banner.text = "ENEMY TURN"
	_phase_banner.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

func _on_enemy_attack_done() -> void:
	_enemy_panel.hide_attack_phase()
	_end_turn_btn.disabled = false
	_phase_banner.text = "YOUR TURN"
	_phase_banner.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))

func _on_log_message(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.8))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_container.add_child(lbl)
	await get_tree().process_frame
	_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)

func _on_game_over(player_won: bool, message: String) -> void:
	_end_turn_btn.disabled = true

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.72)
	add_child(overlay)

	var lbl := Label.new()
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.text = ("VICTORY\n\n" if player_won else "DEFEAT\n\n") + message
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4) if player_won else Color(1.0, 0.3, 0.3))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(500, 0)
	add_child(lbl)

# ===================================================
# HUD
# ===================================================

func _refresh_hud() -> void:
	_turn_label.text = "Turn %d" % GameState.turn_number
	_hud_label.text  = "Energy: %d / %d     Cards: %d / %d" % [
		GameState.player_energy, GameState.MAX_ENERGY,
		GameState.cards_played,  GameState.MAX_CARDS_PLAYED
	]
	if GameState.current_phase == "player":
		_phase_banner.text = "YOUR TURN"
	_hand.refresh_playability()
