# Cleanup Candidates 2026-05-04

This file separates what is currently useful from what can be removed later after user confirmation. Do not delete large folders automatically.

## Keep For New Session

- `CURRENT_STATE.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `data/proc_maze/module_registry.json`
- `scripts/proc_maze/*.gd`
- `scripts/tools/BakeTestProcMazeMap.gd`
- `scripts/tools/ValidateTestProcMazeMap.gd`
- `scripts/tools/ValidateProcMazePlayable.gd`
- `scripts/tools/BakeTestProcMazeNoCeilingPreview.gd`
- `scripts/tools/ValidateProcMazeNoCeilingPreview.gd`
- `scripts/tools/CaptureTestProcMazeMapLayout.gd`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `run_proc_maze_test.bat`
- `run_proc_maze_no_ceiling_preview.bat`
- `run_mvp_room.bat`
- `start_texture_tool.bat`
- `codex_tools/texture_tool/texture_tool_server.py`
- `artifacts/screenshots/test_proc_maze_layout.png`
- `logs/proc_maze_variety_*_20260504.log`

## Keep Until User Accepts Or Rejects Visual Experiments

- `scenes/mvp/experiments/FourRoomMVP_contact_ao_experiment.tscn`
- `scenes/mvp/experiments/FourRoomMVP_grime_experiment.tscn`
- `materials/textures/grime/*`
- `scripts/visual/GrimeOverlayBuilder.gd`
- `scripts/tools/BakeGrimeExperiment.gd`
- `scripts/tools/ValidateGrimeExperiment.gd`
- `scripts/tools/CaptureGrimeExperimentScreenshot.gd`
- `artifacts/screenshots/grime_*`
- `artifacts/screenshots/contact_ao_*`
- `artifacts/screenshots/foreground_cutout_*`

## Cleaned In This Pass

- Removed empty runtime log: `logs/run_proc_maze_no_ceiling_preview.log`.
- Removed failed/hung viewport screenshot log after documenting the issue: `logs/proc_maze_variety_screenshot_20260504.log`.
- Removed old root launchers:
  - `open_base_resource_gallery.bat`
  - `open_grime_texture_preview.bat`
  - `open_latest_scene.bat`
  - `open_proc_maze_no_ceiling_preview.bat`
  - `run_base_resource_gallery.bat`
  - `run_contact_ao_experiment.bat`
  - `run_grime_experiment.bat`
  - `run_latest_demo.bat`
  - `start_codex_fresh_cli.bat`
  - `start_codex_fresh_desktop.bat`
- Added replacement MVP verification launcher `run_mvp_room.bat`; do not restore `run_latest_demo.bat` unless explicitly requested.

## Possible Cleanup After Confirmation

- Old one-off screenshot HTML previews under `artifacts/screenshots/`, especially `grime_texture_*_preview.html` and `grime_texture_image2_contact_sheet_*.html`.
- Older proc-maze validation logs before `proc_maze_variety_*_20260504.log` if storage becomes noisy.

## Do Not Delete Without Explicit User Approval

- `3D模型/`
- `addons/`
- `materials/`
- `scenes/mvp/`
- `scenes/modules/`
- `scripts/scene/`
- `scripts/player/`
- `scripts/monster/`
- `四房间MVP_Agent抗遗忘执行包/`
- any `.glb` model file
- any accepted `.tscn` scene
