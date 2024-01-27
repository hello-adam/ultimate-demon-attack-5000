extends Node3D

@onready var hud_menu = $HUD/M/HB/VB/Menu
@onready var console = $HUD/M/HB/ChatConsole
@onready var jc: JamConnect = $JamConnect

# for collecting data to save to a file on server shutdown
var game_log_data: Array[String] = []
var prev_log_text = ""

# values for controlling asynchronous GameDB updates in _process
var waiting_for_async: bool = false
var save_counter: float = 0.0
var save_timeout: float = 5.0
var save_idx: int = 0

func _ready():
	console.jam_connect = jc
	hud_menu.get_popup().id_pressed.connect(_on_menu_selection)

func _on_console_pressed():
	console.visible = not console.visible

func _on_menu_selection(id: int):
	if id == 0:
		await jc.client.leave_game()
	elif id == 1:
		if await jc.client.leave_game():
			get_tree().quit(0)
		else:
			get_tree().quit(1)

func _on_jam_connect_player_disconnected(pid: int, pinfo):
	game_log_data.append("player '%s' left at %s" % [pinfo.get("name", "<>"), Time.get_datetime_string_from_system(true)])
	$Level1.remove_player(pid)

func _on_jam_connect_player_verified(pid: int, pinfo):
	var player_name = pinfo.get("name", "<>")
	var player_db_key: String = "PLR-%s" % player_name
	var player_data = jc.server.db.get_game_data(player_db_key)
	game_log_data.append("player '%s' joined at %s" % [player_name, Time.get_datetime_string_from_system(true)])
	
	jc.notify_players.rpc_id(pid, "Log from previous game:\n%s" % prev_log_text)
	$Level1.spawn_player(pid, player_name, player_data)


#
# Demonstration of how the the GameFiles API can be used to persist large files
# between sessions.
#

# Saves a contrived "game log" in response to the server shutting down
func _on_jam_connect_server_shutting_down():
	if not multiplayer.is_server() or jc.server.dev_mode:
		return
		
	var game_log = FileAccess.open("user://game.log", FileAccess.WRITE)
	var game_log_path := game_log.get_path_absolute()
	for log_data in game_log_data:
		game_log.store_line(log_data);
	game_log.close()
	
	if not jc.server.files.put_game_file("game_log", game_log_path):
		printerr("Failed to save game log: ",  jc.server.files.get_last_error())

# Load part of the contrived "game log" from the previous function as prev_log_text in response to
# the server starting up.
func _on_jam_connect_server_pre_ready():
	if not multiplayer.is_server() or jc.server.dev_mode:
		return
	
	var prev_log_path: String = OS.get_user_data_dir() + "/prev_game.log"
	
	var res = jc.server.files.get_game_file("game_log", prev_log_path)
	if not res:
		printerr("Failed to load game log: ", jc.server.files.get_last_error())
		return
	
	var prev_log = FileAccess.open("user://prev_game.log", FileAccess.READ)
	var line = prev_log.get_line()
	var n = 0
	while line and n < 10:
		prev_log_text += line + "\n"
		n += 1
		line = prev_log.get_line()
