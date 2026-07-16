extends Node

signal state_changed(snapshot: Dictionary)
signal event_state_changed(state: String)
signal outfit_owned(outfit_id: String)
signal outfit_equipped(outfit_id: String)

const WardrobeCatalog = preload("res://scripts/wardrobe_catalog.gd")
const SAVE_PATH := "user://wardrobe_state_v1.json"
const SAVE_VERSION := 1
const EVENT_LOCKED := "locked"
const EVENT_PENDING := "pending"
const EVENT_COLLECTING := "collecting"
const EVENT_UNLOCKED := "unlocked"
const VALID_EVENT_STATES := [EVENT_LOCKED, EVENT_PENDING, EVENT_COLLECTING, EVENT_UNLOCKED]

var event_state := EVENT_LOCKED
var collected_bundle_ids: Array[String] = []
var owned_outfit_ids: Array[String] = []
var equipped_outfit_id := WardrobeCatalog.DEFAULT_OUTFIT_ID

func _ready() -> void:
	_reset_to_defaults()
	_load_state()

func mark_event_pending() -> bool:
	if event_state != EVENT_LOCKED:
		return false
	event_state = EVENT_PENDING
	_commit_state()
	event_state_changed.emit(event_state)
	return true

func begin_event() -> bool:
	if event_state != EVENT_PENDING:
		return false
	event_state = EVENT_COLLECTING
	_commit_state()
	event_state_changed.emit(event_state)
	return true

func collect_bundle(bundle_id: String) -> bool:
	if event_state != EVENT_COLLECTING or bundle_id == "" or collected_bundle_ids.has(bundle_id):
		return false
	collected_bundle_ids.append(bundle_id)
	_commit_state()
	return true

func collected_bundle_count() -> int:
	return collected_bundle_ids.size()

func can_complete_event() -> bool:
	return event_state == EVENT_COLLECTING and collected_bundle_ids.size() >= 3

func unlock_wardrobe() -> bool:
	if event_state == EVENT_UNLOCKED:
		return false
	if event_state == EVENT_COLLECTING and not can_complete_event():
		return false
	event_state = EVENT_UNLOCKED
	_commit_state()
	event_state_changed.emit(event_state)
	return true

func is_wardrobe_unlocked() -> bool:
	return event_state == EVENT_UNLOCKED

func owns_outfit(outfit_id: String) -> bool:
	return owned_outfit_ids.has(outfit_id)

func grant_outfit(outfit_id: String) -> bool:
	if not WardrobeCatalog.has_outfit(outfit_id) or owns_outfit(outfit_id):
		return false
	owned_outfit_ids.append(outfit_id)
	_commit_state()
	outfit_owned.emit(outfit_id)
	return true

func purchase_outfit(outfit_id: String, available_coins: int) -> Dictionary:
	if event_state != EVENT_UNLOCKED:
		return {"success": false, "reason": "wardrobe_locked", "remaining_coins": available_coins}
	if owns_outfit(outfit_id):
		return {"success": false, "reason": "already_owned", "remaining_coins": available_coins}
	var outfit := WardrobeCatalog.get_outfit(outfit_id)
	if outfit.is_empty() or not WardrobeCatalog.model_is_available(outfit_id):
		return {"success": false, "reason": "model_unavailable", "remaining_coins": available_coins}
	var price := maxi(int(outfit.get("price", 0)), 0)
	if available_coins < price:
		return {"success": false, "reason": "insufficient_coins", "remaining_coins": available_coins, "missing_coins": price - available_coins}
	owned_outfit_ids.append(outfit_id)
	_commit_state()
	outfit_owned.emit(outfit_id)
	return {"success": true, "reason": "", "remaining_coins": available_coins - price, "price": price}

func equip_outfit(outfit_id: String) -> bool:
	if not owns_outfit(outfit_id) or not WardrobeCatalog.has_outfit(outfit_id):
		return false
	if equipped_outfit_id == outfit_id:
		return true
	equipped_outfit_id = outfit_id
	_commit_state()
	outfit_equipped.emit(outfit_id)
	return true

func snapshot() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"event_state": event_state,
		"collected_bundle_ids": collected_bundle_ids.duplicate(),
		"owned_outfit_ids": owned_outfit_ids.duplicate(),
		"equipped_outfit_id": equipped_outfit_id,
	}

func _reset_to_defaults() -> void:
	event_state = EVENT_LOCKED
	collected_bundle_ids.clear()
	owned_outfit_ids = WardrobeCatalog.default_owned_ids()
	equipped_outfit_id = WardrobeCatalog.DEFAULT_OUTFIT_ID

func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data := parsed as Dictionary
	if int(data.get("version", 0)) != SAVE_VERSION:
		return
	var loaded_state := str(data.get("event_state", EVENT_LOCKED))
	if VALID_EVENT_STATES.has(loaded_state):
		event_state = loaded_state
	collected_bundle_ids.clear()
	for raw_id in data.get("collected_bundle_ids", []):
		var bundle_id := str(raw_id)
		if bundle_id != "" and not collected_bundle_ids.has(bundle_id):
			collected_bundle_ids.append(bundle_id)
	owned_outfit_ids = WardrobeCatalog.default_owned_ids()
	for raw_id in data.get("owned_outfit_ids", []):
		var outfit_id := str(raw_id)
		if WardrobeCatalog.has_outfit(outfit_id) and not owned_outfit_ids.has(outfit_id):
			owned_outfit_ids.append(outfit_id)
	var loaded_equipped := str(data.get("equipped_outfit_id", WardrobeCatalog.DEFAULT_OUTFIT_ID))
	if owned_outfit_ids.has(loaded_equipped) and WardrobeCatalog.has_outfit(loaded_equipped):
		equipped_outfit_id = loaded_equipped

func _commit_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(snapshot(), "\t"))
	state_changed.emit(snapshot())
