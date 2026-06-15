class_name UpgradeCatalog
extends RefCounted
# upgrade_catalog.gd — upgrades.json の読込・購入・cost_growth・効果適用（v0.3）。
# category でUI分類。unlock(条件配列) を満たすまで購入不可（特殊設備の実績ゲート）。
# stat 系 effects は game_state へ直接加算する。

const STAT_KEYS := [
	"comfort", "food", "cleanliness", "guest_capacity", "security", "rooms",
	"placement_slots",
]

var upgrades: Array = []
var _by_id: Dictionary = {}

func _init() -> void:
	upgrades = DataLoader.load_array("res://data/upgrades.json")
	for u in upgrades:
		_by_id[str(u.get("id", ""))] = u

func get_def(id: String) -> Dictionary:
	return _by_id.get(id, {})

func category_of(id: String) -> String:
	return str(get_def(id).get("category", "base"))

# unlock 条件（無ければ常に解放）
func is_unlocked(state: GameState, id: String) -> bool:
	var d: Dictionary = get_def(id)
	if not d.has("unlock"):
		return true
	return CondEval.eval_all(state, d.get("unlock", []))

func cost_for(state: GameState, id: String) -> int:
	var d: Dictionary = get_def(id)
	if d.is_empty():
		return 0
	var base: float = float(d.get("cost", 0))
	var growth: float = float(d.get("cost_growth", 1.5))
	var lv: int = state.upgrade_level(id)
	return int(round(base * pow(growth, lv)))

func is_maxed(state: GameState, id: String) -> bool:
	var d: Dictionary = get_def(id)
	if d.is_empty():
		return true
	if not d.has("max_level"):
		return false
	return state.upgrade_level(id) >= int(d["max_level"])

func can_buy(state: GameState, id: String) -> bool:
	if is_maxed(state, id):
		return false
	if not is_unlocked(state, id):
		return false
	return state.gold >= cost_for(state, id)

func buy(state: GameState, id: String) -> bool:
	if not can_buy(state, id):
		return false
	var d: Dictionary = get_def(id)
	var cost: int = cost_for(state, id)
	state.gold -= cost
	state.upgrade_levels[id] = state.upgrade_level(id) + 1
	if not state.unlocked_upgrades.has(id):
		state.unlocked_upgrades.append(id)
	var effects: Dictionary = d.get("effects", {})
	for k in effects.keys():
		if STAT_KEYS.has(k):
			state.set(k, int(state.get(k)) + int(effects[k]))
	_recalc_level(state)
	state.add_log("「%s」を導入しました（Lv%d）" % [str(d.get("name", id)), state.upgrade_level(id)])
	return true

func _recalc_level(state: GameState) -> void:
	var total: int = 0
	for v in state.upgrade_levels.values():
		total += int(v)
	state.level = 1 + int(total / 3)
