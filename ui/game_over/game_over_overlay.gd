extends CanvasLayer

signal restart_requested

@export var death_type: String = "unknown"
@export var use_checkpoint_restart: bool = false

@onready var panel: PanelContainer = $Screen/Panel
@onready var eyebrow_label: Label = $Screen/Panel/Margin/VBox/Eyebrow
@onready var title_label: Label = $Screen/Panel/Margin/VBox/Title
@onready var death_type_label: Label = $Screen/Panel/Margin/VBox/DeathType
@onready var detail_label: Label = $Screen/Panel/Margin/VBox/Detail
@onready var restart_button: Button = $Screen/Panel/Margin/VBox/RestartButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_terminal_style()
	restart_button.pressed.connect(restart_level)
	update_copy()
	restart_button.grab_focus()

func show_death(next_death_type: String) -> void:
	death_type = next_death_type
	if is_node_ready():
		update_copy()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		get_viewport().set_input_as_handled()
		restart_level()

func update_copy() -> void:
	title_label.text = get_title_copy()
	death_type_label.text = "> ERROR_TYPE: %s" % death_type.to_upper()
	detail_label.text = get_death_detail()
	restart_button.text = "> RESTART CHECKPOINT" if use_checkpoint_restart else "> RESTART LEVEL"

func get_title_copy() -> String:
	if death_type == "fall":
		return "SYSTEM FAILURE"
	if death_type == "spike":
		return "SYSTEM FAILURE"

	return "LINK FAILURE"

func get_death_detail() -> String:
	if death_type == "tether_break":
		return "> HARDLIGHT_LINK_RANGE_EXCEEDED\n> SAFETY ROUTINE: RESTART REQUIRED"
	if death_type == "fall":
		return "> STABLE_FOOTING_LOST\n> CASTOR/POLLUX RECOVERY FAILED\n> REBOOT FROM LAST CHECKPOINT"
	if death_type == "spike":
		return "> HULL_BREACH_DETECTED\n> HAZARD_CONTACT\n> REBOOT FROM LAST CHECKPOINT"

	return "> UNKNOWN_FAILURE_STATE\n> RESTART REQUIRED"

func _apply_terminal_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.018, 0.026, 0.023, 0.92)
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
	panel.custom_minimum_size = Vector2(420, 184)

	eyebrow_label.text = "ASTRO-KNOT // EMERGENCY TERMINAL"
	eyebrow_label.add_theme_font_size_override("font_size", 11)
	eyebrow_label.add_theme_color_override("font_color", Color(0.44, 0.82, 0.72, 1.0))

	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.78, 0.28, 0.22, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0.78, 0.28, 0.22, 0.16))
	title_label.add_theme_constant_override("shadow_offset_x", 1)
	title_label.add_theme_constant_override("shadow_offset_y", 0)

	death_type_label.add_theme_font_size_override("font_size", 11)
	death_type_label.add_theme_color_override("font_color", Color(0.44, 0.82, 0.72, 1.0))
	death_type_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	detail_label.add_theme_font_size_override("font_size", 11)
	detail_label.add_theme_color_override("font_color", Color(0.68, 0.86, 0.78, 1.0))
	detail_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	restart_button.text = "> RESTART CHECKPOINT" if use_checkpoint_restart else "> RESTART LEVEL"
	restart_button.add_theme_font_size_override("font_size", 13)
	restart_button.add_theme_color_override("font_color", Color(0.04, 0.07, 0.06, 1.0))
	restart_button.add_theme_color_override("font_focus_color", Color(0.04, 0.07, 0.06, 1.0))

	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color(0.38, 0.74, 0.64, 1.0)
	button_style.border_color = Color(0.64, 0.9, 0.82, 1.0)
	button_style.border_width_left = 1
	button_style.border_width_top = 1
	button_style.border_width_right = 1
	button_style.border_width_bottom = 1
	button_style.corner_radius_top_left = 3
	button_style.corner_radius_top_right = 3
	button_style.corner_radius_bottom_left = 3
	button_style.corner_radius_bottom_right = 3
	restart_button.add_theme_stylebox_override("normal", button_style)
	restart_button.add_theme_stylebox_override("hover", button_style)
	restart_button.add_theme_stylebox_override("pressed", button_style)
	restart_button.add_theme_stylebox_override("focus", button_style)

func restart_level() -> void:
	get_tree().paused = false
	if use_checkpoint_restart:
		restart_requested.emit()
		queue_free()
		return
	get_tree().reload_current_scene()
