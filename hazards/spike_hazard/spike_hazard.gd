extends Area2D

signal triggered(body: Node2D)

@export var valid_body_names: PackedStringArray = ["Castor", "Pollux"]
@export var death_type: String = "spike"
@export var game_over_scene: PackedScene = preload("res://ui/game_over/GameOverOverlay.tscn")

var _is_triggered: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _is_triggered:
		return

	if not valid_body_names.is_empty() and body.name not in valid_body_names:
		return

	_is_triggered = true
	triggered.emit(body)
	var checkpoint_manager := get_node_or_null("/root/CheckpointManager")
	if checkpoint_manager != null and checkpoint_manager.has_method("kill_with_overlay"):
		checkpoint_manager.call("kill_with_overlay", death_type, game_over_scene)
	else:
		show_game_over()

func reset() -> void:
	_is_triggered = false

func show_game_over() -> void:
	if not game_over_scene:
		return

	var overlay: Node = game_over_scene.instantiate()
	var overlay_parent: Node = self
	if get_tree().current_scene:
		overlay_parent = get_tree().current_scene

	overlay_parent.add_child(overlay)
	if overlay.has_method("show_death"):
		overlay.call("show_death", death_type)

	get_tree().paused = true
