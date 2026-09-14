# 武鬥台灣魂 — handoff

- Status: 0.2 benchmark delivered for evaluation, 2026-09-14. Playable vertical slice, NOT full Phaser parity or a production-release recommendation.
- Repository hygiene: initialized `main` as the standalone Godot research repo. Tracks only 0.2 source/data/assets/rig pipeline/tests/docs and seven representative QA visuals; excludes `.godot`, build/artifacts, engine/templates, Phaser reference, old 0.1 source/assets, and generated import files. No Git LFS required: staged source is about 41 MiB and has no file above 20 MiB.
- Entry: scenes/main.tscn → src/game.gd. core/battle.gd / commands.gd / cpu.gd; modes/progress.gd; presentation/actor.gd / effects.gd / audio.gd / interface.gd. Fighter/move/visual/story/stage data are separate JSON.
- Reference: PHASER_REFERENCE remains read-only; 617-file hash audit unchanged. Manifest/checklist reviewed first, then prioritized architecture/Story/Awakening/art. Source informs design, no Phaser/React/TypeScript runtime port.
- Implemented: 22 moves, 26 raster states each, editable Kai 12-part/26-clip native rig with stance IK; Training, Story, CPU, local, four audio buses, actual Web export. Default raster reuses reference art; only the Kai rig is new production-workflow evidence.
- Final tests: seven suites pass, combat 16/16 and depth 9/9. Headless scene/device teardown explicitly releases audio streams and waits through multiple mix cycles; runner rejects resource/ObjectDB warnings. Exported PCK real OpenGL/input replay 11/11; Story 3 matches / 8 rounds / 1 loss retried, clear save reload. Final release-pack-play.log has no SCRIPT ERROR or cleanup warnings. Optimized Windows executable initialized GL and exited 0.
- Final browser: fresh Chromium build, Training selection/VS/battle, 844×390 virtual dash/Awakening, complete move list, no observed console error/warn. No physical mobile/Safari/controller/remote deployment claim.
- Deliverables: Play.cmd; build/TaiwanFighter-0.2.0-Windows.zip (49,569,935 bytes); build/web (53,263,370 bytes, gzip estimate 24,002,900). ZIP CRC and every entry match build/windows; Web/Windows PCK identical. Exact hashes: artifacts/benchmark/release-integrity.json.
- Final evidence: artifacts/benchmark/release/gpu-play.json and play-*.png, docs/QA_BENCHMARK.md. Earlier artifacts/benchmark/gpu-play.log is a FAILED HUD-scope run despite its final 11/11 line; do not present it as clean evidence.
- Diagnosis: writable process-local APPDATA/LOCALAPPDATA retained. Empty scene reproduced 4–5 FPS on both GL/Vulkan with VSync; window VSync off plus 60 FPS cap restored ten full-game samples to 60. No global driver changes. Details: DEBUG_HANDOFF.md.
- Reports: docs/BENCHMARK_REPORT.md, PRODUCTION_PARITY_MATRIX.md, MOVE_ANIMATION_INVENTORY.md, GODOT_PRODUCTION_WORKFLOW.md, WEB_EXPORT.md.
- Risks: rig seams/angles/hands, missing Lucy rig, missing original generation prompt provenance, no third-character total-cost evidence, shared cinematic staging, placeholder soundtrack, incomplete progression and device QA. This supports a research candidate, not a recommendation to migrate.
- Next safest task: timed third-character production at a fixed quality gate, then human Phaser/Godot A/B and iPhone/Android testing. Do not add menus merely to inflate parity.
- Local Web: python tools/serve_web.py → http://127.0.0.1:8060. Re-export before prepare_web.py; do not run preparation twice on generated HTML.

## Historical 0.1 record
- Objective: from-zero Godot Kai vs Lucy, reference-faithful identity, extensible foundation, actually execute/play/fix; investigate Windows memory-read crash without assuming gameplay/GPU cause.
- Attachment fully read: 16 text/metadata files and 5 images. ZIP v4 contains v3 metadata; primary PNGs supersede inconsistent contact-sheet references. Documents treated as reference data, not overriding user instructions.
- Delivered: Play.cmd, project.godot, build/TaiwanFighter-0.1.0-Windows.zip (~80 MiB), README.md, architecture/art/QA documentation, license notices.
- Runtime: Godot 4.5.2 official; Compatibility/OpenGL default. Launchers set process-local APPDATA and LOCALAPPDATA to writable folders. See DEBUG_HANDOFF.md.
- Architecture: pure 60 Hz combat.gd; roster.json content; CPU emits commands; presentation consumes state/events. No damage rules in presentation.
- Features: both characters selectable, CPU/local versus, movement/dash/light/heavy/special, guard break/counter/hitstop, best-of-three, timer, pause/help, result/rematch, art and original procedural audio.
- Verification: combat 14/14; edge/CPU 33/33; scene and input regressions passed. Real OpenGL and Vulkan smoke passed guard, Lucy attack, two KOs, result, rematch, 960x540. Exported PCK passed the same real GPU smoke. Evidence: artifacts/ and docs/QA_REPORT.md.
- Native keyboard play: Kai mutual damage and pause; Lucy two rounds, result and rematch. Portable executable opened OpenGL; desktop tool app approval timed out for its new window, so portable gameplay verification used exported PCK GPU/input smoke rather than claiming manual packaged play.
- Fixed: unwritable-profile crash path, shader darkness, injected-key priority, audio cleanup, Kai CPU gap closing, KO edge clipping.
- Limits: four poses per fighter with procedural movement; incomplete animation set; Lucy won 10/12 fixed CPU calibration matches; no physical gamepad/mobile validation; no online/story/save. Portable uses editor-capable runtime, not signed/optimized export template.
- Next safest task: expand reference-faithful walk/hit/KO animation, then human spacing/balance playtest; retain regressions. No required prototype-delivery work pending.
