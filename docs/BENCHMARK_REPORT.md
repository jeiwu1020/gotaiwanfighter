# Godot Production Parity Benchmark — 0.2

2026-09-14 最後發行包重播與完整性驗證已完成。證據索引：[QA_BENCHMARK.md](QA_BENCHMARK.md)。

這版已從四姿勢 prototype 改為可評估的戰鬥與產品 vertical slice；**目前不建議據此決定 Phaser 發布後全面重構。** 架構可行性已有證據，但角色製作成本、演出品質與 mobile Web 尚缺決定性比較。

## 內容與架構

逐項狀態：[PRODUCTION_PARITY_MATRIX.md](PRODUCTION_PARITY_MATRIX.md)。完整招式與 frame sequence：[MOVE_ANIMATION_INVENTORY.md](MOVE_ANIMATION_INVENTORY.md)。每人 11 招：六 normals、command normal、兩必殺、Super、Awakening。Kai 移速 310、突進／確認連段；Lucy 移速 280、更高跳速、更長棍腳範圍、special kick 減速和精準防禦「反情報」氣量／限時增傷。

core/battle.gd 是 60 Hz authoritative simulation；commands.gd 解相對面向輸入；cpu.gd 僅發相同命令。fighter JSON 定義 timed boxes、hurtbox、cancel、meter、status、passive。座標腳底原點、前向 x 正、向上 y 負，P2 mirror 一次；group 防止一段重複命中，先收集接觸再結算以允許 trade。

game.gd 組合模式／輸入／生命週期；modes/progress.gd 管 Story/save；presentation 的 actor/effects/audio/interface 分別管人物、特效鏡頭、聲音、UI；stage 獨立。骨架是可編輯 scene/AnimationLibrary。資料契約允許第三 ID，不在核心以 Kai/Lucy ID 分支；但大量 roster UI、全新機制仍需開發。JSON/dictionary 仍偏 code-first，沒有證明比 Phaser 靜態型別資料更好維護。

## Super / Awakening 與模式

48-frame Super、90-frame Awakening 時鐘凍結戰鬥；角色特寫、斜切色面、局部速度線、letterbox、Camera2D 推近／返回；release 短期弧光和速度線，接真實兩段攻擊與收招，最後接觸段才擊倒。Reset／退出清 cinematic/entity/input/camera；暫停凍結同一時鐘。它是完整流程，但共用分鏡仍未達最終專屬演出。

CPU 三難度、local 2P、Training、Story、選角／VS／回合／結果／重賽共用 simulation。Training 可收合設定、重置位置、回血／無限氣、idle/guard dummy、傷害與狀態、F2 判定與 Tab 招式表。Story 資料節點可增加路線與戰鬥；Kai 兩場、Lucy 一場、勝利才推進、version 1 clear save。沒有長篇 campaign、招募／解鎖 graph、dummy 錄製或線上對戰。

## 人物 production

完整流程與 Astra／較便宜模型／自動化分工：[GODOT_PRODUCTION_WORKFLOW.md](GODOT_PRODUCTION_WORKFLOW.md)。真正新做的是 Kai 同源 12 零件、26 骨架 clips 與支撐腳 IK，全部經 Godot 渲染並產生連續步行。足端漂移有量測；臉／服裝／道具不逐 pose 重新生成。

預設 raster 使用 Phaser 現有完整美術，不能算 Godot 新生成成果。Rig 仍有接縫、紙片感、轉身與手勢不足；Lucy rig 沒做；新部件相對 Master 尚未獲使用者核准，也沒有第三角色總工時比較。原始生成 prompt 未持久保存，只保存源圖與 hash/build report，這是 provenance 缺口而非可偽造補寫的紀錄。

## 視覺／VFX／Audio／UI

紙色、深底、暖紅操作重點，角色局部冷色 accent；繁中 Noto 子集；真 Controls、暫停、招式表、減少動態和靜音。實際截圖修正過 portrait 白塊（貼圖引用生命週期）、骨架層級、訓練遮擋、KO 裁切、去綠底 uint8 溢位、Web 雙重縮放。

Music/Ambience/SFX/UI 分 bus。舊短循環不再被新入口引用。36 秒音樂、30 秒雨聲及有限 one-shots 是技術素材，不是正式 soundtrack。VFX 以受控幾何和 raster 組成，品質與專屬性尚未證明勝過 Phaser。

## Web 與驗證

[WEB_EXPORT.md](WEB_EXPORT.md) 說明 build、尺寸、local run、部署交接。已有本機 Chromium 真實操作、844×390 版面及虛擬 dash／Awakening 對位，console 無當時錯誤。Safari、實機 GPU、瀏海和雙手把未測，未做遠端部署。gzip 數字是壓縮估算，非已部署伺服器的實測下載量。

tools/test.ps1 檢查 exit code 與 SCRIPT ERROR，避免 Godot assertion 退出碼不可靠。Combat 16/16、depth 9/9，另有 modes/scene/devices/passive/rig suites。真 OpenGL replay 用鍵盤事件檢查 hit/block/knockdown/air/P2/cinematic pause/reset，並用真實碰撞與 CPU 命令走兩個 Story 關卡（最終校準後含失敗重試，共八回合）→clear→save reload，沒有直接寫 HP 或 winner 來通關。JSON 和 play-*.png 位於 artifacts/benchmark/release。另有 Windows 原生 Training 手動鍵盤操作與瀏覽器操作。多指／trigger 是 InputEvent 注入，不等於實機；0.1 舊 47 個測試不拿來充 0.2 覆蓋。

效能排查：空白視窗在 OpenGL、Vulkan 開 VSync 都只有 4–5 FPS；完整遊戲關閉視窗 VSync 並限 60 FPS 後十次採樣皆 60 FPS，已採為本專案預設，未修改 driver。詳見 DEBUG_HANDOFF.md。最終 CPU 36 場樣本：easy Kai 7/Lucy 5、normal 7/5、hard 6/6；不能等同真人平衡接受。

## Godot vs Phaser 判斷

| 判斷 | 證據 |
|---|---|
| 局部更好 | 這組 Kai 骨架不再逐 pose 重生臉／衣服；比例与足端可量測，AnimationPlayer 可編輯。不是引擎獨占技術，也未證明總工時更低。 |
| 只是不同 | JSON moves、fixed step、CPU 命令、Story 節點、audio buses；Phaser 同樣能做到，翻成 GDScript 不自動更好。 |
| 尚待實證的優勢 | Godot 原生 scene／動畫／camera authoring；目前 UI/VFX 仍大量程式建立，尚無另一位美術／開發者操作效率比較。 |
| 仍落後 | Production polish、完整 progression、框編輯工具、成熟機制覆蓋、Web 體積／裝置 QA 深度。 |
| 是否支持正式重構 | **值得保留為研究候選；不足以支持正式重構決策。** 可玩与架構可行，不等於遷移收益成立。 |

缺少的關鍵證據：全新第三角色同品質門檻的生成次數／返工／核心改檔與總工時；同場景真人盲測輸入延遲／hit feel／動畫；iPhone Safari 和中階 Android 冷啟動及 10 分鐘對戰；另一位開發者／美術實際修改招式、動畫、Story 的成本。

在這些證據出現之前，不應因 Godot 版能玩就建議放棄接近發布的 Phaser 版。
