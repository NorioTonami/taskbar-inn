class_name GameState
extends RefCounted
# game_state.gd — 状態の単一の真実（v0.3）。
# 純粋データのみを保持し、ロジックは持たない。
# 永続化は to_dict()/from_dict() 経由で save_manager が行う。

# 汚れメーターの上限（規模で増える）
const DIRTY_CAP_BASE: int = 30
const DIRTY_CAP_PER_CAPACITY: int = 10
# 食材在庫の上限（規模で増える）
const FOOD_CAP_BASE: int = 15
const FOOD_CAP_PER_CAPACITY: int = 5

var gold: int = 50
var reputation: int = 0
var level: int = 1

var rooms: int = 2
var comfort: int = 1
var food: int = 1
var cleanliness: int = 1
var security: int = 0

var guest_count: int = 0
var guest_capacity: int = 2

var dirtiness: float = 0.0                # 0 .. dirty_cap()
var food_stock: float = 0.0               # 0 .. food_cap()（階層②以降）
var service_rank: int = 1                 # サービス階層（1=素泊まり, 2=食事つき, ...）

var total_guests: int = 0
var total_gold_earned: int = 0
var guest_type_counts: Dictionary = {}

var unlocked_upgrades: Array[String] = []
var upgrade_levels: Dictionary = {}        # id:String -> level:int
var tool_levels: Dictionary = {}           # tool_id:String -> level:int

var skills: Dictionary = {}                # skill_id -> {"level":int, "xp":float}
var staff: Array = []                       # [{role_id, name, level:int, xp:float, assigned:bool}]
var placement_slots: int = 0               # 配置可能なスタッフ数（初期0 → チュートリアルで解放）
var active_work: String = ""               # 手動で訓練中のスキルid（""=なし）
var tutorial_slot_unlocked: bool = false

var badges: Array[String] = []
var titles: Array[String] = []

var event_log: Array = []                  # 直近 MAX_LOG 件（新しいものが末尾）
const MAX_LOG: int = 50

var last_saved_at: int = 0

# --- 派生 ---
func dirty_cap() -> int:
	return DIRTY_CAP_BASE + guest_capacity * DIRTY_CAP_PER_CAPACITY

func food_cap() -> int:
	return FOOD_CAP_BASE + guest_capacity * FOOD_CAP_PER_CAPACITY

# --- ログ / 客 ---
func add_log(text: String) -> void:
	event_log.append(text)
	if event_log.size() > MAX_LOG:
		event_log = event_log.slice(event_log.size() - MAX_LOG, event_log.size())

func get_count(type_id: String) -> int:
	return int(guest_type_counts.get(type_id, 0))

func add_guest_count(type_id: String, n: int = 1) -> void:
	guest_type_counts[type_id] = get_count(type_id) + n

# --- アップグレード / 道具 ---
func upgrade_level(id: String) -> int:
	return int(upgrade_levels.get(id, 0))

func tool_level(id: String) -> int:
	return int(tool_levels.get(id, 0))

# --- スキル ---
func _ensure_skill(id: String) -> void:
	if not skills.has(id):
		skills[id] = {"level": 1, "xp": 0.0}

func skill_level(id: String) -> int:
	if not skills.has(id):
		return 0
	return int(skills[id].get("level", 1))

func skill_xp(id: String) -> float:
	if not skills.has(id):
		return 0.0
	return float(skills[id].get("xp", 0.0))

# --- スタッフ ---
func staff_count() -> int:
	return staff.size()

func assigned_staff_count() -> int:
	var n: int = 0
	for s in staff:
		if bool(s.get("assigned", false)):
			n += 1
	return n

# --- 永続化 ---
func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"reputation": reputation,
		"level": level,
		"rooms": rooms,
		"comfort": comfort,
		"food": food,
		"cleanliness": cleanliness,
		"security": security,
		"guest_count": guest_count,
		"guest_capacity": guest_capacity,
		"dirtiness": dirtiness,
		"food_stock": food_stock,
		"service_rank": service_rank,
		"total_guests": total_guests,
		"total_gold_earned": total_gold_earned,
		"guest_type_counts": guest_type_counts,
		"unlocked_upgrades": unlocked_upgrades,
		"upgrade_levels": upgrade_levels,
		"tool_levels": tool_levels,
		"skills": skills,
		"staff": staff,
		"placement_slots": placement_slots,
		"active_work": active_work,
		"tutorial_slot_unlocked": tutorial_slot_unlocked,
		"badges": badges,
		"titles": titles,
		"event_log": event_log,
		"last_saved_at": last_saved_at,
	}

func from_dict(d: Dictionary) -> void:
	gold = int(d.get("gold", gold))
	reputation = int(d.get("reputation", reputation))
	level = int(d.get("level", level))
	rooms = int(d.get("rooms", rooms))
	comfort = int(d.get("comfort", comfort))
	food = int(d.get("food", food))
	cleanliness = int(d.get("cleanliness", cleanliness))
	security = int(d.get("security", security))
	guest_count = int(d.get("guest_count", guest_count))
	guest_capacity = int(d.get("guest_capacity", guest_capacity))
	dirtiness = float(d.get("dirtiness", dirtiness))
	food_stock = float(d.get("food_stock", food_stock))
	service_rank = int(d.get("service_rank", service_rank))
	total_guests = int(d.get("total_guests", total_guests))
	total_gold_earned = int(d.get("total_gold_earned", total_gold_earned))
	guest_type_counts = (d.get("guest_type_counts", {}) as Dictionary).duplicate(true)
	upgrade_levels = (d.get("upgrade_levels", {}) as Dictionary).duplicate(true)
	tool_levels = (d.get("tool_levels", {}) as Dictionary).duplicate(true)
	skills = (d.get("skills", {}) as Dictionary).duplicate(true)
	staff = (d.get("staff", []) as Array).duplicate(true)
	placement_slots = int(d.get("placement_slots", placement_slots))
	active_work = str(d.get("active_work", active_work))
	tutorial_slot_unlocked = bool(d.get("tutorial_slot_unlocked", tutorial_slot_unlocked))
	last_saved_at = int(d.get("last_saved_at", 0))
	# 型付き配列へはコピーして格納する
	unlocked_upgrades.clear()
	for v in d.get("unlocked_upgrades", []):
		unlocked_upgrades.append(str(v))
	badges.clear()
	for v in d.get("badges", []):
		badges.append(str(v))
	titles.clear()
	for v in d.get("titles", []):
		titles.append(str(v))
	event_log = (d.get("event_log", []) as Array).duplicate()
