extends Control
class_name Main

var isDebug : bool = false
var isReady : bool = false
var selectedValueType : int = 0
var cheatText : String
@export_category("Controls")
@export var TextInputField : LineEdit
@export var ValueTypeDisplay : Label
@export var ValueTypeButtonIncrease : Button
@export var ValueTypeButtonDecrease : Button
@export var TextInputFieldOffset : LineEdit
@export var TextInputFieldCheatName : LineEdit
@export var TextOutput : LineEdit
@export var TextOutputButton : Button
@export var ButtonReset : Button
@export var ButtonExit : Button
@export var ButtonOffsetAdjustPlus1 : Button
@export var ButtonOffsetAdjustPlus2 : Button
@export var ButtonOffsetAdjustPlus4 : Button
@export var ButtonOffsetAdjustPlus8 : Button
@export var ButtonOffsetAdjustPlus16 : Button
@export var ButtonOffsetAdjustPlus32 : Button
@export var ButtonOffsetAdjustPlus64 : Button
@export var ButtonOffsetAdjustMinus1 : Button
@export var ButtonOffsetAdjustMinus2 : Button
@export var ButtonOffsetAdjustMinus4 : Button
@export var ButtonOffsetAdjustMinus8 : Button
@export var ButtonOffsetAdjustMinus16 : Button
@export var ButtonOffsetAdjustMinus32 : Button
@export var ButtonOffsetAdjustMinus64 : Button
func _ready() -> void:
	isReady = false
	await _CliArgsRead()
	await _WindowInit()
	await _ComponentsInit()
	await _ValueTypeClamp()
	await _ValueTypeDisplayUpdate()
	isReady = true
func _CliArgsRead():
	var args : PackedStringArray = OS.get_cmdline_user_args()
	if !args.is_empty():
		var index : int = args.find("--debug")
		if index != -1:
			isDebug = true
		else:
			isDebug = false
func _WindowInit():
	var screenSize : Vector2 = DisplayServer.screen_get_size(0)
	if screenSize != Vector2.ZERO:
		get_tree().root.size = screenSize / 2
		get_window().content_scale_size = get_tree().root.size
func _ComponentsInit():
	get_tree().root.size_changed.connect(window_size_changed)
	tree_exiting.connect(on_tree_exiting)
	TextInputField.text_changed.connect(game_title_text_changed)
	TextInputFieldOffset.text_changed.connect(offset_input_text_changed)
	TextInputFieldCheatName.text_changed.connect(cheat_name_text_changed)
	ValueTypeButtonIncrease.pressed.connect(_ValueTypeButtonIncreasePressed)
	ValueTypeButtonDecrease.pressed.connect(_ValueTypeButtonDecreasePressed)
	TextOutputButton.pressed.connect(_TextOutputButtonPressed)
	ButtonReset.pressed.connect(button_reset_pressed)
	ButtonExit.pressed.connect(button_exit_pressed)
	ButtonOffsetAdjustPlus1.pressed.connect(button_offset_pressed_inc1)
	ButtonOffsetAdjustPlus2.pressed.connect(button_offset_pressed_inc2)
	ButtonOffsetAdjustPlus4.pressed.connect(button_offset_pressed_inc4)
	ButtonOffsetAdjustPlus8.pressed.connect(button_offset_pressed_inc8)
	ButtonOffsetAdjustPlus16.pressed.connect(button_offset_pressed_inc16)
	ButtonOffsetAdjustPlus32.pressed.connect(button_offset_pressed_inc32)
	ButtonOffsetAdjustPlus64.pressed.connect(button_offset_pressed_inc64)
	ButtonOffsetAdjustMinus1.pressed.connect(button_offset_pressed_dec1)
	ButtonOffsetAdjustMinus2.pressed.connect(button_offset_pressed_dec2)
	ButtonOffsetAdjustMinus4.pressed.connect(button_offset_pressed_dec4)
	ButtonOffsetAdjustMinus8.pressed.connect(button_offset_pressed_dec8)
	ButtonOffsetAdjustMinus16.pressed.connect(button_offset_pressed_dec16)
	ButtonOffsetAdjustMinus32.pressed.connect(button_offset_pressed_dec32)
	ButtonOffsetAdjustMinus64.pressed.connect(button_offset_pressed_dec64)
	
func _ValueTypeButtonIncreasePressed():
	selectedValueType += 1
	_DebugLogWrite("_ValueTypeButtonIncreasePressed()::selectedValueType=" + str(selectedValueType), 0)
	await _ValueTypeClamp()
	await _ValueTypeDisplayUpdate()
	await _CheatTextUpdate()
func _ValueTypeButtonDecreasePressed():
	selectedValueType -= 1
	_DebugLogWrite("_ValueTypeButtonDecreasePressed()::selectedValueType=" + str(selectedValueType), 0)
	await _ValueTypeClamp()
	await _ValueTypeDisplayUpdate()
	await _CheatTextUpdate()
func _ValueTypeClamp():
	_DebugLogWrite("_ValueTypeClamp()::Start()", 0)
	if selectedValueType < 0:
		selectedValueType = 8
	elif selectedValueType > 8:
		selectedValueType = 0
func _ValueTypeDisplayUpdate():
	ValueTypeDisplay.text = str(_GetValueType())
	_DebugLogWrite("_ValueTypeDisplayUpdate()", 0)
func _GetGameTitle():
	return TextInputField.text
func _GetValueType():
	match selectedValueType:
		0:
			return "UInt8"
		1:
			return "UInt16"
		2:
			return "UInt32"
		3:
			return "UInt64"
		4:
			return "Int8"
		5:
			return "Int16"
		6:
			return "Int32"
		7:
			return "Int64"
		8:
			return "Float32"
func _GetCheatName():
	return str(TextInputFieldCheatName.text)
func _TextOutputButtonPressed():
	_DebugLogWrite("_TextOutputButtonPressed()::copyStringToClipboard:" + str(cheatText), 0)
	DisplayServer.clipboard_set(str(cheatText))
func _ParseOffsetValue():
	var text : String = TextInputFieldOffset.text
	if text.is_valid_hex_number(true):
		return _HexToInt(text)
func _IncrementOffsetValue(stride : int):
	if stride != 0 and !TextInputFieldOffset.text.is_empty() and TextInputFieldOffset.text.is_valid_hex_number(true):
		var i : int = _HexToInt(TextInputFieldOffset.text)
		i += stride
		TextInputFieldOffset.text = "0x" + str(_IntToHex(i))
		_CheatTextUpdate()
func _HexToInt(hex : String):
	if !hex.is_empty() and hex.is_valid_hex_number(true):
		return hex.hex_to_int()
func _IntToHex(param : int):
	return str("%x" % param).to_upper()

func _CheatTextUpdate():
	cheatText = str(_GetGameTitle()) + "@@@" + str(_GetCheatName()) + "@@@" + str(selectedValueType) + "@@@" + str(_ParseOffsetValue()) + "@@@@@@^^^"
	TextOutput.text = str(cheatText)
	_CheatTextLengthCheck()
func _CheatTextLengthCheck():
	if cheatText.length() > get_tree().root.size.x:
		get_tree().root.size.x = cheatText.length() + 4
func _process(_delta: float) -> void:
	_WindowUpdate()
func _Reset():
	TextInputField.text = ""
	TextInputFieldOffset.text = "0x000000"
	TextInputFieldCheatName.text = ""
	selectedValueType = 0
	await _ValueTypeClamp()
	await _ValueTypeDisplayUpdate()
	await _CheatTextUpdate()
func _DebugLogWrite(message : String, level : int):
	if isDebug and !message.is_empty():
		level = clampi(level, 0, 2)
		var timestamp : String = Time.get_time_string_from_system()
		match level:
			0:
				print("[INFO][" + str(timestamp) + "]::" + str(message))
			1:
				print("[WARNING][" + str(timestamp) + "]::" + str(message))
			2:
				printerr("[ERROR][" + str(timestamp) + "]::" + str(message))
func _WindowUpdate():
	get_window().content_scale_size = get_tree().root.size
# Callable Functions
func on_tree_exiting():
	_DebugLogWrite("on_tree_exiting()", 0)
	get_tree().root.size_changed.disconnect(window_size_changed)
	TextInputField.text_changed.disconnect(game_title_text_changed)
	TextInputFieldOffset.text_changed.disconnect(offset_input_text_changed)
	TextInputFieldCheatName.text_changed.disconnect(cheat_name_text_changed)
	ValueTypeButtonIncrease.pressed.disconnect(_ValueTypeButtonIncreasePressed)
	ValueTypeButtonDecrease.pressed.disconnect(_ValueTypeButtonDecreasePressed)
	TextOutputButton.pressed.disconnect(_TextOutputButtonPressed)
	ButtonReset.pressed.disconnect(button_reset_pressed)
	ButtonExit.pressed.disconnect(button_exit_pressed)
	ButtonOffsetAdjustPlus1.pressed.disconnect(button_offset_pressed_inc1)
	ButtonOffsetAdjustPlus2.pressed.disconnect(button_offset_pressed_inc2)
	ButtonOffsetAdjustPlus4.pressed.disconnect(button_offset_pressed_inc4)
	ButtonOffsetAdjustPlus8.pressed.disconnect(button_offset_pressed_inc8)
	ButtonOffsetAdjustPlus16.pressed.disconnect(button_offset_pressed_inc16)
	ButtonOffsetAdjustPlus32.pressed.disconnect(button_offset_pressed_inc32)
	ButtonOffsetAdjustPlus64.pressed.disconnect(button_offset_pressed_inc64)
	ButtonOffsetAdjustMinus1.pressed.disconnect(button_offset_pressed_dec1)
	ButtonOffsetAdjustMinus2.pressed.disconnect(button_offset_pressed_dec2)
	ButtonOffsetAdjustMinus4.pressed.disconnect(button_offset_pressed_dec4)
	ButtonOffsetAdjustMinus8.pressed.disconnect(button_offset_pressed_dec8)
	ButtonOffsetAdjustMinus16.pressed.disconnect(button_offset_pressed_dec16)
	ButtonOffsetAdjustMinus32.pressed.disconnect(button_offset_pressed_dec32)
	ButtonOffsetAdjustMinus64.pressed.disconnect(button_offset_pressed_dec64)
	_DebugLogWrite("ProgramExit()", 0)
func game_title_text_changed(_new_text : String):
	await _CheatTextUpdate()
func offset_input_text_changed(_new_text : String):
	_CheatTextUpdate()
func cheat_name_text_changed(_new_text : String):
	await _CheatTextUpdate()
func window_size_changed():
	set_anchors_preset(Control.PRESET_FULL_RECT)
func button_reset_pressed():
	_Reset()
func button_exit_pressed():
	get_tree().quit(0)
func button_offset_pressed_inc1():
	_IncrementOffsetValue(1)
func button_offset_pressed_inc2():
	_IncrementOffsetValue(2)
func button_offset_pressed_inc4():
	_IncrementOffsetValue(4)
func button_offset_pressed_inc8():
	_IncrementOffsetValue(8)
func button_offset_pressed_inc16():
	_IncrementOffsetValue(16)
func button_offset_pressed_inc32():
	_IncrementOffsetValue(32)
func button_offset_pressed_inc64():
	_IncrementOffsetValue(64)
func button_offset_pressed_dec1():
	_IncrementOffsetValue(-1)
func button_offset_pressed_dec2():
	_IncrementOffsetValue(-2)
func button_offset_pressed_dec4():
	_IncrementOffsetValue(-4)
func button_offset_pressed_dec8():
	_IncrementOffsetValue(-8)
func button_offset_pressed_dec16():
	_IncrementOffsetValue(-16)
func button_offset_pressed_dec32():
	_IncrementOffsetValue(-32)
func button_offset_pressed_dec64():
	_IncrementOffsetValue(-64)
