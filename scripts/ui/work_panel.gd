class_name WorkPanel
extends VBoxContainer
# work_panel.gd — 「仕事」タブ（v0.3）。HITL の本体。
# 作業モード（手動スキル）とスキル詳細を生成。
# スタッフ雇用/一覧は StaffPanel に分離する。

signal set_work(skill_id: String)
signal buy_tool(id: String)
var _skills: SkillManager
var _staff: StaffManager
var _tools: ToolCatalog

func _ready() -> void:
	add_theme_constant_override("separation", 6)

func setup(skills: SkillManager, staff: StaffManager, tools: ToolCatalog,
		service_tiers: ServiceTierManager) -> void:
	_skills = skills
	_staff = staff
	_tools = tools
	# service_tiers は旧ランクアップ表示との互換引数。ホームタブ側で扱う。

func populate(state: GameState) -> void:
	for c in get_children():
		c.queue_free()
	if _skills == null:
		return

	_header("作業モード（カードで開始・別カードに切替で前の作業は自動停止）")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	var group := ButtonGroup.new()
	for s in _skills.unlocked_skills(state):
		var id: String = str(s.get("id", ""))
		grid.add_child(_work_card(group, str(s.get("icon", "")), str(s.get("name", id)),
			state.active_work == id, func(): set_work.emit(id),
			not _skills.is_work_available(state, id), _skills.unavailable_reason(state, id)))
	grid.add_child(_work_card(group, "☕", "休憩", state.active_work == "",
		func(): set_work.emit("")))

	for s in _skills.unlocked_skills(state):
		add_child(_skill_detail(state, s))

func _skill_detail(state: GameState, s: Dictionary) -> Control:
	var id: String = str(s.get("id", ""))
	var lv: int = max(1, state.skill_level(id))
	var eff: int = _skills.manual_effect(state, id)
	var cd: float = _skills.get_effective_cooldown(id, state)
	var shortener: String = _cooldown_shortener_text(state, id)
	var affects: String = str(s.get("affects", ""))
	var ctx: String = ""
	var sign: String = "-"
	if affects == "dirtiness":
		ctx = "汚れ %d/%d" % [int(state.dirtiness), state.dirty_cap()]
		sign = "-"
	elif affects == "food_stock" or affects == "meal_stocks":
		ctx = "調理済み %d/%d（%s）" % [int(state.total_meal_stock()), state.meal_storage_capacity(),
			_meal_summary(state)]
		sign = "+"
	elif affects == "vegetable_stock":
		ctx = "野菜 %d/%d ｜ 食材パック %d/%d" % [
			int(state.vegetable_stock), state.vegetable_cap(),
			int(state.generic_ingredient_stock), state.generic_ingredient_cap()]
		sign = "+"
	elif affects == "generic_ingredient_stock":
		ctx = "食材パック %d/%d" % [
			int(state.generic_ingredient_stock), state.generic_ingredient_cap()]
		sign = "+"
	elif affects == "reputation":
		ctx = "評判 %d" % state.reputation
		sign = "+"
	var detail := Label.new()
	detail.add_theme_font_size_override("font_size", 12)
	detail.text = "%s %s Lv%d ｜ %s ｜ 手動 1回 %s%d ｜ 所要 %.1f秒%s ｜ XP %d/%d" % [
		str(s.get("icon", "")), str(s.get("name", id)), lv, ctx, sign, eff, cd, shortener,
		int(state.skill_xp(id)), int(_skills.xp_to_next(state, id))]
	return detail

func _cooldown_shortener_text(state: GameState, id: String) -> String:
	var lv: int = _skills.cooldown_upgrade_level(id, state)
	if lv <= 0:
		return ""
	var label: String = _skills.cooldown_upgrade_label(id)
	if label == "":
		return ""
	return "（%sLv%dで短縮）" % [label, lv]

func _meal_summary(state: GameState) -> String:
	return "簡%d 家%d 定%d" % [
		int(state.meal_stock("basic")),
		int(state.meal_stock("standard")),
		int(state.meal_stock("good")),
	]

func _header(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l)

# 作業モードのカード（トグル）。ButtonGroup で単一選択になり、別カードを押すと
# 自動的に前の選択が外れる＝清掃などが自動オフになる。
func _work_card(group: ButtonGroup, icon: String, name: String, selected: bool, cb: Callable,
		disabled: bool = false, reason: String = "") -> Button:
	var card := Button.new()
	card.toggle_mode = true
	card.button_group = group
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = Vector2(94, 58)
	card.clip_text = true
	card.text = "%s\n%s" % [icon, name]
	card.add_theme_font_size_override("font_size", 13)
	card.button_pressed = selected
	card.disabled = disabled and not selected
	card.tooltip_text = reason
	card.pressed.connect(cb)
	return card
