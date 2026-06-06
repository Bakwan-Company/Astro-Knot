extends Node

const OUTLINE_SHADER := preload("res://interactables/interactable_outline.gdshader")
const OUTLINE_DIRECTIONS: Array[Vector2] = [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN,
	Vector2(-0.7071068, -0.7071068),
	Vector2(0.7071068, -0.7071068),
	Vector2(-0.7071068, 0.7071068),
	Vector2(0.7071068, 0.7071068),
]

@export var outline_color: Color = Color.WHITE
@export var outline_offset: float = 2.0
@export var min_alpha: float = 0.25
@export var max_alpha: float = 0.85
@export var pulse_speed: float = 1.6

var target_sprite: Sprite2D
var _outline_sprites: Array[Sprite2D] = []
var _outline_material: ShaderMaterial
var _is_active: bool = false
var _pulse_time: float = 0.0

func setup(sprite: Sprite2D) -> void:
	target_sprite = sprite
	_ensure_outline()
	_sync_outline_sprites()
	set_active(false)

func set_active(active: bool) -> void:
	if _is_active == active:
		return

	_is_active = active
	if _is_active:
		_sync_outline_sprites()
		_apply_pulse_alpha()
	_process_outline_visibility()
	set_process(_is_active)

func _ready() -> void:
	if target_sprite == null:
		target_sprite = get_parent() as Sprite2D
	_ensure_outline()
	_sync_outline_sprites()
	set_active(false)

func _process(delta: float) -> void:
	if target_sprite == null or not is_instance_valid(target_sprite):
		set_active(false)
		return

	_pulse_time += delta * pulse_speed
	_sync_outline_sprites()
	_apply_pulse_alpha()

func _ensure_outline() -> void:
	if target_sprite == null or not _outline_sprites.is_empty():
		return

	_outline_material = ShaderMaterial.new()
	_outline_material.shader = OUTLINE_SHADER

	for direction in OUTLINE_DIRECTIONS:
		var outline_sprite := Sprite2D.new()
		outline_sprite.name = "InteractOutline"
		outline_sprite.position = direction * outline_offset
		outline_sprite.show_behind_parent = true
		outline_sprite.material = _outline_material
		outline_sprite.visible = false
		target_sprite.add_child(outline_sprite)
		_outline_sprites.append(outline_sprite)

func _sync_outline_sprites() -> void:
	if target_sprite == null:
		return

	for index in range(_outline_sprites.size()):
		var outline_sprite := _outline_sprites[index]
		if outline_sprite == null or not is_instance_valid(outline_sprite):
			continue

		outline_sprite.texture = target_sprite.texture
		outline_sprite.centered = target_sprite.centered
		outline_sprite.offset = target_sprite.offset
		outline_sprite.flip_h = target_sprite.flip_h
		outline_sprite.flip_v = target_sprite.flip_v
		outline_sprite.hframes = target_sprite.hframes
		outline_sprite.vframes = target_sprite.vframes
		outline_sprite.frame = target_sprite.frame
		outline_sprite.region_enabled = target_sprite.region_enabled
		outline_sprite.region_rect = target_sprite.region_rect
		outline_sprite.position = OUTLINE_DIRECTIONS[index] * outline_offset

func _apply_pulse_alpha() -> void:
	if _outline_material == null:
		return

	var pulse := (sin(_pulse_time * TAU) + 1.0) * 0.5
	var alpha := lerpf(min_alpha, max_alpha, pulse)
	_outline_material.set_shader_parameter("outline_color", Color(outline_color.r, outline_color.g, outline_color.b, alpha))

func _process_outline_visibility() -> void:
	for outline_sprite in _outline_sprites:
		if outline_sprite != null and is_instance_valid(outline_sprite):
			outline_sprite.visible = _is_active
