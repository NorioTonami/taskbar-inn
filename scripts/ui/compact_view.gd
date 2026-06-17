class_name CompactView
extends PanelContainer
# compact_view.gd — 常駐する小窓 UI（v0.3）。コードで生成。
# 所持金・汚れ・食事在庫・通知・現在の作業を表示し、客到着時に吹き出しを出す。
# state のスナップショットを読むだけ。状態変更はしない。

signal expand_requested

const BUBBLE_SECONDS: float = 1.5

var _icon: Label
var _status: Label
var _notice: Label
var _bubble: Label
var _bubble_timer: float = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(row)

	_icon = _mk_label("🏠", 26)
	_icon.custom_minimum_size = Vector2(34, 0)
	row.add_child(_icon)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.custom_minimum_size = Vector2(350, 0)
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)

	_status = _mk_label("", 13)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.custom_minimum_size = Vector2(0, 22)
	col.add_child(_status)

	var sub := HBoxContainer.new()
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.add_theme_constant_override("separation", 8)
	col.add_child(sub)
	_notice = _mk_label("", 11)
	_notice.modulate = Color(0.95, 0.82, 0.48)
	_notice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.add_child(_notice)
	_bubble = _mk_label("", 11)
	_bubble.modulate = Color(1, 1, 1, 0.85)
	_bubble.custom_minimum_size = Vector2(120, 0)
	_bubble.clip_text = true
	_bubble.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub.add_child(_bubble)

	var btn := Button.new()
	btn.text = "📋"
	btn.tooltip_text = "管理画面を開く"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(52, 52)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn.pressed.connect(func(): expand_requested.emit())
	row.add_child(btn)

	set_process(true)

func _mk_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return l

func _process(delta: float) -> void:
	if _bubble_timer > 0.0:
		_bubble_timer -= delta
		if _bubble_timer <= 0.0 and _bubble != null:
			_bubble.text = ""

func show_bubble(text: String) -> void:
	if _bubble == null or text.is_empty():
		return
	_bubble.text = "「%s」" % text
	_bubble_timer = BUBBLE_SECONDS

func refresh(state: GameState, work_label: String) -> void:
	if _icon == null:
		return
	var food_text: String = "-"
	if state.service_rank >= 2:
		food_text = "%d/%d" % [int(state.total_meal_stock()), state.meal_storage_capacity()]
	_status.text = "G %d   評判 %d   客 %d/%d   汚れ %d/%d   食事 %s" % [
		state.gold, state.reputation, state.guest_count, state.guest_capacity,
		int(state.dirtiness), state.dirty_cap(), food_text]
	_notice.text = _notice_text(state, work_label)

func _notice_text(state: GameState, work_label: String) -> String:
	var cap: int = state.dirty_cap()
	var dirt_frac: float = state.dirtiness / maxf(1.0, float(cap))
	if dirt_frac >= 0.8:
		return "清掃が必要です"
	if state.service_rank >= 2 and state.total_meal_stock() <= 0.0:
		return "食事在庫が空です"
	if work_label != "":
		return "作業中: %s" % work_label
	return "休憩中"
