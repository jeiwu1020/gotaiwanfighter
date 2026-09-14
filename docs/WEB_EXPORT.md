# Web export 與部署交接

已實際使用官方 Godot 4.5.2 single-thread Web release template，Compatibility/WebGL2，輸出在 build/web。沒有發布至遠端。

## 重建與本機執行

1. 官方 Godot executable 位於 tools/godot；export templates 位於 tools/export-templates。版本固定 4.5.2。若換版本，engine 與 templates 必須一起換。
2. 執行 `powershell -File tools/export_web.ps1 -Python <python.exe>`。Python 僅標準函式庫即可 export shell；字型／美術 builder 另外需要 fontTools/Pillow/numpy。
3. `python tools/serve_web.py`，開啟 http://127.0.0.1:8060 。server 只綁 loopback；不是外網部署。
4. 不使用 file://；WebAssembly 必須是 application/wasm，PCK 不可被 SPA fallback 改成 HTML。音訊需使用者互動後啟動。

prepare_web.py 應接在新一次 export 後執行，不要在同一份已處理 HTML 重複套用。它加入繁中、safe area、等比例 canvas、手機直向提示與 build-size 記錄。canvas backing buffer 按 CSS 尺寸×devicePixelRatio 調整，避免雙重縮放。

## 大小與效能界線

最終 byte 數以 artifacts/benchmark/web-size.json 為準；本輪約 50.8 MiB 原始檔、22.9 MiB gzip 估算。主要 WASM 為 38,047,590 bytes（約 36.3 MiB），PCK 約 14.2 MiB。這不是小型即開網頁；本機快取載入不能代表手機冷啟動速度。

gzip 數字是逐檔壓縮估算，簡易本機 server 沒有啟用 gzip。正式伺服器應設定正確 MIME 和壓縮，並用實際 Network transfer 量測。不得把預估誤寫成部署成果。

Chromium 已在 1280×720 和 844×390 使用真實選單／按鈕／鍵盤操作；可進 Training、施放虛擬 dash／Awakening、顯示招式表。一次 844×390 F2 觀察為 56 FPS（剛進場），只是桌機 Chromium 樣本，不是手機性能結論。原生 1280×720 在 MX450 上停用 VSync、限制 60 FPS 後十次採樣皆 60 FPS。Texture monitor 約 180 MiB，尚未優化為按需載入全部動畫；不等於總 RSS。

single-thread export 不需要 SharedArrayBuffer，也不要求以 COOP/COEP 來啟用執行緒。本輪没有 GDExtension、網路或多執行緒假設。依據 [Godot Web export 文件](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html)。

## Cloudflare 特別限制

不能直接說把現在資料夾丟上 Pages 就會成功：Pages 與 Workers 靜態資產每檔上限 25 MiB，原始 WASM 超過。官方建議較大檔案用 R2。見 [Pages limits](https://developers.cloudflare.com/pages/platform/limits/) 與 [Workers limits](https://developers.cloudflare.com/workers/platform/limits/)。

交接路線：使用 R2 保存 `build/web`，以同源 Worker 串流提供。根目錄的 `wrangler.toml` 是 Cloudflare Git deployment 的設定；它只部署 `deploy/cloudflare/worker.mjs`，不尋找或上傳未提交的 `build/web`。這避免 Git build 誤跑 `wrangler deploy` 時出現「Could not detect a directory containing static files」錯誤。

首次部署：在同一 Cloudflare account 建立名稱為 `taiwanfighter-benchmark-assets` 的 R2 bucket，連接本 repo，build command 設為 `npx wrangler deploy`。Git build 只部署 Worker。之後在具備 Wrangler 登入或 API token 的受信任本機，依序執行：

```powershell
powershell -File tools/export_web.ps1
powershell -File tools/upload_cloudflare_r2.ps1
```

上傳腳本保留相對路徑並最後上傳 `index.html`，降低 HTML 指到尚未完成資產版本的時間窗口。先用 `-DryRun` 檢視清單。bucket 名稱改動時，同時以 `-BucketName` 執行腳本並更新 `wrangler.toml`。這個流程仍**尚未遠端測試或部署**；設定壓縮後應重新驗證啟動、音訊、存檔、reload 和 mobile。

另一條可行路線是自有 Nginx/Caddy 等靜態伺服器，沒有此單檔限制。未使用未驗證的 Pages gzip rewrite 來假稱可直接部署。

## 尚待實機確認

- iPhone/iPad Safari 的 WebGL2、音訊恢復、IndexedDB clear save、記憶體回收／tab reload。
- Android 中階 GPU 的冷啟動、10 分鐘對戰 FPS、溫度與峰值記憶體。
- 真實瀏海 env safe-area 值、瀏覽器工具列收放、旋轉後多指輸入；本輪只做瀏覽器尺寸與程式多指回歸。
- 實體控制器、兩支控制器的裝置映射。
- 弱網下載、快取失配與遠端 HTTP headers。

Desktop 鍵盤仍可用，F4 可切虛擬按鈕。Web 預設顯示虛擬按鈕，不依 pointer 類型隱藏功能；手機直向顯示轉向提示。
