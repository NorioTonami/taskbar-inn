class_name ToolPanel
extends VBoxContainer
# tool_panel.gd — 道具投資ページ。
# 手動作業とスタッフ自動化に効く道具を、仕事タブから独立して一覧表示する。
# 解放済みスキルに紐づく道具だけ購入可能にする。

signal buy_tool(id: String)

var _skills: SkillManager
var _tools: ToolCatalog

func setup(skills: SkillManager, tools: ToolCatalog) -> void:
	_skills = skills
	_tools = tools

func _ready() -> void:
	add_theme_constant_override("separation", 8)

func populate(state: GameState) -> void:
	for c in get_children():
		c.queue_free()
	if _skills == null or _tools == null:
		return
	_header("道具")
	for t in _tools.tools:
		var skill_id: String = str(t.get("skill", ""))
		if _skills.is_unlocked(state, skill_id):
			add_child(_tool_row(state, t))

func _tool_row(state: GameState, t: Dictionary) -> Control:
	var id: String = str(t.get("id", ""))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var cur := _tools.current_tier(state, id)
	var name_lbl := Label.new()
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.text = "%s %s：%s（+%d）" % [str(t.get("icon", "")), str(t.get("name", id)),
		str(cur.get("name", "")), int(cur.get("bonus", 0))]
	row.add_child(name_lbl)
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	if _tools.is_maxed(state, id):
		btn.text = "MAX"
		btn.disabled = true
	else:
		var nt := _tools.next_tier(state, id)
		btn.text = "▲%s 💰%d" % [str(nt.get("name", "")), _tools.next_cost(state, id)]
		btn.disabled = not _tools.can_buy(state, id)
		btn.pressed.connect(func(): buy_tool.emit(id))
	row.add_child(btn)
	return row

func _header(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	add_child(l)
