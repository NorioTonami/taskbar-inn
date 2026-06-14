class_name HomePanel
extends VBoxContainer
# home_panel.gd — ホームタブの情報集積ダッシュボード。
# 宿の定量ステータス、アンロック通知、次階層へのアップデート、
# 次に見るべき道筋を示す。

signal buy_upgrade(id: String)
signal rank_up()

var _catalog: UpgradeCatalog
var _tiers: ServiceTierManager

func setup(catalog: UpgradeCatalog, service_tiers: ServiceTierManager) -> void:
	_catalog = catalog
	_tiers = service_tiers

func _ready() -> void:
	add_theme_constant_override("separation", 8)

func populate(state: GameState) -> void:
	for c in get_children():
		c.queue_free()
	if _catalog == null or _tiers == null:
		return
	_status_dashboard(state)
	_notification_area(state)
	_rank_section(state)

func _status_dashboard(state: GameState) -> void:
	_header("宿の状況")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	grid.add_child(_stat_card("売上", "%d G" % state.gold))
	grid.add_child(_stat_card("累計売上", "%d G" % state.total_gold_earned))
	grid.add_child(_stat_card("宿泊中", "%d / %d" % [state.guest_count, state.guest_capacity]))
	grid.add_child(_stat_card("累計宿泊", "%d 人" % state.total_guests))
	grid.add_child(_stat_card("評判", "%d" % state.reputation))
	grid.add_child(_stat_card("汚れ", "%d / %d" % [int(state.dirtiness), state.dirty_cap()]))

func _notification_area(state: GameState) -> void:
	var box := PanelContainer.new()
	add_child(box)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 3)
	box.add_child(inner)
	var title := Label.new()
	title.text = "通知"
	title.add_theme_font_size_override("font_size", 13)
	inner.add_child(title)
	var body := Label.new()
	body.add_theme_font_size_override("font_size", 12)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color(0.94, 0.86, 0.72)
	if _tiers.has_next(state) and _tiers.can_rank_up(state):
		var nxt: Dictionary = _tiers.next_def(state)
		body.text = "%s %s が解放できます。ホームで宿をアップデートしましょう。" % [
			str(nxt.get("icon", "")), str(nxt.get("name", ""))]
	elif _tiers.has_next(state):
		body.text = "次の目標：%s" % _tiers.next_requirements_text(state)
	elif state.event_log.is_empty():
		body.text = "新しい通知はありません。"
	else:
		body.text = str(state.event_log[state.event_log.size() - 1])
	inner.add_child(body)

func _rank_section(state: GameState) -> void:
	if not _tiers.has_next(state):
		return
	var nxt: Dictionary = _tiers.next_def(state)
	var box := PanelContainer.new()
	add_child(box)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	box.add_child(inner)
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 13)
	title.text = "宿アップデート：%s %s" % [str(nxt.get("icon", "")), str(nxt.get("name", ""))]
	inner.add_child(title)
	var desc := Label.new()
	desc.add_theme_font_size_override("font_size", 12)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.modulate = Color(1, 1, 1, 0.72)
	desc.text = str(nxt.get("desc", ""))
	inner.add_child(desc)
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	if _tiers.can_rank_up(state):
		btn.text = "宿をアップデートする"
		btn.pressed.connect(func(): rank_up.emit())
	else:
		btn.text = "解放条件：%s" % _tiers.next_requirements_text(state)
		btn.disabled = true
		btn.clip_text = true
	inner.add_child(btn)

func _stat_card(label: String, value: String) -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(110, 48)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 0)
	box.add_child(inner)
	var l := Label.new()
	l.text = label
	l.add_theme_font_size_override("font_size", 11)
	l.modulate = Color(1, 1, 1, 0.62)
	inner.add_child(l)
	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 14)
	v.clip_text = true
	v.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	inner.add_child(v)
	return box

func _header(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	add_child(l)
