extends Area2D

signal terminal_activated(is_on: bool)

@onready var visual_rect: ColorRect = $ColorRect 

var is_active: bool = false
var pollux_in_range: bool = false

# placeholder, will be replaced by real sprites
var color_on = Color.GREEN
var color_off = Color.RED 

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	visual_rect.color = color_off

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Pollux":
		pollux_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Pollux":
		pollux_in_range = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and pollux_in_range:
		toggle_terminal()

func toggle_terminal() -> void:
	is_active = !is_active
	terminal_activated.emit(is_active)
	
	if is_active:
		visual_rect.color = color_on
		print("Terminal ON - Hijau")
	else:
		visual_rect.color = color_off
		print("Terminal OFF - Merah")
