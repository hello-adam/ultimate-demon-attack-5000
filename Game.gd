extends Node3D

@onready var hud_menu = $HUD/M/HB/VB/Menu
@onready var console = $HUD/M/HB/ChatConsole
@onready var jc: JamConnect = $JamConnect

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
	$Level1.remove_player(pid)

func _on_jam_connect_player_verified(pid: int, pinfo):
	var player_name = pinfo.get("name", "<>")
	$Level1.spawn_player(pid, player_name)

