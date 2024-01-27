extends PlayerBase

var popup_scn = preload("res://ui/PopupMessage.tscn")
var popup_msg: PopupMessage

func _ready():
	super._ready()
	if multiplayer.get_unique_id() == pid:
		popup_msg = popup_scn.instantiate()
		add_child(popup_msg)
		popup_msg.show_message("You are a Human.\n\nYou must find your cat.\nPet cats to stay lucid.\n\nDon't pet weird cats.")

func _input(event):
	super._input(event)

func _unhandled_input(event):
	super._unhandled_input(event)

func _process(delta):
	super._process(delta)
	
	if multiplayer.is_server():
		if interact_requested:
			dummy_interaction()
			interact_requested = false

func dummy_interaction():
	if not multiplayer.is_server():
		return
	
	print("dummy interaction start")
	set_interacting.rpc(true)
	await get_tree().create_timer(1.0).timeout
	set_interacting.rpc(false)
	print("dummy interaction done")

func _physics_process(delta):
	super._physics_process(delta)

