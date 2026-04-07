extends Node
## GameState — AutoLoad singleton
## Holds all live game data: city stats, turn tracking, deck state.

signal turn_phase_changed(phase: String)
signal city_stats_changed()
signal game_over(player_won: bool, message: String)
signal card_drawn(card_data: Dictionary)

# ---------- Constants ----------
const MAX_HAND_SIZE    := 8
const MAX_CARDS_PLAYED := 4
const MAX_ENERGY       := 3
const CARDS_PER_DRAW   := 8

# ---------- City Stats ----------
var player_hp:             int = 20
var player_hp_max:         int = 20
var player_defense:        int = 20
var player_defense_max:    int = 20  # reduced permanently by infrastructure hits
var player_infrastructure: int = 20  # each point = 1 max defense restored per turn

var enemy_hp:             int = 20
var enemy_hp_max:         int = 20
var enemy_defense:        int = 20
var enemy_defense_max:    int = 20
var enemy_infrastructure: int = 20

# ---------- Turn State ----------
var current_phase:      String = "player"   # "player" | "enemy"
var turn_number:        int    = 1
var cards_played:       int    = 0
var player_energy:      int    = MAX_ENERGY
var is_game_over:       bool   = false

# ---------- Deck State ----------
var player_deck:    Array[Dictionary] = []
var player_hand:    Array[Dictionary] = []
var player_discard: Array[Dictionary] = []

# ---------- Current Enemy ----------
var enemy_data: Dictionary = {}

# ===================================================
# City Damage / Healing
# ===================================================

func apply_effect(effect: Dictionary, is_targeting_enemy: bool) -> void:
	match effect["type"]:
		"damage_defense":
			_damage_defense(is_targeting_enemy, effect["amount"])
		"damage_infrastructure":
			_damage_infrastructure(is_targeting_enemy, effect["amount"])
		"damage_hp":
			_damage_hp(is_targeting_enemy, effect["amount"])
		"heal_defense":
			_heal_defense(not is_targeting_enemy, effect["amount"])
		"heal_infrastructure":
			_heal_infrastructure(not is_targeting_enemy, effect["amount"])
		"draw_cards":
			# Handled by BattleScene — signal is enough
			pass
	city_stats_changed.emit()
	check_game_over()

func _damage_defense(enemy: bool, amount: int) -> void:
	if enemy:
		enemy_defense -= amount
		if enemy_defense < 0:
			# Overflow into HP
			enemy_hp += enemy_defense  # defense is negative
			enemy_defense = 0
	else:
		player_defense -= amount
		if player_defense < 0:
			player_hp += player_defense
			player_defense = 0

func _damage_infrastructure(enemy: bool, amount: int) -> void:
	if enemy:
		enemy_infrastructure = max(0, enemy_infrastructure - amount)
		enemy_defense_max = enemy_infrastructure  # 1 infra = 1 max defense
	else:
		player_infrastructure = max(0, player_infrastructure - amount)
		player_defense_max = player_infrastructure

func _damage_hp(enemy: bool, amount: int) -> void:
	if enemy:
		enemy_hp = max(0, enemy_hp - amount)
	else:
		player_hp = max(0, player_hp - amount)

func _heal_defense(player_side: bool, amount: int) -> void:
	if player_side:
		player_defense = min(player_defense_max, player_defense + amount)
	else:
		enemy_defense = min(enemy_defense_max, enemy_defense + amount)

func _heal_infrastructure(player_side: bool, amount: int) -> void:
	if player_side:
		player_infrastructure = min(20, player_infrastructure + amount)
		player_defense_max = player_infrastructure
	else:
		enemy_infrastructure = min(20, enemy_infrastructure + amount)
		enemy_defense_max = enemy_infrastructure

# ===================================================
# Defense Restore (start of each player turn)
# ===================================================

func restore_player_defense() -> void:
	player_defense = player_defense_max
	city_stats_changed.emit()

func restore_enemy_defense() -> void:
	enemy_defense = enemy_defense_max
	city_stats_changed.emit()

# ===================================================
# Win / Loss Check
# ===================================================

func check_game_over() -> void:
	if is_game_over:
		return
	if player_hp <= 0:
		is_game_over = true
		var msg: String = enemy_data.get("defeat_text", "You have been defeated.")
		game_over.emit(false, msg)
	elif enemy_hp <= 0:
		is_game_over = true
		var msg: String = enemy_data.get("victory_text", "Victory!")
		game_over.emit(true, msg)

# ===================================================
# Deck Operations
# ===================================================

func shuffle_deck() -> void:
	player_deck.shuffle()

func draw_cards(count: int) -> Array[Dictionary]:
	var drawn: Array[Dictionary] = []
	for i in range(count):
		if player_deck.is_empty():
			_reshuffle_discard()
		if player_deck.is_empty():
			break
		var card = player_deck.pop_back()
		player_hand.append(card)
		drawn.append(card)
	return drawn

func _reshuffle_discard() -> void:
	player_deck = player_discard.duplicate()
	player_discard.clear()
	player_deck.shuffle()

func discard_hand() -> void:
	for card in player_hand:
		player_discard.append(card)
	player_hand.clear()

func play_card(card_data: Dictionary) -> bool:
	if cards_played >= MAX_CARDS_PLAYED:
		return false
	if player_energy < card_data.get("cost", 1):
		return false
	player_hand.erase(card_data)
	player_discard.append(card_data)
	player_energy -= card_data.get("cost", 1)
	cards_played += 1
	return true

# ===================================================
# Turn Management
# ===================================================

func start_player_turn() -> void:
	current_phase = "player"
	cards_played = 0
	player_energy = MAX_ENERGY
	restore_player_defense()
	discard_hand()
	draw_cards(CARDS_PER_DRAW)
	turn_phase_changed.emit("player")

func start_enemy_turn() -> void:
	current_phase = "enemy"
	turn_phase_changed.emit("enemy")

func advance_turn() -> void:
	turn_number += 1

# ===================================================
# Load Enemy
# ===================================================

func load_enemy(data: Dictionary) -> void:
	enemy_data = data
	enemy_hp             = data.get("hp", 20)
	enemy_hp_max         = data.get("hp", 20)
	enemy_defense        = data.get("defense_max", 20)
	enemy_defense_max    = data.get("defense_max", 20)
	enemy_infrastructure = data.get("infrastructure_max", 20)
	city_stats_changed.emit()

func reset_player() -> void:
	player_hp             = 20
	player_hp_max         = 20
	player_defense        = 20
	player_defense_max    = 20
	player_infrastructure = 20
	cards_played          = 0
	player_energy         = MAX_ENERGY
	turn_number           = 1
	is_game_over          = false
	player_deck.clear()
	player_hand.clear()
	player_discard.clear()
