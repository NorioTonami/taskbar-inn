# AI_DEV_GUIDE.md — コーディング規約

## 原則
- **コードファースト**: UI・ノードツリーは `.gd` の `_ready()` でコード生成する。
  `.tscn` は `main.tscn` 1つだけ（ルート Node + main.gd のアタッチのみ）。
- **1 機能 1 ファイル**。マネージャ系は単一責務。
- **UI はスナップショットを読むだけ**。状態変更は必ずマネージャ経由で `game_state` を更新。
- **静的型注釈を必須化**（`var gold: int = 0`）。型エラーを早期に検出する。
- **マジックナンバーは JSON か定数へ**。バランス値は `data/*.json`。
- 各 `.gd` 冒頭に 3〜5 行の責務コメントを置く。

## 構造
- `game_state.gd`: 状態の単一の真実。純粋データ + to_dict/from_dict。ロジックを持たない。
- `inn_simulator.gd`: tick 計算。UI 非依存。マネージャを束ねて毎秒評価。
- 各 `*_manager.gd` / `*_catalog.gd`: JSON 読込と該当ドメインの処理。
- `ui/*.gd`: 描画と入力のみ。シグナルでマネージャ呼び出し。

## シグナル / 更新フロー
- main.gd が game_state と各マネージャを生成し保持。
- 1秒 Timer → inn_simulator.tick() → game_state 更新 → UI に `refresh(snapshot)` 通知。
- UI から購入/方針変更等は main.gd 経由でマネージャを呼ぶ。

## JSON 読込
- `FileAccess.get_file_as_string("res://data/xxx.json")` → `JSON.parse_string()`。
- 読込失敗は push_error して空配列/空辞書にフォールバック（起動は止めない）。

## 検証
- 各 .gd 追加時:
  `godot.exe --headless --check-only --script scripts/<file>.gd`
- フェーズ末:
  `godot.exe --headless --path . --quit`（パースエラー無しを確認）。
- エラーが出たら次フェーズに進まない。

### class_name 追加・削除時のキャッシュ再生成
`class_name` 付きスクリプトを新規追加・削除すると `.godot/global_script_class_cache.cfg`
が古くなり、他ファイルの参照箇所で `Parse Error: Could not find type "X"` が連鎖して
起動失敗する（個別 `--check-only` でも再現）。検証前にエディタスキャンで再生成する：
```
godot.exe --headless --editor --quit     # または --import
```
その後に通常の `--headless --path . --quit` を流す。

### リーク監査（idle 系なので回帰しうる）
`extends SceneTree` の一時スクリプトを書き、`_process` で毎フレーム
`sim.tick()` と `expanded.refresh(state)`（管理画面を開きっぱなしの最悪ケース）を回し、
`Performance.get_monitor()` で OBJECT_COUNT / OBJECT_NODE_COUNT /
OBJECT_ORPHAN_NODE_COUNT / MEMORY_STATIC を定期サンプルする。
```
godot.exe --headless --path . --script scripts/_audit.gd
```
判定: object/node/orphan が横ばい＆ orphan=0 ならリーク無し
（static_mem の微増はアロケータ高水位で、単調増加でなければ問題なし）。
- baseline（2026-06）: 2400 フレームで objects 2036 / nodes 235 / orphans 0 で完全横ばい
  ＝ロジックにリーク無し。expanded.refresh が毎秒 queue_free＋再生成しても解放漏れ無し。
- 将来の最適化候補: expanded.refresh の毎秒フル再構築（queue_free＋再生成）を
  ラベル更新方式へ置き換える。

## 命名
- ファイル: snake_case。クラス: 必要なら `class_name PascalCase`。
- 関数/変数: snake_case。定数: UPPER_SNAKE。
- シグナル: 過去形 or 名詞（例 `state_changed`）。
