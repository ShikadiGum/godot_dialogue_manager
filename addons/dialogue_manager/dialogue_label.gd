extends RichTextLabel


signal spoke(letter, speed)
signal paused(duration)
signal finished()


const Line = preload("res://addons/dialogue_manager/dialogue_line.gd")

export var skip_action: String = "ui_cancel"
export var seconds_per_step: float = 0.02


var dialogue: Line

var index: int = 0
var percent_per_index: float = 0
var last_wait_index: int = -1
var last_mutation_index: int = -1
var waiting_seconds: float = 0
var is_typing: bool = false
var has_finished: bool = false


func _process(delta: float) -> void:
	if is_typing:
		# Type out text
		if percent_visible < 1:
			# If cancel is pressed then skip typing it out
			if Input.is_action_just_pressed(skip_action):
				percent_visible = 1
				# Run any inline mutations that haven't been run yet
				for i in range(index, get_total_character_count()):
					dialogue.mutate_inline_mutations(i)
			
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
	if last_mutation_index != index:
		last_mutation_index = index
		dialogue.mutate_inline_mutations(index)
	
	if last_wait_index != index and dialogue.get_pause(index) > 0:
		last_wait_index = index
		waiting_seconds += dialogue.get_pause(index)
		emit_signal("paused", dialogue.get_pause(index))
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
