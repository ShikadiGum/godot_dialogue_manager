extends RichTextLabel


signal spoke(letter, speed)
signal paused(duration)
signal finished()


const Line = preload("res://addons/dialogue_manager/dialogue_line.gd")

export var seconds_per_step: float = 0.02


var dialogue: Line
var index: int = 0
var percent_per_index: float = 0
var last_wait_index: int = -1
var waiting_seconds: float = 0
var is_typing: bool = false
var has_finished: bool = false


func _process(delta: float) -> void:
	if is_typing:
		# Type out text
		if percent_visible < 1:
			# If cancel is pressed then skip typing it out
			if Input.is_action_pressed("ui_cancel"):
				percent_visible = 1
			
			# Otherwise, keep typing
			elif waiting_seconds > 0:
				waiting_seconds = max(0, waiting_seconds - delta)
			else:
				type_next(delta, 0)
		else:
			is_typing = false
			if has_finished == false:
				has_finished = true
				emit_signal("finished")


func type_next(delta: float, seconds_needed: float) -> void:
	if last_wait_index != index and dialogue.get_pause(index) > 0:
		emit_signal("paused", dialogue.get_pause(index))
		waiting_seconds += dialogue.get_pause(index)
		last_wait_index = index
	else:
		percent_visible += percent_per_index
		index += 1
		seconds_needed += seconds_per_step * (1.0 / dialogue.get_speed(index))
		if seconds_needed > delta:
			waiting_seconds += seconds_needed
			if index < text.length():
				emit_signal("spoke", text[index - 1], dialogue.get_speed(index))
		else:
			type_next(delta, seconds_needed)


func type_out() -> void:
	bbcode_text = dialogue.dialogue
	percent_visible = 0
	index = 0
	has_finished = false
	waiting_seconds = 0
	# Text isn't calculated until the next frame
	yield(get_tree(), "idle_frame")
	percent_per_index = 100.0 / float(get_total_character_count()) / 100.0
	is_typing = true