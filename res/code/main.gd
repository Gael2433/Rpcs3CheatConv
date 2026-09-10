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
@export var ButtonAddCheatToList : Button
@export var ButtonRemoveCheatFromList : Button
@export var ButtonClearCheatList : Button
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
@export var PopupAboutMenu : PopupMenu
@export var CheatList : ItemList
@export var HelpWindow : Control
@export var HelpWindowCloseButton : Button
@export var HelpWindow2 : Control
@export var HelpWindow2CloseButton : Button
@export var FloatingWindow : ColorRect
@export var FloatingWindowLabel : Label
@export var ButtonImportFromClipboard : Button
@export var ButtonExportToClipboard : Button
@export var FileDialogOpenFile : FileDialog
@export var background : ColorRect
var lastFilePath : String = "D:/Emulators/RPCS3/patches/"

var themeList : Array[Theme]
@export var ThemeWindowBase : Control
@export var ItemListThemes : ItemList
@export var ThemeWindowCloseButton : Button

# Initialisation
func _ready() -> void:
	isReady = false
	await _CliArgsRead()
	await _ThemeListBuild()
	await _ConfigLoad()
	await _WindowInit()
	await _ComponentsInit()
	await _ValueTypeClamp()
	await _ValueTypeDisplayUpdate()
	await _Reset()
	isReady = true
	get_window().size = DisplayServer.screen_get_size(-1) / 2.0
func _CliArgsRead():
	var args : PackedStringArray = OS.get_cmdline_user_args()
	if !args.is_empty():
		var index : int = args.find("--debug")
		if index != -1:
			isDebug = true
		else:
			isDebug = false
func _ThemeListBuild():
	var da : DirAccess = DirAccess.open("res://data/themes")
	var files : PackedStringArray = da.get_files()
	if !files.is_empty():
		var cc : int = files.size()
		if cc != 0:
			for i in range(cc):
				var fPath : String = "res://data/themes/" + str(files[i])
				var themeFile : Theme = ResourceLoader.load(str(fPath))
				if themeFile != null:
					themeList.append(themeFile)
					var themeName : String = ""
					match i:
						0:
							themeName = "Bright"
						1:
							themeName = "Industrial"
						2:
							themeName = "Midnight"
					ItemListThemes.add_item(str(themeName))
				i += 1
				if i >= cc:
					print(str(themeList))
					break
func _ConfigLoad():
	var cf : ConfigFile = ConfigFile.new()
	cf.load("user://config.cfg")
	if cf != null and cf.has_section("Common"):
		await _ApplySettingsFromConfig(cf)
		_DebugLogWrite("_ConfigLoad():: Loaded user config from " + str(OS.get_user_data_dir()) + "/config.cfg", 0)
	else:
		_DebugLogWrite("_ConfigLoad()::No user config found, creating it.", 0)
		await _CreateDefaultConfig(cf)
		await _ApplySettingsFromConfig(cf)

func _ApplySettingsFromConfig(cf : ConfigFile):
	if cf != null:
		if cf.has_section("Common"):
			if cf.has_section_key("Common", "Theme"):
				await _SetTheme(str(cf.get_value("Common", "Theme", "1")).to_int())
				_DebugLogWrite("_ApplySettingsFromConfig()::ReadValue Theme=" + str(cf.get_value("Common", "Theme", "1")), 0)
			if cf.has_section_key("Common", "LastFilePath"):
				lastFilePath = str(cf.get_value("Common", "LastFilePath", ""))
				_DebugLogWrite("_ApplySettingsFromConfig()::ReadValue lastFilePath=" + str(lastFilePath), 0)
func _WindowInit():
	get_tree().root.min_size = Vector2i(1024, 720)
	var screenSize : Vector2 = DisplayServer.screen_get_size(0)
	if screenSize != Vector2.ZERO:
		get_tree().root.size = screenSize / 2
		get_window().content_scale_size = get_tree().root.size
func _ComponentsInit():
	get_tree().root.size_changed.connect(window_size_changed)
	tree_exiting.connect(on_tree_exiting)
	TextInputField.text_changed.connect(game_title_text_changed)
	#TextInputFieldOffset.text_changed.connect(offset_input_text_changed)
	TextInputFieldOffset.text_submitted.connect(offset_input_text_changed)
	TextInputFieldCheatName.text_changed.connect(cheat_name_text_changed)
	ValueTypeButtonIncrease.pressed.connect(_ValueTypeButtonIncreasePressed)
	ValueTypeButtonDecrease.pressed.connect(_ValueTypeButtonDecreasePressed)
	TextOutputButton.pressed.connect(_TextOutputButtonPressed)
	ButtonReset.pressed.connect(button_reset_pressed)
	ButtonExit.pressed.connect(button_exit_pressed)
	ButtonAddCheatToList.pressed.connect(button_add_to_cheat_list_pressed)
	ButtonRemoveCheatFromList.pressed.connect(button_remove_from_cheat_list_pressed)
	PopupFileMenu.index_pressed.connect(file_popup_menu_item_selected)
	PopupAboutMenu.index_pressed.connect(about_popup_menu_item_selected)
	CheatList.item_clicked.connect(cheat_list_item_clicked)
	_SetHelpWindowState(false)
	_SetHelp2WindowState(false)
	FloatingWindow.visible = false
	ButtonImportFromClipboard.pressed.connect(button_import_from_clipboard_pressed)
	ButtonExportToClipboard.pressed.connect(button_export_to_clipboard_pressed)
	ButtonClearCheatList.pressed.connect(button_clear_cheat_list_pressed)
	FileDialogOpenFile.file_selected.connect(file_open_dialog_closed)
	FileDialogOpenFile.visible = false
	HelpWindowCloseButton.pressed.connect(help_window_close_button_pressed)
	HelpWindow2CloseButton.pressed.connect(help_window_2_close_button_pressed)
	_SetThemeWindowState(false)
	ThemeWindowCloseButton.pressed.connect(theme_window_close_button_pressed)
	ItemListThemes.item_clicked.connect(theme_list_item_selected)
# Process
func _process(_delta: float) -> void:
	_WindowUpdate()

# Filesystem Access
func _FileOpenDialog(filter : String):
	FileDialogOpenFile.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	FileDialogOpenFile.layout_toggle_enabled = true
	FileDialogOpenFile.size = get_tree().root.size
	if !filter.is_empty():
		FileDialogOpenFile.set_filename_filter("cheats.yml")
	FileDialogOpenFile.access = FileDialog.ACCESS_FILESYSTEM
	FileDialogOpenFile.show_hidden_files = true
	FileDialogOpenFile.use_native_dialog = false
	FileDialogOpenFile.folder_creation_enabled = false
	FileDialogOpenFile.deleting_enabled = false
	FileDialogOpenFile.visible = true
	if !lastFilePath.is_empty():
		FileDialogOpenFile.current_dir = str(lastFilePath)

# YAML Parsing
func _ParseYaml(file : FileAccess):
	if file != null:
		_DebugLogWrite("TODO:_ParseYml=" + str(file.get_path()), 0)
# CHD File Load/Saving(Deprecated)
#func _FileDialogOpen(open_mode : bool): # false = save, true = open
	#if open_mode:
		#var file_dialog : FileDialog = FileDialog.new()
		#file_dialog.use_native_dialog = true
		#file_dialog.add_filter("*.cht")
		#file_dialog.deleting_enabled = false
		#file_dialog.folder_creation_enabled = false
		#file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		#file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		#file_dialog.name = "OpenFileDialog"
		#add_child.call_deferred(file_dialog)
		#await file_dialog.tree_entered
		#file_dialog.owner = get_tree().edited_scene_root
		#file_dialog.visible = true
		#return file_dialog
	#else:
		#var file_dialog : FileDialog = FileDialog.new()
		#file_dialog.use_native_dialog = true
		#file_dialog.add_filter("*.cht")
		#file_dialog.deleting_enabled = true
		#file_dialog.folder_creation_enabled = true
		#file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		#file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		#file_dialog.name = "SaveFileDialog"
		#add_child.call_deferred(file_dialog)
		#await file_dialog.tree_entered
		#file_dialog.owner = get_tree().edited_scene_root
		#file_dialog.visible = true
		#return file_dialog
#func _CallOpenFileDialog():
	#var open_dialog : FileDialog = await _FileDialogOpen(true)
	#await open_dialog.file_selected
	#var selected_file : String = str(open_dialog.current_dir) + "/" + str(open_dialog.current_file)
	#open_dialog.queue_free()
	#await open_dialog.tree_exited
	#if !selected_file.is_empty():
		#pass
#func _CallSaveFileDialog():
	#var save_dialog : FileDialog = await _FileDialogOpen(false)
	#await save_dialog.file_selected
	#var selected_file : String = str(save_dialog.current_dir) + "/" + str(save_dialog.current_file)
	#save_dialog.queue_free()
	#await save_dialog.tree_exited
	#if !selected_file.is_empty():
		#pass
#func _LoadFileCht(path : String):
	#_DebugLogWrite("_LoadFileCht()::path=" + str(path), 0)
	#if !path.is_empty():
		#var cht_file : FileAccess = FileAccess.open(str(path), FileAccess.READ)
		#if cht_file != null:
			#_ParseFileCht(cht_file)
#func _ParseFileCht(file : FileAccess):
	#if file != null:
		#var header : PackedByteArray = file.get_buffer(5)
		#var header_len : int = header.size()
		#var header_hex : String = ""
		#if header_len == 5:
			#for i in range(header_len):
				#var value : String = _IntToHex(header[i])
				#if !value.is_empty():
					#header_hex += str(value)
				#i += 1
				#if i >= header_len:
					#break
		## Check that file header is "5243485440" in Hex (RCHT@)
		#if header_hex == "5243485440":
			#_DebugLogWrite("_LoadFileCht()::Header OK", 0)
			#var file_version : PackedByteArray = file.get_buffer(2)
			#var file_version_major : int = file_version[0]
			#var file_version_minor : int = file_version[1]
			#_DebugLogWrite("_LoadFileCht()::CHT File Version: Major:" + str(file_version_major) + " Minor:" + str(file_version_minor), 0)
		#else:
			#_DebugLogWrite("_LoadFileCht()::Invalid file header! got:" + str(header_hex) + ", expected:5243485440", 1)
			#file.close()
		## Get Game Title
		#var game_title : StringName = _FileChdReadBufferString(file, 256)
		#_DebugLogWrite("_LoadFileCht()::Got game title: " + str(game_title), 0)
		## Get Cheat Name
		#var cheat_name : StringName = _FileChdReadBufferString(file, 256)
		#_DebugLogWrite("_LoadFileCht()::Got cheat name: " + str(cheat_name), 0)
		## Get Value Type
		#var value_type : int = file.get_buffer(1)[0]
		#_DebugLogWrite("_LoadFileCht()::Got value type: " + str(_GetValueTypeString(value_type)), 0)
		## Get Cheat Offset
		##file.seek(file.get_position() - 1) # Hacky hack :3
		#var offset : String = _IntToHex(_FileChdReadBufferString(file, 256).to_int())
		#_DebugLogWrite("_LoadFileCht()::Got cheat offset: 0x0" + str(offset), 0)
		## Apply values to UI
		#await _Reset()
		#TextInputField.text = str(game_title)
		#TextInputFieldCheatName.text = str(cheat_name)
		#TextInputFieldOffset.text = "0x0" + str(offset)
		#selectedValueType = clampi(value_type, 0, 8)
		#await _ValueTypeDisplayUpdate()
		#await _CheatTextUpdate()
		#file.close()
#func _FileChdReadBufferString(file : FileAccess, length : int):
	#var out_string : StringName = ""
	#var buf : PackedByteArray = file.get_buffer(length)
	#var buf_size : int = buf.size()
	#if buf_size > 0:
		#for i in range(buf_size):
			#var letter : String = _IntToHex(buf[i])
			#var letter_hex : String = str(letter)
			#if letter_hex == "24":
				#if _IntToHex(buf[i + 1]) == "24":
					#file.seek(file.get_position() - buf_size + i + 2) # Seek to end of found value.
					#break
			#out_string += letter
			#i += 1
			#if i >= buf_size:
				#break
	#return str(out_string.hex_decode().get_string_from_utf8())
#func _SaveFileChd(path : String):
	#if !path.is_empty():
		#var file_access : FileAccess = FileAccess.open(str(path), FileAccess.WRITE)
		#if file_access != null:
			#_DebugLogWrite(str(file_access.get_path()), 0)
			## Write file magic
			#_FileChtWriteDataArray(file_access, "RCHT@".to_utf8_buffer(), false)
			## Write file version
			#_FileChtWriteVersion(file_access)
			## Write Game Title
			#_FileChtWriteDataArray(file_access, str(TextInputField.text).to_utf8_buffer(), true)
			## Write Cheat Name
			#_FileChtWriteDataArray(file_access, str(TextInputFieldCheatName.text).to_utf8_buffer(), true)
			## Write Value Type
			#_FileChtWriteValueType(file_access)
			## Write Offset
			#_FileChtWriteDataArray(file_access, str(_ParseOffsetValue()).to_utf8_buffer(), true)
			## Close File
			#file_access.close()
#func _FileChtWriteDataArray(file : FileAccess, in_buf : PackedByteArray, add_terminator : bool):
	#var buf_length : int = in_buf.size()
	#if file != null and buf_length > 0:
		#if add_terminator:
			#in_buf.append_array("$$".to_utf8_buffer())
		#file.store_buffer(in_buf)
#func _FileChtWriteVersion(file : FileAccess):
	#if file != null:
		#var buf : PackedByteArray
		#buf.append(01)
		#buf.append(00)
		#file.store_buffer(buf)
#func _FileChtWriteValueType(file : FileAccess):
	#if file != null:
		#var buf : PackedByteArray
		#buf.append(selectedValueType)
		#file.store_buffer(buf)

# Helpers
func _Reset():
	TextInputField.text = ""
	TextInputFieldOffset.text = "0x000000"
	TextInputFieldCheatName.text = ""
	selectedValueType = 0
	await _ValueTypeClamp()
	await _ValueTypeDisplayUpdate()
	await _CheatTextUpdate()
func _DebugLogWrite(message : String, level : int):
	if !message.is_empty():
		level = clampi(level, 0, 2)
		var timestamp : String = Time.get_time_string_from_system()
		match level:
			0:
				print("[INFO][" + str(timestamp) + "]::" + str(message))
			1:
				print("[WARNING][" + str(timestamp) + "]::" + str(message))
			2:
				printerr("[ERROR][" + str(timestamp) + "]::" + str(message))
	elif message.is_empty():
		printerr("_DebugLogWrite()::attempted to print empty string to log")
func _WindowUpdate():
	get_window().content_scale_size = get_tree().root.size
func _ValueTypeButtonIncreasePressed():
	if !_GetHelpWindowState():
		selectedValueType += 1
		_DebugLogWrite("_ValueTypeButtonIncreasePressed()::selectedValueType=" + str(selectedValueType), 0)
		await _ValueTypeClamp()
		await _ValueTypeDisplayUpdate()
		await _CheatTextUpdate()
func _ValueTypeButtonDecreasePressed():
	if !_GetHelpWindowState():
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
	if CheatList.item_count != 0:
		var outputString : String = ""
		var cc : int = CheatList.item_count
		_DebugLogWrite("itemCount=" + str(cc), 0)
		if cc != 0:
			for i in range(cc):
				var itemString = CheatList.get_item_text(i)
				_DebugLogWrite("itemString=" + str(itemString), 0)
				if !itemString.is_empty():
					if outputString.is_empty():
						outputString = itemString
					else:
						outputString = str(outputString) + str(itemString)
				i += 1
				if i >= cc:
					_DebugLogWrite("ClipboardOutput=" + str(outputString), 0)
					DisplayServer.clipboard_set(str(outputString))
					_FloatingWindowCreate(0, 1.0)
					break
func _ParseOffsetValue():
	var text : String = str(TextInputFieldOffset.text)
	if !text.is_empty():
		text = str(await _CheckForHexPrefix(str(text)))
		if text.is_valid_hex_number(true):
			return _HexToInt(text)
		else:
			return "null"
	else:
		_DebugLogWrite("_ParseOffsetValue()::text string is empty", 2)
func _CheckForHexPrefix(text : String):
	if !text.is_empty():
		var prefix : String = text.left(2)
		if prefix != "0x" or prefix != "0X":
			if text.is_valid_hex_number(false):
				return "0x" + str(text)
			else:
				return str(text)
		elif text.is_valid_hex_number(true):
			return str(text)
	else:
		_DebugLogWrite("_CheckForHexPrefix()::text string is empty!", 2)
func _IncrementOffsetValue(stride : int):
	if stride != 0 and !TextInputFieldOffset.text.is_empty() and TextInputFieldOffset.text.is_valid_hex_number(true):
		var i : int = _HexToInt(TextInputFieldOffset.text)
		i += stride
		i = clampi(i, 0, 472498237715)
		TextInputFieldOffset.text = str(_IntToHex(i))
		#TextInputFieldOffset.text = _CheckForHexPrefix(TextInputFieldOffset.text)
		_CheatTextUpdate()
func _HexToInt(hex : String):
	if !hex.is_empty() and hex.is_valid_hex_number(true):
		return hex.hex_to_int()
func _IntToHex(param : int):
	return str("%x" % param).to_upper()
func _CheatTextUpdate():
	cheatText = str(_GetGameTitle()) + "@@@" + str(_GetCheatName()) + "@@@" + str(selectedValueType) + "@@@" + str(await _ParseOffsetValue()) + "@@@@@@^^^"
	TextInputFieldOffset.text = str(_CheckForHexPrefix(TextInputFieldOffset.text))
	TextOutput.text = str(cheatText)
	_CheatTextLengthCheck()
func _CheatTextLengthCheck():
	if cheatText.length() > get_tree().root.size.x:
		get_tree().root.size.x = cheatText.length() + 4
func _SetDisplayFromCheatString(cheat_string : String):
	if !cheat_string.is_empty():
		var slice_count : int = cheat_string.get_slice_count("@@@")
		#print(str(slice_count))
		for i in range(slice_count):
			if i == 0:
				var game_title_string : String = str(cheat_string.get_slice("@@@", i))
				if !game_title_string.is_empty():
					TextInputField.text = str(cheat_string.get_slice("@@@", 0))
			elif i == 1:
				var cheat_name_string : String = str(cheat_string.get_slice("@@@", i))
				if !cheat_name_string.is_empty():
					TextInputFieldCheatName.text = str(cheat_name_string)
			elif i == 2:
				var value_type : int = str(cheat_string.get_slice("@@@", i)).to_int()
				selectedValueType = value_type
				await _GetValueType()
				await _ValueTypeDisplayUpdate()
			elif i == 3:
				var offset_int : String = str(cheat_string.get_slice("@@@", i))
				if !offset_int.is_empty():
					TextInputFieldOffset.text = "0x" + str(_IntToHex(str(offset_int).to_int()))
			i += 1
			if i >= slice_count:
				_CheatTextUpdate()
				break
func _SetTheme(id : int):
	if !themeList.is_empty() and themeList.size() >= id:
		var chosenTheme : Theme = themeList[id]
		if chosenTheme != null:
			theme = chosenTheme
			await _SaveConfigValue("Common", "Theme", str(id))
			match id:
				0:	# Bright
					background.color = "#c2c2c2"
					HelpWindow.get_child(0, true).color = "#c2c2c2"
					HelpWindow2.get_child(0, true).color = "#c2c2c2"
					ThemeWindowBase.get_child(0, true). color = "#c2c2c2"
					FloatingWindow.color = "#c2c2c2"
				1: # Default
					background.color = "#404040"
					HelpWindow.get_child(0, true).color = "#404040"
					HelpWindow2.get_child(0, true).color = "#404040"
					ThemeWindowBase.get_child(0, true). color = "#404040"
					FloatingWindow.color = "#404040"
				2: # Midnight
					background.color = Color.BLACK
					HelpWindow.get_child(0, true).color = Color.BLACK
					HelpWindow2.get_child(0, true).color = Color.BLACK
					ThemeWindowBase.get_child(0, true). color = Color.BLACK
					FloatingWindow.color = Color.BLACK
			_DebugLogWrite("_SetTheme()::successfully applied theme with id " + str(id), 0)
		else:
			_DebugLogWrite("_SetTheme():: failed to load requested theme with id " + str(id), 1)
	elif themeList.is_empty():
		_DebugLogWrite("_SetTheme()::ThemeList is empty!", 2)
	elif themeList.size() < id:
		_DebugLogWrite("_SetTheme()::Requested theme id is out of bounds! id=" + str(id) + ", themeList size=" + str(themeList.size()), 2)

# Keybinds Window
func _GetOverlayWindowState():
	if HelpWindow.visible == true or HelpWindow2.visible == true:
		return true
	else:
		return false
func _GetHelpWindowState():
	return HelpWindow.visible
func _SetHelpWindowState(state : bool):
	HelpWindow.visible = state
# ValueTypes Window
func _GetHelp2WindowState():
	return HelpWindow2.visible
func _SetHelp2WindowState(state : bool):
	if state:
		if _GetHelpWindowState():
			_SetHelpWindowState(false)
	HelpWindow2.visible = state
# Theme Window
func _SetThemeWindowState(state : bool):
	ThemeWindowBase.visible = state
func _GetThemeWindowState():
	return ThemeWindowBase.visible
# Config
func _CreateDefaultConfig(cf : ConfigFile):
	if cf != null:
		cf.set_value("Common", "CfgVersion", "1.0")
		cf.set_value("Common", "Theme", "1")
		cf.set_value("Common", "LastFilePath", "")
		cf.set_value("Common", "Language", "0")
		cf.save("user://config.cfg")

func _SaveConfigValue(section : String, key : String, value : String):
	if !section.is_empty() and !key.is_empty() and !value.is_empty():
		var cf : ConfigFile = ConfigFile.new()
		cf.load("user://config.cfg")
		cf.set_value(str(section), str(key), str(value))
		cf.save("user://config.cfg")

# Input
func _input(event: InputEvent) -> void:
	if event != null:
		if event.is_action_pressed("input_help"):
			if _GetHelpWindowState():
				_SetHelpWindowState(false)
			else:
				_SetHelpWindowState(true)
		if !_GetHelpWindowState():
			if event.is_action_pressed("input_export_current"):
				button_export_to_clipboard_pressed()
			elif event.is_action_pressed("input_offset_increment"):
				await button_offset_adjust_pressed(1)
			elif event.is_action_pressed("input_offset_decrement"):
				await button_offset_adjust_pressed(-1)
			elif event.is_action_pressed("input_import_clipboard"):
				await button_import_from_clipboard_pressed()
				if CheatList.item_count != 0:
					cheat_list_item_clicked(CheatList.item_count - 1, Vector2(0.0, 0.0), 1)


func _FloatingWindowCreate(id : int, timeout : float):
	if timeout > 0.0:
		FloatingWindow.visible = true
		var windowText : String = "N/A"
		match id:
			0:
				windowText = "Exported " + str(CheatList.item_count) + " Cheat(s) to clipboard."
			1:
				windowText = "Cheat Deleted."
			2:
				windowText = "Invalid Cheat!"
			3:
				windowText = "Imported Cheat(s) from clipboard"
			4:
				windowText = "Clipboard is empty!"
			5:
				windowText = "Exported to clipboard"
			6:
				windowText = "Nothing to export!"
			7:
				windowText = "Cheat List cleared"
		FloatingWindowLabel.text = windowText
		var t : Timer = Timer.new()
		t.autostart = true
		t.one_shot = true
		t.wait_time = timeout
		add_child.call_deferred(t)
		await t.tree_entered
		t.owner = get_tree().edited_scene_root
		await t.timeout
		FloatingWindow.visible = false
		t.queue_free()
		await t.tree_exited
func _CheatStringSyntaxCheck(cheat_string : String):
	var score : int = 0
	if !cheat_string.is_empty():
		var slice_count : int = cheat_string.get_slice_count("@@@")
		for i in range(slice_count):
			if i == 0:
				var game_title_string : String = str(cheat_string.get_slice("@@@", i))
				if !game_title_string.is_empty():
					score += 1
					_DebugLogWrite("_CheatStringSyntaxCheck()::GameTitleCheck Passed", 0)
				else:
					_DebugLogWrite("_CheatStringSyntaxCheck()::GameTitleCheck Failed", 0)
			elif i == 1:
				var cheat_name_string : String = str(cheat_string.get_slice("@@@", i))
				if !cheat_name_string.is_empty():
					score += 1
					_DebugLogWrite("_CheatStringSyntaxCheck()::CheatNameCheck Passed", 0)
				else:
					_DebugLogWrite("_CheatStringSyntaxCheck()::CheatNameCheck Failed", 0)
			elif i == 2:
				var value_type : int = str(cheat_string.get_slice("@@@", i)).to_int()
				if value_type >= 0 and value_type < 9:
					score += 1
					_DebugLogWrite("_CheatStringSyntaxCheck()::ValueTypeCheck Passed", 0)
				else:
					_DebugLogWrite("_CheatStringSyntaxCheck()::ValueTypeCheck Failed", 0)
			elif i == 3:
				var offset_int : String = str(cheat_string.get_slice("@@@", i))
				if offset_int.is_valid_int():
					score += 1
					_DebugLogWrite("_CheatStringSyntaxCheck()::OffsetCheck Passed", 0)
				else:
					_DebugLogWrite("_CheatStringSyntaxCheck()::OffsetCheck Failed", 0)
			i += 1
			if i >= slice_count:
				if score >= 4:
					_DebugLogWrite("_CheatStringSyntaxCheck()::IsValidCheat=true", 0)
					return true
				else:
					_DebugLogWrite("_CheatStringSyntaxCheck()::IsValidCheat=false", 0)
					return false
	else:
		_DebugLogWrite("_CheatStringSyntaxCheck()::IsValidCheat=false", 0)
		return false
func _CheatListCheckIfAlreadyInList(cheat_string : String):
	if !cheat_string.is_empty():
		var cc : int = CheatList.item_count
		if cc != 0:
			var cheatListEntries : Array[String]
			for i in range(cc):
				var item_text : String = CheatList.get_item_text(i)
				if !item_text.is_empty():
					cheatListEntries.append(item_text)
				i += 1
				if i >= cc:
					if !cheatListEntries.has(cheat_string):
						return false
					else:
						return true
		else:
			return false
	else:
		return true

# Callable Functions
func on_tree_exiting():
	_DebugLogWrite("on_tree_exiting()", 0)
	get_tree().root.size_changed.disconnect(window_size_changed)
	
	# TextInput Fields
	TextInputField.text_changed.disconnect(game_title_text_changed)
	TextInputFieldOffset.text_changed.disconnect(offset_input_text_changed)
	TextInputFieldCheatName.text_changed.disconnect(cheat_name_text_changed)
	
	# Value Type Buttons
	ValueTypeButtonIncrease.pressed.disconnect(_ValueTypeButtonIncreasePressed)
	ValueTypeButtonDecrease.pressed.disconnect(_ValueTypeButtonDecreasePressed)
	TextOutputButton.pressed.disconnect(_TextOutputButtonPressed)
	
	# TopBar Popup Menus
	PopupFileMenu.index_pressed.disconnect(file_popup_menu_item_selected)
	PopupAboutMenu.index_pressed.disconnect(about_popup_menu_item_selected)
	
	# Utility Buttons
	ButtonReset.pressed.disconnect(button_reset_pressed)
	ButtonExit.pressed.disconnect(button_exit_pressed)
	ButtonAddCheatToList.pressed.disconnect(button_add_to_cheat_list_pressed)
	ButtonRemoveCheatFromList.pressed.disconnect(button_remove_from_cheat_list_pressed)
	ButtonImportFromClipboard.pressed.disconnect(button_import_from_clipboard_pressed)
	ButtonExportToClipboard.pressed.disconnect(button_export_to_clipboard_pressed)
	ButtonClearCheatList.pressed.disconnect(button_clear_cheat_list_pressed)
	
	# Filesystem Menus
	if FileDialogOpenFile.file_selected.is_connected(file_open_dialog_closed):
		FileDialogOpenFile.file_selected.disconnect(file_open_dialog_closed)
	
	# Help Windows
	HelpWindowCloseButton.pressed.disconnect(help_window_close_button_pressed)
	HelpWindow2CloseButton.pressed.disconnect(help_window_2_close_button_pressed)
	# Theme Window
	ThemeWindowCloseButton.pressed.disconnect(theme_window_close_button_pressed)
	ItemListThemes.item_clicked.disconnect(theme_list_item_selected)
	
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
	if !_GetHelpWindowState() and !_GetHelp2WindowState() and !_GetThemeWindowState():
		await _Reset()
func button_exit_pressed():
	if !_GetHelpWindowState() and !_GetHelp2WindowState() and !_GetThemeWindowState():
		get_tree().quit(0)
func button_offset_adjust_pressed(stride : int):
	if stride != 0 and !_GetHelpWindowState() and !_GetHelp2WindowState() and !_GetThemeWindowState():
		_IncrementOffsetValue(stride)
func file_popup_menu_item_selected(index : int):
	if !_GetHelpWindowState() and !_GetHelp2WindowState() and !_GetThemeWindowState():
		if index != -1:
			if index == 0:
				_FileOpenDialog("cheats.yml")
				#_CallOpenFileDialog()
			elif index == 1:
				pass
				#_CallSaveFileDialog()
		else:
			_DebugLogWrite("file_popup_menu_item_selected()::fired with invalid index.(" + str(index) + ")", 2)
func about_popup_menu_item_selected(index : int):
	if !_GetHelpWindowState() and !_GetHelp2WindowState() and !_GetThemeWindowState():
		if index != -1:
			if index == 0: # Keybinds
				_SetHelpWindowState(true)
				_SetHelp2WindowState(false)
				_SetThemeWindowState(false)
			elif index == 1: # Value Types
				_SetHelp2WindowState(true)
				_SetHelp2WindowState(true)
				_SetThemeWindowState(true)
			elif index == 2: # Theme
				_SetHelp2WindowState(false)
				_SetHelpWindowState(false)
				_SetThemeWindowState(true)
func button_add_to_cheat_list_pressed():
	if !cheatText.is_empty() and !_CheatListCheckIfAlreadyInList(cheatText) and _CheatStringSyntaxCheck(cheatText) and !_GetHelpWindowState() and !_GetHelp2WindowState() and !_GetThemeWindowState():
		CheatList.add_item(str(cheatText), null, true)
func button_remove_from_cheat_list_pressed():
	if !_GetHelpWindowState() and !_GetHelp2WindowState() and !_GetThemeWindowState():
		var cl : PackedInt32Array = CheatList.get_selected_items()
		if !cl.is_empty():
			var cc : int = cl.size()
			if cc != 0:
				for i in range(cc):
					CheatList.remove_item(i)
					await _Reset()
					i += 1
					if i >= cc:
						_FloatingWindowCreate(1, 0.34)
						break
func button_clear_cheat_list_pressed():
	if !_GetHelpWindowState() and !_GetHelp2WindowState() and !_GetThemeWindowState():
		CheatList.clear()
		_FloatingWindowCreate(7, 1.0)
func cheat_list_item_clicked(index : int, pos : Vector2, mouse_button_id : int):
	if !_GetHelpWindowState() and !_GetHelp2WindowState() and !_GetThemeWindowState():
		if mouse_button_id == 1:	# Left Mouse Button
			var menuItem = CheatList.get_item_at_position(pos, true)
			if menuItem != null:
				var itemText : String = CheatList.get_item_text(index)
				if !itemText.is_empty():
					await _Reset()
					await _SetDisplayFromCheatString(itemText)
		elif mouse_button_id == 2:	# Right Mouse Button
			var menuItem = CheatList.get_item_at_position(pos, true)
			if menuItem != null:
				CheatList.remove_item(menuItem)
				_FloatingWindowCreate(1, 0.34)
func button_import_from_clipboard_pressed():
	if !_GetHelpWindowState() and !_GetHelp2WindowState() and !_GetThemeWindowState():
		var clipboard_string : String = DisplayServer.clipboard_get()
		if !clipboard_string.is_empty():
			var cheat_count : int = clipboard_string.get_slice_count("^^^")
			if cheat_count != 0:
				for i in range(cheat_count):
					var cheat_string : String = clipboard_string.get_slice("^^^", i)
					if !cheat_string.is_empty():
						if !_CheatListCheckIfAlreadyInList(cheat_string):
							if _CheatStringSyntaxCheck(cheat_string):
								CheatList.add_item(str(cheat_string), null, true)
							else:
								_FloatingWindowCreate(2, 1.0)
								break
					i += 1
					if i >= cheat_count:
						_FloatingWindowCreate(3, 1.0)
						break
		else:
			_FloatingWindowCreate(4, 1.0)
func button_export_to_clipboard_pressed():
	if !_GetHelpWindowState() and !_GetHelp2WindowState() and !_GetThemeWindowState():
		var clipboard_string : String = TextOutput.text
		if !clipboard_string.is_empty() and _CheatStringSyntaxCheck(str(clipboard_string)):
			DisplayServer.clipboard_set(str(clipboard_string))
			_FloatingWindowCreate(5, 1.0)
		else:
			_FloatingWindowCreate(6, 1.0)
func file_open_dialog_closed(file_path : String):
	FileDialogOpenFile.visible = false
	if !file_path.is_empty():
		var pth : String = ""
		var cc : int = file_path.get_slice_count("/")
		if cc != 0:
			for i in range(cc):
				pth = pth + str(file_path.get_slice("/", i))
				if i < cc - 1:
					pth = pth + "/"
				i += 1
				if i >= cc - 1:
					await _SaveConfigValue("Common", "LastFilePath", str(pth))
					lastFilePath = str(pth)
					break
		var fa : FileAccess = FileAccess.open(str(file_path), FileAccess.READ)
		if fa != null and !fa.get_path().is_empty():
			_ParseYaml(fa)
	else:
		_DebugLogWrite("file_open_dialog_closed()::selected file is null", 0)
func help_window_close_button_pressed():
	if _GetHelpWindowState():
		_SetHelpWindowState(false)
func help_window_2_close_button_pressed():
	if _GetHelp2WindowState():
		_SetHelp2WindowState(false)
func theme_window_close_button_pressed():
	_SetThemeWindowState(false)
func theme_list_item_selected(index : int, _pos : Vector2, mouse_button_index : int):
	await _SetThemeWindowState(false)
	if mouse_button_index == 1:
		await _SetTheme(index)
