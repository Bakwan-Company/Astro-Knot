extends Node

var jump_suppressed_until_msec: int = 0

func suppress_jump(duration: float = 1.0) -> void:
	var duration_msec := int(maxf(duration, 0.0) * 1000.0)
	jump_suppressed_until_msec = max(jump_suppressed_until_msec, Time.get_ticks_msec() + duration_msec)

func is_jump_suppressed() -> bool:
	return Time.get_ticks_msec() < jump_suppressed_until_msec
