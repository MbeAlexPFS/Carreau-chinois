extends Area2D

var hover = false
var dragging = false
var placed = false
var hover_slot = false
var moved = false
var slot_index = -1
var old_index = -1
@export_enum("red","blue") var team : int = 0

var dfx = 0
var dfy = 0
const minimax = preload("res://scripts/minimax.gd")
var instance = minimax.new()

func _ready() -> void:
	dfx = position.x
	dfy = position.y

	if team == 0 :
		$P1.animation = "red"
	else :
		$P1.animation = "blue"

func _process(_delta: float) -> void:
	if $"..".winner != 0:
		_update_win_visual()
		return

	_update_modulate()

	# Un seul point de vérité : on est « actif » si c'est notre tour ET
	# si aucune animation n'est en cours.
	var is_my_turn: bool = ($"..".turn == team) and not $"..".animation_lock

	if is_my_turn:
		if Engine.get_meta("game_mode") == "ia" and team == 1:
			_handle_ai_turn()
		else:
			_handle_player_input()

	if dragging:
		global_position = get_global_mouse_position()
	elif hover_slot is Vector2:
		placed = true
	elif not placed:
		global_position = Vector2(dfx, dfy)

	if not hover_slot is Vector2:
		placed = false

	# CORRECTION : on ne pose QUE si c'est bien notre tour.
	if placed and not dragging and is_my_turn:
		_try_place()


# ---------------------------------------------------------
# IA
# ---------------------------------------------------------

func _handle_ai_turn() -> void:
	if not $"..".ai_move_computed:
		$"..".ai_move_computed = true
		$"..".ai_move_claimed = false
		$"..".ai_move_stuck_timer = 0
		var difficulty
		if Engine.get_meta("game_diff") == "easy":
			difficulty = instance.Difficulty.EASY
		elif Engine.get_meta("game_diff") == "medium":
			difficulty = instance.Difficulty.MEDIUM
		else:
			difficulty = instance.Difficulty.HARD
		$"..".ai_move = instance.get_best_move($"..".slot_state, $"..".available(), 2, difficulty)
		if $"..".ai_move.is_empty():
			push_warning("IA (team 1) bloquée : get_best_move n'a renvoyé aucun coup.")
			# CORRECTION : ne pas rester coincé sur ai_move_computed == true
			$"..".ai_move_computed = false
			return

	var move: Dictionary = $"..".ai_move
	if move.is_empty() or $"..".ai_move_claimed:
		return

	$"..".ai_move_stuck_timer += 1
	if $"..".ai_move_stuck_timer > 30:
		push_warning("IA (team 1) : coup %s non réclamé, recalcul forcé." % str(move))
		$"..".ai_move_computed = false
		return

	if move.type == "place":
		# On vérifie aussi l'état partagé : si la case n'est plus vide,
		# quelqu'un s'est désynchronisé → on force un recalcul.
		if not placed and old_index == -1:
			if $"..".slot_state[move.to] != 0:
				$"..".ai_move_computed = false
				return
			$"..".ai_move_claimed = true
			hover_slot = $"..".slot_positions[move.to]
			dragging = false

	elif move.type == "move":
		if move.from == move.to:
			$"..".ai_move_computed = false
			return
		# CORRECTION : on ne touche PAS à slot_state ici.
		# C'est _try_place qui le fera, et uniquement en cas de succès.
		if old_index == move.from \
		and $"..".slot_state[move.from] == team + 1 \
		and $"..".slot_state[move.to] == 0:
			$"..".ai_move_claimed = true
			hover_slot = $"..".slot_positions[move.to]
			dragging = false


# ---------------------------------------------------------
# Joueur humain
# ---------------------------------------------------------

func _handle_player_input() -> void:
	if hover and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and $"..".select_count == 0:
		dragging = true
		z_index = 100
		$"..".select_count = 1
		# CORRECTION : on NE vide PAS slot_state ici.
		# Le vidage se fera dans _try_place, une fois le coup validé.
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		dragging = false
		z_index = 1
		$"..".select_count = 0


# ---------------------------------------------------------
# Pose / déplacement effectif
# ---------------------------------------------------------

func _try_place() -> void:
	var target_index: int = $"..".slot_positions.find(hover_slot)

	# Drop sur sa propre case : annulation propre.
	if target_index == old_index:
		global_position = Vector2(dfx, dfy)
		hover_slot = false
		placed = false
		_release_ai_claim()
		return

	var target_empty: bool = target_index >= 0 and $"..".slot_state[target_index] == 0
	# CORRECTION : on utilise la vraie règle d'adjacence de l'étoile,
	# au lieu d'un seuil en pixels.
	var adjacent_ok: bool = old_index == -1 or (target_index in instance.ADJACENCY[old_index])

	if target_empty and adjacent_ok:
		# On libère l'ancienne case SEULEMENT maintenant qu'on est sûr.
		if old_index != -1:
			$"..".slot_state[old_index] = 0
		$"..".slot_state[target_index] = team + 1
		$"..".played = true

		$"..".animation_lock = true
		var tw = create_tween()
		tw.tween_property(self, "global_position", hover_slot, 0.25).set_trans(Tween.TRANS_SINE)
		tw.finished.connect(func(): $"..".animation_lock = false)

		dfx = hover_slot.x
		dfy = hover_slot.y
		old_index = target_index
		hover_slot = false
		placed = false

		# CORRECTION : alternance sûre, même si turn n'est ni 0 ni 1.
		$"..".turn = 1 - $"..".turn
		$"..".played = false
		$"..".ai_move_computed = false
		$"..".ai_move_claimed = false
		$"..".ai_move = {}

		var check = $"..".check_win()
		if check != 0:
			$"..".winner = check
	else:
		if Engine.get_meta("game_mode") == "ia" and team == 1:
			push_warning("Coup IA rejeté -> to=%s empty=%s adj=%s old=%s board=%s" % [
				target_index, target_empty, adjacent_ok, old_index, str($"..".slot_state)
			])
		# CORRECTION : on restaure le pion à sa position d'origine.
		# slot_state[old_index] n'a pas été vidé (on a déplacé le vidage
		# dans la branche « succès »), donc rien à restaurer côté modèle.
		global_position = Vector2(dfx, dfy)
		hover_slot = false
		placed = false
		_release_ai_claim()


func _release_ai_claim() -> void:
	if Engine.get_meta("game_mode") == "ia" and team == 1:
		$"..".ai_move_claimed = false
		$"..".ai_move_computed = false


# ---------------------------------------------------------
# Visuel
# ---------------------------------------------------------

func _update_modulate() -> void:
	if $"..".turn == 0 :
		modulate = Color(1,1,1,1) if team == 0 else Color(1,1,1,0.5)
	else :
		modulate = Color(1,1,1,1) if team == 1 else Color(1,1,1,0.5)

func _update_win_visual() -> void:
	modulate = Color(1,1,1,1)
	if $"..".winner == team + 1 :
		scale = Vector2(0.12,0.12)
		modulate = Color(1.5,1.5,1.5,1)


func _on_mouse_entered() -> void:
	hover = true

func _on_mouse_exited() -> void:
	hover = false
