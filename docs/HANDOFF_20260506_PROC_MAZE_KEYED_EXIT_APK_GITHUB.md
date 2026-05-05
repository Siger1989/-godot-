# Handoff 2026-05-06 Proc Maze Keyed Exit, Monsters, APK, GitHub

## Objective

- Keep `res://scenes/mvp/FourRoomMVP.tscn` as the global editable monster-size source.
- Use the user's adjusted Nightmare size from the MVP room.
- Make the active Nightmare collision fit through standard doors.
- Put five runtime monsters in the large proc-maze scene:
  - two normal monsters
  - two hearing-only Nightmare monsters
  - one red hunter
- Remove the escape key from the red hunter.
- Add one random/cabinet escape key pickup.
- Add one keyed outer-wall exit door in the large proc maze.
- Fix wall-opening generation so Z-axis openings do not rotate the wall/frame node.
- Export the large proc-maze Android debug APK.
- Replace the provided GitHub repository with filtered project contents, including this handoff document.

## Important Scene Paths

- MVP editable size source: `res://scenes/mvp/FourRoomMVP.tscn`
- Large playable proc maze: `res://scenes/tests/Test_ProcMazeMap.tscn`
- No-ceiling preview: `res://scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- APK output: `builds/android/backrooms_proc_maze_mvp_debug.apk`

## Main Changes

- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
  - Adds `LevelRoot/Doors/Door_KeyedOuterExit`.
  - Adds `LevelRoot/Props/ProcMaze_EscapeKey`.
  - Creates one extra outer-wall opening and frame using separate groups:
    - `proc_keyed_exit_opening`
    - `proc_keyed_exit_frame`
    - `proc_keyed_exit_door`
  - Skips the keyed outer opening from internal `proc_portal` counts so existing maze validation remains based on graph edges.

- `scripts/proc_maze/TestProcMazeMap.gd`
  - Runtime monster spawn set is now five monsters:
    - `Monster`
    - `Monster_Normal_B`
    - `NightmareCreature_A`
    - `NightmareCreature_B`
    - `Monster_Red_Hunter`
  - Red hunter no longer carries or drops the escape key.

- `assets/backrooms/monsters/NightmareCreature_Monster.tscn`
  - Nightmare collision box reduced so the active character can pass door openings.
  - Visual size still comes from the MVP source scene.

- `scripts/scene/WallOpeningBody.gd`
  - Z-axis wall openings now keep node rotation at zero.
  - Mesh and collision are generated axis-correctly instead of relying on rotated nodes.

- `scripts/scene/DoorFrameVisual.gd`
  - Z-axis door frames now keep node rotation at zero.
  - Frame mesh is generated axis-correctly.

- `project.godot`
  - Main scene is now `res://scenes/tests/Test_ProcMazeMap.tscn`.

- `export_presets.cfg`
  - Android export path is now `builds/android/backrooms_proc_maze_mvp_debug.apk`.

## Behavior Notes

- Nightmare monsters do not use vision against the player.
- Nightmare monsters hear player footsteps, chase the sound, investigate after the sound stops, then return to wandering after losing the target.
- Nightmare sonar audio is present on runtime Nightmare monsters.
- Player footstep audio is quieter than the original loud pass and remains separate from the gameplay hearing radius.
- Red hunter attacks visible living creatures and has no escape key visual/metadata in the proc maze.
- The escape key is generated as a pickup in the maze, currently placed on a generated cabinet when one is available.
- The keyed outer door refuses interaction before key pickup and opens after the player collects the key.

## Validation

All listed validations passed on 2026-05-06:

- Godot parse: `logs/proc_maze_keyed_exit_parse_20260506.log`
- Keyed outer exit: `logs/proc_maze_keyed_exit_validate_r2_20260506.log`
- Proc-maze monster/key setup: `logs/proc_maze_monster_key_after_bake_validate_20260506.log`
- Nightmare hearing/wander AI: `logs/nightmare_hearing_wander_validate_20260506.log`
- Clean rebuilt wall openings: `logs/clean_rebuild_no_rotated_openings_validate_r2_20260506.log`
- Proc-maze scene validation: `logs/proc_maze_test_map_validate_r2_20260506.log`
- Proc-maze playable validation: `logs/proc_maze_playable_validate_20260506.log`
- Monster AI: `logs/monster_ai_red_living_validate_20260506.log`
- Monster size source: `logs/monster_size_source_after_bake_validate_20260506.log`
- Imported monster assets: `logs/imported_monsters_validate_20260506.log`
- Generated mesh rules: `logs/generated_mesh_rules_validate_20260506.log`
- Forced mobile controls: `logs/mobile_controls_validate_20260506.log`
- Four-room MVP monster set after bake: `logs/four_room_mvp_monster_set_after_bake_validate_20260506.log`

## APK

- Export command succeeded:
  - preset: `Android`
  - output: `builds/android/backrooms_proc_maze_mvp_debug.apk`
  - log: `logs/apk_export_proc_maze_keyed_exit_20260506.log`
- APK verification succeeded with Android build-tools `apksigner`:
  - v2 scheme: true
  - v3 scheme: true
  - signer count: 1
- APK size at export time: `309735233` bytes.

## GitHub Upload Plan

- Target repository provided by user:
  - `https://github.com/Siger1989/-godot-`
- The local Godot project folder is not a git repository.
- Upload used a temporary clone of the target repository:
  - `E:\godot_publish_20260506\repo`
- Existing target repository contents were removed except `.git`.
- Copied only project-needed source content, including:
  - `addons`
  - `assets`
  - `data`
  - `docs`
  - `materials`
  - `scenes`
  - `scripts`
  - `3D模型`
  - root project files such as `project.godot`, `export_presets.cfg`, `README.md`, `AGENTS.md`, `icon.svg`, `icon.svg.import`, and helper BAT files
- Exclude generated/local-only content:
  - `.godot`
  - `logs`
  - `artifacts`
  - `builds`
  - `godot后室新`
  - `codex_tools`
  - Blender scratch files and Python caches
- First push succeeded:
  - commit: `4eefef9`
  - remote update: `0c2b6af..4eefef9`

## Next Session Notes

- If the user adjusts monster sizes again, edit `res://scenes/mvp/FourRoomMVP.tscn`, save, then rebuild/bake scenes so generated scenes use the saved source transform.
- If door width changes, keep `WallOpeningBody.gd` and `DoorFrameVisual.gd` axis-aware with zero node rotation.
- If the GitHub push fails, check local `git`/`gh` authentication first; implementation/export work is already completed locally.
