class_name StaffManager
extends RefCounted
# staff_manager.gd — staff_roles.json の読込・雇用・自動作業。
# 雇用は評判ゲート（reputation_req＋帯で初期Lv）。配置枠(placement_slots)内で稼働。
# 雇用直後は自動効率 < 手動。育成(XP→Lv)で手動を追い越す。

const NAME_POOL: Array = ["ハナ", "タケ", "ミナ", "ゴロウ", "サキ", "クマ", "リン", "トラ", "ユキ", "ソラ"]

var roles: Array = []
var _by_id: Dictionary = {}
var _tools: ToolCatalog
var _skills: SkillManager
var _timers: Array = []        # staff index -> 経過秒（transient）

func _init(tools: ToolCatalog, skills: SkillManager) -> void:
	_tools = tools
	_skills = skills
	roles = DataLoader.load_array("res://data/staff_roles.json")
	for r in roles:
		_by_id[str(r.get("role_id", ""))] = r

func get_role(role_id: String) -> Dictionary:
	return _by_id.get(role_id, {})

func tier_req(role_id: String) -> int:
	return int(get_role(role_id).get("tier_req", 1))

func is_unlocked(state: GameState, role_id: String) -> bool:
	var r: Dictionary = get_role(role_id)
	if r.is_empty():
		return false
	if state.service_rank < int(r.get("tier_req", 1)):
		return false
	if r.has("unlock") and not CondEval.eval_all(state, r.get("unlock", [])):
		return false
	return true

# 現在解放済み（雇用可能な階層に達した）職の定義一覧
func unlocked_roles(state: GameState) -> Array:
	var out: Array = []
	for r in roles:
		if is_unlocked(state, str(r.get("role_id", ""))):
			out.append(r)
	return out

func count_of_role(state: GameState, role_id: String) -> int:
	var n: int = 0
	for s in state.staff:
		if str(s.get("role_id", "")) == role_id:
			n += 1
	return n

func initial_level(state: GameState, _role_id: String) -> int:
	return clampi(1 + int(state.reputation / 20), 1, 8)

func hire_cost(state: GameState, role_id: String) -> int:
	var r: Dictionary = get_role(role_id)
	if r.is_empty():
		return 0
	var base: float = float(r.get("hire_cost", 50))
	var growth: float = float(r.get("cost_growth", 1.6))
	return int(round(base * pow(growth, count_of_role(state, role_id))))

func has_free_slot(state: GameState) -> bool:
	return state.assigned_staff_count() < state.placement_slots

func can_hire(state: GameState, role_id: String) -> bool:
	var r: Dictionary = get_role(role_id)
	if r.is_empty():
		return false
	if not is_unlocked(state, role_id):
		return false
	if state.reputation < int(r.get("reputation_req", 0)):
		return false
	if not has_free_slot(state):
		return false
	return state.gold >= hire_cost(state, role_id)

func hire(state: GameState, role_id: String) -> bool:
	if not can_hire(state, role_id):
		return false
	var cost: int = hire_cost(state, role_id)
	state.gold -= cost
	var nm: String = NAME_POOL[randi() % NAME_POOL.size()]
	state.staff.append({
		"role_id": role_id,
		"name": nm,
		"level": initial_level(state, role_id),
		"xp": 0.0,
		"assigned": true,
	})
	state.add_log("%s を雇いました（%s Lv%d）" % [nm, str(get_role(role_id).get("name", role_id)),
		int(state.staff[state.staff.size() - 1]["level"])])
	return true

func cooldown(role_id: String) -> float:
	return float(get_role(role_id).get("cooldown_sec", 6))

func auto_effect(state: GameState, s: Dictionary) -> int:
	var r: Dictionary = get_role(str(s.get("role_id", "")))
	if r.is_empty():
		return 0
	var base: int = int(r.get("base_auto_effect", 0))
	var per: int = int(r.get("effect_per_level", 0))
	var lv: int = max(1, int(s.get("level", 1)))
	var tool_bonus: int = _tools.bonus_for(state, str(r.get("skill", "")), "staff")
	return base + lv * per + tool_bonus

func _xp_to_next(s: Dictionary) -> float:
	var r: Dictionary = get_role(str(s.get("role_id", "")))
	var base: float = float(r.get("xp_base", 10))
	var growth: float = float(r.get("xp_growth", 1.4))
	var lv: int = max(1, int(s.get("level", 1)))
	return round(base * pow(growth, lv))

func _add_staff_xp(s: Dictionary, amount: float) -> void:
	var r: Dictionary = get_role(str(s.get("role_id", "")))
	s["xp"] = float(s.get("xp", 0.0)) + amount
	while float(s["xp"]) >= _xp_to_next(s):
		s["xp"] = float(s["xp"]) - _xp_to_next(s)
		s["level"] = int(s.get("level", 1)) + 1

func _perform(state: GameState, s: Dictionary) -> void:
	var r: Dictionary = get_role(str(s.get("role_id", "")))
	var skill: String = str(r.get("skill", ""))
	var eff: int = auto_effect(state, s)
	_skills.apply_effect_for(state, skill, eff)
	_add_staff_xp(s, float(r.get("xp_per_action", 1)))

# 配置中スタッフの自動作業を dt 秒ぶん進める。
func tick(state: GameState, dt: float) -> void:
	if _timers.size() != state.staff.size():
		_timers.resize(state.staff.size())
		for i in _timers.size():
			if _timers[i] == null:
				_timers[i] = 0.0
	for i in state.staff.size():
		var s: Dictionary = state.staff[i]
		if not bool(s.get("assigned", false)):
			continue
		var cd: float = cooldown(str(s.get("role_id", "")))
		_timers[i] = float(_timers[i]) + dt
		while float(_timers[i]) >= cd:
			_timers[i] = float(_timers[i]) - cd
			_perform(state, s)

# オフライン用：配置中スタッフの、指定スキルの毎秒あたり自動処理量合計
func auto_per_sec_for(state: GameState, skill_id: String) -> float:
	var total: float = 0.0
	for s in state.staff:
		if not bool(s.get("assigned", false)):
			continue
		var r: Dictionary = get_role(str(s.get("role_id", "")))
		if str(r.get("skill", "")) != skill_id:
			continue
		var cd: float = cooldown(str(s.get("role_id", "")))
		if cd > 0.0:
			total += float(auto_effect(state, s)) / cd
	return total
