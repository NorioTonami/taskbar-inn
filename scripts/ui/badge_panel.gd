class_name BadgePanel
extends VBoxContainer
# badge_panel.gd — 取得済み/未取得バッジの一覧。獲得済みは点灯、未取得は淡色。

var _grid: GridContainer

func _ready() -> void:
	var title := Label.new()
	title.text = "バッジ"
	title.add_theme_font_size_override("font_size", 16)
	add_child(title)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 4)
	add_child(_grid)

func populate(manager: BadgeManager, state: GameState) -> void:
	if _grid == null:
		return
	for c in _grid.get_children():
		c.queue_free()
	for b in manager.badges:
		var id: String = str(b.get("id", ""))
		var got: bool = state.badges.has(id)
		var lbl := Label.new()
		lbl.text = "%s %s" % [str(b.get("icon", "")), str(b.get("name", id)) if got else "？？？"]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.modulate = Color(1, 1, 1) if got else Color(1, 1, 1, 0.35)
		_grid.add_child(lbl)
