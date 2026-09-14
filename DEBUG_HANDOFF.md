# Debug handoff — 2026-09-14

## 0.2 benchmark: current fixes and evidence

- 2026-09-14 Cloudflare Git build first failed before Worker deployment: the command was `npx wrangler deploy`, but this repo had no root `wrangler.toml`; Wrangler therefore tried static-assets auto-detection and reported no directory. `wrangler.toml` now declares `deploy/cloudflare/worker.mjs`, CI Worker name `gotaiwanfighter`, and the `GAME_ASSETS` R2 binding. The next build reached the binding check, proving the entrypoint/config path is fixed; it failed only because R2 bucket `taiwanfighter-benchmark-assets` does not exist in account `2ef8316fe79e7394847533af7c25edb1` (Cloudflare code 10085). The generated Godot `index.wasm` is about 36 MiB, above Cloudflare Pages/Workers static-file limits, so Git deploys only the Worker and `tools/upload_cloudflare_r2.ps1` uploads the locally generated Web runtime to that bucket. Its dry run resolves nine runtime files and leaves `index.html` for last. Worker syntax (`node --check`) passes. After creating the bucket, rerun the Git build, upload assets, then validate requests/mobile.

- 2026-09-14 Vercel fallback added because R2 activation on this account requires a billing subscription even though R2 has a free allowance. `vercel.json` builds from `tools/vercel_build.sh`, which downloads Godot 4.5.2 Linux and matching export templates in the build container before exporting `build/web`. The total output is about 51 MiB and WASM about 36 MiB, below Vercel Hobby's 100 MB static-file upload limit. Shell syntax must be checked locally before the first Vercel import; no remote Vercel build has yet run.

- 2026-09-14 repository QA re-ran tools/test.ps1 and exposed intermittent AudioStreamWAV cleanup warnings in headless `parity_devices_test` and `parity_scene_test`. Reproduction: devices test leaked 4/8 runs after a fixed 0.15-second disposal wait; verbose output identified stage music/rain plus swing/cinematic playback resources. Releasing `stream` references alone did not eliminate it. The headless audio driver retains playback through later mix cycles. `audio.shutdown()` now stops and clears all streams; both scene tests invoke it and wait 1.0 second before quit. Five repeated device runs and the complete seven-suite runner are clean. This is test lifecycle cleanup, not a combat/audio-playback design change.

- Final packaged proof: release-pack-play.log is clean, 11/11; release/gpu-play.json records 3 matches, 8 rounds, one loss retried and saved Story clear. Earlier gpu-play.log contains a HUD scope failure and is historical failed evidence. The final export already replaces out-of-scope a.y with game.model.fighters[0].y.
- Optimized executable separately initialized OpenGL and exited 0: release-exe.log. ZIP CRC/every entry and identical Web/Windows PCK verified by tools/verify_release.py. Tests/tools/docs are excluded from exports, so final harness-only corrections do not change the tested PCK.
- Harness cleanup investigation: devices-exit-before.log identifies four WAV/playback resources still owned by the audio thread when free/quit happen in the same turn. Deferred free and a timer remove the warning. Controlled scene-exit-probe.log versus scene-exit-limited.log then proved --quit-after 120 could cut off cleanup in an uncapped headless loop. Runner now explicitly uses --max-fps 60 and a 1,800-frame emergency ceiling, and fails on ObjectDB/resource-exit warnings. All seven suites pass afterward; production audio was unchanged.

- New entry is src/game.gd, not src/main.gd. New seven-suite runner tools/test.ps1 checks both exit status and SCRIPT ERROR because Godot assertion failure can still exit 0.
- Portraits rendered as white rectangles: draw_texture_rect used a function-local loaded texture, releasing its RID before render. Persistent portrait cache fixed Select/VS/cinematic on real GPU.
- Kai rig rear limbs disappeared: negative child z values rendered behind stage. Actor rig uses positive base z; normalized scale 0.84 matches raster height. Green despill used uint8 +15 overflow; float math removed pink skin speckles. Fixed KO root offset and presentation edge clipping.
- Super group 0 knocked down immediately, making group 1 miss. Authored knockdown_group=1 and longer initial stun restore real two-hit sequence. Projectile contacts no longer grant unrelated melee cancel confirmation; first simultaneous cinematic owns freeze.
- GPU input harness observed before accumulated InputEvent delivery. Explicit Input.flush_buffered_events made the test follow engine input ordering; gameplay was not changed to satisfy a timing artifact. 11/11 GPU flow replay passes, including complete two-battle Story with real collision and saved clear.
- Web canvas was CSS-scaled twice at 844x390. Shell now sizes backing buffer to CSS dimensions × devicePixelRatio, keeping one coordinate transform. Virtual Awakening/dash clicks verified in resized Chromium.
- Training settings now collapse to protect the air-attack playfield. A move-list indentation error was caught by scene tests and fixed before packaging.

### 0.2 low FPS: VSync comparison (separate from original native crash)

Full game on MX450/OpenGL initially sampled 3–5 FPS. A completely empty SceneTree reproduced 4–5 FPS in BOTH OpenGL and Vulkan, with process time approximately 300–380 ms and physics under 0.1 ms. Thus game simulation/art was not needed to reproduce this slowdown.

Disabling VSync only for the test window, with Engine.max_fps=60, restored the SAME full game to ten consecutive 60 FPS samples at 1280x720. Evidence: artifacts/benchmark/probe-gl.log, probe-gl-no-vsync.log, probe-vulkan.log, native-perf-vsync-on.json, perf-no-vsync.log. The empty no-VSync probe completed before its FPS counter warmed up, so its reported 1 FPS is not a valid steady-state measurement; the full-game warmed-up test is the evidence.

Project now sets window/vsync/vsync_mode=0 and application/run/max_fps=60. No global driver/Windows settings were changed. This localizes the symptom to the display synchronization path on this environment; it does not prove a particular driver defect. Possible tearing is the tradeoff; other machines can compare VSync enabled in Project Settings. Web is paced by browser requestAnimationFrame.

Texture monitor was approximately 189 MB (180 MiB), and Godot static allocator approximately 58.6 MB; these are different monitors, NOT total process RSS. Physical mobile memory/performance still requires measurement.

## Historical 0.1 diagnosis below

## Windows native memory-read crash

Initial failure occurred before game implementation: headless engine failed to create default APPDATA Godot/app_userdata and user://logs, then native signal 11. No GPU renderer or game scene was active.

Controlled change: process-local APPDATA redirected to writable artifacts/runtime. Same engine then executed the intentionally failing missing-model test normally; after implementation, tests passed. Editor import separately exposed an inaccessible LOCALAPPDATA cache, so launchers redirect both variables for child processes. No system settings changed.

Evidence supports a writable-userdata failure path; it is not an engine-source-level diagnosis of every possible memory-read dialog. Initial failure details are preserved here from observed console output; no Windows crash dump was captured.

Renderer comparison, Godot 4.5.2 official and NVIDIA MX450:
- Compatibility / OpenGL 3.3, NVIDIA 572.16: desktop play and full GPU smoke passed, artifacts/render-opengl.log.
- Mobile / Vulkan 1.4.303: same GPU smoke passed, artifacts/render-vulkan.log.
- Exported PCK loaded with OpenGL: full smoke passed, artifacts/portable-smoke.log; standalone copied executable initialized OpenGL, artifacts/portable.log.

No native crash reproduced in writable-path runs. Compatibility remains default for this 2D project, not because Vulkan was proven faulty. Sandboxed runs emit a root-certificate-store read warning; verbose inspection reported built-in CA loaded. Unsandboxed GPU logs do not show it. Offline gameplay performs no network requests.

## Keyboard input

Native automation injected logical Enter=4194309/L=76 with physical_keycode=4194313 (Pause). Prioritizing physical input discarded the intended command; zero-only fallback did not solve it. Opt-in trace in artifacts/input-trace.log isolated this. Logical keycode now takes priority, physical remains fallback. Regression carrying the observed conflicting values failed before the fix and passed afterward. Native Enter, attacks, pause and rematch subsequently worked. This concerns observed injected input, not all physical keyboards.

## Presentation and cleanup

- Dark sprites: shader multiplied sampled texture by COLOR already containing sampled color. Removed duplicate multiplication; native and GPU captures confirm restored colors.
- WAV/ObjectDB exit warnings: stop/free procedural streams and await scene disposal in tests. Final scene/render logs contain no cleanup warnings.
- Kai CPU: 12/12 losses exposed failure to close weapon spacing. Gap-closing regression failed first. CPU now uses dash and special startup lunge range; calibration Kai 2 / Lucy 10, all matches resolve with mutual damage. Balance remains provisional.
- KO at screen edge: clamped presentation center and reduced downward displacement; inspected final OpenGL KO capture. Collision model remains independent.

## Portable verification boundary

New TaiwanFighter.exe desktop capture encountered a Computer Use app approval timeout. No manual portable-input claim is made. Original native engine was played through a full match; exported PCK was separately verified with real GPU rendering and injected input using tests/render_smoke.gd. This validates resource packing and scene behavior without repeating the timed-out desktop approval.
