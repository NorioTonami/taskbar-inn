class_name TitleManager
extends RefCounted
# title_manager.gd — titles.json の条件判定。
# 毎秒 check() を回し、新規達成分の title def 配列を返す（トースト用）。
# 称号獲得はゲーム終了ではなくログ＋トースト表示のみ。

var titles: Array = []
var _by_id: Dictionary = {}

func _init() -> void:
	titles = DataLoader.load_array("res://data/titles.json")
	for t in titles:
		_by_id[str(t.get("id", ""))] = t

func get_def(id: String) -> Dictionary:
	return _by_id.get(id, {})

func check(state: GameState) -> Array:
	var newly: Array = []
	for t in titles:
		var id: String = str(t.get("id", ""))
		if state.titles.has(id):
			continue
		if CondEval.eval_all(state, t.get("conditions", [])):
			state.titles.append(id)
			state.add_log("称号を獲得しました：%s" % str(t.get("name", id)))
			newly.append(t)
	return newly
