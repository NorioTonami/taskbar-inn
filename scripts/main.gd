extends Control
# main.gd — エントリ（v0.3）。状態/マネージャ生成・tick 統括・view 切替・dev。
# ゲームロジックは各マネージャに委譲し、ここは配線と UI 切替に専念する。

const AUTOSAVE_EVERY_TICKS: int = 15

var state: GameState
var upgrades: UpgradeCatalog
var guests: GuestManager
var events: EventManager
var badges: BadgeManager
var titles: TitleManager
var tools: ToolCatalog
var skills: SkillManager
var staff: StaffManager
var tiers: ServiceTierManager
var simulator: InnSimulator
var saver: SaveManager
var window_mgr: WindowManager

var compact: CompactView
var expanded: ExpandedView
var dev_overlay: DevOverlay
var _expanded_mode: bool = false
var _tick_count: int = 0
var _saved: bool = false
var _resetting: bool = false

var _dev_mode: bool = false
var _time_scale: int = 1

# 枠なしウィンドウのドラッグ移動用
var _dragging: bool = false
var _drag_offset: Vector2i = Vector2i.ZERO

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiTheme.build()

	# --- dev 設定 ---
	var dev: Dictionary = DataLoader.load_dict("res://data/dev_config.json")
	_dev_mode = bool(dev.get("dev_mode", false))
	_time_scale = max(1, int(dev.get("time_scale", 1)))

	# --- 状態とマネージャ ---
	state = GameState.new()
	upgrades = UpgradeCatalog.new()
	guests = GuestManager.new()
	events = EventManager.new()
	badges = BadgeManager.new()
	titles = TitleManager.new()
	tools = ToolCatalog.new()
	skills = SkillManager.new(tools)
	staff = StaffManager.new(tools, skills)
	tiers = ServiceTierManager.new()
	simulator = InnSimulator.new(state, upgrades, guests, events, badges, titles, skills, staff, tools)
	simulator.price_mult = float(dev.get("price_mult", 1.0))
	saver = SaveManager.new()
	window_mgr = WindowManager.new(get_window())

	# --- セーブ読込 + オフライン進行 ---
	var load_result: Dictionary = saver.load(state, simulator)

	# --- UI 生成 ---
	compact = CompactView.new()
	compact.expand_requested.connect(_on_expand_requested)
	add_child(compact)

	expanded = ExpandedView.new()
	expanded.setup(upgrades, skills, staff, tools, tiers, badges, titles, _dev_mode)
	expanded.close_requested.connect(_on_close_requested)
	expanded.quit_requested.connect(_on_quit_requested)
	expanded.buy_upgrade.connect(_on_buy_upgrade)
	expanded.set_work.connect(_on_set_work)
	expanded.buy_tool.connect(_on_buy_tool)
	expanded.hire_staff.connect(_on_hire_staff)
	expanded.rank_up.connect(_on_rank_up)
	expanded.dev_toggle_requested.connect(_on_dev_toggle)
	expanded.visible = false
	add_child(expanded)

	_set_passthrough(compact)
	_set_passthrough(expanded)

	# --- simulator signal 配線 ---
	simulator.guest_arrived.connect(_on_guest_arrived)
	simulator.badge_unlocked.connect(_on_award.bind("バッジ獲得"))
	simulator.title_unlocked.connect(_on_award.bind("称号獲得"))
	simulator.slot_unlocked.connect(_on_slot_unlocked)
	simulator.skill_leveled.connect(_on_skill_leveled)
	simulator.work_performed.connect(_on_work_performed)

	# --- dev オーバーレイ ---
	if _dev_mode:
		_build_dev_overlay()

	_show_compact()

	# --- tick タイマー ---
	var timer := Timer.new()
	timer.wait_time = InnSimulator.TICK_SECONDS
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	add_child(timer)

	var off: Dictionary = load_result.get("offline", {})
	if not off.is_empty() and int(off.get("seconds", 0)) > 0:
		_show_offline_panel(off)

	_refresh()

func _on_tick() -> void:
	for i in _time_scale:
		simulator.tick()
	_refresh()
	window_mgr.enforce_fixed_size()
	_tick_count += 1
	if _tick_count % AUTOSAVE_EVERY_TICKS == 0:
		saver.save(state)

func _refresh() -> void:
	if _expanded_mode:
		expanded.refresh(state)
	else:
		var work_label: String = ""
		if state.active_work != "" and skills.has_skill(state.active_work):
			work_label = skills.display_name(state.active_work)
		compact.refresh(state, work_label)

# --- view 切替 ---
func _show_compact() -> void:
	_expanded_mode = false
	expanded.visible = false
	compact.visible = true
	window_mgr.apply_compact()
	_refresh()

func _show_expanded() -> void:
	_expanded_mode = true
	compact.visible = false
	expanded.visible = true
	window_mgr.apply_expanded()
	_refresh()

# --- 入力 ---
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		_on_dev_toggle()

func _on_dev_toggle() -> void:
	if dev_overlay != null:
		dev_overlay.visible = not dev_overlay.visible

func _unhandled_input(event: InputEvent) -> void:
	_drag_window(event)

# 枠なしウィンドウのドラッグ移動。余白からの通常入力でも、モーダル背景の
# gui_input からでも同じ処理を使い、常にウィンドウを掴んで動かせるようにする。
func _drag_window(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = DisplayServer.mouse_get_position() - get_window().position
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		get_window().position = DisplayServer.mouse_get_position() - _drag_offset

func _set_passthrough(node: Node) -> void:
	for c in node.get_children():
		_set_passthrough(c)
	if node is Button or node is TabContainer or node is ScrollContainer \
			or node is TabBar or node is ScrollBar:
		return
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_PASS

func _on_expand_requested() -> void:
	_show_expanded()

func _on_close_requested() -> void:
	_show_compact()

func _on_quit_requested() -> void:
	if not _saved and state != null and saver != null:
		saver.save(state)
		_saved = true
	get_tree().quit()

# --- 操作ハンドラ ---
func _on_buy_upgrade(id: String) -> void:
	if upgrades.buy(state, id):
		_refresh()

func _on_set_work(skill_id: String) -> void:
	state.active_work = skill_id
	_refresh()

func _on_buy_tool(id: String) -> void:
	if tools.buy(state, id):
		_refresh()

func _on_hire_staff(role_id: String) -> void:
	if staff.hire(state, role_id):
		_refresh()

func _on_rank_up() -> void:
	var def: Dictionary = tiers.rank_up(state)
	if not def.is_empty():
		_show_toast("🎊 ランクアップ！\n%s %s" % [str(def.get("icon", "")), str(def.get("name", ""))])
		_refresh()

# --- 演出 ---
func _on_guest_arrived(_type_def: Dictionary, line: String, _price: int) -> void:
	if not _expanded_mode:
		compact.show_bubble(line)

func _on_award(def: Dictionary, prefix: String) -> void:
	_show_toast("%s：%s %s" % [prefix, str(def.get("icon", "")), str(def.get("name", ""))])

func _on_slot_unlocked(_slots: int) -> void:
	_show_toast("スタッフ詰め所が設備に追加されました！\n建てるとスタッフ管理が開きます")

func _on_skill_leveled(skill_id: String, level: int) -> void:
	_show_toast("%s Lv%d に上がりました" % [skills.display_name(skill_id), level])

func _on_work_performed(skill_id: String, effect: int) -> void:
	# 作業状況パネルの進捗バーをリセット＆演出（expanded 表示時のみ意味を持つ）
	expanded.on_work_performed(skill_id, effect)

# オフライン進行の結果はクリックで閉じるモーダル。自動では消えない。
func _show_offline_panel(off: Dictionary) -> void:
	var mins: int = int(off.get("seconds", 0)) / 60
	var body: String = "🛏️ 宿泊客 : %d人\n💰 売上 : %dG\n⭐ 評判 : +%d\n🧹 汚れ : %d/%d（要清掃かも）" % [
		int(off.get("guests", 0)), int(off.get("gold", 0)), int(off.get("reputation", 0)),
		int(off.get("dirtiness", 0)), int(off.get("dirty_cap", 0))]

	# 結果を読める大きさへ一時的にリサイズ
	window_mgr.apply_dialog()

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.55)
	# 暗幕をドラッグするとウィンドウを移動できる（モーダル中も動かせる）
	bg.gui_input.connect(_drag_window)
	overlay.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)
	var m := MarginContainer.new()
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		m.add_theme_constant_override(k, 14)
	panel.add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	m.add_child(box)

	var title := Label.new()
	title.text = "🌙 留守中の営業結果（約%d分）" % mins
	title.add_theme_font_size_override("font_size", 15)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var lbl := Label.new()
	lbl.text = body
	lbl.add_theme_font_size_override("font_size", 13)
	box.add_child(lbl)

	var ok := Button.new()
	ok.text = "✓ 確認して始める"
	ok.focus_mode = Control.FOCUS_NONE
	ok.pressed.connect(func():
		overlay.queue_free()
		window_mgr.apply_compact())
	box.add_child(ok)

	add_child(overlay)

func _show_toast(text: String) -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(0, 6)
	# トーストはクリックを奪わない。compact の 📋（展開）ボタン等の上に
	# 重なっても、下のボタンをそのまま押せるようにする。
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		m.add_theme_constant_override(k, 8)
	m.add_child(lbl)
	panel.add_child(m)
	add_child(panel)
	panel.reset_size.call_deferred()
	var tw := create_tween()
	tw.tween_interval(2.8)
	tw.tween_property(panel, "modulate:a", 0.0, 0.6)
	tw.tween_callback(panel.queue_free)

# --- dev ---
func _build_dev_overlay() -> void:
	dev_overlay = DevOverlay.new()
	dev_overlay.position = Vector2(8, 8)
	dev_overlay.visible = false
	dev_overlay.time_scale_set.connect(func(s): _time_scale = max(1, s))
	dev_overlay.add_gold.connect(func(n): state.gold += n; _refresh())
	dev_overlay.add_rep.connect(func(n): state.reputation += n; _refresh())
	dev_overlay.set_dirty.connect(_on_dev_set_dirty)
	dev_overlay.set_food.connect(_on_dev_set_food)
	dev_overlay.add_generic_ingredients.connect(_on_dev_add_generic_ingredients)
	dev_overlay.force_guests.connect(_on_dev_force_guests)
	dev_overlay.add_slot.connect(func(): state.placement_slots += 1; _refresh())
	dev_overlay.rank_up.connect(_on_dev_rank_up)
	dev_overlay.reset_save.connect(_on_dev_reset)
	add_child(dev_overlay)

func _on_dev_set_dirty(full: bool) -> void:
	state.dirtiness = float(state.dirty_cap()) if full else 0.0
	_refresh()

func _on_dev_set_food(full: bool) -> void:
	state.ensure_meal_stocks()
	for rank in GameState.MEAL_RANKS:
		state.meal_stocks[rank] = 0.0
	if full:
		state.meal_stocks["basic"] = float(state.meal_storage_capacity())
		state.vegetable_stock = float(state.vegetable_cap())
		state.generic_ingredient_stock = float(state.generic_ingredient_cap())
	else:
		state.vegetable_stock = 0.0
		state.generic_ingredient_stock = 0.0
	state.sync_food_stock_from_meals()
	_refresh()

func _on_dev_add_generic_ingredients(n: int) -> void:
	state.add_generic_ingredient_stock(float(n))
	_refresh()

func _on_dev_rank_up() -> void:
	# dev: 条件を無視して1段上げる（次階層が存在すれば）
	if tiers.has_next(state):
		state.service_rank += 1
		state.add_log("（dev）ランクを %d に上げました" % state.service_rank)
		_refresh()

func _on_dev_force_guests(n: int) -> void:
	state.total_guests += n
	state.add_guest_count("traveler", n)
	_refresh()

func _on_dev_reset() -> void:
	_resetting = true
	saver.reset()
	get_tree().reload_current_scene()

# --- 終了時セーブ ---
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		if not _resetting and not _saved and state != null and saver != null:
			saver.save(state)
			_saved = true
		if what == NOTIFICATION_WM_CLOSE_REQUEST:
			get_tree().quit()
