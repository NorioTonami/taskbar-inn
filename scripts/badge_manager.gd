class_name BadgeManager
extends RefCounted
# badge_manager.gd — badges.json の条件判定。
# 毎秒 check() を回し、新規達成分の badge def 配列を返す（トースト用）。

var badges: Array = []
var _by_id: Dictionary = {}

func _init() -> void:
	badges = DataLoader.load_array("res://data/badges.json")
	for b in badges:
		_by_id[str(b.get("id", ""))] = b

func get_def(id: String) -> Dictionary:
	return _by_id.get(id, {})

# 未獲得で条件を満たしたバッジを付与し、新規獲得分の def を返す。
func check(state: GameState) -> Array:
	var newly: Array = []
	for b in badges:
		var id: String = str(b.get("id", ""))
		if state.badges.has(id):
			continue
		if CondEval.eval_all(state, b.get("conditions", [])):
			state.badges.append(id)
			state.add_log("バッジ獲得：%s" % str(b.get("name", id)))
			newly.append(b)
	return newly
