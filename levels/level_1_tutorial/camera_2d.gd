extends Camera2D

@export var castor: Node2D
@export var pollux: Node2D

@export var follow_speed: float = 6.0
@export var zoom_speed: float = 5.0
@export var min_zoom: float = 0.45
@export var max_zoom: float = 0.95
@export var padding: Vector2 = Vector2(220, 140)
@export var framing_offset: Vector2 = Vector2(0, -45)
@export var include_pollux: bool = true

func _process(delta: float) -> void:
	if castor == null:
		return

	var target_position: Vector2 = castor.global_position + framing_offset
	if include_pollux and pollux != null:
		target_position = ((castor.global_position + pollux.global_position) * 0.5) + framing_offset

	global_position = global_position.lerp(target_position, follow_speed * delta)

	var target_zoom: Vector2 = Vector2(max_zoom, max_zoom)
	if include_pollux and pollux != null:
		var distance: Vector2 = (castor.global_position - pollux.global_position).abs()
		var viewport_size: Vector2 = get_viewport_rect().size
		var target_size: Vector2 = distance + padding

		var zoom_x: float = viewport_size.x / max(target_size.x, 1.0)
		var zoom_y: float = viewport_size.y / max(target_size.y, 1.0)
		var target_zoom_value: float = clamp(min(zoom_x, zoom_y), min_zoom, max_zoom)
		target_zoom = Vector2(target_zoom_value, target_zoom_value)

	zoom = zoom.lerp(target_zoom, zoom_speed * delta)
