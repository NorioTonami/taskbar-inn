class_name GuestManager
extends RefCounted
# guest_manager.gd — guest_types.json の読込と重み付き抽選（v0.3）。
# requires(ステ条件) を満たす客から weight に比例して1つ選ぶ。
# 営業モード・ニーズによる重み補正は階層B以降で拡張する。

var guest_types: Array = []
var _by_id: Dictionary = {}

func _init() -> void:
	guest_types = DataLoader.load_array("res://data/guest_types.json")
	for g in guest_types:
		_by_id[str(g.get("id", ""))] = g

func get_type(id: String) -> Dictionary:
	return _by_id.get(id, {})

func _meets_requires(state: GameState, req: Dictionary) -> bool:
	for k in req.keys():
		if int(state.get(k)) < int(req[k]):
			return false
	return true

func pick(state: GameState) -> Dictionary:
	var candidates: Array = []
	var weights: Array = []
	var total: float = 0.0
	for g in guest_types:
		if not _meets_requires(state, g.get("requires", {})):
			continue
		var w: float = float(g.get("weight", 1))
		if w <= 0.0:
			continue
		candidates.append(g)
		weights.append(w)
		total += w
	if candidates.is_empty():
		return {}
	var r: float = randf() * total
	var acc: float = 0.0
	for i in candidates.size():
		acc += weights[i]
		if r <= acc:
			return candidates[i]
	return candidates[candidates.size() - 1]

func random_line(type_id: String) -> String:
	var g: Dictionary = get_type(type_id)
	var lines: Array = g.get("lines", [])
	if lines.is_empty():
		return ""
	return str(lines[randi() % lines.size()])
