extends Node

const BROWSE_SFX: AudioStream = preload("res://asset/Audio/button_browse.mp3")
const CLICK_SFX: AudioStream = preload("res://asset/Audio/button_click.mp3")

@export var browse_volume_db: float = -8.0
@export var click_volume_db: float = -6.0

var browse_player: AudioStreamPlayer
var click_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	browse_player = _create_player("BrowsePlayer", BROWSE_SFX, browse_volume_db)
	click_player = _create_player("ClickPlayer", CLICK_SFX, click_volume_db)


func play_browse() -> void:
	_play_one_shot(browse_player)


func play_click() -> void:
	_play_one_shot(click_player)


func bind_button(button: Button, play_click_on_pressed: bool = true) -> void:
	if button == null or button.has_meta(&"ui_sfx_bound"):
		return

	button.set_meta(&"ui_sfx_bound", true)
	button.focus_entered.connect(func() -> void:
		if not button.disabled:
			play_browse()
	)
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			play_browse()
	)

	if play_click_on_pressed:
		button.pressed.connect(play_click)


func _create_player(player_name: String, stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = player_name
	player.bus = "Master"
	player.stream = stream
	player.volume_db = volume
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player


func _play_one_shot(player: AudioStreamPlayer) -> void:
	if player == null:
		return

	player.stop()
	player.play()
