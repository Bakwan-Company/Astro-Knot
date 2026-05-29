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
@export_range(0.5, 1.0) var page_width_ratio: float = 0.84
@export_range(0.5, 1.0) var page_height_ratio: float = 0.78

@onready var dimmer: ColorRect = $Dimmer
@onready var root: VBoxContainer = $Root
@onready var page_frame: PanelContainer = $Root/PageFrame
@onready var page_texture: TextureRect = $Root/PageFrame/PageTexture
@onready var caption_panel: PanelContainer = $Root/CaptionPanel
@onready var caption_label: Label = $Root/CaptionPanel/Margin/CaptionLabel
@onready var page_counter: Label = $Root/Footer/PageCounter
@onready var previous_button: Button = $Root/Footer/PreviousButton
@onready var skip_button: Button = $Root/Footer/SkipButton
@onready var next_button: Button = $Root/Footer/NextButton

var current_page: int = 0
var previous_pause_state: bool = false
var is_closing: bool = false

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
	_fit_page_frame()
	_refresh_page()
	next_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if is_closing:
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
	if is_closing or current_page <= 0:
		return

	current_page -= 1
	_refresh_page()

func next_page() -> void:
	if is_closing:
		return

	if current_page >= pages.size() - 1:
		_close()
		return

	current_page += 1
	_refresh_page()

func skip() -> void:
	if skippable:
		_close()

func _close() -> void:
	if is_closing:
		return

	is_closing = true
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
	skip_button.text = skip_text
	skip_button.visible = skippable

func _apply_style() -> void:
	dimmer.color = Color(0.015, 0.014, 0.013, 0.92)

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

func _style_button(button: Button, primary: bool) -> void:
	button.custom_minimum_size = Vector2(92.0, 34.0)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color(0.06, 0.045, 0.035, 1.0) if primary else Color(0.72, 0.66, 0.58, 1.0))

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
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

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
	page_frame.custom_minimum_size = Vector2(frame_width, frame_height)
	page_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
