class_name UpgradePanel
extends VBoxContainer
# upgrade_panel.gd — 「設備」タブの一覧（v0.3）。
# category 見出しで分類し、未解放(unlock未達)はグレーアウトで条件を示す。

signal buy_requested(id: String)

const CATEGORY_LABEL := {
	"base": "基礎設備",
	"production": "生産設備",
	"interior": "内装投資",
	"facility": "特殊設備",
	"special": "特殊設備",
}

func _ready() -> void:
	add_theme_constant_override("separation", 4)

func populate(catalog: UpgradeCatalog, state: GameState) -> void:
	for c in get_children():
		c.queue_free()

	var order := ["base", "production", "interior", "facility", "special"]
	var seen := {}
	for cat in order:
		var rows := _rows_for_category(catalog, state, cat)
		if rows.is_empty():
			continue
		seen[cat] = true
		_header(str(CATEGORY_LABEL.get(cat, cat)))
		for row in rows:
			add_child(row)
	# 未知カテゴリの拾い上げ
	for u in catalog.upgrades:
		var cat: String = catalog.category_of(str(u.get("id", "")))
		if not seen.has(cat) and not CATEGORY_LABEL.has(cat):
			seen[cat] = true
			_header(cat)
			for u2 in catalog.upgrades:
				if catalog.category_of(str(u2.get("id", ""))) == cat:
					add_child(_make_row(catalog, state, u2, str(u2.get("id", ""))))

func _rows_for_category(catalog: UpgradeCatalog, state: GameState, cat: String) -> Array:
	var out: Array = []
	for u in catalog.upgrades:
		var id: String = str(u.get("id", ""))
		if catalog.category_of(id) == cat:
			out.append(_make_row(catalog, state, u, id))
	return out

func _header(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	add_child(l)

func _make_row(catalog: UpgradeCatalog, state: GameState, u: Dictionary, id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var unlocked: bool = catalog.is_unlocked(state, id)
	var name_lbl := Label.new()
	name_lbl.text = "%s %s Lv%d" % [str(u.get("icon", "")), str(u.get("name", id)), state.upgrade_level(id)]
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not unlocked:
		name_lbl.modulate = Color(1, 1, 1, 0.4)
	row.add_child(name_lbl)

	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	if not unlocked:
		btn.text = "🔒"
		btn.disabled = true
		btn.tooltip_text = "解放条件未達"
	elif catalog.is_maxed(state, id):
		btn.text = "MAX"
		btn.disabled = true
	else:
		btn.text = "💰%d" % catalog.cost_for(state, id)
		btn.disabled = not catalog.can_buy(state, id)
		btn.pressed.connect(func(): buy_requested.emit(id))
	row.add_child(btn)
	return row
