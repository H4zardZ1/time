extends Node

const DEFAULT_SAVE_SPOT = "user://player_data/{0}/main.dat"
const BACKUP_SAVE_SPOT = "user://player_data/{0}/backup.dat"
const AUTOSAVE_SPOT = "user://autosave/main.dat"
const BACKUP_AUTOSAVE_SPOT = "user://autosave/backup.dat"
const VER = "2015/12/11"
# I don't really expect node deletions to come into this game so... Hope you don't don't mind!
var time_difference_between_this_and_last_save: float
var data: Dictionary[String, Variant] = {}

func _ready() -> void:
	_after_ready.call_deferred()

func _after_ready() -> void:
	var dir := DirAccess.open("user://player_data")
	if DirAccess.get_open_error() == ERR_DOES_NOT_EXIST: #or DirAccess.get_open_error() == ERR_INVALID_PARAMETER:
		DirAccess.make_dir_recursive_absolute("user://player_data")
		# reopen, since its null
		dir = DirAccess.open("user://player_data")
	if not dir:
		print("Cleanup of backup saves failed.")
		return
	
	
	dir.include_hidden = false
	var directories := dir.get_directories()
	for save_directory in directories:
		var l_file := FileAccess.open(DEFAULT_SAVE_SPOT.format([save_directory]), FileAccess.READ) 
		var ferror := FileAccess.get_open_error()
		l_file.close()
		if ferror != 0:
			l_file = FileAccess.open(BACKUP_SAVE_SPOT.format([save_directory]), FileAccess.READ) 
			ferror = FileAccess.get_open_error()
			l_file.close()
			if ferror != 0 and ferror != ERR_FILE_NOT_FOUND:
				DirAccess.remove_absolute(DEFAULT_SAVE_SPOT.format([save_directory]))
				DirAccess.remove_absolute(BACKUP_SAVE_SPOT.format([save_directory]))
			else:
				DirAccess.copy_absolute(BACKUP_SAVE_SPOT.format([save_directory]), DEFAULT_SAVE_SPOT.format([save_directory]))




	await get_tree().process_frame
	var file := FileAccess.open(AUTOSAVE_SPOT,FileAccess.READ)
	data = JSON.parse_string(file.get_line())
	file.close()
	get_tree().call_group("Has_Persistent", "load_data")

func save_to_file(save_name: String = ""):
	DirAccess.copy_absolute(DEFAULT_SAVE_SPOT.format([save_name]), BACKUP_SAVE_SPOT.format([save_name]))
	get_tree().call_group("Has_Persistent", "save_data")
	
	var file := FileAccess.open(DEFAULT_SAVE_SPOT.format([save_name]),FileAccess.WRITE)
	file.store_line(VER)
	file.store_line(JSON.stringify(data))
	file.close()
	print("save complete at {0}".format([Time.get_datetime_string_from_system(true, false)]))


func load_from_file(save_name: String = ""):
	# Technically checking if the file exists before reading them is unsafe. just read it immediately instead
	
	var file : FileAccess = null 
	# First, try to load the NEWER one
	if FileAccess.get_modified_time(DEFAULT_SAVE_SPOT.format([save_name])) + FileAccess.get_modified_time(BACKUP_SAVE_SPOT.format([save_name])) == 0:
		return
	if FileAccess.get_modified_time(DEFAULT_SAVE_SPOT.format([save_name])) > FileAccess.get_modified_time(BACKUP_SAVE_SPOT.format([save_name])):
		file = FileAccess.open(DEFAULT_SAVE_SPOT.format([save_name]),FileAccess.READ)
		if FileAccess.get_open_error():
			file = FileAccess.open(BACKUP_SAVE_SPOT.format([save_name]),FileAccess.READ)
			if FileAccess.get_open_error():
				return
	else:
		file = FileAccess.open(BACKUP_SAVE_SPOT.format([save_name]),FileAccess.READ)
		if FileAccess.get_open_error():
			file = FileAccess.open(DEFAULT_SAVE_SPOT.format([save_name]),FileAccess.READ)
			if FileAccess.get_open_error():
				return
	var old_ver: String = JSON.parse_string(file.get_line())
	data = JSON.parse_string(file.get_line())
	time_difference_between_this_and_last_save = Time.get_unix_time_from_system() - FileAccess.get_modified_time(file.get_path())
	print("difference in time: {0} seconds".format([time_difference_between_this_and_last_save]))
	file.close()
	old_ver_updates(old_ver)
	get_tree().call_group("Has_Persistent", "load_data")

func _autosave():
	#get_tree().call_group("Has_Persistent", "save_data")
	#DirAccess.copy_absolute(AUTOSAVE_SPOT, BACKUP_AUTOSAVE_SPOT)
#
	#var file := FileAccess.open(AUTOSAVE_SPOT,FileAccess.WRITE)
	#if FileAccess.get_open_error():
		#return
	#data.time_last_save = Time.get_unix_time_from_system()
	#file.store_line(JSON.stringify(data))
	#file.close()
	pass

func old_ver_updates(_v: String) -> void:
	# Looks good so far!
	return
