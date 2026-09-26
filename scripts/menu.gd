extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_ia_pressed() -> void:
	Engine.set_meta("game_mode", "ia")
	get_tree().change_scene_to_file("res://game difficulty.tscn")

func _on_v_1_pressed() -> void:
	Engine.set_meta("game_mode", "1v1")
	get_tree().change_scene_to_file("res://game option.tscn")


func _on_tuto_pressed() -> void:
	get_tree().change_scene_to_file("res://tutoriel.tscn")


func _on_credit_pressed() -> void:
	get_tree().change_scene_to_file("res://credit.tscn")
