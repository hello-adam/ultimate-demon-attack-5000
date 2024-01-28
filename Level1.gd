extends Node3D

var human_scn = preload("res://human/Human.tscn")
var cat_scn = preload("res://cat/Cat.tscn")

var paint_scn = preload("res://furniture/PaintCan.tscn")

var human_spawned = false

func spawn_player(pid: int, nametag: String):
	print("spawning player ", pid, " ", nametag)
	var p = null

	if human_spawned:
		p = cat_scn.instantiate()
		p.transform = $SpawnPoints.get_children().pick_random().transform
		
		if $SpawnTimer.is_stopped():
			$SpawnTimer.start()
	else:
		p = human_scn.instantiate()
		human_spawned = true
		p.transform = $SpawnPoints/HumanSpawnPoint.transform
	
	p.pid = pid
	p.nametag = nametag
	p.name = str(pid)
	$Players.add_child(p, true)

func remove_player(pid):
	print("removing player ", pid)
	for p in $Players.get_children():
		if p.pid == pid:
			p.queue_free()
			return

func get_players():
	return $Players.get_children()


func _on_spawn_timer_timeout():
	var paint = paint_scn.instantiate()
	paint.position = Vector3(randf_range(-100, 100), 0.0, randf_range(-100, 100))
	$Paint.add_child(paint, true)
