extends CanvasLayer

@export var main_menu_scene_path: String = "res://MainMenu.tscn"

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $Screen/Panel
@onready var heading_label: Label = $Screen/Panel/Margin/VBox/Heading
@onready var title_label: Label = $Screen/Panel/Margin/VBox/Title
@onready var detail_label: Label = $Screen/Panel/Margin/VBox/Detail
@onready var resume_button: Button = $Screen/Panel/Margin/VBox/ResumeButton
@onready var restart_button: Button = $Screen/Panel/Margin/VBox/RestartButton
@onready var main_menu_button: Button = $Screen/Panel/Margin/VBox/MainMenuButton

var is_open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_apply_placeholder_style()
	resume_button.pressed.connect(resume_game)
	restart_button.pressed.connect(restart_level)
	main_menu_button.pressed.connect(go_to_main_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if is_open:
			resume_game()
		elif not get_tree().paused:
			pause_game()
	elif is_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		resume_game()

func pause_game() -> void:
	is_open = true
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()

func resume_game() -> void:
	is_open = false
	visible = false
	get_tree().paused = false

func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene_path)

func _apply_placeholder_style() -> void:
	dimmer.color = Color(0.015, 0.023, 0.035, 0.74)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.018, 0.026, 0.023, 0.94)
	panel_style.border_color = Color(0.22, 0.58, 0.52, 0.82)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", panel_style)

	heading_label.text = "ASTRO-KNOT // PAUSE TERMINAL"
	heading_label.add_theme_font_size_override("font_size", 12)
	heading_label.add_theme_color_override("font_color", Color(0.44, 0.82, 0.72, 1.0))

	title_label.text = "PAUSED"
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color(0.86, 0.74, 0.42, 1.0))

	detail_label.text = "> MISSION TEMPORARILY SUSPENDED"
	detail_label.add_theme_font_size_override("font_size", 14)
	detail_label.add_theme_color_override("font_color", Color(0.68, 0.86, 0.78, 1.0))

	_style_button(resume_button, "> RESUME")
	_style_button(restart_button, "> RESTART LEVEL")
	_style_button(main_menu_button, "> MAIN MENU")

func _style_button(button: Button, label: String) -> void:
	button.text = label
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.04, 0.07, 0.06, 1.0))
	button.add_theme_color_override("font_focus_color", Color(0.04, 0.07, 0.06, 1.0))

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.38, 0.74, 0.64, 1.0)
	normal_style.border_color = Color(0.64, 0.9, 0.82, 1.0)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.corner_radius_top_left = 3
	normal_style.corner_radius_top_right = 3
	normal_style.corner_radius_bottom_left = 3
	normal_style.corner_radius_bottom_right = 3

	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.54, 0.88, 0.76, 1.0)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
