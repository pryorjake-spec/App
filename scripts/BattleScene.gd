extends Control
## BattleScene — root of the main game scene.
## Builds the entire UI in code, wires up signals, and drives the game loop.

const CityPanelScript  := preload("res://scripts/CityPanel.gd")
const HandScript       := preload("res://scripts/Hand.gd")
const TurnManagerScript:= preload("res://scripts/TurnManager.gd")

# UI nodes
var _player_panel:  PanelContainer
var _enemy_panel:   PanelContainer
var _hand:          HBoxContainer
var _end_turn_btn:  Button
var _log_container: VBoxContainer
var _log_scroll:    ScrollContainer
var _hud_label:     Label       # energy / cards played display
var _turn_label:    Label
var _phase_banner:  Label       # "YOUR TURN" / "ENEMY TURN"

var _turn_manager: Node

# ===================================================
# _ready — wire everything up
# ===================================================

func _ready() -> void:
	_build_layout()
	_setup_turn_manager()
	_load_battle("north_korea")

# ===================================================
# Layout construction
# ===================================================

func _build_layout() -> void:
	anchor_right  = 1.0
	anchor_bottom = 1.0

	# Dark gradient background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.09)
	add_child(bg)

	# ---- Top bar (turn info) ----
	var top_bar := _make_hbox(self, Control.PRESET_TOP_WIDE)
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, 48)
	top_bar.add_theme_constant_override("separation", 20)
	var top_margin := _margin_wrap(top_bar, 8, 0, 0, 0)
	add_child(top_margin)

	_turn_label = Label.new()
	_turn_label.add_theme_font_size_override("font_size", 16)
	_turn_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	top_bar.add_child(_turn_label)

	_hud_label = Label.new()
	_hud_label.add_theme_font_size_override("font_size", 14)
	_hud_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_hud_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(_hud_label)

	_phase_banner = Label.new()
	_phase_banner.add_theme_font_size_override("font_size", 16)
	_phase_banner.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	_phase_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_phase_banner.custom_minimum_size = Vector2(180, 0)
	top_bar.add_child(_phase_banner)

	# ---- Main area: city panels + log ----
	var main_area := HBoxContainer.new()
	main_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_area.add_theme_constant_override("separation", 12)
	var main_margin := MarginContainer.new()
	main_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_margin.add_theme_constant_override("margin_left",   16)
	main_margin.add_theme_constant_override("margin_right",  16)
	main_margin.add_theme_constant_override("margin_top",    56)
	main_margin.add_theme_constant_override("margin_bottom", 210)
	main_margin.add_child(main_area)
	add_child(main_margin)

	# Player city panel
	_player_panel = PanelContainer.new()
	_player_panel.set_script(CityPanelScript)
	_player_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_area.add_child(_player_panel)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_area.add_child(spacer)

	# Battle log (center)
	_log_scroll = ScrollContainer.new()
	_log_scroll.custom_minimum_size = Vector2(320, 0)
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_area.add_child(_log_scroll)

	_log_container = VBoxContainer.new()
	_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_container.add_theme_constant_override("separation", 2)
	_log_scroll.add_child(_log_container)

	# Spacer
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_area.add_child(spacer2)

	# Enemy city panel
	_enemy_panel = PanelContainer.new()
	_enemy_panel.set_script(CityPanelScript)
	_enemy_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_area.add_child(_enemy_panel)

	# ---- Hand area (bottom) ----
	var hand_bg := ColorRect.new()
	hand_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hand_bg.custom_minimum_size = Vector2(0, 200)
	hand_bg.color = Color(0.06, 0.06, 0.10, 0.95)
	add_child(hand_bg)

	var hand_margin := MarginContainer.new()
	hand_margin.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hand_margin.custom_minimum_size = Vector2(0, 200)
	hand_margin.add_theme_constant_override("margin_left",   16)
	hand_margin.add_theme_constant_override("margin_right",  180)
	hand_margin.add_theme_constant_override("margin_top",    12)
	hand_margin.add_theme_constant_override("margin_bottom", 12)
	add_child(hand_margin)

	_hand = HBoxContainer.new()
	_hand.set_script(HandScript)
	hand_margin.add_child(_hand)

	# End Turn button
	_end_turn_btn = Button.new()
	_end_turn_btn.text = "End Turn"
	_end_turn_btn.custom_minimum_size = Vector2(140, 50)
	_end_turn_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_end_turn_btn.position = Vector2(-156, -62)
	_end_turn_btn.pressed.connect(_on_end_turn_pressed)
	add_child(_end_turn_btn)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.25, 0.55, 0.25)
	btn_style.corner_radius_top_left     = 6
	btn_style.corner_radius_top_right    = 6
	btn_style.corner_radius_bottom_left  = 6
	btn_style.corner_radius_bottom_right = 6
	_end_turn_btn.add_theme_stylebox_override("normal", btn_style)

# ===================================================
# Battle Initialization
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

# ===================================================
# Turn Manager Setup
# ===================================================

func _setup_turn_manager() -> void:
	_turn_manager = Node.new()
	_turn_manager.set_script(TurnManagerScript)
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
	_hand.card_played.connect(_on_card_played, CONNECT_ONE_SHOT)
	_refresh_hud()

func _on_card_played(card_data: Dictionary) -> void:
	_hand.remove_card(card_data)
	_turn_manager.player_play_card(card_data)
	# Reconnect for next card
	if not _hand.card_played.is_connected(_on_card_played):
		_hand.card_played.connect(_on_card_played, CONNECT_ONE_SHOT)

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
	# Auto-scroll to bottom
	await get_tree().process_frame
	_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)

func _on_game_over(player_won: bool, message: String) -> void:
	_end_turn_btn.disabled = true
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
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
# HUD Refresh
# ===================================================

func _refresh_hud() -> void:
	_turn_label.text = "Turn %d" % GameState.turn_number
	_hud_label.text  = "Energy: %d / %d    Cards: %d / %d" % [
		GameState.player_energy, GameState.MAX_ENERGY,
		GameState.cards_played,  GameState.MAX_CARDS_PLAYED
	]
	if GameState.current_phase == "player":
		_phase_banner.text = "YOUR TURN"
	_hand.refresh_playability()

# ===================================================
# Helpers
# ===================================================

func _make_hbox(parent: Node, _preset: int) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return hbox

func _margin_wrap(child: Node, top: int, right: int, bottom: int, left: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top",    top)
	m.add_theme_constant_override("margin_right",  right)
	m.add_theme_constant_override("margin_bottom", bottom)
	m.add_theme_constant_override("margin_left",   left)
	m.add_child(child)
	return m
