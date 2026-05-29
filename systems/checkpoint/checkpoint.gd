extends Area2D

@export var valid_body_names: PackedStringArray = ["Castor"]
@export var activate_once: bool = false

var activated: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if activate_once and activated:
		return

	if not valid_body_names.is_empty() and String(body.name) not in valid_body_names:
		return

	var manager := get_node_or_null("/root/CheckpointManager")
	if manager == null or not manager.has_method("set_checkpoint"):
		return

	activated = true
	manager.call("set_checkpoint", self)
