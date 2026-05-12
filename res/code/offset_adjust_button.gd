extends Button
class_name OffsetAdjustButton
var main : Main
signal offsetAdjustButtonPressed(amount : int)

func _ready() -> void:
	main = get_parent()
	if main != null:
		tree_exiting.connect(on_tree_exiting)
		offsetAdjustButtonPressed.connect(main.button_offset_adjust_pressed)
		pressed.connect(on_button_pressed)
func on_button_pressed():
	if offsetAdjustButtonPressed.is_connected(main.button_offset_adjust_pressed) and !text.is_empty():
		emit_signal("offsetAdjustButtonPressed", text.to_int())
func on_tree_exiting():
	pressed.disconnect(on_button_pressed)
	if main != null:
		offsetAdjustButtonPressed.disconnect(main.button_offset_adjust_pressed)
