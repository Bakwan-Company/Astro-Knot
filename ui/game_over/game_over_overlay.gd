extends CanvasLayer

@export var death_type: String = "unknown"

@onready var death_type_label: Label = $Screen/Panel/Margin/VBox/DeathType
@onready var detail_label: Label = $Screen/Panel/Margin/VBox/Detail
@onready var restart_button: Button = $Screen/Panel/Margin/VBox/RestartButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	death_type_label.text = "Death type: %s" % death_type
	detail_label.text = get_death_detail()

func get_death_detail() -> String:
	if death_type == "tether_break":
		return "Hardlight power link exceeded its safe range."

	return "Placeholder failure state. Add a death-type message here."

func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
