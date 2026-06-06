extends Area2D

signal elevator_reset_requested

const InteractableOutline := preload("res://interactables/interactable_outline.gd")
const PolluxInteractSfx := preload("res://systems/pollux_interact_sfx.gd")

@export var elevator_paths: Array[NodePath] = []
@export var valid_body_names: PackedStringArray = ["Pollux"]
@export var reset_on_body_entered: bool = false

@onready var visual_sprite: Sprite2D = $Sprite2D

var _bodies_in_range: Array[Node2D] = []
var _interact_outline: Node

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_interact_outline = InteractableOutline.new()
	visual_sprite.add_child(_interact_outline)
	_interact_outline.setup(visual_sprite)

func _process(_delta: float) -> void:
	_update_interact_outline()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_interact():
		reset_elevator()
		get_viewport().set_input_as_handled()

func can_interact() -> bool:
	return _has_body_in_range() and _has_resettable_elevator()

func reset_elevator() -> void:
	if not _has_resettable_elevator():
		return

	PolluxInteractSfx.play_at(self, global_position)
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
	_update_interact_outline()

	if reset_on_body_entered:
		reset_elevator()

func _on_body_exited(body: Node2D) -> void:
	_bodies_in_range.erase(body)
	_update_interact_outline()

func _is_valid_interactor(body: Node2D) -> bool:
	return valid_body_names.is_empty() or body.name in valid_body_names

func _has_body_in_range() -> bool:
	for index in range(_bodies_in_range.size() - 1, -1, -1):
		if not is_instance_valid(_bodies_in_range[index]):
			_bodies_in_range.remove_at(index)

	return not _bodies_in_range.is_empty()

func _has_resettable_elevator() -> bool:
	for path in elevator_paths:
		var elevator := get_node_or_null(path)
		if elevator != null and elevator.has_method("can_reset_to_start") and elevator.call("can_reset_to_start"):
			return true

	return false

func _update_interact_outline() -> void:
	if _interact_outline != null:
		_interact_outline.set_active(can_interact())
