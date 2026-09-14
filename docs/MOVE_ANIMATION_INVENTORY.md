# Moves and animation inventory — Godot 0.2

Frame values use 60 Hz. Super/Awakening damage is per hit before combo scaling. Raster art is the user-provided Phaser baseline, not newly generated Godot animation.

## 阿凱 / kai

Speed 310 px/s; jump 690 px/s; preferred range 125 px. 疾速突進・確認連段.

| Move ID | Name | Startup / active / recovery | Damage | Meter | Level | Animation |
|---|---|---|---|---|---|---|
| punch | 巷口直拳 | 5 / 3 / 10 | 45 | 0 | mid | PUNCH |
| kick | 急煞前踢 | 9 / 4 / 17 | 68 | 0 | mid | KICK |
| crouch_punch | 低位截擊 | 5 / 3 / 9 | 35 | 0 | mid | CROUCH_PUNCH |
| crouch_kick | 巷弄掃腿 | 8 / 4 / 22 | 63 | 0 | low | CROUCH_KICK |
| air_punch | 躍送肘擊 | 5 / 5 / 12 | 48 | 0 | overhead | JUMP_PUNCH |
| air_kick | 跨巷飛踢 | 8 / 7 / 16 | 67 | 0 | overhead | JUMP_KICK |
| command | 上門破防 | 21 / 3 / 22 | 74 | 0 | overhead | KICK |
| special_punch | 破風急件 | 12 / 6 / 22 | 95 | 0 | mid | SPECIAL_PUNCH |
| special_kick | 路口迴旋 | 16 / 8 / 26 | 110 | 0 | mid | SPECIAL_KICK |
| super | 極速送達 | 10 / 18 / 29 | 160 | 100 | mid | SUPER |
| awakening | 使命必達 | 14 / 23 / 36 | 245 | 200 | mid | AWAKENING |

| Clip | Sheet | Frame sequence | FPS | Loop |
|---|---|---|---|---|
| IDLE | idle | [0, 1] | 3 | True |
| WALK_FORWARD | walk | [0, 1, 2, 3] | 8 | True |
| WALK_BACK | walk | [3, 2, 1, 0] | 8 | True |
| CROUCH | crouch | [0] | 12 | False |
| JUMP_START | jump | [0] | 20 | False |
| JUMP_UP | jump | [1] | 12 | False |
| JUMP_FALL | jump | [2] | 10 | False |
| LANDING | jump | [3] | 20 | False |
| PUNCH | normal | [0, 1, 2, 3, 4] | 18 | False |
| KICK | normal | [5, 6, 7, 8, 9] | 15 | False |
| CROUCH_PUNCH | normal | [10, 11, 12, 13] | 18 | False |
| CROUCH_KICK | normal | [14, 15, 16, 17, 18] | 15 | False |
| JUMP_PUNCH | normal | [19, 20, 21, 22] | 16 | False |
| JUMP_KICK | normal | [23, 24, 25, 26] | 15 | False |
| BLOCK | block | [0] | 12 | True |
| CROUCH_BLOCK | block | [2] | 12 | True |
| HIT | hit | [0, 1, 2] | 15 | False |
| HIT_ALT | hit | [1, 2, 0] | 15 | False |
| BLOCK_HIT | block | [0, 1] | 20 | False |
| KNOCKDOWN | hit | [3, 4, 5, 6] | 12 | False |
| WAKEUP | hit | [7, 8, 9, 10] | 15 | False |
| SPECIAL_PUNCH | special | [0, 1, 2, 3, 4, 5] | 18 | False |
| SPECIAL_KICK | special | [6, 7, 8, 9, 10, 11] | 17 | False |
| SUPER | super | [0, 1, 2, 3, 4, 5, 6, 7] | 20 | False |
| AWAKENING | awakening | [0, 1, 2, 3, 4, 5, 6, 7, 8] | 18 | False |
| KO | hit | [11, 12, 13, 14] | 10 | False |

Command normal reuses KICK presentation; other attack IDs resolve to their named semantic clip. Several transitional clips share source frames. A semantic state count is not a count of independently authored drawings.

## 露希 / lucy

Speed 280 px/s; jump 735 px/s; preferred range 175 px. 武器控距・節奏制壓.

| Move ID | Name | Startup / active / recovery | Damage | Meter | Level | Animation |
|---|---|---|---|---|---|---|
| punch | 諜影刺拳 | 4 / 3 / 10 | 45 | 0 | mid | PUNCH |
| kick | 特勤迴旋踢 | 9 / 4 / 17 | 68 | 0 | mid | KICK |
| crouch_punch | 低姿探棍 | 5 / 3 / 9 | 35 | 0 | mid | CROUCH_PUNCH |
| crouch_kick | 影步掃腿 | 8 / 4 / 22 | 63 | 0 | low | CROUCH_KICK |
| air_punch | 空降破勢 | 5 / 5 / 12 | 48 | 0 | overhead | JUMP_PUNCH |
| air_kick | 無聲飛踢 | 8 / 7 / 16 | 67 | 0 | overhead | JUMP_KICK |
| command | 斷線下劈 | 21 / 3 / 22 | 74 | 0 | overhead | KICK |
| special_punch | 影鏈突襲 | 10 / 6 / 22 | 95 | 0 | mid | SPECIAL_PUNCH |
| special_kick | 蛇環裂圓 | 16 / 8 / 26 | 110 | 0 | mid | SPECIAL_KICK |
| super | 黑燕殲滅 | 10 / 18 / 29 | 160 | 100 | mid | SUPER |
| awakening | 終局代號：將軍 | 14 / 23 / 36 | 245 | 200 | mid | AWAKENING |

| Clip | Sheet | Frame sequence | FPS | Loop |
|---|---|---|---|---|
| IDLE | idle | [0, 1] | 3 | True |
| WALK_FORWARD | walk | [0, 1, 2, 3] | 8 | True |
| WALK_BACK | walk | [3, 2, 1, 0] | 8 | True |
| CROUCH | crouch | [0] | 12 | False |
| JUMP_START | jump | [0] | 20 | False |
| JUMP_UP | jump | [1] | 12 | False |
| JUMP_FALL | jump | [2] | 10 | False |
| LANDING | jump | [3] | 20 | False |
| PUNCH | normal | [0, 1, 2, 3, 4] | 18 | False |
| KICK | normal | [5, 6, 7, 8, 9] | 15 | False |
| CROUCH_PUNCH | normal | [10, 11, 11, 13] | 18 | False |
| CROUCH_KICK | normal | [14, 15, 16, 17, 18] | 15 | False |
| JUMP_PUNCH | normal | [19, 20, 21, 22] | 16 | False |
| JUMP_KICK | normal | [23, 24, 25, 26] | 15 | False |
| BLOCK | block | [0] | 12 | True |
| CROUCH_BLOCK | block | [3] | 20 | False |
| HIT | hit | [0, 1, 2] | 15 | False |
| HIT_ALT | hit | [1, 2, 0] | 15 | False |
| BLOCK_HIT | block | [0, 1] | 20 | False |
| KNOCKDOWN | hit | [3, 4, 5, 6] | 12 | False |
| WAKEUP | hit | [7, 8, 9, 10] | 15 | False |
| SPECIAL_PUNCH | special | [0, 1, 2, 3, 4, 5] | 18 | False |
| SPECIAL_KICK | special | [6, 7, 8, 9, 10, 11] | 17 | False |
| SUPER | super | [0, 1, 2, 3, 4, 5, 6, 7] | 20 | False |
| AWAKENING | awakening | [0, 1, 2, 3, 4, 5, 6, 7, 8] | 18 | False |
| KO | hit | [11, 12, 13, 14] | 10 | False |

Command normal reuses KICK presentation; other attack IDs resolve to their named semantic clip. Several transitional clips share source frames. A semantic state count is not a count of independently authored drawings.
