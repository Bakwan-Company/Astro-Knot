extends Area2D

signal triggered(body: Node2D)

@export var valid_body_names: PackedStringArray = ["Castor", "Pollux"]

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
	get_tree().call_deferred("reload_current_scene")
