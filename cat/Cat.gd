extends PlayerBase

var popup_scn = preload("res://ui/PopupMessage.tscn")
var popup_msg: PopupMessage
var message:
	set(val):
		message = val
	get:
		return message

var typing = false
var target_wall = null

func _ready():
	super._ready()
	if multiplayer.get_unique_id() == pid:
		popup_msg = popup_scn.instantiate()
		add_child(popup_msg)
		popup_msg.show_message.call_deferred("You are a Cat.\n\nThe Hoomin must know the truth.\n\nTell him with graffiti.")

@rpc("any_peer")
func send_string(msg: String):
	if multiplayer.get_remote_sender_id() != self.pid:
		return
	if target_wall != null:
		target_wall.label_text += msg
	

func _input(event):
	super._input(event)

func _unhandled_input(event):
	super._unhandled_input(event)
	if typing:
		if event is InputEventKey:
			var input = event.as_text_keycode()
			send_string.rpc_id(1, input)
	
func _process(delta):
	super._process(delta)
	
	if multiplayer.is_server():
		if interact_requested:
			interact_requested = false

			for target in $InteractionArea.get_overlapping_areas():
				if target != null:
					if target.get_parent().is_in_group("write_surface"):
						self.target_wall = target.get_parent()
						start_typing.rpc(self.target_wall.get_path())
						set_interacting.rpc(true)
					else:
						pass # do the swap
						return

func _physics_process(delta):
	super._physics_process(delta)

func _on_interaction_area_area_entered(area):
	if area.get_parent().is_in_group("write_surface"):
		#highlight surface
		pass

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

@rpc
func start_typing(node_path: String):
	target_wall = get_node(node_path)
	typing = true
	$Camera3D.global_position = target_wall.camera.global_position
	$Camera3D.rotation = target_wall.camera.rotation
	
	
	
@rpc
func stop_typing():
	typing = false
	
