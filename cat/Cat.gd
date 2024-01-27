extends PlayerBase

var popup_scn = preload("res://ui/PopupMessage.tscn")
var popup_msg: PopupMessage
var message:
	set(val):
		message = val
	get:
		return message

func _ready():
	super._ready()
	if multiplayer.get_unique_id() == pid:
		popup_msg = popup_scn.instantiate()
		add_child(popup_msg)
		popup_msg.show_message.call_deferred("You are a Cat.\n\nThe Hoomin must know the truth.\n\nTell him with graffiti.")


func _input(event):
	super._input(event)

func _unhandled_input(event):
	super._unhandled_input(event)

func _process(delta):
	super._process(delta)
	
	if multiplayer.is_server():
		if interact_requested:
			print("True")
			interact_requested = false
			
			for target in $InteractionArea.get_overlapping_areas():
				if target.is_in_group("write_surface"):
					print("test")
					post_the_text(target.get_parent())
					return
				else:
					pass # do the swap
					return

func _physics_process(delta):
	super._physics_process(delta)

func open_message_pad():
	$Camera3D/CanvasLayer/TextEdit.show()
	$Camera3D/CanvasLayer/TextEdit.grab_focus()

func _on_text_edit_text_changed():
	message = $Camera3D/CanvasLayer/TextEdit.text
	do_interact()

func _on_interaction_area_area_entered(area):
	if area.get_parent().is_in_group("write_surface"):
		open_message_pad()

func post_the_text(target):
	print(target)
	set_interacting.rpc(true)
	do_post_the_text.rpc_id(pid)
	await get_tree().create_timer(1.7).timeout
	set_interacting.rpc(false)

@rpc
func do_post_the_text():
	if multiplayer.get_unique_id() != pid:
		return
	print("message")
