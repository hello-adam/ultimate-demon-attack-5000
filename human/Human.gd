extends PlayerBase

var popup_scn = preload("res://ui/PopupMessage.tscn")
var popup_msg: PopupMessage:
	get:
		if popup_msg == null:
			popup_msg = popup_scn.instantiate()
			add_child(popup_msg)
		return popup_msg

@onready var interact_area: Area3D = $InteractionArea
@onready var lucid_bar: ProgressBar = $HUD/M/VB/Lucidity
var lucid_sync_time := 0.0
var lucid_sync_interval := 2.0

var cat_scn = preload("res://cat/Cat.tscn")

var has_won = false

func stop_music():
	for child in get_node("../../../Music").get_children():
		child.stop()

func play_theme_music():
	stop_music()
	get_node("../../../Music/HumanTheme").play()
	
@rpc()
func start_theme_sync():
	play_theme_music()

func _ready():
	super._ready()
	lucid_bar.value = 70.0
	popup_msg.popup_hide.connect(on_popup_dismiss)
	if multiplayer.get_unique_id() == pid:
		play_theme_music()
		$HUD.visible = true
		popup_msg.show_message("You wake up in the middle of the night.\n\n Or are you awake? \n Your cat will know the answer \n You need to find your cat.\n")
	else:
		popup_msg.hide()
		$HUD.visible = false

func _input(event):
	super._input(event)

func _unhandled_input(event):
	super._unhandled_input(event)

func _process(delta):
	super._process(delta)
	
	
	if multiplayer.get_unique_id() == pid:
		lucid_bar.value -= delta * 2
		
	if multiplayer.is_server():
		lucid_bar.value -= delta * 2
		lucid_sync_time += delta
		if lucid_sync_time >= lucid_sync_interval:
			sync_lucidity.rpc_id(pid, lucid_bar.value)
		
		if lucid_bar.value <= 0.1:
			lucid_bar.value = 90.0
			sync_lucidity.rpc_id(pid, lucid_bar.value)
			position = get_node("../../SpawnPoints/HumanSpawnPoint").position
			y_rotation = get_node("../../SpawnPoints/HumanSpawnPoint").rotation.y
			show_msg.rpc_id(pid, "Was it just a dream?\n\nYour cat will know the answer\nYou need to find your cat.\n")
			
		
		if not interacting:
			if interact_requested:
				interact_requested = false
				
				for target in interact_area.get_overlapping_areas():
					if target.is_in_group("cat"):
						if target.is_in_group("npc"):
							pet_the_cat(target.get_parent())
							return
						else:
							body_swap(target.get_parent())
							return
						
				#dummy_interaction()

@rpc("reliable")
func set_hud_visibility(v: bool):
	$HUD.visible = v

@rpc()
func sync_lucidity(val: float):
	lucid_bar.value = val

func body_swap(other):
	print("body swapping")
	set_interacting.rpc(true)
	other.set_interacting.rpc(true)
	
	var old_hoomin = pid
	var new_hoomin = other.pid
	
	set_hud_visibility.rpc_id(old_hoomin, false)
	other.set_hud_visibility.rpc_id(new_hoomin, false)
	
	# todo: swap animation
	await get_tree().create_timer(0.5)
	
	sync_body_swap.rpc(other.get_path())
	
	await get_tree().create_timer(0.25)
	
	show_msg.rpc_id(new_hoomin, "You are a Human.\n\nYou must find your cat.\nPet cats to stay lucid.\n\nDon't pet weird cats.")
	set_hud_visibility.rpc_id(new_hoomin, true)
	start_theme_sync.rpc_id(new_hoomin)
	other.show_msg.rpc_id(old_hoomin, "You tried to pet a weird cat.\n\nNow you are a weird cat.")
	other.set_hud_visibility.rpc_id(old_hoomin, true)
	other.start_theme_sync.rpc_id(old_hoomin)
	
	set_interacting.rpc(false)
	other.set_interacting.rpc(false)
	print("done body swapping")

@rpc("reliable")
func show_msg(msg: String):
	if pid != multiplayer.get_unique_id():
		return
	popup_msg.show_message(msg)

@rpc("call_local", "reliable")
func sync_body_swap(other_path: String):
	var other = get_node(other_path)
	if other == null:
		push_error("cannot get other node")
		return
	
	var my_pid = pid
	pid = other.pid
	state_key = "%d" % pid
	other.pid = my_pid
	other.state_key = "%d" % my_pid
	
	if pid == multiplayer.get_unique_id():
		camera.make_current()
	elif other.pid == multiplayer.get_unique_id():
		other.camera.make_current()

func pet_the_cat(target):
	print("petting the cat")
	set_interacting.rpc(true)
	target.receive_pets(2.0)
	if target.true_cat:
		do_win_the_game.rpc_id(pid)
		has_won = true
	else:
		do_pet_the_cat.rpc_id(pid)
		lucid_bar.value += 50
		sync_lucidity.rpc_id(pid, lucid_bar.value)
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
	popup_msg.show_message("You pet the cat. \n\n Where did this cat come from? \n\n This isn't your cat. \n Find your cat.")

@rpc
func do_win_the_game():
	if multiplayer.get_unique_id() != pid:
		return
	var base_camera_pos = camera.position
	var tween = get_tree().create_tween()
	tween.tween_property(camera, "position", base_camera_pos + Vector3(0, -0.41, 0), 1.2).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(camera, "position", base_camera_pos, 0.5).set_trans(Tween.TRANS_CIRC)
	tween.play()
	await tween.finished
	has_won = true
	popup_msg.show_message("Yes. \nThis is your cat. You've found your cat. \n But realization hits you. \n\n You were the cat the whole time.\n\nNow go vandalize things with the other cats.")

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

func on_popup_dismiss():
	print("popup dismiss")
	if has_won:
		print("popup dismiss on win")
		ready_to_win.rpc_id(1)

@rpc("any_peer")
func ready_to_win():
	print("ready to win")
	if not multiplayer.is_server():
		return
	if not has_won:
		return
	
	print("you cat")
	var you_cat = cat_scn.instantiate()
	you_cat.transform = transform
	you_cat.pid = pid
	you_cat.nametag = nametag
	you_cat.name = str(pid) + "THECAT"
	get_parent().add_child(you_cat)
	queue_free()
	
