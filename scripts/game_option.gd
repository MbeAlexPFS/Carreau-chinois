extends Control

var lvl = 1
var nbpion = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	updatelvl()
	updatepion()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func updatelvl() -> void:
	if lvl == 1 :
		$Lv2.modulate = Color(255.014, 255.014, 255.014, 0.6)
		$Lv1.modulate = Color(255.014, 255.014, 255.014, 255)
	elif lvl == 2 :
		$Lv1.modulate = Color(255.014, 255.014, 255.014, 0.6)
		$Lv2.modulate = Color(255.014, 255.014, 255.014, 255)
	
func updatepion() -> void:
	if nbpion == 1 :
		$j2.label_settings.font_color = Color(255.014, 255.014, 255.014, 0.6)
		$j1.label_settings.font_color = Color(255.014, 255.014, 255.014, 255)
	elif nbpion == 2 :
		$j1.label_settings.font_color = Color(255.014, 255.014, 255.014, 0.6)
		$j2.label_settings.font_color = Color(255.014, 255.014, 255.014, 255)

func _on_retour_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_lvl_1_pressed() -> void:
	lvl = 1
	nbpion = 1
	updatepion()
	updatelvl()

func _on_lvl_2_pressed() -> void:
	lvl = 2
	updatelvl()

func _on_pion_pressed() -> void:
	nbpion = 1
	updatepion()

func _on_pion_2_pressed() -> void:
	if lvl == 2 :
		nbpion = 2
		updatepion()

func _on_jouer_pressed() -> void:
	Engine.set_meta("lvl", lvl)
	Engine.set_meta("nbpion", nbpion)
	Engine.set_meta("turn", 0)
	if lvl == 1 :
		get_tree().change_scene_to_file("res://game.tscn")
	elif lvl == 2 and nbpion == 1 :
		get_tree().change_scene_to_file("res://gamelvl2-3pions.tscn")
	elif lvl == 2 and nbpion == 2 :
		get_tree().change_scene_to_file("res://gamelvl2-4pions.tscn")


func _on_jouer_2_pressed() -> void:
	Engine.set_meta("lvl", lvl)
	Engine.set_meta("nbpion", nbpion)
	Engine.set_meta("turn", 1)
	if lvl == 1 :
		get_tree().change_scene_to_file("res://game.tscn")
	elif lvl == 2 and nbpion == 1 :
		get_tree().change_scene_to_file("res://gamelvl2-3pions.tscn")
	elif lvl == 2 and nbpion == 2 :
		get_tree().change_scene_to_file("res://gamelvl2-4pions.tscn")
