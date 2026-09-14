# 武鬥台灣魂 / Taiwan Fighter — Godot 0.2

Kai vs Lucy 的 production parity benchmark。可玩 CPU、同機雙人、Story、Training；目的是評估正式重構可行性，並非宣布已追平 Phaser 或決定遷移。

## 開始遊玩

此 repo 刻意不包含 Godot executable、export template 或已輸出的 Windows／Web build。clone 後先執行 `powershell -File tools/setup.ps1` 下載官方 Godot 4.5.2；要重新 export 時，依 [Web export 文件](docs/WEB_EXPORT.md) 安裝同版本官方 export templates。

- 目前專案：雙擊根目錄 Play.cmd。
- 可攜 Windows／Web export 是本機驗證產物，不隨 repo 發布；可按 tools/package.ps1、tools/export_web.ps1 與 docs/WEB_EXPORT.md 重建。不能直接雙擊 Web 的 index.html。
- Godot 編輯：tools/run.ps1 -Editor。

## 操作

| 動作 | P1 | P2 |
|---|---|---|
| 走／退 | A / D | 左／右方向鍵 |
| 蹲／跳 | S / W | 下／上方向鍵 |
| 拳／腳（依站、蹲、空中） | J / K | 數字鍵盤 1 / 2 |
| Command normal | 前＋K | 前＋數字鍵盤 2 |
| 必殺 I / II | U / I，或 236＋J/K | 數字鍵盤 4 / 5 |
| Super / Awakening | O / L，或 236236＋J/K | 數字鍵盤 6 / 3 |
| 防禦 | 空白鍵；蹲下可防下段 | 數字鍵盤 0 |
| 衝刺 | Shift＋方向 | 數字鍵盤 7＋方向 |

Enter 開始／下一回合／重賽，Esc 暫停，R 重開，F1 說明，Tab 招式表，F2 判定與 FPS，F3 減少動態，F4 切換虛擬按鈕，M 靜音。數字鍵盤建議 Num Lock 開啟。

Training：R 重置；F5 切 dummy idle/guard；F6 切無限氣；F7 比較 Kai 骨架。左側「訓練設定」可展開回血與其他開關。骨架是可評估的實驗模式，預設仍為完整 raster 動作。

手把：左搖桿／D-pad 移動，D-pad 上跳、下蹲，A 拳、X 腳、Y 必殺 I、LT 必殺 II、LB Super、RT Awakening、B 防禦、RB 衝刺、Start 開始／暫停。映射與 trigger 邏輯有測試，實體手把未驗證。

## 戰鬥與內容

60 Hz、60 秒、先拿兩回合。每人 11 招，Super 100 氣、Awakening 200 氣、上限 300；必殺不耗氣。普通技命中／被擋可於窗口接必殺／Super，空振不能取消；有下段／中段、擊倒起身、hitstop、guard break 與連段遞減。

Kai 偏突進與確認連段；Lucy 偏武器距離、減速與限時精準防禦回饋。Story 有 Kai 兩場和 Lucy 一場的資料路線，勝利才推進並保存 clear；未實作長篇 campaign 或線上對戰。

## 驗收與製作

- docs/BENCHMARK_REPORT.md：誠實 Godot vs Phaser 判斷。
- docs/PRODUCTION_PARITY_MATRIX.md：完成／部分／未完成。
- docs/MOVE_ANIMATION_INVENTORY.md：招式、幀數、所有 clip。
- docs/GODOT_PRODUCTION_WORKFLOW.md：美術實證、模型分工、第三角色新增檔案。
- CODEX_HANDOFF.md / DEBUG_HANDOFF.md：交接與問題根因。
- tools/test.ps1：七個 regression suites；tests/parity_gpu_play.gd：真 GPU 與完整 Story 重播。
- tools/export_web.ps1：實際 Web export；tools/package.ps1：Windows release 包。
- tools/audit_content.py：資料／atlas／reference hashes；需要 Pillow。

Phaser 參考資料唯讀；617 個檔案 hash 核對未變。預設人物 atlas／portrait 是使用者提供的 Phaser 既有美術，不是這次新生成；Kai experimental rig 才是新流程實證。

## 目前界線

本機 Compatibility + 60 FPS cap；此機 VSync 路徑即使空白場景也異常低 FPS，停用本視窗 VSync 後完整遊戲恢復 60 FPS。這沒有改動 Windows／driver 設定。啟動器把 APPDATA/LOCALAPPDATA 限於程序的可寫資料夾以避開原 native crash 路徑。

骨架紙片感／接縫、正式 soundtrack、完整 progression、手機 Safari／實體裝置與第三角色工時比較仍未完成。可評估架構，還不足以支持正式重構決策。

