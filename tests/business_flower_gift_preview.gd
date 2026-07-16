extends Node

const OUTPUT_DIR := "res://artifacts/business_flower_gift"
const PREVIEW_SIZES := [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]


func _ready() -> void:
	call_deferred("_run")


func _set_preview_state(world: Node, manager: Node, state: String, base_gifts: Dictionary) -> void:
	match state:
		"locked":
			world.set("_business_level_stars", {})
			manager.set("unlocked", false)
			manager.set("selected_gift", "calming_bouquet")
			var locked_gifts := base_gifts.duplicate(true)
			locked_gifts["calming_bouquet"] = 1
			manager.set("gifts", locked_gifts)
		"empty":
			world.set("_business_level_stars", {"5": 1})
			manager.set("unlocked", true)
			manager.set("selected_gift", "")
			manager.set("gifts", base_gifts.duplicate(true))
		"equipped":
			world.set("_business_level_stars", {"5": 1})
			manager.set("unlocked", true)
			manager.set("selected_gift", "calming_bouquet")
			var equipped_gifts := base_gifts.duplicate(true)
			equipped_gifts["calming_bouquet"] = 3
			manager.set("gifts", equipped_gifts)
	manager.emit_signal("state_changed")
	world.call("_update_business_flower_gift_button")


func _run() -> void:
	var manager := get_node_or_null("/root/FlowerGardenManager")
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	if manager == null or packed == null:
		get_tree().quit(1)
		return
	var original := {
		"unlocked": bool(manager.get("unlocked")),
		"selected_gift": str(manager.get("selected_gift")),
		"gifts": (manager.get("gifts") as Dictionary).duplicate(true),
		"persistence_suspended": bool(manager.get("_persistence_suspended")),
	}
	manager.set("_persistence_suspended", true)
	manager.set("unlocked", false)
	manager.set("selected_gift", "")
	var world := packed.instantiate()
	add_child(world)
	await get_tree().process_frame
	await get_tree().process_frame
	world.set("_business_level_stars", {})
	world.call("_build_chapter_one_scene")
	for _frame in range(4):
		await get_tree().process_frame
	if not bool(world.call("_open_business_prep")):
		manager.set("_persistence_suspended", bool(original.get("persistence_suspended", false)))
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var window := get_window()
	var base_gifts := (original.get("gifts", {}) as Dictionary).duplicate(true)
	for state in ["locked", "empty", "equipped"]:
		_set_preview_state(world, manager, state, base_gifts)
		for viewport_size in PREVIEW_SIZES:
			window.size = viewport_size
			world.call("_update_business_flower_gift_button")
			for _frame in range(4):
				await get_tree().process_frame
			window.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [OUTPUT_DIR, state, viewport_size.x, viewport_size.y])
	world.queue_free()
	for _frame in range(4):
		await get_tree().process_frame
	manager.set("unlocked", bool(original.get("unlocked", false)))
	manager.set("selected_gift", str(original.get("selected_gift", "")))
	manager.set("gifts", (original.get("gifts", {}) as Dictionary).duplicate(true))
	manager.set("_persistence_suspended", bool(original.get("persistence_suspended", false)))
	print("BUSINESS_FLOWER_GIFT_PREVIEW: PASS")
	get_tree().quit(0)
