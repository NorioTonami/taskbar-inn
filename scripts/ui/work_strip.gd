class_name WorkStrip
extends PanelContainer
# work_strip.gd — タブ下に常駐する作業アニメ＋進捗バー（v0.3）。
# 選択中スキルのクールダウンを 0→100% で可視化し、一周ごとに対象メーターが動く。
# 進捗は UI 側 delta で滑らかに進め、実際の perform() で 0 にリセットして同期する。
# state のスナップショットを読むだけ（状態変更はしない）。

var _skills: SkillManager
var _state: GameState

var _icon: Label
var _name: Label
var _bar: ProgressBar
var _feedback: Label

var _t: float = 0.0                 # UI 側の経過（秒）
var _cd: float = 5.0
var _active: String = ""
var _wiggle: float = 0.0            # アイコン揺れ位相
var _pulse: float = 0.0            # 完了時バー発光
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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	m.add_child(row)

	_icon = Label.new()
	_icon.add_theme_font_size_override("font_size", 26)
	_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon.custom_minimum_size = Vector2(34, 0)
	_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_icon)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 3)
	row.add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	col.add_child(top)
	_name = Label.new()
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.add_theme_font_size_override("font_size", 12)
	_name.clip_text = true
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(_name)
	_feedback = Label.new()
	_feedback.add_theme_font_size_override("font_size", 12)
	_feedback.modulate = Color(0.6, 1.0, 0.7, 0.0)
	top.add_child(_feedback)

	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.step = 0.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 12)
	col.add_child(_bar)

	set_process(true)

# ExpandedView.refresh から毎 tick 呼ばれる。状態参照とクールダウンを更新。
func update_state(state: GameState) -> void:
	_state = state
	if state.active_work != _active:
		_active = state.active_work
		_t = 0.0
	if _active != "" and _skills != null and _skills.has_skill(_active):
		_cd = maxf(0.1, _skills.cooldown(_active))

# 実際に1回作業が実行された瞬間（汚れ減少など）。バーを 0 に戻し演出する。
func on_performed(skill_id: String, effect: int) -> void:
	_t = 0.0
	_pulse = 1.0
	if _skills == null:
		return
	var d: Dictionary = _skills.get_def(skill_id)
	var affects: String = str(d.get("affects", ""))
	if affects == "dirtiness":
		_feedback.text = "🧹 -%d" % effect
	elif affects == "food_stock":
		_feedback.text = "🍽️ +%d" % effect
	else:
		_feedback.text = "+%d" % effect
	_feedback_t = 1.2

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var working: bool = _active != "" and _skills != null and _skills.has_skill(_active)
	if working:
		var d: Dictionary = _skills.get_def(_active)
		_icon.text = str(d.get("icon", "🛠️"))
		_name.text = "%s 実行中…" % str(d.get("name", _active))
		_t = minf(_t + delta, _cd)            # 満タンで perform 待ち
		_bar.value = _t / _cd
		# アイコンを左右に軽く揺らす（ほうきを動かす感じ）
		_wiggle += delta * 6.0
		_icon.pivot_offset = _icon.size * 0.5
		_icon.rotation = deg_to_rad(9.0 * sin(_wiggle))
	else:
		_icon.text = "💤"
		_icon.rotation = 0.0
		_name.text = "休憩中 — 「仕事」タブで作業カードを選ぶと開始します"
		_bar.value = 0.0

	# 完了パルス（バーを一瞬明るく）
	if _pulse > 0.0:
		_pulse = maxf(0.0, _pulse - delta * 2.5)
	_bar.modulate = Color(1, 1, 1).lerp(Color(1.4, 1.4, 1.0), _pulse)

	# フィードバック文字のフェード
	if _feedback_t > 0.0:
		_feedback_t -= delta
		_feedback.modulate.a = clampf(_feedback_t, 0.0, 1.0)
		if _feedback_t <= 0.0:
			_feedback.text = ""
