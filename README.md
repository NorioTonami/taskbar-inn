# Taskbar Inn

タスクバー脇に常駐する極小ウィンドウの放置型・宿屋経営ゲーム（Godot 4.6 / GDScript）。
小窓（compact view）で常駐し、📋 ボタンで管理画面（expanded view）を開いて
設備投資・方針選択を行う。放置しても客が訪れ、gold・評判・宿泊客が増えていく。

## 必要環境
- Godot 4.6.x（検証は 4.6.3 stable）
  実行ファイル例: `C:\Users\Tonami\Desktop\gamedev\engines\godot\4.6.3\godot.exe`
- Windows（最終配布）。検証は headless で可。

## 実行方法

### 通常起動（小窓 GUI）— 推奨
リポジトリ直下の **`run.bat` をダブルクリック**。初回はクラスキャッシュを自動生成して起動する。
コマンドで起動する場合:
```
"C:\Users\Tonami\Desktop\gamedev\engines\godot\4.6.3\godot.exe" --path .
```
起動すると画面右下に枠なし・常時手前の小窓が出る（マルチモニタ時はプライマリの右下）。
- 📋 ボタン: 管理画面（expanded）を開く
- 管理画面の「✕ 閉じる」: 小窓に戻る
- **ウィンドウ移動: ボタン以外の余白をドラッグ**
- 終了: Alt+F4（終了時に自動セーブ）

> 起動手順・既知の落とし穴（class_name インポート、.bat の文字コード等）の詳細は
> `docs/SETUP.md` を参照。

### 初回インポート（class_name キャッシュ生成）
クローン直後など、`class_name` が未登録だと起動時にパースエラーが出る。
一度だけインポートを実行してグローバルクラスキャッシュを作る:
```
"C:\Users\Tonami\Desktop\gamedev\engines\godot\4.6.3\godot.exe" --headless --path . --import
```

### headless 起動チェック（CI / 検証）
```
"C:\Users\Tonami\Desktop\gamedev\engines\godot\4.6.3\godot.exe" --headless --path . --quit
```
エラーが出なければパース OK。数 tick 走らせて確認したい場合:
```
"...\godot.exe" --headless --path . --quit-after 400
```

## 遊び方の要点
- **方針（庶民宿 / 旅人宿 / 高級宿）** で客層・売上・評判の伸びが変わる。
  高級宿は comfort 3 以上で解禁。方針変更直後 60 秒は常連が様子見し評判の伸びが半減。
- **アップグレード**（客室・寝具・厨房・清掃・看板・暖炉・厩舎・庭園）で
  収容人数・快適さ・料理・清潔・来訪率・評判を強化。再購入でレベルアップ（コスト逓増）。
- **満室が 10 秒続くと「賑わい」**になり、売上と評判が +15%。
- **客タイプ**（旅人・商人・冒険者・巡礼者）ごとに単価と来訪条件・台詞が異なる。
- **バッジ 8 種・称号 3 種**を条件達成で獲得（トースト表示）。
- **オフライン進行**: 終了中の営業を最大 8 時間ぶん集計し、起動時に結果をトースト表示。

## セーブデータ
`user://savegame.json`（Windows では
`%APPDATA%\Godot\app_userdata\Taskbar Inn\savegame.json`）。
約 15 秒ごとと終了時に自動保存。削除すれば最初から。

## プロジェクト構成
- `scenes/main.tscn` … 唯一のシーン（ルート + `main.gd`）
- `scripts/` … ロジック（マネージャ系）と UI（`ui/`）。UI もコードで動的生成
- `data/*.json` … 全ゲームデータ（バランスは JSON 編集で調整可能）
- `docs/` … SPEC / GAME_BALANCE / AI_DEV_GUIDE / ROADMAP（仕様と進捗の正本）

詳細仕様は `docs/SPEC.md`、数値根拠は `docs/GAME_BALANCE.md` を参照。
