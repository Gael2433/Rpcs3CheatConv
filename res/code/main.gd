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
@export var PopupFileMenu : PopupMenu

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
	PopupFileMenu.index_pressed.connect(file_popup_menu_item_selected)
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
func _GetValueTypeString(value_type : int):
	value_type = clampi(value_type, 0, 8)
	match value_type:
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
func _FileDialogOpen(open_mode : bool): # false = save, true = open
	if open_mode:
		var file_dialog : FileDialog = FileDialog.new()
		file_dialog.use_native_dialog = true
		file_dialog.add_filter("*.cht")
		file_dialog.deleting_enabled = false
		file_dialog.folder_creation_enabled = false
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.name = "OpenFileDialog"
		add_child.call_deferred(file_dialog)
		await file_dialog.tree_entered
		file_dialog.owner = get_tree().edited_scene_root
		file_dialog.visible = true
		return file_dialog
	else:
		var file_dialog : FileDialog = FileDialog.new()
		file_dialog.use_native_dialog = true
		file_dialog.add_filter("*.cht")
		file_dialog.deleting_enabled = true
		file_dialog.folder_creation_enabled = true
		file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.name = "SaveFileDialog"
		add_child.call_deferred(file_dialog)
		await file_dialog.tree_entered
		file_dialog.owner = get_tree().edited_scene_root
		file_dialog.visible = true
		return file_dialog
func _CallOpenFileDialog():
	var open_dialog : FileDialog = await _FileDialogOpen(true)
	await open_dialog.file_selected
	var selected_file : String = str(open_dialog.current_dir) + "/" + str(open_dialog.current_file)
	open_dialog.queue_free()
	await open_dialog.tree_exited
	if !selected_file.is_empty():
		_LoadFileCht(selected_file)
func _LoadFileCht(path : String):
	_DebugLogWrite("_LoadFileCht()::path=" + str(path), 0)
	if !path.is_empty():
		var cht_file : FileAccess = FileAccess.open(str(path), FileAccess.READ)
		if cht_file != null:
			_ParseFileCht(cht_file)
func _ParseFileCht(file : FileAccess):
	if file != null:
		var header : PackedByteArray = file.get_buffer(5)
		var header_len : int = header.size()
		var header_hex : String = ""
		if header_len == 5:
			for i in range(header_len):
				var value : String = _IntToHex(header[i])
				if !value.is_empty():
					header_hex += str(value)
				i += 1
				if i >= header_len:
					break
		# Check that file header is "5243485440" in Hex (RCHT@)
		if header_hex == "5243485440":
			_DebugLogWrite("_LoadFileCht()::Header OK", 0)
			var file_version : PackedByteArray = file.get_buffer(2)
			var file_version_major : int = file_version[0]
			var file_version_minor : int = file_version[1]
			_DebugLogWrite("_LoadFileCht()::CHT File Version: Major:" + str(file_version_major) + " Minor:" + str(file_version_minor), 0)
		else:
			_DebugLogWrite("_LoadFileCht()::Invalid file header! got:" + str(header_hex) + ", expected:5243485440", 1)
			file.close()
		# Get Game Title
		var game_title : StringName = _FileChdReadBufferString(file, 256)
		_DebugLogWrite("_LoadFileCht()::Got game title: " + str(game_title), 0)
		# Get Cheat Name
		var cheat_name : StringName = _FileChdReadBufferString(file, 256)
		_DebugLogWrite("_LoadFileCht()::Got cheat name: " + str(cheat_name), 0)
		# Get Value Type
		var value_type : int = file.get_buffer(1)[0]
		_DebugLogWrite("_LoadFileCht()::Got value type: " + str(_GetValueTypeString(value_type)), 0)
		# Get Cheat Offset
		#file.seek(file.get_position() - 1) # Hacky hack :3
		var offset : String = _IntToHex(_FileChdReadBufferString(file, 256).to_int())
		_DebugLogWrite("_LoadFileCht()::Got cheat offset: 0x0" + str(offset), 0)
		# Apply values to UI
		await _Reset()
		TextInputField.text = str(game_title)
		TextInputFieldCheatName.text = str(cheat_name)
		TextInputFieldOffset.text = "0x0" + str(offset)
		selectedValueType = clampi(value_type, 0, 8)
		await _ValueTypeDisplayUpdate()
		await _CheatTextUpdate()
		file.close()
func _FileChdReadBufferString(file : FileAccess, length : int):
	var out_string : StringName = ""
	var buf : PackedByteArray = file.get_buffer(length)
	var buf_size : int = buf.size()
	if buf_size > 0:
		for i in range(buf_size):
			var letter : String = _IntToHex(buf[i])
			var letter_hex : String = str(letter)
			if letter_hex == "24":
				if _IntToHex(buf[i + 1]) == "24":
					file.seek(file.get_position() - buf_size + i + 2) # Seek to end of found value.
					break
			out_string += letter
			i += 1
			if i >= buf_size:
				break
	return str(out_string.hex_decode().get_string_from_utf8())
func _CallSaveFileDialog():
	var save_dialog : FileDialog = await _FileDialogOpen(false)
	await save_dialog.file_selected
	var selected_file : String = str(save_dialog.current_dir) + "/" + str(save_dialog.current_file)
	save_dialog.queue_free()
	await save_dialog.tree_exited
	if !selected_file.is_empty():
		_SaveFileChd(selected_file)
func _SaveFileChd(path : String):
	if !path.is_empty():
		var file_access : FileAccess = FileAccess.open(str(path), FileAccess.WRITE)
		if file_access != null:
			_DebugLogWrite(str(file_access.get_path()), 0)
			# Write file magic
			_FileChtWriteDataArray(file_access, "RCHT@".to_utf8_buffer(), false)
			# Write file version
			_FileChtWriteVersion(file_access)
			# Write Game Title
			_FileChtWriteDataArray(file_access, str(TextInputField.text).to_utf8_buffer(), true)
			# Write Cheat Name
			_FileChtWriteDataArray(file_access, str(TextInputFieldCheatName.text).to_utf8_buffer(), true)
			# Write Value Type
			_FileChtWriteValueType(file_access)
			# Write Offset
			_FileChtWriteDataArray(file_access, str(_ParseOffsetValue()).to_utf8_buffer(), true)
			# Close File
			file_access.close()
func _FileChtWriteDataArray(file : FileAccess, in_buf : PackedByteArray, add_terminator : bool):
	var buf_length : int = in_buf.size()
	if file != null and buf_length > 0:
		if add_terminator:
			in_buf.append_array("$$".to_utf8_buffer())
		file.store_buffer(in_buf)
func _FileChtWriteVersion(file : FileAccess):
	if file != null:
		var buf : PackedByteArray
		buf.append(01)
		buf.append(00)
		file.store_buffer(buf)
func _FileChtWriteValueType(file : FileAccess):
	if file != null:
		var buf : PackedByteArray
		buf.append(selectedValueType)
		file.store_buffer(buf)
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
func button_offset_adjust_pressed(stride : int):
	if stride != 0:
		_IncrementOffsetValue(stride)
func file_popup_menu_item_selected(index : int):
	if index != -1:
		if index == 0:
			_CallOpenFileDialog()
		elif index == 1:
			_CallSaveFileDialog()
