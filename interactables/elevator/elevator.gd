extends AnimatableBody2D

@export var rise_distance: float = 256.0
@export var move_duration: float = 1.25
@export var can_return: bool = false
@export var valid_body_names: PackedStringArray = ["Pollux"]

var _start_position: Vector2
var _is_up: bool = false
var _is_moving: bool = false
var _bodies_in_range: Array[Node2D] = []
var _move_tween: Tween

func _ready() -> void:
	_start_position = global_position
	$InteractionArea.body_entered.connect(_on_interaction_area_body_entered)
	$InteractionArea.body_exited.connect(_on_interaction_area_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_interact():
		activate()
		get_viewport().set_input_as_handled()

func can_interact() -> bool:
	if _is_moving:
		return false

	if _is_up and not can_return:
		return false

	return not _bodies_in_range.is_empty()

func activate() -> void:
	var target_position := _start_position
	if not _is_up:
		target_position = _start_position + Vector2.UP * rise_distance

	_move_to(target_position)

func _move_to(target_position: Vector2) -> void:
	_is_moving = true
	if _move_tween:
		_move_tween.kill()

	_move_tween = create_tween()
	_move_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_move_tween.tween_property(self, "global_position", target_position, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_move_tween.finished.connect(_on_move_finished)

func _on_move_finished() -> void:
	_is_up = not _is_up
	_is_moving = false

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if _is_valid_interactor(body) and body not in _bodies_in_range:
		_bodies_in_range.append(body)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	_bodies_in_range.erase(body)

func _is_valid_interactor(body: Node2D) -> bool:
	return valid_body_names.is_empty() or body.name in valid_body_names
