class_name ServiceTierManager
extends RefCounted
# service_tier_manager.gd — service_tiers.json の読込とランクアップ判定（v0.3）。
# 次の階層の unlock 条件（実績ゲート）を満たすと rank_up でき、新しい
# スキル/スタッフ職/メーターが解放される（個々の解放判定は各マネージャの tier_req）。

var tiers: Array = []
var _by_rank: Dictionary = {}

func _init() -> void:
	tiers = DataLoader.load_array("res://data/service_tiers.json")
	for t in tiers:
		_by_rank[int(t.get("rank", 0))] = t

func by_rank(rank: int) -> Dictionary:
	return _by_rank.get(rank, {})

func current(state: GameState) -> Dictionary:
	return by_rank(state.service_rank)

func next_def(state: GameState) -> Dictionary:
	return by_rank(state.service_rank + 1)

func has_next(state: GameState) -> bool:
	return not next_def(state).is_empty()

func can_rank_up(state: GameState) -> bool:
	var nxt: Dictionary = next_def(state)
	if nxt.is_empty():
		return false
	return CondEval.eval_all(state, nxt.get("unlock", []))

func rank_up(state: GameState) -> Dictionary:
	if not can_rank_up(state):
		return {}
	var nxt: Dictionary = next_def(state)
	state.service_rank = int(nxt.get("rank", state.service_rank + 1))
	state.add_log("宿が「%s」にランクアップしました！" % str(nxt.get("name", "")))
	return nxt

# UI 用：次階層の未達条件を人間可読にする
func next_requirements_text(state: GameState) -> String:
	var nxt: Dictionary = next_def(state)
	if nxt.is_empty():
		return ""
	var parts: PackedStringArray = []
	for c in nxt.get("unlock", []):
		var field: String = str(c.get("field", ""))
		var val: Variant = c.get("value", 0)
		var cur: Variant = CondEval._resolve_field(state, field)
		parts.append("%s %s%s（現在 %s）" % [_label(field), str(c.get("op", ">=")),
			_num(val), _num(cur)])
	return " / ".join(parts)

# 表示用：整数値の float を綺麗に
static func _num(v: Variant) -> String:
	if typeof(v) == TYPE_FLOAT and v == floor(v):
		return str(int(v))
	return str(v)

const FIELD_LABEL := {
	"total_guests": "累計宿泊客",
	"food": "料理",
	"reputation": "評判",
	"comfort": "快適さ",
	"cleanliness": "清潔さ",
}

static func _label(field: String) -> String:
	return str(FIELD_LABEL.get(field, field))
