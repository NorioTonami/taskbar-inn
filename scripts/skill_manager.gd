class_name SkillManager
extends RefCounted
# skill_manager.gd — skills.json の読込とプレイヤーのアクティブ作業処理。
# 選択中スキルをクールダウンごとに1回実行し、対象メーターへ効果＋XPを与える。
# Lv が上がると1回あたりの効果が増える（Melvor 式の訓練）。

var skills: Array = []
var _by_id: Dictionary = {}
var _tools: ToolCatalog

func _init(tools: ToolCatalog) -> void:
	_tools = tools
	skills = DataLoader.load_array("res://data/skills.json")
	for s in skills:
		_by_id[str(s.get("id", ""))] = s

func get_def(id: String) -> Dictionary:
	return _by_id.get(id, {})

func has_skill(id: String) -> bool:
	return _by_id.has(id)

func tier_req(id: String) -> int:
	return int(get_def(id).get("tier_req", 1))

# サービス階層が解放条件を満たしているか
func is_unlocked(state: GameState, id: String) -> bool:
	return state.service_rank >= tier_req(id)

# 現在解放済みのスキル定義一覧
func unlocked_skills(state: GameState) -> Array:
	var out: Array = []
	for s in skills:
		if is_unlocked(state, str(s.get("id", ""))):
			out.append(s)
	return out

func display_name(id: String) -> String:
	return str(get_def(id).get("name", id))

func icon(id: String) -> String:
	return str(get_def(id).get("icon", ""))

func cooldown(id: String) -> float:
	return float(get_def(id).get("cooldown_sec", 5))

# 手動1回あたりの効果量 = base + lv*per + プレイヤー用道具bonus
func manual_effect(state: GameState, id: String) -> int:
	var d: Dictionary = get_def(id)
	if d.is_empty():
		return 0
	var base: int = int(d.get("base_effect", 0))
	var per: int = int(d.get("effect_per_level", 0))
	var lv: int = max(1, state.skill_level(id))
	var tool_bonus: int = _tools.bonus_for(state, id, "player")
	return base + lv * per + tool_bonus

func xp_to_next(state: GameState, id: String) -> float:
	var d: Dictionary = get_def(id)
	var base: float = float(d.get("xp_base", 10))
	var growth: float = float(d.get("xp_growth", 1.35))
	var lv: int = max(1, state.skill_level(id))
	return round(base * pow(growth, lv))

func add_xp(state: GameState, id: String, amount: float) -> int:
	state._ensure_skill(id)
	var levels_gained: int = 0
	var cur: Dictionary = state.skills[id]
	cur["xp"] = float(cur.get("xp", 0.0)) + amount
	while float(cur["xp"]) >= xp_to_next(state, id):
		cur["xp"] = float(cur["xp"]) - xp_to_next(state, id)
		cur["level"] = int(cur.get("level", 1)) + 1
		levels_gained += 1
	state.skills[id] = cur
	return levels_gained

# 1回分のアクティブ作業を実行。効果を対象へ適用しXP加算。
# 戻り値: {"effect":int, "levels":int, "leveled":bool}
func perform(state: GameState, id: String) -> Dictionary:
	var d: Dictionary = get_def(id)
	if d.is_empty():
		return {"effect": 0, "levels": 0, "leveled": false}
	var eff: int = manual_effect(state, id)
	_apply_effect(state, d, eff)
	var lv: int = add_xp(state, id, float(d.get("xp_per_action", 1)))
	return {"effect": eff, "levels": lv, "leveled": lv > 0}

func _apply_effect(state: GameState, d: Dictionary, eff: int) -> void:
	apply_effect_for(state, str(d.get("id", "")), eff)

# スキル種別に応じて効果を適用（手動・スタッフ自動の両方から呼ばれる共通処理）。
# meter は減らし、stock は上限まで増やす。
func apply_effect_for(state: GameState, skill_id: String, amount: int) -> void:
	var d: Dictionary = get_def(skill_id)
	if d.is_empty():
		return
	var target: String = str(d.get("target", ""))
	var affects: String = str(d.get("affects", ""))
	if target == "meter" and affects == "dirtiness":
		state.dirtiness = maxf(0.0, state.dirtiness - float(amount))
	elif target == "stock" and affects == "food_stock":
		state.food_stock = minf(float(state.food_cap()), state.food_stock + float(amount))
