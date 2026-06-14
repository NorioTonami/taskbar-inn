# AGENTS.md — Taskbar Inn 開発指示書 (auto mode)

このファイルは Codex が **auto mode で自走** するための環境・プロセスの正本です。
作業前に必ず全体を読み、`docs/ROADMAP.md` のフェーズ順に着手すること。

> **【重要・v0.3 で抜本改訂】ゲーム設計の正本は `docs/SPEC.md`（v0.3）に移行した。**
> 本ファイルの §3〜§8（v0.2 の方針 style 分岐・客タイプ・アップグレード等の**ゲーム内容**）は
> **歴史的経緯として残すが、設計としては SPEC.md / GAME_BALANCE.md / ROADMAP.md が優先する**。
> v0.3 はタスクバー常駐の incremental 宿経営（最前線を手動→スタッフで自動化→次の階層へ）。
> 方針 style システムと厩舎は撤去。数値は GAME_BALANCE.md、着手順は ROADMAP.md（マイルストーンA→B）。
> 本ファイルで今も有効なのは **§0(前提)・§1(環境)・§2(構成の原則)・§9(規約)・§10(着手順の運用)**。

---

## 0. このプロジェクトの最重要前提（必読）

**Godot エディタは使えない。Codex はファイル生成・編集と CLI 実行しかできない。**

したがって以下を絶対に守る：

1. **コードファースト構築**：UI レイアウトもノードツリーも、原則 `.gd` スクリプトの `_ready()` 内で
   コードから動的生成する。`.tscn` は「ルートノードと該当スクリプトのアタッチ」だけの最小構成にする。
   複雑なシーンツリーを `.tscn` に手書きしない（壊れやすく検証できないため）。
2. **検証は headless CLI で行う**：各フェーズ完了時に、プロジェクトが
   パースエラーなく起動するかを必ず確認する。Godot 実行ファイルは下記に存在する：
   ```
   C:\Users\Tonami\Desktop\gamedev\engines\godot\4.6.3\godot.exe
   ```
   検証コマンド（リポジトリ直下で実行）：
   ```
   "C:\Users\Tonami\Desktop\gamedev\engines\godot\4.6.3\godot.exe" --headless --path . --quit
   ```
   - スクリプトのパースエラーを能動的に出すため、起動確認に加えて
     `--check-only` での GDScript 構文チェックも各 .gd 追加時に活用してよい：
     ```
     "C:\Users\Tonami\Desktop\gamedev\engines\godot\4.6.3\godot.exe" --headless --check-only --script scripts/<file>.gd
     ```
   - エラーが出たら次フェーズに進まず修正する。
   - 環境は **Godot 4.6.x（安定版）**。`project.godot` の機能タグは 4.6 に合わせる
     （`config/features=PackedStringArray("4.6", ...)`）。
   - Jolt が 4.6 で 3D 既定物理になったが、本作は 2D/UI のみなので物理は不使用。
3. **GDScript の静的型注釈を積極的に使う**（`var gold: int = 0` 等）。型エラーを早期に出すため。
4. **ゲームロジックを UI スクリプトに書かない**。シミュレーションは純粋な `.gd` クラスに閉じ込め、
   UI はそのスナップショットを読むだけにする（テスト容易性のため）。
5. **全ゲームデータは `data/*.json`**。アップグレード・客タイプ・方針・イベント・バッジ・称号は
   コードにハードコードせず JSON から読む。バランス調整を JSON 編集だけで完結させる。

---

## 1. ターゲット環境

- **エンジン**: Godot 4.6.x（GDScript）。`project.godot` は `config_version=5`、
  機能タグは `"4.6"`。実行ファイルは
  `C:\Users\Tonami\Desktop\gamedev\engines\godot\4.6.3\godot.exe`。
- **OS**: Windows（最終配布）。開発検証は headless で OK。
- **ウィンドウ**: 起動時は **compact view**（極小・常時手前・枠なし）。
  taskbar hero 的に「作業の傍らに常駐」する見た目を狙う。
  - `DisplayServer` / `Window` で以下を設定：
    `borderless = true`, `always_on_top = true`, 小サイズ（例 420x64）、
    起動位置は画面右下寄せ。
  - **透明ウィンドウ・トレイ常駐は v0.2 では実装しない**（設計案 §19 の非対象）。
    borderless + always on top + 小サイズで「常駐感」を出すに留める。
  - expanded view 切替時はウィンドウをリサイズ（例 560x520）して管理画面を出す。
    閉じると compact に戻る。

---

## 2. ディレクトリ構成（この通りに作る）

```
taskbar-inn/
  project.godot
  scenes/
    main.tscn              # ルート。main.gd をアタッチするだけ
  scripts/
    main.gd                # エントリ。ウィンドウ管理 + view 切替の統括
    window_manager.gd      # compact/expanded のウィンドウ設定・リサイズ
    game_state.gd          # 状態の単一の真実。純粋データ + load/save 用 dict 変換
    inn_simulator.gd       # tick ごとの計算（gold/guest/reputation）。UI 非依存
    guest_manager.gd       # 客タイプ抽選・カウント
    upgrade_catalog.gd     # upgrades.json 読込・購入・効果適用
    inn_style_manager.gd   # 方針の適用と補正
    event_manager.gd       # events.json 読込・発火・ログ
    badge_manager.gd       # badges.json 判定
    title_manager.gd       # titles.json 判定
    save_manager.gd        # user:// への保存/復元 + オフライン進行
    ui/
      compact_view.gd      # 小窓 UI をコード生成
      expanded_view.gd     # 管理画面 UI をコード生成
      upgrade_panel.gd
      event_log_panel.gd
      badge_panel.gd
      title_panel.gd
  data/
    upgrades.json
    guest_types.json
    inn_styles.json
    events.json
    badges.json
    titles.json
  docs/
    SPEC.md                # この AGENTS.md の要約 + 計算式の正本
    AI_DEV_GUIDE.md        # コーディング規約
    GAME_BALANCE.md        # 数値の根拠メモ
    ROADMAP.md             # フェーズ順タスク（着手順の正本）
```

`.tscn` は `main.tscn` の1つだけ。残りの UI は `ui/*.gd` がコードで生成し、
`main.gd` が必要に応じてインスタンス化・add_child する。

---

## 3. v0.2 完成条件（DoD / すべて満たすこと）

- [ ] Windows 上で小窓 Godot アプリとして起動する（compact view）
- [ ] compact ↔ expanded をボタンで切り替えられる（ウィンドウもリサイズ）
- [ ] 放置で gold / reputation / guest_count が増減する（1秒 tick）
- [ ] 客タイプが最低3種（旅人・商人・冒険者）
- [ ] アップグレードが最低8種（§5）
- [ ] 方針を3種から選べる（庶民宿・旅人宿・高級宿）
- [ ] 方針で客層・売上・評判の伸びが変わる
- [ ] イベントログが流れ、一部が数値に影響
- [ ] 宿の見た目がレベルまたは方針で少し変わる（絵文字/簡易図形で可）
- [ ] バッジが最低6個
- [ ] 到達称号が最低3種
- [ ] セーブ/ロード（`user://savegame.json`）
- [ ] オフライン進行（最大8時間）
- [ ] `godot --headless --path . --quit` がエラーなく通る

---

## 4. ゲーム状態（game_state.gd）

保持する変数（型付きで）：
```
gold:int, reputation:int, level:int
rooms:int, comfort:int, food:int, cleanliness:int, security:int
guest_count:int, guest_capacity:int
current_style:String                 # "common" | "traveler" | "luxury"
total_guests:int, total_gold_earned:int
guest_type_counts:Dictionary         # {"traveler":int,"merchant":int,"adventurer":int}
unlocked_upgrades:Array[String]
badges:Array[String]
titles:Array[String]
event_log:Array                      # 直近 N 件（例 50）を保持
last_saved_at:int                    # Unix 時刻
```
`to_dict()` / `from_dict()` を用意し、save_manager はこれ経由で永続化する。
`security` は将来の冒険者宿用。v0.2 では値だけ持ち、軽い補正に使ってよい。

初期値の例：gold=50, reputation=0, level=1, rooms=2, comfort=1, food=1,
cleanliness=1, security=0, guest_capacity=2, current_style="traveler"。

---

## 5. データ仕様（data/*.json）

### upgrades.json（最低8種）
各要素：`id, name, icon, cost, cost_growth, effects{stat:delta}, max_level?`
```
room_plus      最大客数 +1 (guest_capacity +1)
bedding        comfort +1
kitchen        food +1
cleaning       cleanliness +1
signboard      guest_rate +1（看板）
fireplace      comfort +1（冬の雰囲気）
stable         商人・旅人来訪率アップ
garden         reputation_gain アップ
```
購入で `unlocked_upgrades` に id を追加。同一 id を再購入でレベルアップ可（cost_growth 適用）。

### guest_types.json（最低3種）
```json
[
  {"id":"traveler","name":"旅人","icon":"🧳","base_price_multiplier":1.0,
   "requires":{},"preferred_styles":["common","traveler"],"weight":50},
  {"id":"merchant","name":"商人","icon":"💰","base_price_multiplier":1.4,
   "requires":{"comfort":3},"preferred_styles":["traveler","luxury"],"weight":30},
  {"id":"adventurer","name":"冒険者","icon":"🗡️","base_price_multiplier":1.3,
   "requires":{},"preferred_styles":["traveler","common"],"weight":20,
   "event_bias":0.15}
]
```
余裕があれば4種目「巡礼者」（清潔・料理重視、評判が上がりやすい）。

### inn_styles.json（3種）
```json
[
  {"id":"common","name":"庶民宿","guest_rate_mult":1.25,"price_mult":0.90,
   "reputation_gain_mult":1.2},
  {"id":"traveler","name":"旅人宿","guest_rate_mult":1.10,"price_mult":1.10,
   "reputation_gain_mult":1.0},
  {"id":"luxury","name":"高級宿","guest_rate_mult":0.75,"price_mult":1.70,
   "reputation_gain_mult":0.9,"comfort_req":3}
]
```

### events.json
各要素：`id, type(positive|minor_negative|guest), text, effects{}`、出現条件 `cond?`。
例：
```
guest    "旅人が一晩泊まっていきました"           gold +bonus
positive "清掃が行き届いていて評判が上がりました"  reputation +1   cond: cleanliness>=3
positive "商人が朝食を気に入ったようです"          reputation +1   cond: food>=3
minor_negative "寝具が古く、少し評価が下がりました" reputation -1  cond: comfort<=1
guest    "看板を見た客が立ち寄りました"            guest_count +1  cond: has signboard
guest    "部屋が満室になりました"                  -               cond: guest_count>=capacity
```

### badges.json（最低6個）
```
first_guest      はじめてのお客        total_guests>=1
full_house       満室の夜              guest_count>=guest_capacity
proud_kitchen    料理自慢              food>=5
clean_inn        清潔な宿              cleanliness>=5
travelers_perch  旅人たちの止まり木     guest_type_counts.traveler>=20
talk_of_town     町で噂の宿            reputation>=30
```
余裕があれば `merchant_favorite`（商人累計10）, `luxury_first_step`。

### titles.json（最低3種）
```
beloved_inn   町で愛される宿  style==common  AND reputation>=40 AND total_guests>=100
highway_inn   街道の名宿      style==traveler AND guest_type_counts.traveler>=60 AND comfort>=5
small_luxury  小さな高級宿    style==luxury  AND gold>=5000 AND comfort>=8
```
達成時はゲーム終了ではなく「称号を獲得しました」をログ＋トースト表示するだけ。

---

## 6. 計算モデル（inn_simulator.gd / 正本は docs/GAME_BALANCE.md）

1秒 tick ごとに評価：
```
base_guest_rate = rooms * 0.4 + reputation * 0.05
guest_rate      = base_guest_rate * style.guest_rate_mult * (1 + signboard_bonus)

# 客の到着（確率的）。capacity 未満のときだけ受け入れる
on_arrival:
    type = weighted_pick(guest_types, requires/preferred_styles を考慮)
    guest_type_counts[type] += 1
    total_guests += 1
    guest_count = min(guest_count + 1, guest_capacity)

price = (base_price + comfort*2 + food*2 + cleanliness)
        * type.base_price_multiplier
        * style.price_mult
gold += price ; total_gold_earned += price

reputation の伸び = f(cleanliness, food) * style.reputation_gain_mult （緩やかに）
退室で guest_count を時々減らし回転させる
```
**正確さより「方針・客タイプで体感が変わる」ことを優先**（設計案 §13）。
tick とは別に毎秒 badge_manager / title_manager の判定を回す。

---

## 7. オフライン進行（save_manager.gd）

- 終了/保存時に `last_saved_at = Time.get_unix_time_from_system()`。
- 起動時に差分秒を計算、**最大 8 時間 (28800 秒) でクランプ**。
- その間の tick をまとめて概算適用（ループでなく集計式で軽く）。
- compact 起動直後に expanded を一瞬出すか、トーストで結果表示：
  ```
  留守中の営業結果
  宿泊客: 18人 / 売上: 620G / 評判: +3 / イベント: 2件
  ```

---

## 8. 私（人間）が足した「おもしろさの継ぎ足し」（設計案を超える微調整）

設計案は数値増加が淡白になりがち。破綻しない範囲で以下を**必須で**入れる：

1. **看板の口コミ表示**：客が来た時に compact view に短い吹き出し
   （例「いい宿だ」「料理が旨い」）を 1.5 秒だけ出す。客タイプ別に台詞を 2〜3 個
   持たせる（events.json とは別の軽い flavor 配列でよい）。**生きてる感**の核。
2. **方針変更にクールダウン**：方針はいつでも変えられるが、変更直後 60 秒は
   reputation の伸びが半減する「客が戸惑っている」演出。コロコロ変える戦略を抑制し
   選択に重みを出す。ログに「宿の方針が変わり、常連が少し様子見しています」。
3. **満室ボーナス**：guest_count == capacity が一定時間続くと
   「賑わい」状態になり price と reputation_gain が +15%。capacity を上げる動機づけ。

この 3 つ以外は設計案を増築しない（§19 の非対象は厳守）。

---

## 9. コーディング規約（docs/AI_DEV_GUIDE.md に転記）

- 1 機能 1 ファイル。マネージャ系は単一責務。
- UI は `game_state` のスナップショットを読むだけ。状態変更は必ずマネージャ経由。
- マジックナンバーは JSON か定数へ。
- 各 `.gd` 冒頭に 3〜5 行の責務コメント。
- フェーズ完了ごとに headless 起動確認 → docs/ROADMAP.md の該当チェックを更新。
- コミット単位はフェーズ単位（自走中も `docs/ROADMAP.md` を進捗台帳として使う）。

---

## 10. 着手順

`docs/ROADMAP.md` の Phase 0 → 9 を順に。各フェーズ末で DoD 部分確認と headless 起動チェック。
Phase 0（仕様 + JSON 定義）を最初に完了させてから実装に入ること。
