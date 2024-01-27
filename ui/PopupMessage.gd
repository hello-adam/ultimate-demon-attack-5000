extends Popup
class_name PopupMessage

@onready var msg_label: Label = $M/VB/Msg

var display_text = ""

func _ready():
	pass

func _process(delta):
	pass

func show_message(msg: String):
	display_text = msg
	# todo: add animated text
	msg_label.text = display_text
	popup_centered_ratio(0.5)

func _on_yes_pressed():
	hide()
