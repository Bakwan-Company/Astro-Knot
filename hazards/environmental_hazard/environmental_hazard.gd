extends Area2D

signal triggered(body: Node2D)

@export var valid_body_names: PackedStringArray = ["Castor", "Pollux"]
@export var death_type: String = "environment"

var _is_reloading: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = true

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _is_reloading:
		return

	if not valid_body_names.is_empty() and body.name not in valid_body_names:
		return

	triggered.emit(body)
	_is_reloading = true
	var checkpoint_manager := get_node_or_null("/root/CheckpointManager")
	if checkpoint_manager != null and checkpoint_manager.has_method("kill"):
		checkpoint_manager.call("kill", death_type)
	else:
		get_tree().call_deferred("reload_current_scene")

func reset() -> void:
	_is_reloading = false
