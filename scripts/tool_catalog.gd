class_name ToolCatalog
extends RefCounted
# tool_catalog.gd — tools.json の読込。道具は2系統（player/staff）。
# 各 (skill, track) に1つの道具があり、世代(tier)を購入して bonus を上げる。
# スタッフ用は1個買えば全スタッフで共用（個数概念なし）。

var tools: Array = []
var _by_id: Dictionary = {}

func _init() -> void:
	tools = DataLoader.load_array("res://data/tools.json")
	for t in tools:
		_by_id[str(t.get("id", ""))] = t

func get_def(id: String) -> Dictionary:
	return _by_id.get(id, {})

func _tiers(id: String) -> Array:
	return get_def(id).get("tiers", [])

func current_tier(state: GameState, id: String) -> Dictionary:
	var ts: Array = _tiers(id)
	var lv: int = clampi(state.tool_level(id), 0, ts.size() - 1)
	if ts.is_empty():
		return {}
	return ts[lv]

func is_maxed(state: GameState, id: String) -> bool:
	return state.tool_level(id) >= _tiers(id).size() - 1

func next_tier(state: GameState, id: String) -> Dictionary:
	var ts: Array = _tiers(id)
	var lv: int = state.tool_level(id) + 1
	if lv >= ts.size():
		return {}
	return ts[lv]

func next_cost(state: GameState, id: String) -> int:
	var nt: Dictionary = next_tier(state, id)
	return int(nt.get("cost", 0))

func can_buy(state: GameState, id: String) -> bool:
	if is_maxed(state, id):
		return false
	return state.gold >= next_cost(state, id)

func buy(state: GameState, id: String) -> bool:
	if not can_buy(state, id):
		return false
	var cost: int = next_cost(state, id)
	var nt: Dictionary = next_tier(state, id)
	state.gold -= cost
	state.tool_levels[id] = state.tool_level(id) + 1
	state.add_log("道具「%s」を導入しました" % str(nt.get("name", id)))
	return true

# 指定スキル・系統の現在 bonus 合計（同条件の道具を合算）
func bonus_for(state: GameState, skill_id: String, track: String) -> int:
	var total: int = 0
	for t in tools:
		if str(t.get("skill", "")) == skill_id and str(t.get("track", "")) == track:
			total += int(current_tier(state, str(t.get("id", ""))).get("bonus", 0))
	return total

# UI 用：指定系統の道具定義一覧
func tools_for_track(track: String) -> Array:
	var out: Array = []
	for t in tools:
		if str(t.get("track", "")) == track:
			out.append(t)
	return out
