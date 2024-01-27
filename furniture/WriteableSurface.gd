extends Node3D

var label_text:
	set(val):
		$Label3D.text = val
		if multiplayer.is_server():
			sync_label_text.rpc(val)
		
	get:
		return $Label3D.text

@onready var camera: Camera3D = $Camera3D
@onready var light: Node3D = $Light

func _ready():
	light.visible = false
	label_text = ""

func _process(delta):
	pass

@rpc
func sync_label_text(text):
	label_text = text

func set_illuminate(active: bool):
	print("illuminated ", active)
	light.visible = active
