extends PlayerBase

var popup_scn = preload("res://ui/PopupMessage.tscn")
var popup_msg: PopupMessage:
	get:
		if popup_msg == null:
			popup_msg = popup_scn.instantiate()
			add_child(popup_msg)
		return popup_msg
		
var message:
	set(val):
		message = val
	get:
		return message

var typing = false
var target_wall = null

@onready var paint_bar = $HUD/M/VB/Paint
var paint := 10.0:
	set(val):
		paint = val
		if paint_bar:
			paint_bar.value = val
		

var camera_base_transform: Transform3D

var illuminated_wall = null:
	set(val):
		if illuminated_wall != null:
			illuminated_wall.set_illuminate(false)
		if val != null:
			val.set_illuminate(true)
		illuminated_wall = val

@rpc("call_local", "reliable")
func sync_paint(p: float):
	paint = p

@rpc("reliable")
func show_msg(msg: String):
	if pid != multiplayer.get_unique_id():
		return
	popup_msg.show_message(msg)
	
func _ready():
	super._ready()
	camera_base_transform = camera.transform
	if multiplayer.get_unique_id() == pid:
		$HUD.visible = true
		popup_msg.show_message.call_deferred("You are a Cat.\n\nThe Hoomin must know the truth.\n\nTell him with graffiti.")
	else:
		$HUD.visible = false

@rpc("reliable")
func set_hud_visibility(v: bool):
	$HUD.visible = v

@rpc("any_peer")
func send_string(msg: String):
	if multiplayer.get_remote_sender_id() != self.pid:
		return
	if target_wall != null:
		if msg == "Enter":
			end_typing()
			return
		elif msg == "Space":
			msg = " "
		elif len(msg) > 1:
			return
		target_wall.label_text += msg
		sync_paint.rpc(paint - 1.0)
		
		if len(target_wall.label_text) >= 40 or paint < 1.0:
			end_typing()

func end_typing():
	target_wall = null
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
	
	if multiplayer.is_server() and not interacting:
		if interact_requested:
			interact_requested = false

			for target in $InteractionArea.get_overlapping_areas():
				if target != null:
					if target.get_parent().is_in_group("write_surface"):
						target_wall = target.get_parent()
						target_wall.label_text = ""
						start_typing.rpc_id(pid, target_wall.get_path())
						set_interacting.rpc(true)
						return
						

func _physics_process(delta):
	super._physics_process(delta)

func _on_interaction_area_area_entered(area):
	if multiplayer.is_server() and self.pid != -1:
		if area.get_parent().is_in_group("paint"):
			print("getting paint")
			sync_paint.rpc(paint + 10.0)
			area.get_parent().collect.rpc()
	
	if multiplayer.get_unique_id() != self.pid:
		return
	if area.get_parent().is_in_group("write_surface"):
		illuminated_wall = area.get_parent()

func _on_interaction_area_area_exited(area):
	if multiplayer.get_unique_id() != self.pid:
		return
	if area.get_parent() == illuminated_wall:
		illuminated_wall = null

@rpc
func start_typing(node_path: String):
	if multiplayer.get_unique_id() != pid:
		return
	print("target wall", node_path)
	target_wall = get_node(node_path)
	typing = true
	illuminated_wall = null
	camera.global_transform = target_wall.camera.global_transform
	#$Camera3D.global_rotation = target_wall.camera.global_rotation

@rpc
func stop_typing():
	if multiplayer.get_unique_id() != pid:
		return
	target_wall = null
	typing = false
	camera.transform = camera_base_transform
