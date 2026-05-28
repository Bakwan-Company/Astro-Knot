extends Area2D

signal death_triggered(death_type: String)

@export var death_type: String = "fall"
@export var player_body_names: Array[StringName] = [&"Castor", &"Pollux"]
@export var game_over_scene: PackedScene

var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func reset() -> void:
	triggered = false

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return

	if not player_body_names.has(body.name) and not body.is_in_group("player"):
		return

	triggered = true
	var has_external_handler := not get_signal_connection_list(&"death_triggered").is_empty()
	death_triggered.emit(death_type)

	if has_external_handler:
		return

	if game_over_scene == null:
		get_tree().call_deferred("reload_current_scene")
		return

	var overlay := game_over_scene.instantiate()
	get_tree().current_scene.add_child(overlay)
	if overlay.has_method("show_death"):
		overlay.call("show_death", death_type)
	get_tree().paused = true
