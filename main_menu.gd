extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().paused = false
	BgmManager.play_main_menu()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_pressed() -> void:
# Fungsi ini ngeganti scene saat ini ke level game lu
	# Gw ambil path ini sesuai dari settingan project lu sebelumnya
	get_tree().change_scene_to_file("res://levels/level_1_tutorial/Level1Tutorial.tscn")


func _on_quit_pressed() -> void: # Replace with function body.
	get_tree().quit()
