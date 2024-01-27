extends PlayerBase

var popup_scn = preload("res://ui/PopupMessage.tscn")
var popup_msg: PopupMessage

@onready var interact_area: Area3D = $InteractionArea
@onready var camera: Camera3D = $Camera3D

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
			interact_requested = false
			
			for target in interact_area.get_overlapping_areas():
				if target.is_in_group("cat"):
					if target.is_in_group("npc"):
						pet_the_cat(target.get_parent())
						return
					else:
						pass # do the swap
						return
					
			dummy_interaction()

func pet_the_cat(target):
	print("petting the cat")
	set_interacting.rpc(true)
	target.receive_pets(2.0)
	do_pet_the_cat.rpc_id(pid)
	await get_tree().create_timer(1.7).timeout
	set_interacting.rpc(false)
	print("done petting the cat")

@rpc
func do_pet_the_cat():
	if multiplayer.get_unique_id() != pid:
		return
	var base_camera_pos = camera.position
	var tween = get_tree().create_tween()
	tween.tween_property(camera, "position", base_camera_pos + Vector3(0, -0.41, 0), 1.2).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(camera, "position", base_camera_pos, 0.5).set_trans(Tween.TRANS_CIRC)
	tween.play()
	await tween.finished
	popup_msg.show_message("You pet the cat.")

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

