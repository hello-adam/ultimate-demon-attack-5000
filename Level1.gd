extends Node3D

var human_scn = preload("res://human/Human.tscn")
var cat_scn = preload("res://cat/Cat.tscn")

var human_spawned = false

func spawn_player(pid: int, nametag: String):
	print("spawning player ", pid, " ", nametag)
	var p = null
	if human_spawned:
		p = cat_scn.instantiate()
	else:
		p = human_scn.instantiate()
		human_spawned = true
	
	p.pid = pid
	p.nametag = nametag
	p.position = $SpawnPoints.get_children().pick_random().position
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
