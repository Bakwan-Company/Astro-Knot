extends CanvasLayer

@export var area_title: String = "Area Name"
@export var area_subtitle: String = ""
@export var title_color: Color = Color(0.18, 0.11, 0.07, 1.0)
@export var subtitle_color: Color = Color(0.62, 0.28, 0.08, 1.0)
@export var shadow_color: Color = Color(1.0, 0.78, 0.42, 0.45)
@export var hold_time: float = 2.0
@export var fade_time: float = 1.0

@onready var title_group: VBoxContainer = $AreaTitle
@onready var title_label: Label = $AreaTitle/Title
@onready var subtitle_label: Label = $AreaTitle/Subtitle

func _ready() -> void:
	show_title()

func show_title() -> void:
	title_label.text = area_title
	subtitle_label.text = area_subtitle
	title_label.add_theme_color_override("font_color", title_color)
	title_label.add_theme_color_override("font_shadow_color", shadow_color)
	subtitle_label.add_theme_color_override("font_color", subtitle_color)
	subtitle_label.add_theme_color_override("font_shadow_color", shadow_color)
	title_group.modulate.a = 1.0

	var tween := create_tween()
	tween.tween_interval(hold_time)
	tween.tween_property(title_group, "modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free)
