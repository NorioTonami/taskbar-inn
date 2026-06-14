class_name CompactView
extends PanelContainer
# compact_view.gd — 常駐する小窓 UI（v0.3）。コードで生成。
# 所持金・客数・評判・汚れメーター・現在の作業を表示し、客到着時に吹き出しを出す。
# state のスナップショットを読むだけ。状態変更はしない。

signal expand_requested

const BUBBLE_SECONDS: float = 1.5

var _icon: Label
var _gold: Label
var _guests: Label
var _rep: Label
var _dirt: Label
var _food: Label
var _work: Label
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
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(row)

	_icon = _mk_label("🏠", 26)
	row.add_child(_icon)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 12)
	col.add_child(stats)
	_gold = _mk_label("💰0", 14)
	_guests = _mk_label("🛏️0/0", 14)
	_rep = _mk_label("⭐0", 14)
	_dirt = _mk_label("🧹0", 14)
	_food = _mk_label("", 14)
	_food.modulate = Color(1.0, 0.85, 0.5)
	stats.add_child(_gold)
	stats.add_child(_guests)
	stats.add_child(_rep)
	stats.add_child(_dirt)
	stats.add_child(_food)

	var sub := HBoxContainer.new()
	sub.add_theme_constant_override("separation", 8)
	col.add_child(sub)
	_work = _mk_label("", 11)
	_work.modulate = Color(0.7, 0.9, 1.0)
	_work.clip_text = true
	_work.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub.add_child(_work)
	_bubble = _mk_label("", 11)
	_bubble.modulate = Color(1, 1, 1, 0.85)
	_bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bubble.clip_text = true
	_bubble.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub.add_child(_bubble)

	var btn := Button.new()
	btn.text = "📋"
	btn.tooltip_text = "管理画面を開く"
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func(): expand_requested.emit())
	row.add_child(btn)

	set_process(true)

func _mk_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
	_gold.text = "💰%d" % state.gold
	_guests.text = "🛏️%d/%d" % [state.guest_count, state.guest_capacity]
	_rep.text = "⭐%d" % state.reputation
	var cap: int = state.dirty_cap()
	_dirt.text = "🧹%d/%d" % [int(state.dirtiness), cap]
	var frac: float = state.dirtiness / maxf(1.0, float(cap))
	if frac >= 0.8:
		_dirt.modulate = Color(1.0, 0.4, 0.4)
	elif frac >= 0.6:
		_dirt.modulate = Color(1.0, 0.8, 0.4)
	else:
		_dirt.modulate = Color(0.7, 1.0, 0.7)
	if state.service_rank >= 2:
		_food.text = "🍽️%d/%d" % [int(state.food_stock), state.food_cap()]
	else:
		_food.text = ""
	_work.text = ("🛠️ %s" % work_label) if work_label != "" else ""
