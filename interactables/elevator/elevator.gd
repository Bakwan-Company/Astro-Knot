extends AnimatableBody2D

@export var rise_distance: float = 256.0
@export var move_duration: float = 1.25
@export var can_return: bool = false
@export var required_body_names: PackedStringArray = ["Castor", "Pollux"]

var _start_position: Vector2
var _is_up: bool = false
var _is_moving: bool = false
var _move_target_is_up: bool = false
var _bodies_in_range: Array[Node2D] = []
var _frozen_bodies: Array[Node2D] = []
var _previous_body_frozen_meta: Dictionary = {}
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

	return _has_all_required_bodies()

func activate() -> void:
	var target_is_up := not _is_up
	var target_position := _start_position
	if target_is_up:
		target_position = _start_position + Vector2.UP * rise_distance

	_move_to(target_position, target_is_up)

func reset_to_start() -> void:
	if _move_tween:
		_move_tween.kill()

	if _is_moving:
		_set_lift_controls_frozen(false)

	if global_position.distance_to(_start_position) <= 0.1:
		_is_up = false
		_is_moving = false
		global_position = _start_position
		return

	_move_to(_start_position, false)

func force_reset_to_start() -> void:
	if _move_tween:
		_move_tween.kill()

	_set_lift_controls_frozen(false)
	_is_up = false
	_is_moving = false
	_move_target_is_up = false
	_bodies_in_range.clear()
	global_position = _start_position

func _move_to(target_position: Vector2, target_is_up: bool) -> void:
	_is_moving = true
	_move_target_is_up = target_is_up
	_set_lift_controls_frozen(true)
	if _move_tween:
		_move_tween.kill()

	_move_tween = create_tween()
	_move_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_move_tween.tween_property(self, "global_position", target_position, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_move_tween.finished.connect(_on_move_finished)

func _on_move_finished() -> void:
	_is_up = _move_target_is_up
	_is_moving = false
	_set_lift_controls_frozen(false)

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if _is_valid_interactor(body) and body not in _bodies_in_range:
		_bodies_in_range.append(body)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	_bodies_in_range.erase(body)

func _is_valid_interactor(body: Node2D) -> bool:
	return required_body_names.is_empty() or body.name in required_body_names

func _has_all_required_bodies() -> bool:
	for index in range(_bodies_in_range.size() - 1, -1, -1):
		if not is_instance_valid(_bodies_in_range[index]):
			_bodies_in_range.remove_at(index)

	if required_body_names.is_empty():
		return not _bodies_in_range.is_empty()

	for body_name in required_body_names:
		var has_body := false
		for body in _bodies_in_range:
			if body.name == body_name:
				has_body = true
				break

		if not has_body:
			return false

	return true

func _set_lift_controls_frozen(frozen: bool) -> void:
	if frozen:
		_frozen_bodies.clear()
		_previous_body_frozen_meta.clear()
		for body in _bodies_in_range:
			if not is_instance_valid(body):
				continue

			_frozen_bodies.append(body)
			_previous_body_frozen_meta[body] = body.get_meta("controls_frozen", false)
			body.set_meta("controls_frozen", true)

			if body.has_method("set_controls_frozen"):
				body.call("set_controls_frozen", true)
			elif body is RigidBody2D:
				body.linear_velocity = Vector2.ZERO
				body.angular_velocity = 0.0
		return

	for body in _frozen_bodies:
		if not is_instance_valid(body):
			continue

		var was_frozen := _previous_body_frozen_meta.get(body, false) as bool
		body.set_meta("controls_frozen", was_frozen)
		if body.has_method("set_controls_frozen"):
			body.call("set_controls_frozen", was_frozen)

	_frozen_bodies.clear()
	_previous_body_frozen_meta.clear()
