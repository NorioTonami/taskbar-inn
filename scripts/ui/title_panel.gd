class_name TitlePanel
extends VBoxContainer
# title_panel.gd — 到達称号の一覧。獲得済みは点灯、未取得は淡色表示。

var _list: VBoxContainer

func _ready() -> void:
	var title := Label.new()
	title.text = "称号"
	title.add_theme_font_size_override("font_size", 16)
	add_child(title)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	add_child(_list)

func populate(manager: TitleManager, state: GameState) -> void:
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()
	for t in manager.titles:
		var id: String = str(t.get("id", ""))
		var got: bool = state.titles.has(id)
		var lbl := Label.new()
		lbl.text = "%s %s" % [str(t.get("icon", "")), str(t.get("name", id)) if got else "？？？"]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.modulate = Color(1, 0.95, 0.6) if got else Color(1, 1, 1, 0.35)
		_list.add_child(lbl)
