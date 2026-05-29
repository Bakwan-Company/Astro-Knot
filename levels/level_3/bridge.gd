extends AnimatableBody2D

# Seberapa jauh jembatannya mau ditarik/digeser?
# Contoh: Vector2(150, 0) berarti geser ke KANAN 150 pixel.
# Kalau mau geser ke BAWAH (biar jadi jalan), misal Vector2(0, 150)
@export var retract_offset: Vector2 = Vector2(0, 150) 
@export var retract_duration: float = 1.0 # Waktu nariknya (1 detik)

@onready var start_position: Vector2 = global_position

# Fungsi yang bakal nerima teriakan sinyal dari Terminal
func _on_terminal_activated(is_on: bool) -> void:
	# Bikin animasi pergerakan (Tween) biar gesernya mulus
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	if is_on:
		# Pas terminal ON: Jembatan digeser sejauh nilai retract_offset
		tween.tween_property(self, "global_position", start_position + retract_offset, retract_duration)
	else:
		# Pas terminal OFF: Jembatan balik ke posisi semula
		tween.tween_property(self, "global_position", start_position, retract_duration)
