extends Area2D

signal elevator_reset_requested

@export var elevator_paths: Array[NodePath] = []
@export var valid_body_names: PackedStringArray = ["Castor", "Pollux"]
@export var reset_on_body_entered: bool = false

var _bodies_in_range: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_interact():
		reset_elevator()
		get_viewport().set_input_as_handled()

func can_interact() -> bool:
	return not _bodies_in_range.is_empty()

func reset_elevator() -> void:
	elevator_reset_requested.emit()

	for path in elevator_paths:
		var elevator := get_node_or_null(path)
		if elevator != null and elevator.has_method("reset_to_start"):
			elevator.call("reset_to_start")

func _on_body_entered(body: Node2D) -> void:
	if not _is_valid_interactor(body):
		return

	if body not in _bodies_in_range:
		_bodies_in_range.append(body)

	if reset_on_body_entered:
		reset_elevator()

func _on_body_exited(body: Node2D) -> void:
	_bodies_in_range.erase(body)

func _is_valid_interactor(body: Node2D) -> bool:
	return valid_body_names.is_empty() or body.name in valid_body_names
