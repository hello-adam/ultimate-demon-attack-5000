extends Node3D

@onready var hud_menu = $HUD/M/HB/VB/Menu
@onready var console = $HUD/M/HB/ChatConsole
@onready var jc: JamConnect = $JamConnect

func _ready():
	if not OS.has_feature("server"):
		$Music/Menu.play()
	console.jam_connect = jc
	hud_menu.get_popup().id_pressed.connect(_on_menu_selection)
	console.visible = false
	
func _on_game_time_limit_timeout():
	if jc.server:
		print("Game time limit reached - shutting down...")
		jc.server.shut_down()

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
	$Level1.remove_player(pid)

func _on_jam_connect_player_connected(pid: int, username: String) -> void:
	$GameTimeLimit.stop()
	$GameTimeLimit.start(60 * 60)
	$Level1.spawn_player(pid, username)
	stop_menu_music.rpc()

@rpc("reliable")
func stop_menu_music():
	$Music/Menu.stop()

func _on_jam_connect_server_pre_ready():
	if not OS.has_feature("server"):
		$Music/Menu.stop()
