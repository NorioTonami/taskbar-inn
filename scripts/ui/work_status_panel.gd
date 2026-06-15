class_name WorkStatusPanel
extends PanelContainer
# work_status_panel.gd — expanded の作業状況を1枚に統合する表示。
# 現在作業、クールダウン進捗、次に必要な手入れをまとめる。
# state のスナップショットを読むだけで、状態変更は行わない。

var _skills: SkillManager
var _state: GameState

var _title: Label
var _message: Label
var _bar: ProgressBar
var _feedback: Label

var _active: String = ""
var _t: float = 0.0
var _cd: float = 5.0
var _pulse: float = 0.0
var _feedback_t: float = 0.0

func setup(skills: SkillManager) -> void:
	_skills = skills

func _ready() -> void:
	var m := MarginContainer.new()
	for k in ["margin_left", "margin_right"]:
		m.add_theme_constant_override(k, 8)
	for k in ["margin_top", "margin_bottom"]:
		m.add_theme_constant_override(k, 6)
	add_child(m)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	m.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)

	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 13)
	_title.clip_text = true
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_title)

	_feedback = Label.new()
	_feedback.add_theme_font_size_override("font_size", 12)
	_feedback.modulate = Color(0.6, 1.0, 0.7, 0.0)
	row.add_child(_feedback)

	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.step = 0.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 10)
	box.add_child(_bar)

	_message = Label.new()
	_message.add_theme_font_size_override("font_size", 11)
	_message.modulate = Color(0.88, 0.78, 0.62)
	_message.clip_text = true
	_message.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(_message)

	set_process(true)

func update_state(state: GameState) -> void:
	_state = state
	if state.active_work != _active:
		_active = state.active_work
		_t = 0.0
	if _active != "" and _skills != null and _skills.has_skill(_active):
		_cd = maxf(0.1, _skills.get_effective_cooldown(_active, state))
	_title.text = _title_text(state)
	_message.text = _message_text(state)

func on_performed(skill_id: String, effect: int) -> void:
	_t = 0.0
	_pulse = 1.0
	if _skills == null:
		return
	var d: Dictionary = _skills.get_def(skill_id)
	var affects: String = str(d.get("affects", ""))
	if affects == "dirtiness":
		_feedback.text = "🧹 -%d" % effect
	elif affects == "food_stock" or affects == "meal_stocks":
		_feedback.text = "🍳 +%d" % effect
	elif affects == "vegetable_stock":
		_feedback.text = "🥕 +%d" % effect
	elif affects == "generic_ingredient_stock":
		_feedback.text = "📦 +%d" % effect
	else:
		_feedback.text = "+%d" % effect
	_feedback_t = 1.2

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var working: bool = _active != "" and _skills != null and _skills.has_skill(_active)
	if working:
		_t = minf(_t + delta, _cd)
		_bar.value = _t / _cd
	else:
		_bar.value = 0.0

	if _pulse > 0.0:
		_pulse = maxf(0.0, _pulse - delta * 2.5)
	_bar.modulate = Color(1, 1, 1).lerp(Color(1.4, 1.4, 1.0), _pulse)

	if _feedback_t > 0.0:
		_feedback_t -= delta
		_feedback.modulate.a = clampf(_feedback_t, 0.0, 1.0)
		if _feedback_t <= 0.0:
			_feedback.text = ""

func _title_text(state: GameState) -> String:
	if state.active_work == "" or _skills == null or not _skills.has_skill(state.active_work):
		return "💤 休憩中"
	var d: Dictionary = _skills.get_def(state.active_work)
	return "%s %s中" % [str(d.get("icon", "🛠️")), str(d.get("name", state.active_work))]

func _message_text(state: GameState) -> String:
	if _skills == null:
		return ""
	if state.active_work != "" and _skills.has_skill(state.active_work):
		return _running_message(state.active_work)
	var dcap: int = state.dirty_cap()
	if dcap > 0 and float(state.dirtiness) / float(dcap) >= 0.8:
		return "汚れが高いため清掃をおすすめします"
	if _skills.has_skill("cooking") and _skills.is_unlocked(state, "cooking") \
			and not _skills.is_work_available(state, "cooking"):
		return _skills.unavailable_reason(state, "cooking")
	if _skills.has_skill("harvesting") and _skills.is_unlocked(state, "harvesting") \
			and not _skills.is_work_available(state, "harvesting"):
		return _skills.unavailable_reason(state, "harvesting")
	return "仕事タブで作業カードを選ぶと開始します"

func _running_message(skill_id: String) -> String:
	var d: Dictionary = _skills.get_def(skill_id)
	var affects: String = str(d.get("affects", ""))
	var suffix: String = " ｜ 所要 %.1f秒%s" % [_cd, _cooldown_shortener_text(skill_id)]
	if affects == "dirtiness":
		return "汚れを下げています%s" % suffix
	if affects == "meal_stocks":
		return "野菜と食材パックを使って調理済みを作っています%s" % suffix
	if affects == "vegetable_stock":
		return "畑から野菜を収穫しています%s" % suffix
	if affects == "reputation":
		return "客へのもてなしで評判を伸ばしています%s" % suffix
	return "作業を進めています%s" % suffix

func _cooldown_shortener_text(skill_id: String) -> String:
	if _state == null:
		return ""
	var lv: int = _skills.cooldown_upgrade_level(skill_id, _state)
	if lv <= 0:
		return ""
	var label: String = _skills.cooldown_upgrade_label(skill_id)
	if label == "":
		return ""
	return " / %sLv%dで短縮" % [label, lv]
