extends CanvasLayer

signal confirmed
signal canceled

@export var heading_text: String = "OLD SIGNAL RELAY"
@export var title_text: String = "Follow the signal?"
@export var detail_text: String = "Continue to the next area"
@export var yes_text: String = "Yes"
@export var no_text: String = "No"

@onready var heading_label: Label = $Dimmer/Panel/Margin/VBox/Heading
@onready var title_label: Label = $Dimmer/Panel/Margin/VBox/Title
@onready var detail_label: Label = $Dimmer/Panel/Margin/VBox/Detail
@onready var yes_button: Button = $Dimmer/Panel/Margin/VBox/Buttons/YesButton
@onready var no_button: Button = $Dimmer/Panel/Margin/VBox/Buttons/NoButton

func _ready() -> void:
	add_to_group("gameplay_input_blocker")
	apply_text()
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	yes_button.grab_focus()

func apply_text() -> void:
	if heading_label == null:
		return

	heading_label.text = heading_text
	title_label.text = title_text
	detail_label.text = detail_text
	yes_button.text = yes_text
	no_button.text = no_text

func _on_yes_pressed() -> void:
	confirmed.emit()

func _on_no_pressed() -> void:
	canceled.emit()
