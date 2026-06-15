class_name StaffPanel
extends VBoxContainer
# staff_panel.gd — スタッフ専用ページ。
# スタッフ詰め所の建設後に表示される。
# 雇用ボタン、配置枠、現在のスタッフ一覧をまとめて表示する。

signal hire_staff(role_id: String)

var _staff: StaffManager

func _ready() -> void:
	add_theme_constant_override("separation", 6)

func setup(staff: StaffManager) -> void:
	_staff = staff

func populate(state: GameState) -> void:
	for c in get_children():
		c.queue_free()
	if _staff == null:
		return

	_header("スタッフ（配置枠 %d / %d）" % [state.assigned_staff_count(), state.placement_slots])
	_note("スタッフは選択中の仕事とは別に、自分の担当作業を自動で進めます。")

	_header("雇用")
	var roles: Array = _staff.unlocked_roles(state)
	if roles.is_empty():
		_note("雇用できるスタッフはまだいません。宿Lvや評判を上げましょう。")
	else:
		for r in roles:
			add_child(_hire_row(state, r))

	_header("スタッフリスト")
	if state.staff.is_empty():
		_note("まだスタッフはいません。スタッフ詰め所で配置枠を増やしてから雇用できます。")
	else:
		for s in state.staff:
			add_child(_staff_row(state, s))

func _header(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l)

func _note(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.modulate = Color(1, 1, 1, 0.6)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l)

func _hire_row(state: GameState, r: Dictionary) -> Control:
	var role_id: String = str(r.get("role_id", ""))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.text = "%s %s を雇用（初期 Lv%d）" % [
		str(r.get("icon", "")), str(r.get("name", role_id)),
		_staff.initial_level(state, role_id)
	]
	row.add_child(lbl)

	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = "💰%d" % _staff.hire_cost(state, role_id)
	btn.disabled = not _staff.can_hire(state, role_id)
	if not _staff.has_free_slot(state):
		btn.tooltip_text = "配置枠が足りません。設備でスタッフ詰め所を増やしましょう"
	elif state.reputation < int(r.get("reputation_req", 0)):
		btn.tooltip_text = "評判が足りません（%d 必要）" % int(r.get("reputation_req", 0))
	row.add_child(btn)
	btn.pressed.connect(func(): hire_staff.emit(role_id))
	return row

func _staff_row(state: GameState, s: Dictionary) -> Control:
	var row := Label.new()
	row.add_theme_font_size_override("font_size", 12)
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var role: Dictionary = _staff.get_role(str(s.get("role_id", "")))
	row.text = "%s %s ｜ %s Lv%d ｜ 自動 %d（%.0f秒ごと）" % [
		str(role.get("icon", "")), str(s.get("name", "")),
		str(role.get("name", "")), int(s.get("level", 1)),
		_staff.auto_effect(state, s), _staff.cooldown(str(s.get("role_id", "")))
	]
	return row
