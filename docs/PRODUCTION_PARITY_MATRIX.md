# Phaser → Godot parity（0.2）

「完成」指兩角色 vertical slice 的能力已實作並有驗證，不代表 Phaser 全產品已移植。基準是提供的原始碼、文件和美術；沒有同機執行 Phaser/Godot A/B 效能測試。

| 項目 | 狀態 | 實際交付／限制 |
|---|---|---|
| 60 Hz 戰鬥、走退跳蹲／dash | 完成 | simulation 與 render 分開；起跳、落地、空中狀態；退走降速 |
| 六 normals＋command normal＋兩必殺 | 完成 | 每人 11 moves（含 Super/Awakening）；站／蹲／空中、前＋K |
| Hitbox / hurtbox | 完成 | 時間窗、多形狀、多接觸 group、hurtbox keyframes；pushbox 仍簡化 |
| Confirm / cancel / command | 完成 | hit/block/whiff、取消窗口與目標、buffer、相對面向 236/236236 |
| Hitstun / knockback / knockdown / wakeup | 完成 | Guard break、hitstop、起身無敵、連段遞減 |
| HP / meter / timer / round / KO | 完成 | 60 秒、先拿兩回合、結果重賽；Training 不結算 |
| Super / Awakening 流程 | 完成 | freeze、特寫、camera、release VFX、兩段判定、收招、暫停／reset 清理 |
| 演出與打擊感追平正式 Phaser | 部分 | 流程閉環；共用構圖＋raster 攻擊；精緻度與角色專屬演出未證明勝出 |
| Projectile / area / status / counter | 部分 | 模型和 fixture 測試；Lucy slow 實裝；前三種未形成完整新角色內容 |
| Passives | 部分 | Lucy 精準防禦獲氣／短期增傷／冷卻；未覆蓋全部 Phaser 組合 |
| CPU | 完成 | 三難度、反應延遲、距離選招、對空、确认取消；真人平衡未接受 |
| Local 2P | 完成 | 獨立鍵盤與手把映射；實體雙手把未測 |
| Select / VS / Battle / pause / move list | 完成 | 真 Controls、對手／難度、招式表；大量 roster 的選角 grid 未做 |
| Story vertical slice | 完成 | Kai 兩場／Lucy 一場；對話→battle→result→續篇／clear，版本化 clear save |
| 完整 progression | 部分 | clear 標記；長篇 campaign、章節 unlock、招募和複雜存檔遷移未追平 |
| Training | 完成 | reset、回血／無限氣、idle／guard dummy、狀態／傷害／判定；無 dummy 錄製 |
| Raster 動作 | 完成 | 每人 26 語義 states，使用 Phaser 既有完整 atlas；不是新生產成果 |
| 新角色 art workflow | 部分 | Kai 12 固定零件＋26 native clips、腳端量測／圖集；紙片感、角度／接縫待修；Lucy 未做新 rig |
| Native authoring | 部分 | Skeleton2D/Bone2D/AnimationPlayer、Camera2D、Controls、buses；招式 JSON、無框編輯器 |
| Audio 結構與 loop 清理 | 完成 | Music/Ambience/SFX/UI、有限長度素材、角色／舞台 override |
| 正式 soundtrack／聲音品質 | 未完成 | 合成 cue 是技術 placeholder，無完整音樂／配音 |
| Web export / local run | 完成 | single-thread Compatibility、local Chromium 實玩、build/gzip 記錄與腳本 |
| Mobile landscape / virtual controls | 部分 | 844×390 操作、縮放點擊、多指程式回歸；不是手機實機 |
| Safe area / Safari | 部分 | CSS env 外殼、直向提示；真瀏海／iOS／Android 持續效能未測 |
| Cloudflare 遠端發布 | 未完成 | 靜態輸出與交接；沒有部署宣稱 |

結論：可評估 Godot 是否承接玩法與產品流程；尚未證明遷移收益。下一個證據應是第三角色計時製作、真人雙引擎 A/B、實機 Web，不是繼續增加選單。
