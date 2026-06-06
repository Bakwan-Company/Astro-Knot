extends Control

const LEVEL_1_SCENE := "res://levels/level_1_tutorial/Level1Tutorial.tscn"

@onready var bg_space: TextureRect = %BgSpace
@onready var planet: TextureRect = %Planet
@onready var planet_glow: TextureRect = %PlanetGlow
@onready var menu_layer: Control = %MenuLayer
@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton
@onready var shooting_stars: CPUParticles2D = %ShootingStars
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var fade_black: ColorRect = %FadeBlack

var intro_tween: Tween
var transition_tween: Tween
var is_transitioning: bool = false


func _ready() -> void:
	get_tree().paused = false
	BgmManager.play_main_menu()

	_style_button(play_button, "> PLAY")
	_style_button(quit_button, "> QUIT")
	UiSfx.bind_button(play_button, false)
	UiSfx.bind_button(quit_button, false)
	_configure_shooting_stars()
	planet_glow.texture = _create_planet_glow_texture()
	_configure_glow_animation()
	_set_initial_state()
	_play_intro()


func _set_initial_state() -> void:
	bg_space.self_modulate.a = 0.0
	planet.self_modulate.a = 0.0
	planet_glow.self_modulate.a = 0.0
	menu_layer.modulate.a = 0.0
	fade_black.color.a = 0.0
	shooting_stars.emitting = false
	play_button.disabled = true
	quit_button.disabled = true


func _play_intro() -> void:
	if intro_tween != null and intro_tween.is_valid():
		intro_tween.kill()

	intro_tween = create_tween()
	intro_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	intro_tween.tween_interval(0.35)
	intro_tween.tween_property(planet, "self_modulate:a", 1.0, 1.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(bg_space, "self_modulate:a", 1.0, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro_tween.tween_callback(func() -> void:
		shooting_stars.restart()
		shooting_stars.emitting = true
	)
	intro_tween.tween_property(menu_layer, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro_tween.tween_callback(_on_intro_finished)


func _on_intro_finished() -> void:
	play_button.disabled = false
	quit_button.disabled = false
	play_button.grab_focus()
	animation_player.play("planet_glow")


func _configure_shooting_stars() -> void:
	shooting_stars.texture = _create_shooting_star_texture()
	shooting_stars.amount = 3
	shooting_stars.lifetime = 0.78
	shooting_stars.explosiveness = 0.92
	shooting_stars.randomness = 0.18
	shooting_stars.direction = Vector2(-0.86, 0.5).normalized()
	shooting_stars.spread = 2.0
	shooting_stars.gravity = Vector2.ZERO
	shooting_stars.initial_velocity_min = 860.0
	shooting_stars.initial_velocity_max = 1040.0
	shooting_stars.scale_amount_min = 0.85
	shooting_stars.scale_amount_max = 1.15
	shooting_stars.color = Color(0.72, 0.92, 1.0, 0.95)


func _create_shooting_star_texture() -> Texture2D:
	var image: Image = Image.create(6, 6, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(2.5, 2.5)
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var distance_ratio: float = center.distance_to(Vector2(x, y)) / 3.0
			var alpha: float = clampf(1.0 - distance_ratio, 0.0, 1.0)
			image.set_pixel(x, y, Color(0.82, 0.96, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _create_planet_glow_texture() -> Texture2D:
	var image: Image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(127.5, 127.5)
	var max_radius: float = 127.5
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var distance_ratio: float = center.distance_to(Vector2(x, y)) / max_radius
			var alpha: float = clampf(1.0 - distance_ratio, 0.0, 1.0)
			alpha = pow(alpha, 2.8) * 0.42
			image.set_pixel(x, y, Color(1.0, 0.45, 0.13, alpha))
	return ImageTexture.create_from_image(image)


func _configure_glow_animation() -> void:
	var animation: Animation = Animation.new()
	animation.length = 3.2
	animation.loop_mode = Animation.LOOP_LINEAR

	var color_track: int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(color_track, ^"Visuals/PlanetLayer/PlanetGlow:self_modulate")
	animation.track_set_interpolation_type(color_track, Animation.INTERPOLATION_CUBIC)
	animation.track_insert_key(color_track, 0.0, Color(1.0, 0.48, 0.12, 0.46))
	animation.track_insert_key(color_track, 0.8, Color(1.0, 0.68, 0.26, 0.74))
	animation.track_insert_key(color_track, 1.6, Color(1.0, 0.48, 0.12, 0.46))
	animation.track_insert_key(color_track, 2.4, Color(1.0, 0.62, 0.2, 0.63))
	animation.track_insert_key(color_track, 3.2, Color(1.0, 0.48, 0.12, 0.46))

	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation("planet_glow", animation)
	animation_player.add_animation_library("", library)


func _style_button(button: Button, label: String) -> void:
	button.text = label
	button.custom_minimum_size = Vector2(120, 28)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.04, 0.07, 0.06, 1.0))
	button.add_theme_color_override("font_focus_color", Color(0.04, 0.07, 0.06, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.04, 0.07, 0.06, 1.0))

	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
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

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.54, 0.88, 0.76, 1.0)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("disabled", normal_style)


func _on_play_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	play_button.disabled = true
	quit_button.disabled = true
	UiSfx.play_click()

	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()

	transition_tween = create_tween()
	transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	transition_tween.tween_property(fade_black, "color:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition_tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file(LEVEL_1_SCENE)
	)


func _on_quit_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	play_button.disabled = true
	quit_button.disabled = true
	UiSfx.play_click()
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()
