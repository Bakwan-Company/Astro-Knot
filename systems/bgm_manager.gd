extends Node

const MAIN_MENU := "res://asset/Audio/bgm_mainmenu.mp3"
const LEVEL_1 := "res://asset/Audio/bgm_level1.mp3"
const LEVEL_2 := "res://asset/Audio/bgm_level2.mp3"
const LEVEL_3 := "res://asset/Audio/bgm_level3.mp3"
const ENDING := "res://asset/Audio/bgm_end.mp3"

@export var default_volume_db: float = -10.0
@export var fade_floor_db: float = -45.0
@export var default_fade_time: float = 0.8

var current_path: String = ""
var active_player: AudioStreamPlayer
var standby_player: AudioStreamPlayer
var fade_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	active_player = _create_player("ActivePlayer")
	standby_player = _create_player("StandbyPlayer")

func play(path: String, loop: bool = true, fade_time: float = -1.0) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return

	if current_path == path and active_player.playing:
		return

	var stream := load(path) as AudioStream
	if stream == null:
		return

	stream = stream.duplicate()
	stream.set("loop", loop)

	var duration := default_fade_time if fade_time < 0.0 else fade_time
	standby_player.stop()
	standby_player.stream = stream
	standby_player.volume_db = fade_floor_db
	standby_player.play()

	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.parallel().tween_property(standby_player, "volume_db", default_volume_db, duration)
	if active_player.playing:
		fade_tween.parallel().tween_property(active_player, "volume_db", fade_floor_db, duration)
	fade_tween.finished.connect(_finish_crossfade)
	current_path = path

func stop(fade_time: float = -1.0) -> void:
	var duration := default_fade_time if fade_time < 0.0 else fade_time
	current_path = ""

	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if active_player.playing:
		fade_tween.tween_property(active_player, "volume_db", fade_floor_db, duration)
	if standby_player.playing:
		fade_tween.parallel().tween_property(standby_player, "volume_db", fade_floor_db, duration)
	fade_tween.finished.connect(func() -> void:
		active_player.stop()
		standby_player.stop()
	)

func play_main_menu() -> void:
	play(MAIN_MENU)

func play_level_1() -> void:
	play(LEVEL_1)

func play_level_2() -> void:
	play(LEVEL_2)

func play_level_3() -> void:
	play(LEVEL_3)

func play_ending() -> void:
	play(ENDING, false, 1.0)

func _create_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = "Master"
	player.volume_db = fade_floor_db
	add_child(player)
	return player

func _finish_crossfade() -> void:
	active_player.stop()
	active_player.stream = null
	var old_active := active_player
	active_player = standby_player
	standby_player = old_active
