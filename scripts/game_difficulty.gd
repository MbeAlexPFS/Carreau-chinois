extends Control

var mode = "easy"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	updatebuttons()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func updatebuttons() -> void :
	if mode == "easy" :
		$easy.label_settings.font_color = Color(255,255,255,255)
		$medium.label_settings.font_color = Color(255,255,255,0.6)
		$hard.label_settings.font_color = Color(255,255,255,0.6)
	elif mode == "medium" :
		$easy.label_settings.font_color = Color(255,255,255,0.6)
		$medium.label_settings.font_color = Color(255,255,255,255)
		$hard.label_settings.font_color = Color(255,255,255,0.6)
	elif mode == "hard" :
		$easy.label_settings.font_color = Color(255,255,255,0.6)
		$medium.label_settings.font_color = Color(255,255,255,0.6)
		$hard.label_settings.font_color = Color(255,255,255,255)

func _on_retour_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")

func _on_button_pressed() -> void:
	mode = "easy"
	updatebuttons()

func _on_button_2_pressed() -> void:
	mode = "medium"
	updatebuttons()

func _on_button_3_pressed() -> void:
	mode = "hard"
	updatebuttons()

func _on_next_pressed() -> void:
	Engine.set_meta("game_diff", mode)
	get_tree().change_scene_to_file("res://game option.tscn")
