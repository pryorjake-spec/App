extends HBoxContainer
## Hand — displays the player's current hand of cards.
## Notifies BattleScene when a card is clicked via card_played signal.

signal card_played(card_data: Dictionary)

const CardClass = preload("res://scripts/Card.gd")

var _card_nodes: Array = []

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 10)

func populate(hand: Array[Dictionary]) -> void:
	_clear_cards()
	for card_data in hand:
		_add_card(card_data)
	_refresh_playability()

func remove_card(card_data: Dictionary) -> void:
	for node in _card_nodes:
		if node.card_data == card_data:
			_card_nodes.erase(node)
			node.queue_free()
			break
	_refresh_playability()

func refresh_playability() -> void:
	_refresh_playability()

func _add_card(card_data: Dictionary) -> void:
	var card = CardClass.new()
	add_child(card)
	card.setup(card_data)
	card.card_clicked.connect(_on_card_clicked)
	_card_nodes.append(card)

func _clear_cards() -> void:
	for node in _card_nodes:
		node.queue_free()
	_card_nodes.clear()

func _refresh_playability() -> void:
	var can_still_play := GameState.cards_played < GameState.MAX_CARDS_PLAYED
	for node in _card_nodes:
		var cost: int = node.card_data.get("cost", 1)
		var affordable: bool = GameState.player_energy >= cost
		node.set_playable(can_still_play and affordable)

func _on_card_clicked(card_data: Dictionary) -> void:
	card_played.emit(card_data)
