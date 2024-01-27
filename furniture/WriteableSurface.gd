extends Node3D

var label_text:
	set(val):
		$Label3D.text = val
		if multiplayer.is_server():
			sync_label_text.rpc(val)
		
	get:
		return $Label3D.text

@onready var camera: Camera3D = $Camera3D

func _ready():
	label_text = "Example Text that could be overwritten by player 2"

func _process(delta):
	pass

@rpc
func sync_label_text(text):
	label_text = text
