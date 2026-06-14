class_name EventManager
extends RefCounted
# event_manager.gd — events.json の読込・条件判定・発火・効果適用。
# cond は構造化（{stat,op,value} / {has_upgrade} / {special:"full_house"}）。

var events: Array = []

func _init() -> void:
	events = DataLoader.load_array("res://data/events.json")

func _cond_met(state: GameState, cond: Dictionary) -> bool:
	if cond.is_empty():
		return true
	if cond.has("has_upgrade"):
		return state.upgrade_level(str(cond["has_upgrade"])) > 0
	if cond.has("special"):
		match str(cond["special"]):
			"full_house":
				return state.guest_count >= state.guest_capacity
			_:
				return false
	if cond.has("stat"):
		var lhs: int = int(state.get(str(cond["stat"])))
		var rhs: int = int(cond.get("value", 0))
		match str(cond.get("op", ">=")):
			">=": return lhs >= rhs
			"<=": return lhs <= rhs
			">": return lhs > rhs
			"<": return lhs < rhs
			"==": return lhs == rhs
			_: return false
	return true

func _eligible(state: GameState) -> Array:
	var out: Array = []
	for e in events:
		if _cond_met(state, e.get("cond", {})):
			out.append(e)
	return out

# 条件を満たすイベントから重み抽選で1つ選び、効果を適用してログ追加。
# 発火したら event dict を、無ければ {} を返す。
func fire_one(state: GameState) -> Dictionary:
	var pool: Array = _eligible(state)
	if pool.is_empty():
		return {}
	var total: float = 0.0
	for e in pool:
		total += float(e.get("weight", 1))
	var r: float = randf() * total
	var acc: float = 0.0
	var chosen: Dictionary = pool[pool.size() - 1]
	for e in pool:
		acc += float(e.get("weight", 1))
		if r <= acc:
			chosen = e
			break
	_apply_effects(state, chosen.get("effects", {}))
	state.add_log(str(chosen.get("text", "")))
	return chosen

func _apply_effects(state: GameState, effects: Dictionary) -> void:
	if effects.has("gold"):
		state.gold = max(0, state.gold + int(effects["gold"]))
		if int(effects["gold"]) > 0:
			state.total_gold_earned += int(effects["gold"])
	if effects.has("reputation"):
		state.reputation = max(0, state.reputation + int(effects["reputation"]))
	if effects.has("guest_count"):
		state.guest_count = clampi(state.guest_count + int(effects["guest_count"]), 0, state.guest_capacity)
