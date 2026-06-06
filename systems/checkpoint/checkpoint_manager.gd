extends Node

signal checkpoint_changed(checkpoint: Node)
signal respawned(death_type: String)

@export var game_over_scene: PackedScene = preload("res://ui/game_over/GameOverOverlay.tscn")

var checkpoint_scene_path: String = ""
var castor_position: Vector2 = Vector2.ZERO
var pollux_position: Vector2 = Vector2.ZERO
var rope_length: float = 0.0
var tether_connected: bool = true
var has_checkpoint: bool = false
var respawning: bool = false
var death_pending: bool = false
var last_checkpoint_name: String = "none"
var last_death_type: String = "none"
var last_status: String = "waiting"

func set_checkpoint(checkpoint: Node) -> void:
	if checkpoint == null:
		last_status = "ignored null checkpoint"
		return

	var current_scene := get_tree().current_scene
	checkpoint_scene_path = current_scene.scene_file_path if current_scene != null else ""

	var castor_marker := checkpoint.get_node_or_null("CastorSpawn") as Marker2D
	var pollux_marker := checkpoint.get_node_or_null("PolluxSpawn") as Marker2D
	if castor_marker == null or pollux_marker == null:
		last_status = "missing spawn markers"
		return

	castor_position = castor_marker.global_position
	pollux_position = pollux_marker.global_position

	var rope_manager := find_rope_manager()
	if rope_manager != null:
		if "current_rope_length" in rope_manager:
			rope_length = float(rope_manager.get("current_rope_length"))
		if rope_manager.has_method("is_tether_connected"):
			tether_connected = bool(rope_manager.call("is_tether_connected"))

	has_checkpoint = true
	last_checkpoint_name = checkpoint.name
	last_status = "set"
	checkpoint_changed.emit(checkpoint)

func kill(death_type: String = "hazard") -> void:
	if respawning or death_pending:
		last_status = "death already pending"
		return

	last_death_type = death_type
	if not has_checkpoint or not is_checkpoint_for_current_scene():
		death_pending = true
		last_status = "overlay: no checkpoint"
		call_deferred("_show_game_over", death_type, game_over_scene, false)
		return

	death_pending = true
	last_status = "showing overlay"
	call_deferred("_show_game_over", death_type, game_over_scene, true)

func kill_with_overlay(death_type: String, overlay_scene: PackedScene) -> void:
	if respawning or death_pending:
		last_status = "death already pending"
		return

	last_death_type = death_type
	if not has_checkpoint or not is_checkpoint_for_current_scene():
		death_pending = true
		last_status = "overlay: no checkpoint"
		call_deferred("_show_game_over", death_type, overlay_scene if overlay_scene != null else game_over_scene, false)
		return

	death_pending = true
	last_status = "showing overlay"
	call_deferred("_show_game_over", death_type, overlay_scene if overlay_scene != null else game_over_scene, true)

func restart_from_checkpoint(death_type: String = "pause_restart") -> bool:
	if respawning:
		last_status = "manual restart blocked: respawning"
		return false

	if not has_checkpoint or not is_checkpoint_for_current_scene():
		last_status = "manual restart: no checkpoint"
		return false

	last_death_type = death_type
	death_pending = false
	_begin_respawn(death_type)
	return true

func _show_game_over(death_type: String, overlay_scene: PackedScene, use_checkpoint_restart: bool) -> void:
	if overlay_scene == null:
		if use_checkpoint_restart:
			_begin_respawn(death_type)
		else:
			death_pending = false
			get_tree().call_deferred("reload_current_scene")
		return

	var overlay: Node = overlay_scene.instantiate()
	var overlay_parent: Node = self
	if get_tree().current_scene != null:
		overlay_parent = get_tree().current_scene

	overlay_parent.add_child(overlay)
	overlay.set("use_checkpoint_restart", true)
	if overlay.has_method("show_death"):
		overlay.call("show_death", death_type)
	if overlay.has_signal("restart_requested"):
		overlay.connect(
			"restart_requested",
			Callable(self, "_on_overlay_restart_requested").bind(death_type, use_checkpoint_restart),
			CONNECT_ONE_SHOT
		)

	get_tree().paused = true

func _on_overlay_restart_requested(death_type: String, use_checkpoint_restart: bool) -> void:
	if use_checkpoint_restart:
		_begin_respawn(death_type)
	else:
		death_pending = false
		get_tree().paused = false
		get_tree().call_deferred("reload_current_scene")

func _begin_respawn(death_type: String) -> void:
	get_tree().paused = false
	death_pending = false
	respawning = true
	last_status = "respawning"
	call_deferred("_respawn", death_type)

func _respawn(death_type: String) -> void:
	var castor := find_node_by_name("Castor") as CharacterBody2D
	var pollux := find_node_by_name("Pollux") as RigidBody2D
	var rope_manager := find_rope_manager()

	if castor == null or pollux == null:
		respawning = false
		death_pending = false
		last_status = "reload: missing actor"
		get_tree().call_deferred("reload_current_scene")
		return

	get_tree().paused = false

	if castor.has_method("set_throw_mode_locked"):
		castor.call("set_throw_mode_locked", false)
	castor.velocity = Vector2.ZERO
	castor.global_position = castor_position

	pollux.linear_velocity = Vector2.ZERO
	pollux.angular_velocity = 0.0
	pollux.global_position = pollux_position

	if rope_manager != null:
		if "current_rope_length" in rope_manager and rope_length > 0.0:
			rope_manager.set("current_rope_length", rope_length)
		if rope_manager.has_method("set_tether_connected"):
			rope_manager.call("set_tether_connected", tether_connected)
		if rope_manager.has_method("update_rope_visual"):
			rope_manager.call("update_rope_visual")

	if rope_manager == null or not tether_connected:
		pollux.freeze = true
		pollux.sleeping = true
	else:
		pollux.freeze = false
		pollux.sleeping = false

	reset_hazards()
	reset_level_2_elevators()
	respawning = false
	last_status = "respawned"
	respawned.emit(death_type)

func get_debug_summary() -> String:
	return "cp %s at C(%.0f,%.0f) P(%.0f,%.0f) death %s %s" % [
		last_checkpoint_name if has_checkpoint else "none",
		castor_position.x,
		castor_position.y,
		pollux_position.x,
		pollux_position.y,
		last_death_type,
		last_status,
	]

func is_checkpoint_for_current_scene() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	return checkpoint_scene_path == "" or checkpoint_scene_path == current_scene.scene_file_path

func find_rope_manager() -> Node:
	return find_node_by_name("RopeManager")

func find_node_by_name(node_name: StringName) -> Node:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null
	return find_node_recursive(current_scene, node_name)

func find_node_recursive(root: Node, node_name: StringName) -> Node:
	if root.name == node_name:
		return root

	for child in root.get_children():
		var found := find_node_recursive(child, node_name)
		if found != null:
			return found

	return null

func reset_hazards() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	reset_hazards_recursive(current_scene)

func reset_hazards_recursive(root: Node) -> void:
	if root.has_method("reset"):
		root.call("reset")
	if "_is_triggered" in root:
		root.set("_is_triggered", false)
	if "_is_reloading" in root:
		root.set("_is_reloading", false)

	for child in root.get_children():
		reset_hazards_recursive(child)

func reset_level_2_elevators() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null or current_scene.scene_file_path != "res://levels/level_2/Level2.tscn":
		return

	reset_level_2_elevators_recursive(current_scene)

func reset_level_2_elevators_recursive(root: Node) -> void:
	if root.has_method("force_reset_to_start"):
		root.call("force_reset_to_start")
	elif root.has_method("reset_to_start"):
		root.call("reset_to_start")

	for child in root.get_children():
		reset_level_2_elevators_recursive(child)
