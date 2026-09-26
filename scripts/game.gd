extends Node2D

var select_count = 0
var turn = 0
var played = false
var slot_positions = []
var slot_state = []
var drag = Vector2(0,0)
var winner = 0
var ai_move_computed = false
var ai_move_claimed = false
var ai_move = {}
var ai_move_stuck_timer = 0
var animation_lock = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for slot in $board.get_children() :
		slot_positions.append(slot.global_position)
		slot_state.append(0)
	if Engine.get_meta("turn") :
		turn = Engine.get_meta("turn")
		
	if Engine.get_meta("game_mode") == "1v1" :
		$desc.text = "Joueur VS Joeur"
	else : 
		if Engine.get_meta("game_diff") == "easy" :
			$desc.text = "Facile"
		elif Engine.get_meta("game_diff") == "medium" :
			$desc.text = "Normal"
		else :
			$desc.text = "Difficile"
			
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if winner == 0 :
		$playing.text = str("Joueur ",turn + 1)
	else :
		$playing.text = str("Joueur ",winner," gagne !")
		$playing.label_settings.font_size = 50
		$rejouer.visible = true
		
	
# board.gd
const minimax = preload("res://scripts/minimax.gd")
var game = minimax.new()

func check_win() -> int:
	return game.check_winner(slot_state)
	
func available() -> Dictionary:
	var p1 = 3 - slot_state.count(1)
	var p2 = 3 - slot_state.count(2)
	return {1: p1, 2: p2}

func _on_rejouer_pressed() -> void:
	if $rejouer.visible :
		get_tree().reload_current_scene()

func _on_retour_pressed() -> void:
	get_tree().change_scene_to_file("res://game option.tscn")
