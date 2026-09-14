# 0.2 最終 QA — 2026-09-14

只列本輪證據；0.1 測試不計入覆蓋。Phaser 617 檔 hash audit 未發現修改，沒有同機實跑 Phaser 的 A/B 數據。

## 發行包

Windows ZIP 49,569,935 bytes；PCK 14,864,288 bytes，SHA256 `e814684c2911137c06aea749cebea523545a86ef0ab6baee81f604b834143149`。

tools/verify_release.py 在本機驗證 ZIP CRC、全部八檔與 build/windows 一致、Web/Windows PCK 完全相同。正式 optimized exe 初始化 OpenGL/MX450 並正常退出 0。這些 build/log 都是未提交的本機 QA output；完整玩法由 exported PCK replay 驗證，沒有宣稱手動操作整場 portable exe。

## 真 renderer、input 與 Story

官方 engine 掛載最後 PCK，由外部腳本送鍵盤 InputEvent。11/11：移動、拳命中、防禦、蹲踢倒地、空中攻擊、Awakening 暫停與恢復、P2 移動／必殺、Story 通關與 save reload。Kai 兩關含一次落敗重試，共三場、八回合；不直接改 HP/winner 通關。

最終 log 無 SCRIPT ERROR、native crash 或退出資源警告；機器結果為 11/11。提交少量可檢視的 [主選單](qa-evidence/main-menu.png)、[選角](qa-evidence/character-select.png)、[Training](qa-evidence/training.png)、[Story](qa-evidence/story.png)、[Awakening 特寫](qa-evidence/awakening-cutin.png) 與 [Story clear](qa-evidence/story-clear.png)，確認角色比例、接地、HUD、肖像及鏡頭回復。不是逐幀美術核准或真人 hit-feel 接受。

原生手動鍵盤 Training 的 dash／special／Awakening 曾實玩。舊 artifacts/benchmark/gpu-play.log 是修正前 HUD scope error 的失敗紀錄，即使末尾寫 11/11 也不是 clean pass；最終證據以 release 路徑為準。

## 回歸與角色製作

tools/test.ps1 七套全部通過：combat 16/16、depth 9/9、modes、scene、devices、passive、rig。最後修復 harness 音訊清理時機與過短 headless 幀數上限，並讓 runner 拒絕 ObjectDB／資源退出警告；沒有為測試更改遊戲規則。

Sandbox headless 的 root-certificate-store 讀取訊息仍在，未隱藏；非 sandbox 最終 GPU log 沒有此訊息，離線遊戲不發網路請求。多指／搖桿 trigger 用 InputEvent 注入，不等於實體裝置。

Kai 新 rig：12 同源部件、26 clips、固定頭／衣服／道具、左右支撐腳 IK。[連續步行](qa-evidence/kai-rig-walk.gif)。骨骼足端水平漂移 0.005858 px、接地誤差 0.060742 px；不是鞋底輪廓完全無滑動，接縫／紙片感／轉體仍需改善。未做 Lucy 新 rig 或第三角色製作成本比較。

36 場 CPU：easy Kai 7/Lucy 5、normal 7/5、hard 6/6，全部完成；不能當成競技平衡保證。

## Web、效能與界線

最後 Web 總檔案 53,263,370 bytes（50.8 MiB）；逐檔 gzip 估算 24,002,900 bytes（22.9 MiB）。本機 server 未啟用 gzip，估算不是已部署下載量。

2026-09-14 新 Chromium 分頁載入最後 build，經首頁→Training 選角→VS→battle。844×390 下 canvas 約 693×390，置中 x≈75；虛擬 dash／Awakening 與完整 11 招表均實際操作及目視，當次 console 無 error/warn。縮放瞬間有尚未穩定的一幀，後續尺寸與點擊對位正確；未宣稱所有旋轉／DPR 組合已測。

原生 MX450 1280×720，window VSync off、60 FPS cap 後十次採樣皆 60。空白 SceneTree 在 GL/Vulkan 開 VSync 都重現 4–5 FPS，詳 DEBUG_HANDOFF。Web 舊單次 56 FPS 觀察不代表手機持續效能。

尚未：Safari、實體 iPhone/Android、真瀏海、多指握持、雙控制器、弱網冷啟動／10 分鐘熱測、遠端部署、真人雙引擎 A/B。Cloudflare 單檔大小限制與 R2/Worker 交接見 WEB_EXPORT.md。
