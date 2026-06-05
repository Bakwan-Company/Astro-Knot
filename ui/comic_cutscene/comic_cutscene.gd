extends CanvasLayer

signal finished

@export_group("Comic Pages")
@export var pages: Array[Texture2D] = []
@export var captions: Array[String] = []
@export var start_page: int = 0

@export_group("Controls")
@export var skippable: bool = false
@export var pause_tree: bool = true
@export var next_text: String = "Next"
@export var previous_text: String = "Back"
@export var skip_text: String = "Skip"
@export var finish_text: String = "Done"
@export var page_aspect_ratio: float = 16.0 / 9.0
@export_range(0.5, 1.0) var page_width_ratio: float = 0.74
@export_range(0.5, 1.0) var page_height_ratio: float = 0.72

@export_group("Intro Transition")
@export var intro_enabled: bool = true
@export var intro_fade_time: float = 0.42
@export var intro_slide_time: float = 0.0
@export var intro_slide_offset_ratio: float = 0.0

@export_group("Film Strip")
@export var page_slide_time: float = 0.56
@export var close_fade_time: float = 0.24
@export var side_panel_scale: float = 0.84
@export var side_panel_gap: float = 28.0
@export var side_panel_alpha: float = 0.34

@onready var dimmer: ColorRect = $Dimmer
@onready var root: VBoxContainer = $Root
@onready var page_frame: PanelContainer = $Root/PageFrame
@onready var page_texture: TextureRect = $Root/PageFrame/PageTexture
@onready var caption_panel: PanelContainer = $Root/CaptionPanel
@onready var caption_label: Label = $Root/CaptionPanel/Margin/CaptionLabel
@onready var footer: HBoxContainer = $Root/Footer
@onready var page_counter: Label = $Root/Footer/PageCounter
@onready var previous_button: Button = $Root/Footer/PreviousButton
@onready var skip_button: Button = $Root/Footer/SkipButton
@onready var next_button: Button = $Root/Footer/NextButton

var current_page: int = 0
var previous_pause_state: bool = false
var is_closing: bool = false
var is_intro_playing: bool = false
var is_page_animating: bool = false
var dimmer_final_color: Color
var film_bars: Control
var side_panel_layer: Control
var left_preview_frame: PanelContainer
var right_preview_frame: PanelContainer
var left_preview_texture: TextureRect
var right_preview_texture: TextureRect
var root_home_position: Vector2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	previous_pause_state = get_tree().paused
	if pause_tree:
		get_tree().paused = true

	current_page = clampi(start_page, 0, maxi(pages.size() - 1, 0))
	previous_button.pressed.connect(previous_page)
	next_button.pressed.connect(next_page)
	skip_button.pressed.connect(skip)
	get_viewport().size_changed.connect(_fit_page_frame)
	_apply_style()
	_create_side_previews()
	_prime_intro_state()
	_fit_page_frame()
	_refresh_page()
	next_button.grab_focus()
	_play_intro_transition()

func _unhandled_input(event: InputEvent) -> void:
	if is_closing or is_intro_playing or is_page_animating:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		get_viewport().set_input_as_handled()
		next_page()
	elif event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		previous_page()
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		next_page()
	elif skippable and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		skip()

func previous_page() -> void:
	if is_closing or is_page_animating or current_page <= 0:
		return

	_slide_to_page(current_page - 1, -1)

func next_page() -> void:
	if is_closing or is_page_animating:
		return

	if current_page >= pages.size() - 1:
		_close()
		return

	_slide_to_page(current_page + 1, 1)

func skip() -> void:
	if skippable:
		_close()

func _close() -> void:
	if is_closing:
		return

	is_closing = true
	await _play_close_transition()
	if pause_tree:
		get_tree().paused = previous_pause_state
	finished.emit()
	queue_free()

func _refresh_page() -> void:
	var has_pages := pages.size() > 0
	page_texture.texture = pages[current_page] if has_pages else null

	var caption := ""
	if current_page < captions.size():
		caption = captions[current_page]

	caption_panel.visible = caption.strip_edges() != ""
	caption_label.text = caption
	page_counter.text = "%d / %d" % [current_page + 1, maxi(pages.size(), 1)]
	previous_button.text = previous_text
	previous_button.disabled = current_page <= 0
	next_button.text = finish_text if current_page >= pages.size() - 1 else next_text
	next_button.disabled = false
	skip_button.text = skip_text
	skip_button.visible = skippable
	skip_button.disabled = false
	_refresh_side_previews()

func _apply_style() -> void:
	dimmer.color = Color(0.0, 0.0, 0.0, 1.0)
	dimmer_final_color = dimmer.color
	_create_film_bars()

	var page_style := StyleBoxFlat.new()
	page_style.bg_color = Color(0.05, 0.045, 0.04, 1.0)
	page_style.border_color = Color(0.5, 0.42, 0.32, 0.9)
	page_style.border_width_left = 2
	page_style.border_width_top = 2
	page_style.border_width_right = 2
	page_style.border_width_bottom = 2
	page_style.corner_radius_top_left = 4
	page_style.corner_radius_top_right = 4
	page_style.corner_radius_bottom_left = 4
	page_style.corner_radius_bottom_right = 4
	page_frame.add_theme_stylebox_override("panel", page_style)

	var caption_style := StyleBoxFlat.new()
	caption_style.bg_color = Color(0.03, 0.027, 0.023, 0.92)
	caption_style.border_color = Color(0.42, 0.34, 0.25, 0.8)
	caption_style.border_width_left = 1
	caption_style.border_width_top = 1
	caption_style.border_width_right = 1
	caption_style.border_width_bottom = 1
	caption_style.corner_radius_top_left = 3
	caption_style.corner_radius_top_right = 3
	caption_style.corner_radius_bottom_left = 3
	caption_style.corner_radius_bottom_right = 3
	caption_panel.add_theme_stylebox_override("panel", caption_style)

	caption_label.add_theme_color_override("font_color", Color(0.86, 0.8, 0.7, 1.0))
	page_counter.add_theme_color_override("font_color", Color(0.72, 0.66, 0.56, 1.0))

	_style_button(previous_button, false)
	_style_button(next_button, true)
	_style_button(skip_button, false)

func _make_page_style(is_side_panel: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.045, 0.04, 1.0)
	style.border_color = Color(0.32, 0.29, 0.25, 0.75) if is_side_panel else Color(0.5, 0.42, 0.32, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _style_button(button: Button, primary: bool) -> void:
	button.custom_minimum_size = Vector2(92.0, 34.0)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color(0.06, 0.045, 0.035, 1.0) if primary else Color(0.72, 0.66, 0.58, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.44, 0.38, 0.78))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.72, 0.54, 0.3, 1.0) if primary else Color(0.08, 0.073, 0.065, 1.0)
	style.border_color = Color(0.86, 0.68, 0.42, 1.0) if primary else Color(0.34, 0.29, 0.24, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3

	var disabled_style := StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.045, 0.041, 0.037, 0.74)
	disabled_style.border_color = Color(0.18, 0.16, 0.13, 0.8)
	disabled_style.border_width_left = 1
	disabled_style.border_width_top = 1
	disabled_style.border_width_right = 1
	disabled_style.border_width_bottom = 1
	disabled_style.corner_radius_top_left = 3
	disabled_style.corner_radius_top_right = 3
	disabled_style.corner_radius_bottom_left = 3
	disabled_style.corner_radius_bottom_right = 3

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_stylebox_override("disabled", disabled_style)

func _fit_page_frame() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var max_width := viewport_size.x * page_width_ratio
	var max_height := viewport_size.y * page_height_ratio
	var frame_width := max_width
	var frame_height := frame_width / page_aspect_ratio

	if frame_height > max_height:
		frame_height = max_height
		frame_width = frame_height * page_aspect_ratio

	root.offset_left = (viewport_size.x - frame_width) * 0.5
	root.offset_right = -root.offset_left
	root.offset_top = maxf((viewport_size.y - frame_height) * 0.42, 18.0)
	root.offset_bottom = -22.0
	root_home_position = root.position
	page_frame.custom_minimum_size = Vector2(frame_width, frame_height)
	page_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_layout_film_bars(viewport_size)
	_layout_side_previews()

func _create_film_bars() -> void:
	if film_bars != null:
		return

	film_bars = Control.new()
	film_bars.name = "FilmBars"
	film_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	film_bars.anchors_preset = Control.PRESET_FULL_RECT
	film_bars.anchor_right = 1.0
	film_bars.anchor_bottom = 1.0
	film_bars.grow_horizontal = Control.GROW_DIRECTION_BOTH
	film_bars.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(film_bars)
	move_child(film_bars, dimmer.get_index() + 1)

	var top_bar := ColorRect.new()
	top_bar.name = "TopBar"
	top_bar.color = Color(0.0, 0.0, 0.0, 0.86)
	film_bars.add_child(top_bar)

	var bottom_bar := ColorRect.new()
	bottom_bar.name = "BottomBar"
	bottom_bar.color = Color(0.0, 0.0, 0.0, 0.86)
	film_bars.add_child(bottom_bar)

func _create_side_previews() -> void:
	if side_panel_layer != null:
		return

	side_panel_layer = Control.new()
	side_panel_layer.name = "SidePanelLayer"
	side_panel_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side_panel_layer.anchors_preset = Control.PRESET_FULL_RECT
	side_panel_layer.anchor_right = 1.0
	side_panel_layer.anchor_bottom = 1.0
	side_panel_layer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	side_panel_layer.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(side_panel_layer)
	move_child(side_panel_layer, root.get_index())

	left_preview_frame = _create_preview_frame("LeftPreview")
	left_preview_texture = left_preview_frame.get_node("PageTexture") as TextureRect
	side_panel_layer.add_child(left_preview_frame)

	right_preview_frame = _create_preview_frame("RightPreview")
	right_preview_texture = right_preview_frame.get_node("PageTexture") as TextureRect
	side_panel_layer.add_child(right_preview_frame)

func _create_preview_frame(frame_name: String) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.name = frame_name
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _make_page_style(true))
	frame.modulate = Color(0.58, 0.58, 0.58, side_panel_alpha)

	var texture := TextureRect.new()
	texture.name = "PageTexture"
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture.layout_mode = 2
	frame.add_child(texture)
	return frame

func _create_transition_frame(texture: Texture2D) -> PanelContainer:
	var frame := _create_preview_frame("TransitionPreview")
	frame.add_theme_stylebox_override("panel", _make_page_style(false))
	frame.modulate = Color.WHITE
	(frame.get_node("PageTexture") as TextureRect).texture = texture
	side_panel_layer.add_child(frame)
	return frame

func _create_side_transition_frame(texture: Texture2D) -> PanelContainer:
	var frame := _create_preview_frame("SideTransitionPreview")
	(frame.get_node("PageTexture") as TextureRect).texture = texture
	side_panel_layer.add_child(frame)
	return frame

func _prime_intro_state() -> void:
	if not intro_enabled:
		return

	root.visible = false
	if film_bars != null:
		film_bars.modulate.a = 0.0
	if side_panel_layer != null:
		side_panel_layer.visible = false
		side_panel_layer.modulate.a = 0.0

func _layout_film_bars(viewport_size: Vector2) -> void:
	if film_bars == null:
		return

	var bar_height := maxf(viewport_size.y * 0.07, 18.0)
	var top_bar := film_bars.get_node("TopBar") as ColorRect
	var bottom_bar := film_bars.get_node("BottomBar") as ColorRect
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = bar_height
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.offset_top = -bar_height

func _layout_side_previews() -> void:
	if side_panel_layer == null:
		return

	var frame_size := page_frame.custom_minimum_size
	var side_size := frame_size * side_panel_scale
	var side_y := root_home_position.y + (frame_size.y - side_size.y) * 0.5
	var left_x := root_home_position.x - side_size.x - side_panel_gap
	var right_x := root_home_position.x + frame_size.x + side_panel_gap

	for frame in [left_preview_frame, right_preview_frame]:
		frame.custom_minimum_size = side_size
		frame.size = side_size
		frame.modulate = Color(0.58, 0.58, 0.58, side_panel_alpha)

	left_preview_frame.position = Vector2(left_x, side_y)
	right_preview_frame.position = Vector2(right_x, side_y)
	_refresh_side_previews()

func _refresh_side_previews() -> void:
	if side_panel_layer == null:
		return

	var has_pages := pages.size() > 0
	left_preview_frame.visible = has_pages and current_page > 0
	right_preview_frame.visible = has_pages and current_page < pages.size() - 1

	if left_preview_frame.visible:
		left_preview_texture.texture = pages[current_page - 1]
	if right_preview_frame.visible:
		right_preview_texture.texture = pages[current_page + 1]

func _play_intro_transition() -> void:
	if not intro_enabled:
		return

	is_intro_playing = true
	var root_target_position := root_home_position
	dimmer.color = Color(dimmer_final_color.r, dimmer_final_color.g, dimmer_final_color.b, 0.0)
	root.modulate.a = 0.0
	root.position = root_target_position
	root.visible = true
	if film_bars != null:
		film_bars.modulate.a = 0.0
	if side_panel_layer != null:
		side_panel_layer.visible = true
		side_panel_layer.modulate.a = 0.0
		side_panel_layer.position = Vector2.ZERO

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(dimmer, "color", dimmer_final_color, intro_fade_time)
	tween.parallel().tween_property(root, "modulate:a", 1.0, intro_fade_time)
	if film_bars != null:
		tween.parallel().tween_property(film_bars, "modulate:a", 1.0, intro_fade_time)
	if side_panel_layer != null:
		tween.parallel().tween_property(side_panel_layer, "modulate:a", 1.0, intro_fade_time)
	tween.finished.connect(func() -> void:
		is_intro_playing = false
	)

func _slide_to_page(target_page: int, direction: int) -> void:
	if target_page < 0 or target_page >= pages.size():
		return

	is_page_animating = true
	previous_button.disabled = true
	next_button.disabled = true

	var moving_frame := right_preview_frame if direction > 0 else left_preview_frame
	var moving_texture := right_preview_texture if direction > 0 else left_preview_texture
	var outgoing_slot_frame := left_preview_frame if direction > 0 else right_preview_frame
	var outer_page := target_page + direction
	moving_texture.texture = pages[target_page]
	moving_frame.visible = true
	moving_frame.modulate = Color(0.58, 0.58, 0.58, side_panel_alpha)

	var start_position := moving_frame.position
	var start_size := moving_frame.size
	var frame_size := page_frame.custom_minimum_size
	var outgoing_frame := _create_transition_frame(pages[current_page])
	outgoing_frame.position = root_home_position
	outgoing_frame.custom_minimum_size = Vector2.ZERO
	outgoing_frame.size = frame_size

	var side_size := frame_size * side_panel_scale
	var side_y := root_home_position.y + (frame_size.y - side_size.y) * 0.5
	var side_x := root_home_position.x - side_size.x - side_panel_gap if direction > 0 else root_home_position.x + frame_size.x + side_panel_gap
	var outgoing_target_position := Vector2(side_x, side_y)
	var outgoing_slot_target_position := outgoing_slot_frame.position - Vector2(direction * (side_size.x + side_panel_gap), 0.0)
	var incoming_outer_frame: PanelContainer = null
	if outer_page >= 0 and outer_page < pages.size():
		incoming_outer_frame = _create_side_transition_frame(pages[outer_page])
		incoming_outer_frame.custom_minimum_size = Vector2.ZERO
		incoming_outer_frame.size = side_size
		incoming_outer_frame.position = start_position + Vector2(direction * (side_size.x + side_panel_gap), 0.0)
		incoming_outer_frame.modulate = Color(0.58, 0.58, 0.58, 0.0)

	page_frame.modulate.a = 0.0
	caption_panel.modulate.a = 0.0

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	if outgoing_slot_frame.visible:
		tween.parallel().tween_property(outgoing_slot_frame, "position", outgoing_slot_target_position, page_slide_time)
		tween.parallel().tween_property(outgoing_slot_frame, "modulate:a", 0.0, page_slide_time)
	tween.parallel().tween_property(outgoing_frame, "position", outgoing_target_position, page_slide_time)
	tween.parallel().tween_property(outgoing_frame, "size", side_size, page_slide_time)
	tween.parallel().tween_property(outgoing_frame, "modulate", Color(0.58, 0.58, 0.58, side_panel_alpha), page_slide_time)
	tween.parallel().tween_property(moving_frame, "position", root_home_position, page_slide_time)
	tween.parallel().tween_property(moving_frame, "size", frame_size, page_slide_time)
	tween.parallel().tween_property(moving_frame, "modulate", Color.WHITE, page_slide_time)
	if incoming_outer_frame != null:
		tween.parallel().tween_property(incoming_outer_frame, "position", start_position, page_slide_time)
		tween.parallel().tween_property(incoming_outer_frame, "modulate", Color(0.58, 0.58, 0.58, side_panel_alpha), page_slide_time)
	tween.parallel().tween_property(footer, "modulate:a", 0.0, minf(page_slide_time * 0.45, 0.16))

	await tween.finished

	current_page = target_page
	root.position = root_home_position
	root.modulate.a = 1.0
	page_frame.modulate.a = 1.0
	caption_panel.modulate.a = 1.0
	moving_frame.position = start_position
	moving_frame.size = start_size
	outgoing_frame.queue_free()
	if incoming_outer_frame != null:
		incoming_outer_frame.queue_free()
	_refresh_page()
	_layout_side_previews()
	footer.modulate.a = 0.0
	var footer_tween := create_tween()
	footer_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	footer_tween.tween_property(footer, "modulate:a", 1.0, minf(page_slide_time * 0.35, 0.14))
	await footer_tween.finished
	is_page_animating = false

func _play_close_transition() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(root, "modulate:a", 0.0, close_fade_time)
	tween.parallel().tween_property(dimmer, "color", Color(dimmer_final_color.r, dimmer_final_color.g, dimmer_final_color.b, 0.0), close_fade_time)
	if side_panel_layer != null:
		tween.parallel().tween_property(side_panel_layer, "modulate:a", 0.0, close_fade_time)
	if film_bars != null:
		tween.parallel().tween_property(film_bars, "modulate:a", 0.0, close_fade_time)
	await tween.finished
