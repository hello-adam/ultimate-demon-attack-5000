extends PlayerBase

func _ready():
	buffered_sync = get_node("../../../BufferedSync")
	state_key = get_path()

func _input(event):
	pass

func _unhandled_input(event):
	pass

func _process(delta):
	super._process(delta)

func _physics_process(delta):
	super._physics_process(delta)
