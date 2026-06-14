# SETUP.md — 起動方法・環境構築・既知の注意点

MVP 動作確認までに判明した起動手順と落とし穴をまとめる。詰まったらまずここを見る。

## 起動方法

### 推奨：run.bat をダブルクリック
リポジトリ直下の `run.bat` をダブルクリックすると小窓ゲームが起動する。
- 初回だけ class_name キャッシュ生成のため自動でインポートを実行する。
- 2 回目以降はキャッシュがあるので即起動。

### 手動（PowerShell）
```
& "C:\Users\Tonami\Desktop\gamedev\engines\godot\4.6.3\godot.exe" --path "C:\Users\Tonami\Desktop\gamedev\taskbar-inn"
```
このセッションのプロンプトでは行頭に `!` を付けると実行できる。

### headless 検証
```
"...\godot.exe" --headless --path . --quit            # パースチェック
"...\godot.exe" --headless --path . --quit-after 400  # 数 tick 走らせる
```

## 既知の落とし穴（MVP で実際に踏んだもの）

### 1. class_name はインポートしないと未登録（起動時パースエラー）
クローン直後など `.godot/global_script_class_cache.cfg` が無い状態だと、
`Could not find type "..."` が多発して起動できない。一度インポートすれば解消：
```
"...\godot.exe" --headless --path . --import
```
`run.bat` はこのキャッシュの有無を見て、無ければ自動でインポートする。

### 2. .bat は ASCII のみ（cmd.exe は CP932 で解釈する）
`run.bat` を UTF-8（日本語コメント入り）で保存すると、日本語 Windows の cmd.exe が
CP932 でバイト列を誤読し、`--headless` や `errorlevel`・godot 起動行まで壊れて
「一瞬で消える」状態になる（ログが `'・繝ｼ繝医ｒ螳溯｡後☆繧九・'` のように文字化けする）。
→ **バッチファイルのコメント・メッセージは英語（ASCII）のみにする。**
ゲーム内文字列は GDScript/JSON 側にあるので日本語のままで問題ない。

### 3. パス末尾のバックスラッシュがクォートを壊す
`%~dp0` は末尾 `\` 付きを返すため、`--path "...\taskbar-inn\"` の `\"` が
エスケープ扱いになり `Invalid project path` で即終了する。
→ `run.bat` は末尾 `\` を除去してから `--path` に渡している。
   `set "PROJ=%~dp0"` の後に `if "%PROJ:~-1%"=="\" set "PROJ=%PROJ:~0,-1%"`。

### 4. 小窓が見つからない（マルチモニタ）
compact は borderless・420x64・**プライマリモニタの右下（タスクバーのすぐ上）**に出る。
マルチモニタ環境（仮想画面が負座標から始まる等）では別モニタを見ていて気づきにくい。
位置・サイズは `scripts/window_manager.gd` の `COMPACT_SIZE` / `_place_bottom_right` で調整可。

## 常駐パフォーマンス（適用済み）
極小・常時手前ウィンドウを常時フル描画すると CPU/GPU を食うため、`project.godot` に
省電力設定を入れてある：
```
application/run/low_processor_mode=true
application/run/low_processor_mode_sleep_usec=16000
application/run/max_fps=30
```
これ以上詰めるなら expanded.refresh の毎秒フル再構築をラベル更新方式へ変える
（詳細は AI_DEV_GUIDE.md「リーク監査」末尾）。

## 操作
- 📋 ボタン：管理画面（expanded）を開く / 「✕ 閉じる」で小窓に戻る。
- **ウィンドウ移動：ボタン以外の余白をドラッグ**（枠なしのため。`main.gd` の
  `_unhandled_input` で実装。ボタン/タブ/スクロールは消費するのでドラッグにならない）。
- 終了：Alt+F4（終了時に自動セーブ）。

## セーブデータ
`user://savegame.json` =
`%APPDATA%\Godot\app_userdata\Taskbar Inn\savegame.json`。
約 15 秒ごと + 終了時に自動保存。最初からやり直すにはこのファイルを削除する。
