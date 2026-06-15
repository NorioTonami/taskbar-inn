class_name CondEval
extends RefCounted
# cond_eval.gd — badges/titles の conditions 配列を評価する共有ヘルパー。
# field は state フィールド名、または "guest_type_counts.<id>"。
# "skill.<id>" / "tool.<id>" / "upgrade.<id>" / "action.<id>" も解決する。
# value が文字列のとき: op が比較演算なら別フィールド名として解決、
#                       op が "==" なら文字列リテラルとして比較。

static func _resolve_field(state: GameState, field: String) -> Variant:
	if field.contains("."):
		var parts: PackedStringArray = field.split(".")
		match parts[0]:
			"guest_type_counts":
				return state.get_count(parts[1])
			"skill":
				return state.skill_level(parts[1])
			"tool":
				return state.tool_level(parts[1])
			"upgrade":
				return state.upgrade_level(parts[1])
			"action":
				return state.action_count(parts[1])
			_:
				return 0
	match field:
		"staff_count":
			return state.staff_count()
		_:
			return state.get(field)

static func eval_one(state: GameState, cond: Dictionary) -> bool:
	var field: String = str(cond.get("field", ""))
	var op: String = str(cond.get("op", ">="))
	var lhs: Variant = _resolve_field(state, field)
	var raw: Variant = cond.get("value", 0)

	if op == "==":
		return str(lhs) == str(raw)

	var rhs: int
	if typeof(raw) == TYPE_STRING:
		rhs = int(_resolve_field(state, str(raw)))
	else:
		rhs = int(raw)
	var l: int = int(lhs)
	match op:
		">=": return l >= rhs
		"<=": return l <= rhs
		">": return l > rhs
		"<": return l < rhs
		_: return false

static func eval_all(state: GameState, conditions: Array) -> bool:
	for c in conditions:
		if not eval_one(state, c):
			return false
	return true
