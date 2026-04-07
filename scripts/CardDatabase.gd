extends Node
## CardDatabase — AutoLoad singleton
## Loads all card JSON files and provides card data by ID.
## Add new cards by editing JSON files in res://data/cards/

var _cards: Dictionary = {}   # id -> card Dictionary
var _tiers: Dictionary = {}   # tier_name -> Array[Dictionary]

const CARD_DIR := "res://data/cards/"

func _ready() -> void:
	_load_all_cards()

func _load_all_cards() -> void:
	var dir := DirAccess.open(CARD_DIR)
	if dir == null:
		push_error("CardDatabase: Could not open " + CARD_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			_load_card_file(CARD_DIR + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	print("CardDatabase: Loaded %d cards" % _cards.size())

func _load_card_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CardDatabase: Could not open " + path)
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("CardDatabase: JSON parse error in " + path)
		return

	var data = json.get_data()
	if data is Array:
		for card in data:
			_register_card(card)
	elif data is Dictionary:
		_register_card(data)

func _register_card(card: Dictionary) -> void:
	var id: String = card.get("id", "")
	if id.is_empty():
		push_warning("CardDatabase: Card missing 'id' field, skipping.")
		return
	_cards[id] = card

	var tier: String = card.get("tier", "base")
	if not _tiers.has(tier):
		_tiers[tier] = []
	_tiers[tier].append(card)

# ===================================================
# Public API
# ===================================================

func get_card(id: String) -> Dictionary:
	return _cards.get(id, {})

func get_all_cards() -> Array:
	return _cards.values()

func get_cards_by_tier(tier: String) -> Array:
	return _tiers.get(tier, [])

func get_starter_deck() -> Array[Dictionary]:
	## Returns a default starting deck (3 copies of each base card).
	var deck: Array[Dictionary] = []
	for card in get_cards_by_tier("base"):
		for i in range(3):
			deck.append(card.duplicate())
	return deck

func get_enemy_data(enemy_id: String) -> Dictionary:
	var path := "res://data/enemies/%s.json" % enemy_id
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CardDatabase: Could not open enemy file " + path)
		return {}

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("CardDatabase: JSON parse error in " + path)
		return {}

	return json.get_data()
