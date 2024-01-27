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

var camera_base_transform: Transform3D

var illuminated_wall = null:
	set(val):
		if illuminated_wall != null:
			illuminated_wall.set_illuminate(false)
		if val != null:
			val.set_illuminate(true)
		illuminated_wall = val

func _ready():
	super._ready()
	camera_base_transform = camera.transform
	if multiplayer.get_unique_id() == pid:
		popup_msg = popup_scn.instantiate()
		add_child(popup_msg)
		popup_msg.show_message.call_deferred("You are a Cat.\n\nThe Hoomin must know the truth.\n\nTell him with graffiti.")

@rpc("any_peer")
func send_string(msg: String):
	if multiplayer.get_remote_sender_id() != self.pid:
		return
	if target_wall != null:
		if msg == "Enter":
			stop_typing.rpc_id(pid)
			set_interacting.rpc(false)
			return
		elif msg == "Space":
			msg = " "
		elif len(msg) > 1:
			return
		target_wall.label_text += msg
		
		if len(target_wall.label_text) >= 40:
			stop_typing.rpc_id(pid)
			set_interacting.rpc(false)


func _input(event):
	super._input(event)

func _unhandled_input(event):
	super._unhandled_input(event)
	if typing:
		if event is InputEventKey and event.is_pressed():
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
						target_wall = target.get_parent()
						target_wall.label_text = ""
						start_typing.rpc_id(pid, self.target_wall.get_path())
						set_interacting.rpc(true)
					else:
						pass # do the swap
						return

func _physics_process(delta):
	super._physics_process(delta)

func _on_interaction_area_area_entered(area):
	if multiplayer.get_unique_id() != self.pid:
		return
	if area.get_parent().is_in_group("write_surface"):
		illuminated_wall = area.get_parent()

func _on_interaction_area_area_exited(area):
	if multiplayer.get_unique_id() != self.pid:
		return
	if area.get_parent() == illuminated_wall:
		illuminated_wall = null

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
	illuminated_wall = null
	camera.global_transform = target_wall.camera.global_transform
	#$Camera3D.global_rotation = target_wall.camera.global_rotation

@rpc
func stop_typing():
	target_wall = null
	typing = false
	camera.transform = camera_base_transform
