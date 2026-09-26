enum Difficulty { EASY, MEDIUM, HARD }

# ---------------------------------------------------------
# Paramètres du jeu
# ---------------------------------------------------------

# Profondeur de recherche selon la difficulté
const DEPTH_BY_DIFFICULTY = {
	Difficulty.MEDIUM: 3,
	Difficulty.HARD: 5
}

var BOARD_SIZE := 5          # 3 ou 5
var WIN_LENGTH := 3          # 3 ou 4 (doit être <= BOARD_SIZE)
var PIECES_PER_PLAYER := 3

const TERMINAL_SCORE := 1000000.0

# ---------------------------------------------------------
# Pattern des diagonales réellement dessinées
# ---------------------------------------------------------
# Taille : (BOARD_SIZE - 1) x (BOARD_SIZE - 1)
# Chaque cellule 2x2 de points (r, c) décrit quelles diagonales existent :
#   0 = aucune diagonale
#   1 = "\"  (haut-gauche -> bas-droite)
#   2 = "/"  (haut-droit  -> bas-gauche)
#   3 = les deux (X)
#
# Lecture du schéma 5x5 :
#   +--+--+--+--+
#   |\ |/ |\ |/ |
#   +--+--+--+--+
#   |/ |\ |/ |\ |
#   +--+--+--+--+
#   |\ |/ |\ |/ |
#   +--+--+--+--+
#   |/ |\ |/ |\ |
#   +--+--+--+--+
var DIAG_PATTERN := [
	[1, 2, 1, 2],
	[2, 1, 2, 1],
	[1, 2, 1, 2],
	[2, 1, 2, 1],
]

# Pour un 3x3 (étoile ou grille simple), mets :
# const DIAG_PATTERN := [
#     [3, 3],
#     [3, 3],
# ]

# ---------------------------------------------------------
# Tables générées au démarrage
# ---------------------------------------------------------
var ADJACENCY: Array = []
var WIN_LINES: Array = []


func _init() -> void:
	if Engine.get_meta("lvl") == 1 :
		BOARD_SIZE = 3
		DIAG_PATTERN = [
	 		[1, 2],
	 		[2, 1],
 		]
	else :
		BOARD_SIZE = 5
		
	if Engine.get_meta("nbpion") == 1 :
		WIN_LENGTH = 3
	else :
		WIN_LENGTH = 4
	
	PIECES_PER_PLAYER = WIN_LENGTH
		
	_build_adjacency()
	_build_win_lines()


# ---------------------------------------------------------
# Construction de l'adjacence (à partir des arêtes réellement tracées)
# ---------------------------------------------------------

func _build_adjacency() -> void:
	ADJACENCY.clear()
	var n := BOARD_SIZE

	# On part d'une liste vide pour chaque point
	for i in range(n * n):
		ADJACENCY.append([])

	# --- Arêtes orthogonales : toujours présentes ---
	for r in range(n):
		for c in range(n):
			var i := r * n + c
			if r + 1 < n:
				_add_edge(i, (r + 1) * n + c)
			if c + 1 < n:
				_add_edge(i, r * n + (c + 1))

	# --- Diagonales : uniquement celles du pattern ---
	assert(DIAG_PATTERN.size() == n - 1,
		"DIAG_PATTERN doit avoir BOARD_SIZE-1 lignes (ici %d)" % (n - 1))

	for r in range(n - 1):
		assert(DIAG_PATTERN[r].size() == n - 1,
			"DIAG_PATTERN[%d] doit avoir BOARD_SIZE-1 entrées" % r)
		for c in range(n - 1):
			var pat: int = DIAG_PATTERN[r][c]
			if pat == 0:
				continue
			var tl := r * n + c
			var tr := r * n + (c + 1)
			var bl := (r + 1) * n + c
			var br := (r + 1) * n + (c + 1)
			if pat & 1:  # "\" : haut-gauche <-> bas-droite
				_add_edge(tl, br)
			if pat & 2:  # "/" : haut-droit  <-> bas-gauche
				_add_edge(tr, bl)


func _add_edge(a: int, b: int) -> void:
	if not (b in ADJACENCY[a]):
		ADJACENCY[a].append(b)
	if not (a in ADJACENCY[b]):
		ADJACENCY[b].append(a)


# ---------------------------------------------------------
# Construction des lignes gagnantes (parcours du graphe d'adjacence)
# ---------------------------------------------------------

func _build_win_lines() -> void:
	WIN_LINES.clear()
	var n := BOARD_SIZE

	# On ne considère que les 4 directions « droites » (pas de zigzag)
	var dirs := [[0, 1], [1, 0], [1, 1], [1, -1]]

	for start in range(n * n):
		var sr := start / n
		var sc := start % n
		for d in dirs:
			var line: Array = [start]
			var cr := sr
			var cc := sc
			var ok := true
			for k in range(1, WIN_LENGTH):
				var nr: int = cr + d[0]
				var nc: int = cc + d[1]
				if nr < 0 or nr >= n or nc < 0 or nc >= n:
					ok = false
					break
				var cur_idx: int = cr * n + cc
				var next_idx: int = nr * n + nc
				# Le segment (cur_idx -> next_idx) doit exister dans le graphe
				if not (next_idx in ADJACENCY[cur_idx]):
					ok = false
					break
				line.append(next_idx)
				cr = nr
				cc = nc
			if ok:
				WIN_LINES.append(line)

	print("minimax: ADJACENCY=%d WIN_LINES=%d (BOARD_SIZE=%d, WIN_LENGTH=%d)" % [
		ADJACENCY.size(), WIN_LINES.size(), BOARD_SIZE, WIN_LENGTH
	])


# ---------------------------------------------------------
# Aides de création d'état (facultatif mais pratique)
# ---------------------------------------------------------

func create_board() -> Array:
	var b: Array = []
	b.resize(BOARD_SIZE * BOARD_SIZE)
	b.fill(0)
	return b


func create_pieces_available() -> Dictionary:
	return {1: PIECES_PER_PLAYER, 2: PIECES_PER_PLAYER}


# ---------------------------------------------------------
# API principale
# ---------------------------------------------------------

func get_best_move(board: Array, pieces_available: Dictionary, ai_player: int, difficulty: Difficulty = Difficulty.HARD) -> Dictionary:
	var moves := get_valid_moves(board, ai_player, pieces_available)
	if moves.is_empty():
		return {}

	match difficulty:
		Difficulty.EASY:
			return moves[randi() % moves.size()]

		Difficulty.MEDIUM:
			if randf() < 0.5:
				return moves[randi() % moves.size()]
			return get_optimal_move(board, pieces_available, ai_player, DEPTH_BY_DIFFICULTY[Difficulty.MEDIUM])

		Difficulty.HARD:
			return get_optimal_move(board, pieces_available, ai_player, DEPTH_BY_DIFFICULTY[Difficulty.HARD])

	return moves[0]


func get_optimal_move(board: Array, pieces_available: Dictionary, ai_player: int, max_depth: int) -> Dictionary:
	var opponent := 3 - ai_player
	var moves := get_valid_moves(board, ai_player, pieces_available)

	var best_score := -INF
	var best_move := {}

	for move in moves:
		apply_move(board, pieces_available, move, ai_player)
		var score = minimax(board, pieces_available, 1, max_depth, false, ai_player, opponent, -INF, INF)
		undo_move(board, pieces_available, move, ai_player)

		if score > best_score:
			best_score = score
			best_move = move

	return best_move


# ---------------------------------------------------------
# Minimax avec élagage alpha-bêta et profondeur limitée
# ---------------------------------------------------------

func minimax(board: Array, pieces_available: Dictionary, depth: int, max_depth: int, is_maximizing: bool, ai_player: int, opponent: int, alpha: float, beta: float) -> float:
	var winner = check_winner(board)
	if winner == ai_player:
		return TERMINAL_SCORE - depth
	elif winner == opponent:
		return depth - TERMINAL_SCORE

	if depth >= max_depth:
		return evaluate_heuristic(board, ai_player, opponent)

	var current_player = ai_player if is_maximizing else opponent
	var moves := get_valid_moves(board, current_player, pieces_available)

	if moves.is_empty():
		return (depth - TERMINAL_SCORE) if is_maximizing else (TERMINAL_SCORE - depth)

	if is_maximizing:
		var best := -INF
		for move in moves:
			apply_move(board, pieces_available, move, current_player)
			var score = minimax(board, pieces_available, depth + 1, max_depth, false, ai_player, opponent, alpha, beta)
			undo_move(board, pieces_available, move, current_player)
			best = max(best, score)
			alpha = max(alpha, best)
			if beta <= alpha:
				break
		return best
	else:
		var best := INF
		for move in moves:
			apply_move(board, pieces_available, move, current_player)
			var score = minimax(board, pieces_available, depth + 1, max_depth, true, ai_player, opponent, alpha, beta)
			undo_move(board, pieces_available, move, current_player)
			best = min(best, score)
			beta = min(beta, best)
			if beta <= alpha:
				break
		return best


# ---------------------------------------------------------
# Génération / application des coups
# ---------------------------------------------------------

func get_valid_moves(board: Array, player: int, pieces_available: Dictionary) -> Array:
	var moves: Array = []
	var total := BOARD_SIZE * BOARD_SIZE

	# Poser un pion
	if pieces_available[player] > 0:
		for i in range(total):
			if board[i] == 0:
				moves.append({"type": "place", "to": i})

	# Déplacer un pion (uniquement vers une arête réellement présente)
	for i in range(total):
		if board[i] == player:
			for adj in ADJACENCY[i]:
				if board[adj] == 0:
					moves.append({"type": "move", "from": i, "to": adj})

	return moves


func apply_move(board: Array, pieces_available: Dictionary, move: Dictionary, player: int) -> void:
	if move.type == "place":
		board[move.to] = player
		pieces_available[player] -= 1
	else:
		board[move.from] = 0
		board[move.to] = player


func undo_move(board: Array, pieces_available: Dictionary, move: Dictionary, player: int) -> void:
	if move.type == "place":
		board[move.to] = 0
		pieces_available[player] += 1
	else:
		board[move.to] = 0
		board[move.from] = player


# ---------------------------------------------------------
# Heuristique
# ---------------------------------------------------------

func evaluate_heuristic(board: Array, ai_player: int, opponent: int) -> float:
	var score := 0.0
	for line in WIN_LINES:
		var ai_count := 0
		var opp_count := 0
		for idx in line:
			if board[idx] == ai_player:
				ai_count += 1
			elif board[idx] == opponent:
				opp_count += 1

		if ai_count > 0 and opp_count == 0:
			score += pow(10, ai_count)
		elif opp_count > 0 and ai_count == 0:
			score -= pow(10, opp_count)

	return score


func check_winner(board: Array) -> int:
	for line in WIN_LINES:
		var first: int = board[line[0]]
		if first == 0:
			continue
		var ok := true
		for k in range(1, line.size()):
			if board[line[k]] != first:
				ok = false
				break
		if ok:
			return first
	return 0
