class_name ExpandedView
extends PanelContainer
# expanded_view.gd — 管理画面 UI（v0.3）。コード生成。
# ヘッダ統計＋左サイドバー（ホーム/設備/仕事/ログ/実績）。操作は signal で main へ通知する。

signal close_requested
signal quit_requested
signal buy_upgrade(id: String)
signal set_work(skill_id: String)
signal buy_tool(id: String)
signal hire_staff(role_id: String)
signal rank_up()
signal dev_toggle_requested()

var _catalog: UpgradeCatalog
var _skills: SkillManager
var _staff: StaffManager
var _tools: ToolCatalog
var _tiers: ServiceTierManager
var _badges: BadgeManager
var _titles: TitleManager

var _header: Label
var _home_panel: HomePanel
var _upgrade_panel: UpgradePanel
var _work_panel: WorkPanel
var _tool_panel: ToolPanel
var _log_panel: EventLogPanel
var _badge_panel: BadgePanel
var _title_panel: TitlePanel
var _work_strip: WorkStrip
var _mini_log: MiniLog
var _status_label: Label
var _dev_status_label: Label
var _dev_enabled: bool = false
var _page_host: Control
var _pages: Dictionary = {}
var _current_page: String = "home"

func setup(catalog: UpgradeCatalog, skills: SkillManager, staff: StaffManager,
		tools: ToolCatalog, service_tiers: ServiceTierManager,
		badges: BadgeManager, titles: TitleManager, dev_enabled: bool = false) -> void:
	_catalog = catalog
	_skills = skills
	_staff = staff
	_tools = tools
	_tiers = service_tiers
	_badges = badges
	_titles = titles
	_dev_enabled = dev_enabled

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	var margin := MarginContainer.new()
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 10)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)

	# --- ヘッダ ---
	var top := HBoxContainer.new()
	root.add_child(top)
	_header = Label.new()
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_theme_font_size_override("font_size", 14)
	_header.clip_text = true
	_header.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(_header)
	var minimize_btn := Button.new()
	minimize_btn.text = "－"
	minimize_btn.tooltip_text = "ミニウィンドウへ"
	minimize_btn.focus_mode = Control.FOCUS_NONE
	minimize_btn.pressed.connect(func(): close_requested.emit())
	top.add_child(minimize_btn)
	var quit_btn := Button.new()
	quit_btn.text = "✕"
	quit_btn.tooltip_text = "ゲームを終了"
	quit_btn.focus_mode = Control.FOCUS_NONE
	quit_btn.pressed.connect(func(): quit_requested.emit())
	top.add_child(quit_btn)

	# --- サイドバー + ページ ---
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(0, 330)
	body.add_theme_constant_override("separation", 8)
	root.add_child(body)

	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(112, 0)
	sidebar.add_theme_constant_override("separation", 6)
	body.add_child(sidebar)
	var group := ButtonGroup.new()
	sidebar.add_child(_menu_button(group, "home", "🏠 ホーム"))
	sidebar.add_child(_menu_button(group, "upgrades", "🧱 設備"))
	sidebar.add_child(_menu_button(group, "work", "🧹 仕事"))
	sidebar.add_child(_menu_button(group, "tools", "🧰 道具"))
	sidebar.add_child(_menu_button(group, "log", "📜 ログ"))
	sidebar.add_child(_menu_button(group, "achievements", "🏅 実績"))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(spacer)

	_page_host = Control.new()
	_page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_page_host)

	# ホーム
	var home_scroll := ScrollContainer.new()
	home_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	home_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_home_panel = HomePanel.new()
	_home_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_home_panel.setup(_catalog, _tiers)
	_home_panel.rank_up.connect(func(): rank_up.emit())
	home_scroll.add_child(_home_panel)
	_add_page("home", home_scroll)

	# 設備
	var upgrade_scroll := ScrollContainer.new()
	upgrade_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	upgrade_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_upgrade_panel = UpgradePanel.new()
	_upgrade_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_panel.buy_requested.connect(func(id): buy_upgrade.emit(id))
	upgrade_scroll.add_child(_upgrade_panel)
	_add_page("upgrades", upgrade_scroll)

	# 仕事
	var work_scroll := ScrollContainer.new()
	work_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	work_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_work_panel = WorkPanel.new()
	_work_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_work_panel.setup(_skills, _staff, _tools, _tiers)
	_work_panel.set_work.connect(func(id): set_work.emit(id))
	_work_panel.buy_tool.connect(func(id): buy_tool.emit(id))
	_work_panel.hire_staff.connect(func(id): hire_staff.emit(id))
	work_scroll.add_child(_work_panel)
	_add_page("work", work_scroll)

	# 道具
	var tool_scroll := ScrollContainer.new()
	tool_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	tool_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tool_panel = ToolPanel.new()
	_tool_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tool_panel.setup(_skills, _tools)
	_tool_panel.buy_tool.connect(func(id): buy_tool.emit(id))
	tool_scroll.add_child(_tool_panel)
	_add_page("tools", tool_scroll)

	# ログ
	_log_panel = EventLogPanel.new()
	_log_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_add_page("log", _log_panel)

	# 実績
	var ach := VBoxContainer.new()
	ach.set_anchors_preset(Control.PRESET_FULL_RECT)
	ach.add_theme_constant_override("separation", 10)
	_badge_panel = BadgePanel.new()
	_title_panel = TitlePanel.new()
	ach.add_child(_badge_panel)
	ach.add_child(_title_panel)
	_add_page("achievements", ach)
	_show_page(_current_page)

	# --- タブ下：作業アニメ＋進捗バー（常時表示）---
	_work_strip = WorkStrip.new()
	_work_strip.setup(_skills)
	root.add_child(_work_strip)

	# --- タブ下：直近ログ（常時表示・ログタブとは別）---
	_mini_log = MiniLog.new()
	root.add_child(_mini_log)

	# --- 通常ステータスバー ---
	var bar := PanelContainer.new()
	root.add_child(bar)
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 8)
	bar.add_child(bar_row)
	_status_label = Label.new()
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.modulate = Color(0.72, 0.66, 0.58)
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar_row.add_child(_status_label)

	# --- dev 専用ステータスバー（リリース時は生成しない） ---
	if _dev_enabled:
		var dev_bar := PanelContainer.new()
		root.add_child(dev_bar)
		var dev_row := HBoxContainer.new()
		dev_row.add_theme_constant_override("separation", 8)
		dev_bar.add_child(dev_row)
		_dev_status_label = Label.new()
		_dev_status_label.text = "開発用"
		_dev_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_dev_status_label.add_theme_font_size_override("font_size", 11)
		_dev_status_label.modulate = Color(0.86, 0.72, 0.50)
		_dev_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dev_row.add_child(_dev_status_label)
		var dev_btn := Button.new()
		dev_btn.text = "🛠 DEV"
		dev_btn.tooltip_text = "開発パネルを開閉 (F9)"
		dev_btn.focus_mode = Control.FOCUS_NONE
		dev_btn.add_theme_font_size_override("font_size", 11)
		dev_btn.pressed.connect(func(): dev_toggle_requested.emit())
		dev_row.add_child(dev_btn)

func refresh(state: GameState) -> void:
	if _header == null:
		return
	var work_name: String = "なし"
	if state.active_work != "" and _skills.has_skill(state.active_work):
		work_name = _skills.display_name(state.active_work)
	var tier_name: String = str(_tiers.current(state).get("name", ""))
	var food_str: String = ""
	if state.service_rank >= 2:
		food_str = "  🍽️%d/%d" % [int(state.total_meal_stock()), state.meal_storage_capacity()]
	_header.text = "%s ｜ 💰%d  ⭐%d  🛏️%d/%d  🧹%d/%d%s  Lv%d  作業:%s" % [
		tier_name, state.gold, state.reputation, state.guest_count, state.guest_capacity,
		int(state.dirtiness), state.dirty_cap(), food_str, state.level, work_name]
	_home_panel.populate(state)
	_upgrade_panel.populate(_catalog, state)
	_work_panel.populate(state)
	_tool_panel.populate(state)
	_log_panel.populate(state)
	_badge_panel.populate(_badges, state)
	_title_panel.populate(_titles, state)
	_work_strip.update_state(state)
	_mini_log.populate(state)

	var hint: String = "🛠️ 作業: %s" % work_name
	var dcap: int = state.dirty_cap()
	if dcap > 0 and float(state.dirtiness) / float(dcap) >= 0.8:
		hint += "    ⚠ 汚れがひどい — 清掃を"
	_status_label.text = hint
	if _dev_status_label != null:
		_dev_status_label.text = "開発用ステータスバー / F9"

# 作業が1回実行された瞬間を作業ストリップへ転送（バーのリセット＆演出）。
func on_work_performed(skill_id: String, effect: int) -> void:
	if _work_strip != null:
		_work_strip.on_performed(skill_id, effect)

func _menu_button(group: ButtonGroup, page_id: String, text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.toggle_mode = true
	btn.button_group = group
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 36)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.button_pressed = page_id == _current_page
	btn.pressed.connect(func(): _show_page(page_id))
	return btn

func _add_page(page_id: String, page: Control) -> void:
	page.visible = false
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_host.add_child(page)
	_pages[page_id] = page

func _show_page(page_id: String) -> void:
	_current_page = page_id
	for key in _pages.keys():
		var page: Control = _pages[key]
		page.visible = str(key) == page_id
