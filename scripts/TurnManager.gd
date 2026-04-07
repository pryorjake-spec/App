extends Node
## TurnManager — orchestrates the full turn loop.
## Attach to BattleScene. Calls into GameState and emits signals
## that BattleScene listens to for UI updates.

signal hand_updated()
signal log_message(text: String)
signal enemy_attacking(phase_label: String)
signal enemy_attack_done()
signal cards_played_updated()

@export var enemy_attack_delay: float = 1.2   # seconds before enemy resolves

var _battle_scene: Node   # set by BattleScene._ready()

func start_battle(battle_scene: Node) -> void:
	_battle_scene = battle_scene
	GameState.start_player_turn()
	_log("Turn %d — Your move." % GameState.turn_number)
	hand_updated.emit()

# ===================================================
# Player Actions
# ===================================================

func player_play_card(card_data: Dictionary) -> void:
	if GameState.current_phase != "player":
		return
	if GameState.is_game_over:
		return

	var success := GameState.play_card(card_data)
	if not success:
		_log("Cannot play that card right now.")
		return

	_log("Played: %s" % card_data.get("name", "?"))

	var effects: Array = card_data.get("effects", [])
	for effect in effects:
		var targets_enemy: bool = effect.get("target", "enemy") == "enemy"

		if effect["type"] == "draw_cards":
			var drawn := GameState.draw_cards(effect.get("amount", 1))
			_log("Drew %d card(s)." % drawn.size())
		else:
			GameState.apply_effect(effect, targets_enemy)

	cards_played_updated.emit()
	hand_updated.emit()

	if GameState.is_game_over:
		return

	if GameState.cards_played >= GameState.MAX_CARDS_PLAYED:
		_log("No cards remaining this turn — ending turn.")
		await get_tree().create_timer(0.5).timeout
		player_end_turn()

func player_end_turn() -> void:
	if GameState.current_phase != "player":
		return
	if GameState.is_game_over:
		return
	_run_enemy_turn()

# ===================================================
# Enemy Turn
# ===================================================

func _run_enemy_turn() -> void:
	GameState.start_enemy_turn()
	var phase := _get_enemy_phase()
	_log("Enemy turn — %s" % phase.get("label", "Attacking..."))
	enemy_attacking.emit(phase.get("label", ""))

	await get_tree().create_timer(enemy_attack_delay).timeout

	if GameState.is_game_over:
		enemy_attack_done.emit()
		return

	var attacks: Array = phase.get("attacks", [])
	for attack in attacks:
		GameState.apply_effect(attack, false)   # targets player

	if GameState.is_game_over:
		enemy_attack_done.emit()
		return

	enemy_attack_done.emit()
	_start_next_player_turn()

func _start_next_player_turn() -> void:
	GameState.advance_turn()
	GameState.restore_enemy_defense()
	GameState.start_player_turn()
	_log("— Turn %d — Your move." % GameState.turn_number)
	hand_updated.emit()

# ===================================================
# Enemy AI — pick attack phase by turn number
# ===================================================

func _get_enemy_phase() -> Dictionary:
	var phases: Array = GameState.enemy_data.get("attack_phases", [])
	var turn := GameState.turn_number
	for phase in phases:
		var range_arr: Array = phase.get("turn_range", [1, 99])
		if turn >= range_arr[0] and turn <= range_arr[1]:
			return phase
	return {"label": "Infantry Wave", "attacks": [{"type": "damage_defense", "amount": 6}]}

# ===================================================
# Helpers
# ===================================================

func _log(text: String) -> void:
	log_message.emit(text)
	print("[TurnManager] " + text)
