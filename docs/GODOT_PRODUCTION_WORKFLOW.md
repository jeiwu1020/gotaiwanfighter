# Godot 角色製作流程與實證

這次採用兩條可切換的 presentation 路線。正式對戰預設使用參考包的完整 raster atlas；Training 的「骨架 F7」啟用 Kai 的單一來源骨架實驗。既有 Phaser 動作的品質不能算成 Godot 生產效率的成果。

## 本輪真正做出的東西

- Kai：一次 reference-driven 部件圖生成，12 個固定部件，Skeleton2D / Bone2D / AnimationPlayer，26 個可編輯動畫。原始圖 `art/kai-rig/parts-source.png`；生成後來源 SHA 與各部件 SHA 在 `art/kai-rig/build-report.json`。
- 固定臉、髮型、上衣、褲子、背包與安全帽的貼圖不因 pose 更換；手臂／腿沿固定關節層級運動。因此消除了這一組動作之間「每張圖重新生成整個人」的身份漂移來源。
- `tools/build_rig_parts.py` 執行記錄在案的去綠底、邊緣處理、部件 crop；`tools/build_rig.gd` 產生 `scenes/rigs/kai.tscn`。使用者在 Godot 可查看骨骼與 AnimationPlayer tracks。重建會覆寫生成的 scene，手修前應先另存或把參數回寫 builder。
- Walk 採固定兩段腿長的 IK pose 計算，前後腿相差半週期。站立足端與世界移動速度配合，而非整張人物上下浮動。`tests/rig_test.gd` 對支撐半週量測：水平足端漂移約 0.006 px、垂直誤差約 0.061 px；這是骨骼端點，並不代表鞋底像素完全不滑。
- 26 clips 實際經 Godot/OpenGL 渲染：`artifacts/benchmark/kai-rig-inventory.png`；24 幀步行輸出與 GIF。全狀態固定頭部貼圖的回歸測試通過。
- 發現並修正：負 z-index 讓後側肢體落到舞台之後；去綠底 uint8 加法溢位造成皮膚粉紅雜點；站立比例過高；倒地根節點過低。

## 不應誇大的地方

26 clips 是完整的語義狀態覆蓋，並非 26 組高品質獨立手繪動畫。HIT/HIT_ALT/BLOCK_HIT 有共享姿勢；特殊技、Super 有普通攻擊姿勢重組。固定平面零件仍有關節接縫、胸廓無法可信旋轉、固定握拳和較硬的動作。Kai 新部件的臉與主參考仍須人工 Canon 審查，不是使用者已接受的 Master。Lucy 未建立新骨架，仍使用參考 raster 動作。沒有完成全新第三角色從 Canon 到可玩的工時比較。

生成工具的完整原始 prompt 未持久化保存，只有來源圖及構建報告；這是本輪 provenance 缺口。不可偽造一份「原始 prompt」。後續每次生成先存 request JSON、來源 hash、工具回傳位置與採用／退件原因，再開始裁切。

## 後續可重複流程

1. **Canon**：把臉、髮型、身高比例、服裝色塊、配件與武器持手寫成角色規格。以已核准 Master 固定參考，不從不同動作各自選「比較好看」的人。
2. **技術小樣**：先做 idle、walk、punch、guard、knockdown 五種。比較 raster、rig、必要的角度替換；沒有通過接地與身份 QA 就不生成整套。
3. **部件與姿勢**：生成／人工繪製同源部件；固定唯一頭部、軀幹與道具，左右肢體分名。武器端點用骨骼掛點，不分散到任意姿勢貼圖。現在 Kai 已做到固定背包與安全帽；Lucy 的雙節棍掛點尚未實作。
4. **Canonical geometry**：raster cell 384×384、feet baseline 377；rig root 在腳底，關節長度和像素尺寸分開。P2 在 actor 根節點鏡像一次；不再次鏡像個別 atlas。
5. **動作權責**：AnimationPlayer 控制身體與零件；60 Hz move data 控制出招／碰撞／資源。Hitstop 與 cinematic 使用同一個 simulation freeze 判斷，避免骨架仍自行播放。
6. **Normalize / QA**：檢查 alpha、bounds、atlas 索引、ground、尺度、左右腳相位、關節長度、持物數與手。出 contact sheet，播放循環，在實戰中對照判定框。骨骼足端測試只能作量測之一，不能取代鞋底與輪廓目視。
7. **落地**：data/roster 註冊，Training 逐招 hit/block/whiff/cancel/meter/KO/鏡像；完整模式進出與 Web build 檢查。技術 PASS、美術 QA、使用者核准分開標示。

## 新增第三角色需要哪些檔案

| 新增／修改 | 內容 |
|---|---|
| 新增 `data/fighters/<id>.json` | stats、hurtboxes、moves、cancel、passives、visual/portrait/rig 路徑 |
| 新增 `data/visuals/<id>.json` | atlas、clip、fps、loop、pivot 契約；目前所有角色仍須有 raster fallback |
| 新增 `assets/characters/<id>/` | 角色自己的 runtime atlas、portrait、可選 rig 部件 |
| 可選 `scenes/rigs/<id>.tscn` | Skeleton2D、Bone2D、AnimationPlayer，遵循同一組 clip 名称 |
| 新增 `art/<id>/` | Canon、Master、生成 request/log、原始部件、build report；不輸出到遊戲包 |
| 修改 `data/roster.json` | 加入一個 fighter JSON 路徑 |
| 可選修改 `data/stories.json` | 新 route、dialogue、opponent、stage 與 difficulty |
| 可選新增 `assets/audio/` 與角色 audio 對映 | 已有 audio bus 與角色 event-to-path override |
| 新增內容測試／QA artifact | 不應為角色 ID 改 battle core |

相同機制下不需修改 core/battle.gd、CPU、Actor；第三 ID 的資料 fixture 已通過戰鬥測試。**這只证明契約，不是完整第三角色交付。** 選角畫面目前為兩名角色排版，增加較多角色須做 UI paging/grid；新機制超出目前 enums 時也仍需擴充核心與測試。

## Astra、較便宜模型與自動化

| 工作 | 適合分工 |
|---|---|
| Canon 判斷、reference 衝突、動作設計、異常肢體診斷、最終視覺審查 | Astra／高能力視覺模型，加人工美術核准 |
| 依明確規格建立 JSON、story text 草稿、既有動畫軌道填寫、測試與文件 | 較便宜模型；必須通過同一 QA |
| alpha/crop、hash、atlas 索引、命名、foot/pivot 量測、圖集、export | 確定性的 Python/Godot 工具 |
| 最終角色是否仍是原本人物、打擊動作是否可信 | 不可只交給自動測試判斷 |

這個流程降低的是「重複生成整個人物」的風險；尚未證明整體美術成本更低。修骨架接縫、角度替換與手勢也有成本，應用第三角色計時實驗再決定是否採用。
