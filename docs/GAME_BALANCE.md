# GAME_BALANCE.md — 数値の根拠メモ（v0.3 / 計算式の正本）

「正確さより、設備・スタッフ・階層・モードで体感が変わること」を優先。
本書はマイルストーンA（素泊まり階層）の数値を確定する。B以降は追補する。

## 共通定数（inn_simulator.gd）
```
TICK_SECONDS          = 1.0
BASE_PRICE            = 5
DEPART_PROB           = 0.15    # 毎秒の退室確率
REP_GAIN_BASE         = 0.02    # (cleanliness+food) あたりの毎秒評判
EVENT_PROB_PER_SEC    = 0.20
OFFLINE_CAP_SECONDS   = 28800   # 8時間
```

## 汚れメーター（dirtiness）
```
dirty_cap          = 30 + guest_capacity * 10        # capacity2 → 50
DIRTY_PER_GUEST    = 2.0                              # 宿泊1回ごと加算（家族は人数倍：B）
REP_THRESH_FRAC    = 0.60   # 汚れが cap*0.6 超で評判の伸び half
RATE_THRESH_FRAC   = 0.80   # 汚れが cap*0.8 超で集客率が低下し、cap で 0.2 倍
```
意図：素泊まり(cap50)はすぐ汚れるが掃除範囲も狭い。規模拡大で cap が上がり、
手動清掃だけでは追いつかなくなり**スタッフ自動化が必須**になる。

集客の汚れ係数：
```
if dirtiness < 0.8*cap: 1.0
else: lerp(1.0 → 0.2, (dirtiness-0.8*cap)/(0.2*cap))
```
評判の汚れ係数：`dirtiness > 0.6*cap なら 0.5、それ以外 1.0`。

## 来訪率・価格・評判
```
base_guest_rate = rooms*0.4 + reputation*0.05
guest_rate      = base_guest_rate * dirt_rate_factor   # （B: ×営業モード×広告）
到着確率 p      = clamp(guest_rate, 0, 1)   （capacity 未満時のみ）

price = (BASE_PRICE + comfort*2 + food*2 + cleanliness) * type.base_price_multiplier
        を四捨五入 int 化（dev: price_mult を乗算）

rep_per_sec = (cleanliness+food) * REP_GAIN_BASE * dirt_rep_factor
小数を累積し整数を超えた分を reputation に加算
```

## プレイヤースキル（清掃）— skills.json
```
cleaning: base_effect=2, effect_per_level=1, cooldown_sec=5,
          xp_per_action=4, xp_base=10, xp_growth=1.35
manual_effect = base_effect + skill_lv*effect_per_level + player_tool_bonus
xp_to_next(lv) = round(xp_base * xp_growth^lv)
```
アクティブ作業：選択中スキルを 5 秒ごとに1回実行＝汚れ −manual_effect、XP +4。
汚れが 0 の場合、清掃は自動で休憩に戻る。

## 設備による手動クールダウン短縮
道具は「1回あたりの効果量」を増やし、基礎設備は「1回あたりの所要時間」を短くする。
スタッフ自動作業のクールダウンはこの補正の対象外。

対応関係：
```
cleaning   -> cleaning_gear（清掃用具）
cooking    -> kitchen（厨房）
harvesting -> field（畑）
```

設備Lvごとの固定倍率：
```
Lv0  1.00
Lv1  0.90
Lv2  0.80
Lv3  0.72
Lv4  0.66
Lv5+ 0.60
```

```
effective_cooldown = skills.json.cooldown_sec * cooldown_multiplier
```
例：基礎5秒の作業は、対応設備Lv2で4.0秒、Lv5以上で3.0秒になる。

## 宿Lv2〜Lv3・調理・収穫・もてなし（暫定）
```
宿Lv2 meals unlock = total_guests >= 10
                    reputation >= 20
                    skill.cleaning >= 2
                    upgrade.room_plus >= 2

宿Lv3 farmstead unlock = total_guests >= 40
                        reputation >= 60
                        skill.cooking >= 3
                        action.cooking >= 20
                        upgrade.kitchen >= 2

cooking: base_effect=3, effect_per_level=1, cooldown_sec=5,
         xp_per_action=4, xp_base=10, xp_growth=1.35
         target=stock, affects=meal_stocks

harvesting: base_effect=2, effect_per_level=1, cooldown_sec=5,
            xp_per_action=4, xp_base=10, xp_growth=1.35
            target=stock, affects=vegetable_stock

hospitality: base_effect=1, effect_per_level=0, cooldown_sec=8,
             xp_per_action=3, xp_base=12, xp_growth=1.4
             target=stat, affects=reputation
```
調理済みは `meal_stocks`（basic/standard/good/luxury/specialty/vip）へ保存する。
旧 `food_stock` は互換フィールドとして合計調理済み在庫と同期する。
調理は調理済みが `meal_storage_capacity()` に達している場合、自動で休憩に戻る。

Lv2 から収穫/畑/野菜在庫を解放し、`vegetable_stock` または
`generic_ingredient_stock`（UI表示は食材パック）を消費して調理済みを作る。
野菜も食材パックも無い場合、調理は開始できない。食材パックは basic/standard/good までの
詰み防止補助で、完全自動補充はしない。

料理ランクの仮解放：
```
kitchen Lv1 => basic
kitchen Lv2 => standard
kitchen Lv3+ => good
cooking Lv が足りない場合は一段下がる
```
もてなしは本来「短時間バフ」候補だが、現時点ではゲーム内で押せる攻めの作業として
reputation +1 の暫定効果にしている。

食材保管：
```
meal_storage_capacity      = 12 + guest_capacity*4 + meal_storage Lv*8
vegetable_cap              = 10 + food_storage Lv*8 + field Lv*6 + vegetable_storage Lv*10
generic_ingredient_cap     = 8 + food_storage Lv*6
```
Lv3 は収穫の初解放ではなく、自給体制の拡張・安定化、農夫/自動収穫の前段階として扱う。

## スタッフ（清掃係）— staff_roles.json
```
cleaner: base_auto_effect=1, effect_per_level=1, cooldown_sec=6,
         hire_cost=80, cost_growth=1.7, reputation_req=0,
         xp_per_action=3, xp_base=10, xp_growth=1.4
auto_effect = base_auto_effect + staff_lv*effect_per_level + staff_tool_bonus
初期スキル Lv = clamp(1 + floor(reputation/20), 1, 8)   # 評判帯で人材の質が上がる
雇用コスト    = hire_cost * cost_growth^(同職の雇用済み人数)
```
**雇用直後**：auto(=1+1)≈2/6秒 ≒ 0.33/秒 < 手動(=2+…)/5秒。育成で逆転する。

## 道具（tools.json・2系統）
```
player_cleaning（手動効率↑）  tiers bonus [0,1,2,3,4]  cost [-,50,150,400,1000]
staff_cleaning （自動効率↑）  tiers bonus [0,1,2,3,4]  cost [-,120,350,900,2200]
                # スタッフ用は1個で全スタッフ共用
```
UI 上は仕事ページから分離し、`道具` ページで購入する。

## 配置枠・チュートリアル
```
placement_slots 初期 = 0
TUTORIAL_GUESTS = 5  → 累計5人宿泊でスタッフ詰め所が設備に解放
スタッフ詰め所購入で placement_slots +1。以後の枠拡張も設備/評判で行う
```

## オフライン集計（apply_offline）
```
sec = clamp(now - last_saved_at, 0, OFFLINE_CAP_SECONDS)
p   = clamp(guest_rate(clean), 0, 1)
arrivals = int(sec * p * 0.4)                         # 稼働率＋汚れドラッグで控えめ
gold    += arrivals * avg_price ; reputation += int(rep_per_sec*sec*0.5)
# 留守中の汚れ収支
dirt_added   = arrivals * DIRTY_PER_GUEST
dirt_cleaned = Σ(staff auto_effect / cooldown) * sec
dirtiness    = clamp(dirtiness + dirt_added - dirt_cleaned, 0, dirty_cap)
結果（客/売上/評判/汚れ現況/イベント数）をトースト表示
```
→ スタッフ無しなら戻ったとき汚れ満杯＝**再ログイン片付けルーティン**が発生。

## dev（dev_config.json）
```
dev_mode  : bool   # false でデバッグ機能を無効化（リリース）
time_scale: int    # 1/10/60。1実ティックで simulator.tick() を time_scale 回実行
price_mult: float  # 清算料金の倍率
```
デバッグオーバーレイ（F9）：gold/評判/汚れ/枠の操作、5人宿泊強制、セーブリセット。
