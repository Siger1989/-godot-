# Footstep Sound Sources

Updated 2026-05-06.

Replaced files:
- `player_footstep_01.wav`
- `player_footstep_02.wav`
- `monster_footstep_01.wav`
- `monster_footstep_02.wav`

Source material:
- `snd_footsteps1.wav` from OpenGameArt "Various Sound Effects" by Spring Spring.
  - URL: https://opengameart.org/content/various-sound-effects-0
  - License: CC0
- `tap_stone.wav` and `small_rock_impact.wav` from the same OpenGameArt package.
  - URL: https://opengameart.org/content/various-sound-effects-0
  - License: CC0

Processing notes:
- Converted source sounds to mono 44.1 kHz WAV to keep existing project paths unchanged.
- Player footsteps use lighter trimmed step variants.
- Monster footsteps use lower-pitched, low-pass processed variants mixed with a small transient for weight.
- Original project files were backed up under `artifacts/backups/footsteps_before_replace_20260506/`.
