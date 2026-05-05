# CURRENT_STATE

## 2026-05-06 Proc Maze Monsters, Keyed Outer Exit, And APK/GitHub

Current objective:
- Use the user's adjusted MVP Nightmare size as the global source, shrink the active Nightmare collision so it can pass doors, add two hearing-only Nightmare monsters, two normal monsters, one red hunter, one random escape key, and one keyed outer-wall exit door to the large proc-maze scene. Export the large scene APK and attempt to update the GitHub repository.

Current progress:
- Startup checks completed. `git status --short` and `git diff --stat` still fail because `E:\godot后室` is not a git repository.
- Searched `E:\` for `.git`; only unrelated ESP32 library repos were found. The user later provided the target remote `https://github.com/Siger1989/-godot-`, so publishing will use a temporary clone and replace that repo with filtered project contents after validation/export.
- Read project startup docs and identified the large scene path as `res://scenes/tests/Test_ProcMazeMap.tscn`.
- Changed generated wall-opening/frame scripts to keep Z-axis openings unrotated and generate axis-correct mesh/collision instead.
- Shrunk the active Nightmare collision box while preserving the MVP visual size source.
- Added proc-maze keyed outer exit generation, random/cabinet escape key placement, and five runtime monsters: two normal, two Nightmare, one red hunter.
- Added validation coverage for keyed outer exit and Nightmare lost-target wandering.
- Baked `FourRoomMVP.tscn`, `Test_ProcMazeMap.tscn`, and `Test_ProcMazeMap_NoCeilingPreview.tscn`.
- Switched the project main scene to the large proc-maze scene and exported `builds/android/backrooms_proc_maze_mvp_debug.apk`.
- Added a new handoff document for this pass and will include it in the GitHub upload.

Files changed:
- `CURRENT_STATE.md`
- `assets/backrooms/monsters/NightmareCreature_Monster.tscn`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/scene/DoorFrameVisual.gd`
- `scripts/scene/WallOpeningBody.gd`
- `scripts/tools/ValidateCleanRebuildScene.gd`
- `scripts/tools/ValidateNightmareHearingAI.gd`
- `scripts/tools/ValidateProcMazeKeyedExit.gd`
- `scripts/tools/ValidateProcMazeMonsterKey.gd`
- `project.godot`
- `export_presets.cfg`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `docs/HANDOFF_20260506_PROC_MAZE_KEYED_EXIT_APK_GITHUB.md`

Commands run:
- `git status --short` -> FAIL, directory is not a git repository.
- `git diff --stat` -> FAIL, directory is not a git repository.
- `.git` search under `E:\` -> no Godot project repository found.
- Godot parse -> PASS, log `logs\proc_maze_keyed_exit_parse_20260506.log`.
- `ValidateProcMazeKeyedExit.gd` -> PASS, final log `logs\proc_maze_keyed_exit_validate_r2_20260506.log`.
- `ValidateProcMazeMonsterKey.gd` -> PASS, final log `logs\proc_maze_monster_key_after_bake_validate_20260506.log`.
- `ValidateNightmareHearingAI.gd` -> PASS, log `logs\nightmare_hearing_wander_validate_20260506.log`.
- `ValidateCleanRebuildScene.gd` -> PASS after updating frame AABB expectation for zero-rotation Z-axis frames, log `logs\clean_rebuild_no_rotated_openings_validate_r2_20260506.log`.
- `ValidateTestProcMazeMap.gd` -> PASS, final log `logs\proc_maze_test_map_validate_r2_20260506.log`.
- `ValidateProcMazePlayable.gd` -> PASS, log `logs\proc_maze_playable_validate_20260506.log`.
- `ValidateMonsterAI.gd` -> PASS, log `logs\monster_ai_red_living_validate_20260506.log`.
- `ValidateMonsterSizeSource.gd` -> PASS after bake, log `logs\monster_size_source_after_bake_validate_20260506.log`.
- `ValidateImportedMonsterAssets.gd` -> PASS, log `logs\imported_monsters_validate_20260506.log`.
- `ValidateGeneratedMeshRules.gd` -> PASS, log `logs\generated_mesh_rules_validate_20260506.log`.
- `ValidateMobileControls.gd` with `FORCE_MOBILE_CONTROLS=1` -> PASS, log `logs\mobile_controls_validate_20260506.log`.
- `ValidateFourRoomMVPMonsterSet.gd` -> PASS after bake, log `logs\four_room_mvp_monster_set_after_bake_validate_20260506.log`.
- `BakeFourRoomScene.gd` -> PASS, log `logs\bake_four_room_no_rotated_openings_20260506.log`.
- `BakeTestProcMazeMap.gd` -> PASS, log `logs\bake_proc_maze_keyed_exit_20260506.log`.
- `BakeTestProcMazeNoCeilingPreview.gd` -> PASS, log `logs\bake_proc_maze_no_ceiling_preview_keyed_exit_20260506.log`.
- Android export -> PASS, log `logs\apk_export_proc_maze_keyed_exit_20260506.log`.
- `apksigner verify --verbose builds\android\backrooms_proc_maze_mvp_debug.apk` -> PASS, v2/v3 signatures verified.

Validation result: PASS

Current blocking issue:
- GitHub update still needs a temporary clone of the provided remote and push.

Next step:
- Replace/push the provided GitHub repository with filtered project files, including the handoff documents.

## 2026-05-06 MVP Direct Editable Monster Size Source

Current objective:
- Change `FourRoomMVP.tscn` itself into the editable monster-size source. The MVP room must contain exactly one directly selectable source node per monster type so the user can adjust global monster sizes there and save the MVP TSCN.

Current progress:
- Re-ran recovery startup checks after context compaction. `git status --short` and `git diff --stat` still fail because this project directory is not a git repository.
- Replaced the previous `MonsterRoot` instance usage in `FourRoomMVP.tscn` with a direct editable `MonsterRoot`.
- Kept only one source node per monster type in `FourRoomMVP.tscn`: `Monster`, `Monster_Red_KeyBearer_MVP`, and `NightmareCreature_A_MVP`.
- Removed the duplicate MVP source nodes `Monster_Normal_B` and `NightmareCreature_B_MVP` from the MVP room.
- Kept editor selection floor handles/labels for the three remaining source monsters; `MonsterSizeSourceRuntime.gd` still removes those helpers at runtime.
- Updated `MonsterSizeSource.gd` so generated/resource scenes read their scales from `res://scenes/mvp/FourRoomMVP.tscn`, with `normal_b` aliasing `normal` and `nightmare_b` aliasing `nightmare`.
- Updated proc-maze/resource-showcase source metadata and focused validators for the direct-MVP-source rule.
- Updated `open_monster_size_source.bat` to open `res://scenes/mvp/FourRoomMVP.tscn`; added `open_mvp_monster_room.bat` as a direct alias.

Files changed:
- `CURRENT_STATE.md`
- `open_monster_size_source.bat`
- `open_mvp_monster_room.bat`
- `scripts/monster/MonsterSizeSource.gd`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/tools/BuildNaturalPropScenes.gd`
- `scripts/tools/ValidateMonsterSizeSource.gd`
- `scripts/tools/ValidateFourRoomMVPMonsterSet.gd`
- `scripts/tools/ValidateNightmareHearingAI.gd`
- `scripts/tools/ValidateMonsterSavedScale.gd`
- `scripts/tools/InspectMonsterSizeSourceBounds.gd`
- `scripts/lighting/LightingController.gd`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/tests/Test_NaturalPropsShowcase.tscn`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/HANDOFF_20260505_IMPORTED_MONSTERS_AND_MVP_TEST.md`

Commands run:
- `git status --short` -> FAIL, directory is not a git repository.
- `git diff --stat` -> FAIL, directory is not a git repository.
- Godot parse -> PASS, log `logs\mvp_direct_monster_source_parse_final_20260506.log`.
- `ValidateMonsterSizeSource.gd` -> PASS after fixing the validator to check runtime-only Nightmare sonar after the scene enters the tree; final log `logs\mvp_direct_monster_source_validate_size_source_final_20260506.log`.
- `ValidateFourRoomMVPMonsterSet.gd` -> PASS with `monsters=3 normal=1 nightmares=1`, log `logs\mvp_direct_monster_source_validate_four_room_20260506.log`.
- `ValidateNightmareHearingAI.gd` -> PASS, log `logs\mvp_direct_monster_source_validate_nightmare_ai_20260506.log`.
- `ValidateMonsterSavedScale.gd` -> PASS, log `logs\mvp_direct_monster_source_validate_saved_scale_20260506.log`.
- `ValidateResourceShowcase.gd` first caught a stale Nightmare showcase scale after moving the source to MVP; updated `Test_NaturalPropsShowcase.tscn`, then PASS, log `logs\mvp_direct_monster_source_validate_resource_showcase_r3_20260506.log`.
- `ValidateProcMazeMonsterKey.gd` -> PASS, log `logs\mvp_direct_monster_source_validate_proc_maze_20260506.log`.
- `InspectMonsterSizeSourceBounds.gd` -> PASS, log `logs\mvp_direct_monster_source_bounds_20260506.log`.
- `ValidateCleanRebuildScene.gd` -> PASS, log `logs\mvp_direct_monster_source_validate_clean_rebuild_20260506.log`.
- `ValidateGeneratedMeshRules.gd` first exposed a cleanup-time freed-light script error; patched `LightingController.gd`, then PASS, log `logs\mvp_direct_monster_source_validate_generated_mesh_r2_20260506.log`.
- `ValidateMonsterAI.gd` -> PASS, log `logs\mvp_direct_monster_source_validate_monster_ai_20260506.log`.
- `ValidateMobileControls.gd` with `FORCE_MOBILE_CONTROLS=1` -> PASS, log `logs\mvp_direct_monster_source_validate_mobile_controls_20260506.log`.
- `ValidateImportedMonsterAssets.gd` -> PASS, log `logs\mvp_direct_monster_source_validate_imported_monsters_20260506.log`.
- Android export -> PASS, log `logs\apk_export_mvp_direct_monster_source_20260506.log`.
- APK file check -> PASS, `builds\android\backrooms_four_room_mvp_debug.apk`, `303419004` bytes, last write `2026-05-06 07:17:23`.
- `apksigner verify --verbose builds\android\backrooms_four_room_mvp_debug.apk` with `JAVA_HOME=D:\GodotAndroid\jdk-17` -> PASS, v2/v3 verified.
- Final Godot parse after docs/state updates -> PASS, log `logs\mvp_direct_monster_source_parse_after_docs_20260506.log`.
- Post-export `ValidateMonsterSizeSource.gd` on the current serialized MVP scene -> PASS, log `logs\mvp_direct_monster_source_validate_size_source_post_export_20260506.log`.
- Post-export `ValidateFourRoomMVPMonsterSet.gd` on the current serialized MVP scene -> PASS, log `logs\mvp_direct_monster_source_validate_four_room_post_export_20260506.log`.

Validation result: PASS

Current blocking issue:
- None. Godot still prints known non-blocking ObjectDB/resource cleanup warnings on some headless exits.

Next step:
- Open `open_mvp_monster_room.bat` or `open_monster_size_source.bat`, select the three direct monster nodes under `MonsterRoot` in `FourRoomMVP.tscn`, adjust their scale, and save the scene.

## 2026-05-06 Red Hunter, Cabinet Key, Keyed Exit, Dual Nightmare Sonar

Current objective:
- Update FourRoomMVP so the red monster no longer carries the escape key, attacks any living creature it can see while facing its prey, the key sits on a cabinet and is picked up with `E`, a keyed exit door sits in an outer wall opening, and the scene contains two hearing-only Nightmare monsters that emit sonar-like calls. Then validate and export an Android APK.

Current progress:
- Startup checks completed for this work item.
- `git status --short` and `git diff --stat` were run as required, but this project directory is not a git repository.
- Read project handoff/state docs and confirmed the current active compact MVP monster source is `res://scenes/modules/MonsterSizeSource.tscn`.
- Added a reusable `EscapeKeyPickup.tscn` and placed `CabinetTop_EscapeKey` on `RoomB_Maintenance_Cabinet`.
- Updated `DoorComponent.gd` so selected doors can require the player's escape key and play locked/unlock audio feedback.
- Changed the red monster source/showcase/proc-maze generator path so red monsters are red hunters, not key carriers.
- Added a second controller-backed `NightmareCreature_B_MVP` to `MonsterSizeSource.tscn`.
- Generated/imported `assets/audio/nightmare_sonar_call.wav` and wired Nightmare monsters to emit periodic sonar calls.
- Changed `SceneBuilder.gd` so Room_C's north outer wall has a runtime-generated exit opening and door frame.
- Added `Door_Exit_C_North_Keyed` to `FourRoomMVP.tscn` and changed `project.godot` main scene to `res://scenes/mvp/FourRoomMVP.tscn` for this APK pass.
- Baked `FourRoomMVP.tscn` once so the outer wall opening and frame are visible in the editor; a cleanup-time LightingController cast warning was found and patched before final validation.
- Updated project docs for the new red-hunter/cabinet-key/keyed-exit/dual-Nightmare baseline.
- Exported Android debug APK: `builds/android/backrooms_four_room_mvp_debug.apk`.

Files changed:
- `CURRENT_STATE.md`
- `project.godot`
- `export_presets.cfg`
- `scripts/scene/DoorComponent.gd`
- `scripts/monster/MonsterController.gd`
- `scripts/monster/MonsterSizeSource.gd`
- `scripts/core/SceneBuilder.gd`
- `scripts/lighting/LightingController.gd`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/tools/generate_mvp_audio_assets.py`
- `scripts/tools/BuildNaturalPropScenes.gd`
- `scripts/tools/ValidateMonsterSizeSource.gd`
- `scripts/tools/ValidateFourRoomMVPMonsterSet.gd`
- `scripts/tools/ValidateNightmareHearingAI.gd`
- `scripts/tools/ValidateResourceShowcase.gd`
- `scripts/tools/ValidateProcMazeMonsterKey.gd`
- `scripts/tools/ValidateCleanRebuildScene.gd`
- `scripts/tools/ValidateGeneratedMeshRules.gd`
- `scripts/tools/InspectMonsterSizeSourceBounds.gd`
- `scripts/tools/CaptureTestProcMazeMapScreenshot.gd`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/HANDOFF_20260505_IMPORTED_MONSTERS_AND_MVP_TEST.md`
- `scenes/modules/EscapeKeyPickup.tscn`
- `scenes/modules/MonsterSizeSource.tscn`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/tests/Test_NaturalPropsShowcase.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `assets/audio/nightmare_sonar_call.wav`
- `assets/audio/nightmare_sonar_call.wav.import`

Commands run:
- `git status --short` -> FAIL, directory is not a git repository.
- `git diff --stat` -> FAIL, directory is not a git repository.
- Read `AGENTS.md`, `README.md`, `docs/AGENT_START_HERE.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/FORBIDDEN_PATTERNS.md`, `docs/TASKS_PHASED.md`, and `docs/ACCEPTANCE_CHECKLIST.md`.
- `python scripts\tools\generate_mvp_audio_assets.py` -> PASS, generated 11 WAV assets including `nightmare_sonar_call.wav`.
- Godot import -> PASS, log `logs\sonar_audio_import_20260506_004424.log`.
- `BakeFourRoomScene.gd` -> PASS, log `logs\keyed_exit_bake_20260506_004424.log`; it exposed a cleanup-time red-light flicker stale-object warning, now patched in `LightingController.gd`.
- Godot parse -> PASS, log `logs\keyed_exit_parse_20260506_004424.log`.
- Final `BakeFourRoomScene.gd` -> PASS, log `logs\keyed_exit_bake_final2_20260506_004424.log`.
- `ValidateMonsterSizeSource.gd` -> PASS, log `logs\keyed_exit_20260506_004424_size_source.log`.
- `ValidateFourRoomMVPMonsterSet.gd` -> PASS, log `logs\keyed_exit_20260506_004424_four_room_mvp_r2.log`.
- `ValidateNightmareHearingAI.gd` -> PASS, log `logs\keyed_exit_20260506_004424_r2_nightmare_ai.log`.
- `ValidateResourceShowcase.gd` -> PASS, log `logs\keyed_exit_20260506_004424_r2_resource_showcase.log`.
- `ValidateCleanRebuildScene.gd` -> PASS, log `logs\keyed_exit_20260506_004424_r2_clean_rebuild.log`.
- `ValidateGeneratedMeshRules.gd` -> PASS, log `logs\keyed_exit_20260506_004424_generated_mesh_r4.log`.
- `ValidateMonsterAI.gd` -> PASS, log `logs\keyed_exit_20260506_004424_r4_monster_ai.log`.
- `ValidateMobileControls.gd` with `FORCE_MOBILE_CONTROLS=1` -> PASS, log `logs\keyed_exit_20260506_004424_mobile_controls_forced.log`.
- `ValidateProcMazeMonsterKey.gd` -> PASS for the no-key red-hunter regression, log `logs\keyed_exit_20260506_004424_r5_proc_maze_red_hunter.log`.
- `ValidateImportedMonsterAssets.gd` -> PASS, log `logs\keyed_exit_20260506_004424_r5_imported_monsters.log`.
- `InspectMonsterSizeSourceBounds.gd` -> PASS, log `logs\keyed_exit_20260506_004424_r5_bounds.log`.
- Focused forbidden-pattern implementation scan -> PASS for new implementation; only known existing allowed hits remain in grime/transparency experiments and a hide-locker placement validator.
- Android export -> PASS, log `logs\apk_export_keyed_exit_20260506_004424.log`.
- Final Android export after screenshot-tool cleanup -> PASS, log `logs\apk_export_keyed_exit_final_20260506_004424.log`.
- APK file check -> PASS, `builds\android\backrooms_four_room_mvp_debug.apk`, `303406716` bytes.
- `apksigner verify --verbose builds\android\backrooms_four_room_mvp_debug.apk` with `JAVA_HOME=D:\GodotAndroid\jdk-17` -> PASS, v2/v3 verified.
- Final Godot parse after docs/screenshot-tool cleanup -> PASS, log `logs\keyed_exit_final_parse_after_docs_20260506_004424.log`.

Validation result: PASS

Current blocking issue:
- None. Godot still prints known non-blocking resource cleanup warnings on some headless validation exits.

Next step:
- Install and test `builds\android\backrooms_four_room_mvp_debug.apk` on a phone.

## 2026-05-05 Remove Creature And Activate Nightmare Hearing AI

Current objective:
- Delete the Creature monster and make `NightmareCreature_A` an active FourRoomMVP monster that has no vision, hears player footsteps, approaches the last heard prey, and attacks when close. Also reduce and normalize footstep audio.

Current progress:
- Removed `CreatureZombie_A_MVP` from `MonsterSizeSource.tscn`, resource showcase, rebuild script, and validators.
- Deleted project files matching `assets/backrooms/monsters/CreatureZombie_A*`.
- Added `assets/backrooms/monsters/NightmareCreature_Monster.tscn` as a controller-backed Nightmare scene.
- Replaced the static Nightmare source instance with the active hearing-AI scene in `MonsterSizeSource.tscn`.
- Lowered the active Nightmare visual root so `NightmareCreature_A_MVP` bounds now start at about `y=-0.001`, effectively floor-aligned in the size source scene.
- Extended `MonsterController.gd` with `monster_role = "nightmare"`, hearing-only detection, last-heard investigation, nonlethal MVP Nightmare hit metadata, active Nightmare animation mapping, and quieter monster audio defaults.
- Lowered player footstep volume/distance, made pitch variation subtler, and exposed footstep-noise radius methods for Nightmare hearing.

Files changed:
- `scripts/monster/MonsterController.gd`
- `scripts/player/PlayerController.gd`
- `assets/backrooms/monsters/NightmareCreature_A.tscn`
- `assets/backrooms/monsters/NightmareCreature_Monster.tscn`
- `scenes/modules/MonsterSizeSource.tscn`
- `scripts/monster/MonsterSizeSource.gd`
- `scenes/tests/Test_NaturalPropsShowcase.tscn`
- `scripts/tools/BuildNaturalPropScenes.gd`
- `scripts/tools/ValidateMonsterSizeSource.gd`
- `scripts/tools/ValidateFourRoomMVPMonsterSet.gd`
- `scripts/tools/ValidateResourceShowcase.gd`
- `scripts/tools/ValidateImportedMonsterAssets.gd`
- `scripts/tools/ValidateNightmareCreatureAnimationMapping.gd`
- `scripts/tools/ValidateNightmareHearingAI.gd`
- `scripts/tools/InspectMonsterSizeSourceBounds.gd`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/HANDOFF_20260505_IMPORTED_MONSTERS_AND_MVP_TEST.md`
- deleted `assets/backrooms/monsters/CreatureZombie_A*`
- `CURRENT_STATE.md`

Commands run:
- `git status --short` -> FAIL, directory is not a git repository.
- `git diff --stat` -> FAIL, directory is not a git repository.
- Removed 23 `CreatureZombie_A*` files under `assets/backrooms/monsters/` -> PASS.
- `rg` for Creature refs under `scripts`, `scenes`, and `assets` -> PASS, no active references remain.
- Godot parse -> PASS, log `logs\nightmare_hearing_full_parse_20260505.log`.
- `ValidateImportedMonsterAssets.gd` -> PASS, log `logs\nightmare_hearing_full_imported_monsters_20260505.log`.
- `ValidateNightmareCreatureAnimationMapping.gd` -> PASS, log `logs\nightmare_hearing_full_mapping_20260505.log`.
- `ValidateNightmareHearingAI.gd` -> PASS, log `logs\nightmare_hearing_full_ai_20260505.log`.
- `ValidateMonsterSizeSource.gd` -> PASS, log `logs\nightmare_hearing_full_size_source_20260505.log`.
- `ValidateFourRoomMVPMonsterSet.gd` -> PASS, log `logs\nightmare_hearing_full_mvp_monsters_20260505.log`.
- `ValidateResourceShowcase.gd` -> PASS, log `logs\nightmare_hearing_full_resource_showcase_20260505.log`.
- `ValidateMonsterAI.gd` -> PASS, log `logs\nightmare_hearing_full_monster_ai_20260505.log`.
- `ValidateMonsterSavedScale.gd` -> PASS, log `logs\nightmare_hearing_full_saved_scale_20260505.log`.
- `ValidateMonsterCollisionLimit.gd` -> PASS, log `logs\nightmare_hearing_full_collision_20260505.log`.
- `InspectMonsterSizeSourceBounds.gd` -> PASS, log `logs\nightmare_hearing_full_bounds_20260505.log`.
- Nightmare visual grounding retry -> PASS:
  - parse log `logs\nightmare_grounded_parse_20260505.log`
  - bounds log `logs\nightmare_grounded_bounds_20260505.log`
  - size source log `logs\nightmare_grounded_size_source_20260505.log`
  - hearing AI log `logs\nightmare_grounded_ai_20260505.log`
  - FourRoomMVP log `logs\nightmare_grounded_mvp_monsters_20260505.log`
  - resource showcase log `logs\nightmare_grounded_resource_showcase_20260505.log`

Validation result: PASS

Current blocking issue:
- None. Godot headless still prints known cleanup/material warnings in some runs, but all validation exit codes were `0`.

Next step:
- Reload/reopen `MonsterSizeSource.tscn` in the Godot editor to see the Creature removal and active Nightmare source scene.

## 2026-05-05 Reloaded Correct CreatureZombie GLB From Downloads

Current objective:
- Follow the user's request to delete/reload the Creature model from `C:\Users\sigeryang\Downloads\creature__zombie.glb` and make it visible at a suitable size.

Current progress:
- Verified the Downloads GLB exists at `C:\Users\sigeryang\Downloads\creature__zombie.glb`.
- Compared SHA256 hashes and confirmed the Downloads GLB and the project `assets/backrooms/monsters/CreatureZombie_A.glb` were the same file: `380B67975BDB19CE1F91B41355A672674AF3D8E824B332372B2DBC1BE6BFDDE7`.
- Deleted the old project `CreatureZombie_A.glb`, `.glb.import`, and extracted `CreatureZombie_A_*` texture/import files from `assets/backrooms/monsters/`.
- Copied the Downloads GLB back into the project as `assets/backrooms/monsters/CreatureZombie_A.glb`.
- Ran Godot import so the GLB and embedded textures were regenerated.
- Kept the corrected wrapper transform from the previous visibility fix:
  - `assets/backrooms/monsters/CreatureZombie_A.tscn` -> `Model.position = Vector3(0.338, -1.766, 1.01)`
  - `Model.scale = Vector3(3.55, 3.55, 3.55)`
- Confirmed `CreatureZombie_A_MVP` now has visible mesh bounds about `1.56m x 1.69m x 2.52m`, so it should be plainly visible in `MonsterSizeSource.tscn`.

Files changed:
- `assets/backrooms/monsters/CreatureZombie_A.glb`
- `assets/backrooms/monsters/CreatureZombie_A.glb.import`
- regenerated `assets/backrooms/monsters/CreatureZombie_A_*` extracted texture files and `.import` metadata
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`

Commands run:
- SHA256 comparison -> PASS, Downloads GLB and project GLB matched before reload.
- Removed old project `CreatureZombie_A` GLB/import/extracted texture files -> PASS.
- Copied `C:\Users\sigeryang\Downloads\creature__zombie.glb` to `assets\backrooms\monsters\CreatureZombie_A.glb` -> PASS.
- `godot --headless --import --path .` -> PASS, log `logs\reload_creature_zombie_import_20260505_235317.log`; Godot reported the known duplicate `Creeping_Eat` animation-name warning.
- `ValidateImportedMonsterAssets.gd` -> PASS, log `logs\reload_creature_zombie_imported_monsters_20260505_235358.log`.
- `ValidateMonsterSizeSource.gd` -> PASS, log `logs\reload_creature_zombie_monster_size_source_20260505_235358.log`.
- `ValidateFourRoomMVPMonsterSet.gd` -> PASS, log `logs\reload_creature_zombie_mvp_monsters_20260505_235358.log`.
- `ValidateResourceShowcase.gd` -> PASS, log `logs\reload_creature_zombie_resource_showcase_20260505_235358.log`.
- `InspectMonsterSizeSourceBounds.gd` -> PASS, log `logs\reload_creature_zombie_bounds_20260505_235358.log`.
- Forbidden-pattern scan after reload -> PASS for touched work; known existing hits unchanged, log `logs\forbidden_scan_after_reload_creature_zombie_20260505_235423.log`.
- Texture tool process cleanup check -> PASS, `NO_TEXTURE_TOOL_SERVER`.

Validation result: PASS

Current blocking issue:
- None for the Creature reload. If Godot editor still shows the old invisible state, reload `MonsterSizeSource.tscn` from disk or reopen it through `open_monster_size_source.bat`.

Next step:
- Open `open_monster_size_source.bat` and adjust `CreatureZombie_A_MVP` as needed.

## 2026-05-05 CreatureZombie Visibility Fix

Current objective:
- Fix the user's report that `Creature__Zombie` / `CreatureZombie_A_MVP` appears as a label/selection node but no visible model in `MonsterSizeSource.tscn`.

Current progress:
- Confirmed with `InspectMonsterSizeSourceBounds.gd` that `CreatureZombie_A_MVP` existed but its visible mesh bounds were only about `0.012m` tall, so it was effectively invisible in the editor.
- Fixed `assets/backrooms/monsters/CreatureZombie_A.tscn` by changing the wrapper `Model` transform:
  - `position = Vector3(0.338, -1.766, 1.01)`
  - `scale = Vector3(3.55, 3.55, 3.55)`
- After the fix, `CreatureZombie_A_MVP` bounds are about `1.69m` high and visible around its marker/name label.
- Added `scripts/tools/InspectMonsterSizeSourceBounds.gd` for future direct bounds diagnostics.
- Strengthened `ValidateImportedMonsterAssets.gd` so imported monster validation checks actual visible mesh height as well as metadata. This prevents another "metadata exists but model is too tiny to see" regression.
- Synced `NightmareCreature_A_Showcase` scale in `Test_NaturalPropsShowcase.tscn` to the current `MonsterSizeSource.tscn` scale after validation caught the static showcase was still using the older scale.

Files changed:
- `assets/backrooms/monsters/CreatureZombie_A.tscn`
- `scripts/tools/InspectMonsterSizeSourceBounds.gd`
- `scripts/tools/ValidateImportedMonsterAssets.gd`
- `scenes/tests/Test_NaturalPropsShowcase.tscn`
- `CURRENT_STATE.md`

Commands run:
- `InspectMonsterSizeSourceBounds.gd` before fix -> confirmed `CreatureZombie_A_MVP` visual height was about `0.012m`, log `logs\inspect_monster_size_source_bounds_20260505.log`.
- `InspectMonsterSizeSourceBounds.gd` after fix -> confirmed `CreatureZombie_A_MVP` visual height is about `1.69m`, log `logs\inspect_monster_size_source_bounds_after_creature_fix_20260505.log`.
- `ValidateImportedMonsterAssets.gd` probe after fix -> PASS, log `logs\validate_imported_monsters_after_creature_fix_probe_20260505.log`.
- Godot parse after validator strengthening -> PASS, log `logs\creature_zombie_visibility_parse_20260505_234819.log`.
- `ValidateImportedMonsterAssets.gd` after validator strengthening -> PASS, log `logs\creature_zombie_visibility_imported_monsters_20260505_234819.log`.
- `ValidateMonsterSizeSource.gd` after fix -> PASS, log `logs\creature_zombie_visibility_monster_size_source_20260505_234819.log`.
- `ValidateResourceShowcase.gd` first run -> FAIL because `NightmareCreature_A_Showcase` still used old scale while `MonsterSizeSource.tscn` had a saved adjusted scale.
- Synced `NightmareCreature_A_Showcase` scale to `Vector3(0.775966, 0.722142, 0.617676)`.
- `ValidateResourceShowcase.gd` retry -> PASS, log `logs\creature_zombie_visibility_retry_resource_showcase_20260505_234856.log`.
- `ValidateMonsterSizeSource.gd` retry -> PASS, log `logs\creature_zombie_visibility_retry_monster_size_source_20260505_234856.log`.
- `ValidateImportedMonsterAssets.gd` retry -> PASS, log `logs\creature_zombie_visibility_retry_imported_monsters_20260505_234856.log`.

Validation result: PASS

Current blocking issue:
- The Godot editor may already have `MonsterSizeSource.tscn` open in a modified `(*)` tab. Reload the scene from disk before judging the Creature fix, otherwise the viewport may still show the stale open copy.

Next step:
- Reopen `open_monster_size_source.bat` or reload `MonsterSizeSource.tscn` from disk, then select `CreatureZombie_A_MVP` in the Scene tree to adjust its size.

## 2026-05-05 Monster Size Source Selection Helpers

Current objective:
- Explain and fix the editor issue where imported monster GLB meshes are hard to select directly in the viewport.

Current progress:
- The two newly imported models are present in `MonsterSizeSource.tscn`:
  - `CreatureZombie_A_MVP`, the large hunched creature.
  - `NightmareCreature_A_MVP`, the thinner creature.
- The reason they are hard to select by clicking the visible body is that they are nested imported GLB scenes with skeleton/mesh internals; viewport picking often hits the internal bone/mesh selection instead of the outer size-source node that should be scaled.
- Added `EditorSelectHandles` floor markers in `MonsterSizeSource.tscn`:
  - blue markers for controller-backed monsters;
  - yellow markers for the two imported monsters.
- Added `MonsterSizeSourceRuntime.gd` to remove `EditorSelectHandles` at runtime, so these editor markers do not affect gameplay.
- Added yellow `Label3D` name tags above each monster, including `CreatureZombie_A` and `NightmareCreature_A`, so the two newly imported models are immediately identifiable in the editor viewport.

Files changed:
- `scenes/modules/MonsterSizeSource.tscn`
- `scripts/monster/MonsterSizeSourceRuntime.gd`
- `scripts/monster/MonsterSizeSourceRuntime.gd.uid`
- `CURRENT_STATE.md`

Commands run:
- Godot parse -> PASS, log `logs\monster_size_source_handles_parse_20260505_233703.log`.
- `ValidateMonsterSizeSource.gd` -> PASS, log `logs\monster_size_source_handles_validate_20260505_233703.log`.
- `ValidateFourRoomMVPMonsterSet.gd` -> PASS, log `logs\monster_size_source_handles_mvp_20260505_233703.log`.
- Godot parse after name labels -> PASS, log `logs\monster_size_source_labels_parse_20260505_234145.log`.
- `ValidateMonsterSizeSource.gd` after name labels -> PASS, log `logs\monster_size_source_labels_validate_20260505_234145.log`.
- Texture tool process cleanup check -> PASS, `NO_TEXTURE_TOOL_SERVER`.

Validation result: PASS

Current blocking issue:
- None.

Next step:
- In the Scene tree, select the outer monster node such as `CreatureZombie_A_MVP` or `NightmareCreature_A_MVP` to adjust its transform/scale. The colored floor markers are only visual selection aids.

## 2026-05-05 Monster Size Source Launcher

Current objective:
- Add a root `.bat` launcher so the user can directly open the editable monster-size source scene.

Current progress:
- Added `open_monster_size_source.bat`.
- The launcher opens Godot editor with `res://scenes/modules/MonsterSizeSource.tscn` and writes `logs\open_monster_size_source.log`.
- It checks `project.godot`, the Godot 4.6.2 GUI executable, and the target scene before launching.

Files changed:
- `open_monster_size_source.bat`
- `CURRENT_STATE.md`

Commands run:
- Static launcher path check -> PASS: `open_monster_size_source.bat`, `scenes\modules\MonsterSizeSource.tscn`, and Godot GUI executable all exist.

Validation result: PASS

Current blocking issue:
- None.

Next step:
- Double-click `open_monster_size_source.bat` from the project root to open the editable monster-size source scene.

## 2026-05-05 Editable Monster Size Source Scene

Current objective:
- Put all current monsters into the FourRoomMVP room.
- Create one editable `.tscn` source where the user can adjust and save monster sizes.
- Make MVP and generated monster paths use that source scene rather than hardcoded monster sizes.

Current progress:
- Added `scenes/modules/MonsterSizeSource.tscn` as the editable monster-size source scene.
- The source scene contains all current monsters:
  - `Monster`, the original normal controller-backed monster.
  - `Monster_Normal_B`, the second normal controller-backed monster.
  - `Monster_Red_KeyBearer_MVP`, the red key-bearer controller-backed monster.
  - `CreatureZombie_A_MVP`, the imported `CreatureZombie_A` display/prototype monster.
  - `NightmareCreature_A_MVP`, the imported `NightmareCreature_A` candidate monster.
- Replaced `scenes/mvp/FourRoomMVP.tscn` -> `MonsterRoot` with an instance of `MonsterSizeSource.tscn`, preserving old paths such as `MonsterRoot/Monster`.
- Added `scripts/monster/MonsterSizeSource.gd` so code can duplicate a named template from the source scene and preserve its saved scale.
- Updated proc-maze monster generation in `TestProcMazeMap.gd` to instantiate normal/red templates from `MonsterSizeSource.tscn` instead of assigning the old hardcoded `Vector3(0.953989, 0.387199, 0.688722)` scale.
- Updated the resource-showcase rebuild path and validator to read monster scales from `MonsterSizeSource.tscn`.
- Added `ValidateMonsterSizeSource.gd` to verify the editable source scene has all five monsters, all are visible and inside MVP bounds, and FourRoomMVP uses this source scene.
- Updated existing MVP/scale/proc-maze validators so future user size changes in the source scene do not fail only because the old hardcoded scale changed.

Files changed:
- `scenes/modules/MonsterSizeSource.tscn`
- `scripts/monster/MonsterSizeSource.gd`
- `scripts/monster/MonsterSizeSource.gd.uid`
- `scenes/mvp/FourRoomMVP.tscn`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/tools/BuildNaturalPropScenes.gd`
- `scripts/tools/ValidateMonsterSizeSource.gd`
- `scripts/tools/ValidateFourRoomMVPMonsterSet.gd`
- `scripts/tools/ValidateMonsterSavedScale.gd`
- `scripts/tools/ValidateResourceShowcase.gd`
- `scripts/tools/ValidateProcMazeMonsterKey.gd`
- `scenes/tests/Test_NaturalPropsShowcase.tscn`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse -> PASS, log `logs\monster_size_source_parse_20260505_232840.log`.
- `ValidateMonsterSizeSource.gd` -> PASS, log `logs\monster_size_source_monster_size_source_20260505_232855.log`.
- `ValidateFourRoomMVPMonsterSet.gd` -> PASS, log `logs\monster_size_source_mvp_monsters_20260505_232855.log`.
- `ValidateMonsterSavedScale.gd` -> PASS, log `logs\monster_size_source_monster_saved_scale_20260505_232855.log`.
- `ValidateMonsterAI.gd` -> PASS, log `logs\monster_size_source_monster_ai_20260505_232855.log`.
- `ValidateMonsterCollisionLimit.gd` -> PASS, log `logs\monster_size_source_monster_collision_20260505_232855.log`.
- `ValidateImportedMonsterAssets.gd` -> PASS, log `logs\monster_size_source_imported_monsters_20260505_232918.log`.
- `ValidateNightmareCreatureAnimationMapping.gd` -> PASS, log `logs\monster_size_source_nightmare_mapping_20260505_232918.log`.
- `ValidateResourceShowcase.gd` -> PASS, log `logs\monster_size_source_resource_showcase_20260505_232918.log`.
- `ValidateProcMazeMonsterKey.gd` -> PASS, log `logs\monster_size_source_proc_maze_monster_key_20260505_232918.log`.
- Forbidden-pattern scan after edits -> PASS for touched work; known existing hits unchanged, log `logs\forbidden_scan_after_monster_size_source_20260505_232936.log`.
- Godot parse after proc-maze velocity reset -> PASS, log `logs\monster_size_source_parse_after_velocity_20260505_233133.log`.
- `ValidateProcMazeMonsterKey.gd` after proc-maze velocity reset -> PASS, log `logs\monster_size_source_proc_maze_after_velocity_20260505_233133.log`.
- Texture tool process cleanup check -> PASS, `NO_TEXTURE_TOOL_SERVER`.

Validation result: PASS

Current blocking issue:
- None for the editable source scene.
- `CreatureZombie_A_MVP` and `NightmareCreature_A_MVP` are visible in MVP for size review but are not controller-backed gameplay monsters yet.
- Large proc-maze layout placement remains paused; this pass updated the generation code and validator but did not save/rebake the large proc-maze scene.

Next step:
- Open `scenes/modules/MonsterSizeSource.tscn` in Godot, adjust each child monster's transform/scale, and save. FourRoomMVP inherits that scene through `MonsterRoot`; future generated proc-maze monsters and rebuilt resource showcase entries read from it.

## 2026-05-05 NightmareCreature Gameplay Candidate Animation Mapping

Current objective:
- Continue from `docs/HANDOFF_20260505_IMPORTED_MONSTERS_AND_MVP_TEST.md` without touching the paused proc-maze layout.
- Prepare `NightmareCreature_A` for a later gameplay integration pass by recording its usable animation mapping and making the shared monster controller accept optional attack/death animations.

Current progress:
- Confirmed project startup state after handoff. `git status --short` and `git diff --stat` both fail as expected because `E:\godot后室` is not a git repository.
- Ran the handoff baseline validations before edits: Godot parse, imported-monster validation, resource showcase validation, FourRoomMVP monster set validation, Monster AI, saved scale, and collision limit all passed.
- Added optional `attack_animation` and `death_animation` exports to `MonsterController.gd`.
- Red/normal monsters with no attack/death animation configured keep the old behavior by falling back to `idle_animation`.
- `MonsterController.gd` now sets configured attack/death animations to non-looping while keeping current idle/walk/run behavior unchanged.
- Added candidate gameplay animation metadata to `assets/backrooms/monsters/NightmareCreature_A.tscn`:
  - idle: `Creature_armature|idle`
  - walk: `Creature_armature|walk`
  - run: `Creature_armature|Run`
  - attack: `Creature_armature|attack_1`
  - death: `Creature_armature|death_1`
  - hit: `Creature_armature|hit_1`
  - roar: `Creature_armature|roar`
- Added `scripts/tools/ValidateNightmareCreatureAnimationMapping.gd` to verify the metadata maps to real imported GLB animations and that the controller exposes attack/death mapping fields.

Files changed:
- `scripts/monster/MonsterController.gd`
- `assets/backrooms/monsters/NightmareCreature_A.tscn`
- `scripts/tools/ValidateNightmareCreatureAnimationMapping.gd`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse before edits -> PASS, log `logs\resume_parse_20260505_231344.log`.
- `ValidateImportedMonsterAssets.gd` before edits -> PASS, log `logs\resume_imported_monsters_20260505_231359.log`.
- `ValidateResourceShowcase.gd` before edits -> PASS, log `logs\resume_resource_showcase_20260505_231359.log`.
- `ValidateFourRoomMVPMonsterSet.gd` before edits -> PASS, log `logs\resume_mvp_monsters_20260505_231359.log`.
- `ValidateMonsterAI.gd` before edits -> PASS, log `logs\resume_monster_ai_20260505_231359.log`.
- `ValidateMonsterSavedScale.gd` before edits -> PASS, log `logs\resume_monster_scale_20260505_231359.log`.
- `ValidateMonsterCollisionLimit.gd` before edits -> PASS, log `logs\resume_monster_collision_20260505_231359.log`.
- Forbidden-pattern scan before edits -> PASS for touched work; known existing hits are docs/approved foreground cutout/grime/graffiti/old validator context, log `logs\forbidden_scan_before_nightmare_mapping_20260505_231518.log`.
- Godot parse after edits -> PASS, log `logs\nightmare_mapping_parse_20260505_231646.log`.
- `ValidateNightmareCreatureAnimationMapping.gd` -> PASS, log `logs\nightmare_mapping_validate_20260505_231646.log`.
- `ValidateImportedMonsterAssets.gd` after edits -> PASS, log `logs\nightmare_mapping_imported_monsters_20260505_231702.log`.
- `ValidateResourceShowcase.gd` after edits -> PASS, log `logs\nightmare_mapping_resource_showcase_20260505_231702.log`.
- `ValidateFourRoomMVPMonsterSet.gd` after edits -> PASS, log `logs\nightmare_mapping_mvp_monsters_20260505_231702.log`.
- `ValidateMonsterAI.gd` after edits -> PASS, log `logs\nightmare_mapping_monster_ai_20260505_231702.log`.
- `ValidateMonsterSavedScale.gd` after edits -> PASS, log `logs\nightmare_mapping_monster_scale_20260505_231702.log`.
- `ValidateMonsterCollisionLimit.gd` after edits -> PASS, log `logs\nightmare_mapping_monster_collision_20260505_231702.log`.
- Forbidden-pattern scan after edits -> PASS for touched work; known existing hits unchanged, log `logs\forbidden_scan_after_nightmare_mapping_20260505_231725.log`.

Validation result: PASS

Current blocking issue:
- `NightmareCreature_A` is still not wired into gameplay, by design. It now has validated candidate animation metadata, but still needs a separate integration pass for controller scene setup, collision, scale, attribution, optional hit/roar/death behavior, and FourRoomMVP runtime testing.
- Large proc-maze layout placement remains paused.

Next step:
- If the user wants to use `NightmareCreature_A` as a gameplay monster, create a separate controller-backed candidate scene and validate it in `FourRoomMVP` before touching proc-maze.

## 2026-05-05 Handoff For New Session

Current objective:
- Prepare a clean handoff for a new Codex session.

Current progress:
- Added `docs/HANDOFF_20260505_IMPORTED_MONSTERS_AND_MVP_TEST.md`.
- The handoff summarizes the latest imported-monster resource pass, FourRoomMVP monster test setup, current proc-maze layout pause, validation commands, latest logs, known warnings, cleanup rule, and suggested next-session prompt.

Files changed:
- `docs/HANDOFF_20260505_IMPORTED_MONSTERS_AND_MVP_TEST.md`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.

Validation result: PASS

Current blocking issue:
- None. This is a documentation handoff.

Next step:
- New session should read `docs/HANDOFF_20260505_IMPORTED_MONSTERS_AND_MVP_TEST.md` after the existing startup docs and continue from the user's next instruction.

## 2026-05-05 Imported New Monster Resources To Showcase

Current objective:
- Add the two user-provided monster GLBs from `E:\godot后室\新增资源` into the project resource library and the unified resource showcase.
- Analyze the two models before treating them as gameplay-ready monsters.

Current progress:
- Copied the source GLBs into the resource library:
  - `assets/backrooms/monsters/CreatureZombie_A.glb`
  - `assets/backrooms/monsters/NightmareCreature_A.glb`
- Godot imported both GLBs and extracted their embedded textures beside the library copies.
- Created lightweight wrapper scenes:
  - `assets/backrooms/monsters/CreatureZombie_A.tscn`
  - `assets/backrooms/monsters/NightmareCreature_A.tscn`
- Added both wrappers to `scenes/tests/Test_NaturalPropsShowcase.tscn` under `Characters`.
- Updated `BuildNaturalPropScenes.gd` so future resource-showcase rebuilds preserve these two imported monster resources.
- Updated `ValidateResourceShowcase.gd` to require the two imported monsters; the showcase now validates `22` resources.
- Added `ValidateImportedMonsterAssets.gd` to verify source metadata, visible mesh presence, animation counts, estimated display height, and triangle-count metadata.
- Updated `CaptureNaturalPropScene.gd` showcase camera framing so the widened resource display remains visible.
- Captured visual evidence at `artifacts/screenshots/resource_showcase_imported_monsters_20260505.png`.

Model analysis:
- `CreatureZombie_A`: Sketchfab title `Creature_ Zombie`, author `Kapi777`, license `CC-BY-NC-4.0`, about `51716` triangles, `5` meshes, `5` materials, `10` embedded texture images, `21` animations. It needed a strong display scale-down to about `1.69m`. Because it is high-poly and non-commercial licensed, keep it as showcase/reference or non-commercial prototype content unless a proper license/optimization pass happens.
- `NightmareCreature_A`: Sketchfab title `Nightmare Creature 1#`, author `Idk`, license `CC-BY-4.0`, about `6718` triangles, `1` mesh, `1` material, `3` embedded texture images, `22` animations. It displays at about `1.29m` and is the better gameplay candidate after animation mapping and collision setup.

Files changed:
- `assets/backrooms/monsters/CreatureZombie_A.glb`
- `assets/backrooms/monsters/CreatureZombie_A.glb.import`
- `assets/backrooms/monsters/CreatureZombie_A.tscn`
- `assets/backrooms/monsters/CreatureZombie_A_*` extracted texture files and `.import` metadata
- `assets/backrooms/monsters/NightmareCreature_A.glb`
- `assets/backrooms/monsters/NightmareCreature_A.glb.import`
- `assets/backrooms/monsters/NightmareCreature_A.tscn`
- `assets/backrooms/monsters/NightmareCreature_A_*` extracted texture files and `.import` metadata
- `scenes/tests/Test_NaturalPropsShowcase.tscn`
- `scripts/tools/BuildNaturalPropScenes.gd`
- `scripts/tools/ValidateResourceShowcase.gd`
- `scripts/tools/ValidateImportedMonsterAssets.gd`
- `scripts/tools/CaptureNaturalPropScene.gd`
- `artifacts/screenshots/resource_showcase_imported_monsters_20260505.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Python GLB metadata inspection -> PASS.
- `godot --headless --import --path .` -> PASS, log `logs\import_new_monster_assets_import_20260505.log`; Godot reported a non-blocking duplicate animation-name import warning for `CreatureZombie_A`.
- Godot parse -> PASS, log `logs\import_new_monster_assets_parse_final_20260505.log`.
- `ValidateImportedMonsterAssets.gd` -> PASS, log `logs\import_new_monster_assets_validate_final_20260505.log`.
- `ValidateResourceShowcase.gd` -> PASS, log `logs\import_new_monster_resource_showcase_validate_final_20260505.log`.
- Non-headless showcase capture -> PASS, log `logs\import_new_monster_resource_showcase_capture_20260505.log`.

Validation result: PASS

Current blocking issue:
- None for adding the assets to the resource library/showcase.
- Gameplay integration is intentionally not done yet because these GLBs use different rigs/animation names from the current `MonsterController`, and `CreatureZombie_A` has non-commercial licensing plus a high triangle count.

Next step:
- Use `run_resource_showcase.bat` to inspect and scale-review the two imported monsters. Only after selecting one for gameplay should we add collision, animation mapping, AI hookup, optimization, and license-safe production handling.

## 2026-05-05 FourRoomMVP Monster Mechanic Test Set

Current objective:
- Put the monster set into `scenes/mvp/FourRoomMVP.tscn` so the user can test monster behavior in the compact MVP room.
- Keep the player immortal in this MVP test room.
- Do not continue large proc-maze scene placement/layout work while the user may redesign the map.

Current progress:
- Added two additional MVP test monsters under `MonsterRoot`:
  - `Monster_Normal_B`, a second normal monster in Room_B.
  - `Monster_Red_KeyBearer_MVP`, a red key-bearer monster in Room_C.
- Kept the existing `MonsterRoot/Monster` as the first normal monster so existing validations and spawn logic still use the same path.
- Marked the MVP scene and player with `mvp_player_immortal = true`.
- Updated red-monster attack handling so an `mvp_player_immortal` target only records a nonlethal test hit and does not call any damage method.
- Ensured red monsters with `attach_escape_key = true` set `has_escape_key = true` when configuring visuals.
- Enlarged the reusable monster module's simple BoxShape collision to cover the current visible monster body at the accepted MVP scale.
- Added `ValidateFourRoomMVPMonsterSet.gd` to verify the MVP room has exactly two normal monsters, one red key-bearer, the player immortal flag, red chest key visual, nonlethal player hit path, and the normal-monster counter-damage rule.
- Updated old monster AI/collision validators so they remain valid with the new extra MVP test monsters and nonuniform monster root scale.

Files changed:
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/modules/MonsterModule.tscn`
- `scripts/monster/MonsterController.gd`
- `scripts/tools/ValidateFourRoomMVPMonsterSet.gd`
- `scripts/tools/ValidateMonsterAI.gd`
- `scripts/tools/ValidateMonsterCollisionLimit.gd`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse -> PASS, log `logs\mvp_monster_set_parse_final_20260505.log`.
- `ValidateFourRoomMVPMonsterSet.gd` -> PASS, log `logs\mvp_monster_set_validate_final_20260505.log`.
- `ValidateMonsterAI.gd` -> PASS, log `logs\mvp_monster_set_ai_after_collision_20260505.log`.
- `ValidateMonsterSavedScale.gd` -> PASS, log `logs\mvp_monster_set_saved_scale_after_collision_20260505.log`.
- `ValidateMonsterCollisionLimit.gd` -> PASS, log `logs\mvp_monster_set_collision_scaled_validator_20260505.log`.
- `ValidateMobileControls.gd` with `FORCE_MOBILE_CONTROLS=1` -> PASS, log `logs\mvp_monster_set_mobile_controls_20260505.log`.

Validation result: PASS

Current blocking issue:
- None for the MVP monster test room. Large proc-maze layout placement remains paused by user request.

Next step:
- Use `run_mvp_room.bat` to test the three monsters in the compact MVP room. Do not bake or edit the large proc-maze layout until the user gives the new layout direction.

## 2026-05-05 Pause Scene Layout, Fix Mobile Hide/Sprint Controls

Current objective:
- Stop large-scene layout/placement work because the user may redesign the map layout.
- Keep only non-layout control fixes: phone sprint button and a phone-friendly exit button while hiding inside lockers.

Current progress:
- Reverted the partial proc-maze hideable-placement rule change started in this turn; no new large-scene prop placement or bake was kept.
- Added a dedicated `HideLockerExitButtonLayer/ExitHideButton` in `HideableCabinetComponent.gd` while inside a locker. It shows `E 出来` and exits hiding on phone/touch without relying on the player prompt, which is hidden while interaction is locked.
- Enlarged and relabeled the phone sprint button in `PlayerController.gd` from a compact single-character button to `跑步`, and positioned it in the right-thumb area.
- Completed missing non-layout monster/audio helper functions left from the interrupted gameplay pass so the project parses again:
  - monster footstep/roar/attack audio players;
  - red-monster light-flicker trigger call;
  - red attack / normal counter-damage / red key drop helpers;
  - target collider helper.
- Imported the generated local WAV assets under `assets/audio/`.

Files changed:
- `scripts/scene/HideableCabinetComponent.gd`
- `scripts/player/PlayerController.gd`
- `scripts/monster/MonsterController.gd`
- `scripts/lighting/LightingController.gd`
- `scripts/tools/ValidateMobileControls.gd`
- `scripts/tools/ValidateHideableLocker.gd`
- `assets/audio/*.wav` and generated `.import` metadata
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot import -> PASS, imported 10 WAV assets.
- Godot parse -> PASS, log `logs\pause_no_scene_parse_after_fix_20260505.log`.
- `ValidateMobileControls.gd` with `FORCE_MOBILE_CONTROLS=1` -> PASS, `sprint_button=true`.
- `ValidateHideableLocker.gd` -> PASS, including the new `E 出来` button.

Validation result: PASS

Current blocking issue:
- Large-scene layout, extra locker placement, outer-wall exit-door placement, and APK export are intentionally paused until the user decides the new scene layout direction.

Next step:
- Do not bake or alter proc-maze scene placement until the layout decision is clear. Continue only non-layout code/system fixes if requested.

## 2026-05-05 Proc-maze exit location overview screenshot

Current objective:
- Show where the current large proc-maze scene exit is located in the full-map preview.

Current progress:
- Added `CaptureProcMazeExitOverview.gd` to capture the no-ceiling full-map preview and mark the current exit location.
- The screenshot marks:
  - red circle: main-route door frame into the exit room, `DoorFrame_E_N16_N17`, at `(-5.0, 0.0, 51.25)`;
  - orange circle: current `Exit` marker / exit room center, `Marker_N17`, at `(-10.0, 0.05, 48.75)`.
- Important current-state note: this identifies the existing generated exit marker/exit-room door frame. A separate key-locked final escape door is not yet implemented as an interactive gameplay door.

Files changed:
- `scripts/tools/CaptureProcMazeExitOverview.gd`
- `artifacts/screenshots/proc_maze_exit_overview_marked_20260505.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`

Commands run:
- `godot --path . --resolution 1600x1000 --script res://scripts/tools/CaptureProcMazeExitOverview.gd --log-file logs\proc_maze_exit_overview_capture_20260505.log` -> first FAIL due capture-script marker lookup conversion, then PASS after script fix.

Validation result: PASS

Current blocking issue:
- None for the screenshot. Separate locked exit-door gameplay remains unimplemented.

Next step:
- If the user wants the red-monster key to open a real final exit door, add a dedicated door asset/scene on the outer edge of `N17` or another outer-ring module and wire it to key/victory logic.

## 2026-05-05 Interactive resource showcase controls

Current objective:
- Make the unified resource showcase scene directly controllable so resources can be rotated around, selected, and resized for review.

Current progress:
- Added `ResourceShowcaseController.gd` to `Test_NaturalPropsShowcase.tscn`.
- The showcase now opens with a Chinese control panel and supports:
  - right mouse drag to orbit the review camera;
  - mouse wheel zoom;
  - left click to select a resource by its visible bounds;
  - Tab / `[ ]` or UI buttons to switch resources;
  - `Q/E` or UI buttons to rotate the selected resource;
  - `+/-` or UI buttons to scale the selected resource at runtime;
  - `R` reset, `F` focus selected, and `0`/Home focus all.
- Runtime scale edits are review-only and do not write back to the GLB or wrapper scene files.
- Updated `BuildNaturalPropScenes.gd` so future resource showcase rebuilds keep the interactive controller.
- Extended `ValidateResourceShowcase.gd` to require the controller script and review UI.

Files changed:
- `scripts/tools/ResourceShowcaseController.gd`
- `scenes/tests/Test_NaturalPropsShowcase.tscn`
- `scripts/tools/BuildNaturalPropScenes.gd`
- `scripts/tools/ValidateResourceShowcase.gd`
- `artifacts/screenshots/resource_showcase_controls_20260505.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse -> PASS, log `logs/resource_showcase_controls_parse_20260505.log`.
- `ValidateResourceShowcase.gd` -> PASS, log `logs/resource_showcase_controls_validate_20260505.log`.
- Non-headless resource showcase capture -> PASS:
  - `artifacts/screenshots/resource_showcase_controls_20260505.png`

Validation result: PASS

Current blocking issue:
- None.

Next step:
- Use `run_resource_showcase.bat` for resource review. Permanent size corrections should still be applied deliberately to the authored model or wrapper scene, not through the temporary review-scale controls.

## 2026-05-05 Resource showcase launcher and monster default scale

Current objective:
- Add a direct root launcher for the unified resource showcase scene, and keep the proc-maze monster default size aligned with the user's adjusted FourRoomMVP monster scale.

Current progress:
- Added `run_resource_showcase.bat`, which opens `res://scenes/tests/Test_NaturalPropsShowcase.tscn` and writes logs to `logs/run_resource_showcase.log`.
- Updated `scenes/modules/MonsterModule.tscn` so new monster instances default to the FourRoomMVP saved scale `(0.953989, 0.387199, 0.688722)`.
- Updated proc-maze monster spawning in `TestProcMazeMap.gd` to force that same scale on the two normal monsters and the red key-bearer.
- Expanded `Test_NaturalPropsShowcase.tscn` into the unified resource showcase: first-batch natural props, `OldOfficeDoor_A`, `HideLocker_A`, player, normal monster, and red key-bearer monster are now displayed together.
- Updated `BuildNaturalPropScenes.gd` so future natural-prop rebuilds preserve the unified showcase additions instead of reverting the showcase to only the original 15 props.
- Added `ValidateResourceShowcase.gd` to check all 20 current showcase resources and the monster scale.
- Rebaked `scenes/tests/Test_ProcMazeMap.tscn` after the monster scale change.
- Refreshed Android debug APK after the monster scale/resource update: `builds/android/backrooms_proc_maze_mvp_debug.apk`.

Files changed:
- `run_resource_showcase.bat`
- `scenes/modules/MonsterModule.tscn`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/tools/ValidateProcMazeMonsterKey.gd`
- `scripts/tools/ValidateResourceShowcase.gd`
- `scripts/tools/CaptureNaturalPropScene.gd`
- `scripts/tools/BuildNaturalPropScenes.gd`
- `scenes/tests/Test_NaturalPropsShowcase.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `builds/android/backrooms_proc_maze_mvp_debug.apk`
- `artifacts/screenshots/resource_showcase_all_assets_20260505.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse -> PASS.
- `ValidateResourceShowcase.gd` -> PASS, `resources=20 monster_scale=(0.953989, 0.387199, 0.688722)`.
- `ValidateMonsterSavedScale.gd` -> PASS, saved/runtime scale matches `(0.953989, 0.387199, 0.688722)`.
- `BakeTestProcMazeMap.gd` -> PASS.
- `ValidateProcMazeMonsterKey.gd` -> PASS, `monsters=3 red=Monster_Red_KeyBearer key_parts=7 scale=(0.953989, 0.387199, 0.688722)`.
- `ValidateProcMazeProps.gd` -> PASS, `total=34 floor=23 wall=11 hideable=1 modules=20`.
- `ValidateMobileControls.gd` with `FORCE_MOBILE_CONTROLS=1` -> PASS.
- `ValidateNaturalProps.gd` -> PASS, `props=15 placements=16`.
- Non-headless resource showcase capture -> PASS:
  - `artifacts/screenshots/resource_showcase_all_assets_20260505.png`
- Android debug export -> PASS, `builds/android/backrooms_proc_maze_mvp_debug.apk`.
- Static launcher path check -> PASS: `run_resource_showcase.bat`, showcase scene, and Godot executable all exist.
- Final process check -> PASS for texture tool: no `python codex_tools\texture_tool\texture_tool_server.py` process remains.

Validation result: PASS

Current blocking issue:
- None for this pass. Existing Godot editor/run windows remain user-launched and were not killed.

Next step:
- Double-click `run_resource_showcase.bat` to inspect all current authored resources in one scene. Future new resource assets should be added to the same showcase scene and validator.

## 2026-05-05 Red monster chest key and guidance arrow clearance

Current objective:
- Keep generated graffiti arrows away from door frames/wall z-fighting, and put a clear visible key on the red monster's chest in the playable proc-maze MVP.

Current progress:
- Increased generated guidance-arrow door-side clearance and wall-surface offset in `ProcMazeSceneBuilder.gd`; arrow metadata now records `door_side_offset` and `wall_offset` so the validator can reject the old too-close placement.
- Added proc-maze runtime monster spawning in `TestProcMazeMap.gd`: the large playable scene now creates two normal monsters plus one `Monster_Red_KeyBearer` under `MonsterRoot`.
- Added red-monster role support in `MonsterController.gd`. A monster with `monster_role = "red"` gets a clear red material override and, when `attach_escape_key = true`, creates a gold `ChestEscapeKey` visual child.
- Added `ValidateProcMazeMonsterKey.gd` to verify the large scene has exactly three monsters, one red key-bearer, red visual material, and a visible multi-part gold chest key.
- Updated `CaptureTestProcMazeMapScreenshot.gd` with `monster_key` capture mode.
- Rebaked `scenes/tests/Test_ProcMazeMap.tscn`; the baked scene now has 14 guidance arrows with larger clearance metadata and three generated monster instances.
- Exported a refreshed Android debug APK: `builds/android/backrooms_proc_maze_mvp_debug.apk`, size `269268783` bytes.

Files changed:
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/monster/MonsterController.gd`
- `scripts/tools/ValidateGuidanceGraffiti.gd`
- `scripts/tools/ValidateProcMazeMonsterKey.gd`
- `scripts/tools/CaptureTestProcMazeMapScreenshot.gd`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `builds/android/backrooms_proc_maze_mvp_debug.apk`
- `artifacts/screenshots/guidance_arrow_spacing_20260505.png`
- `artifacts/screenshots/red_monster_chest_key_20260505_r3.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse -> PASS.
- `BakeTestProcMazeMap.gd` -> PASS.
- `ValidateGuidanceGraffiti.gd` -> PASS, `arrows=14 exit=N17`.
- `ValidateProcMazeMonsterKey.gd` -> PASS, `monsters=3 red=Monster_Red_KeyBearer key_parts=7`.
- `ValidateProcMazeProps.gd` -> PASS, `total=34 floor=23 wall=11 hideable=1 modules=20`.
- `ValidateMobileControls.gd` with `FORCE_MOBILE_CONTROLS=1` -> PASS.
- Non-headless screenshot capture -> PASS:
  - `artifacts/screenshots/guidance_arrow_spacing_20260505.png`
  - `artifacts/screenshots/red_monster_chest_key_20260505_r3.png`
- Android debug export -> PASS, `builds/android/backrooms_proc_maze_mvp_debug.apk`.
- `apksigner verify --verbose` -> PASS with APK Signature Scheme v2/v3.
- Final process check -> PASS for texture tool: no `python codex_tools\texture_tool\texture_tool_server.py` process remains.

Validation result: PASS

Current blocking issue:
- None for this pass. Existing Godot editor / `run_proc_maze_test` windows remain open and were not killed because they appear to be user-launched.
- Broader red-monster combat, key pickup, and special exit-door victory logic are not part of this small pass and remain separate follow-up work.

Next step:
- Relaunch the currently open DEBUG/run window or install the refreshed APK to see the updated arrow spacing and red key-bearer in-game.

## 2026-05-05 Mobile joystick inset tuning

Current objective:
- Fix the phone movement joystick feeling unusable because it sits too close to the bottom-left screen corner.

Current progress:
- Moved the mobile joystick inward by changing the default radius from `74` to `92` and margin from `Vector2(34, 34)` to `Vector2(126, 126)`. The joystick center is now about `218px` from the left and bottom edges instead of `108px`.
- Added `mobile_joystick_start_radius_multiplier = 3.0` and changed touch-start detection so the enlarged comfortable start area is judged around the joystick center instead of being clipped by the old fixed left-screen percentage check.
- Extended `ValidateMobileControls.gd` to assert that the joystick is no longer too close to the left/bottom edges and that a comfortable thumb start is accepted.
- Re-exported the Android debug APK after the control change: `builds/android/backrooms_proc_maze_mvp_debug.apk`, size `268853211` bytes.
- Checked ADB devices; no Android phone was connected, so the APK was not auto-installed.

Files changed:
- `scripts/player/PlayerController.gd`
- `scripts/tools/ValidateMobileControls.gd`
- `builds/android/backrooms_proc_maze_mvp_debug.apk`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse -> PASS.
- `ValidateMobileControls.gd` with `FORCE_MOBILE_CONTROLS=1` -> initially FAIL because the old fixed left-screen input bound clipped the enlarged start area; after fixing `_is_mobile_stick_start()`, PASS.
- `ValidateProcMazeProps.gd` -> PASS, `total=34 floor=23 wall=11 hideable=1 modules=20`.
- Android debug export -> PASS, `builds/android/backrooms_proc_maze_mvp_debug.apk`.
- `apksigner verify --verbose` -> PASS, v2/v3 signature schemes.
- `adb devices` -> PASS command, no connected devices listed.

Validation result: PASS

Current blocking issue:
- None for the build. Real hand-feel still needs another phone install/test because no device is currently connected through ADB.

Next step:
- Install the updated APK on the phone and test whether the new joystick center/large start area feels usable. If it is still off, tune `mobile_joystick_margin` rather than moving the visual with scene-specific overrides.

## 2026-05-05 D-drive Android toolchain and APK export

Current objective:
- Install the missing Android export dependencies on D drive, configure Godot to use them, and produce a phone-installable debug APK for the current proc-maze MVP scene.

Current progress:
- Installed the Android export toolchain under `D:\GodotAndroid`:
  - JDK: `D:\GodotAndroid\jdk-17`
  - Android SDK: `D:\GodotAndroid\android-sdk`
  - Godot export templates: `D:\GodotAndroid\godot_export_templates\4.6.2.stable`
  - Debug keystore: `D:\GodotAndroid\keystores\debug.keystore`
- Created a junction from `C:\Users\sigeryang\AppData\Roaming\Godot\export_templates\4.6.2.stable` to the D-drive template directory because Godot expects templates under its user-data template path.
- Configured `C:\Users\sigeryang\AppData\Roaming\Godot\editor_settings-4.6.tres` to point at the D-drive JDK, Android SDK, and debug keystore.
- Updated the Android export preset to use the D-drive debug keystore and filled the required Android preset options.
- Enabled `rendering/textures/vram_compression/import_etc2_astc=true`; Godot 4.6 Android export validation fails without ETC2/ASTC import enabled.
- Reimported resources after enabling Android texture formats.
- Fixed the invalid 20-byte proc-maze module placeholder scenes by giving each a minimal `Node3D` root, so Android export no longer reports parse errors for those module paths.
- Added `icon.svg` and `config/icon="res://icon.svg"` for the Android app icon.
- Produced and verified the APK: `builds/android/backrooms_proc_maze_mvp_debug.apk`, size `268849115` bytes.

Files changed:
- `project.godot`
- `export_presets.cfg`
- `icon.svg`
- `scenes/proc_maze/modules/*.tscn` placeholder module files that previously had no root node
- `godot后室新/.gdignore`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Downloaded and extracted Temurin JDK 17 to `D:\GodotAndroid\jdk-17`.
- Downloaded Android command-line tools to `D:\GodotAndroid\android-sdk\cmdline-tools\latest`.
- `sdkmanager --licenses` -> PASS.
- `sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"` -> PASS.
- `sdkmanager "build-tools;35.0.1" "cmake;3.10.2.4988404" "ndk;28.1.13356709"` -> PASS.
- Downloaded Godot `Godot_v4.6.2-stable_export_templates.tpz`, extracted `android_debug.apk` and `android_release.apk` to the D-drive template directory -> PASS.
- `godot --headless --import --path .` after enabling ETC2/ASTC -> PASS.
- Android export initially failed with a blank configuration error; Godot 4.6 source confirmed the missing condition was `rendering/textures/vram_compression/import_etc2_astc`.
- `godot --headless --path . --export-debug Android builds\android\backrooms_proc_maze_mvp_debug.apk` -> PASS.
- `apksigner verify --verbose builds\android\backrooms_proc_maze_mvp_debug.apk` -> PASS, verified with APK Signature Scheme v2 and v3.
- Godot parse after export changes -> PASS.
- `ValidateProcMazeProps.gd` -> PASS, `total=34 floor=23 wall=11 hideable=1 modules=20`.
- `ValidateMobileControls.gd` with `FORCE_MOBILE_CONTROLS=1` -> PASS.

Validation result: PASS

Current blocking issue:
- None. The debug APK exists and signature verification passes. Godot still prints a non-blocking warning that nested `godot后室新/project.godot` is ignored.

Next step:
- Install `builds/android/backrooms_proc_maze_mvp_debug.apk` on an Android device for real touch/performance testing. If a device is connected with USB debugging, use `D:\GodotAndroid\android-sdk\platform-tools\adb.exe install -r builds\android\backrooms_proc_maze_mvp_debug.apk`.

## 2026-05-05 Proc-maze prop placement and mobile APK preparation

Current objective:
- Place the authored environmental props naturally into the large proc-maze scene, make the proc-maze scene the playable main scene, add phone-style controls, and attempt an Android APK export.

Current progress:
- Extended `ProcMazeSceneBuilder.gd` so `LevelRoot/Props` is generated during every proc-maze rebuild. Props now come from the existing reusable GLB wrapper scenes and are placed by space type and solid-wall candidates, not by hand-editing the baked scene.
- Current proc-maze placement validation reports `34` generated props: `23` floor/near-wall props, `11` wall props, and `1` hideable locker across `20` modules. Blocking props are rejected near portals, markers, and corridor spaces.
- Added mobile virtual joystick support to `PlayerController.gd`. On Android/iOS/touch devices it shows a left-bottom movement stick; desktop validation can force it with `FORCE_MOBILE_CONTROLS=1`. Existing tap/click interaction button still calls the same interaction path as keyboard `E`.
- Changed `project.godot` main scene to `res://scenes/tests/Test_ProcMazeMap.tscn`.
- Added `export_presets.cfg` with an Android debug preset targeting `builds/android/backrooms_proc_maze_mvp_debug.apk`, arm64-v8a only, and export exclusions for `artifacts/`, `logs/`, `docs/`, `codex_tools/`, and `builds/`.
- Added `.gdignore` under `artifacts/` and `builds/` so screenshots/build outputs are not imported as game resources.
- Captured current playable proc-maze screenshots:
  - `artifacts/screenshots/proc_maze_props_mobile_main_20260505.png`
  - `artifacts/screenshots/proc_maze_props_focus_20260505.png`

Files changed:
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/player/PlayerController.gd`
- `scripts/tools/ValidateProcMazeProps.gd`
- `scripts/tools/ValidateMobileControls.gd`
- `scripts/tools/CaptureTestProcMazeMapScreenshot.gd`
- `project.godot`
- `export_presets.cfg`
- `artifacts/.gdignore`
- `builds/.gdignore`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `artifacts/screenshots/proc_maze_props_mobile_main_20260505.png`
- `artifacts/screenshots/proc_maze_props_focus_20260505.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse: `--headless --path . --quit` -> PASS.
- `ValidateProcMazeProps.gd` -> PASS, `total=34 floor=23 wall=11 hideable=1 modules=20`.
- `ValidateMobileControls.gd` with `FORCE_MOBILE_CONTROLS=1` -> PASS, joystick input contributed `(0.55, 0.8)`.
- `BakeTestProcMazeMap.gd` -> PASS.
- `ValidateTestProcMazeMap.gd` -> PASS.
- `ValidateProcMazePlayable.gd` -> PASS, player moved through entrance route.
- `BakeTestProcMazeNoCeilingPreview.gd` -> PASS.
- `ValidateProcMazeNoCeilingPreview.gd` -> PASS.
- `ValidateNaturalProps.gd` -> PASS.
- `ValidateBackroomsDoorProps.gd` -> PASS.
- `ValidateHideableLocker.gd` -> PASS.
- `ValidateGeneratedMeshRules.gd` -> PASS.
- Non-headless `CaptureTestProcMazeMapScreenshot.gd` -> PASS, saved `artifacts/screenshots/proc_maze_props_mobile_main_20260505.png`.
- Non-headless `CaptureTestProcMazeMapScreenshot.gd` with `CAPTURE_MODE=prop_focus` -> PASS, saved `artifacts/screenshots/proc_maze_props_focus_20260505.png`.
- Android export attempts -> FAIL. Logs: `logs/android_export_attempt_20260505.log`, `logs/android_export_attempt_after_ignore_20260505.log`.
- Touched-file forbidden-pattern scan -> PASS; only existing/generated `BoxMesh` hits are ceiling-light/generated scene resources, not final prop art.
- Final targeted process check -> PASS; no `texture_tool_server.py`, proc-maze bake/validate/capture, or Android export process remains.

Validation result: BLOCKED

Current blocking issue:
- APK export did not produce a file because this machine is missing the Android export templates, a valid Java SDK path, and a valid Android SDK path. Godot reported missing:
  - `C:/Users/sigeryang/AppData/Roaming/Godot/export_templates/4.6.2.stable/android_debug.apk`
  - `C:/Users/sigeryang/AppData/Roaming/Godot/export_templates/4.6.2.stable/android_release.apk`
  - Java SDK path
  - Android SDK path

Next step:
- Install Godot 4.6.2 Android export templates plus Java SDK and Android SDK, configure those paths in Godot editor settings, then rerun:
  `godot --headless --path . --export-debug Android builds\android\backrooms_proc_maze_mvp_debug.apk`.

## 2026-05-05 Hideable locker slit mask and close-front interaction tuning

Current objective:
- Tune the hideable locker interior view: invert mouse up/down, make black mask areas fully opaque, slightly enlarge the slits, soften the black-frame edge to suggest defocus, and allow any close player facing the cabinet front to press/click interaction and enter.

Current progress:
- Updated `HideableCabinetComponent.gd` so vertical mouse motion is inverted for the locker peek view. Keyboard look behavior was left unchanged.
- Added `apply_peek_mouse_motion()` so the mouse-look math can be validated directly without relying on headless mouse-capture state.
- Rebuilt the slit-view mask as fully opaque black core rectangles plus partial-opacity `SoftMaskEdge` feather strips. This keeps black areas nontransparent while softening the slit/frame edge slightly.
- Widened the visible mask window and made horizontal bars slightly thinner, then enlarged the Blender-authored physical slit spacing by reducing rail height and increasing slit spacing in `create_hideable_locker_blender.py`.
- Added `HideableCabinetComponent.can_interact_from()` and updated `PlayerController.gd` to use it. The player can now enter when close to the cabinet front and facing it, without requiring exact marker alignment.
- Re-exported `HideLocker_A.glb`, reimported it in Godot, rebuilt `HideLocker_A.tscn`, showcase, and the `FourRoomMVP` placement.
- Extended `ValidateHideableLocker.gd` to verify close-front interaction, button entry, inverted mouse pitch, fully opaque core mask rects, and soft mask edge rects.
- Captured updated slit-view screenshot: `artifacts/screenshots/hideable_locker_slit_view_20260505_172927.png`.

Files changed:
- `scripts/tools/create_hideable_locker_blender.py`
- `scripts/scene/HideableCabinetComponent.gd`
- `scripts/player/PlayerController.gd`
- `scripts/tools/ValidateHideableLocker.gd`
- `assets/backrooms/props/furniture/HideLocker_A.glb`
- `assets/backrooms/props/furniture/HideLocker_A.glb.import`
- `assets/backrooms/props/furniture/HideLocker_A.tscn`
- `artifacts/blender_sources/hideables/HideLocker_A.blend`
- `scenes/tests/Test_HideableLockerShowcase.tscn`
- `scenes/mvp/FourRoomMVP.tscn`
- `artifacts/screenshots/hideable_locker_slit_view_20260505_172927.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python -m py_compile scripts\tools\create_hideable_locker_blender.py` -> PASS.
- `godot --headless --path . --quit` -> PASS.
- `blender --background --python scripts\tools\create_hideable_locker_blender.py` -> PASS.
- `godot --headless --import --path .` -> PASS.
- `godot --headless --path . --script res://scripts/tools/BuildHideableLockerScene.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateHideableLocker.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateNaturalProps.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateBackroomsDoorProps.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidatePlayerAnimation.gd` -> PASS.
- `godot --path . --script res://scripts/tools/CaptureHideableLockerScene.gd` with `CAPTURE_MODE=slit_view` -> PASS; saved `artifacts/screenshots/hideable_locker_slit_view_20260505_172927.png`.
- Removed transient `scripts/tools/__pycache__` if present.
- Final targeted process check -> PASS; no `texture_tool_server.py`, hideable Blender export, Godot build/validate, or capture script process remains.

Validation result: PASS

Current blocking issue:
- None. Godot still prints the known non-blocking MCP port message when another Godot instance owns port 7777.

Next step:
- Relaunch the currently open MVP/DEBUG window before judging the updated slit view and close-front interaction in-game.

## 2026-05-05 Hideable locker one-piece door and interaction button pass

Current objective:
- Fix `HideLocker_A` so the front reads as one integrated cabinet door with upper viewing slits, and add a visible interaction button while preserving keyboard `E` entry.

Current progress:
- Updated `scripts/tools/create_hideable_locker_blender.py` so the lower front is exported as `HideLocker_A_front_door_one_piece_panel`, widened to the full door face instead of reading as an inset separate lower board.
- Re-exported `assets/backrooms/props/furniture/HideLocker_A.glb` and `artifacts/blender_sources/hideables/HideLocker_A.blend`, then reimported through Godot and rebuilt `HideLocker_A.tscn`, showcase, and the `FourRoomMVP` placement.
- Added a lightweight player `InteractionPromptLayer/InteractButton` in `PlayerController.gd`. Near a hideable locker it displays `E 进入`; near a door it displays `E 开门` or `E 关门`. Pressing the button calls the same interaction path as keyboard `E`.
- Extended `ValidateHideableLocker.gd` to reject the old separate lower-panel mesh name, require the integrated door-panel mesh, validate that the prompt button appears, and confirm the button can enter the locker.
- Added `mvp_prompt` capture mode in `CaptureHideableLockerScene.gd` to place the player near the MVP locker and show the prompt in a screenshot.

Files changed:
- `scripts/tools/create_hideable_locker_blender.py`
- `scripts/player/PlayerController.gd`
- `scripts/tools/ValidateHideableLocker.gd`
- `scripts/tools/CaptureHideableLockerScene.gd`
- `assets/backrooms/props/furniture/HideLocker_A.glb`
- `assets/backrooms/props/furniture/HideLocker_A.glb.import`
- `assets/backrooms/props/furniture/HideLocker_A.tscn`
- `artifacts/blender_sources/hideables/HideLocker_A.blend`
- `scenes/tests/Test_HideableLockerShowcase.tscn`
- `scenes/mvp/FourRoomMVP.tscn`
- `artifacts/screenshots/hideable_locker_mvp_prompt_20260505_170200.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python -m py_compile scripts\tools\create_hideable_locker_blender.py` -> PASS.
- `godot --headless --path . --quit` -> PASS.
- `blender --background --python scripts\tools\create_hideable_locker_blender.py` -> PASS.
- `godot --headless --import --path .` -> PASS.
- `godot --headless --path . --script res://scripts/tools/BuildHideableLockerScene.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateHideableLocker.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateNaturalProps.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateBackroomsDoorProps.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidatePlayerAnimation.gd` -> PASS.
- `godot --path . --script res://scripts/tools/CaptureHideableLockerScene.gd` with `CAPTURE_MODE=mvp_prompt` -> PASS; saved `artifacts/screenshots/hideable_locker_mvp_prompt_20260505_170200.png`.
- Removed transient `scripts/tools/__pycache__` if present.
- Final targeted process check -> PASS; no `texture_tool_server.py`, hideable Blender export, Godot build/validate, or capture script process remains.

Validation result: PASS

Current blocking issue:
- None. Godot still prints the known non-blocking MCP port message when another Godot instance owns port 7777.

Next step:
- Relaunch the currently open MVP/DEBUG window before judging the locker in-game so the rebuilt GLB, wrapper scene, and player UI script reload.

## 2026-05-05 Hideable locker MVP placement follow-up

Current objective:
- Answer where the previous pass spent the most time, then place the newly made hideable locker into `FourRoomMVP` for actual MVP-scene review. Future small/prop assets should also get a deliberate MVP placement for player-view validation unless the user explicitly asks for resource-only work.

Current progress:
- Identified the main time sink: the final slit-view visual pass, where the first inside screenshot was nearly black and required reworking the physical slit opening, camera/view setup, lighting, and screenshot validation.
- Rebuilt `HideLocker_A.tscn` and placed one instance in `scenes/mvp/FourRoomMVP.tscn` as `LevelRoot/Props/RoomC_HideLocker_A`.
- The locker is positioned in Room_C at `Vector3(8.58, 0.0, 7.32)`, near the east wall, facing inward, away from P_BC/P_CD door centers and the room center.
- Updated natural-prop rebuild/validation logic so the existing 16 natural prop placements remain separate from hideable MVP props: natural prop rebuilds preserve hideable props, and natural prop validation ignores `hideable_prop_id` extras.
- Added `mvp_room_c` screenshot mode to `CaptureHideableLockerScene.gd` for direct MVP review.

Files changed:
- `scripts/tools/BuildHideableLockerScene.gd`
- `scripts/tools/ValidateHideableLocker.gd`
- `scripts/tools/ValidateNaturalProps.gd`
- `scripts/tools/BuildNaturalPropScenes.gd`
- `scripts/tools/CaptureHideableLockerScene.gd`
- `scenes/mvp/FourRoomMVP.tscn`
- `artifacts/screenshots/hideable_locker_mvp_room_c_20260505_163757.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `godot --headless --path . --script res://scripts/tools/BuildHideableLockerScene.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateHideableLocker.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateNaturalProps.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateBackroomsDoorProps.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/CaptureHideableLockerScene.gd` with `CAPTURE_MODE=mvp_room_c` -> FAIL because headless dummy rendering returned no viewport texture.
- `godot --path . --script res://scripts/tools/CaptureHideableLockerScene.gd` with `CAPTURE_MODE=mvp_room_c` -> PASS; saved `artifacts/screenshots/hideable_locker_mvp_room_c_20260505_163757.png`.
- Removed transient `scripts/tools/__pycache__` if present.
- Final targeted process check -> PASS; no `texture_tool_server.py`, hideable/natural build, validation, or capture script process remains. Existing unrelated Godot/editor processes were left alone.

Validation result: PASS

Current blocking issue:
- None. Godot still prints the known non-blocking MCP port message when another Godot instance owns port 7777.

Next step:
- Relaunch the currently open MVP/DEBUG window before judging the newly placed locker in-game, because already-running windows can keep stale scene/imported resources.

## 2026-05-05 Hideable locker asset and slit-view interaction pass

Current objective:
- Create one Backrooms-style standing hideable locker/cabinet through the image2 reference -> Blender model -> GLB -> Godot reusable scene -> resource showcase flow. The upper slits must support hiding inside and looking out with a restricted slit view.

Current progress:
- Generated the image2 reference board for `HideLocker_A` and saved it as `artifacts/references/hideables/HideLocker_A_reference_20260505.png`.
- Installed/located a command-line Blender 5.1.1 executable because the active shell did not have `blender.exe` available in PATH.
- Added `scripts/tools/create_hideable_locker_blender.py` and exported a low/mid-poly metric old beige-gray metal locker with upper horizontal slits, hinge/handle details, simple wear, bottom dust, dull metal, and generated procedural albedo textures. The reference image is not used as a final texture.
- Exported `assets/backrooms/props/furniture/HideLocker_A.glb` and `artifacts/blender_sources/hideables/HideLocker_A.blend`.
- Created reusable wrapper `assets/backrooms/props/furniture/HideLocker_A.tscn` with `HideableCabinetComponent`, `Model`, simple `StaticBody3D + BoxShape3D` collision, `HideStandPoint`, `HideCameraAnchor`, `ExitMarker`, and `InteractionPoint`.
- Extended `PlayerController.gd` so `E` first checks nearby `interactive_hideable` props, while preserving the existing door interaction path.
- Added `HideableCabinetComponent.gd`: entering hides/locks the player, disables player collision, moves the camera to the cabinet slit anchor, narrows FOV to `34`, clamps view to `18°` yaw / `8°` pitch, and adds a slit-shaped UI mask. Pressing `E` again exits and restores player/camera state.
- Added `scenes/tests/Test_HideableLockerShowcase.tscn` for resource display.
- Added `ValidateHideableLocker.gd` for resource, collision, slit geometry, showcase, and E enter/exit interaction validation.
- Added `CaptureHideableLockerScene.gd` and captured both outside showcase and inside slit-view screenshots.
- Fixed the first slit-view visual pass: removed black filler geometry from the actual slit openings so the camera can see out through the physical gaps; the dark interior is now behind the slit area instead of blocking the slits.

Files changed:
- `scripts/tools/create_hideable_locker_blender.py`
- `scripts/scene/HideableCabinetComponent.gd`
- `scripts/player/PlayerController.gd`
- `scripts/tools/BuildHideableLockerScene.gd`
- `scripts/tools/ValidateHideableLocker.gd`
- `scripts/tools/CaptureHideableLockerScene.gd`
- `assets/backrooms/props/furniture/HideLocker_A.glb`
- `assets/backrooms/props/furniture/HideLocker_A.glb.import`
- `assets/backrooms/props/furniture/HideLocker_A.tscn`
- `assets/backrooms/props/furniture/HideLocker_A_old_beige_gray_locker_metal_procedural_albedo.png`
- `assets/backrooms/props/furniture/HideLocker_A_slightly_darker_side_metal_procedural_albedo.png`
- `artifacts/blender_sources/hideables/HideLocker_A.blend`
- `artifacts/references/hideables/HideLocker_A_reference_20260505.png`
- `scenes/tests/Test_HideableLockerShowcase.tscn`
- `artifacts/screenshots/hideable_locker_showcase_20260505_154726.png`
- `artifacts/screenshots/hideable_locker_slit_view_20260505_160403.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- image2 generation for `HideLocker_A` reference -> PASS.
- `python -m py_compile scripts\tools\create_hideable_locker_blender.py` -> PASS.
- `winget search --name Blender --accept-source-agreements` -> PASS.
- `winget install --id BlenderFoundation.Blender --source winget --accept-source-agreements --accept-package-agreements --silent --disable-interactivity` -> PASS.
- `blender --background --python scripts\tools\create_hideable_locker_blender.py` -> PASS after removing the slit filler geometry and fixing indentation.
- Inline GLB inspection -> PASS; final GLB has 43 nodes, 7 named `view_slit` rail meshes, and old metal/interior/handle/wear materials.
- `godot --headless --path . --quit` -> PASS using the explicit Godot executable path.
- `godot --headless --import --path .` -> PASS.
- `godot --headless --path . --script res://scripts/tools/BuildHideableLockerScene.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateHideableLocker.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateBackroomsDoorProps.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateNaturalProps.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateGeneratedMeshRules.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidatePlayerAnimation.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidatePlayerAnimationCollision.gd` -> PASS.
- `godot --path . --script res://scripts/tools/CaptureHideableLockerScene.gd` -> PASS for:
  - `artifacts/screenshots/hideable_locker_showcase_20260505_154726.png`
  - `artifacts/screenshots/hideable_locker_slit_view_20260505_160403.png`
- Primitive scan for `CSG`, `PlaneMesh`, and `BoxMesh` in the final locker asset/script targets -> PASS; no final primitive art matches.
- Touched-file forbidden scan -> PASS for asset art constraints; the only text match was validator wording about FOV narrowing.
- Removed transient `scripts/tools/__pycache__`.
- Final targeted process check -> PASS; no `texture_tool_server.py`, hideable-locker Blender export, Godot build/validate, or capture script process remains. Existing user/editor processes were left alone.

Validation result: PASS

Current blocking issue:
- None. Godot still prints known non-blocking MCP port and cleanup/leak warnings in some validations even when commands exit `0`.

Next step:
- Open `scenes/tests/Test_HideableLockerShowcase.tscn` or instantiate `assets/backrooms/props/furniture/HideLocker_A.tscn` in a gameplay scene. Stand near the front of the locker and press `E` to enter/exit; relaunch already-open Godot windows so the updated GLB and wrapper reload.

## 2026-05-05 Door gap and E interaction pass

Current objective:
- Fix the visible top gap above `OldOfficeDoor_A` and make the selected MVP door open with `E`, swinging toward the player's facing direction.

Current progress:
- Increased the Blender-authored door panel height from `2.05m` to `2.09m`, so the panel reaches the existing door-frame inner top without leaving the visible slit shown in the player screenshot.
- Re-exported `OldOfficeDoor_A.glb` and rebuilt the Godot wrapper/scene placement.
- Changed `OldOfficeDoor_A.tscn` from a center-rotating door to a hinged wrapper: root `DoorComponent`, child `HingePivot`, then `Model` and `CollisionBody` under the pivot. The simple BoxShape collision now rotates with the door.
- Extended `DoorComponent.gd` with `open_toward_direction()`, `interact_from()`, target-angle animation, and an `interactive_door` group.
- Added `interact` input action bound to `E` in `PlayerController.gd`. Pressing E finds the closest facing door within range and calls the door interaction path.
- Updated `SceneBuilder.gd` so runtime rebuilds relink existing selected doors back to their matching `PortalComponent` by `portal_id`; portal state now reads the door after both baked and runtime builds.
- Updated `ValidateBackroomsDoorProps.gd` to check door height, hinge pivot, collision, player interaction path, E binding, door animation, and portal state.
- Added `door_p_bc_open` capture mode for open-door visual checks.

Files changed:
- `scripts/tools/create_backrooms_doors_blender.py`
- `scripts/tools/BuildBackroomsDoorScenes.gd`
- `scripts/scene/DoorComponent.gd`
- `scripts/player/PlayerController.gd`
- `scripts/core/SceneBuilder.gd`
- `scripts/tools/ValidateBackroomsDoorProps.gd`
- `scripts/tools/CaptureNaturalPropScene.gd`
- `assets/backrooms/props/doors/OldOfficeDoor_A.glb`
- `assets/backrooms/props/doors/OldOfficeDoor_A.glb.import`
- `assets/backrooms/props/doors/OldOfficeDoor_A.tscn`
- `assets/backrooms/props/doors/OldOfficeDoor_A_old_yellowed_door_panel_procedural_albedo.png.import`
- `artifacts/blender_sources/doors/OldOfficeDoor_A.blend`
- `scenes/mvp/FourRoomMVP.tscn`
- `artifacts/screenshots/door_p_bc_interaction_20260505_145851.png`
- `artifacts/screenshots/door_p_bc_open_interaction_20260505_145851.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python -m py_compile scripts\tools\create_backrooms_doors_blender.py` -> PASS.
- `godot --headless --path . --quit` -> PASS.
- `blender --background --python scripts\tools\create_backrooms_doors_blender.py` -> PASS.
- `godot --headless --import --path .` -> PASS.
- `godot --headless --path . --script res://scripts/tools/BuildBackroomsDoorScenes.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateBackroomsDoorProps.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateNaturalProps.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateCleanRebuildScene.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateGeneratedMeshRules.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidatePlayerAnimation.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidatePlayerAnimationCollision.gd` -> PASS.
- `godot --headless --path . --scene res://scenes/mvp/FourRoomMVP.tscn --quit-after 3` -> PASS.
- `godot --path . --script res://scripts/tools/CaptureNaturalPropScene.gd` -> PASS for closed/open screenshots:
  - `artifacts/screenshots/door_p_bc_interaction_20260505_145851.png`
  - `artifacts/screenshots/door_p_bc_open_interaction_20260505_145851.png`
- Door primitive scan for `CSG`, `PlaneMesh`, and `BoxMesh` under `assets/backrooms/props/doors` -> PASS; no matches.
- Project forbidden-pattern scan on touched door/player/core/tool paths -> PASS.
- Removed transient `scripts/tools/__pycache__`.
- Final targeted process check -> PASS; no `texture_tool_server.py`, door Blender/export/build/validate/capture script process remains.

Validation result: PASS

Current blocking issue:
- None. Godot validation can still print known cleanup/leak warnings at process exit even when the validation command exits `0`; these did not block the checks.

Next step:
- Relaunch the MVP/DEBUG window and press `E` near the P_BC door while facing it. The already-open window may still show stale scene resources until restarted.

## 2026-05-05 Selected old-office door asset pass

Current objective:
- Add one Backrooms-style old office door that matches the existing MVP door-frame size and scene mood, using the required image2 reference -> Blender model -> GLB -> Godot wrapper -> selected scene placement flow.

Current progress:
- Generated an image2 reference board for `OldOfficeDoor_A` and saved it under `artifacts/references/doors/OldOfficeDoor_A_reference_20260505.png`.
- Added a Blender source/export script for a metric, low/mid-poly old beige door with dull metal handle/hinges, subtle grime, edge wear, and a generated procedural door-panel albedo texture. The image2 reference is not used as a texture.
- Exported `OldOfficeDoor_A.glb` and editable `OldOfficeDoor_A.blend`.
- Imported the GLB into `assets/backrooms/props/doors/` and created reusable `OldOfficeDoor_A.tscn` with `DoorComponent`, `Model`, and simple `StaticBody3D + BoxShape3D` collision.
- Placed exactly one selected door instance in `scenes/mvp/FourRoomMVP.tscn`: `LevelRoot/Doors/Door_P_BC_OldOffice_A`, centered on portal `P_BC`. Other door frames remain without this door.
- Added `ValidateBackroomsDoorProps.gd` and a `door_p_bc` capture mode for focused validation screenshots.
- Added `artifacts/references/.gdignore` and removed generated `.import` files under `artifacts/references/` so image2 reference boards stay modeling references, not Godot-imported resources.

Files changed:
- `scripts/tools/create_backrooms_doors_blender.py`
- `scripts/tools/BuildBackroomsDoorScenes.gd`
- `scripts/tools/ValidateBackroomsDoorProps.gd`
- `scripts/tools/CaptureNaturalPropScene.gd`
- `assets/backrooms/props/doors/OldOfficeDoor_A.glb`
- `assets/backrooms/props/doors/OldOfficeDoor_A.glb.import`
- `assets/backrooms/props/doors/OldOfficeDoor_A.tscn`
- `assets/backrooms/props/doors/OldOfficeDoor_A_old_yellowed_door_panel_procedural_albedo.png`
- `assets/backrooms/props/doors/OldOfficeDoor_A_old_yellowed_door_panel_procedural_albedo.png.import`
- `artifacts/blender_sources/doors/OldOfficeDoor_A.blend`
- `artifacts/references/.gdignore`
- `artifacts/references/doors/OldOfficeDoor_A_reference_20260505.png`
- `artifacts/screenshots/backrooms_door_p_bc_20260505_133648.png`
- `artifacts/screenshots/backrooms_door_p_bc_wide_20260505_133821.png`
- `scenes/mvp/FourRoomMVP.tscn`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- image2 generation for `OldOfficeDoor_A` reference -> PASS.
- `python -m py_compile scripts\tools\create_backrooms_doors_blender.py` -> PASS.
- `blender --background --python scripts\tools\create_backrooms_doors_blender.py` -> PASS; exported `OldOfficeDoor_A.glb` and `.blend`.
- Inline GLB inspection -> PASS; door GLB contains old door-panel, wear, seam/shadow, and metal materials with a generated procedural albedo image.
- `godot --headless --import --path .` -> PASS; imported the door GLB and procedural texture.
- `godot --headless --path . --script res://scripts/tools/BuildBackroomsDoorScenes.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateBackroomsDoorProps.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateNaturalProps.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateCleanRebuildScene.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateGeneratedMeshRules.gd` -> PASS.
- `godot --path . --script res://scripts/tools/CaptureNaturalPropScene.gd` -> PASS for:
  - `artifacts/screenshots/backrooms_door_p_bc_20260505_133648.png`
  - `artifacts/screenshots/backrooms_door_p_bc_wide_20260505_133821.png`
- Door primitive scan for `CSG`, `PlaneMesh`, and `BoxMesh` under `assets/backrooms/props/doors` -> PASS; no matches.
- Scene instance scan -> PASS; only `Door_P_BC_OldOffice_A` is placed under `LevelRoot/Doors`.
- Removed generated `.import` files under `artifacts/references/`.
- Removed transient `scripts/tools/__pycache__`.
- Final targeted process check -> PASS; no `texture_tool_server.py`, door Blender/export/build/validate/capture script process remains.

Validation result: PASS

Current blocking issue:
- None. Godot validation commands may still print the known non-blocking MCP port 7777 message if another Godot process owns that port.

Next step:
- Relaunch the currently open DEBUG/MVP game window before judging the door in-game, because already-running Godot windows can show stale imported resources and baked scene wrappers.

## 2026-05-05 Natural prop collision and material realism pass

Current objective:
- Fix the visible clipping issue where the player can stand inside the cleaning corner bucket/mop and old chair, and make those natural props read less like flat temporary materials.

Current progress:
- Added simple reusable wrapper collisions for `Bucket_A`, `Mop_A`, and `Chair_Old_A` using `StaticBody3D + CollisionShape3D + BoxShape3D`.
- Marked those three props as `blocks_path=true`; validation confirms their FourRoomMVP placements remain away from door openings and walkable room centers.
- Updated the natural-prop validator so `Bucket_A`, `Mop_A`, and `Chair_Old_A` are expected to have collision.
- Improved the Blender source asset pass for the screenshot props: bucket inner shadow/rim wear/scuffs, mop handle wear and cloth variation, and chair vinyl/fabric wear, edge scuffs, underside shadow, and dark feet.
- Added small generated procedural albedo textures from the Blender script for old blue-gray plastic, old cloth, old tan vinyl, and old beige furniture. These are generated from code, not from the reference images, and Godot imported the resulting low-resolution texture PNGs beside the GLBs.
- Tuned the procedural texture export so the glTF base color does not multiply the albedo texture and over-darken the bucket/chair.
- Added `room_b_close` and `room_c_chair` capture modes for focused visual checks of the cleaning corner and old chair.

Files changed:
- `scripts/tools/create_natural_props_blender.py`
- `scripts/tools/BuildNaturalPropScenes.gd`
- `scripts/tools/ValidateNaturalProps.gd`
- `scripts/tools/CaptureNaturalPropScene.gd`
- `assets/backrooms/props/**/{*.glb,*.glb.import,*.tscn}`
- `assets/backrooms/props/**/*procedural_albedo.png`
- `assets/backrooms/props/**/*procedural_albedo.png.import`
- `artifacts/blender_sources/natural_props/*.blend`
- `scenes/tests/Test_NaturalPropsShowcase.tscn`
- `scenes/mvp/FourRoomMVP.tscn`
- `artifacts/screenshots/natural_props_collision_materials_*20260505*.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python -m py_compile scripts\tools\create_natural_props_blender.py` -> PASS.
- `blender --background --python scripts\tools\create_natural_props_blender.py` -> PASS; re-exported all 15 natural-prop GLBs and `.blend` sources.
- Inline GLB material/texture inspection -> PASS; `Bucket_A`, `Mop_A`, and `Chair_Old_A` contain generated procedural albedo textures where expected.
- `godot --headless --import --path .` -> PASS; reimported GLBs and extracted low-resolution procedural texture PNGs.
- `godot --headless --path . --script res://scripts/tools/BuildNaturalPropScenes.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateNaturalProps.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateCleanRebuildScene.gd` -> PASS.
- `godot --headless --path . --script res://scripts/tools/ValidateGeneratedMeshRules.gd` -> PASS.
- `godot --path . --script res://scripts/tools/CaptureNaturalPropScene.gd` -> PASS for final close screenshots:
  - `artifacts/screenshots/natural_props_collision_materials_textured_final_room_b_close_20260505_131135.png`
  - `artifacts/screenshots/natural_props_collision_materials_textured_final_room_c_chair_20260505_131206.png`
- Final wrapper collision scan -> PASS for `Bucket_A`, `Mop_A`, and `Chair_Old_A`.
- Final prop primitive scan for `CSG`, `PlaneMesh`, and `BoxMesh` under `assets/backrooms/props` -> PASS; no matches.
- Removed transient `scripts/tools/__pycache__`.
- Final targeted process check -> PASS; no `texture_tool_server.py`, natural-prop Blender script, capture script, build script, or validation script process remains.

Validation result: PASS

Current blocking issue:
- None. Godot commands still show the known non-blocking MCP runtime port 7777 already-in-use message when another Godot instance owns that port; validation and captures exited successfully.

Next step:
- Relaunch the currently open DEBUG game window before judging the in-game result, because already-running Godot windows can show stale imported resources and scene-local wrappers.

## 2026-05-05 Texture tool edge-layer vertical offset visibility fix

Current objective:
- Fix the layer-composition vertical offset so bottom/top grime visibly moves in the texture-tool preview and Godot runtime random wall grime.

Current progress:
- Confirmed the bug: bottom-anchored overlays were placed at the canvas bottom first, then positive-down offset was clamped back to the same bottom edge, so values like `0.46` could not visibly move the stain.
- Changed `_overlay_position()` so bottom/top layers offset relative to their edge band. Bottom positive values move downward past the wall foot and are clipped by the canvas; negative values move upward into the wall. Top layers use the same positive-down rule.
- Changed `_blend_overlay()` to safely crop overlays that move partly outside the image instead of forcing every overlay back inside the canvas.
- Updated `contact_ao_surface.gdshader` so runtime random wall grime uses the same unclamped edge-band offset behavior instead of clamping bottom positive offset back to the old location.
- Verified with image-level comparison that the same wall layer has different vertical positions at `position_y_offset=-0.46`, `0.0`, and `0.46`.

Files changed:
- `codex_tools/texture_tool/texture_tool_server.py`
- `materials/shaders/contact_ao_surface.gdshader`
- `materials/textures/backrooms_wall_runtime_grime_atlas.png`
- `materials/textures/backrooms_wall_runtime_grime_config.json`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py scripts\tools\build_runtime_wall_grime_atlas.py` -> PASS.
- Inline image comparison for wall layer offsets `-0.46 / 0.0 / 0.46` -> PASS; measured dirty-pixel vertical centroid moved from `754.9` to `886.82` to `981.17`.
- `python codex_tools\texture_tool\texture_tool_server.py --self-test` -> PASS.
- `python scripts\tools\build_runtime_wall_grime_atlas.py` -> PASS, `candidates=8`.
- `godot --headless --path . --script res://scripts/tools/ValidateGeneratedMeshRules.gd` -> PASS.
- Removed transient Python `__pycache__` folders.
- Final process check -> PASS; no `python codex_tools\texture_tool\texture_tool_server.py` process remains.

Validation result: PASS

Current blocking issue:
- None for the offset movement fix.

Next step:
- Restart the texture tool server/browser page, then adjust `上下偏移 -1~1（正数向下）`. For a bottom/墙脚 layer, positive values now push the stain downward toward/past the wall foot; negative values move it upward into the wall.

## 2026-05-05 Natural environment props pipeline pass

Current objective:
- Build the first Backrooms natural-environment prop batch through the required image2 reference -> Blender asset -> individual GLB -> Godot wrapper scene -> FourRoomMVP natural placement flow.

Current progress:
- Generated 4 reference boards under `artifacts/references/natural_props/`: boxes, cleaning props, old furniture, and industrial maintenance props.
- Added a Blender generation/export script that creates 15 low/mid-poly metric assets with simple PBR materials and no image-texture projection, text, logos, warning signs, arrows, blood, or gameplay hints.
- Exported individual GLBs to the required Godot resource directories under `assets/backrooms/props/boxes`, `cleaning`, `furniture`, and `industrial`.
- Added `.gdignore` to `artifacts/blender_sources/` so Godot does not try to import the editable `.blend` source files.
- Created 15 reusable prop wrapper scenes. Blocking/simple-collision wrappers: `Box_Medium_A`, `Box_Large_A`, `Box_Stack_2_A`, `Box_Stack_3_A`, `SmallCabinet_A`, `MetalShelf_A`. Small/wall/detail props stay nonblocking.
- Created `scenes/tests/Test_NaturalPropsShowcase.tscn` for size/material review.
- Placed 16 natural prop instances under `FourRoomMVP.tscn` `LevelRoot/Props`, grouped by room use: Room_A corner boxes, Room_B maintenance/cleaning wall, Room_C storage/old-office side, Room_D upper wall/pipe/low cloth detail.
- Fixed the first material export pass: Blender 5.1 did not match the old `Principled BSDF` node name, so GLBs exported default white. The script now sets material color by BSDF node type and `diffuse_color`; GLB material JSON confirms kraft cardboard, gray metal, blue-gray plastic, and beige furniture colors.
- Fixed the prop scene build script to assign owners for generated `Geometry`, `Areas`, `Portals`, `Markers`, `Lights`, and `Props` before saving, preserving baked FourRoomMVP geometry.
- Updated the capture script to hide ceiling nodes only for screenshot review and support a no-props before capture without modifying the scene.

Files changed:
- `scripts/tools/create_natural_props_blender.py`
- `scripts/tools/BuildNaturalPropScenes.gd`
- `scripts/tools/ValidateNaturalProps.gd`
- `scripts/tools/CaptureNaturalPropScene.gd`
- `assets/backrooms/props/**/{*.glb,*.glb.import,*.tscn}`
- `artifacts/blender_sources/.gdignore`
- `artifacts/blender_sources/natural_props/*.blend`
- `artifacts/references/natural_props/*.png`
- `scenes/tests/Test_NaturalPropsShowcase.tscn`
- `scenes/mvp/FourRoomMVP.tscn`
- `artifacts/screenshots/natural_props_*20260505.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python -m py_compile scripts\tools\create_natural_props_blender.py` -> PASS.
- `blender --background --python scripts\tools\create_natural_props_blender.py` -> PASS; exported all 15 GLBs.
- `godot --headless --import --path .` -> PASS; imported GLBs and generated `.glb.import` files. The `artifacts/blender_sources/.gdignore` file avoids `.blend` importer noise.
- `godot --headless --script res://scripts/tools/BuildNaturalPropScenes.gd` -> PASS; generated wrappers, showcase scene, and 16 FourRoomMVP placements.
- `godot --headless --script res://scripts/tools/ValidateNaturalProps.gd` -> PASS.
- `godot --headless --script res://scripts/tools/ValidateCleanRebuildScene.gd` -> PASS.
- `godot --headless --script res://scripts/tools/ValidateGeneratedMeshRules.gd` -> PASS.
- `godot --script res://scripts/tools/CaptureNaturalPropScene.gd` -> PASS for showcase, before cutaway, after cutaway, Room_A, Room_B, and Room_C screenshots.
- Implementation forbidden-pattern scan for `if Room_*` -> PASS; no matches in touched scripts, FourRoomMVP, or prop assets.
- Final prop resource scan for `CSG`, `PlaneMesh`, and `BoxMesh` -> PASS; no matches under `assets/backrooms/props`. Existing `BoxMesh` hits in FourRoomMVP are ceiling light panels, not natural props.
- Removed transient `scripts/tools/__pycache__`.
- Final process check -> PASS; no `python codex_tools\texture_tool\texture_tool_server.py`, natural-prop script, or stalled Blender winget install process remains.

Validation result: PASS

Current blocking issue:
- None for the natural props batch.
- Godot tool runs still report the known non-blocking MCP runtime port 7777 already-in-use warning; all validation and capture commands above exited successfully.

Next step:
- Review the output screenshots and, if acceptable, keep this as the first reusable natural environment prop batch. Do not start a second prop batch until this placement pass is accepted.

## 2026-05-05 Texture tool layer X/Y scale and vertical offset pass

Current objective:
- Make the texture tool layer-composition controls clear for beginners by separating horizontal and vertical overlay scale, adding a vertical position offset, and keeping tool preview/save/runtime wall grime aligned.

Current progress:
- Split layer scale into `scale_x_min` / `scale_x_max` for left-right width and `scale_y_min` / `scale_y_max` for up-down height.
- Added `position_y_offset` limited to `-1.0..1.0`, with positive values moving overlays downward.
- Kept old `scale_min` / `scale_max` compatible: old layer configs are read as both X and Y defaults, while saved/new payloads also keep legacy scale fields as a broad fallback range.
- Updated the backend composition path used by both `/api/layers/preview` and `/api/layers/compose`, so preview and saved non-wall composites use the same new X/Y scale and Y-offset math.
- Updated beginner-facing UI labels to explicitly say horizontal width, vertical height, and positive-down vertical offset.
- Updated runtime wall grime config generation to summarize `size_x_scale`, `size_y_scale`, `top_offset`, and `bottom_offset` from wall layers.
- Updated `contact_ao_surface.gdshader` and `ContactShadowMaterial.gd` so Godot runtime random wall grime receives and applies the new runtime size/offset parameters.
- Rebuilt the runtime wall grime atlas/config; current config now includes `size_x_scale`, `size_y_scale`, `top_offset`, and `bottom_offset`.

Files changed:
- `codex_tools/texture_tool/texture_tool_server.py`
- `scripts/tools/build_runtime_wall_grime_atlas.py`
- `materials/shaders/contact_ao_surface.gdshader`
- `scripts/visual/ContactShadowMaterial.gd`
- `materials/textures/backrooms_wall_runtime_grime_atlas.png`
- `materials/textures/backrooms_wall_runtime_grime_config.json`
- `materials/textures/_texture_tool_backups/backrooms_wall_albedo_before_runtime_grime_20260505_102157.png`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py scripts\tools\build_runtime_wall_grime_atlas.py` -> PASS.
- `python codex_tools\texture_tool\texture_tool_server.py --self-test` -> PASS, `materials=5`.
- Inline Python compatibility test for legacy `scale_min` / `scale_max`, split X/Y scale, Y offset clamp, and runtime config summary -> PASS.
- Extracted embedded texture-tool JavaScript and ran `node --check` -> PASS.
- Godot parse: `logs/texture_layer_xy_parse_20260505_102123.log` -> PASS with the existing non-blocking MCP port 7777 warning.
- Touched-file forbidden-pattern scan -> PASS, no matches.
- `python scripts\tools\build_runtime_wall_grime_atlas.py` -> PASS, `candidates=16`.
- Temporary HTTP smoke test on port `8766` for root HTML and `/api/layers?id=wall` -> PASS; process stopped in `finally`.
- Removed transient Python `__pycache__` folders.
- Final process check -> PASS, no `python codex_tools\texture_tool\texture_tool_server.py` process remains.

Validation result: PASS

Current blocking issue:
- None for the texture-tool layer X/Y scale and vertical offset pass.
- Godot parse still reports the known MCP runtime port 7777 already-in-use warning when another editor/runtime owns that port; the command exited successfully.

Next step:
- Relaunch `start_texture_tool.bat`, open `图层合成`, and use `横向缩放最小/最大（左右宽度）`, `纵向缩放最小/最大（上下高度）`, and `上下偏移 -1~1（正数向下）` to place grime layers more clearly. Click generate/sync so runtime wall grime config and baked scene-local materials refresh.

## 2026-05-05 Grime layer probability, rotation, and edge feather pass

Current objective:
- Improve wall grime layer controls so stains can appear with a configurable probability, rotate randomly without rotating the wall-aligned mask, anchor to top/bottom edges correctly, and avoid hard rectangular horizontal seams.

Current progress:
- Added per-layer `probability` to the texture tool. Each random candidate draw now only appears if it passes this probability.
- Added per-layer random rotation controls: `random_rotation` and `rotation_degrees`.
- Random rotation is applied to the stain image before the wall mask is regenerated, so top/bottom/left/right mask feathering stays aligned to the wall instead of rotating with the stain.
- Changed top and bottom layer placement to edge-anchored placement: top layers start at the ceiling-side edge and fade downward; bottom layers start at the wall-foot edge and fade upward.
- Added horizontal edge feathering to `bottom_fade` and `top_fade` masks to remove hard left/right rectangular seams on wall stains.
- Added horizontal alpha feathering to generated runtime grime atlas tiles.
- Runtime wall grime now samples with the same material UV scale/offset used by the base wall texture, so saved UV Y offset affects actual baked/game grime height.
- Texture tool `compose` and `sync` now save current UV/material controls before composing or Godot rebaking, so UI UV changes are not lost.
- Runtime grime config now includes density from layer probability and random rotation settings for shader use.
- Rebaked MVP, proc-maze playable, and no-ceiling preview scenes.

Files changed:
- `codex_tools/texture_tool/texture_tool_server.py`
- `scripts/tools/build_runtime_wall_grime_atlas.py`
- `materials/shaders/contact_ao_surface.gdshader`
- `scripts/visual/ContactShadowMaterial.gd`
- `materials/textures/backrooms_wall_runtime_grime_atlas.png`
- `materials/textures/backrooms_wall_runtime_grime_config.json`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python scripts\tools\build_runtime_wall_grime_atlas.py` -> PASS, `candidates=18`.
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py scripts\tools\build_runtime_wall_grime_atlas.py` -> PASS.
- `python codex_tools\texture_tool\texture_tool_server.py --self-test` -> PASS.
- Extracted embedded texture-tool JS and ran `node --check` -> PASS.
- Godot parse: `logs/grime_probability_parse_20260505_092202.log` -> PASS.
- MVP bake: `logs/grime_probability_bake_mvp_20260505_092304.log` -> PASS.
- Proc-maze bake: `logs/grime_probability_bake_proc_20260505_092304.log` -> PASS.
- No-ceiling preview bake: `logs/grime_probability_bake_no_ceiling_20260505_092304.log` -> PASS.
- Generated mesh validation: `logs/grime_probability_validate_mesh_20260505_092304.log` -> PASS.
- Scene shadow validation: `logs/grime_probability_validate_shadows_20260505_092304.log` -> PASS.
- Proc-maze structure validation: `logs/grime_probability_validate_proc_20260505_092304.log` -> PASS.
- Proc-maze playable validation: `logs/grime_probability_validate_playable_20260505_092304.log` -> PASS.
- No-ceiling preview validation: `logs/grime_probability_validate_no_ceiling_20260505_092304.log` -> PASS.
- Baked scenes checked for `random_grime_rotation_enabled` / `random_grime_rotation_degrees` shader parameters -> present.
- Touched-file forbidden-pattern scan -> PASS, no matches.
- Closed running `python codex_tools\texture_tool\texture_tool_server.py` process.
- Removed transient Python `__pycache__` folders.

Validation result: PASS

Current blocking issue:
- Godot logs still print MCP port 7777 already-in-use warnings when another Godot/editor instance owns that port, but all validation commands exited successfully.

Next step:
- Relaunch the texture tool. Use `出现概率 0-1` to thin out a layer, enable `随机旋转脏迹图`, then set `随机旋转角度`; press generate/sync so current UV offset and layer settings are saved before scene rebake.

## 2026-05-05 Texture tool wall UV preview parity pass

Current objective:
- Fix the mismatch where the texture tool's wall preview could show top/bottom grime at a different vertical side than the generated Godot wall surfaces.

Current progress:
- Changed the WebGL model preview texture upload to stop using `UNPACK_FLIP_Y_WEBGL`, because generated wall UVs already map image bottom to the wall foot and image top to the ceiling side.
- Added `materials/textures/backrooms_wall_runtime_grime_config.json`, generated from the wall layer settings.
- Updated the runtime grime shader so top/bottom grime placement uses layer-derived weights and bands instead of hardcoded 50/50 top/bottom random placement.
- Updated `ContactShadowMaterial.gd` so baked wall material instances read the runtime grime config and store the same top/bottom weights in MVP/proc scenes.
- Rebuilt the runtime grime atlas/config and rebaked MVP, proc-maze playable, and no-ceiling preview scenes.

Files changed:
- `materials/shaders/contact_ao_surface.gdshader`
- `materials/textures/backrooms_wall_runtime_grime_atlas.png`
- `materials/textures/backrooms_wall_runtime_grime_config.json`
- `scripts/tools/build_runtime_wall_grime_atlas.py`
- `scripts/visual/ContactShadowMaterial.gd`
- `codex_tools/texture_tool/texture_tool_server.py`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python scripts\tools\build_runtime_wall_grime_atlas.py` -> PASS, `candidates=8`.
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py scripts\tools\build_runtime_wall_grime_atlas.py` -> PASS.
- `python codex_tools\texture_tool\texture_tool_server.py --self-test` -> PASS.
- Extracted embedded texture-tool JS and ran `node --check` -> PASS.
- Godot parse: `logs/wall_uv_preview_parse_20260505_021318.log` -> PASS.
- MVP bake: `logs/wall_uv_preview_bake_mvp_20260505_021353.log` -> PASS.
- Proc-maze bake: `logs/wall_uv_preview_bake_proc_20260505_021353.log` -> PASS.
- No-ceiling preview bake: `logs/wall_uv_preview_bake_no_ceiling_20260505_021353.log` -> PASS.
- Generated mesh validation: `logs/wall_uv_preview_validate_mesh_20260505_021437.log` -> PASS.
- Scene shadow validation: `logs/wall_uv_preview_validate_shadows_20260505_021437.log` -> PASS.
- Proc-maze structure validation: `logs/wall_uv_preview_validate_proc_20260505_021437.log` -> PASS.
- Proc-maze playable validation: `logs/wall_uv_preview_validate_playable_20260505_021437.log` -> PASS.
- No-ceiling preview validation: `logs/wall_uv_preview_validate_no_ceiling_20260505_021437.log` -> PASS.
- Checked baked scenes for `random_grime_top_weight` / `random_grime_bottom_weight` -> found current `top_weight=0.0`, `bottom_weight=2.0` wall bindings.
- Closed running `python codex_tools\texture_tool\texture_tool_server.py` process.
- Removed transient Python `__pycache__` folders.
- Touched-file forbidden-pattern scan -> PASS, no matches.
- Final recheck: no `texture_tool_server.py`, no Godot validation script process, no `__pycache__`.

Validation result: PASS

Current blocking issue:
- None for this UV preview/runtime grime parity pass.

Next step:
- Relaunch the texture tool and Godot run windows. With the current wall layer config, bottom/wall-foot grime should preview at the wall foot and bake into scenes as bottom-only runtime grime until a top layer is added.

## 2026-05-05 Runtime random wall grime pass

Current objective:
- Replace the fixed baked wall-grime PNG workflow with runtime randomized grime so wall, doorway wall, and corner/WallJoint pillar surfaces do not all share one identical dirty texture result.

Current progress:
- Added `materials/textures/backrooms_wall_runtime_grime_atlas.png`, generated from the current wall layer candidate pool in `codex_tools/texture_tool/texture_layers.json`.
- Added `scripts/tools/build_runtime_wall_grime_atlas.py` so the atlas can be rebuilt from the user's current wall overlay candidate images.
- Restored `materials/textures/backrooms_wall_albedo.png` from the wall base snapshot so the base wall texture is no longer the fixed random composite output.
- Updated `materials/shaders/contact_ao_surface.gdshader` so wall materials can sample the runtime grime atlas and place top/bottom grime spots procedurally by per-wall seed.
- Updated `ContactShadowMaterial.gd` with `make_wall_instance()` and per-instance random-grime shader uniforms.
- Updated MVP and proc-maze builders so solid walls, wall openings, internal walls, and WallJoint/corner pillars receive individual seeded wall material instances instead of a single shared wall-grime result.
- Updated wall vertical UVs to map full wall height, with the texture bottom aligned to the wall foot. This lets texture-tool bottom/top concepts appear on the expected wall bands.
- Updated the texture tool wall layer save path: for `wall`, generating layers now rebuilds the runtime grime atlas and keeps the base albedo as the material texture, instead of baking one fixed random albedo PNG.
- Rebaked MVP, proc-maze playable, and proc-maze no-ceiling preview scenes.
- Documented the accepted runtime-random wall grime rule in `docs/PROGRESS.md` and `docs/DECISIONS.md`.

Files changed:
- `materials/shaders/contact_ao_surface.gdshader`
- `materials/backrooms_wall.tres`
- `materials/textures/backrooms_wall_albedo.png`
- `materials/textures/backrooms_wall_runtime_grime_atlas.png`
- `scripts/tools/build_runtime_wall_grime_atlas.py`
- `scripts/visual/ContactShadowMaterial.gd`
- `scripts/scene/GeneratedMeshRules.gd`
- `scripts/scene/WallOpeningBody.gd`
- `scripts/core/SceneBuilder.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/tools/ValidateGeneratedMeshRules.gd`
- `codex_tools/texture_tool/texture_tool_server.py`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python scripts\tools\build_runtime_wall_grime_atlas.py` -> PASS, `candidates=19`.
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py scripts\tools\build_runtime_wall_grime_atlas.py` -> PASS.
- `python codex_tools\texture_tool\texture_tool_server.py --self-test` -> PASS.
- Extracted embedded texture-tool JS with Python UTF-8 handling and ran `node --check` -> PASS.
- Godot parse: `logs/runtime_grime_parse_20260505_013749.log` -> PASS.
- MVP bake: `logs/runtime_grime_bake_mvp_20260505_013749.log` -> PASS.
- Generated mesh validation: `logs/runtime_grime_v2_validate_mesh_20260505_013949.log` -> PASS.
- Scene shadow validation: `logs/runtime_grime_v3_validate_shadows_20260505_014117.log` -> PASS.
- Proc-maze bake: `logs/runtime_grime_v3_bake_proc_20260505_014117.log` -> PASS.
- Proc-maze structure validation: `logs/runtime_grime_v3_validate_proc_20260505_014117.log` -> PASS.
- Proc-maze playable validation: `logs/runtime_grime_v3_validate_playable_20260505_014117.log` -> PASS.
- No-ceiling preview bake: `logs/runtime_grime_v3_bake_no_ceiling_20260505_014117.log` -> PASS.
- No-ceiling preview validation: `logs/runtime_grime_v3_validate_no_ceiling_20260505_014117.log` -> PASS.
- Checked baked scenes for random-grime uniforms -> found runtime grime bindings in target scenes.
- Removed transient Python `__pycache__`.
- Checked for running `texture_tool_server.py` -> none.
- Rechecked forbidden old mask/fade patterns in touched runtime/material files -> PASS, no matches.
- Rechecked transient Python `__pycache__` folders -> PASS, none.
- Rechecked running Python texture-tool services -> PASS, none.
- Rechecked Godot validation script process list -> PASS, no leftover Godot validation process.

Validation result: PASS with one unrelated material-rule blocker

Current blocking issue:
- `ValidateMaterialLightingRules.gd` currently fails on the user's floor material settings (`normal_scale=0.800` and floor color rule), not on the runtime wall-grime implementation. This was not changed as part of the wall task.

Next step:
- Relaunch `run_mvp_room.bat` or `run_proc_maze_test.bat`; wall grime should vary per wall/doorway wall/WallJoint pillar instead of being a single baked repeated texture.

## 2026-05-05 Wall UV origin unified at wall foot

Current objective:
- Fix the visible mismatch where ordinary generated walls and doorway wall/opening pieces started the wall texture from different vertical UV origins, causing horizontal grime bands to line up differently around door frames.

Current progress:
- Changed ordinary generated wall boxes so vertical wall-face UV V starts from the wall-foot/global Y origin instead of the mesh-local center.
- Kept wall-opening bodies on the same wall-foot/global Y rule.
- Updated the texture tool WebGL preview's generated solid-wall UV rule so previewed wall grime/repeat placement matches the actual generated scene.
- Added generated-mesh validation to reject regular wall/opening meshes whose vertical UV V no longer matches wall-foot/global Y.
- Rebaked MVP, proc-maze playable, and proc-maze no-ceiling preview scenes from generator rules.

Files changed:
- `scripts/scene/GeneratedMeshRules.gd`
- `scripts/core/SceneBuilder.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/tools/ValidateGeneratedMeshRules.gd`
- `codex_tools/texture_tool/texture_tool_server.py`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py` -> PASS.
- `python codex_tools\texture_tool\texture_tool_server.py --self-test` -> PASS.
- Extracted embedded texture-tool JS with Python UTF-8 handling and ran `node --check` -> PASS.
- Godot parse: `logs/uv_origin_parse_20260505_005414.log` -> PASS.
- MVP bake: `logs/uv_origin_bake_mvp_20260505_005414.log` -> PASS.
- Generated mesh validation: `logs/uv_origin_validate_mesh_20260505_005414.log` -> PASS.
- Material validation: `logs/uv_origin_validate_material_20260505_005414.log` -> PASS.
- Scene shadow validation: `logs/uv_origin_validate_shadows_20260505_005414.log` -> PASS.
- Proc-maze bake: `logs/uv_origin_bake_proc_20260505_005414.log` -> PASS.
- Proc-maze structure validation: `logs/uv_origin_validate_proc_20260505_005414.log` -> PASS.
- Proc-maze playable validation: `logs/uv_origin_validate_playable_20260505_005414.log` -> PASS.
- No-ceiling preview bake: `logs/uv_origin_bake_no_ceiling_20260505_005414.log` -> PASS.
- No-ceiling preview validation: `logs/uv_origin_validate_no_ceiling_20260505_005414.log` -> PASS.
- Broad forbidden-pattern scan -> existing documentation/log/approved-alpha hits only; no new implementation issue identified.
- Touched-file forbidden-pattern scan -> PASS.
- Removed transient Python `__pycache__`.
- Closed three running `python codex_tools\texture_tool\texture_tool_server.py` processes so relaunching the texture tool loads the updated code.

Validation result: PASS

Current blocking issue:
- Existing open browser/game windows may still show old resources until refreshed or relaunched.

Next step:
- Reopen `run_mvp_room.bat` and/or refresh `start_texture_tool.bat`; the wall grime band should now start from the same wall-foot origin on ordinary walls and doorway wall pieces.

## 2026-05-05 Texture tool preview uses actual wall UV origin

Current objective:
- Make the texture tool's WebGL generator preview show the same horizontal grime/repeat behavior as the actual in-game generated wall meshes.

Current progress:
- Found the remaining preview mismatch: normal solid walls in game use `GeneratedMeshRules.build_box_mesh`, which maps wall UVs from the mesh-local center. The tool preview was still mapping wall UVs from each preview box's bottom/zero corner, so the mid-wall repeat seam and horizontal grime line could be missing in the preview.
- Added `addGeneratedBox()` in `codex_tools/texture_tool/texture_tool_server.py` to mimic `GeneratedMeshRules` box UVs for solid generated walls.
- Added `addWallOpeningBox()` to keep wall-opening preview UVs closer to `WallOpeningBody` instead of treating openings exactly like solid box walls.
- Closed the running old `python codex_tools\texture_tool\texture_tool_server.py` process so the next `start_texture_tool.bat` launch loads the updated preview code.

Files changed:
- `CURRENT_STATE.md`
- `codex_tools/texture_tool/texture_tool_server.py`

Commands run:
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py` -> PASS.
- `python codex_tools\texture_tool\texture_tool_server.py --self-test` -> PASS.
- Extracted embedded texture-tool JS with Python UTF-8 handling and ran `node --check` -> PASS.
- Removed transient Python `__pycache__`.
- Closed the old texture-tool Python process.

Validation result: PASS

Current blocking issue:
- Existing browser tab must be refreshed after relaunching `start_texture_tool.bat`.

Next step:
- Relaunch `start_texture_tool.bat`; the 3D preview should now show the same solid-wall horizontal repeat/grime behavior as the game.

## 2026-05-05 Texture tool sync must rebake generated scenes

Current objective:
- Fix the remaining mismatch where texture-tool material settings looked saved but the actual Godot scene still rendered old values.

Current progress:
- Confirmed `materials/backrooms_wall.tres` had `uv1_scale = Vector3(1, 1, 1)`.
- Confirmed the baked MVP scene still had wall contact-shadow `shader_parameter/uv_scale = Vector2(0.1, 0.1)`, so the actual scene could render stale material wrapper data.
- Updated `codex_tools/texture_tool/texture_tool_server.py` so `/api/sync` now runs:
  - Godot resource import,
  - `scripts/tools/BakeFourRoomScene.gd`,
  - `scripts/tools/BakeTestProcMazeMap.gd`,
  - `scripts/tools/BakeTestProcMazeNoCeilingPreview.gd`.
- Ran the new sync path successfully. MVP and proc baked wall shader materials now show `shader_parameter/uv_scale = Vector2(1, 1)`.

Files changed:
- `CURRENT_STATE.md`
- `codex_tools/texture_tool/texture_tool_server.py`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`

Commands run:
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py` -> PASS.
- `python codex_tools\texture_tool\texture_tool_server.py --self-test` -> PASS.
- Extracted embedded texture-tool JS with Python UTF-8 handling and ran `node --check` -> PASS.
- `run_sync()` -> PASS:
  - `logs/texture_tool_sync_20260505_002025_import.log`
  - `logs/texture_tool_sync_20260505_002025_bake_mvp.log`
  - `logs/texture_tool_sync_20260505_002026_bake_proc.log`
  - `logs/texture_tool_sync_20260505_002027_bake_proc_no_ceiling.log`
- Checked baked scenes for wall `uv_scale` values -> PASS.
- Checked for Python texture-tool process -> none.

Validation result: PASS

Current blocking issue:
- Already-open Godot DEBUG/game windows may still show stale resources until closed and relaunched.

Next step:
- Close the visible DEBUG run window and launch `run_mvp_room.bat` again to compare against the texture-tool preview.

## 2026-05-04 Texture tool game UV parity fix

Current objective:
- Explain and fix why the texture tool's generator preview did not match the saved/imported Godot game result.

Current progress:
- Found the main mismatch: Godot generated wall meshes use `GeneratedMeshRules.build_box_mesh(..., WALL_UV_WORLD_SIZE = 6.0)`, so wall UVs are based on `world_size / 6.0` before the material `uv1_scale` is applied.
- The WebGL preview was using raw meter-sized UVs and then applying the material scale, so `uv1_scale = 0.1` looked much denser in the tool than in-game.
- Updated `codex_tools/texture_tool/texture_tool_server.py` so WebGL wall/opening preview divides UVs by the same game wall world size, floor preview divides by `12.0`, ceiling preview divides by `6.0`, and door-frame boxes use normalized frame dimensions closer to `DoorFrameVisual.gd`.
- Confirmed the second source of apparent mismatch: an already running Godot game window will not hot-reload every material/texture change; close and relaunch the run window after saving/importing.

Files changed:
- `CURRENT_STATE.md`
- `codex_tools/texture_tool/texture_tool_server.py`

Commands run:
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py` -> PASS.
- `python codex_tools\texture_tool\texture_tool_server.py --self-test` -> PASS.
- Extracted embedded texture-tool JS with Python UTF-8 handling and ran `node --check` -> PASS.

Validation result: PASS

Current blocking issue:
- No automated blocker.

Next step:
- Relaunch `start_texture_tool.bat` and the Godot run window; the tool preview should now show low `uv1_scale` values as stretched in the same direction as the game.

## 2026-05-04 Contact shadow and texture-tool live preview pass

Current objective:
- Make wall/floor/ceiling/door-frame junctions feel less visually floating by adding Mobile-compatible contact darkening.
- Add runtime controls for the contact darkening to the existing ESC lighting tuning panel.
- Finish the texture tool's live UV/layer/model preview work after the interrupted session.

Current progress:
- Added `scripts/visual/ContactShadowMaterial.gd`.
- `SceneBuilder.gd` now wraps MVP wall, floor, ceiling, and door-frame surfaces in contact-shadow ShaderMaterials derived from the existing shared materials.
- `ProcMazeSceneBuilder.gd` now wraps generated proc-maze walls, wall openings, internal walls, and door frames in the same contact-shadow material path; proc floors/ceilings keep their original materials to avoid map-wide false grid bands.
- `LightingTuningPanel.gd` now exposes runtime controls for `闭塞阴影`, `闭塞强度`, and `最大压暗` alongside the existing light and ambient controls.
- `SceneValidator.gd`, `ValidateMaterialLightingRules.gd`, and `ValidateGeneratedMeshRules.gd` now accept validated contact-shadow wrappers as preserving the underlying material rule.
- The attempted SSAO route was rejected because Godot 4.6.2 warns SSAO is unavailable under the Mobile renderer; the final implementation is material-level contact darkening instead.
- `docs/DECISIONS.md` now records the Mobile-safe contact-shadow decision, and `docs/ACCEPTANCE_CHECKLIST.md` includes contact-shadow acceptance checks.
- `codex_tools/texture_tool/texture_tool_server.py` now:
  - updates 2D texture previews with current UV scale/offset,
  - shows unsaved layer-composition results through `/api/layers/preview`,
  - feeds the live composed albedo into the WebGL model preview,
  - keeps the 3D model preview sticky beside the material controls,
  - adds closer zoom and reset buttons.

Files changed:
- `CURRENT_STATE.md`
- `codex_tools/texture_tool/texture_tool_server.py`
- `materials/shaders/contact_ao_surface.gdshader`
- `scripts/visual/ContactShadowMaterial.gd`
- `scripts/core/SceneBuilder.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/lighting/LightingTuningPanel.gd`
- `scripts/proc_maze/SceneValidator.gd`
- `scripts/tools/ValidateMaterialLightingRules.gd`
- `scripts/tools/ValidateGeneratedMeshRules.gd`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `docs/DECISIONS.md`
- `docs/ACCEPTANCE_CHECKLIST.md`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py` -> PASS.
- `python codex_tools\texture_tool\texture_tool_server.py --self-test` -> PASS.
- Extracted embedded texture-tool JS and ran `node --check` -> PASS.
- Temporary texture-tool HTTP check on port `8778` -> PASS for `/`, `/api/layers?id=wall`, and `/api/layers/preview`; the server was stopped afterward.
- Godot parse: `logs/contact_shadow_parse_v2_20260504_233642.log` -> PASS.
- MVP bake: `logs/contact_shadow_bake_mvp_v2_20260504_233706.log` -> PASS.
- Proc-maze bake: `logs/contact_shadow_bake_proc_v2_20260504_233735.log` -> PASS.
- Proc-maze no-ceiling bake: `logs/contact_shadow_bake_proc_no_ceiling_v2_20260504_233802.log` -> PASS.
- Material validation: `logs/contact_shadow_validate_material_20260504_233833.log` -> PASS.
- Generated mesh validation: `logs/contact_shadow_validate_mesh_20260504_233901.log` -> PASS.
- Scene shadow validation: `logs/contact_shadow_validate_shadows_20260504_233926.log` -> PASS.
- Proc-maze structure validation: `logs/contact_shadow_validate_proc_20260504_233954.log` -> PASS.
- Proc-maze playable validation: `logs/contact_shadow_validate_playable_20260504_234017.log` -> PASS.
- Proc-maze no-ceiling validation: `logs/contact_shadow_validate_no_ceiling_20260504_234044.log` -> PASS.
- Removed transient Python `__pycache__` folders.
- Closed the remaining `python codex_tools\texture_tool\texture_tool_server.py` background process so the next `start_texture_tool.bat` launch loads the new UI.

Validation result: PASS

Current blocking issue:
- No automated blocker.
- The contact shadow strength still needs manual visual tuning in-game; use `ESC` in `run_proc_maze_test.bat` and adjust the new closure-shadow controls.

Next step:
- Manually inspect wall-floor and door-frame junctions in `run_mvp_room.bat` and `run_proc_maze_test.bat`; tune `闭塞强度` and `最大压暗` if the edge darkening is too subtle or too dirty.

## 2026-05-04 Texture tool game-scale model preview pass

Current objective:
- Fix the texture tool's model preview so its room corner, doorway, and door frame match the actual game geometry more closely.
- Remove the misleading simplified/chunky door-frame preview that did not match MVP/proc-maze door-frame dimensions.

Current progress:
- Updated `codex_tools/texture_tool/texture_tool_server.py` WebGL preview:
  - Replaced the old illustrative door-frame boxes with game-scale constants.
  - Preview now uses `6.0m` room width/depth, `2.55m` wall height, `0.20m` wall thickness, `1.15m` wall opening width, `2.16m` opening height, `0.95m` door-frame inner width, `0.10m` trim width, `0.16m` frame depth, and `2.18m` frame outer height.
  - Rebuilt the preview wall as an actual doorway opening made from side wall segments and a header segment instead of a full wall plus a dark fake rectangle.
  - Rebuilt the preview frame as a U-shaped three-piece frame with the same canonical dimensions used by `DoorFrameVisual.gd` and `ProcMazeSceneBuilder.gd`.
  - Added a small through-door floor reveal so the opening reads as a real passage, not a black panel.
  - Adjusted the preview camera target/distance for the larger real-scale 6m sample.
  - Updated the preview hint to state the game dimensions being used.

Files changed:
- `CURRENT_STATE.md`
- `codex_tools/texture_tool/texture_tool_server.py`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py` -> PASS.
- `python codex_tools\texture_tool\texture_tool_server.py --self-test` -> PASS.
- Extracted embedded `<script>` and ran `node --check` -> PASS.
- Temporary HTTP check on port `8777` -> PASS for `/`; the server process was stopped afterward.
- `node -e "require('playwright')"` -> FAIL, Playwright is not installed, so no browser screenshot was captured in this pass.
- Removed transient `codex_tools\texture_tool\__pycache__`.
- Process cleanup check found only the pre-existing default `python codex_tools\texture_tool\texture_tool_server.py`; it was left running because it was not started by this pass.

Validation result: PASS

Validation evidence:
- `TEXTURE_TOOL_SELF_TEST PASS materials=5`
- `TEXTURE_TOOL_GAME_PREVIEW_HTTP_CHECK PASS port=8777`
- Embedded script `node --check` exited 0.

Current blocking issue:
- No automated blocker.
- The user should refresh/restart `start_texture_tool.bat` to see the updated WebGL preview, because an older texture-tool process is already running.

Next step:
- If the preview still feels different from in-game, generate the preview mesh from a shared exported geometry description instead of duplicating the constants in JavaScript.

## 2026-05-04 Texture tool layer delete, blend modes, and mask feather pass

Current objective:
- Fix the texture tool issue where added overlay layers could not be deleted.
- Add more per-layer blend modes.
- Add per-layer masks with adjustable edge feathering so grime/stain overlays can fade naturally.

Current progress:
- Updated `codex_tools/texture_tool/texture_tool_server.py`:
  - Fixed layer deletion by saving the already-filtered layer list instead of re-collecting from the old DOM before redraw.
  - Made candidate texture removal use the current DOM state plus the edited pool list, so removed assets persist.
  - Added backend layer fields: `mask` and `mask_feather`.
  - Added mask modes: `none`, `soft_rect`, `bottom_fade`, `top_fade`, and `radial`.
  - Added mask feather range `0.0..0.5`; the compositor now applies the mask to the overlay alpha before blending.
  - Expanded blend modes beyond normal/multiply/screen/darken with `lighten`, `overlay`, `soft_light`, `hard_light`, and `difference`.
  - Added matching UI controls for blend mode, mask mode, and mask feather on every layer.

Files changed:
- `CURRENT_STATE.md`
- `codex_tools/texture_tool/texture_tool_server.py`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py` -> PASS.
- `python codex_tools\texture_tool\texture_tool_server.py --self-test` -> PASS.
- Extracted embedded `<script>` and ran `node --check` -> PASS.
- Temporary HTTP check on port `8776` -> PASS for `/` and `/api/layers?id=wall`; the server process was stopped afterward.
- Direct mask unit check for `soft_rect` and `bottom_fade` alpha falloff -> PASS.
- Removed transient `codex_tools\texture_tool\__pycache__`.
- The temporary port `8776` texture-tool check server was stopped afterward.
- A separate default `python codex_tools\texture_tool\texture_tool_server.py` process was present after validation and was left running because it was not started by this pass.

Validation result: PASS

Validation evidence:
- `TEXTURE_TOOL_SELF_TEST PASS materials=5`
- `TEXTURE_TOOL_HTTP_CHECK PASS port=8776 layers=5 mask=bottom_fade feather=0.16`
- `TEXTURE_LAYER_MASK_UNIT PASS`

Current blocking issue:
- No automated blocker.
- User should reopen `start_texture_tool.bat` and verify deleting a manually added layer from the browser UI.

Next step:
- If the mask workflow feels right, optionally add a small per-layer thumbnail preview for mask/feather before writing to the real material texture.

## 2026-05-04 Runtime lighting tuning panel pass

Current objective:
- Add an in-scene lighting controller for the playable proc-maze test scene.
- Let the user press `ESC` to show light controls, then click outside the panel to return to captured gameplay.
- Make the current proc-maze light feel less yellow without modifying `scenes/mvp/FourRoomMVP.tscn`.

Current progress:
- Added `scripts/lighting/LightingTuningPanel.gd`:
  - Runtime `CanvasLayer` panel hidden by default.
  - `ESC` toggles the panel and releases mouse capture.
  - Clicking outside the panel hides it and captures the mouse again.
  - Controls current scene light color, light energy multiplier, range multiplier, attenuation multiplier, lamp-panel emission multiplier, ambient color, ambient energy, and flicker enable.
  - Includes quick presets for warmer white light and a darker/stronger-falloff setup.
  - Applies a less-yellow warm-white default to proc-maze runtime lights and lamp panels.
- Updated `scripts/proc_maze/TestProcMazeMap.gd` so playable runtime systems now include `Systems/LightingTuningPanel`.
- Updated `scripts/lighting/LightingController.gd`:
  - Added `refresh_light_cache()` so runtime tuning becomes the new flicker baseline.
  - Reuses already-unique panel materials instead of duplicating material overrides on every refresh.
- Updated `scripts/tools/ValidateProcMazePlayable.gd` to verify the panel exists, exposes open/close methods, builds enough controls, and can open/close.
- Rebaked `scenes/tests/Test_ProcMazeMap.tscn`.
- Rebaked `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`; validation confirms the preview still has no player and no ceilings.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/ACCEPTANCE_CHECKLIST.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- `scripts/lighting/LightingTuningPanel.gd`
- `scripts/lighting/LightingController.gd`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/tools/ValidateProcMazePlayable.gd`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Read startup docs in requested order.
- Godot parse: `logs/lighting_tuning_panel_parse_20260504_212054.log` -> PASS.
- Proc-maze bake: `logs/lighting_tuning_panel_bake_20260504_212119.log` -> PASS.
- Proc-maze structure validation: `logs/lighting_tuning_panel_validate_structure_20260504_212212.log` -> PASS.
- Proc-maze playable validation: `logs/lighting_tuning_panel_validate_playable_20260504_212212.log` -> PASS.
- Shared MVP light-flicker regression: `logs/lighting_tuning_panel_validate_flicker_20260504_212250.log` -> PASS.
- No-ceiling bake: `logs/lighting_tuning_panel_bake_no_ceiling_20260504_212319.log` -> PASS.
- No-ceiling validation: `logs/lighting_tuning_panel_validate_no_ceiling_20260504_212319.log` -> PASS.
- Shared scene-shadow regression: `logs/lighting_tuning_panel_validate_shadows_20260504_212540.log` -> PASS.
- Process cleanup check found no persistent Godot console validation process or `texture_tool_server.py` left running.

Validation result: PASS

Validation evidence:
- `TEST_PROC_MAZE_VALIDATION PASS seed=2026050401 rooms=36 ... door_to_wall=false door_reveal_blocker=false ... lights=28 light_sources=38`
- `PROC_MAZE_PLAYABLE_VALIDATION PASS start=(3.75, 0.000104, 3.75) end=(7.11762, 0.000104, 3.75) moved_x=3.368 camera_current=true`
- `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 ...`
- `PROC_MAZE_NO_CEILING_PREVIEW_VALIDATION PASS rooms=36 floors=36 walls=339 openings=39 frames=39 lights=38 ceilings=0 camera_size=106.20 player=false`
- `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`

Current blocking issue:
- No automated blocker.
- Needs visual review in `run_proc_maze_test.bat`: press `ESC`, adjust light controls, then click outside the panel to return to gameplay.

Next step:
- If the user likes the control range, keep these runtime defaults. If not, tune default warm-white color, ambient range, and attenuation slider limits.

## 2026-05-04 Texture tool layered random overlay pass

Current objective:
- Add layer-based texture composition to the beginner texture/UV tool.
- Support a bottom/base texture plus one or more overlay layers.
- Let an overlay layer randomly choose from a selected texture pool, so grime/stains can vary instead of using one fixed overlay image.

Current progress:
- Updated `codex_tools/texture_tool/texture_tool_server.py`:
  - Added Pillow-backed layer compositing for material albedo textures.
  - Added per-material layer state stored in `codex_tools/texture_tool/texture_layers.json` when the user saves layer settings.
  - Added layer asset storage under `materials/textures/texture_tool_layers/`.
  - Added a base texture snapshot rule so repeated composition does not keep accumulating grime on top of an already composited output unless the user intentionally resets the base.
  - Added default `bottom_grime` layer with random candidate-pool behavior.
  - Added layer controls in the web UI: add/remove layer, enable layer, placement, blend mode, opacity, random count, random scale range, bottom band height, seed, and multi-file upload into a random candidate pool.
  - Added `生成并保存颜色贴图`, which composites the current layers into the material's albedo texture, backs up the old output texture, and keeps Godot reading the same material slot.
- Added HTTP APIs:
  - `GET /api/layers?id=wall`
  - `POST /api/layers/save`
  - `POST /api/layers/upload`
  - `POST /api/layers/compose`
  - `POST /api/layers/reset-base`

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/ACCEPTANCE_CHECKLIST.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- mirror package docs under `四房间MVP_Agent抗遗忘执行包/docs/`
- `codex_tools/texture_tool/texture_tool_server.py`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- `python codex_tools\texture_tool\texture_tool_server.py --self-test` -> PASS.
- Temporary HTTP check on port `8776` -> PASS for `/`, `/api/materials`, and `/api/layers?id=wall`; the server process was stopped afterward.
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py` -> PASS.
- Extracted embedded `<script>` from the tool HTML and ran `node --check` -> PASS.
- Process cleanup check found no running `texture_tool_server.py` or tool-script Godot processes.
- Removed transient `codex_tools\texture_tool\__pycache__` generated by `py_compile`.

Validation result: PASS

Validation evidence:
- `TEXTURE_TOOL_SELF_TEST PASS materials=5`
- `TEXTURE_TOOL_HTTP_CHECK PASS status=200 materials=5 layers=1`

Current blocking issue:
- No automated blocker.
- User still needs to visually test the new layer UI by running `start_texture_tool.bat`, adding several grime/stain images to a layer, and pressing `生成并保存颜色贴图`.

Next step:
- If the user likes the workflow, add optional thumbnail previews for each random-pool asset and a "generate variant without saving" preview button.

## 2026-05-04 Proc-maze doorway reveal clearance pass

Current objective:
- Prevent a generated wall or internal partition from appearing immediately behind a door frame.
- Keep the fix in shared proc-maze generation/validation rules instead of hand-editing baked scene nodes.
- Preserve the accepted wall bodies, door frames, materials, AO/contact-lighting, light placement, distributed long lights, player setup, and MVP baseline scene.

Current progress:
- Updated `scripts/proc_maze/ProcMazeSceneBuilder.gd`:
  - Added per-door reveal/entry buffer rectangles on both sides of every generated opening.
  - Internal full-height partition walls are now trimmed/split when they would intrude into a doorway reveal.
  - The reveal buffer is `1.10m` deep and `2.15m` wide, wide enough to cover the door frame shoulder while staying inside normal corridor side walls.
  - Large-room and hub internal-wall generation now goes through the same spec list used by placement rules, then applies doorway trimming before creating wall bodies.
- Updated `scripts/proc_maze/SceneValidator.gd`:
  - Door validation now rejects solid boundary walls or internal partition walls inside the doorway reveal area.
  - Added `has_door_reveal_blocker` metric so logs can distinguish abrupt door-frame blockers from ordinary door/opening mismatch.
- Updated `scripts/proc_maze/TestProcMazeMap.gd` and `scripts/tools/ValidateTestProcMazeMap.gd` so validation output reports `door_reveal_blocker=false`.
- Bumped proc-maze fixed generator version to `proc_maze_fixed_layout_v0.10_door_reveal_clearance`.
- Rebaked `scenes/tests/Test_ProcMazeMap.tscn` and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`. `scenes/mvp/FourRoomMVP.tscn` was not modified.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/FORBIDDEN_PATTERNS.md`
- `docs/ACCEPTANCE_CHECKLIST.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- mirror package docs under `四房间MVP_Agent抗遗忘执行包/docs/`
- `scripts/proc_maze/MapGraphGenerator.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/proc_maze/SceneValidator.gd`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/tools/ValidateTestProcMazeMap.gd`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse: `logs/proc_maze_door_reveal_parse_v3_20260504_202620.log`
- Proc-maze bake: `logs/proc_maze_door_reveal_bake_v3_20260504_202620.log`
- Proc-maze no-ceiling bake: `logs/proc_maze_door_reveal_bake_no_ceiling_v3_20260504_202620.log`
- Proc-maze structure validation: `logs/proc_maze_door_reveal_validate_v3_20260504_202640.log`
- Proc-maze playable validation: `logs/proc_maze_door_reveal_playable_v3_20260504_202640.log`
- Proc-maze no-ceiling validation: `logs/proc_maze_door_reveal_validate_no_ceiling_v3_20260504_202640.log`
- Final parse after dead-code cleanup: `logs/proc_maze_door_reveal_parse_final_20260504_202720.log`
- Final structure validation after dead-code cleanup: `logs/proc_maze_door_reveal_validate_final_20260504_202720.log`
- Final playable validation after dead-code cleanup: `logs/proc_maze_door_reveal_playable_final_20260504_202720.log`

Validation result: PASS

Validation evidence:
- `TEST_PROC_MAZE_VALIDATION PASS seed=2026050401 rooms=36 ... door_to_wall=false door_reveal_blocker=false ... lights=28 light_sources=38`
- `PROC_MAZE_PLAYABLE_VALIDATION PASS start=(3.75, 0.043333, 3.75) end=(7.117625, 0.000838, 3.75) moved_x=3.368 camera_current=true`
- `PROC_MAZE_NO_CEILING_PREVIEW_VALIDATION PASS rooms=36 floors=36 walls=339 openings=39 frames=39 lights=38 ceilings=0 camera_size=106.20 player=false`
- Some logs contain the known non-blocking MCP Runtime port `7777` conflict because another Godot/MCP process already owns the port; all listed validation commands exited 0.

Current blocking issue:
- No automated blocker.
- User should visually inspect the doorway shown in the screenshot after reopening `run_proc_maze_test.bat`.

Next step:
- If a doorway still visually feels like a wall starts too close to the frame, identify the edge from player position/screenshot and widen the reveal shoulder or adjust that module's generated opening relation through map/module rules, not by hand-moving baked walls.

## 2026-05-04 Proc-maze distributed long-light sources pass

Current objective:
- Fix long ceiling-light panels that looked like they emitted from one bright point in the center.
- Preserve the visible long lamp panel shape while distributing real light along the panel length.
- Keep wall/panel overlap rules, unlit narrow corridors, materials, AO/contact-lighting, macro-loop topology, player, and MVP baseline intact.

Current progress:
- Updated `scripts/proc_maze/ProcMazeSceneBuilder.gd`:
  - Long ceiling-light panels now create multiple weaker `OmniLight3D` sources along the panel's long axis.
  - Current distribution uses 2 to 4 sources, capped for Mobile performance. The current fixed layout creates 28 visible lamp fixtures and 38 real light sources.
  - Distributed sources use lower per-source energy, shorter range, and stronger attenuation than the old single center light, so the bright spot is spread along the rectangular panel instead of concentrated in the middle.
  - Long panels save metadata such as `light_source_count`, `light_distribution`, `fixture_light_count`, and `distributed_source`.
- Updated `scripts/lighting/LightingController.gd`:
  - Runtime flicker now groups multiple `OmniLight3D` sources by fixture owner.
  - A distributed long lamp flickers/dims as one fixture instead of one source changing while the rest remain unchanged.
- Updated `scripts/proc_maze/SceneValidator.gd`:
  - `active_light_count` means visible light fixtures/panels.
  - `active_light_source_count` means real `OmniLight3D` source count.
  - A panel may own one or more real sources, and every source must sit under its owner panel.
- Updated no-ceiling and structure validators to report/validate both fixture count and source count.
- Bumped proc-maze fixed generator version to `proc_maze_fixed_layout_v0.9_distributed_long_lights`.
- Rebaked `scenes/tests/Test_ProcMazeMap.tscn` and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`. `scenes/mvp/FourRoomMVP.tscn` was not modified.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/FORBIDDEN_PATTERNS.md`
- `docs/ACCEPTANCE_CHECKLIST.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- mirror package docs under `四房间MVP_Agent抗遗忘执行包/docs/`
- `scripts/proc_maze/MapGraphGenerator.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/proc_maze/SceneValidator.gd`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/lighting/LightingController.gd`
- `scripts/tools/BakeTestProcMazeNoCeilingPreview.gd`
- `scripts/tools/ValidateProcMazeNoCeilingPreview.gd`
- `scripts/tools/ValidateTestProcMazeMap.gd`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse: `logs/proc_maze_distributed_lights_parse_20260504_201130.log`
- Proc-maze bake: `logs/proc_maze_distributed_lights_bake_v2_20260504_201140.log`
- Proc-maze no-ceiling bake: `logs/proc_maze_distributed_lights_bake_no_ceiling_v2_20260504_201140.log`
- Proc-maze structure validation: `logs/proc_maze_distributed_lights_validate_20260504_201200.log`
- Proc-maze playable validation: `logs/proc_maze_distributed_lights_playable_20260504_201200.log`
- Proc-maze no-ceiling validation: `logs/proc_maze_distributed_lights_validate_no_ceiling_20260504_201200.log`
- Shared MVP light-flicker regression: `logs/proc_maze_distributed_lights_validate_flicker_20260504_201250.log`
- Shared MVP scene-shadow regression: `logs/proc_maze_distributed_lights_validate_shadows_20260504_201250.log`

Validation result: PASS

Validation evidence:
- `TEST_PROC_MAZE_VALIDATION PASS seed=2026050401 rooms=36 ... lights=28 light_sources=38`
- `PROC_MAZE_PLAYABLE_VALIDATION PASS start=(3.75, 0.043333, 3.75) end=(7.117625, 0.000838, 3.75) moved_x=3.368 camera_current=true`
- `PROC_MAZE_NO_CEILING_PREVIEW_VALIDATION PASS rooms=36 floors=36 walls=339 openings=39 frames=39 lights=38 ceilings=0 camera_size=106.20 player=false`
- `LIGHT_FLICKER_VALIDATION PASS lights=4 ...`
- `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`
- Saved scene scan confirms long panels with `metadata/light_source_count = 3` and distributed sources with `omni_range = 4.7`, per-source `light_energy = 0.47986665`, and `metadata/distributed_source = true`.
- Some logs contain the known non-blocking MCP Runtime port `7777` conflict because another Godot/MCP process already owns the port; all listed validation commands exited 0.

Current blocking issue:
- No automated blocker.
- User should visually inspect the same long-light angle to decide if the spread is soft enough or if the source count/range needs another small tune.

Next step:
- Open `run_proc_maze_test.bat` and inspect long lamps from below. If a visible center hotspot remains, reduce `CEILING_LIGHT_DISTRIBUTED_RANGE` or increase source count/spacing rather than going back to one central light.

## 2026-05-04 Proc-maze ceiling light placement pass

Current objective:
- Prevent generated ceiling light panels from overlapping or clipping into walls/internal partitions.
- Allow narrow or awkward corridor spaces to remain unlit instead of forcing one lamp per space.
- Preserve the current wall, door-frame, material, AO/contact-lighting, shadow, player, macro-loop topology, and MVP baseline scene.

Current progress:
- Updated `scripts/proc_maze/ProcMazeSceneBuilder.gd` so ceiling lights are optional per generated module.
- Added safe ceiling-light placement based on occupied cells and internal partition specs. A light panel must fit inside the owner footprint with clearance and must not overlap internal full-height partition walls.
- Narrow/complex corridor spaces now intentionally skip ceiling lights:
  - `width_tier == narrow_corridor`
  - `space_kind` in `narrow_corridor`, `l_turn`, `junction`, `offset_corridor`
  - non-long corridor modules
- Light panels and `OmniLight3D` nodes now store `owner_module_id`, `space_kind`, `width_tier`, and `lighting_policy` metadata for validation/debugging.
- Updated `scripts/proc_maze/SceneValidator.gd` to reject:
  - lights/panels in required-unlit narrow or complex corridor spaces,
  - ceiling panels outside the owner occupied-cell footprint,
  - ceiling panels overlapping boundary walls or internal partitions in XZ,
  - mismatched visual panel / real light pairs.
- Fixed offline validation to use accumulated local `position` instead of `global_position`, because bake validation runs before every generated node is inside the active scene tree.
- Updated `scripts/tools/ValidateProcMazeNoCeilingPreview.gd` so no-ceiling preview expects `active_light_count`, not one light per room, and fails if every space is still lit.
- Bumped proc-maze fixed generator version to `proc_maze_fixed_layout_v0.8_light_spacing_unlit_narrow`.
- Rebaked `scenes/tests/Test_ProcMazeMap.tscn` and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`. `scenes/mvp/FourRoomMVP.tscn` was not modified.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/FORBIDDEN_PATTERNS.md`
- `docs/ACCEPTANCE_CHECKLIST.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- mirror package docs under `四房间MVP_Agent抗遗忘执行包/docs/`
- `scripts/proc_maze/MapGraphGenerator.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/proc_maze/SceneValidator.gd`
- `scripts/tools/ValidateProcMazeNoCeilingPreview.gd`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse: `logs/proc_maze_light_spacing_parse_20260504_194000.log`
- Proc-maze bake: `logs/proc_maze_light_spacing_bake_v08_20260504_194200.log`
- Proc-maze no-ceiling bake: `logs/proc_maze_light_spacing_bake_no_ceiling_v08_20260504_194200.log`
- Proc-maze structure validation: `logs/proc_maze_light_spacing_validate_v08_20260504_194220.log`
- Proc-maze playable validation: `logs/proc_maze_light_spacing_playable_v08_20260504_194220.log`
- Proc-maze no-ceiling validation: `logs/proc_maze_light_spacing_validate_no_ceiling_v08_20260504_194220.log`
- Process cleanup check: found two old `texture_tool_server.py` processes and stopped them; did not stop existing Godot editor/runtime windows.

Validation result: PASS

Validation evidence:
- `TEST_PROC_MAZE_VALIDATION PASS seed=2026050401 rooms=36 main=18 branches=8 loops=4 macro_loops=1 macro_cycle=14 largest_cycle=14 macro_a=8 macro_b=8 small_loops=2 dead=4 long=5 l_turn=2 l_room=4 internal_large=4 hubs=3 plain_rect=5 large=7 special=2 narrow_corridor=8 normal_corridor=5 normal_room=14 large_width=6 hub_width=3 overlap=false door_to_wall=false fps=1.0 draw_calls=0 lights=28`
- `PROC_MAZE_PLAYABLE_VALIDATION PASS start=(3.75, 0.043333, 3.75) end=(7.117625, 0.000838, 3.75) moved_x=3.368 camera_current=true`
- `PROC_MAZE_NO_CEILING_PREVIEW_VALIDATION PASS rooms=36 floors=36 walls=339 openings=39 frames=39 lights=28 ceilings=0 camera_size=106.20 player=false`
- Generated metric: `active_light_count=28` with `total_rooms=36`, so 8 narrow/complex spaces are intentionally unlit.
- Some logs contain the known non-blocking MCP Runtime port `7777` conflict because another Godot/MCP process already owns the port; all listed validation commands exited 0.
- Final texture-tool process check returned no running `texture_tool_server.py` process.

Current blocking issue:
- No automated blocker.
- Visual acceptance still needs the user to inspect whether wall/lamp intersections are gone from player camera angles.

Next step:
- Open `run_proc_maze_test.bat` and inspect the screenshots' problem areas. If a light still appears too close to a wall, tune `CEILING_LIGHT_WALL_CLEARANCE` or the candidate scoring, not per-room hand placement.

## 2026-05-04 Lighting balance tightening pass

Current objective:
- Lower the global warm ambient fill so unlit/off-axis areas do not stay too bright.
- Slightly strengthen ceiling lights while increasing attenuation so light stays more local.
- Preserve existing wall, door-frame, material, AO/contact-lighting, shadow, player, and proc-maze topology systems.

Current progress:
- Updated the shared four-room generator in `scripts/core/SceneBuilder.gd`:
  - `WORLD_AMBIENT_ENERGY = 0.07` from `0.18` across the two ambient passes.
  - `CEILING_LIGHT_ENERGY = 1.12` from `1.05`.
  - `CEILING_LIGHT_ATTENUATION = 0.92` from `0.78`.
  - `CEILING_LIGHT_RANGE` remains `6.0`.
- Updated the proc-maze generator in `scripts/proc_maze/ProcMazeSceneBuilder.gd`:
  - `WORLD_AMBIENT_ENERGY = 0.07` from `0.18` across the two ambient passes.
  - `CEILING_LIGHT_ENERGY = 1.18` from `1.12`.
  - `CEILING_LIGHT_ATTENUATION = 0.92` from `0.78`.
  - `CEILING_LIGHT_RANGE` remains `6.2`.
- Updated `scripts/tools/ValidateSceneShadows.gd` to accept the darker ambient range `0.05..0.09` and stronger light attenuation up to `1.00`.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`, `scenes/tests/Test_ProcMazeMap.tscn`, and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`.
- Saved scene scan confirms MVP now stores `ambient_light_energy = 0.07`, `light_energy = 1.12`, and `omni_attenuation = 0.92`; proc-maze target scenes store `ambient_light_energy = 0.07`, `light_energy = 1.18`, and `omni_attenuation = 0.92`.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md`
- `scripts/core/SceneBuilder.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/tools/ValidateSceneShadows.gd`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse: `--headless --path . --quit`
- MVP bake: `--headless --path . --script res://scripts/tools/BakeFourRoomScene.gd`
- MVP validations: `ValidateCleanRebuildScene.gd`, `ValidateMaterialLightingRules.gd`, `ValidateSceneShadows.gd`, `ValidateLightFlicker.gd`, `ValidateGeneratedMeshRules.gd`
- MVP startup: `--headless --path . --scene res://scenes/mvp/FourRoomMVP.tscn --quit-after 5`
- Proc-maze bake/validation: `BakeTestProcMazeMap.gd`, `ValidateTestProcMazeMap.gd`, `ValidateProcMazePlayable.gd`
- Proc-maze no-ceiling bake/validation: `BakeTestProcMazeNoCeilingPreview.gd`, `ValidateProcMazeNoCeilingPreview.gd`
- Proc-maze startup checks for both target scenes with `--quit-after 5`
- Saved scene scans for `ambient_light_energy`, `light_energy`, `omni_range`, and `omni_attenuation`.

Validation result: PASS

Validation evidence:
- `logs/lighting_balance_parse_20260504_141000.log`
- `logs/lighting_balance_bake_mvp_20260504_141010.log`
- `logs/lighting_balance_validate_clean_20260504_141020.log`
- `logs/lighting_balance_validate_material_20260504_141020.log`
- `logs/lighting_balance_validate_shadows_20260504_141020.log`
- `logs/lighting_balance_validate_flicker_20260504_141020.log`
- `logs/lighting_balance_validate_generated_mesh_20260504_141020.log`
- `logs/lighting_balance_startup_mvp_20260504_141030.log`
- `logs/lighting_balance_bake_proc_maze_20260504_141040.log`
- `logs/lighting_balance_validate_proc_maze_20260504_141040.log`
- `logs/lighting_balance_validate_proc_playable_20260504_141040.log`
- `logs/lighting_balance_bake_proc_no_ceiling_20260504_141040.log`
- `logs/lighting_balance_validate_proc_no_ceiling_20260504_141040.log`
- `logs/lighting_balance_startup_proc_maze_20260504_141050.log`
- `logs/lighting_balance_startup_proc_no_ceiling_20260504_141050.log`
- `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`
- `CLEAN_REBUILD_SCENE_VALIDATION PASS`
- `MATERIAL_LIGHTING_RULES_VALIDATION PASS`
- `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`
- `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 min_interval=28.0 bright_range=1.25-1.85 base=1.120 dim=0.112 bright=1.792 panel_base=1.100 panel_dim=0.132 panel_bright=1.760`
- `GENERATED_MESH_RULES_VALIDATION PASS`
- `TEST_PROC_MAZE_VALIDATION PASS seed=2026050401 rooms=38 main=18 branches=10 loops=5 macro_loops=1 macro_cycle=14 largest_cycle=14 macro_a=8 macro_b=8 small_loops=3 dead=4 long=7 l_turn=5 l_room=3 internal_large=3 hubs=2 plain_rect=0 large=5 special=2 narrow_corridor=12 normal_corridor=7 normal_room=12 large_width=5 hub_width=2 overlap=false door_to_wall=false fps=1.0 draw_calls=0 lights=38`
- `PROC_MAZE_PLAYABLE_VALIDATION PASS start=(3.75, 0.05, 3.75) end=(7.117625, 0.000838, 3.75) moved_x=3.368 camera_current=true`
- `PROC_MAZE_NO_CEILING_PREVIEW_VALIDATION PASS rooms=38 floors=38 walls=345 openings=42 frames=42 lights=38 ceilings=0 camera_size=106.20 player=false`

Current blocking issue:
- No automated blocker.
- This is a visual lighting-feel change, so final acceptance still needs an editor/runtime look from the same camera angles as the user's screenshots.
- Some logs contain the known non-blocking MCP Runtime port `7777` conflict because another Godot/MCP process owns that port; listed validation commands exited 0.

Next step:
- Reopen or refresh `FourRoomMVP.tscn` and compare the previously bright no-direct-light wall/corner areas.
- If it is still too flat, tune `WORLD_AMBIENT_ENERGY` down further before increasing light range.
- If direct light feels too harsh, reduce `CEILING_LIGHT_ATTENUATION` slightly before reducing the new lower ambient baseline.

## 2026-05-04 Proc-maze corner seam and sprint jitter pass

Current objective:
- Hide visible right-angle wall-corner seams in generated proc-maze walls without hand-placing walls or changing collision clearance.
- Reduce the visible jitter when sprinting.
- Preserve the current macro-loop topology, wall/opening/door-frame/material/AO/light systems, and do not modify `scenes/mvp/FourRoomMVP.tscn`.

Current progress:
- Added `WALL_CORNER_VISUAL_CLEARANCE = 0.01` and computes `WALL_CORNER_VISUAL_OVERLAP = WALL_THICKNESS * 0.5 - WALL_CORNER_VISUAL_CLEARANCE` in `scripts/proc_maze/ProcMazeSceneBuilder.gd`.
- With the current `0.2m` wall thickness, solid proc-maze boundary wall visuals now extend `0.09m` past each end along their length axis.
- Solid wall collision sizes remain unchanged. Only the visual mesh is longer, so player clearance and navigation are not narrowed.
- This brings one wall end close to the perpendicular wall face while leaving a 1cm non-coplanar safety gap to avoid z-fighting/flicker.
- Saved wall bodies now carry `metadata/corner_visual_overlap = 0.09000000000000001` for inspection.
- Added `floor_snap_distance = 0.28` to `scripts/player/PlayerController.gd` and assigns it to `floor_snap_length` in `_ready()`.
- Moved `scripts/camera/CameraController.gd` following from `_process()` to `_physics_process()` so the camera follows the physics-updated player on the same tick.
- Rebuilt both proc-maze target scenes after the wall visual change.

Files changed:
- `CURRENT_STATE.md`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/player/PlayerController.gd`
- `scripts/camera/CameraController.gd`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse: `--headless --path . --quit`
- Godot bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeMap.gd`
- Godot structure validation: `--headless --path . --script res://scripts/tools/ValidateTestProcMazeMap.gd`
- Godot playable validation: `--headless --path . --script res://scripts/tools/ValidateProcMazePlayable.gd`
- Godot no-ceiling preview bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeNoCeilingPreview.gd`
- Godot no-ceiling preview validation: `--headless --path . --script res://scripts/tools/ValidateProcMazeNoCeilingPreview.gd`
- Player animation validation: `--headless --path . --script res://scripts/tools/ValidatePlayerAnimation.gd`
- Player animation/collision validation: `--headless --path . --script res://scripts/tools/ValidatePlayerAnimationCollision.gd`
- Camera free-orbit validation: `--headless --path . --script res://scripts/tools/ValidateCameraRecenter.gd`
- Generated mesh rules validation: `--headless --path . --script res://scripts/tools/ValidateGeneratedMeshRules.gd`
- Godot playable startup: `--headless --path . --scene res://scenes/tests/Test_ProcMazeMap.tscn --quit-after 5`
- Godot no-ceiling startup: `--headless --path . --scene res://scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn --quit-after 5`
- Proc-maze/player/camera target scan for negative/mirrored scale, FourRoom room-name references, and transparent cover/fade terms.

Validation result: PASS

Validation evidence:
- `logs/proc_maze_corner_near_flush_parse_20260504_134311.log`
- `logs/proc_maze_corner_near_flush_bake_20260504_134324.log`
- `logs/proc_maze_corner_near_flush_validate_structure_20260504_134337.log`
- `logs/proc_maze_corner_near_flush_no_ceiling_bake_20260504_134349.log`
- `logs/proc_maze_corner_near_flush_no_ceiling_validate_20260504_134401.log`
- `logs/proc_maze_corner_near_flush_startup_playable_20260504_134436.log`
- `logs/proc_maze_corner_near_flush_startup_no_ceiling_20260504_134436.log`
- `logs/proc_maze_corner_jitter_validate_player_animation_20260504_133822.log`
- `logs/proc_maze_corner_jitter_validate_player_collision_20260504_133822.log`
- `logs/proc_maze_corner_jitter_validate_camera_recenter_20260504_133822.log`
- `logs/proc_maze_corner_jitter_validate_generated_mesh_20260504_133855.log`
- `TEST_PROC_MAZE_VALIDATION PASS seed=2026050401 rooms=38 main=18 branches=10 loops=5 macro_loops=1 macro_cycle=14 largest_cycle=14 macro_a=8 macro_b=8 small_loops=3 dead=4 long=7 l_turn=5 l_room=3 internal_large=3 hubs=2 plain_rect=0 large=5 special=2 narrow_corridor=12 normal_corridor=7 normal_room=12 large_width=5 hub_width=2 overlap=false door_to_wall=false fps=1.0 draw_calls=0 lights=38`
- `PROC_MAZE_PLAYABLE_VALIDATION PASS start=(3.75, 0.05, 3.75) end=(7.117625, 0.000838, 3.75) moved_x=3.368 camera_current=true`
- `PROC_MAZE_NO_CEILING_PREVIEW_VALIDATION PASS rooms=38 floors=38 walls=345 openings=42 frames=42 lights=38 ceilings=0 camera_size=106.20 player=false`
- `PLAYER_ANIMATION_VALIDATION PASS movement=mixamo_com idle=idle_generated`
- `PLAYER_ANIMATION_COLLISION_VALIDATION PASS player_x=-2.439`
- `CAMERA_FREE_ORBIT_VALIDATION PASS yaw_delta=2.700 stationary_delta=0.000 moving_delta=0.000 pitch=-0.087..0.209`
- `GENERATED_MESH_RULES_VALIDATION PASS`
- Saved scene scan: both proc-maze test scenes contain 345 solid wall bodies with `metadata/corner_visual_overlap = 0.09000000000000001`.
- Target scan found no negative/mirrored scale text, no `Room_A/Room_B/Room_C/Room_D` references, and no transparent cover/fade terms in the touched proc-maze/player/camera target files.

Current blocking issue:
- No automated blocker.
- The corner seam and sprint jitter are visual/feel issues, so final acceptance still needs an editor/runtime visual check.
- Some logs contain the known non-blocking MCP Runtime port `7777` conflict because another Godot/MCP process owns that port; listed validation commands exited 0.

Next step:
- Run `run_proc_maze_test.bat` and check the same wall-corner angle.
- Sprint across floor tile seams and near walls; if jitter remains, the next likely fix is animation-specific smoothing or camera interpolation tuning, not more wall geometry changes.

## 2026-05-04 Proc-maze macro-loop topology pass

Current objective:
- Break the proc-maze "single trunk with hanging rooms" feel by adding a real macro loop to the 30-45 node generated test map.
- Keep the existing generated wall, doorway, door-frame, material, AO/contact-lighting, player, ceiling, and MVP systems intact.
- Do not modify `scenes/mvp/FourRoomMVP.tscn`.

Current progress:
- Added generator version `proc_maze_fixed_layout_v0.4_macro_loop`.
- Kept the fixed-layout structure but expanded it to 38 nodes by adding `B37` as a narrow L-turn connector near the macro-loop merge.
- Rerouted the area_1/area_2 branch into a declared macro loop:
  - Split node: `N05`
  - Merge node: `N12`
  - Route A: `N05 -> N06 -> N07 -> N08 -> N09 -> N10 -> N11 -> N12`
  - Route B: `N05 -> B31 -> B24 -> B25 -> B26 -> B27 -> B37 -> N12`
- Route A is the corridor-pressure spine; Route B uses a larger-room arc with `B31` normal room, `B24` large side-chamber room, `B25` L-room, then narrow/offset/L-turn corridor connectors.
- Preserved 3 declared small loops:
  - `N05 -> N06 -> B24 -> B31 -> N05`
  - `N09 -> B28 -> B29 -> N10 -> N09`
  - `N15 -> N16 -> N17 -> B34 -> B36 -> B35 -> N15`
- Extended topology validation to require:
  - at least one declared macro loop,
  - a 10-18 node simple cycle,
  - split/merge route length threshold,
  - disjoint route interiors,
  - route A / route B heterogeneous space signatures,
  - main path alternative through the macro loop,
  - no single internal macro-loop node blocking split-to-merge,
  - 2-4 declared small loops.
- Updated area validation so cross-area declared macro/small-loop participation counts as loop structure; this avoids rejecting `area_1` only because its macro loop closes in adjacent areas.
- Debug view now marks split/merge labels, Macro Route A, Macro Route B, and small-loop route overlays.
- Layout capture now overlays Macro Route A, Macro Route B, split/merge dots, and small loops.
- Rebuilt both proc-maze target scenes.

Files changed:
- `CURRENT_STATE.md`
- `scripts/proc_maze/MapGraphGenerator.gd`
- `scripts/proc_maze/MapValidator.gd`
- `scripts/proc_maze/DebugView.gd`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/tools/ValidateTestProcMazeMap.gd`
- `scripts/tools/CaptureTestProcMazeMapLayout.gd`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `artifacts/screenshots/test_proc_maze_layout.png`

Commands run:
- `git status --short` -> FAIL, this directory is not a git repository.
- `git diff --stat` -> FAIL, this directory is not a git repository.
- Godot parse: `--headless --path . --quit`
- Intermediate Godot bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeMap.gd` -> FAIL because old per-area validation rejected `area_1` for no purely local loop.
- Godot bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeMap.gd`
- Godot structure validation: `--headless --path . --script res://scripts/tools/ValidateTestProcMazeMap.gd`
- Godot playable validation: `--headless --path . --script res://scripts/tools/ValidateProcMazePlayable.gd`
- Godot no-ceiling preview bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeNoCeilingPreview.gd`
- Godot no-ceiling preview validation: `--headless --path . --script res://scripts/tools/ValidateProcMazeNoCeilingPreview.gd`
- Godot layout capture: `--headless --path . --script res://scripts/tools/CaptureTestProcMazeMapLayout.gd`
- Godot playable startup: `--headless --path . --scene res://scenes/tests/Test_ProcMazeMap.tscn --quit-after 5`
- Godot no-ceiling startup: `--headless --path . --scene res://scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn --quit-after 5`
- Proc-maze target scan for negative/mirrored scale, FourRoom room-name references, and transparent cover/fade terms.

Validation result: PASS

Validation evidence:
- `logs/proc_maze_macro_routeb8_parse_20260504_132348.log`
- `logs/proc_maze_macro_routeb8_bake_20260504_132356.log`
- `logs/proc_maze_macro_routeb8_validate_structure_20260504_132406.log`
- `logs/proc_maze_macro_routeb8_validate_playable_20260504_132415.log`
- `logs/proc_maze_macro_routeb8_layout_capture_20260504_132425.log`
- `logs/proc_maze_macro_routeb8_no_ceiling_bake_20260504_132435.log`
- `logs/proc_maze_macro_routeb8_no_ceiling_validate_20260504_132444.log`
- `logs/proc_maze_macro_routeb8_startup_playable_20260504_132453.log`
- `logs/proc_maze_macro_routeb8_startup_no_ceiling_20260504_132501.log`
- `TEST_PROC_MAZE_VALIDATION PASS seed=2026050401 rooms=38 main=18 branches=10 loops=5 macro_loops=1 macro_cycle=14 largest_cycle=14 macro_a=8 macro_b=8 small_loops=3 dead=4 long=7 l_turn=5 l_room=3 internal_large=3 hubs=2 plain_rect=0 large=5 special=2 narrow_corridor=12 normal_corridor=7 normal_room=12 large_width=5 hub_width=2 overlap=false door_to_wall=false fps=1.0 draw_calls=0 lights=38`
- `PROC_MAZE_PLAYABLE_VALIDATION PASS start=(3.75, 0.05, 3.75) end=(7.117625, 0.000838, 3.75) moved_x=3.368 camera_current=true`
- `PROC_MAZE_NO_CEILING_PREVIEW_VALIDATION PASS rooms=38 floors=38 walls=345 openings=42 frames=42 lights=38 ceilings=0 camera_size=106.20 player=false`
- `TEST_PROC_MAZE_LAYOUT_SCREENSHOT PASS path=res://artifacts/screenshots/test_proc_maze_layout.png`
- Saved scene scan confirms both proc-maze test scenes use `proc_maze_fixed_layout_v0.4_macro_loop` with `macro_loop_count=1`, `macro_cycle_length=14`, and `small_loop_count=3`.
- DebugView saved-scene scan confirms `SPLIT`, `MERGE`, `MacroRouteA_*`, `MacroRouteB_*`, and `SmallLoop_*` route markers exist in both test scenes.
- Proc-maze target scan found no negative/mirrored scale text, no `Room_A/Room_B/Room_C/Room_D` references, and no transparent cover/fade terms in the touched proc-maze target files.

Current blocking issue:
- No automated blocker.
- Manual visual acceptance is still required to judge whether the macro loop now breaks the "single trunk with hanging rooms" feeling.
- Some validation logs may include the known non-blocking MCP Runtime port `7777` conflict if another Godot/MCP process already owns the port; listed validation commands exited 0.

Next step:
- Open `run_proc_maze_test.bat` or `run_proc_maze_no_ceiling_preview.bat` and inspect the map flow.
- In DebugView, verify `N05` split, `N12` merge, the green/cyan main Route A, the orange large-room Route B, and blue small-loop overlays.
- If the map still reads too linear visually, the next iteration should move the Route B arc farther from Route A or add one more large-room connector module while keeping the same topology contract.

## 2026-05-04 Player scale globalized and ceiling seam fix

Current objective:
- Use the user's saved MVP player size as the global player visual size.
- Fix the visible ceiling-wall light leak in the MVP scene without breaking the generated wall/door-frame/material/shadow rules.

Current progress:
- Confirmed the user had scaled `scenes/mvp/FourRoomMVP.tscn` `PlayerRoot/Player` to `1.4666373`.
- Folded that visual scale into the shared player module by changing `scenes/modules/PlayerModule.tscn` `ModelRoot.scale` from `0.1` to `0.14666373`.
- Removed the extra MVP scene-instance player scale so the FourRoomMVP scene uses the same global `PlayerModule.tscn` visual size instead of double-scaling.
- Kept the player collision capsule at radius `0.28m` and height `1.6m`; scaling the collision to 1.466x would risk exceeding the current `2.15m` door clearance.
- Diagnosed the ceiling seam as the side effect of the intentional no-horizontal-wall-cap rule. Wall tops are not capped because coplanar caps can fight the ceiling underside.
- Fixed the seam by increasing wall/opening vertical visual overlap into the ceiling from `0.025m` to `0.08m` in the shared four-room wall generation path, not by adding coplanar top faces.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md`
- `scenes/modules/PlayerModule.tscn`
- `scenes/mvp/FourRoomMVP.tscn`
- `scripts/core/SceneBuilder.gd`
- `scripts/scene/WallOpeningBody.gd`

Commands run:
- Godot parse: `--headless --path . --quit`
- Godot bake: `--headless --path . --script res://scripts/tools/BakeFourRoomScene.gd`
- Clean rebuild validation: `--headless --path . --script res://scripts/tools/ValidateCleanRebuildScene.gd`
- Generated mesh rules validation: `--headless --path . --script res://scripts/tools/ValidateGeneratedMeshRules.gd`
- Material/lighting rules validation: `--headless --path . --script res://scripts/tools/ValidateMaterialLightingRules.gd`
- Scene shadow validation: `--headless --path . --script res://scripts/tools/ValidateSceneShadows.gd`
- Phase 3 foreground occlusion validation: `--headless --path . --script res://scripts/tools/ValidatePhase3Occlusion.gd`
- MVP startup: `--headless --path . --scene res://scenes/mvp/FourRoomMVP.tscn --quit-after 5`
- Proc-maze playable validation: `--headless --path . --script res://scripts/tools/ValidateProcMazePlayable.gd`
- Forbidden-pattern scans for old visibility masks, old mask helpers, old fade constants, room-specific `if Room_A/...`, and visited-room state.

Validation result: PASS

Validation evidence:
- `logs/player_scale_ceiling_seam_parse_20260504_125655.log`
- `logs/player_scale_ceiling_seam_bake_20260504_125705.log`
- `logs/player_scale_ceiling_seam_validate_clean_20260504_125719.log`
- `logs/player_scale_ceiling_seam_validate_generated_mesh_20260504_125719.log`
- `logs/player_scale_ceiling_seam_validate_material_20260504_125737.log`
- `logs/player_scale_ceiling_seam_validate_shadows_20260504_125737.log`
- `logs/player_scale_ceiling_seam_validate_occlusion_20260504_125737.log`
- `logs/player_scale_ceiling_seam_startup_mvp_20260504_125836.log`
- `logs/player_scale_ceiling_seam_validate_proc_playable_20260504_125836.log`
- `BAKE_FOUR_ROOM_SCENE PASS`
- `CLEAN_REBUILD_SCENE_VALIDATION PASS`
- `GENERATED_MESH_RULES_VALIDATION PASS`
- `MATERIAL_LIGHTING_RULES_VALIDATION PASS`
- `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`
- `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`
- `PROC_MAZE_PLAYABLE_VALIDATION PASS start=(3.75, 0.043333, 3.75) end=(7.117625, 0.000838, 3.75) moved_x=3.368 camera_current=true`
- Saved scale check: no `1.4666373` player instance scale remains in `FourRoomMVP.tscn`; `PlayerModule.tscn` now has `ModelRoot.scale = Vector3(0.14666373, 0.14666373, 0.14666373)`.
- Saved seam rule check: `SceneBuilder.gd` `WALL_VISUAL_VERTICAL_OVERLAP = 0.08`; `WallOpeningBody.gd` `VISUAL_VERTICAL_OVERLAP = 0.08`.
- Forbidden-pattern scan passed for the checked old visibility/fade/room-state patterns.

Current blocking issue:
- No automated blocker. The ceiling-wall seam fix still needs visual confirmation in the editor viewport because the original issue was visual.
- Some logs may contain the known non-blocking MCP Runtime port `7777` conflict when another Godot/MCP process already owns the port; all listed validation commands exited 0.

Next step:
- Reopen or refresh `FourRoomMVP.tscn` in the editor and inspect the ceiling-wall edge from the same angle.
- If any seam remains, the next fix should continue using shared generated wall/ceiling geometry rules, not per-wall editor edits.

## 2026-05-04 Proc-maze corridor width-tier pass

Current objective:
- Make procedural corridors read as corridors instead of long rectangular rooms.
- Explicitly separate corridor and room width rules while preserving the existing generated wall, opening, door-frame, material, ceiling, AO/contact-lighting, and validation systems.
- Do not modify `scenes/mvp/FourRoomMVP.tscn`.

Current progress:
- Replaced the proc-maze registry with `proc_maze_registry_v0.3_corridor_width_tiers`.
- Changed the proc-maze spatial unit from one 6.0m room-sized cell to a 2.5m sub-grid.
- Added explicit width tiers:
  - `narrow_corridor`: 1 cell / 2.5m
  - `normal_corridor`: 2 cells / 5.0m
  - `normal_room`: 3 cells / 7.5m
  - `large_room` / `hub_room`: 4 cells / 10.0m
- Added required corridor module IDs: `corridor_narrow_straight`, `corridor_long_straight`, `corridor_l_turn`, `corridor_t_junction`, and `corridor_offset`.
- Reworked the fixed 37-node layout to alternate expanded rooms/hubs/large rooms with visibly narrower corridors.
- Removed current graph usage of old same-width modules such as `corridor_long_3`, `corridor_long_5`, `corridor_2x1`, `room_narrow_long`, and `room_1x1`.
- Extended `MapValidator.gd` so it rejects:
  - missing width tiers,
  - missing required corridor module types,
  - corridors whose width approaches normal room width,
  - long corridors with insufficient aspect ratio,
  - normal rooms that become corridor-like strips,
  - corridors with too many graph connections / uncontrolled side doors.
- Updated corridor ceiling-light panels to be more linear/directional while keeping the existing Light3D/material system.
- Rebuilt playable and no-ceiling preview test scenes.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- `四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/CODEX_FRESH_SESSION_PROMPT.md`
- `四房间MVP_Agent抗遗忘执行包/docs/HANDOFF_20260504_PROC_MAZE.md`
- `data/proc_maze/module_registry.json`
- `scripts/proc_maze/ModuleRegistry.gd`
- `scripts/proc_maze/MapGraphGenerator.gd`
- `scripts/proc_maze/MapValidator.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/proc_maze/DebugView.gd`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/tools/ValidateTestProcMazeMap.gd`
- `scenes/proc_maze/modules/normal_room.tscn`
- `scenes/proc_maze/modules/corridor_narrow_straight.tscn`
- `scenes/proc_maze/modules/corridor_long_straight.tscn`
- `scenes/proc_maze/modules/corridor_offset.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `artifacts/screenshots/test_proc_maze_layout.png`

Commands run:
- Godot parse: `--headless --path . --quit`
- Godot bake attempt: `--headless --path . --script res://scripts/tools/BakeTestProcMazeMap.gd` -> FAIL before final adjustment because main path turns were only 5.
- Adjusted the exit branch placement to add more main-path direction change without hand-placing walls.
- Godot bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeMap.gd`
- Godot structure validation: `--headless --path . --script res://scripts/tools/ValidateTestProcMazeMap.gd`
- Godot playable validation: `--headless --path . --script res://scripts/tools/ValidateProcMazePlayable.gd`
- Godot no-ceiling preview bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeNoCeilingPreview.gd`
- Godot no-ceiling preview validation: `--headless --path . --script res://scripts/tools/ValidateProcMazeNoCeilingPreview.gd`
- Godot layout capture: `--headless --path . --script res://scripts/tools/CaptureTestProcMazeMapLayout.gd`
- Godot playable startup: `--headless --path . --scene res://scenes/tests/Test_ProcMazeMap.tscn --quit-after 5`
- Godot no-ceiling startup: `--headless --path . --scene res://scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn --quit-after 5`
- Forbidden-pattern scans over implementation paths.
- Proc-maze target scans for negative/mirrored scale, FourRoom room-name references, and transparent cover/fade terms.
- Updated fresh-session and handoff docs with the current width-tier metrics and mirrored them into the execution package.

Validation result: PASS

Validation evidence:
- `logs/proc_maze_width_parse_20260504_120849.log`
- `logs/proc_maze_width_bake_20260504_120858.log` -> expected intermediate FAIL before final layout turn adjustment.
- `logs/proc_maze_width_bake_20260504_121006.log`
- `logs/proc_maze_width_validate_structure_20260504_121021.log`
- `logs/proc_maze_width_validate_playable_20260504_121031.log`
- `logs/proc_maze_width_no_ceiling_bake_20260504_121043.log`
- `logs/proc_maze_width_no_ceiling_validate_20260504_121052.log`
- `logs/proc_maze_width_layout_capture_20260504_121103.log`
- `logs/proc_maze_width_startup_playable_20260504_121115.log`
- `logs/proc_maze_width_startup_no_ceiling_20260504_121115.log`
- `TEST_PROC_MAZE_VALIDATION PASS seed=2026050401 rooms=37 main=18 branches=10 loops=4 dead=5 long=7 l_turn=5 l_room=3 internal_large=3 hubs=2 plain_rect=0 large=5 special=2 narrow_corridor=11 normal_corridor=7 normal_room=12 large_width=5 hub_width=2 overlap=false door_to_wall=false fps=1.0 draw_calls=0 lights=37`
- `PROC_MAZE_PLAYABLE_VALIDATION PASS start=(3.75, 0.05, 3.75) end=(7.117625, 0.000838, 3.75) moved_x=3.368 camera_current=true`
- `PROC_MAZE_NO_CEILING_PREVIEW_VALIDATION PASS rooms=37 floors=37 walls=342 openings=40 frames=40 lights=37 ceilings=0 camera_size=106.20 player=false`
- `TEST_PROC_MAZE_LAYOUT_SCREENSHOT PASS path=res://artifacts/screenshots/test_proc_maze_layout.png`
- Startup checks for both test scenes exited 0.
- Forbidden-pattern scan: no old visibility masks, old mask helpers, old fade constants, room-specific `if Room_A/...`, or visited-room state were found. Existing alpha/transparency hits remain limited to approved foreground cutout and grime experiment files.
- Proc-maze target scan: no negative/mirrored scale text, no `Room_A/Room_B/Room_C/Room_D` references, and no transparent cover/fade terms.

Current blocking issue:
- No automated blocker. Manual visual acceptance is still required to confirm the player feels the intended "room opens -> corridor narrows -> room opens again" rhythm.
- The no-ceiling validation log may include the known non-blocking MCP Runtime port `7777` conflict if another Godot/MCP process already owns the port; the validation command still exited 0.

Next step:
- User visually inspects `run_proc_maze_test.bat` and `run_proc_maze_no_ceiling_preview.bat`.
- If the corridor squeeze now reads correctly, use these width-tier rules as the base for randomized topology.
- If rejected, tune module quotas/placement under the same width-tier module system. Do not use hand-placed walls, negative scale, stretched wall bodies, or long rectangular room modules to fake corridors.

## 2026-05-04 Proc-maze fresh-session validation rerun

Current objective:
- Continue the Backrooms Godot 4.6.2 Mobile renderer large-map procedural maze test from a fresh session without relying on chat history.
- Validate only the current proc-maze targets:
  - `scenes/tests/Test_ProcMazeMap.tscn`
  - `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
  - `run_proc_maze_test.bat`
  - `run_proc_maze_no_ceiling_preview.bat`
- Do not modify `scenes/mvp/FourRoomMVP.tscn`.

Current progress:
- Read `docs/CODEX_FRESH_SESSION_PROMPT.md`.
- Then read the required project documents in order: `README.md`, `CURRENT_STATE.md`, `docs/AGENT_START_HERE.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/FORBIDDEN_PATTERNS.md`, `docs/ACCEPTANCE_CHECKLIST.md`, and `docs/HANDOFF_20260504_PROC_MAZE.md`.
- Confirmed all proc-maze target scenes, tool scripts, and run `.bat` launchers exist.
- Confirmed Godot 4.6.2 console executable exists at the WinGet path recorded in the handoff.
- Re-ran the bounded proc-maze validation chain. All commands exited 0.
- Refreshed layout evidence at `artifacts/screenshots/test_proc_maze_layout.png`.

Files changed / generated:
- `CURRENT_STATE.md`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `artifacts/screenshots/test_proc_maze_layout.png`
- `logs/proc_maze_session_parse_20260504_114820.log`
- `logs/proc_maze_session_bake_20260504_114834.log`
- `logs/proc_maze_session_validate_structure_20260504_114845.log`
- `logs/proc_maze_session_validate_playable_20260504_114854.log`
- `logs/proc_maze_session_no_ceiling_bake_20260504_114904.log`
- `logs/proc_maze_session_no_ceiling_validate_20260504_114913.log`
- `logs/proc_maze_session_layout_capture_20260504_114922.log`
- `logs/proc_maze_session_startup_playable_20260504_114934.log`
- `logs/proc_maze_session_startup_no_ceiling_20260504_114942.log`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- `rg --files -g 'TASK.md' -g 'RULES.md' -g 'LOG.md' -g 'ARCH.md'` -> no matching root files.
- Godot parse: `--headless --path . --quit`
- Godot bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeMap.gd`
- Godot structure validation: `--headless --path . --script res://scripts/tools/ValidateTestProcMazeMap.gd`
- Godot playable validation: `--headless --path . --script res://scripts/tools/ValidateProcMazePlayable.gd`
- Godot no-ceiling preview bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeNoCeilingPreview.gd`
- Godot no-ceiling preview validation: `--headless --path . --script res://scripts/tools/ValidateProcMazeNoCeilingPreview.gd`
- Godot layout capture: `--headless --path . --script res://scripts/tools/CaptureTestProcMazeMapLayout.gd`
- Godot playable startup: `--headless --path . --scene res://scenes/tests/Test_ProcMazeMap.tscn --quit-after 5`
- Godot no-ceiling startup: `--headless --path . --scene res://scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn --quit-after 5`
- Forbidden-pattern scans over `scripts`, `data`, `scenes`, and `materials`, excluding `addons`, `logs`, `artifacts`, `docs`, and the mirrored execution package.
- Proc-maze scope scans for negative/mirrored scale, `Room_A/Room_B/Room_C/Room_D` references, and transparent/fade/mask terms.

Validation result: PASS

Validation evidence:
- `TEST_PROC_MAZE_BAKE PASS path=res://scenes/tests/Test_ProcMazeMap.tscn seed=2026050401 rooms=37`
- `TEST_PROC_MAZE_VALIDATION PASS seed=2026050401 rooms=37 main=18 branches=10 loops=4 dead=5 long=5 l_turn=7 l_room=4 internal_large=3 hubs=2 plain_rect=5 large=5 special=2 overlap=false door_to_wall=false fps=1.0 draw_calls=0 lights=37`
- `PROC_MAZE_PLAYABLE_VALIDATION PASS start=(5.0, 0.05, 5.0) end=(10.09083, 0.000823, 5.0) moved_x=5.091 camera_current=true`
- `TEST_PROC_MAZE_NO_CEILING_PREVIEW_BAKE PASS path=res://scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn seed=2026050401 rooms=37 lights=37`
- `PROC_MAZE_NO_CEILING_PREVIEW_VALIDATION PASS rooms=37 floors=37 walls=179 openings=40 frames=40 lights=37 ceilings=0 camera_size=155.76 player=false`
- `TEST_PROC_MAZE_LAYOUT_SCREENSHOT PASS path=res://artifacts/screenshots/test_proc_maze_layout.png`
- Both playable and no-ceiling preview startup checks exited 0.
- Forbidden-pattern scan: no old visibility mask resource names, old mask append helpers, old camera fade constants, room-specific `if Room_A/...`, or visited-room state were found in the scanned implementation paths.
- Allowed alpha/transparency hits remain limited to the approved foreground cutout shader and grime experiment system.
- Proc-maze target scan found no negative/mirrored scale text and no `Room_A/Room_B/Room_C/Room_D` references.

Current blocking issue:
- No automated blocker. Manual visual acceptance is still the gate before moving from the accepted fixed-layout test to randomized topology.
- `scripts/tools/CaptureTestProcMazeMapScreenshot.gd` remains a known non-blocking hung viewport screenshot path from the prior session; it was not used in this pass.

Next step:
- User visually inspects `run_proc_maze_test.bat` and `run_proc_maze_no_ceiling_preview.bat`.
- If accepted, implement randomized topology using the same `ModuleRegistry`, occupied-cell graph generation, `MapValidator`, `ProcMazeSceneBuilder`, and `SceneValidator` pipeline.
- If rejected, tune fixed layout/module quotas first. Do not hand-place walls, use room-specific exceptions, negative scale, mirrored scale, stretched wall hacks, or door-to-wall connectors.

## 2026-05-04 New-session handoff and light cleanup

Current objective:
- Prepare a concise handoff so the next Codex session can continue without relying on chat history.
- Clean only clearly useless transient files without deleting validation evidence, models, accepted scenes, or experiment assets.

Current progress:
- Replaced `docs/CODEX_FRESH_SESSION_PROMPT.md` with a current fresh-session prompt.
- Added `docs/HANDOFF_20260504_PROC_MAZE.md`.
- Added `docs/CLEANUP_CANDIDATES_20260504.md`.
- Mirrored those three documents under `四房间MVP_Agent抗遗忘执行包/docs/`.
- Removed two non-evidence logs: empty `logs/run_proc_maze_no_ceiling_preview.log` and failed/hung screenshot log `logs/proc_maze_variety_screenshot_20260504.log`.

Files changed:
- `CURRENT_STATE.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- `docs/CLEANUP_CANDIDATES_20260504.md`
- `四房间MVP_Agent抗遗忘执行包/docs/CODEX_FRESH_SESSION_PROMPT.md`
- `四房间MVP_Agent抗遗忘执行包/docs/HANDOFF_20260504_PROC_MAZE.md`
- `四房间MVP_Agent抗遗忘执行包/docs/CLEANUP_CANDIDATES_20260504.md`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- Removed only `logs/run_proc_maze_no_ceiling_preview.log` and `logs/proc_maze_variety_screenshot_20260504.log` after path verification inside the workspace.

Validation result: PASS

Validation evidence:
- Documentation-only handoff pass; no Godot runtime validation required.

Current blocking issue:
- None. User visual acceptance of the proc-maze result remains the next real gate.

Next step:
- Start the next session from `docs/CODEX_FRESH_SESSION_PROMPT.md`.
- For visual acceptance, run `run_proc_maze_test.bat` and `run_proc_maze_no_ceiling_preview.bat`.

## 2026-05-04 Procedural maze space-variety pass

Current objective:
- Replace the monotonous rectangular-room fixed proc-maze test with a module-type-based 30-45 node layout that includes real long corridors, L-turn spaces, L-shaped rooms, hubs, large rooms with internal partitions, local loops, dead ends, and special reserved spaces.
- Keep `scenes/mvp/FourRoomMVP.tscn` unchanged.

Current progress:
- Expanded `data/proc_maze/module_registry.json` to `proc_maze_registry_v0.2_space_variety`.
- Added the requested module types: `corridor_long_3`, `corridor_long_5`, `corridor_l_turn`, `corridor_t_junction`, `room_l_shape`, `room_wide`, `room_narrow_long`, `hub_room_3_doors`, `hub_room_4_doors`, `large_room_split_ns`, `large_room_split_ew`, `large_room_offset_inner_door`, and `large_room_with_side_chamber`.
- Rebuilt `MapGraphGenerator.gd` as `proc_maze_fixed_layout_v0.2_space_variety` with 37 nodes and shape-cell metadata for non-rectangular footprints.
- Updated the map validator to check actual occupied cells, requested quotas, area variety, local loops, plain-rectangle ratio, repeated signature/door-position chains, and long-corridor repetition.
- Updated the scene builder to generate module geometry from occupied cells rather than bounding rectangles. L-shaped modules now produce L-shaped floors/ceilings/collision, and large internal-room modules receive reusable internal partition walls.
- Updated debug and layout capture to use real occupied cells instead of external rectangle bounds.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `data/proc_maze/module_registry.json`
- `scripts/proc_maze/MapGraphGenerator.gd`
- `scripts/proc_maze/MapValidator.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/proc_maze/SceneValidator.gd`
- `scripts/proc_maze/DebugView.gd`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/tools/ValidateTestProcMazeMap.gd`
- `scripts/tools/CaptureTestProcMazeMapLayout.gd`
- `scenes/proc_maze/modules/*.tscn` placeholders for the new module IDs
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- Godot parse: `--headless --path . --quit`
- Godot bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeMap.gd`
- Godot structure validation: `--headless --path . --script res://scripts/tools/ValidateTestProcMazeMap.gd`
- Godot playable validation: `--headless --path . --script res://scripts/tools/ValidateProcMazePlayable.gd`
- Godot no-ceiling preview bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeNoCeilingPreview.gd`
- Godot no-ceiling preview validation: `--headless --path . --script res://scripts/tools/ValidateProcMazeNoCeilingPreview.gd`
- Godot startup checks for both playable and no-ceiling preview scenes.
- Layout capture: `--headless --path . --script res://scripts/tools/CaptureTestProcMazeMapLayout.gd`
- Forbidden-pattern scans over `scripts`, `data`, `scenes`, and `materials`.

Validation result: PASS

Validation evidence:
- `logs/proc_maze_variety_parse_20260504.log`
- `logs/proc_maze_variety_bake_20260504.log`
- `logs/proc_maze_variety_validate_structure_20260504.log`
- `logs/proc_maze_variety_validate_playable_20260504.log`
- `logs/proc_maze_variety_no_ceiling_bake_20260504.log`
- `logs/proc_maze_variety_no_ceiling_validate_20260504.log`
- `logs/proc_maze_variety_startup_20260504.log`
- `logs/proc_maze_variety_no_ceiling_startup_20260504.log`
- `logs/proc_maze_variety_layout_capture_20260504.log`
- Layout evidence: `artifacts/screenshots/test_proc_maze_layout.png`
- Validation summary: `seed=2026050401`, `generator_version=proc_maze_fixed_layout_v0.2_space_variety`, `rooms=37`, `main=18`, `branches=10`, `loops=4`, `dead=5`, `long=5`, `l_turn=7`, `l_room=4`, `internal_large=3`, `hubs=2`, `plain_rect=5`, `special=2`, `reachable=true`, `overlap=false`, `door_to_wall=false`, `lights=37`.

Current blocking issue:
- Viewport screenshot capture script hung and was stopped; this did not block structural/playable/no-ceiling validation. Manual visual acceptance is still pending.

Next step:
- User opens `run_proc_maze_test.bat` for playable inspection and `run_proc_maze_no_ceiling_preview.bat` for pulled-back no-ceiling layout inspection.
- After visual acceptance, move from the fixed layout test to randomized topology using the same module metadata, shape-cell generation, and validators.

## 2026-05-04 Procedural maze no-ceiling full-map preview

Current objective:
- Provide a separate no-ceiling preview scene for generated maps that opens in a pulled-back god-view camera, not the playable third-person camera.

Current progress:
- Added preview toggles to `scripts/proc_maze/TestProcMazeMap.gd`: `preview_without_ceiling`, `preview_keep_ceiling_lights`, and `preview_full_map_camera`.
- Added `include_ceilings` and `include_ceiling_lights` switches to `scripts/proc_maze/ProcMazeSceneBuilder.gd`.
- Created `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`.
- The preview scene keeps generated floors, walls, openings, door frames, markers, debug labels, and ceiling lights, but omits ceiling meshes/collisions.
- The preview scene disables the playable player/camera hookup and uses the root `Camera3D` as a full-map orthogonal god-view camera.
- Added `open_proc_maze_no_ceiling_preview.bat` for editor inspection and `run_proc_maze_no_ceiling_preview.bat` for direct runtime preview.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/tools/BakeTestProcMazeNoCeilingPreview.gd`
- `scripts/tools/ValidateProcMazeNoCeilingPreview.gd`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `open_proc_maze_no_ceiling_preview.bat`
- `run_proc_maze_no_ceiling_preview.bat`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- Godot parse: `--headless --path . --quit`
- Godot bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeNoCeilingPreview.gd`
- Godot validation: `--headless --path . --script res://scripts/tools/ValidateProcMazeNoCeilingPreview.gd`
- Godot startup: `--headless --path . --scene res://scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn --quit-after 5`
- `rg` scene checks for `Ceiling_`, `PlayerRoot`, `CameraRig`, and camera metadata.

Validation result: PASS

Validation evidence:
- `logs/proc_maze_no_ceiling_fullmap_parse_20260504.log`
- `logs/proc_maze_no_ceiling_fullmap_bake_20260504.log`
- `logs/proc_maze_no_ceiling_fullmap_validate_20260504.log`
- `logs/proc_maze_no_ceiling_fullmap_startup_20260504.log`
- Validation summary: `rooms=37`, `floors=37`, `walls=101`, `openings=40`, `frames=40`, `lights=37`, `ceilings=0`, `camera_size=120.36`, `player=false`.

Current blocking issue:
- None for the no-ceiling full-map preview. User visual acceptance remains pending.

Next step:
- Open `open_proc_maze_no_ceiling_preview.bat` to inspect the whole generated map from above. Keep `run_proc_maze_test.bat` for playable testing.

## 2026-05-04 Procedural maze playable player pass

Current objective:
- Let the player run inside `scenes/tests/Test_ProcMazeMap.tscn` without modifying `scenes/mvp/FourRoomMVP.tscn`.

Current progress:
- Added playable setup to `scripts/proc_maze/TestProcMazeMap.gd`.
- The proc-maze test scene now creates/keeps `PlayerRoot/Player`, `CameraRig/Camera3D`, `Systems/LightingController`, and `Systems/ForegroundOcclusion`.
- Player placement uses the generated `Entrance` marker, currently `Marker_N00` at `(3, 0.05, 3)`.
- Gameplay camera uses the existing third-person `CameraController.gd` and points to `../PlayerRoot/Player`.
- The previous overview `Camera3D` remains in the scene for editor inspection but is not the active gameplay camera.
- Updated `scripts/tools/BakeTestProcMazeMap.gd` so external scene instances such as `PlayerModule.tscn` are not expanded into saved test-scene internals.
- Added `scripts/tools/ValidateProcMazePlayable.gd` to verify player, camera, runtime systems, entrance placement, and forward movement through the first connector.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `scripts/proc_maze/TestProcMazeMap.gd`
- `scripts/tools/BakeTestProcMazeMap.gd`
- `scripts/tools/ValidateProcMazePlayable.gd`
- `scenes/tests/Test_ProcMazeMap.tscn`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- Godot parse: `--headless --path . --quit`
- Godot bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeMap.gd`
- Structure validation: `--headless --path . --script res://scripts/tools/ValidateTestProcMazeMap.gd`
- Playable validation: `--headless --path . --script res://scripts/tools/ValidateProcMazePlayable.gd`
- Startup validation: `--headless --path . --scene res://scenes/tests/Test_ProcMazeMap.tscn --quit-after 5`
- Forbidden-pattern scans for visibility masks, room-specific conditionals, visited-room logic, and alpha/blend usage.

Validation result: PASS

Validation evidence:
- `logs/proc_maze_playable_bake_20260504_4.log`
- `logs/proc_maze_playable_validate_structure_20260504_2.log`
- `logs/proc_maze_playable_movement_20260504_2.log`
- `logs/proc_maze_playable_scene_startup_20260504.log`
- Playable movement result: start `(3.0, 0.05, 3.0)`, end `(8.090853, 0.000838, 3.0)`, moved_x `5.091`, camera_current `true`.

Current blocking issue:
- None for player-in-maze runtime. Headless test logs may still show known MCP port conflicts if the editor already owns port `7777`; this did not fail validation.

Next step:
- User visual playtest with `run_proc_maze_test.bat`.
- After fixed playable layout is accepted, implement random topology using the same registry, validators, scene builder, and playable setup.

## Current Objective

Current objective is validating a copied AO + global grime visual experiment. The accepted base scene `scenes/mvp/FourRoomMVP.tscn` must remain unchanged until the user visually accepts the experiment. AO/contact darkening handles seams and volume; the new grime system handles only subtle reusable aging on structural edges.

## Current Progress

- 2026-05-04 grime texture preview: generated a contact sheet for the 9 true-alpha grime PNGs at `artifacts/screenshots/grime_texture_contact_sheet_20260504.png`. The preview shows each texture at original alpha on checkerboard and with alpha boosted 4x over a yellow wall swatch, confirming the current assets are intentionally very soft and the in-scene result can be too subtle.

- 2026-05-03 global reusable grime experiment: added a first-pass grime overlay system on top of the copied contact-AO experiment, not on the accepted base scene.
- Generated 9 true-alpha PNG variants under `materials/textures/grime/`: 3 `CeilingEdge_Grime`, 3 `Baseboard_Dirt`, and 3 `Corner_Grime`. The PNGs have transparent corners/backgrounds and contain only soft pale gray-yellow/brown-yellow/mold-gray stain pixels.
- Added `scripts/visual/GrimeOverlayBuilder.gd` as the reusable placement entry. It reads room area metadata and portal positions generically, uses deterministic per-room seeds, chooses variant/opacity/strength/length/size per room, and places only small non-colliding structural-edge strips.
- Added `scripts/tools/BakeGrimeExperiment.gd`, which loads `FourRoomMVP_contact_ao_experiment.tscn`, adds `LevelRoot/Geometry/GrimeOverlays` plus an `Experiment_Grime` marker, and saves `scenes/mvp/experiments/FourRoomMVP_grime_experiment.tscn`.
- Added `scripts/tools/ValidateGrimeExperiment.gd` to reject missing true-alpha assets, over-opaque assets, large overlay strips, unexpected textures, collision/child nodes under grime overlays, and missing AO experiment ancestry.
- Added `scripts/tools/CaptureGrimeExperimentScreenshot.gd` and captured `artifacts/screenshots/grime_experiment_20260503 232817.png`.
- Validation result: PASS. `CONTACT_AO_EXPERIMENT_VALIDATION PASS wall=21 floor=4 door_frame=4 ceiling=4`; `GRIME_EXPERIMENT_VALIDATION PASS ceiling=8 baseboard=15 corner=10`. Base-scene merge was not performed.

- 2026-05-03 foreground cutout texture preservation fix: diagnosed the user's screenshot as the foreground cutout material replacing a wall material but not preserving the visible texture sampling. Two issues were fixed: `foreground_occlusion_cutout.gdshader` did not mark albedo/normal samplers as `repeat_enable`, so repeated wall UVs could clamp into a flat color; `ForegroundOcclusion.gd` copied material parameters only from `StandardMaterial3D`, so the contact-AO experiment's `ShaderMaterial` walls lost their texture entirely during cutout.
- `materials/foreground_occlusion_cutout.gdshader` now uses repeat-enabled albedo and normal samplers and applies `UV * uv_scale + uv_offset`.
- `scripts/camera/ForegroundOcclusion.gd` now copies `uv_offset` from StandardMaterial3D sources and also supports ShaderMaterial sources that expose `albedo_tint`, `roughness_value`, `normal_depth`, `uv_scale`, `uv_offset`, `use_texture`, `albedo_texture`, `use_normal`, and `normal_texture`.
- `scripts/tools/ValidatePhase3Occlusion.gd` now checks that the local cutout keeps the original wall/door-frame texture and UV scale in the accepted base scene.
- `scripts/tools/ValidateContactAOExperiment.gd` now checks that a contact-AO ShaderMaterial wall still keeps its texture and UV scale after foreground occlusion applies the local cutout.
- Added `scripts/tools/CaptureForegroundCutoutScreenshot.gd` for a visual regression screenshot of the active local cutout. Latest screenshot: `artifacts/screenshots/foreground_cutout_texture_20260503 223354.png`.

- 2026-05-03 contact-AO experiment UV-scale correction: diagnosed the user's floor screenshot issue as the experimental ShaderMaterial not inheriting the original `StandardMaterial3D.uv1_scale`. The accepted base floor still uses `uv1_scale = Vector3(12, 12, 1)`, but the experimental shader sampled raw `UV`, making the tile grid appear enlarged.
- `materials/shaders/contact_ao_surface.gdshader` now exposes `uv_scale` and `uv_offset`, and samples albedo/normal textures with `UV * uv_scale + uv_offset`.
- `scripts/tools/BakeContactAOExperiment.gd` now passes the original material scale into the experiment copy: floor `(12, 12)`, wall `(4.475, 3.77)`, and door frame `(1.2, 2.0)`. It also writes the experimental material into scripted `visual_material` fields so wall openings and door frames keep the experiment material after reload-time rebuilds.
- `scripts/tools/ValidateContactAOExperiment.gd` now rejects the experiment if those UV-scale values are lost.
- Rebuilt and validated only `scenes/mvp/experiments/FourRoomMVP_contact_ao_experiment.tscn`; the accepted base `scenes/mvp/FourRoomMVP.tscn` was not merged with this AO experiment.
- Screenshot evidence after the UV-scale fix: `artifacts/screenshots/contact_ao_experiment_20260503 215907.png`.

- 2026-05-03 door-frame inset + pale floor pass: diagnosed the latest screenshot as two issues. Door frames were generated with `opening_width = 1.15`, making their inner U edge exactly coplanar with the wall opening inner U edge, and `frame_depth = 0.22` was slightly thicker than the `0.20m` wall. The floor grid was fixed, but the generated source albedo was still too brown/yellow for the requested pale tile.
- `scripts/core/SceneBuilder.gd` now generates door frames as inset trim: `DOOR_FRAME_TRIM_WIDTH = 0.10`, `DOOR_FRAME_SIDE_CLEARANCE = 0.06`, and `DOOR_FRAME_DEPTH = 0.16`. Each generated frame's outer width is now `1.09m`, slightly narrower than the `1.15m` wall opening, leaving about `0.03m` clearance per side and avoiding shared U-edge overlap.
- `scripts/tools/ValidateCleanRebuildScene.gd` now validates the inset door-frame rule instead of accepting a frame whose generated U edge matches the wall opening edge.
- `scripts/tools/RegenerateUniformFloorTextures.gd` regenerated the floor albedo/normal as an even 4x4 square tile sheet with a much lighter pale-white base and softer grout. `materials/backrooms_floor.tres` now uses `albedo_color = Color(1.18, 1.18, 1.14, 1)` while keeping `uv1_scale = Vector3(12, 12, 1)` and zero offset.
- Added `scripts/tools/CaptureFourRoomDoorFrameScreenshot.gd` for bounded visual checks of the current door-frame/floor result. Latest screenshot: `artifacts/screenshots/four_room_doorframe_20260503 110724.png`.
- Validation result: PASS. Ran floor texture regeneration, four-room scene bake, `ValidateCleanRebuildScene`, `ValidateMaterialLightingRules`, `ValidateGeneratedMeshRules`, and `ValidateFloorCoverage`; all exited 0. Some logs include the known non-blocking MCP runtime port `7777` conflict while another Godot/MCP process already owns the port.
- Current blocker: none from automated validation. Remaining check is user visual acceptance of the warmer in-scene lighting over the now pale floor source texture.
- 2026-05-03 door-frame outer-ring correction: accepted the user's correction that the previous inset pass shrank the whole door frame and exposed a visible gap at the wall opening edge. Updated the rule so only the inner opening shrinks: wall opening width remains `1.15m`, door-frame outer width also remains `1.15m`, and the visible inner opening is `0.95m` from the `0.10m` trim. Frame depth remains `0.16m`, so it stays inside the wall thickness without front/back coplanar overlap. Rebaked `FourRoomMVP.tscn`; `ValidateCleanRebuildScene`, `ValidateGeneratedMeshRules`, `ValidateMaterialLightingRules`, and `ValidateFloorCoverage` passed. Screenshot evidence: `artifacts/screenshots/four_room_doorframe_20260503 205320.png`.
- 2026-05-03 visual experiment safety rule: recorded the new production rule in root docs and the execution-package docs. Future visual polish, including wall-base/wall-corner/door-frame-edge/ceiling-turn AO or contact-shadow treatment, must first be tested on copied experiment variants. Only accepted screenshots/validated values are merged back into the base scene, generator, or shared materials. This round changed documentation only and did not modify the playable scene.

- 2026-05-03 uniform floor tile fix: confirmed from the source asset that `materials/textures/backrooms_floor_albedo.png` itself contained non-uniform/partial tile columns at the right edge, so repeated floor rendering could not produce even square tiles. The floor material also had non-uniform `uv1_scale = Vector3(12.385, 12.8, 2.477)` plus an X offset, which further shifted seams.
- Added `scripts/tools/RegenerateUniformFloorTextures.gd` to regenerate the floor albedo and normal maps as a full 1024x1024 seamless 4x4 square tile sheet with no partial edge tile.
- Regenerated `materials/textures/backrooms_floor_albedo.png` and `materials/textures/backrooms_floor_normal.png`. Visual inspection of the source texture now shows complete even square tiles.
- Updated `materials/backrooms_floor.tres` to use uniform `uv1_scale = Vector3(12, 12, 1)` and zero UV offset so the material no longer stretches or shifts the square tile grid.
- Updated `ValidateMaterialLightingRules.gd` to fail if floor UV scale is non-square, not equal to the current world-UV rule, or has a non-zero offset.
- Validation passed: `UNIFORM_FLOOR_TEXTURES_PASS` (`logs/uniform_floor_texture_regen_20260503_*.log`) and `MATERIAL_LIGHTING_RULES_VALIDATION PASS` (`logs/uniform_floor_material_validate_20260503_*.log`). The only stderr during validation was the known non-blocking MCP runtime port 7777 conflict from an already-open Godot instance.

- 2026-05-03 base resource gallery material/generation unification fix: diagnosed the user's red-circle screenshot as a mixed generation path, not a global UV flip. Ordinary wall boxes were direct generated meshes using the UV debug material, while `WallOpeningBody.gd` and `DoorFrameVisual.gd` were tool/runtime scripted components that rebuilt themselves and forced their own production materials after the gallery scene was opened/reloaded.
- `WallOpeningBody.gd` now has exported `visual_material`; its mesh generation and material override both use that injected material when present, otherwise falling back to `backrooms_wall.tres`.
- `DoorFrameVisual.gd` now has exported `visual_material`; its rebuild path uses that injected material when present, otherwise falling back to `backrooms_door_frame.tres`.
- `BakeBaseResourceGallery.gd` now passes the debug/production material into the scripted components before they enter the tree, so reload-time rebuilds preserve the intended row material.
- `GeneratedMeshRules.gd` now owns `append_oriented_triangle()`, and `WallOpeningBody.gd` / `DoorFrameVisual.gd` use that shared triangle append path. This keeps outward normals, UVs, and Godot clockwise front-face winding from being solved separately by each component.
- `ValidateBaseResourceGallery.gd` now checks more than node existence: debug-row components must actually use `uv_direction_debug.tres`, triangle winding must match Godot front-face culling expectations, and vertical UVs must increase toward outside-viewer-right (`U+`) and up (`V+`).
- Rebuilt and validated gallery: `BASE_RESOURCE_GALLERY_BAKE PASS` (`logs/base_resource_gallery_material_unified_bake_20260503_101437.log`) and `BASE_RESOURCE_GALLERY_VALIDATION PASS` (`logs/base_resource_gallery_material_unified_validate_20260503_101445.log`).
- Added `scripts/tools/CaptureBaseResourceGalleryScreenshot.gd` and captured debug-only visual evidence: `artifacts/screenshots/base_resource_gallery_20260503 101928.png`. The screenshot shows `Opening Z`, `Opening X`, `Frame Z`, and `Frame X` using the UV debug arrows instead of reverting to production materials.

- 2026-05-03 base resource gallery: paused four-room visual patching and created an isolated UV inspection scene at `scenes/debug/BaseResourceGallery.tscn`.
- Added `materials/debug/uv_direction_debug.gdshader` and `materials/debug/uv_direction_debug.tres`. The debug material draws red U+ arrows and green V+ arrows so mirrored UVs are visible without relying on the Backrooms texture.
- Added `scripts/tools/BakeBaseResourceGallery.gd`, which creates two rows of basic construction pieces: a debug UV row and a Backrooms material reference row.
- Gallery pieces include `+Z/-Z/+X/-X` wall faces, a wall-joint box, z-axis and x-axis portal opening bodies, z-axis and x-axis door frames, floor panel, and ceiling panel.
- Added `scripts/tools/ValidateBaseResourceGallery.gd` and validated the gallery nodes/meshes: `BASE_RESOURCE_GALLERY_VALIDATION PASS`.
- Added `open_base_resource_gallery.bat` and `run_base_resource_gallery.bat` for direct inspection.
- Accepted the user's correction that the generated UV rule was still reversed. Root cause: vertical generated faces used local-axis UVs and `Vector3.DOWN.cross(normal)` tangent basis, which reverses U relative to the visible face.
- `GeneratedMeshRules.gd` now maps vertical box faces so, when viewed from the face's outside, U+ is viewer-right and V+ is up. Vertical tangent basis now uses `Vector3.UP.cross(normal)`.
- `WallOpeningBody.gd` and `DoorFrameVisual.gd` now compute vertical face UVs from face normal using the same outside-viewer-right rule.
- Rebaked `scenes/debug/BaseResourceGallery.tscn` after the UV correction: `BASE_RESOURCE_GALLERY_BAKE PASS` (`logs/base_resource_gallery_uv_right_bake_20260503_084805.log`).
- Short startup of the isolated gallery passed with Forward Mobile renderer: `logs/base_resource_gallery_uv_right_startup_20260503_085033.log`.
- Note: `ValidateGeneratedMeshRules.gd` currently fails on the baked four-room scene because `FourRoomMVP.tscn` still contains old saved mesh arrays with the previous tangent basis. This is expected until the four-room scene is explicitly rebaked after the base-resource UV rule is accepted.

- 2026-05-03 wall z-fighting visual cleanup: diagnosed the latest screenshot artifacts as likely coplanar/overlapping render faces rather than a pure UV inversion.
- `SceneBuilder.gd` now uses wall spans of `ROOM_SIZE - WALL_JOINT_SIZE` (`5.64m`) so ordinary wall and portal-opening bodies meet wall-joint blocks at their edges instead of penetrating them.
- `GeneratedMeshRules.build_box_mesh()` now supports omitting horizontal cap faces. Solid walls and wall-joint visual meshes use side faces only, preventing their rendered bottoms/tops from fighting the floor and ceiling surfaces while collision boxes remain unchanged.
- `WallOpeningBody.gd` skips rendered profile cap edges at floor/ceiling contact, and `DoorFrameVisual.gd` skips rendered floor cap edges at the frame feet.
- `WallOpeningBody.gd` default `span_length` now matches the canonical `5.64m` span for newly created portal wall bodies.
- Rebaked `scenes/mvp/FourRoomMVP.tscn` with the overlap/cap cleanup.
- Validation passed: `BAKE_FOUR_ROOM_SCENE PASS` (`logs/wall_overlap_caps_bake_20260503_080954.log`), `GENERATED_MESH_RULES_VALIDATION PASS`, `CLEAN_REBUILD_SCENE_VALIDATION PASS`, `MATERIAL_LIGHTING_RULES_VALIDATION PASS`, `SCENE_SHADOW_VALIDATION PASS`, `FLOOR_COVERAGE_VALIDATION PASS`, and `PHASE3_OCCLUSION_VALIDATION PASS`.
- Post-default validation also passed: `ValidateGeneratedMeshRules` and `ValidateCleanRebuildScene` (`logs/wall_overlap_caps_postdefault_*_20260503_081723.log`).
- Short normal startup passed with Forward Mobile renderer: `logs/wall_overlap_caps_startup_20260503_081859.log`.
- Godot MCP editor bridge check was attempted after the fix; the bridge is currently not connected because port `127.0.0.1:6505` is already in use by another GoPeak/MCP process.
- 2026-05-03 follow-up wall edge/side UV cleanup: accepted the user's screenshot correction that the remaining issue was visible black seams plus stretched/striped doorway side faces.
- `SceneBuilder.gd` now extends wall/joint visual side faces by `0.025m` above and below the collision wall height, hiding floor/ceiling edge cracks without adding coplanar horizontal faces.
- `WallOpeningBody.gd` now extends the portal wall visual profile by `0.025m` at floor/ceiling contact and builds explicit per-face UVs so side/reveal faces use depth/height or span/depth UVs instead of degenerate front-face UVs.
- `DoorFrameVisual.gd` now extends frame feet by `0.02m` below the floor and builds explicit per-face UVs so narrow frame side faces no longer collapse to a one-pixel vertical texture stripe.
- Rebaked `scenes/mvp/FourRoomMVP.tscn` with the edge/side-UV cleanup.
- Validation passed: `BAKE_FOUR_ROOM_SCENE PASS` (`logs/wall_edge_uv_bake_20260503_082722.log`), `GENERATED_MESH_RULES_VALIDATION PASS`, `CLEAN_REBUILD_SCENE_VALIDATION PASS`, `MATERIAL_LIGHTING_RULES_VALIDATION PASS`, `SCENE_SHADOW_VALIDATION PASS`, `FLOOR_COVERAGE_VALIDATION PASS`, and `PHASE3_OCCLUSION_VALIDATION PASS`.
- Short normal startup passed: `logs/wall_edge_uv_startup_20260503_082853.log`. The only runtime error was the known non-blocking MCP runtime port `7777` conflict while another instance is already using it.

- 2026-05-03 upright wall UV fix: accepted the user's follow-up that all walls felt UV-reversed after unifying geometry rules.
- `GeneratedMeshRules.gd` now maps generated box visual UV `v` in the positive selected axis direction instead of negating the vertical/side axis.
- `WallOpeningBody.gd` now maps doorway wall V from positive local `y`.
- `DoorFrameVisual.gd` now maps door-frame V from positive local `y`.
- `ValidateGeneratedMeshRules.gd` now rejects vertical generated triangles whose UV `v` does not increase with local height.
- Rebaked `scenes/mvp/FourRoomMVP.tscn` with upright vertical UVs.
- Validation passed: `BAKE_FOUR_ROOM_SCENE PASS` (`logs/wall_uv_upright_bake_20260503_004457.log`), `GENERATED_MESH_RULES_VALIDATION PASS`, `CLEAN_REBUILD_SCENE_VALIDATION PASS`, `MATERIAL_LIGHTING_RULES_VALIDATION PASS`, `SCENE_SHADOW_VALIDATION PASS`, `FLOOR_COVERAGE_VALIDATION PASS`, and `PHASE3_OCCLUSION_VALIDATION PASS`.
- `DiagnoseWallVisuals.gd` still reports shared generated mesh/material/tangent rules for walls, wall joints, and wall openings after the UV flip.
- Residue scan found no active script references to the old negative vertical wall UV expressions.
- Updated root docs and mirrored execution-package docs with the upright vertical UV rule.

- 2026-05-03 canonical scene object generation standard: accepted the user's production rule that scene objects must be generated by type, not by room name, direction, or one-off editor fixes.
- `DoorFrameVisual.gd` now builds one canonical local U-frame mesh. Z-axis doors are handled by node rotation, x-axis doors remain unrotated, and all door-frame nodes keep `scale = Vector3.ONE`.
- `WallOpeningBody.gd` now builds one canonical local U-wall mesh and one canonical local collision layout for doorway walls. Z-axis openings are handled by rotating the body; x-axis openings remain unrotated.
- `SceneBuilder.gd` no longer applies direction-specific non-uniform door-frame scale. Door-frame trim width is `0.15`, frame depth is `WALL_THICKNESS + 0.02`, and all four generated frames share these parameters.
- `ValidateCleanRebuildScene.gd` now validates the canonical standard for portal openings and frames: uniform portal center/width, expected span axis, identity scale, canonical yaw, and local mesh dimensions.
- Rebaked `scenes/mvp/FourRoomMVP.tscn` with the new canonical doorway rules. Saved scene evidence shows z-axis `WallOpening_P_AB`/`DoorFrame_P_AB` rotated by -90 degrees and x-axis `WallOpening_P_BC`/`DoorFrame_P_BC` unrotated, while local mesh AABBs remain canonical.
- Validation passed: `BAKE_FOUR_ROOM_SCENE PASS` (`logs/canonical_type_bake_20260503_002034.log`), `CLEAN_REBUILD_SCENE_VALIDATION PASS` (`logs/canonical_type_clean_validation_20260503_002236.log`), `GENERATED_MESH_RULES_VALIDATION PASS`, `MATERIAL_LIGHTING_RULES_VALIDATION PASS`, `SCENE_SHADOW_VALIDATION PASS`, `FLOOR_COVERAGE_VALIDATION PASS`, `PHASE3_OCCLUSION_VALIDATION PASS`, `LIGHT_FLICKER_VALIDATION PASS`, `SEAM_GRIME_REMOVAL_VALIDATION PASS`, `MONSTER_SAVED_SCALE_VALIDATION PASS`, `MONSTER_AI_VALIDATION PASS`, and `CAMERA_FREE_ORBIT_VALIDATION PASS`.
- MCP scene-node inspection was attempted, but the current Godot editor instance was not connected to the MCP editor plugin. Verification continued through saved scene inspection and Godot validation scripts.
- Updated `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/MECHANICS_ARCHIVE.md`, and the mirrored execution-package docs with the canonical generation standard.

- 2026-05-02 full clean four-room rebuild: accepted the user's correction that the old room container and previous generated room pieces needed to be removed, not merely refactored in place.
- Backed up the pre-clean-rebuild scene to `scenes/mvp/backups/FourRoomMVP.before_full_clean_rebuild_20260502_144848.tscn`.
- `SceneBuilder.gd` now deletes any legacy `LevelRoot/Rooms` node during build and recreates the current demo through separate roots: `LevelRoot/Geometry` for physical/visual floor, walls, ceilings, door frames, and lamp panels; `LevelRoot/Areas` for the four room metadata nodes only.
- `MonsterController.gd` now reads room area metadata from `LevelRoot/Areas` while portals remain under `LevelRoot/Portals`.
- `BakeFourRoomScene.gd` now saves generated `Geometry`, `Areas`, `Portals`, `Markers`, and `Lights` roots. The baked `scenes/mvp/FourRoomMVP.tscn` no longer contains `LevelRoot/Rooms` or any `parent="LevelRoot/Rooms"` nodes.
- Added `ValidateCleanRebuildScene.gd` to reject any return of legacy `LevelRoot/Rooms` and validate that geometry and area metadata are separated.
- Updated existing geometry, material, shadow, floor, and occlusion validators to use `LevelRoot/Geometry` / `LevelRoot/Areas`.
- Validation passed: Godot 4.6.2 parse, `BAKE_FOUR_ROOM_SCENE PASS`, `CLEAN_REBUILD_SCENE_VALIDATION PASS`, generated mesh rules, material lighting rules, scene shadows, floor coverage, Phase 3 occlusion, light flicker, seam-grime removal, monster saved scale, monster AI, active residue scan, and MCP scene-tree inspection. Short startup reached the running scene and was stopped by timeout without a crash.

- 2026-05-02 type-based wall generation cleanup: accepted the user's correction that rooms should only拼接空间, not own different wall rendering rules.
- `SceneBuilder.gd` now uses one `_get_wall_piece_specs()` list and one `_create_wall_piece()` entry for wall bodies. `type = "solid"` creates a solid wall/joint body; `type = "opening"` creates a wall body with a doorway opening.
- Removed the separate wall-opening spec loop from the builder path. Door frames remain a separate trim type, but they now consume the same static visual layer rule as walls instead of deriving visual layers from room area.
- Introduced `STATIC_GEOMETRY_LAYER` as the single layer for room static geometry. Floors, ceilings, solid walls, wall openings, door frames, and light panels all use that layer. Ceiling lights now use the same `STATIC_GEOMETRY_LAYER | ACTOR_LIGHT_LAYER` mask, regardless of Room_A/B/C/D.
- Updated `ValidateSceneShadows.gd` to validate the type-level static layer rule instead of room-specific light masks.
- Backed up the active scene before refactor to `scenes/mvp/backups/FourRoomMVP.before_type_wall_refactor_20260502_142609.tscn`.
- Rebaked `scenes/mvp/FourRoomMVP.tscn` after the refactor. The saved scene now has all four `CeilingLight_Room_*` `light_cull_mask` and `shadow_caster_mask` values at `257`, i.e. one static geometry layer plus actor layer.
- Validation passed: Godot parse, scene bake, scene shadows/static layer rule, generated mesh rules, material lighting rules, floor coverage, Phase 3 occlusion, light flicker, seam-grime removal, monster saved scale, forbidden-pattern scan, and short normal startup.

- 2026-05-02 UV/tangent direction fix: treated the user's "UV direction reversed" observation as a generated mesh tangent-basis problem.
- Fixed `SceneBuilder.gd` floor visual triangle order so the per-room floor ArrayMesh top side renders correctly under the current backface-culling material rule.
- Updated `GeneratedMeshRules.gd` so vertical generated wall/door/ceiling side faces use one shared tangent basis (`Vector3.DOWN.cross(normal)`, positive tangent sign) instead of deriving mixed x/z wall signs from UV winding. This keeps the normal map response consistent across `+x`, `-x`, `+z`, and `-z` wall faces.
- Tightened `ValidateGeneratedMeshRules.gd` so generated vertical surfaces fail validation if they regress to mixed tangent signs.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`. `DiagnoseWallVisuals.gd` now reports vertical wall/opening tangents with a unified `+` sign instead of the previous mixed `+z-`, `-z+`, and `-x-` patterns.
- Validation passed: Godot parse, scene bake, generated mesh rules, material lighting rules, scene shadows, floor coverage, Phase 3 occlusion, light flicker, seam-grime removal, short startup, and a desktop visual screenshot. The visual screenshot `artifacts/screenshots/wall_tangent_visual_20260502_134323.png` shows the floor rendered with readable tile material instead of black.

- 2026-05-02 light-layer visual consistency fix: diagnosed the latest screenshot mismatch by comparing the user-selected `WallOpening_P_AB` / `WallOpening_P_CD` meshes against other portal walls, ordinary walls, joints, floors, and ceiling lights.
- MCP and `DiagnoseWallVisuals.gd` confirmed the saved wall meshes already use the same wall material resource and generated `ArrayMesh` rule; the remaining difference was lighting/render-state behavior, not a missing texture assignment.
- Found the main scene-wide issue: every static visual and every room light was still on the default render layer, so all four ceiling lights could affect the same walls and floors. This filled in shadows unevenly and made some walls read like they were generated under a different rule.
- `SceneBuilder.gd` now assigns explicit render layers for Room_A/B/C/D static geometry and portal/shared wall visuals. Room lights now use matching `light_cull_mask` and `shadow_caster_mask` values plus the actor layer, so each room light lights its room surfaces and actor shadows without flooding every other room surface.
- `WallOpeningBody.gd` now exposes and applies `visual_layers`, so baked and runtime portal wall meshes keep the same light-layer masks.
- Player and monster imported mesh instances now use the actor light layer while still casting real shadows.
- Wall, floor, door-frame, ceiling, and foreground cutout materials now use backface culling instead of two-sided rendering, reducing backside lighting artifacts in Mobile/editor preview.
- Reduced the generated warm ambient fill from `0.26` to `0.18` so real ceiling-light shadows remain visible after layer isolation.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; MCP confirmed example layers/masks: `WallOpening_P_AB/Mesh.layers=3`, `WallOpening_P_BC/Mesh.layers=6`, `Floor_Room_C.layers=4`, `CeilingLight_Room_A.light_cull_mask=257`, and `CeilingLight_Room_C.light_cull_mask=260`.
- Validation passed: Godot parse, `BAKE_FOUR_ROOM_SCENE PASS`, scene shadows/light-layer masks, material lighting/culling rules, generated mesh rules, floor coverage, Phase 3 occlusion, light flicker, seam-grime removal, monster AI, short startup, and wall visual diagnostics. The only repeated stderr line is the known non-blocking MCP runtime port 7777 conflict while the editor already owns the port.

- 2026-05-02 runtime visual lighting unification fix: reconnected Godot MCP after the Codex restart and inspected the selected wall/floor nodes through MCP.
- MCP confirmed `WallOpening_P_AB/Mesh`, `WallOpening_P_DA/Mesh`, and `WallJoint_DA_WestOuter/Mesh` all point to `res://materials/backrooms_wall.tres`; `Floor_Room_D` points to `res://materials/backrooms_floor.tres`.
- Diagnosed the remaining screenshot mismatch as a runtime visual-lighting response issue: the foreground-occlusion cutout shader still used ordinary Lambert lighting while the standard wall material used Lambert Wrap, and the scene had no consistent low ambient baseline.
- Changed `materials/foreground_occlusion_cutout.gdshader` to `diffuse_lambert_wrap` so cutout walls keep the same light response as regular walls.
- Added a generated `WorldEnvironment` under `LevelRoot/Lights` in `SceneBuilder.gd`, with warm low ambient fill `Color(1.0, 0.9, 0.66)` at energy `0.26` and zero sky contribution.
- Reduced normal-map strength for Mobile readability: wall `0.22`, floor `0.28`, door frame `0.24`; added a small floor albedo multiplier so the tile texture no longer reads like a dark overlay.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; MCP confirmed `LevelRoot/Lights/WorldEnvironment` exists in the saved scene.
- Updated validators so material normal strength, floor brightness, and WorldEnvironment presence/tuning are enforced in baked and runtime scenes.
- Validation passed: Godot parse, `BAKE_FOUR_ROOM_SCENE PASS`, material-lighting rules, scene shadows, generated mesh rules, floor coverage, Phase 3 occlusion, light flicker, seam-grime removal, short startup, MCP debug run/stop, and active forbidden-pattern scan. Active scan only found the approved `foreground_occlusion_cutout.gdshader` `ALPHA` use.
- Updated `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/MECHANICS_ARCHIVE.md`, and mirror docs under `四房间MVP_Agent抗遗忘执行包/docs/`.

- 2026-05-02 unified wall mesh generation fix: diagnosed the remaining mismatched wall look as a mixed render-data problem, not a reason to brighten one wall by hand.
- Added `GeneratedMeshRules.build_box_mesh()` so ordinary wall boxes, `WallJoint_*` filler blocks, and ceilings are generated with explicit vertex, normal, UV, and tangent arrays.
- `SceneBuilder.gd` now uses that shared generated mesh path for `_create_box()` visuals while keeping separate primitive `BoxShape3D` collision for mobile stability.
- `WallOpeningBody.gd` now uses the same wall world-size UV rule as ordinary walls instead of per-opening normalized UVs.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; `Wall_South_A/Mesh`, `WallJoint_Center/Mesh`, ceilings, portal wall openings, door frames, and floors now validate as generated `ArrayMesh` render data with explicit material overrides. The only intentional `BoxMesh` resources left are the four ceiling-light panels.
- Tightened real ceiling-light shadow parameters for floor readability: `shadow_bias = 0.02`, `shadow_normal_bias = 0.35`, and `shadow_opacity = 1.0`.
- Expanded `ValidateGeneratedMeshRules.gd` so it now rejects ordinary wall/joint or ceiling visuals that fall back to `BoxMesh` under the Backrooms material set.
- Validation passed: Godot parse, `BAKE_FOUR_ROOM_SCENE PASS`, `GENERATED_MESH_RULES_VALIDATION PASS`, `MATERIAL_LIGHTING_RULES_VALIDATION PASS`, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`, `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`, Phase 3 occlusion, light flicker, seam-grime removal, forbidden-pattern scan, and short normal startup. The only recurring runtime message was the known non-blocking MCP port 7777 conflict when the editor already owns it.
- Updated `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/MECHANICS_ARCHIVE.md`, and mirror docs under `四房间MVP_Agent抗遗忘执行包/docs/`.

- 2026-05-02 unified material lighting/shadow readability fix: diagnosed the latest dark inner-wall and flat floor complaint as a scene-wide material/light response issue, not a reason to hand-tune individual wall meshes.
- `backrooms_wall.tres`, `backrooms_floor.tres`, `backrooms_door_frame.tres`, and `backrooms_ceiling.tres` now use Lambert Wrap diffuse lighting for Mobile.
- Reduced normal-map strength to keep texture detail without harsh black faces: wall `0.32`, floor `0.42`, door frame `0.32`.
- Raised room `OmniLight3D.light_energy` to `1.05` and saved `shadow_bias = 0.035`, `shadow_normal_bias = 0.8`, and `shadow_opacity = 0.9` on all four room lights.
- Hardened `SceneBuilder.gd` so tool/runtime rebuilds resolve the builder's owning scene root instead of relying on `get_tree().current_scene`.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; the stale offset on `Floor_Room_A` is gone and all four ceiling lights save the new real light/shadow settings.
- Added `scripts/tools/ValidateMaterialLightingRules.gd` to validate baked and runtime material assignments plus the shared diffuse/normal-strength rules.
- Godot parse, material-lighting validation, scene shadows, flicker, generated mesh rules, floor coverage, foreground occlusion, forbidden-pattern scan, and short normal startup passed.
- Updated `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/MECHANICS_ARCHIVE.md`, and mirror docs under `四房间MVP_Agent抗遗忘执行包/docs/`.

- 2026-05-02 ceiling light coverage fix: diagnosed incomplete light projection as `OmniLight3D.omni_range = 4.2` being too small for a 6m room with a ceiling-centered light.
- Added `CEILING_LIGHT_RANGE = 6.0` and `CEILING_LIGHT_ATTENUATION = 0.78` to `SceneBuilder.gd`.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; all four `CeilingLight_Room_*` nodes now save `omni_range = 6.0`, `omni_attenuation = 0.78`, `light_energy = 0.82`, and `shadow_enabled = true`.
- Updated `ValidateSceneShadows.gd` to fail if baked or runtime ceiling lights have insufficient range or overly steep falloff.
- Godot parse, bake, shadow/coverage validation, flicker validation, floor coverage, foreground occlusion, generated mesh rules, and short startup validations passed.
- Updated `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/MECHANICS_ARCHIVE.md`, and mirror docs under `四房间MVP_Agent抗遗忘执行包/docs/`.

- 2026-05-02 generated mesh render-rule fix: diagnosed the recurring dark/black selected wall as a generated `ArrayMesh` rule mismatch, not a separate wall material choice.
- Added `scripts/scene/GeneratedMeshRules.gd` so script-generated visual meshes build vertex, normal, UV, and tangent arrays through one shared path.
- Updated `WallOpeningBody.gd`, `DoorFrameVisual.gd`, and regular floor visual generation in `SceneBuilder.gd` to use the shared generated mesh rule.
- Generated wall openings, door frames, and floor visual panels now set `material_override` to their expected material instead of relying only on `ArrayMesh.surface_set_material()`.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; `WallOpening_P_DA/Mesh` and the other generated portal walls now save `material_override = backrooms_wall.tres`.
- Added `scripts/tools/ValidateGeneratedMeshRules.gd`, validating baked and runtime generated wall openings, door frames, and floors all have the expected material override plus matching vertex/normal/UV/tangent arrays.
- Godot parse, generated mesh render-rule validation, floor coverage, Phase 3 foreground occlusion, scene shadows, and short startup validations passed after the fix.
- Added `D038` to `docs/DECISIONS.md`: generated visual meshes using normal-mapped materials must include tangents and material overrides.
- Updated `docs/PROGRESS.md`, `docs/MECHANICS_ARCHIVE.md`, and mirror docs under `四房间MVP_Agent抗遗忘执行包/docs/`.

- 2026-05-02 seam/contact detail rollback: removed the global `WallSeamGrime`, `CeilingSeamGrime`, `DoorSeamGrime`, and `DoorFrameSeamGrime` generation from `SceneBuilder.gd`.
- Removed the generated seam grime material and texture assets: `materials/backrooms_seam_grime.tres`, `materials/textures/backrooms_seam_grime_albedo.png`, and `materials/textures/backrooms_seam_grime_albedo.png.import`.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; the active baked scene no longer references `backrooms_seam_grime` and contains no `seam_grime` nodes.
- `scripts/tools/ValidateSeamGrime.gd` now validates the removal state and reports `SEAM_GRIME_REMOVAL_VALIDATION PASS`.
- Floor coverage, foreground occlusion, and short startup regressions still pass after the rollback.

- 2026-05-02 regular floor visual update: replaced the old `Floor_SouthStrip` / `Floor_NorthStrip` visual pair with one regular visual floor panel per room.
- New floor visuals are `Floor_Room_A`, `Floor_Room_B`, `Floor_Room_C`, and `Floor_Room_D`, all in the `floor_visual` group.
- Floor visuals are `MeshInstance3D` only, own no collision, cast no shadows, and use world-coordinate UVs so square floor texture scale aligns consistently across room boundaries.
- `Floor_WalkableCollision` remains the single continuous physics floor for stable player/monster movement.
- `ValidateFloorCoverage.gd` now rejects the old floor strip visuals and validates the four regular per-room panels.
- Final residue check passed: `scripts/core/SceneBuilder.gd` and `scenes/mvp/FourRoomMVP.tscn` no longer contain `Floor_SouthStrip` or `Floor_NorthStrip`; those names remain only inside the floor validator as old-node rejection cases.

- 2026-05-02 third-person free-orbit camera update: `CameraController.gd` no longer clamps yaw to +/-90 degrees and no longer recenters when movement starts.
- Mouse and touch drag now rotate freely around the player through 360 degrees. Pitch is still clamped by `min_pitch_degrees` and `max_pitch_degrees`.
- Existing common controls remain: click captures mouse, `Esc` releases mouse, `WASD` / arrow keys move relative to the camera, `Shift` sprints, and `S` / down arrow stays backpedal rather than turn.
- `scripts/tools/ValidateCameraRecenter.gd` now validates free-orbit behavior under its legacy filename and reports `CAMERA_FREE_ORBIT_VALIDATION`.

- The earlier 2026-05-02 seam grime/contact-detail pass has been superseded by the rollback above. Do not treat old grime placement notes as current behavior.
- Updated `docs/PROGRESS.md`, `docs/MECHANICS_ARCHIVE.md`, and mirror docs under `四房间MVP_Agent抗遗忘执行包/docs/`.

- 2026-05-02 foreground occlusion edge smoothing: `ForegroundOcclusion.gd` now samples multiple camera-aligned target probes around the player instead of only the center Camera -> Player line.
- Occlusion probing is now bidirectional, reducing misses when the camera is very close to or just past a wall plane.
- Added `cutout_release_delay = 0.16` so foreground cutout materials remain active for a short moment after the line becomes clear, avoiding one-frame wall flashes during camera/wall boundary crossings.
- `ValidatePhase3Occlusion.gd` now validates that wall openings, door frames, and foreground walls keep their local cutout on the immediate clear frame and restore only after the release delay.
- Added `D034` to `docs/DECISIONS.md`: foreground occlusion uses probe hysteresis and remains a local cutout system, not whole-wall fade panels or disabled collision.
- Updated `docs/PROGRESS.md`, `docs/MECHANICS_ARCHIVE.md`, and mirror docs under `四房间MVP_Agent抗遗忘执行包/docs/`.

- 2026-05-01 mechanism archive update: added `docs/MECHANICS_ARCHIVE.md` and mirrored it under `四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md`.
- The archive records the current four-room scene as a reusable verification sandbox for scene layout, floor collision, wall/door-frame geometry, materials, ceiling lights, flicker, shadows, camera/control behavior, player animation, foreground occlusion, and monster MVP behavior.
- Added `D033` to `docs/DECISIONS.md`: accepted mechanics in `FourRoomMVP.tscn` should be archived before reuse in larger maps.
- `docs/PROGRESS.md` now has a Four-Room Mechanism Archive entry and the mirror docs were updated.
- 2026-05-01 monster locomotion animation direction tuning: `MonsterController.gd` now compares actual horizontal velocity against body forward direction while Walk/Run plays.
- If the monster is moving backward relative to its facing direction, Walk/Run playback speed becomes negative so legs reverse instead of forward-running while sliding backward.
- Flee turn speed is now `18.0`, so the preferred behavior is still turning toward the escape direction quickly; reverse playback covers brief backing-up moments during panic starts, route changes, or obstacle avoidance.
- Added debug validation hooks for animation speed scale and locomotion forward dot.
- `ValidateMonsterAI.gd` now validates that forward local movement plays locomotion forward and backward local movement plays locomotion in reverse.
- 2026-05-01 floor seam fix: `SceneBuilder.gd` now creates one continuous `Floor_WalkableCollision` body and keeps `Floor_SouthStrip` / `Floor_NorthStrip` as visual floor meshes without their own collision shapes.
- This was superseded by the 2026-05-02 regular floor visual update: the baked scene still has the same `Floor_WalkableCollision` setup, but the old floor-strip visuals are now removed as well.
- The baked south floor mesh local transform was reset to identity to remove the small saved visual offset from its parent.
- Added `scripts/tools/ValidateFloorCoverage.gd`, which samples all room interiors plus the z=3 seam and validates the monster near the Room_D edge does not drop through.
- 2026-05-01 monster panic/fall tuning: `MonsterController.gd` now has near-player panic detection outside the forward cone, wider/longer vision, stronger flee speed/acceleration/start boost, longer flee memory, faster Run animation playback, floor snap, and last-safe-floor recovery.
- `MonsterModule.tscn` movement collision was narrowed from `0.86 x 0.68 x 2.28` to `0.62 x 0.62 x 1.30`, safe margin is now `0.07`, and the collision center moved forward to reduce wall/door snagging while preserving the saved monster instance scale.
- `ValidateMonsterAI.gd` now validates close-behind panic detection and immediate FLEE start speed.
- 2026-05-01 brighter light tuning: baked `FourRoomMVP.tscn` ceiling `OmniLight3D.light_energy` values are now `0.82` instead of `0.65`.
- Runtime `SceneBuilder.gd` creates the same brighter ceiling lights, so editor-opened and rebuilt scenes match.
- `materials/backrooms_ceiling_light.tres` panel emission is now `1.10` instead of `0.85`.
- `LightingController.gd` bright flicker spikes now use `bright_energy_min/max = 1.25/1.85`, and panel emission can spike up to the same multiplier.
- `ValidateLightFlicker.gd` now validates the brighter base light, brighter base panel emission, and a real bright spike after the dim step.
- 2026-05-01 monster saved-scale fix: `GameBootstrap.gd` now places `MonsterRoot/Monster` at `Spawn_Monster_D` by changing only `global_position`, preserving the editor-saved rotation/scale.
- Current saved monster instance scale in `FourRoomMVP.tscn` is `(0.953989, 0.387199, 0.688722)`, and `ValidateMonsterSavedScale.gd` confirms runtime keeps the same scale.
- 2026-05-01 random light flicker retune: `LightingController.gd` no longer uses per-light fixed countdowns. It now waits a long randomized startup delay, then uses a low per-second probability after a random cooldown.
- Default light flicker tuning is now `startup_delay_min/max = 18/45`, `flicker_interval_min/max = 28/70`, and `flicker_chance_per_second = 0.018`.
- 2026-05-01 ceiling-light flicker update: `LightingController.gd` now manages all `ceiling_light` nodes and occasionally triggers short dim/bright flicker bursts.
- Flicker changes real `OmniLight3D.light_energy` and the matching `CeilingLightPanel_*` runtime material emission energy, then restores both to their base values.
- Lamp panel meshes remain visible; the mechanism does not bind real Light3D enabled state to lamp mesh visibility.
- Added `scripts/tools/ValidateLightFlicker.gd`.
- 2026-05-01 camera recenter update: manual mouse/touch yaw offset no longer auto-recenters while the player is stationary. This behavior has since been superseded by the 2026-05-02 free-orbit camera update.
- 2026-05-01 monster flee routing update: `MonsterController.gd` no longer flees only by moving directly away from the player.
- While fleeing, the monster now detects its current room area from `LevelRoot/Rooms`, scores connected `LevelRoot/Portals`, moves toward the selected portal, and then targets a point just inside the connected room.
- Flee route scoring prefers portal exits farther from the player, avoids the player's current area when possible, and gives a bonus to routes that are not blocked by a simple escape-line raycast.
- If the monster hits a wall or moves too little for `flee_stuck_repath_time`, it repaths instead of continuing to push into the same obstruction.
- `ValidateMonsterAI.gd` now includes a Room_D regression case that would previously send the monster into the north wall; validation requires progress toward P_CD or P_DA.
- 2026-05-01 scene-light shadows: enabled real `OmniLight3D` shadows on all four ceiling lights in both the baked scene and runtime `SceneBuilder.gd`.
- Ceiling light panel meshes now have shadow casting disabled so the visible lamp panels do not block their own real light source.
- `PlayerController.gd` now recursively sets imported player model `MeshInstance3D` nodes to cast shadows.
- `MonsterController.gd` now recursively sets imported monster model `MeshInstance3D` nodes to cast shadows.
- Added `scripts/tools/ValidateSceneShadows.gd` to validate baked and runtime scene shadow setup.

- 2026-05-01 monster MVP: inspected `res://3D模型/guai1.glb`; it exposes one `AnimationPlayer`, one skeleton with 58 bones, and 9 animations: Attack, Idle, Run, Walk, climb, grabA, grabB, grabC, and start_climb.
- Added `scenes/modules/MonsterModule.tscn`, instancing `guai1.glb` as a low crawler-scale `CharacterBody3D` with a simple mobile-friendly box collision.
- Added `scripts/monster/MonsterController.gd`.
- Monster states are isolated to the monster module: `WANDER`, `IDLE_LOOK`, and `FLEE`.
- Monster forward vision uses a horizontal FOV cone plus a physics raycast line-of-sight check against the player.
- If the monster sees the player it runs away using the Run animation; after sight is lost it keeps fleeing briefly through `flee_memory_time=1.5` so turning away does not immediately cancel the flee.
- If it does not see the player it wanders, occasionally stops, plays Idle, and rotates left/right as a simple look-around behavior.
- Monster `Idle`, `Walk`, and `Run` animations are looped and POSITION tracks are disabled to prevent root-motion drift from moving the visual mesh away from the `CharacterBody3D`.
- `GameBootstrap.gd` now places `MonsterRoot/Monster` at `LevelRoot/Markers/Spawn_Monster_D` after runtime scene building.
- `FourRoomMVP.tscn` now instances `MonsterModule.tscn` under `MonsterRoot`.
- Added `scripts/tools/ValidateMonsterAI.gd`.
- First monster AI validation caught a real behavior issue: the monster stopped fleeing as soon as it turned away and the player left its forward FOV. Fixed by adding short flee memory.

- 2026-05-01 player animation hookup: inspected `res://3D模型/zhujiao.glb` through `ModelRoot/zhujiao/AnimationPlayer`.
- The current GLB exposes one skeletal animation: `mixamo_com`, length about 2.042 seconds, no separate idle/walk/run/backpedal clips.
- `PlayerController.gd` now connects to `ModelRoot/zhujiao/AnimationPlayer`, loops the available locomotion clip, and maps it to movement states.
- Current mapping: walk uses `mixamo_com` at 1.0x, sprint uses `mixamo_com` at 1.25x, backpedal uses `mixamo_com` at -0.8x, and idle uses generated `idle_generated`.
- Added `scripts/tools/InspectPlayerAnimations.gd` and `scripts/tools/ValidatePlayerAnimation.gd` for bounded animation inspection and movement animation validation.
- 2026-05-01 player animation root-motion fix: `mixamo_com` includes a `mixamorig_Hips_01` POSITION track with about 1515.96 units of Z displacement across the clip.
- That track caused the skinned visual mesh to drift away from the `CharacterBody3D` collision capsule, making the character appear to float, move at the wrong speed, or visually pass through walls.
- `PlayerController.gd` now disables POSITION tracks when `lock_animation_root_motion` is true, preserving bone rotations while keeping visual movement controlled by `CharacterBody3D`.
- Added `scripts/tools/InspectPlayerAnimationTracks.gd` and `scripts/tools/ValidatePlayerAnimationCollision.gd`; validation confirms the POSITION track is disabled, Hips no longer drifts, and the player body still stops at the west wall.
- 2026-05-01 player idle update: because `zhujiao.glb` has no separate idle clip, `PlayerController.gd` now generates `idle_generated` from a stationary pose sampled from `mixamo_com`.
- When movement input is released, the player now blends into `idle_generated` instead of stopping on the last movement pose.
- Initial generated idle skipped POSITION tracks, looped at 1.2 seconds, and added subtle upper-body breathing through `idle_breath_degrees`; this has been superseded by the 6.0-second retuned idle below.
- Generated idle can be adjusted with `idle_source_animation`, `idle_pose_time`, and `idle_breath_degrees`.
- 2026-05-01 player idle retune: the stopped-state idle no longer uses a one-foot-raised source keyframe or a frozen walk frame.
- `PlayerController.gd` now builds `idle_generated` with the lower body and hips from the model Rest Pose so both feet stay planted, while the upper body samples `mixamo_com` at `idle_pose_time=1.55`.
- Generated idle now loops at 6.0 seconds, uses `idle_breath_degrees=1.8` for slightly stronger breathing, and adds occasional head/neck left-right glance motion through `idle_head_look_degrees=9.0`.
- Added idle pose inspection scripts that compare foot/toe bone heights and upper-body hand symmetry before locking the default sample. The final generated idle measured `foot_delta=0.00` and `toe_delta=0.00`.
- Added stricter idle feet balance validation to `ValidatePlayerAnimation.gd`; it fails if the generated idle lower body is not planted.

- 2026-05-01 Phase 3 update: current project contents were backed up to `E:\godot后室_backups\godot后室_backup_20260501_155923`.
- `ForegroundOcclusion.gd` now implements the Phase 3 MVP: each frame it raycasts from `Camera3D` to the player target point and hides only `MeshInstance3D` children of hit bodies in the `foreground_occluder` group.
- Foreground occlusion restores previously hidden meshes when the camera/player line is clear or when the system is disabled.
- Foreground occlusion keeps `StaticBody3D` and `CollisionShape3D` active; validation confirmed `Wall_West_A` collision stayed enabled while its mesh was hidden.
- `FourRoomMVP.tscn` wires `ForegroundOcclusion` to `CameraRig/Camera3D` and `PlayerRoot/Player`.
- `scripts/tools/ValidatePhase3Occlusion.gd` provides a bounded automated Phase 3 validation scene script.
- 2026-05-01 Phase 3 door-frame tuning: `DoorFrame_P_*` visual meshes now participate in foreground occlusion.
- When `WallOpening_P_*` is hit, the matching `DoorFrame_P_*` is hidden/restored with it so a floating frame is not left behind.
- `ForegroundOcclusion.gd` also checks the Camera -> Player line against the U-shaped door-frame profile, so the lower door-frame header can hide even where it has no player collision.
- Door frames still do not add player-blocking collision; this change is visual-only and keeps wall-opening collision active.
- 2026-05-01 Phase 3 cutout tuning: foreground occlusion no longer hides whole meshes with `visible=false`.
- Hit foreground walls, wall openings, and door frames now receive `materials/foreground_occlusion_cutout.gdshader`, which cuts a player-sized oval around the character and uses a feathered edge for smooth transition back to the normal visible material.
- The cutout is camera-aligned using the current camera right/up axes, so the local hole follows the player silhouette region rather than deleting an entire wall panel.
- When the occluder no longer blocks Camera -> Player, `ForegroundOcclusion.gd` restores the original `material_override` and keeps the mesh visible throughout.
- Phase 0 is complete.
- Phase 1 is complete by static validation.
- Phase 2 is complete by GoPeak MCP runtime validation.
- Godot 4.6.2 executable has been found in the WinGet install directory.
- GoPeak Godot MCP has been installed project-locally through npm package contents.
- Project-level Codex MCP config has been added under `.codex/config.toml`.
- Current Codex session exposes `mcp__godot__` tools after restart.
- Root bat helpers now exist for quick local checks: `open_latest_scene.bat` opens the editor scene from disk, and `run_latest_demo.bat` runs the current main scene.
- Target Godot version is now 4.6.2.
- Rendering target is now Godot Mobile renderer for phone porting.
- `FourRoomMVP.tscn` now contains baked editor-visible room geometry, portals, markers, player, and camera.
- Each room now has one independent ceiling/roof slab in both the baked scene and runtime scene generation.
- Each room now has one ceiling-light visual panel protruding slightly below the ceiling and one separate `OmniLight3D` under `LevelRoot/Lights`.
- `CameraRig` now uses a lower close behind-the-player third-person follow view: distance 1.8m, target height 1.0m, pitch 3 degrees, initial yaw 90 degrees, and Camera3D FOV 62, so the full character remains visible.
- `CameraController.gd` supports click-to-capture mouse, mouse-look orbit, `Esc` to release mouse, and touch-drag rotation for mobile-oriented testing.
- `CameraController.gd` now uses inverted vertical look input versus the previous pass: mouse/touch vertical drag direction has been swapped by changing pitch input to add vertical relative motion.
- Camera yaw is now free 360-degree orbit and no longer recenters automatically when player movement starts.
- Wall height is now 2.55m with slight wall segment overlap to reduce visible cracks.
- Floors are now two continuous slabs instead of one floor per room.
- Each Portal now has one integrated `DoorFrame_P_*` visual MeshInstance generated by `DoorFrameVisual.gd`. It is a single U-shaped frame mesh, not separate side-post/header blocks.
- Door frames are embedded inside the wall thickness, stop at y=2.18, and do not touch the wall top. The wall portion above each opening is now a separate `WallHeader_P_*` wall body from y=2.16 to y=2.55.
- Door-frame visual dimensions now use the user-adjusted `DoorFrame_P_AB` scale as the source of truth: depth scale `1.4412847`, span scale `0.947737`; x-axis doorways swap those axes.
- DoorFrameVisual now generates a monolithic U-profile extrusion mesh instead of three box meshes joined together.
- Portal wall openings now use 4 `WallOpening_P_*` StaticBody nodes generated by `WallOpeningBody.gd`. Old `Wall_*Segment` and `WallHeader_P_*` nodes and their mesh/shape resources have been deleted instead of hidden.
- `WallOpening_P_*` nodes now have explicit saved `Mesh`, `Collision_Left`, `Collision_Right`, and `Collision_Top` child nodes so the middle wall opening geometry is selectable in the Godot editor.
- Generated wall-opening and door-frame U meshes now use the same lit light gray material as the current wall whitebox, so inner walls and outer walls share lighting/shadow behavior.
- Backrooms-style texture assets now exist for wall, floor, and door-frame materials, generated with the built-in image generation tool and exported as 1024px tileable albedo/normal PNGs.
- Current scene and runtime generation now apply `backrooms_wall.tres`, `backrooms_floor.tres`, and `backrooms_door_frame.tres` to wall, floor, wall-opening, and door-frame meshes.
- Generated U meshes in `WallOpeningBody.gd` and `DoorFrameVisual.gd` now include UVs so texture materials render on script-built geometry.
- Diagnosed the currently selected wall color difference: ordinary BoxMesh walls and `WallOpening_P_*` generated U meshes both point to `backrooms_wall.tres`; the visible color shift is primarily from editor viewport preview lighting / wall-face normal direction, not from separate wall material resources.
- Wall generation now includes explicit wall-joint filler blocks at key corners/T-junctions and a missing `Wall_A_NorthWestReturn` boundary wall where Room_D is narrower than Room_A.
- `PlayerModule.tscn` instances `res://3D模型/zhujiao.glb`.
- `zhujiao.glb` is scaled to 0.1 inside `PlayerModule.tscn` so it fits the 6m rooms.
- `PlayerController.gd` handles WASD / arrow movement using `CharacterBody3D`.
- `PlayerController.gd` now moves relative to the camera direction and supports `Shift` sprint.
- `PlayerController.gd` now treats backward input as backpedal only: `S` / down arrow moves backward while the body faces forward instead of staying sideways or turning around.
- `PlayerController.gd` now casts input key values to `Key` for Godot 4.6.2 compatibility.
- Player collision uses a 0.28m radius, 1.6m height capsule shape.
- `GameBootstrap` places the player at `Spawn_Player_A`.
- The old high fixed camera offset `(0, 5, 4)` has been superseded by the third-person orbit camera.
- `project.godot` enables the GoPeak editor/runtime/auto-reload plugins.

## Files Changed

- CURRENT_STATE.md
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/FORBIDDEN_PATTERNS.md
- scripts/tools/generate_grime_textures.py
- scripts/visual/GrimeOverlayBuilder.gd
- scripts/tools/BakeGrimeExperiment.gd
- scripts/tools/ValidateGrimeExperiment.gd
- scripts/tools/CaptureGrimeExperimentScreenshot.gd
- run_grime_experiment.bat
- materials/textures/grime/ceiling_edge_grime_01.png
- materials/textures/grime/ceiling_edge_grime_02.png
- materials/textures/grime/ceiling_edge_grime_03.png
- materials/textures/grime/baseboard_dirt_01.png
- materials/textures/grime/baseboard_dirt_02.png
- materials/textures/grime/baseboard_dirt_03.png
- materials/textures/grime/corner_grime_01.png
- materials/textures/grime/corner_grime_02.png
- materials/textures/grime/corner_grime_03.png
- scenes/mvp/experiments/FourRoomMVP_contact_ao_experiment.tscn
- scenes/mvp/experiments/FourRoomMVP_grime_experiment.tscn
- artifacts/screenshots/grime_experiment_20260503 232817.png
- logs/grime_contact_ao_bake_20260503_231416.log
- logs/grime_experiment_bake_20260503_232025.log
- logs/grime_contact_ao_validate_20260503_232129.log
- logs/grime_experiment_validate_20260503_232129.log
- logs/grime_experiment_screenshot_20260503_232815.log
- logs/grime_forbidden_scan_20260503_235012.log
- artifacts/screenshots/grime_texture_contact_sheet_20260504.png

- CURRENT_STATE.md
- docs/PROGRESS.md
- materials/foreground_occlusion_cutout.gdshader
- scripts/camera/ForegroundOcclusion.gd
- scripts/tools/ValidatePhase3Occlusion.gd
- scripts/tools/ValidateContactAOExperiment.gd
- scripts/tools/CaptureForegroundCutoutScreenshot.gd
- artifacts/screenshots/foreground_cutout_texture_20260503 223354.png
- logs/foreground_cutout_texture_phase3_20260503_222721.log
- logs/foreground_cutout_texture_contact_ao_20260503_223017.log
- logs/foreground_cutout_texture_capture_20260503_223352.log
- logs/foreground_cutout_texture_forbidden_scan_20260503_223552.log

- CURRENT_STATE.md
- docs/PROGRESS.md
- materials/shaders/contact_ao_surface.gdshader
- scripts/tools/BakeContactAOExperiment.gd
- scripts/tools/ValidateContactAOExperiment.gd
- scenes/mvp/experiments/FourRoomMVP_contact_ao_experiment.tscn
- artifacts/screenshots/contact_ao_experiment_20260503 215907.png
- logs/contact_ao_uvscale_bake_20260503_215522.log
- logs/contact_ao_uvscale_validate_20260503_215822.log
- logs/contact_ao_uvscale_capture_20260503_215905.log

- CURRENT_STATE.md
- scenes/mvp/FourRoomMVP.tscn
- scripts/scene/GeneratedMeshRules.gd
- scripts/scene/WallOpeningBody.gd
- scripts/scene/DoorFrameVisual.gd
- scripts/tools/ValidateGeneratedMeshRules.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- logs/wall_uv_upright_bake_20260503_004457.log
- logs/wall_uv_upright_ValidateGeneratedMeshRules_20260503_004535.log
- logs/wall_uv_upright_ValidateCleanRebuildScene_20260503_004535.log
- logs/wall_uv_upright_ValidateMaterialLightingRules_20260503_004535.log
- logs/wall_uv_upright_ValidateSceneShadows_20260503_004536.log
- logs/wall_uv_upright_ValidateFloorCoverage_20260503_004536.log
- logs/wall_uv_upright_ValidatePhase3Occlusion_20260503_004538.log
- logs/wall_uv_upright_DiagnoseWallVisuals_20260503_004743.log

- CURRENT_STATE.md
- scenes/mvp/FourRoomMVP.tscn
- scripts/core/SceneBuilder.gd
- scripts/scene/DoorFrameVisual.gd
- scripts/scene/WallOpeningBody.gd
- scripts/tools/ValidateCleanRebuildScene.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- logs/canonical_type_bake_20260503_002034.log
- logs/canonical_type_clean_validation_20260503_002236.log
- logs/canonical_type_generated_mesh_validation_20260503_002111.log
- logs/canonical_type_material_validation_20260503_002331.log
- logs/canonical_type_shadows_validation_20260503_002415.log
- logs/canonical_type_floor_validation_20260503_002332.log
- logs/canonical_type_occlusion_validation_20260503_002458.log

- CURRENT_STATE.md
- scenes/mvp/FourRoomMVP.tscn
- scenes/mvp/backups/FourRoomMVP.before_full_clean_rebuild_20260502_144848.tscn
- scripts/core/SceneBuilder.gd
- scripts/monster/MonsterController.gd
- scripts/tools/BakeFourRoomScene.gd
- scripts/tools/ValidateCleanRebuildScene.gd
- scripts/tools/ValidateFloorCoverage.gd
- scripts/tools/ValidateGeneratedMeshRules.gd
- scripts/tools/ValidateMaterialLightingRules.gd
- scripts/tools/ValidatePhase3Occlusion.gd
- scripts/tools/ValidateSceneShadows.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- logs/clean_rebuild_parse_20260502_145855.log
- logs/clean_rebuild_bake_20260502_145935.log
- logs/clean_rebuild_ValidateCleanRebuildScene.gd_20260502_150056.log
- logs/clean_rebuild_ValidateGeneratedMeshRules.gd_20260502_150056.log
- logs/clean_rebuild_ValidateMaterialLightingRules.gd_20260502_150056.log
- logs/clean_rebuild_ValidateSceneShadows.gd_20260502_150056.log
- logs/clean_rebuild_ValidateFloorCoverage.gd_20260502_150056.log
- logs/clean_rebuild_ValidatePhase3Occlusion.gd_20260502_150056.log
- logs/clean_rebuild_ValidateLightFlicker.gd_20260502_150056.log
- logs/clean_rebuild_ValidateMonsterSavedScale.gd_20260502_150056.log
- logs/clean_rebuild_ValidateMonsterAI.gd_20260502_150056.log
- logs/clean_rebuild_ValidateSeamGrime_20260502_150256.log
- logs/clean_rebuild_startup_20260502_150143.log
- logs/clean_rebuild_active_residue_scan_20260502_150225.log

- CURRENT_STATE.md
- scenes/mvp/FourRoomMVP.tscn
- scripts/core/SceneBuilder.gd
- scripts/tools/ValidateSceneShadows.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- scenes/mvp/backups/FourRoomMVP.before_type_wall_refactor_20260502_142609.tscn
- logs/typed_wall_parse_20260502_143243.log
- logs/typed_wall_bake_20260502_143312.log
- logs/typed_wall_ValidateSceneShadows.gd_20260502_143411.log
- logs/typed_wall_ValidateGeneratedMeshRules.gd_20260502_143411.log
- logs/typed_wall_ValidateMaterialLightingRules.gd_20260502_143411.log
- logs/typed_wall_ValidateFloorCoverage.gd_20260502_143411.log
- logs/typed_wall_ValidatePhase3Occlusion.gd_20260502_143411.log
- logs/typed_wall_ValidateLightFlicker.gd_20260502_143411.log
- logs/typed_wall_ValidateSeamGrime.gd_20260502_143411.log
- logs/typed_wall_ValidateMonsterSavedScale.gd_20260502_143411.log
- logs/typed_wall_startup_20260502_143446.log
- logs/typed_wall_forbidden_scan_20260502_143532.log
- scripts/scene/GeneratedMeshRules.gd
- scripts/tools/ValidateGeneratedMeshRules.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- artifacts/screenshots/wall_tangent_visual_20260502_134323.png
- logs/floor_winding_parse_20260502_133237.log
- logs/floor_winding_bake_20260502_133237.log
- logs/wall_tangent_bake_20260502_133848.log
- logs/wall_tangent_generated_20260502_133954.log
- logs/wall_tangent_material_20260502_133954.log
- logs/wall_tangent_shadows_20260502_133954.log
- logs/wall_tangent_diag_20260502_133955.log
- logs/wall_tangent_floor_20260502_134122.log
- logs/wall_tangent_phase3_20260502_134123.log
- logs/wall_tangent_flicker_20260502_134123.log
- logs/wall_tangent_seam_20260502_134123.log
- logs/wall_tangent_startup_20260502_134204.log
- logs/wall_tangent_visual_20260502_134323.log
- materials/foreground_occlusion_cutout.gdshader
- materials/backrooms_wall.tres
- materials/backrooms_floor.tres
- materials/backrooms_door_frame.tres
- scenes/mvp/FourRoomMVP.tscn
- scripts/core/SceneBuilder.gd
- scripts/tools/ValidateMaterialLightingRules.gd
- scripts/tools/ValidateSceneShadows.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- logs/visual_unify_parse_stdout_20260502_122645.log
- logs/visual_unify_bake_stdout_20260502_122718.log
- logs/visual_unify_material_stdout_20260502_122755.log
- logs/visual_unify_shadows_stdout_20260502_122755.log
- logs/visual_unify_generated_mesh_stdout_20260502_122755.log
- logs/visual_unify_floor_stdout_20260502_122755.log
- logs/visual_unify_phase3_stdout_20260502_122755.log
- logs/visual_unify_flicker_stdout_20260502_122755.log
- logs/visual_unify_seam_removal_stdout_20260502_122755.log
- logs/visual_unify_startup_stdout_20260502_122855.log
- logs/visual_unify_forbidden_scan_20260502_122855.log
- logs/visual_unify_active_forbidden_scan_20260502_122937.log

- CURRENT_STATE.md
- materials/backrooms_wall.tres
- materials/backrooms_floor.tres
- materials/backrooms_door_frame.tres
- materials/backrooms_ceiling.tres
- scenes/mvp/FourRoomMVP.tscn
- scripts/core/SceneBuilder.gd
- scripts/tools/ValidateSceneShadows.gd
- scripts/tools/ValidateMaterialLightingRules.gd
- scripts/tools/ValidateMaterialLightingRules.gd.uid
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- logs/material_light_rebake_stdout_20260502_104512.log
- logs/material_light_parse_stdout_20260502_104609.log
- logs/material_light_rules_stdout_20260502_104609.log
- logs/material_light_shadows_stdout_20260502_104609.log
- logs/material_light_flicker_stdout_20260502_104609.log
- logs/material_light_generated_mesh_stdout_20260502_104609.log
- logs/material_light_floor_stdout_20260502_104609.log
- logs/material_light_phase3_stdout_20260502_104609.log
- logs/material_light_startup_stdout_20260502_104644.log
- logs/material_light_forbidden_scan_20260502_104722.log

- CURRENT_STATE.md
- scenes/mvp/FourRoomMVP.tscn
- scripts/core/SceneBuilder.gd
- scripts/tools/ValidateSceneShadows.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- logs/light_coverage_parse_stdout_20260502_111500.log
- logs/light_coverage_bake_stdout_20260502_111510.log
- logs/light_coverage_shadows_stdout_20260502_111520.log
- logs/light_coverage_flicker_stdout_20260502_111520.log
- logs/light_coverage_floor_stdout_20260502_111520.log
- logs/light_coverage_phase3_stdout_20260502_111520.log
- logs/light_coverage_generated_mesh_stdout_20260502_111520.log
- logs/light_coverage_startup_stdout_20260502_111540.log

- CURRENT_STATE.md
- scenes/mvp/FourRoomMVP.tscn
- scripts/core/SceneBuilder.gd
- scripts/scene/GeneratedMeshRules.gd
- scripts/scene/WallOpeningBody.gd
- scripts/scene/DoorFrameVisual.gd
- scripts/tools/ValidateGeneratedMeshRules.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- logs/generated_mesh_rules_parse_stdout_20260502_100332.log
- logs/generated_mesh_rules_validation_stdout_20260502_100359.log
- logs/generated_mesh_rules_bake_stdout_20260502_100425.log
- logs/generated_mesh_rules_validation2_stdout_20260502_100530.log
- logs/generated_mesh_rules_floor_stdout_20260502_100602.log
- logs/generated_mesh_rules_phase3_stdout_20260502_100602.log
- logs/generated_mesh_rules_shadows_stdout_20260502_100603.log
- logs/generated_mesh_rules_startup_stdout_20260502_100630.log

- CURRENT_STATE.md
- scenes/mvp/FourRoomMVP.tscn
- scripts/core/SceneBuilder.gd
- scripts/tools/ValidateSeamGrime.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- materials/backrooms_seam_grime.tres
- materials/textures/backrooms_seam_grime_albedo.png
- materials/textures/backrooms_seam_grime_albedo.png.import
- logs/remove_seam_parse_stdout_20260502_093824.log
- logs/remove_seam_bake_stdout_20260502_093912.log
- logs/remove_seam_parse_after_bake_stdout_20260502_094003.log
- logs/remove_seam_validation_stdout_20260502_094027.log
- logs/remove_seam_floor_stdout_20260502_094049.log
- logs/remove_seam_phase3_stdout_20260502_094049.log
- logs/remove_seam_startup_stdout_20260502_094110.log

- CURRENT_STATE.md
- scenes/mvp/FourRoomMVP.tscn
- scripts/core/SceneBuilder.gd
- scripts/tools/ValidateFloorCoverage.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- logs/floor_visual_regular_parse_stdout_20260502_022505.log
- logs/floor_visual_regular_parse_godot_20260502_022505.log
- logs/floor_visual_regular_validation_stdout_20260502_022531.log
- logs/floor_visual_regular_validation_godot_20260502_022531.log
- logs/floor_visual_regular_bake_stdout_20260502_022605.log
- logs/floor_visual_regular_bake_godot_20260502_022605.log
- logs/floor_visual_regular_validation2_stdout_20260502_022627.log
- logs/floor_visual_regular_validation2_godot_20260502_022627.log
- logs/floor_visual_regular_phase3_stdout_20260502_022657.log
- logs/floor_visual_regular_phase3_godot_20260502_022657.log
- logs/floor_visual_regular_startup_stdout_20260502_022657.log
- logs/floor_visual_regular_startup_godot_20260502_022657.log

- CURRENT_STATE.md
- scripts/camera/CameraController.gd
- scripts/tools/ValidateCameraRecenter.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- logs/camera_free_orbit_parse_stdout_20260502_020859.log
- logs/camera_free_orbit_parse_godot_20260502_020859.log
- logs/camera_free_orbit_validation_stdout_20260502_020929.log
- logs/camera_free_orbit_validation_godot_20260502_020929.log
- logs/camera_free_orbit_phase3_stdout_20260502_020958.log
- logs/camera_free_orbit_phase3_godot_20260502_020958.log
- logs/camera_free_orbit_startup_stdout_20260502_020958.log
- logs/camera_free_orbit_startup_godot_20260502_020958.log
- logs/camera_free_orbit_startup_clean_stdout_20260502_021027.log
- logs/camera_free_orbit_startup_clean_godot_20260502_021027.log

- CURRENT_STATE.md
- scenes/mvp/FourRoomMVP.tscn
- scripts/core/SceneBuilder.gd
- scripts/scene/WallModule.gd
- scripts/scene/DoorFrameVisual.gd
- scripts/tools/ValidateSeamGrime.gd
- scripts/tools/ValidateSeamGrime.gd.uid
- scripts/tools/BakeFourRoomScene.gd
- scripts/tools/BakeFourRoomScene.gd.uid
- materials/backrooms_seam_grime.tres
- materials/textures/backrooms_seam_grime_albedo.png
- materials/textures/backrooms_seam_grime_albedo.png.import
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- logs/seam_grime_parse4_stdout_20260502_010753.log
- logs/seam_grime_parse4_godot_20260502_010753.log
- logs/seam_grime_bake3_stdout_20260502_011324.log
- logs/seam_grime_bake3_godot_20260502_011324.log
- logs/seam_grime_final2_validation_stdout_20260502_011444.log
- logs/seam_grime_final2_validation_godot_20260502_011444.log
- logs/seam_grime_final2_phase3_stdout_20260502_011522.log
- logs/seam_grime_final2_phase3_godot_20260502_011522.log
- logs/seam_grime_final2_floor_stdout_20260502_011607.log
- logs/seam_grime_final2_floor_godot_20260502_011607.log
- logs/seam_grime_shadows2_stdout_20260502_011404.log
- logs/seam_grime_shadows2_godot_20260502_011404.log
- logs/seam_grime_startup_stdout_20260502_011649.log
- logs/seam_grime_startup_godot_20260502_011649.log
- logs/seam_grime_no_baseboard_parse_stdout_20260502_013429.log
- logs/seam_grime_no_baseboard_parse_godot_20260502_013429.log
- logs/seam_grime_no_baseboard_bake_stdout_20260502_013505.log
- logs/seam_grime_no_baseboard_bake_godot_20260502_013505.log
- logs/seam_grime_no_baseboard_validation_stdout_20260502_013546.log
- logs/seam_grime_no_baseboard_validation_godot_20260502_013546.log
- logs/seam_grime_no_baseboard_phase3_stdout_20260502_013622.log
- logs/seam_grime_no_baseboard_phase3_godot_20260502_013622.log
- logs/seam_grime_no_baseboard_startup_stdout_20260502_013724.log
- logs/seam_grime_no_baseboard_startup_godot_20260502_013724.log
- logs/door_frame_wall_seam_parse_stdout_20260502_014742.log
- logs/door_frame_wall_seam_parse_godot_20260502_014742.log
- logs/door_frame_wall_seam_validation_stdout_20260502_014805.log
- logs/door_frame_wall_seam_validation_godot_20260502_014805.log
- logs/door_frame_wall_seam_bake_stdout_20260502_014827.log
- logs/door_frame_wall_seam_bake_godot_20260502_014827.log
- logs/door_frame_wall_seam_phase3_stdout_20260502_014855.log
- logs/door_frame_wall_seam_phase3_godot_20260502_014855.log
- logs/door_frame_wall_seam_startup_stdout_20260502_014855.log
- logs/door_frame_wall_seam_startup_godot_20260502_014855.log
- logs/door_frame_wall_seam_refine_parse_stdout_20260502_015954.log
- logs/door_frame_wall_seam_refine_parse_godot_20260502_015954.log
- logs/door_frame_wall_seam_refine_validation_stdout_20260502_020017.log
- logs/door_frame_wall_seam_refine_validation_godot_20260502_020017.log
- logs/door_frame_wall_seam_refine_bake_stdout_20260502_020017.log
- logs/door_frame_wall_seam_refine_bake_godot_20260502_020017.log
- logs/door_frame_wall_seam_refine_post_validation_stdout_20260502_020104.log
- logs/door_frame_wall_seam_refine_post_validation_godot_20260502_020104.log
- logs/door_frame_wall_seam_refine_phase3_stdout_20260502_020104.log
- logs/door_frame_wall_seam_refine_phase3_godot_20260502_020104.log
- logs/door_frame_wall_seam_refine_startup_stdout_20260502_020145.log
- logs/door_frame_wall_seam_refine_startup_godot_20260502_020145.log

- CURRENT_STATE.md
- scripts/camera/ForegroundOcclusion.gd
- scripts/tools/ValidatePhase3Occlusion.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- logs/occlusion_linger_parse_stdout_20260502_001900.log
- logs/occlusion_linger_parse_godot_20260502_001900.log
- logs/occlusion_linger_phase3_stdout_20260502_001930.log
- logs/occlusion_linger_phase3_godot_20260502_001930.log
- logs/occlusion_linger_camera_stdout_20260502_002000.log
- logs/occlusion_linger_camera_godot_20260502_002000.log
- logs/occlusion_linger_startup_stdout_20260502_002000.log
- logs/occlusion_linger_startup_godot_20260502_002000.log

- CURRENT_STATE.md
- docs/MECHANICS_ARCHIVE.md
- docs/PROGRESS.md
- docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- CURRENT_STATE.md
- scripts/monster/MonsterController.gd
- scripts/tools/ValidateMonsterAI.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- logs/monster_reverse_anim_parse_stdout_20260501_234421.log
- logs/monster_reverse_anim_parse_godot_20260501_234421.log
- logs/monster_reverse_anim_ai_stdout_20260501_234448.log
- logs/monster_reverse_anim_ai_godot_20260501_234448.log
- logs/monster_reverse_anim_floor_stdout_20260501_235046.log
- logs/monster_reverse_anim_floor_godot_20260501_235046.log
- logs/monster_reverse_anim_scale_stdout_20260501_235046.log
- logs/monster_reverse_anim_scale_godot_20260501_235046.log
- logs/monster_reverse_anim_shadows_stdout_20260501_235048.log
- logs/monster_reverse_anim_shadows_godot_20260501_235048.log
- logs/monster_reverse_anim_startup_stdout_20260501_235121.log
- logs/monster_reverse_anim_startup_godot_20260501_235121.log
- CURRENT_STATE.md
- scenes/mvp/FourRoomMVP.tscn
- scenes/modules/MonsterModule.tscn
- scripts/core/SceneBuilder.gd
- scripts/monster/MonsterController.gd
- scripts/tools/ValidateFloorCoverage.gd
- scripts/tools/ValidateFloorCoverage.gd.uid
- scripts/tools/ValidateMonsterAI.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- logs/floor_monster_parse_stdout_20260501_232840.log
- logs/floor_monster_parse_godot_20260501_232840.log
- logs/floor_coverage_final_stdout_20260501_233500.log
- logs/floor_coverage_final_godot_20260501_233500.log
- logs/panic_monster_ai_stdout_20260501_233422.log
- logs/panic_monster_ai_godot_20260501_233422.log
- logs/monster_saved_scale_final_stdout_20260501_233500.log
- logs/monster_saved_scale_final_godot_20260501_233500.log
- logs/floor_monster_shadows_stdout_20260501_233529.log
- logs/floor_monster_shadows_godot_20260501_233529.log
- logs/floor_monster_startup_stdout_20260501_233529.log
- logs/floor_monster_startup_godot_20260501_233529.log
- CURRENT_STATE.md
- scenes/mvp/FourRoomMVP.tscn
- scripts/core/SceneBuilder.gd
- materials/backrooms_ceiling_light.tres
- scripts/lighting/LightingController.gd
- scripts/tools/ValidateLightFlicker.gd
- docs/PROGRESS.md
- docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- logs/brighter_lights_parse_stdout_20260501_230809.log
- logs/brighter_lights_parse_godot_20260501_230809.log
- logs/brighter_lights_flicker_stdout_20260501_230835.log
- logs/brighter_lights_flicker_godot_20260501_230835.log
- logs/brighter_lights_shadows_stdout_20260501_230905.log
- logs/brighter_lights_shadows_godot_20260501_230905.log
- logs/brighter_lights_startup_stdout_20260501_230905.log
- logs/brighter_lights_startup_godot_20260501_230905.log
- CURRENT_STATE.md
- scripts/core/GameBootstrap.gd
- scripts/lighting/LightingController.gd
- scripts/tools/ValidateLightFlicker.gd
- scripts/tools/ValidateLightFlicker.gd.uid
- scripts/tools/ValidateMonsterSavedScale.gd
- scripts/tools/ValidateMonsterSavedScale.gd.uid
- logs/saved_monster_random_flicker_parse_stdout_20260501_225647.log
- logs/saved_monster_random_flicker_parse_godot_20260501_225647.log
- logs/saved_monster_scale_stdout_20260501_225809.log
- logs/saved_monster_scale_godot_20260501_225809.log
- logs/random_light_flicker_validation_stdout_20260501_225714.log
- logs/random_light_flicker_validation_godot_20260501_225714.log
- logs/saved_scale_monster_ai_stdout_20260501_225844.log
- logs/saved_scale_monster_ai_godot_20260501_225844.log
- logs/random_flicker_shadows_stdout_20260501_225845.log
- logs/random_flicker_shadows_godot_20260501_225845.log
- logs/saved_scale_random_flicker_run_stdout_20260501_225845.log
- logs/saved_scale_random_flicker_run_godot_20260501_225845.log
- logs/light_flicker_parse_stdout_20260501_224532.log
- logs/light_flicker_parse_godot_20260501_224532.log
- logs/light_flicker_validation_stdout_20260501_224801.log
- logs/light_flicker_validation_godot_20260501_224801.log
- logs/light_flicker_shadows_stdout_20260501_224830.log
- logs/light_flicker_shadows_godot_20260501_224830.log
- logs/light_flicker_run_stdout_20260501_224830.log
- logs/light_flicker_run_godot_20260501_224830.log
- docs/PROGRESS.md
- docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- scripts/camera/CameraController.gd
- scripts/tools/ValidateCameraRecenter.gd
- scripts/tools/ValidateCameraRecenter.gd.uid
- logs/camera_recenter_parse_stdout_20260501_222106.log
- logs/camera_recenter_parse_godot_20260501_222106.log
- logs/camera_recenter_validation_stdout_20260501_222146.log
- logs/camera_recenter_validation_godot_20260501_222146.log
- logs/camera_recenter_player_validation_stdout_20260501_222221.log
- logs/camera_recenter_player_validation_godot_20260501_222221.log
- logs/camera_recenter_monster_validation_stdout_20260501_222221.log
- logs/camera_recenter_monster_validation_godot_20260501_222221.log
- logs/camera_recenter_run_stdout_20260501_222221.log
- logs/camera_recenter_run_godot_20260501_222221.log
- docs/PROGRESS.md
- docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- scripts/monster/MonsterController.gd
- scripts/tools/ValidateMonsterAI.gd
- logs/monster_escape_route_parse_stdout_20260501_221126.log
- logs/monster_escape_route_parse_godot_20260501_221126.log
- logs/monster_escape_route_validation_stdout_20260501_221155.log
- logs/monster_escape_route_validation_godot_20260501_221155.log
- logs/monster_escape_route_run_stdout_20260501_221223.log
- logs/monster_escape_route_run_godot_20260501_221223.log
- docs/PROGRESS.md
- docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- scenes/mvp/FourRoomMVP.tscn
- scripts/core/SceneBuilder.gd
- scripts/player/PlayerController.gd
- scripts/monster/MonsterController.gd
- scripts/tools/ValidateSceneShadows.gd
- scripts/tools/ValidateSceneShadows.gd.uid
- logs/scene_shadows_parse_stdout_20260501_215655.log
- logs/scene_shadows_parse_godot_20260501_215655.log
- logs/scene_shadows_validation_stdout_20260501_215746.log
- logs/scene_shadows_validation_godot_20260501_215746.log
- logs/scene_shadows_player_validation_stdout_20260501_215818.log
- logs/scene_shadows_player_validation_godot_20260501_215818.log
- logs/scene_shadows_monster_validation_stdout_20260501_215818.log
- logs/scene_shadows_monster_validation_godot_20260501_215818.log
- logs/scene_shadows_run_stdout_20260501_215818.log
- logs/scene_shadows_run_godot_20260501_215818.log
- docs/PROGRESS.md
- docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- scenes/mvp/FourRoomMVP.tscn
- scenes/modules/MonsterModule.tscn
- scripts/core/GameBootstrap.gd
- scripts/monster/MonsterController.gd
- scripts/monster/MonsterController.gd.uid
- scripts/tools/ValidateMonsterAI.gd
- scripts/tools/ValidateMonsterAI.gd.uid
- scripts/tools/InspectMonsterModel.gd
- scripts/tools/InspectMonsterModel.gd.uid
- logs/monster_model_inspect_stdout_20260501_212504.log
- logs/monster_model_inspect_godot_20260501_212504.log
- logs/monster_ai_parse_stdout_20260501_213852.log
- logs/monster_ai_parse_godot_20260501_213852.log
- logs/monster_ai_validation_stdout_20260501_213637.log
- logs/monster_ai_validation_godot_20260501_213637.log
- logs/monster_ai_validation_stdout_20260501_213809.log
- logs/monster_ai_validation_godot_20260501_213809.log
- logs/monster_ai_run_stdout_20260501_213950.log
- logs/monster_ai_run_godot_20260501_213950.log
- docs/PROGRESS.md
- docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- scripts/player/PlayerController.gd
- scripts/tools/InspectPlayerAnimations.gd
- scripts/tools/InspectPlayerAnimationTracks.gd
- scripts/tools/ValidatePlayerAnimation.gd
- scripts/tools/ValidatePlayerAnimationCollision.gd
- scripts/tools/InspectIdlePoseCandidates.gd
- scripts/tools/InspectGeneratedIdlePoseCandidates.gd
- scripts/tools/InspectGeneratedIdlePoseCandidates.gd.uid
- scripts/tools/InspectPlayerPoseStates.gd
- scripts/tools/InspectUpperIdlePoseCandidates.gd
- scripts/tools/InspectPlayerPoseStates.gd.uid
- scripts/tools/InspectUpperIdlePoseCandidates.gd.uid
- logs/idle_replace_final_parse_stdout_20260501_211057.log
- logs/idle_replace_final_parse_godot_20260501_211057.log
- logs/idle_replace_final_pose_stdout_20260501_211124.log
- logs/idle_replace_final_pose_godot_20260501_211124.log
- logs/idle_replace_final_validation_stdout_20260501_211152.log
- logs/idle_replace_final_validation_godot_20260501_211152.log
- logs/idle_replace_final_collision_stdout_20260501_211153.log
- logs/idle_replace_final_collision_godot_20260501_211153.log
- logs/idle_replace_final_inspect_stdout_20260501_211153.log
- logs/idle_replace_final_inspect_godot_20260501_211153.log
- logs/idle_replace_final_run_stdout_20260501_211218.log
- logs/idle_replace_final_run_godot_20260501_211218.log
- logs/idle_interpolate_parse_stdout_20260501_203540.log
- logs/idle_interpolate_parse_godot_20260501_203540.log
- logs/generated_idle_pose_candidates_stdout_20260501_203608.log
- logs/generated_idle_pose_candidates_godot_20260501_203608.log
- logs/idle_final_parse_stdout_20260501_203702.log
- logs/idle_final_parse_godot_20260501_203702.log
- logs/idle_final_validation_stdout_20260501_203738.log
- logs/idle_final_validation_godot_20260501_203738.log
- logs/idle_final_collision_stdout_20260501_203802.log
- logs/idle_final_collision_godot_20260501_203802.log
- logs/idle_final_run_stdout_20260501_203840.log
- logs/idle_final_run_godot_20260501_203840.log
- logs/idle_final_inspect_stdout_20260501_204006.log
- logs/idle_final_inspect_godot_20260501_204006.log
- logs/player_animation_inspect_stdout_20260501_170000.log
- logs/player_animation_inspect_godot_20260501_170000.log
- logs/player_animation_parse_stdout_20260501_192813.log
- logs/player_animation_parse_godot_20260501_192813.log
- logs/player_animation_validation_stdout_20260501_192924.log
- logs/player_animation_validation_godot_20260501_192924.log
- logs/player_animation_run_stdout_20260501_192948.log
- logs/player_animation_run_godot_20260501_192948.log
- logs/player_animation_rootmotion_parse_stdout_20260501_200041.log
- logs/player_animation_rootmotion_parse_godot_20260501_200041.log
- logs/player_animation_rootmotion_validation_stdout_20260501_200156.log
- logs/player_animation_rootmotion_validation_godot_20260501_200156.log
- logs/player_animation_collision_validation_stdout_20260501_200306.log
- logs/player_animation_collision_validation_godot_20260501_200306.log
- logs/player_animation_track_inspect_stdout_20260501_200357.log
- logs/player_animation_track_inspect_godot_20260501_200357.log
- logs/player_animation_rootmotion_run_stdout_20260501_200425.log
- logs/player_animation_rootmotion_run_godot_20260501_200425.log
- logs/player_idle_parse_stdout_20260501_200910.log
- logs/player_idle_parse_godot_20260501_200910.log
- logs/player_idle_validation_stdout_20260501_201009.log
- logs/player_idle_validation_godot_20260501_201009.log
- logs/player_idle_inspect_stdout_20260501_201041.log
- logs/player_idle_inspect_godot_20260501_201041.log
- logs/player_idle_collision_validation_stdout_20260501_201040.log
- logs/player_idle_collision_validation_godot_20260501_201040.log
- logs/player_idle_run_stdout_20260501_201116.log
- logs/player_idle_run_godot_20260501_201116.log
- logs/player_idle_breath_parse_stdout_20260501_201728.log
- logs/player_idle_breath_parse_godot_20260501_201728.log
- logs/player_idle_breath_validation_stdout_20260501_201805.log
- logs/player_idle_breath_validation_godot_20260501_201805.log
- logs/player_idle_breath_inspect_stdout_20260501_201805.log
- logs/player_idle_breath_inspect_godot_20260501_201805.log
- logs/player_idle_breath_collision_stdout_20260501_201835.log
- logs/player_idle_breath_collision_godot_20260501_201835.log
- logs/player_idle_breath_run_stdout_20260501_201835.log
- logs/player_idle_breath_run_godot_20260501_201835.log
- scripts/camera/ForegroundOcclusion.gd
- scripts/tools/ValidatePhase3Occlusion.gd
- materials/foreground_occlusion_cutout.gdshader
- logs/phase3_cutout_parse_stdout_20260501_164000.log
- logs/phase3_cutout_parse_godot_20260501_164000.log
- logs/phase3_cutout_validation_stdout_20260501_164020.log
- logs/phase3_cutout_validation_godot_20260501_164020.log
- logs/phase3_cutout_run_stdout_20260501_164040.log
- logs/phase3_cutout_run_godot_20260501_164040.log
- logs/phase3_cutout_final_parse_stdout_20260501_164500.log
- logs/phase3_cutout_final_parse_godot_20260501_164500.log
- logs/phase3_cutout_final_validation_stdout_20260501_164520.log
- logs/phase3_cutout_final_validation_godot_20260501_164520.log
- logs/phase3_cutout_final_run_stdout_20260501_164540.log
- logs/phase3_cutout_final_run_godot_20260501_164540.log
- logs/doorframe_occlusion_parse_stdout_20260501_162000.log
- logs/doorframe_occlusion_parse_godot_20260501_162000.log
- logs/doorframe_occlusion_validation_stdout_20260501_162020.log
- logs/doorframe_occlusion_validation_godot_20260501_162020.log
- logs/doorframe_occlusion_run_stdout_20260501_162040.log
- logs/doorframe_occlusion_run_godot_20260501_162040.log
- logs/backup_20260501_155923.log
- logs/phase3_baseline_parse_stdout_20260501_160008.log
- logs/phase3_baseline_parse_godot_20260501_160008.log
- logs/phase3_baseline_run_stdout_20260501_160032.log
- logs/phase3_baseline_run_godot_20260501_160032.log
- logs/phase3_occlusion_parse_stdout_20260501_160423.log
- logs/phase3_occlusion_parse_godot_20260501_160423.log
- logs/phase3_occlusion_validation_parse_stdout_20260501_160606.log
- logs/phase3_occlusion_validation_parse_godot_20260501_160606.log
- logs/phase3_occlusion_validation_stdout_20260501_160631.log
- logs/phase3_occlusion_validation_godot_20260501_160631.log
- logs/phase3_occlusion_run_stdout_20260501_160654.log
- logs/phase3_occlusion_run_godot_20260501_160654.log
- docs/PROGRESS.md
- docs/DECISIONS.md
- docs/MVP_SPEC.md
- project.godot
- .codex/config.toml
- open_latest_scene.bat
- run_latest_demo.bat
- logs/bat_command_parse_20260501_120626.log
- logs/run_latest_demo_headless_check_20260501_121503.log
- logs/run_latest_demo_window_check_stdout_20260501_121542.log
- logs/run_latest_demo_window_check_godot_20260501_121542.log
- addons/auto_reload/
- addons/godot_mcp_editor/
- addons/godot_mcp_runtime/
- scenes/mvp/FourRoomMVP.tscn
- scenes/modules/PlayerModule.tscn
- scripts/core/SceneBuilder.gd
- scripts/scene/DoorFrameVisual.gd
- scripts/scene/WallOpeningBody.gd
- materials/backrooms_wall.tres
- materials/backrooms_floor.tres
- materials/backrooms_door_frame.tres
- materials/backrooms_ceiling.tres
- materials/backrooms_ceiling_light.tres
- materials/textures/backrooms_wall_albedo.png
- materials/textures/backrooms_wall_normal.png
- materials/textures/backrooms_floor_albedo.png
- materials/textures/backrooms_floor_normal.png
- materials/textures/backrooms_door_frame_albedo.png
- materials/textures/backrooms_door_frame_normal.png
- materials/textures/backrooms_wall_albedo.png.import
- materials/textures/backrooms_wall_normal.png.import
- materials/textures/backrooms_floor_albedo.png.import
- materials/textures/backrooms_floor_normal.png.import
- materials/textures/backrooms_door_frame_albedo.png.import
- materials/textures/backrooms_door_frame_normal.png.import
- artifacts/screenshots/texture_tile_preview_20260501_141626.png
- artifacts/screenshots/godot_current_window_for_uv_guide_20260501_142700.png
- artifacts/screenshots/godot_uv_scale_annotated_20260501_142700.png
- logs/texture_material_parse_stdout_20260501_141419.log
- logs/texture_material_parse_godot_20260501_141419.log
- logs/texture_material_parse_stdout_20260501_141537.log
- logs/texture_material_parse_godot_20260501_141537.log
- logs/texture_material_run_stdout_20260501_141626.log
- logs/texture_material_run_godot_20260501_141626.log
- logs/texture_material_uv_parse_stdout_20260501_142055.log
- logs/texture_material_uv_parse_godot_20260501_142055.log
- logs/texture_material_uv_run_stdout_20260501_142137.log
- logs/texture_material_uv_run_godot_20260501_142137.log
- logs/ceiling_light_parse_stdout_20260501_145837.log
- logs/ceiling_light_parse_godot_20260501_145837.log
- logs/ceiling_light_run_stdout_20260501_145907.log
- logs/ceiling_light_run_godot_20260501_145907.log
- logs/third_person_controls_parse_stdout_20260501_151438.log
- logs/third_person_controls_parse_godot_20260501_151438.log
- logs/third_person_controls_run_stdout_20260501_151510.log
- logs/third_person_controls_run_godot_20260501_151510.log
- logs/camera_close_limited_parse_stdout_20260501_152935.log
- logs/camera_close_limited_parse_godot_20260501_152935.log
- logs/camera_close_limited_run_stdout_20260501_153013.log
- logs/camera_close_limited_run_godot_20260501_153013.log
- logs/camera_low_backpedal_parse_stdout_20260501_153751.log
- logs/camera_low_backpedal_parse_stdout_20260501_153858.log
- logs/camera_low_backpedal_parse_godot_20260501_153858.log
- logs/camera_low_backpedal_run_stdout_20260501_153922.log
- logs/camera_low_backpedal_run_godot_20260501_153922.log
- logs/backpedal_body_recenter_parse_stdout_20260501_154550.log
- logs/backpedal_body_recenter_parse_godot_20260501_154550.log
- logs/backpedal_body_recenter_run_stdout_20260501_154624.log
- logs/backpedal_body_recenter_run_godot_20260501_154624.log
- logs/camera_vertical_invert_parse_stdout_20260501_155030.log
- logs/camera_vertical_invert_parse_godot_20260501_155030.log
- logs/camera_vertical_invert_run_stdout_20260501_155054.log
- logs/camera_vertical_invert_run_godot_20260501_155054.log
- logs/doorframe_integrated_parse_stdout_20260501_125106.log
- logs/doorframe_integrated_parse_godot_20260501_125106.log
- logs/doorframe_integrated_run_stdout_20260501_125106.log
- logs/doorframe_integrated_run_godot_20260501_125106.log
- logs/doorframe_dimension_sync_parse_stdout_20260501_130450.log
- logs/doorframe_dimension_sync_parse_godot_20260501_130450.log
- logs/doorframe_monolithic_u_mesh_parse_stdout_20260501_131242.log
- logs/doorframe_monolithic_u_mesh_parse_godot_20260501_131242.log
- logs/doorframe_monolithic_u_mesh_run_stdout_20260501_131302.log
- logs/doorframe_monolithic_u_mesh_run_godot_20260501_131302.log
- logs/wall_opening_body_parse_stdout_20260501_132619.log
- logs/wall_opening_body_parse_godot_20260501_132619.log
- logs/wall_opening_body_run_stdout_20260501_132634.log
- logs/wall_opening_body_run_godot_20260501_132634.log
- logs/wall_opening_editor_selectable_parse_stdout_20260501_133355.log
- logs/wall_opening_editor_selectable_parse_godot_20260501_133355.log
- logs/wall_opening_editor_selectable_run_stdout_20260501_133414.log
- logs/wall_opening_editor_selectable_run_godot_20260501_133414.log
- logs/wall_opening_material_parse_stdout_20260501_134127.log
- logs/wall_opening_material_parse_godot_20260501_134127.log
- logs/wall_opening_material_run_stdout_20260501_134146.log
- logs/wall_opening_material_run_godot_20260501_134146.log
- logs/wall_opening_lit_material_parse_stdout_20260501_134941.log
- logs/wall_opening_lit_material_parse_godot_20260501_134941.log
- logs/wall_opening_lit_material_run_stdout_20260501_134958.log
- logs/wall_opening_lit_material_run_godot_20260501_134958.log
- logs/door_frame_overlap_editor_parse_stdout_20260501_122731.log
- logs/door_frame_overlap_editor_parse_godot_20260501_122731.log
- logs/door_frame_overlap_run_stdout_20260501_122731.log
- logs/door_frame_overlap_run_godot_20260501_122731.log
- logs/door_frame_overlap_final_parse_stdout_20260501_123234.log
- logs/door_frame_overlap_final_parse_godot_20260501_123234.log
- logs/wall_joint_parse_stdout_20260501_123918.log
- logs/wall_joint_parse_godot_20260501_123918.log
- logs/wall_joint_run_stdout_20260501_123947.log
- logs/wall_joint_run_godot_20260501_123947.log
- scripts/player/PlayerController.gd
- scripts/camera/CameraController.gd
- scripts/core/GameBootstrap.gd
- 四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md
- 四房间MVP_Agent抗遗忘执行包/docs/MVP_SPEC.md
- 四房间MVP_Agent抗遗忘执行包/data/four_room_mvp_layout.yaml
- 四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md

## Commands Run

- Ran `git status`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read recovery/startup context from `CURRENT_STATE.md`, `README.md`, `docs/AGENT_START_HERE.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/FORBIDDEN_PATTERNS.md`, and current AO experiment scripts.
- Ran `python scripts\tools\generate_grime_textures.py`: PASS; generated 9 true-alpha PNG grime variants under `materials/textures/grime/`.
- Rebaked the contact-AO experiment: PASS, `CONTACT_AO_EXPERIMENT_BAKE PASS`; log `logs/grime_contact_ao_bake_20260503_231416.log`.
- Ran first `BakeGrimeExperiment.gd`: failed because Godot 4.6.2 does not accept `PackedStringArray(...)` as a const expression; fixed by using plain string arrays.
- Rebaked the grime experiment: PASS, `GRIME_EXPERIMENT_BAKE PASS path=res://scenes/mvp/experiments/FourRoomMVP_grime_experiment.tscn ceiling=8 baseboard=15 corner=10 total=33`; log `logs/grime_experiment_bake_20260503_232025.log`.
- Ran `ValidateContactAOExperiment.gd`: PASS; log `logs/grime_contact_ao_validate_20260503_232129.log`.
- Ran `ValidateGrimeExperiment.gd`: PASS; log `logs/grime_experiment_validate_20260503_232129.log`. Known non-blocking MCP port message appeared because another Godot/MCP process may own port 7777.
- Tried screenshot capture in headless mode: failed because the dummy renderer has no viewport texture; killed the hung helper process and reran non-headless.
- Captured visual screenshot: PASS; log `logs/grime_experiment_screenshot_20260503_232815.log`; image `artifacts/screenshots/grime_experiment_20260503 232817.png`.
- Ran active forbidden-pattern scan over `scripts`, `materials`, and `scenes`: old visibility mask patterns and room-specific `if Room_*` logic had no hits. The transparency hits are the existing approved foreground cutout and the new requested experiment-only grime overlay materials; log `logs/grime_forbidden_scan_20260503_235012.log`.
- Generated a grime texture contact sheet for visual review: `artifacts/screenshots/grime_texture_contact_sheet_20260504.png`.

- Ran `git status`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read recovery context from `CURRENT_STATE.md`, `README.md`, `docs/AGENT_START_HERE.md`, and `docs/PROGRESS.md`.
- Inspected `materials/foreground_occlusion_cutout.gdshader`, `scripts/camera/ForegroundOcclusion.gd`, `scripts/tools/ValidatePhase3Occlusion.gd`, and the contact-AO experiment validation path.
- Ran `ValidatePhase3Occlusion.gd`: exit 0; log `logs/foreground_cutout_texture_phase3_20260503_222721.log`.
- Ran `ValidateContactAOExperiment.gd`: exit 0; log `logs/foreground_cutout_texture_contact_ao_20260503_223017.log`; the known MCP runtime port message appeared but did not fail the validation.
- Captured foreground cutout screenshot: exit 0; log `logs/foreground_cutout_texture_capture_20260503_223352.log`; image `artifacts/screenshots/foreground_cutout_texture_20260503 223354.png`.
- Ran active forbidden-pattern scan: only the approved foreground-occlusion local cutout `ALPHA` use was found; log `logs/foreground_cutout_texture_forbidden_scan_20260503_223552.log`.

- Ran `git status`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read recovery context from `CURRENT_STATE.md`, `README.md`, `docs/AGENT_START_HERE.md`, and `docs/PROGRESS.md`.
- Inspected `materials/backrooms_floor.tres`, `materials/backrooms_wall.tres`, and `materials/backrooms_door_frame.tres` for the original UV scale values.
- Rebaked the contact-AO experiment scene: exit 0; log `logs/contact_ao_uvscale_bake_20260503_215522.log`.
- Ran `ValidateContactAOExperiment.gd`: exit 0; log `logs/contact_ao_uvscale_validate_20260503_215822.log`.
- Captured visual screenshot: exit 0; log `logs/contact_ao_uvscale_capture_20260503_215905.log`; image `artifacts/screenshots/contact_ao_experiment_20260503 215907.png`.
- Ran active forbidden-pattern scan: only the approved foreground-occlusion cutout shader `ALPHA` use was found; log `logs/contact_ao_uvscale_active_forbidden_scan_20260503_220445.log`.

- Ran `git status`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read recovery context from `CURRENT_STATE.md`; `TASK.md`, `RULES.md`, and `LOG.md` are not present.
- Inspected shared UV code in `GeneratedMeshRules.gd`, `WallOpeningBody.gd`, and `DoorFrameVisual.gd`; confirmed the old wall rules used negative vertical V or reversed normalized V.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`: exit 0; log `logs/wall_uv_upright_bake_20260503_004457.log`.
- Ran `ValidateGeneratedMeshRules.gd`, `ValidateCleanRebuildScene.gd`, `ValidateMaterialLightingRules.gd`, `ValidateSceneShadows.gd`, `ValidateFloorCoverage.gd`, and `ValidatePhase3Occlusion.gd`: all exit 0; logs prefixed `logs/wall_uv_upright_*_20260503_*`.
- Ran active residue scan for old negative vertical UV expressions: no active old expressions remain.
- Ran `DiagnoseWallVisuals.gd`: exit 0; log `logs/wall_uv_upright_DiagnoseWallVisuals_20260503_004743.log`.
- Updated root docs and mirrored execution-package docs.

- Ran `git status`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read recovery context from `CURRENT_STATE.md`; `TASK.md`, `RULES.md`, and `LOG.md` are not present.
- Rebaked `scenes/mvp/FourRoomMVP.tscn` with canonical doorway generation: exit 0; log `logs/canonical_type_bake_20260503_002034.log`.
- Ran `ValidateCleanRebuildScene.gd`: exit 0; log `logs/canonical_type_clean_validation_20260503_002236.log`.
- Ran `ValidateGeneratedMeshRules.gd`: exit 0; log `logs/canonical_type_generated_mesh_validation_20260503_002111.log`.
- Ran `ValidateMaterialLightingRules.gd`, `ValidateSceneShadows.gd`, `ValidateFloorCoverage.gd`, and `ValidatePhase3Occlusion.gd`: all exit 0; logs prefixed `logs/canonical_type_*_validation_20260503_*`.
- Ran `ValidateLightFlicker.gd`, `ValidateSeamGrime.gd`, `ValidateMonsterSavedScale.gd`, `ValidateMonsterAI.gd`, and `ValidateCameraRecenter.gd`: all exit 0; logs prefixed `logs/canonical_type_Validate*_20260503_*`.
- Attempted Godot MCP `scene_node_properties`, but the current editor instance was not connected to the Godot MCP editor plugin. Continued verification through saved scene inspection and Godot validation scripts.
- Ran active residue scan over scripts and the main `FourRoomMVP.tscn`: only intentional validator references to old forbidden roots were found; no active scene/generator residue for direction-specific door-frame scaling or legacy split door-frame nodes.
- Updated root docs and mirrored execution-package docs.

- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read recovery context from `CURRENT_STATE.md`; `TASK.md`, `RULES.md`, and `LOG.md` are not present in this workspace snapshot.
- Backed up the active scene to `scenes/mvp/backups/FourRoomMVP.before_full_clean_rebuild_20260502_144848.tscn`.
- Refactored `SceneBuilder.gd` so the build path deletes legacy `LevelRoot/Rooms`, creates `LevelRoot/Geometry` and `LevelRoot/Areas`, and rebuilds four-room geometry only under `Geometry`.
- Updated `MonsterController.gd` to use `LevelRoot/Areas`; updated `BakeFourRoomScene.gd` and validators for the new root split.
- Added `scripts/tools/ValidateCleanRebuildScene.gd`.
- Ran Godot 4.6.2 parse: exit 0; log `logs/clean_rebuild_parse_20260502_145855.log`.
- Ran `scripts/tools/BakeFourRoomScene.gd`: exit 0; log `logs/clean_rebuild_bake_20260502_145935.log`.
- Ran `ValidateCleanRebuildScene.gd`, `ValidateGeneratedMeshRules.gd`, `ValidateMaterialLightingRules.gd`, `ValidateSceneShadows.gd`, `ValidateFloorCoverage.gd`, `ValidatePhase3Occlusion.gd`, `ValidateLightFlicker.gd`, `ValidateMonsterSavedScale.gd`, and `ValidateMonsterAI.gd`: all exit 0; logs prefixed `logs/clean_rebuild_*_20260502_150056.log`.
- Ran `ValidateSeamGrime.gd`: exit 0; log `logs/clean_rebuild_ValidateSeamGrime_20260502_150256.log`.
- Ran short normal startup: started successfully and was stopped after timeout without a crash; log `logs/clean_rebuild_startup_20260502_150143.log`.
- Ran active residue scan over `SceneBuilder.gd`, `MonsterController.gd`, and `FourRoomMVP.tscn`: PASS, no legacy `LevelRoot/Rooms` or old floor/seam nodes; log `logs/clean_rebuild_active_residue_scan_20260502_150225.log`.
- Used Godot MCP `scene_nodes` to inspect `scenes/mvp/FourRoomMVP.tscn`; confirmed `LevelRoot` has `Geometry` and `Areas`, not `Rooms`.
- Updated root docs and mirrored execution-package docs.

- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read recovery/startup context: `README.md`, `CURRENT_STATE.md`, `docs/AGENT_START_HERE.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/FORBIDDEN_PATTERNS.md`, and `docs/ACCEPTANCE_CHECKLIST.md`.
- Backed up the active scene to `scenes/mvp/backups/FourRoomMVP.before_type_wall_refactor_20260502_142609.tscn`.
- Refactored `SceneBuilder.gd` so walls are generated by `_get_wall_piece_specs()` and `_create_wall_piece()` with `type = "solid"` / `type = "opening"`, not by separate room/area layer paths.
- Updated `ValidateSceneShadows.gd` to enforce one `STATIC_GEOMETRY_LAYER` and one `STATIC_LIGHT_MASK` for the clean MVP room.
- Ran Godot 4.6.2 parse: exit 0; log `logs/typed_wall_parse_20260502_143243.log`.
- Ran `scripts/tools/BakeFourRoomScene.gd`: exit 0; log `logs/typed_wall_bake_20260502_143312.log`.
- Ran `ValidateSceneShadows.gd`, `ValidateGeneratedMeshRules.gd`, `ValidateMaterialLightingRules.gd`, `ValidateFloorCoverage.gd`, `ValidatePhase3Occlusion.gd`, `ValidateLightFlicker.gd`, `ValidateSeamGrime.gd`, and `ValidateMonsterSavedScale.gd`: all exit 0; logs prefixed `logs/typed_wall_*_20260502_143411.log`.
- Ran short normal startup with `--quit-after 8`: exit 0; log `logs/typed_wall_startup_20260502_143446.log`.
- Ran forbidden-pattern scan: only documentation references and the approved `foreground_occlusion_cutout.gdshader` `ALPHA` use were found; log `logs/typed_wall_forbidden_scan_20260502_143532.log`.

- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read startup docs for UV/tangent direction work: `README.md`, `CURRENT_STATE.md`, `docs/AGENT_START_HERE.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/TASKS_PHASED.md`, `docs/FORBIDDEN_PATTERNS.md`, `docs/ACCEPTANCE_CHECKLIST.md`, and `docs/MECHANICS_ARCHIVE.md`.
- Ran pre-fix wall visual diagnostics: log `logs/pre_uv_diag_20260502_132817.log`; confirmed mixed tangent signs between x-facing and z-facing wall/opening faces.
- Ran pre-fix generated mesh validation: `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/pre_uv_generated_mesh_20260502_132817.log`.
- Updated `SceneBuilder.gd` floor triangle/UV order and rebaked: `BAKE_FOUR_ROOM_SCENE PASS`; log `logs/floor_winding_bake_20260502_133237.log`.
- Updated `GeneratedMeshRules.gd` to apply a shared vertical wall tangent basis and updated `ValidateGeneratedMeshRules.gd` to enforce it.
- Ran Godot 4.6.2 parse: exit 0; log `logs/wall_tangent_parse_20260502_133848.log`.
- Ran `scripts/tools/BakeFourRoomScene.gd`: exit 0; `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; log `logs/wall_tangent_bake_20260502_133848.log`.
- Ran `scripts/tools/ValidateGeneratedMeshRules.gd`: exit 0; `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/wall_tangent_generated_20260502_133954.log`.
- Ran `scripts/tools/ValidateMaterialLightingRules.gd`: exit 0; `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; log `logs/wall_tangent_material_20260502_133954.log`.
- Ran `scripts/tools/ValidateSceneShadows.gd`: exit 0; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; log `logs/wall_tangent_shadows_20260502_133954.log`.
- Ran `scripts/tools/DiagnoseWallVisuals.gd`: exit 0; log `logs/wall_tangent_diag_20260502_133955.log`; vertical wall/opening tangent signs now report unified `+` sign.
- Ran `scripts/tools/ValidateFloorCoverage.gd`: exit 0; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.061`; log `logs/wall_tangent_floor_20260502_134122.log`.
- Ran `scripts/tools/ValidatePhase3Occlusion.gd`: exit 0; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/wall_tangent_phase3_20260502_134123.log`.
- Ran `scripts/tools/ValidateLightFlicker.gd`: exit 0; `LIGHT_FLICKER_VALIDATION PASS`; log `logs/wall_tangent_flicker_20260502_134123.log`.
- Ran `scripts/tools/ValidateSeamGrime.gd`: exit 0; `SEAM_GRIME_REMOVAL_VALIDATION PASS`; log `logs/wall_tangent_seam_20260502_134123.log`.
- Ran short normal startup with `--quit-after 8`: exit 0; log `logs/wall_tangent_startup_20260502_134204.log`.
- Ran a bounded desktop visual screenshot check: saved `artifacts/screenshots/wall_tangent_visual_20260502_134323.png`; floor rendered visibly with tile material, not black.

- Ran `git status`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read startup docs after Codex restart: `README.md`, `CURRENT_STATE.md`, `docs/AGENT_START_HERE.md`, `docs/PROGRESS.md`, `docs/FORBIDDEN_PATTERNS.md`, `docs/ACCEPTANCE_CHECKLIST.md`, and `docs/DECISIONS.md`.
- Reconnected Godot MCP: `editor_status` reported `connected=true`; `editor_launch` opened the Godot 4.6.2 editor.
- Used MCP `scene_node_properties` to inspect `WallOpening_P_AB/Mesh`, `WallOpening_P_DA/Mesh`, `WallJoint_DA_WestOuter/Mesh`, and `Floor_Room_D`.
- Used MCP `class_info` to verify Godot 4.6.2 `Environment` property names and constants.
- Inspected `backrooms_wall.tres`, `backrooms_floor.tres`, `backrooms_door_frame.tres`, `backrooms_ceiling.tres`, `foreground_occlusion_cutout.gdshader`, `SceneBuilder.gd`, `ValidateSceneShadows.gd`, and `ValidateMaterialLightingRules.gd`.
- Updated cutout shader diffuse mode, material normal strengths/floor brightness, generated `WorldEnvironment`, and visual-lighting validators.
- Ran Godot 4.6.2 parse: exit 0; log `logs/visual_unify_parse_stdout_20260502_122645.log`.
- Ran `scripts/tools/BakeFourRoomScene.gd`: exit 0; `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; log `logs/visual_unify_bake_stdout_20260502_122718.log`.
- Ran `scripts/tools/ValidateMaterialLightingRules.gd`: exit 0; `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; log `logs/visual_unify_material_stdout_20260502_122755.log`.
- Ran `scripts/tools/ValidateSceneShadows.gd`: exit 0; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; log `logs/visual_unify_shadows_stdout_20260502_122755.log`.
- Ran `scripts/tools/ValidateGeneratedMeshRules.gd`: exit 0; `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/visual_unify_generated_mesh_stdout_20260502_122755.log`.
- Ran `scripts/tools/ValidateFloorCoverage.gd`: exit 0; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; log `logs/visual_unify_floor_stdout_20260502_122755.log`.
- Ran `scripts/tools/ValidatePhase3Occlusion.gd`: exit 0; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/visual_unify_phase3_stdout_20260502_122755.log`.
- Ran `scripts/tools/ValidateLightFlicker.gd`: exit 0; `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 min_interval=28.0 bright_range=1.25-1.85 base=1.050 dim=0.105 bright=1.680 panel_base=1.100 panel_dim=0.132 panel_bright=1.760`; log `logs/visual_unify_flicker_stdout_20260502_122755.log`.
- Ran `scripts/tools/ValidateSeamGrime.gd`: exit 0; `SEAM_GRIME_REMOVAL_VALIDATION PASS`; log `logs/visual_unify_seam_removal_stdout_20260502_122755.log`.
- Ran short normal startup with `--quit-after 8`: exit 0; log `logs/visual_unify_startup_stdout_20260502_122855.log`.
- Ran active forbidden-pattern scan over current scene/scripts/materials: PASS; log `logs/visual_unify_active_forbidden_scan_20260502_122937.log`. Only active hit is the approved local foreground cutout shader `ALPHA` use.
- Used MCP `editor_run`, `editor_debug_output`, and `editor_stop`: project started and stopped successfully. Only existing GDScript naming warnings appeared; no visual-unification runtime errors.

- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read startup docs for the material/light consistency fix: `README.md`, `CURRENT_STATE.md`, `docs/AGENT_START_HERE.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/TASKS_PHASED.md`, `docs/FORBIDDEN_PATTERNS.md`, `docs/ACCEPTANCE_CHECKLIST.md`, and `docs/MECHANICS_ARCHIVE.md`.
- Inspected `backrooms_wall.tres`, `backrooms_floor.tres`, `backrooms_door_frame.tres`, `backrooms_ceiling.tres`, `SceneBuilder.gd`, `ValidateSceneShadows.gd`, `ValidateGeneratedMeshRules.gd`, `ValidateLightFlicker.gd`, and baked `FourRoomMVP.tscn` wall/floor/light assignments.
- Updated shared material diffuse/normal settings and real ceiling light energy/shadow settings.
- Added `scripts/tools/ValidateMaterialLightingRules.gd`.
- Ran initial scene bake; `ValidateFloorCoverage.gd` caught stale saved `Floor_Room_A` transform offset. Fixed `SceneBuilder.gd` to rebuild from its owning scene root and explicitly reset floor visual transforms, then rebaked.
- Ran final Godot 4.6.2 parse: exit 0; log `logs/material_light_parse_stdout_20260502_104609.log`.
- Ran `scripts/tools/ValidateMaterialLightingRules.gd`: exit 0; `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; log `logs/material_light_rules_stdout_20260502_104609.log`.
- Ran `scripts/tools/ValidateSceneShadows.gd`: exit 0; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; log `logs/material_light_shadows_stdout_20260502_104609.log`.
- Ran `scripts/tools/ValidateLightFlicker.gd`: exit 0; `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 min_interval=28.0 bright_range=1.25-1.85 base=1.050 dim=0.105 bright=1.680 panel_base=1.100 panel_dim=0.132 panel_bright=1.760`; log `logs/material_light_flicker_stdout_20260502_104609.log`.
- Ran `scripts/tools/ValidateGeneratedMeshRules.gd`: exit 0; `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/material_light_generated_mesh_stdout_20260502_104609.log`.
- Ran `scripts/tools/ValidateFloorCoverage.gd`: exit 0; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; log `logs/material_light_floor_stdout_20260502_104609.log`.
- Ran `scripts/tools/ValidatePhase3Occlusion.gd`: exit 0; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/material_light_phase3_stdout_20260502_104609.log`.
- Ran short normal startup with `--quit-after 8`: exit 0; log `logs/material_light_startup_stdout_20260502_104644.log`. The only stderr item was the known non-blocking MCP runtime port 7777 conflict when the editor already owns the port.
- Ran forbidden-pattern scan over active scripts/scenes/materials: PASS. The only meaningful `ALPHA` hit is the approved `materials/foreground_occlusion_cutout.gdshader`; texture import alpha settings are normal import metadata.

- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read startup docs for ceiling-light coverage work: `README.md`, `CURRENT_STATE.md`, `docs/AGENT_START_HERE.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/TASKS_PHASED.md`, `docs/FORBIDDEN_PATTERNS.md`, `docs/ACCEPTANCE_CHECKLIST.md`, and `docs/MECHANICS_ARCHIVE.md`. `TASK.md`, `RULES.md`, and `LOG.md` are missing in this workspace snapshot.
- Inspected `SceneBuilder.gd`, `LightingController.gd`, `ValidateSceneShadows.gd`, `ValidateLightFlicker.gd`, `BakeFourRoomScene.gd`, and baked `CeilingLight_Room_*` properties in `FourRoomMVP.tscn`.
- Increased generated ceiling light range/falloff in `SceneBuilder.gd` and added range/falloff checks in `ValidateSceneShadows.gd`.
- Ran Godot 4.6.2 parse: exit 0; log `logs/light_coverage_parse_stdout_20260502_111500.log`.
- Ran `scripts/tools/BakeFourRoomScene.gd`: exit 0; `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; log `logs/light_coverage_bake_stdout_20260502_111510.log`.
- Ran `scripts/tools/ValidateSceneShadows.gd`: exit 0; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; log `logs/light_coverage_shadows_stdout_20260502_111520.log`.
- Ran `scripts/tools/ValidateLightFlicker.gd`: exit 0; `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 min_interval=28.0 bright_range=1.25-1.85 base=0.820 dim=0.082 bright=1.312 panel_base=1.100 panel_dim=0.132 panel_bright=1.760`; log `logs/light_coverage_flicker_stdout_20260502_111520.log`.
- Ran `scripts/tools/ValidateFloorCoverage.gd`: exit 0; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.063`; log `logs/light_coverage_floor_stdout_20260502_111520.log`.
- Ran `scripts/tools/ValidatePhase3Occlusion.gd`: exit 0; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/light_coverage_phase3_stdout_20260502_111520.log`.
- Ran `scripts/tools/ValidateGeneratedMeshRules.gd`: exit 0; `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/light_coverage_generated_mesh_stdout_20260502_111520.log`.
- Ran short normal startup with `--quit-after 8`: exit 0; log `logs/light_coverage_startup_stdout_20260502_111540.log`.
- Verified baked scene now saves all four `CeilingLight_Room_*` nodes with `omni_range = 6.0` and `omni_attenuation = 0.78`.

- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read startup docs for generated-wall render investigation: `README.md`, `CURRENT_STATE.md`, `docs/AGENT_START_HERE.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/TASKS_PHASED.md`, `docs/FORBIDDEN_PATTERNS.md`, `docs/ACCEPTANCE_CHECKLIST.md`, and `docs/MECHANICS_ARCHIVE.md`.
- Inspected `WallOpeningBody.gd`, `DoorFrameVisual.gd`, `SceneBuilder.gd`, `backrooms_wall.tres`, `backrooms_floor.tres`, `backrooms_door_frame.tres`, and `FourRoomMVP.tscn` material assignments around `WallOpening_P_DA`.
- Added `GeneratedMeshRules.gd`, updated generated wall-opening, door-frame, and floor visual mesh builders, and added `ValidateGeneratedMeshRules.gd`.
- Ran Godot 4.6.2 parse: exit 0; log `logs/generated_mesh_rules_parse_stdout_20260502_100332.log`.
- Ran `scripts/tools/ValidateGeneratedMeshRules.gd`: exit 0; `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/generated_mesh_rules_validation_stdout_20260502_100359.log`.
- Ran `scripts/tools/BakeFourRoomScene.gd`: exit 0; `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; log `logs/generated_mesh_rules_bake_stdout_20260502_100425.log`.
- Ran updated baked + runtime generated mesh validation: exit 0; `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/generated_mesh_rules_validation2_stdout_20260502_100530.log`.
- Ran `scripts/tools/ValidateFloorCoverage.gd`: exit 0; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.061`; log `logs/generated_mesh_rules_floor_stdout_20260502_100602.log`.
- Ran `scripts/tools/ValidatePhase3Occlusion.gd`: exit 0; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/generated_mesh_rules_phase3_stdout_20260502_100602.log`.
- Ran `scripts/tools/ValidateSceneShadows.gd`: exit 0; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; log `logs/generated_mesh_rules_shadows_stdout_20260502_100603.log`.
- Ran short normal startup with `--quit-after 8`: exit 0; log `logs/generated_mesh_rules_startup_stdout_20260502_100630.log`. The only notable runtime warning was the known non-blocking MCP runtime port 7777 conflict when the editor already owns the port.
- Verified `FourRoomMVP.tscn` now saves `WallOpening_P_DA/Mesh` with `material_override = ExtResource("18_wall_mat")`, matching `res://materials/backrooms_wall.tres`.

- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read startup docs for seam/contact-detail rollback: `README.md`, `CURRENT_STATE.md`, `docs/AGENT_START_HERE.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/TASKS_PHASED.md`, `docs/FORBIDDEN_PATTERNS.md`, `docs/ACCEPTANCE_CHECKLIST.md`, and `docs/MECHANICS_ARCHIVE.md`.
- Inspected `scripts/core/SceneBuilder.gd`, `scenes/mvp/FourRoomMVP.tscn`, `scripts/tools/ValidateSeamGrime.gd`, and generated seam grime material/texture assets.
- Removed seam grime generation calls/helpers from `SceneBuilder.gd` and removed the generated seam material/texture files.
- Ran Godot 4.6.2 parse before rebake: exit 0; log `logs/remove_seam_parse_stdout_20260502_093824.log`.
- Ran `scripts/tools/BakeFourRoomScene.gd`: exit 0; `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; log `logs/remove_seam_bake_stdout_20260502_093912.log`. The log contains expected stale-resource parse errors from loading the pre-rollback baked scene after deleting the seam material; a follow-up parse after rebake is clean.
- Ran Godot 4.6.2 parse after rebake: exit 0; log `logs/remove_seam_parse_after_bake_stdout_20260502_094003.log`.
- Ran `scripts/tools/ValidateSeamGrime.gd`: exit 0; `SEAM_GRIME_REMOVAL_VALIDATION PASS`; log `logs/remove_seam_validation_stdout_20260502_094027.log`.
- Ran `scripts/tools/ValidateFloorCoverage.gd`: exit 0; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; log `logs/remove_seam_floor_stdout_20260502_094049.log`.
- Ran `scripts/tools/ValidatePhase3Occlusion.gd`: exit 0; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/remove_seam_phase3_stdout_20260502_094049.log`.
- Ran short normal startup with `--quit-after 8`: exit 0; log `logs/remove_seam_startup_stdout_20260502_094110.log`.
- Mirrored updated `docs/PROGRESS.md`, `docs/DECISIONS.md`, and `docs/MECHANICS_ARCHIVE.md` into `四房间MVP_Agent抗遗忘执行包/docs/`; hash comparison passed.
- Ran final residue search: `SceneBuilder.gd`, `FourRoomMVP.tscn`, and `materials/` contain no active `SeamGrime`, `seam_grime`, or `backrooms_seam_grime` references.
- Ran forbidden-pattern search over active scripts/scenes/materials: PASS. The only alpha-related hit is the approved foreground-occlusion cutout shader.

- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read startup docs for global seam grime work: `README.md`, `CURRENT_STATE.md`, `docs/AGENT_START_HERE.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/TASKS_PHASED.md`, `docs/FORBIDDEN_PATTERNS.md`, `docs/ACCEPTANCE_CHECKLIST.md`, and `docs/MECHANICS_ARCHIVE.md`.
- Inspected `scripts/core/SceneBuilder.gd`, `scripts/scene/DoorFrameVisual.gd`, `scripts/scene/WallOpeningBody.gd`, `scripts/scene/WallModule.gd`, existing material resources, and validation scripts.
- Generated a seam grime texture through the built-in image generation flow and copied it to `materials/textures/backrooms_seam_grime_albedo.png`.
- Ran Godot 4.6.2 parse after seam grime work: exit 0; logs `logs/seam_grime_parse4_stdout_20260502_010753.log` and `logs/seam_grime_parse4_godot_20260502_010753.log`.
- Ran `scripts/tools/BakeFourRoomScene.gd`: exit 0; `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; logs `logs/seam_grime_bake3_stdout_20260502_011324.log` and `logs/seam_grime_bake3_godot_20260502_011324.log`.
- Ran `scripts/tools/ValidateSeamGrime.gd`: exit 0; `SEAM_GRIME_VALIDATION PASS total=31 wall=19 ceiling=4 door=8`.
- Ran `scripts/tools/ValidatePhase3Occlusion.gd`: exit 0; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=2 door_hidden_count=4`.
- Ran `scripts/tools/ValidateFloorCoverage.gd`: exit 0; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`.
- Ran `scripts/tools/ValidateSceneShadows.gd`: exit 0; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`.
- Ran short normal startup with `--quit-after 8`: exit 0; logs `logs/seam_grime_startup_stdout_20260502_011649.log` and `logs/seam_grime_startup_godot_20260502_011649.log`.
- Ran touched-file forbidden-pattern check: PASS. The only hit is `material.transparency` in `ValidateSeamGrime.gd`, which asserts the seam material stays opaque.
- Removed the wall-base cove/bevel strip from `SceneBuilder.gd`, reduced `SEAM_BASE_HEIGHT` to `0.18`, and kept only flat stain-like wall-base grime.
- Ran Godot 4.6.2 parse after removing the baseboard-like cove: exit 0; logs `logs/seam_grime_no_baseboard_parse_stdout_20260502_013429.log` and `logs/seam_grime_no_baseboard_parse_godot_20260502_013429.log`.
- Ran `scripts/tools/BakeFourRoomScene.gd`: exit 0; `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; logs `logs/seam_grime_no_baseboard_bake_stdout_20260502_013505.log` and `logs/seam_grime_no_baseboard_bake_godot_20260502_013505.log`.
- Ran `scripts/tools/ValidateSeamGrime.gd`: exit 0; `SEAM_GRIME_VALIDATION PASS total=31 wall=19 ceiling=4 door=8`.
- Ran `scripts/tools/ValidatePhase3Occlusion.gd`: exit 0; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=2 door_hidden_count=4`.
- Ran short normal startup with `--quit-after 8`: exit 0; logs `logs/seam_grime_no_baseboard_startup_stdout_20260502_013724.log` and `logs/seam_grime_no_baseboard_startup_godot_20260502_013724.log`.
- Searched touched files for baseboard/cove generation symbols: PASS, no `SEAM_BEVEL`, `_append_box_bevel_grime`, or `_quad_normal` remains in `SceneBuilder.gd`.
- Corrected door seam grime to follow the door-frame-to-wall outer contact edge instead of the inner doorway reveal or floor threshold.
- Ran Godot 4.6.2 parse after door seam correction: exit 0; logs `logs/door_frame_wall_seam_parse_stdout_20260502_014742.log` and `logs/door_frame_wall_seam_parse_godot_20260502_014742.log`.
- Ran `scripts/tools/ValidateSeamGrime.gd`: exit 0; `SEAM_GRIME_VALIDATION PASS total=31 wall=19 ceiling=4 door=8`; logs `logs/door_frame_wall_seam_validation_stdout_20260502_014805.log` and `logs/door_frame_wall_seam_validation_godot_20260502_014805.log`.
- Ran `scripts/tools/BakeFourRoomScene.gd`: exit 0; `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; logs `logs/door_frame_wall_seam_bake_stdout_20260502_014827.log` and `logs/door_frame_wall_seam_bake_godot_20260502_014827.log`.
- Ran `scripts/tools/ValidatePhase3Occlusion.gd`: exit 0; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=2 door_hidden_count=4`; logs `logs/door_frame_wall_seam_phase3_stdout_20260502_014855.log` and `logs/door_frame_wall_seam_phase3_godot_20260502_014855.log`.
- Ran short normal startup with `--quit-after 8`: exit 0; logs `logs/door_frame_wall_seam_startup_stdout_20260502_014855.log` and `logs/door_frame_wall_seam_startup_godot_20260502_014855.log`; stderr includes the known non-blocking MCP port 7777 warning when another Godot instance owns the port.
- Mirrored `docs/PROGRESS.md`, `docs/DECISIONS.md`, and `docs/MECHANICS_ARCHIVE.md` to `四房间MVP_Agent抗遗忘执行包/docs/`.
- Ran touched-file forbidden-pattern check for the door seam correction: PASS. The only implementation hit is `material.transparency` in `ValidateSeamGrime.gd`, which asserts opacity; documentation still contains the existing `current_room` / `visited_rooms` forbidden-rule text.
- Refined the door-frame side of the same seam so frame grime sits on the frame's outer inside edge, while wall grime sits on the wall just outside the frame.
- Ran Godot 4.6.2 parse after door seam refinement: exit 0; logs `logs/door_frame_wall_seam_refine_parse_stdout_20260502_015954.log` and `logs/door_frame_wall_seam_refine_parse_godot_20260502_015954.log`.
- Ran `scripts/tools/ValidateSeamGrime.gd`: exit 0; `SEAM_GRIME_VALIDATION PASS total=31 wall=19 ceiling=4 door=8`; logs `logs/door_frame_wall_seam_refine_post_validation_stdout_20260502_020104.log` and `logs/door_frame_wall_seam_refine_post_validation_godot_20260502_020104.log`.
- Ran `scripts/tools/BakeFourRoomScene.gd`: exit 0; `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; logs `logs/door_frame_wall_seam_refine_bake_stdout_20260502_020017.log` and `logs/door_frame_wall_seam_refine_bake_godot_20260502_020017.log`; stderr includes the known non-blocking MCP port warning from concurrent validation.
- Ran `scripts/tools/ValidatePhase3Occlusion.gd`: exit 0; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=2 door_hidden_count=4`; logs `logs/door_frame_wall_seam_refine_phase3_stdout_20260502_020104.log` and `logs/door_frame_wall_seam_refine_phase3_godot_20260502_020104.log`; stderr includes the known non-blocking MCP port warning from concurrent validation.
- Ran short normal startup with `--quit-after 8`: exit 0; logs `logs/door_frame_wall_seam_refine_startup_stdout_20260502_020145.log` and `logs/door_frame_wall_seam_refine_startup_godot_20260502_020145.log`.
- Re-ran touched-file forbidden-pattern check after refinement: PASS. No old threshold/reveal helper symbols remain; only the known validation/documentation hits appear.
- Updated `CameraController.gd` to use free 360-degree yaw orbit with no movement-triggered recenter. Pitch remains clamped.
- Updated `scripts/tools/ValidateCameraRecenter.gd` to validate free orbit behavior under the existing validation entrypoint.
- Ran Godot 4.6.2 parse after free-orbit camera update: exit 0; logs `logs/camera_free_orbit_parse_stdout_20260502_020859.log` and `logs/camera_free_orbit_parse_godot_20260502_020859.log`.
- Ran `scripts/tools/ValidateCameraRecenter.gd`: exit 0; `CAMERA_FREE_ORBIT_VALIDATION PASS yaw_delta=2.700 stationary_delta=0.000 moving_delta=0.000 pitch=-0.087..0.209`; logs `logs/camera_free_orbit_validation_stdout_20260502_020929.log` and `logs/camera_free_orbit_validation_godot_20260502_020929.log`.
- Ran `scripts/tools/ValidatePhase3Occlusion.gd`: exit 0; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=2 door_hidden_count=4`; logs `logs/camera_free_orbit_phase3_stdout_20260502_020958.log` and `logs/camera_free_orbit_phase3_godot_20260502_020958.log`.
- Ran short normal startup with `--quit-after 8`: exit 0; clean logs `logs/camera_free_orbit_startup_clean_stdout_20260502_021027.log` and `logs/camera_free_orbit_startup_clean_godot_20260502_021027.log`.
- Updated `docs/PROGRESS.md`, `docs/DECISIONS.md`, and `docs/MECHANICS_ARCHIVE.md`; mirrored them to `四房间MVP_Agent抗遗忘执行包/docs/`.
- Ran touched-file forbidden-pattern check for the free-orbit camera update: PASS for implementation files. Documentation hits are only existing rule text for `current_room` / `visited_rooms` and prior validation notes about opaque material checks.
- Confirmed `scenes/mvp/FourRoomMVP.tscn`, `CameraController.gd`, and `ValidateCameraRecenter.gd` no longer contain old yaw clamp/recenter symbols such as `max_yaw_offset_degrees`, `recenter_delay`, `recenter_smoothing`, `_yaw_offset`, or `rotation_smoothing`.
- Replaced the old visual floor strip pair with regular per-room floor visual panels generated by `SceneBuilder.gd`.
- Updated `ValidateFloorCoverage.gd` to reject `Floor_SouthStrip` / `Floor_NorthStrip`, validate `Floor_Room_A/B/C/D`, and keep the single continuous `Floor_WalkableCollision` requirement.
- Ran Godot 4.6.2 parse after floor visual update: exit 0; logs `logs/floor_visual_regular_parse_stdout_20260502_022505.log` and `logs/floor_visual_regular_parse_godot_20260502_022505.log`.
- Initial floor validation before rebake failed as expected because baked `FourRoomMVP.tscn` still contained old `Floor_SouthStrip`; logs `logs/floor_visual_regular_validation_stdout_20260502_022531.log` and `logs/floor_visual_regular_validation_godot_20260502_022531.log`.
- Ran `scripts/tools/BakeFourRoomScene.gd`: exit 0; `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; logs `logs/floor_visual_regular_bake_stdout_20260502_022605.log` and `logs/floor_visual_regular_bake_godot_20260502_022605.log`.
- Ran `scripts/tools/ValidateFloorCoverage.gd`: exit 0; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.063`; logs `logs/floor_visual_regular_validation2_stdout_20260502_022627.log` and `logs/floor_visual_regular_validation2_godot_20260502_022627.log`.
- Ran `scripts/tools/ValidatePhase3Occlusion.gd`: exit 0; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=2 door_hidden_count=4`; logs `logs/floor_visual_regular_phase3_stdout_20260502_022657.log` and `logs/floor_visual_regular_phase3_godot_20260502_022657.log`.
- Ran short normal startup with `--quit-after 8`: exit 0; logs `logs/floor_visual_regular_startup_stdout_20260502_022657.log` and `logs/floor_visual_regular_startup_godot_20260502_022657.log`.
- Ran final floor residue checks: old `Floor_SouthStrip` / `Floor_NorthStrip` names are absent from `scripts/core/SceneBuilder.gd` and `scenes/mvp/FourRoomMVP.tscn`; `Floor_Room_A/B/C/D` and `Floor_WalkableCollision` are present in the baked scene.

- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read startup docs for foreground occlusion edge smoothing: `README.md`, `CURRENT_STATE.md`, `docs/AGENT_START_HERE.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/TASKS_PHASED.md`, `docs/FORBIDDEN_PATTERNS.md`, `docs/ACCEPTANCE_CHECKLIST.md`, and `docs/MECHANICS_ARCHIVE.md`.
- Inspected `scripts/camera/ForegroundOcclusion.gd`, `materials/foreground_occlusion_cutout.gdshader`, `scripts/tools/ValidatePhase3Occlusion.gd`, `scenes/mvp/FourRoomMVP.tscn`, and `scripts/core/SceneBuilder.gd`.
- Ran Godot 4.6.2 headless editor parse after occlusion edge smoothing: exit 0; logs `logs/occlusion_linger_parse_stdout_20260502_001900.log` and `logs/occlusion_linger_parse_godot_20260502_001900.log`.
- Ran `scripts/tools/ValidatePhase3Occlusion.gd`: exit 0; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`.
- Ran `scripts/tools/ValidateCameraRecenter.gd`: exit 0; `CAMERA_RECENTER_VALIDATION PASS stationary_offset=0.660 moving_offset=0.013`.
- Ran short normal scene startup after occlusion edge smoothing with `--quit-after 8`: exit 0; only MCP runtime port 7777 was already occupied by the open editor.
- Ran touched-file forbidden-pattern check for `ForegroundOcclusion.gd` and `ValidatePhase3Occlusion.gd`: PASS.

- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Read startup docs for the mechanism archive update: `README.md`, `CURRENT_STATE.md`, `docs/AGENT_START_HERE.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/TASKS_PHASED.md`, `docs/FORBIDDEN_PATTERNS.md`, and `docs/ACCEPTANCE_CHECKLIST.md`.
- Inspected current project files under `scripts/`, `scenes/`, `materials/`, and `data/` to build the reusable mechanism archive.
- Verified `docs/MECHANICS_ARCHIVE.md` and `四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md` are byte-identical by SHA256: `CF7764D1418E014AD7AB79BCE7D9FD216EC1A09B3C39B32D0865C97ECBA4EC92`.
- Ran forbidden-pattern check on the new mechanism archive files: PASS, no matches.
- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Ran Godot 4.6.2 headless editor parse after monster reverse-locomotion animation tuning: exit 0; logs `logs/monster_reverse_anim_parse_stdout_20260501_234421.log` and `logs/monster_reverse_anim_parse_godot_20260501_234421.log`.
- Ran `scripts/tools/ValidateMonsterAI.gd`: exit 0; `MONSTER_AI_VALIDATION PASS state=WANDER flee_z=1.355 animation=road_creature_reference_skeleton|Walk`; this includes forward-positive and backward-negative locomotion playback checks.
- Ran `scripts/tools/ValidateFloorCoverage.gd`: exit 0; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`.
- Ran `scripts/tools/ValidateMonsterSavedScale.gd`: exit 0; `MONSTER_SAVED_SCALE_VALIDATION PASS saved_scale=(0.953989, 0.387199, 0.688722) runtime_scale=(0.953989, 0.387199, 0.688722)`.
- Ran `scripts/tools/ValidateSceneShadows.gd`: exit 0; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`.
- Ran short normal scene startup after monster reverse-locomotion animation tuning with `--quit-after 8`: exit 0; only MCP runtime port 7777 was already occupied by the open editor.
- Ran touched-file forbidden-pattern check for `MonsterController.gd` and `ValidateMonsterAI.gd`: PASS.
- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Ran Godot 4.6.2 headless editor parse after floor/monster panic tuning: exit 0; logs `logs/floor_monster_parse_stdout_20260501_232840.log` and `logs/floor_monster_parse_godot_20260501_232840.log`.
- Ran `scripts/tools/ValidateFloorCoverage.gd`: final exit 0; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.053`; logs `logs/floor_coverage_final_stdout_20260501_233500.log` and `logs/floor_coverage_final_godot_20260501_233500.log`.
- Ran `scripts/tools/ValidateMonsterAI.gd`: final exit 0; `MONSTER_AI_VALIDATION PASS state=WANDER flee_z=1.738 animation=road_creature_reference_skeleton|Walk`; logs `logs/panic_monster_ai_stdout_20260501_233422.log` and `logs/panic_monster_ai_godot_20260501_233422.log`.
- Ran `scripts/tools/ValidateMonsterSavedScale.gd`: exit 0; `MONSTER_SAVED_SCALE_VALIDATION PASS saved_scale=(0.953989, 0.387199, 0.688722) runtime_scale=(0.953989, 0.387199, 0.688722)`.
- Ran `scripts/tools/ValidateSceneShadows.gd`: exit 0; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`.
- Ran short normal scene startup after floor/monster panic tuning with `--quit-after 8`: exit 0; only MCP runtime port 7777 was already occupied by the open editor.
- Ran touched-file forbidden-pattern check for `SceneBuilder.gd`, `MonsterController.gd`, `ValidateFloorCoverage.gd`, `ValidateMonsterAI.gd`, `MonsterModule.tscn`, and `FourRoomMVP.tscn`: PASS.
- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Ran Godot 4.6.2 headless editor parse after brighter-light tuning: exit 0; logs `logs/brighter_lights_parse_stdout_20260501_230809.log` and `logs/brighter_lights_parse_godot_20260501_230809.log`.
- Ran `scripts/tools/ValidateLightFlicker.gd` after brighter-light tuning: exit 0; `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 min_interval=28.0 bright_range=1.25-1.85 base=0.820 dim=0.082 bright=1.312 panel_base=1.100 panel_dim=0.132 panel_bright=1.760`.
- Ran `scripts/tools/ValidateSceneShadows.gd`: exit 0; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`.
- Ran short normal scene startup after brighter-light tuning with `--quit-after 8`: exit 0; only MCP runtime port 7777 was already occupied by the open editor.
- Ran touched-file forbidden-pattern check for `LightingController.gd`, `ValidateLightFlicker.gd`, `SceneBuilder.gd`, `FourRoomMVP.tscn`, and `backrooms_ceiling_light.tres`: PASS.
- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Ran Godot 4.6.2 headless editor parse after saved-scale/random-flicker update: exit 0; logs `logs/saved_monster_random_flicker_parse_stdout_20260501_225647.log` and `logs/saved_monster_random_flicker_parse_godot_20260501_225647.log`.
- Ran `scripts/tools/ValidateMonsterSavedScale.gd`: exit 0; `MONSTER_SAVED_SCALE_VALIDATION PASS saved_scale=(0.953989, 0.387199, 0.688722) runtime_scale=(0.953989, 0.387199, 0.688722)`.
- Ran `scripts/tools/ValidateLightFlicker.gd` after random-frequency retune: exit 0; `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 min_interval=28.0 base=0.650 dim=0.065 panel_base=0.850 panel_dim=0.102`.
- Ran monster AI regression after saved-scale placement fix: exit 0; `MONSTER_AI_VALIDATION PASS state=WANDER flee_z=5.983 animation=road_creature_reference_skeleton|Walk`.
- Ran scene shadow regression after random-flicker retune: exit 0; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`.
- Ran normal window scene startup after saved-scale/random-flicker update with `--quit-after 8`: exit 0; only MCP runtime port 7777 was already occupied by the open editor.
- Ran touched-file forbidden-pattern check for `GameBootstrap.gd`, `LightingController.gd`, `ValidateLightFlicker.gd`, and `ValidateMonsterSavedScale.gd`: PASS.
- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Ran Godot 4.6.2 headless editor parse after ceiling-light flicker update: exit 0; logs `logs/light_flicker_parse_stdout_20260501_224532.log` and `logs/light_flicker_parse_godot_20260501_224532.log`.
- Ran `scripts/tools/ValidateLightFlicker.gd`: final exit 0; `LIGHT_FLICKER_VALIDATION PASS lights=4 base=0.650 dim=0.065 panel_base=0.850 panel_dim=0.102`; logs `logs/light_flicker_validation_stdout_20260501_224801.log` and `logs/light_flicker_validation_godot_20260501_224801.log`.
- Ran scene shadow regression after ceiling-light flicker update: exit 0; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`.
- Ran normal window scene startup after ceiling-light flicker update with `--quit-after 8`: exit 0.
- Ran touched-file forbidden-pattern check for `LightingController.gd` and `ValidateLightFlicker.gd`: PASS.
- Ran `git status --short`: not a git repository; expected for this workspace snapshot.
- Ran `git diff --stat`: not a git repository; expected for this workspace snapshot.
- Ran Godot 4.6.2 headless editor parse after camera recenter update: exit 0; logs `logs/camera_recenter_parse_stdout_20260501_222106.log` and `logs/camera_recenter_parse_godot_20260501_222106.log`.
- Ran `scripts/tools/ValidateCameraRecenter.gd`: exit 0; `CAMERA_RECENTER_VALIDATION PASS stationary_offset=0.660 moving_offset=0.013`; logs `logs/camera_recenter_validation_stdout_20260501_222146.log` and `logs/camera_recenter_validation_godot_20260501_222146.log`.
- Ran player animation regression after camera recenter update: exit 0; `PLAYER_ANIMATION_VALIDATION PASS movement=mixamo_com idle=idle_generated`.
- Ran monster AI regression after camera recenter update: exit 0; `MONSTER_AI_VALIDATION PASS state=WANDER flee_z=5.543 animation=road_creature_reference_skeleton|Walk`.
- Ran normal window scene startup after camera recenter update: exit 0.
- Ran touched-file forbidden-pattern check for `CameraController.gd` and `ValidateCameraRecenter.gd`: PASS.
- Ran `scripts/tools/InspectPlayerAnimations.gd`: exit 0; `PLAYER_ANIMATION_INSPECT PASS players=1`; found `ModelRoot/zhujiao/AnimationPlayer` with one animation `mixamo_com`, length 2.042, loop mode 0.
- Updated `PlayerController.gd` to play the GLB animation for walk/sprint/backpedal and stop on idle when no idle animation is configured.
- Added `scripts/tools/ValidatePlayerAnimation.gd` and ran it through Godot 4.6.2 headless: exit 0; `PLAYER_ANIMATION_VALIDATION PASS animation=mixamo_com`.
- Ran Godot 4.6.2 headless editor parse after the animation hookup: exit 0; only existing nested-project warning.
- Ran normal window scene startup after the animation hookup with `--quit-after 8`: exit 0; no animation script errors.
- Ran `scripts/tools/InspectPlayerAnimationTracks.gd`: exit 0; found `mixamorig_Hips_01` POSITION track with delta `(0.300295, 2.112946, 1515.96)`.
- Updated `PlayerController.gd` to disable animation POSITION tracks by default through `lock_animation_root_motion`.
- Re-ran track inspection: exit 0; `TRACK 027 type=POSITION enabled=false`.
- Re-ran player animation validation: exit 0; `PLAYER_ANIMATION_VALIDATION PASS animation=mixamo_com`, including root-motion drift checks.
- Ran `scripts/tools/ValidatePlayerAnimationCollision.gd`: exit 0; `PLAYER_ANIMATION_COLLISION_VALIDATION PASS player_x=-2.533`.
- Ran normal window scene startup after root-motion fix with `--quit-after 8`: exit 0; no animation script errors.
- Updated `PlayerController.gd` to generate `idle_generated` from the current GLB when no authored idle clip exists.
- Updated `scripts/tools/ValidatePlayerAnimation.gd` so stopping movement must play `idle_generated`.
- Ran Godot 4.6.2 headless editor parse after idle generation: exit 0; only existing nested-project warning.
- Ran player animation validation after idle generation: exit 0; `PLAYER_ANIMATION_VALIDATION PASS movement=mixamo_com idle=idle_generated`; only MCP port 7777 was already occupied by the open editor.
- Ran animation inspection after idle generation: exit 0; `AnimationPlayer` now reports `idle_generated` and `mixamo_com`.
- Ran collision validation after idle generation: exit 0; `PLAYER_ANIMATION_COLLISION_VALIDATION PASS player_x=-2.533`; only MCP port 7777 was already occupied by the open editor.
- Ran normal window scene startup after idle generation with `--quit-after 8`: exit 0; no player animation script errors; only MCP port 7777 was already occupied by the open editor.
- Added subtle generated idle breathing through upper-body rotation keys controlled by `idle_breath_degrees`.
- Ran Godot 4.6.2 headless editor parse after idle breathing: exit 0; only existing nested-project warning.
- Ran player animation validation after idle breathing: exit 0; `PLAYER_ANIMATION_VALIDATION PASS movement=mixamo_com idle=idle_generated`; only MCP port 7777 was already occupied by the open editor.
- Ran animation inspection after idle breathing: exit 0; `AnimationPlayer` still reports `idle_generated` and `mixamo_com`.
- Ran collision validation after idle breathing: exit 0; `PLAYER_ANIMATION_COLLISION_VALIDATION PASS player_x=-2.533`.
- Ran normal window scene startup after idle breathing with `--quit-after 8`: exit 0; no player animation script errors; only MCP port 7777 was already occupied by the open editor.

- Backed up current project contents with robocopy excluding `.godot`; backup saved to `E:\godot后室_backups\godot后室_backup_20260501_155923`, log saved to `logs/backup_20260501_155923.log`.
- Ran Phase 3 baseline Godot 4.6.2 headless editor parse: exit 0; only existing warning was nested `project.godot` under the older project folder.
- Ran Phase 3 baseline normal window startup with `--quit-after 8`: exit 0; only error line was the existing MCP runtime port 7777 already occupied by another Godot instance.
- Implemented `scripts/camera/ForegroundOcclusion.gd` Camera -> Player raycast hiding for foreground `MeshInstance3D` children.
- Wired `ForegroundOcclusion` camera and target paths in `scenes/mvp/FourRoomMVP.tscn`.
- Added `scripts/tools/ValidatePhase3Occlusion.gd` for automated occlusion/collision validation.
- Ran Godot 4.6.2 headless editor parse after Phase 3 implementation: exit 0; only existing nested-project warning.
- Ran Phase 3 validation script: exit 0, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1`.
- Ran normal window scene startup after Phase 3 implementation with `--quit-after 8`: exit 0; only MCP runtime port 7777 occupied by another Godot instance.
- Ran static follow-up log checks for `ForegroundOcclusion`, camera/player scripts, script errors, and forbidden placeholder patterns: PASS.
- Updated `ForegroundOcclusion.gd` so matching `DoorFrame_P_*` visual meshes hide/restored with `WallOpening_P_*` occluders.
- Added Camera -> Player line tests against the U-shaped door-frame visual profile for trim/head pieces that do not have player collision.
- Extended `ValidatePhase3Occlusion.gd` to assert `WallOpening_P_AB` and `DoorFrame_P_AB` hide together, restore together, and keep wall-opening collision enabled.
- Ran Godot 4.6.2 headless editor parse for the door-frame occlusion tuning: exit 0; only existing nested-project warning.
- Ran Phase 3 validation script after the door-frame occlusion tuning: exit 0, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`.
- Ran normal window scene startup after the door-frame occlusion tuning with `--quit-after 8`: exit 0; only MCP runtime port 7777 occupied by another Godot instance.
- Ran forbidden-pattern search over touched Phase 3 files: PASS.
- Added `materials/foreground_occlusion_cutout.gdshader` for local player-area cutout with feathered alpha transition.
- Replaced whole-mesh `visible=false` occlusion in `ForegroundOcclusion.gd` with temporary `ShaderMaterial` overrides that preserve original wall, wall-opening, and door-frame materials.
- Updated `ValidatePhase3Occlusion.gd` so validation expects visible meshes with local cutout materials, restored original materials, and unchanged collisions.
- Ran Godot 4.6.2 headless editor parse for local cutout tuning: exit 0; only existing nested-project warning.
- Ran Phase 3 validation script after local cutout tuning: exit 0, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`.
- Ran normal window scene startup after local cutout tuning with `--quit-after 8`: exit 0; only MCP runtime port 7777 occupied by another Godot instance.
- Forbidden-pattern search over touched Phase 3 files found only the expected local `ALPHA` use in `foreground_occlusion_cutout.gdshader`; this is the allowed Phase 3 local cutout path, not a large transparent wall or visibility overlay.
- Ran final Godot 4.6.2 headless editor parse after documentation/text cleanup: exit 0; only existing nested-project warning.
- Ran final Phase 3 validation script after local cutout tuning: exit 0, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`.
- Ran final normal window scene startup after local cutout tuning with `--quit-after 8`: exit 0; only MCP runtime port 7777 occupied by another Godot instance.
- git status --short
- git diff --stat
- Read CURRENT_STATE.md
- Read docs/PROGRESS.md
- Read docs/TASKS_PHASED.md Phase 2
- Read docs/ACCEPTANCE_CHECKLIST.md Phase 2
- Read docs/FORBIDDEN_PATTERNS.md
- PowerShell scene external resource checks with UTF-8 path handling
- PowerShell player file checks
- PowerShell camera angle configuration check
- PowerShell player controller static checks
- PowerShell forbidden-pattern search over implementation files
- PowerShell old visibility file search
- Get-Command godot/godot4/godot4.3
- Bounded E drive search for Godot*.exe
- Updated Godot target version to 4.6.2
- Switched project renderer from Forward+ to Mobile
- Recorded mobile renderer decision in docs
- Baked editor-visible preview geometry into FourRoomMVP.tscn
- PowerShell static scene resource and structure checks
- Scaled player model to 0.1 and adjusted collision/move speed after editor visual check showed the model was too large
- Removed ceilings after editor visual check
- Reduced wall height from 3.0m to 2.55m
- Added 0.04m wall segment overlap to reduce visible gaps
- Replaced per-room floor pieces with two continuous floor slabs
- Added 8 door-frame posts around the 4 Portal openings
- Located Godot 4.6.2 WinGet executable path
- Researched Godot MCP options and selected GoPeak for runtime validation needs
- Installed GoPeak addon files from npm package contents into `addons/`
- Added project-level Codex MCP config in `.codex/config.toml`
- Enabled GoPeak plugins in `project.godot`
- Ran Godot headless project parse check
- Ran Godot editor headless plugin-load check
- Synced root `docs/PROGRESS.md` and `docs/DECISIONS.md` back into the execution package copy
- Validated `.codex/config.toml` with a TOML parser
- Verified GoPeak addon plugin files exist
- Re-ran forbidden-pattern search over project implementation files excluding third-party `addons/`
- Used `mcp__godot__` project_info, editor_run, runtime_status, editor_debug_output, and editor_stop
- Used GoPeak runtime TCP commands for get_tree, get_node/call_method, inject_action, capture_screenshot, and set_property
- Ran Phase 2 MCP runtime validation and saved `logs/phase2_mcp_runtime_validation_20260501_113727.json`
- Saved screenshot `artifacts/screenshots/phase2_mcp_runtime_20260501_113727.png`
- Fixed Godot 4.6.2 enum warning in `scripts/player/PlayerController.gd`
- Adjusted camera follow offset to `(0, 5, 4)` in `scripts/camera/CameraController.gd`
- Synced updated `docs/PROGRESS.md` and `docs/DECISIONS.md` back into the execution package copy
- Ran final LSP diagnostics for player and camera scripts: no diagnostics
- Ran final forbidden-pattern search: PASS
- Stopped the running Godot project after validation
- Re-synced updated `docs/PROGRESS.md` and `docs/DECISIONS.md` into the execution package copy
- Added four `DoorFrame_*_Header` top frame/lintel pieces to `FourRoomMVP.tscn`
- Updated `SceneBuilder.gd` to generate the same four door frame headers at runtime
- Ran Godot headless project parse check for the door frame change
- Ran LSP diagnostics for `SceneBuilder.gd`: no diagnostics
- Ran GoPeak MCP runtime validation for door frame headers and P_AB pass-through
- Ran final forbidden-pattern search after door frame change: PASS
- Synced updated docs back into the execution package copy
- Stopped the running Godot project after door frame validation
- Thickened door frame headers from 0.28m to 0.44m and lowered their centers to y=2.33
- Ran Godot headless parse check for thicker door frame headers
- Ran GoPeak MCP runtime validation for sealed door headers and P_AB pass-through
- Ran final forbidden-pattern search after thicker door header change: PASS
- Synced updated docs into the execution package copy after thicker door header change
- Stopped the running Godot project after thicker door header validation
- Added `open_latest_scene.bat` for opening `FourRoomMVP.tscn` from disk with Godot 4.6.2.
- Added `run_latest_demo.bat` for running the current main scene with Godot 4.6.2.
- Checked helper bat files with PowerShell static path/content validation.
- Ran Godot console headless command parse check for the editor open command; log saved to `logs/bat_command_parse_20260501_120626.log`.
- Fixed bat project path quoting by trimming the trailing slash from `%~dp0`.
- Changed `run_latest_demo.bat` to use Godot console output, keep the window open after exit, and write `logs/run_latest_demo.log`.
- Ran a headless run check; Godot 4.6.2 crashed in headless mode, log saved to `logs/run_latest_demo_headless_check_20260501_121503.log`.
- Ran a normal window run check with `--quit-after 20`; it exited 0 with no error hits, logs saved to `logs/run_latest_demo_window_check_stdout_20260501_121542.log` and `logs/run_latest_demo_window_check_godot_20260501_121542.log`.
- Shifted all door-frame side posts 0.06m inward to overlap the visible door edge instead of only touching it.
- Expanded baked door-frame header meshes/shapes so each header spans both side posts.
- Updated `SceneBuilder.gd` with `DOOR_FRAME_EDGE_OVERLAP`, `_door_frame_edge_offset()`, and `_door_frame_header_span()` so runtime generation matches the baked scene.
- Ran static door-frame overlap checks against `FourRoomMVP.tscn` and `SceneBuilder.gd`: PASS.
- Ran forbidden-pattern search for old mask/fade symbols in touched files: PASS.
- Ran Godot headless editor parse check: exit 0, no error hits; logs saved to `logs/door_frame_overlap_editor_parse_stdout_20260501_122731.log` and `logs/door_frame_overlap_editor_parse_godot_20260501_122731.log`.
- Ran normal window scene check with `--quit-after 20`: exit 0; only error hit was GoPeak MCP runtime port 7777 already in use by the existing Godot instance; logs saved to `logs/door_frame_overlap_run_stdout_20260501_122731.log` and `logs/door_frame_overlap_run_godot_20260501_122731.log`.
- Ran final Godot headless editor parse check after docs updates: exit 0, no error hits; logs saved to `logs/door_frame_overlap_final_parse_stdout_20260501_123234.log` and `logs/door_frame_overlap_final_parse_godot_20260501_123234.log`.
- Added `Wall_A_NorthWestReturn` to close the exposed outer boundary segment caused by Room_D being narrower than Room_A.
- Added 10 `WallJoint_*` filler blocks at key wall corners/T-junctions in both baked scene geometry and runtime `SceneBuilder.gd` generation.
- Ran static wall-joint resource/node checks: PASS.
- Ran Godot headless editor parse check for wall joints: exit 0, no error hits; logs saved to `logs/wall_joint_parse_stdout_20260501_123918.log` and `logs/wall_joint_parse_godot_20260501_123918.log`.
- Ran normal window scene check with `--quit-after 20`: exit 0, no error hits; logs saved to `logs/wall_joint_run_stdout_20260501_123947.log` and `logs/wall_joint_run_godot_20260501_123947.log`.
- Replaced split door-frame post/header nodes with 4 integrated `DoorFrame_P_*` visual MeshInstances using `scripts/scene/DoorFrameVisual.gd`.
- Added 4 separate `WallHeader_P_*` StaticBody wall headers so the wall above each doorway is wall geometry, not part of the door frame.
- Updated runtime `SceneBuilder.gd` to create the same integrated door frames and wall headers.
- Ran static integrated door-frame checks: old split door-frame pieces 0, new door frames 4, wall headers 4.
- Ran Godot headless editor parse check for integrated door frames: exit 0, no error hits; logs saved to `logs/doorframe_integrated_parse_stdout_20260501_125106.log` and `logs/doorframe_integrated_parse_godot_20260501_125106.log`.
- Ran normal window scene check with `--quit-after 20`: exit 0, no error hits; logs saved to `logs/doorframe_integrated_run_stdout_20260501_125106.log` and `logs/doorframe_integrated_run_godot_20260501_125106.log`.
- Used Godot MCP `editor_status` and `scene_nodes` to confirm the editor bridge is connected and the scene tree contains 4 `DoorFrame_P_*` nodes plus 4 `WallHeader_P_*` nodes.
- Synced integrated door-frame progress and D017 decision into root docs and the execution package copy.
- Ran final PowerShell static check after documentation sync: old split door-frame nodes 0, new `DoorFrame_P_*` nodes 4, `WallHeader_P_*` nodes 4, runtime specs 4, docs synced PASS.
- Read saved `DoorFrame_P_*` node blocks from `FourRoomMVP.tscn`; detected user-adjusted `DoorFrame_P_AB` transform scale `x=1.4412847`, `z=0.947737`.
- Applied the same physical door-frame dimensions to `DoorFrame_P_BC`, `DoorFrame_P_CD`, and `DoorFrame_P_DA`; x-axis frames swap span/depth scale axes.
- Updated runtime `SceneBuilder.gd` with `DOOR_FRAME_DEPTH_SCALE`, `DOOR_FRAME_SPAN_SCALE`, and axis-aware `_door_frame_scale()`.
- Ran final static door-frame dimension check: all 4 scene transforms matched expected scale; runtime scale constants and axis swap present.
- Ran Godot 4.6.2 headless parse check for door-frame dimension sync: exit 0, no error hits; logs saved to `logs/doorframe_dimension_sync_parse_stdout_20260501_130450.log` and `logs/doorframe_dimension_sync_parse_godot_20260501_130450.log`.
- Ran final door-frame dimension documentation/static sync check: scene transforms, runtime scale constants, root docs, and execution package docs all PASS.
- Reworked `DoorFrameVisual.gd` from three `_add_box()` pieces into a single U-shaped 2D profile extruded through wall depth.
- Removed saved door-frame `mesh = SubResource("ArrayMesh_*")` assignments from `FourRoomMVP.tscn` so the scene no longer starts from stale three-piece meshes.
- Ran static monolithic door-frame mesh checks: `_add_box` absent, `Geometry2D.triangulate_polygon()` U-profile present, door-frame mesh assignment count 0, door-frame node count 4.
- Ran Godot 4.6.2 headless parse check for monolithic U mesh: exit 0, no error hits; logs saved to `logs/doorframe_monolithic_u_mesh_parse_stdout_20260501_131242.log` and `logs/doorframe_monolithic_u_mesh_parse_godot_20260501_131242.log`.
- Ran normal window scene startup with `--quit-after 8`: exit 0, no error hits; logs saved to `logs/doorframe_monolithic_u_mesh_run_stdout_20260501_131302.log` and `logs/doorframe_monolithic_u_mesh_run_godot_20260501_131302.log`.
- Ran final monolithic U mesh documentation/static sync check: script topology, scene door-frame nodes, root docs, and execution package docs all PASS.
- Replaced portal wall opening construction with `WallOpeningBody.gd`, a `StaticBody3D` that owns one monolithic U-shaped visual mesh plus simple child box collisions for the left side, right side, and top.
- Deleted old baked `Wall_AB/BC/CD/DA_*Segment` nodes and `WallHeader_P_*` nodes from `FourRoomMVP.tscn`.
- Removed unused old segment/header `BoxMesh` and `BoxShape3D` resources from `FourRoomMVP.tscn`; no hidden old mesh nodes remain.
- Updated runtime `SceneBuilder.gd` to create `WallOpening_P_*` bodies and no longer create old segment/header specs or hide old mesh nodes.
- Ran static wall-opening cleanup checks: 4 `WallOpening_P_*` nodes, 0 old segment nodes, 0 old header nodes, 0 old segment/header resources, no `.visible = false` mesh hiding.
- Ran Godot 4.6.2 headless parse check for wall opening bodies: exit 0, no error hits; logs saved to `logs/wall_opening_body_parse_stdout_20260501_132619.log` and `logs/wall_opening_body_parse_godot_20260501_132619.log`.
- Ran normal window scene startup with `--quit-after 8`: exit 0, no error hits; logs saved to `logs/wall_opening_body_run_stdout_20260501_132634.log` and `logs/wall_opening_body_run_godot_20260501_132634.log`.
- Used Godot MCP `scene_nodes` to confirm saved scene now contains 4 `WallOpening_P_*` nodes and no `WallHeader_P_*` or old portal wall segment nodes.
- Ran final wall-opening documentation/static sync check: scene cleanup, runtime generator cleanup, replacement body collision ownership, root docs, and execution package docs all PASS.
- Fixed Godot editor selection for portal wall openings by saving explicit `Mesh`, `Collision_Left`, `Collision_Right`, and `Collision_Top` child nodes under each `WallOpening_P_*`.
- Updated `WallOpeningBody.gd` so dynamically created editor children receive the edited scene root as `owner`.
- Ran static editor-selectability checks: all 4 wall openings have 1 Mesh child and 3 collision children; owner assignment exists.
- Ran Godot 4.6.2 headless parse check for editor-selectable wall openings: exit 0, no error hits; logs saved to `logs/wall_opening_editor_selectable_parse_stdout_20260501_133355.log` and `logs/wall_opening_editor_selectable_parse_godot_20260501_133355.log`.
- Ran normal window scene startup with `--quit-after 8`: exit 0, no error hits; logs saved to `logs/wall_opening_editor_selectable_run_stdout_20260501_133414.log` and `logs/wall_opening_editor_selectable_run_godot_20260501_133414.log`.
- Used Godot MCP `scene_nodes` to confirm each `WallOpening_P_*` exposes `Mesh`, `Collision_Left`, `Collision_Right`, and `Collision_Top` children.
- Temporarily tested generated `WallOpeningBody.gd` and `DoorFrameVisual.gd` materials as unshaded light gray; this was superseded by the later lit-material alignment so inner walls match outer wall lighting.
- Ran static material consistency and touched-file forbidden-pattern checks: PASS.
- Ran Godot 4.6.2 headless parse check for the material fix: exit 0, no error hits; logs saved to `logs/wall_opening_material_parse_stdout_20260501_134127.log` and `logs/wall_opening_material_parse_godot_20260501_134127.log`.
- Ran normal window scene startup with `--quit-after 8`: exit 0, no non-MCP error hits; logs saved to `logs/wall_opening_material_run_stdout_20260501_134146.log` and `logs/wall_opening_material_run_godot_20260501_134146.log`.
- Synced the material/color fix note into root `docs/` and the execution package `docs/` copy.
- Ran final material line, documentation sync, and touched-file forbidden-pattern checks: PASS.
- Removed `SHADING_MODE_UNSHADED` from `WallOpeningBody.gd` and `DoorFrameVisual.gd` so generated inner wall/door-frame meshes use normal lit `StandardMaterial3D`, matching outer wall lighting/shadow behavior.
- Ran static lit-material consistency and touched-file forbidden-pattern checks: PASS.
- Ran Godot 4.6.2 headless parse check for the lit-material alignment: exit 0, no error hits; logs saved to `logs/wall_opening_lit_material_parse_stdout_20260501_134941.log` and `logs/wall_opening_lit_material_parse_godot_20260501_134941.log`.
- Ran normal window scene startup with `--quit-after 8`: exit 0, no non-MCP error hits; logs saved to `logs/wall_opening_lit_material_run_stdout_20260501_134958.log` and `logs/wall_opening_lit_material_run_godot_20260501_134958.log`.
- Used built-in image generation to create realistic Backrooms-style seamless texture sources for wall wallpaper, worn vinyl floor tile, and pale gray door-frame trim.
- Exported project-local 1024px albedo/normal textures under `materials/textures/`.
- Added `materials/backrooms_wall.tres`, `materials/backrooms_floor.tres`, and `materials/backrooms_door_frame.tres` with albedo texture, normal texture, roughness, and UV tiling.
- Added material overrides to baked `FourRoomMVP.tscn` floor and wall mesh nodes.
- Updated runtime `SceneBuilder.gd` to apply floor/wall materials when rebuilding generated boxes.
- Updated `WallOpeningBody.gd` and `DoorFrameVisual.gd` to use material resources and generate UV arrays for script-built U meshes.
- First Godot texture parse failed because the scene file had a UTF-8 BOM after a bulk PowerShell rewrite; removed the BOM and re-ran validation.
- Ran static texture/material scene checks and forbidden-pattern search: PASS.
- Ran Godot 4.6.2 headless parse after BOM fix: exit 0, no error hits; logs saved to `logs/texture_material_parse_stdout_20260501_141537.log` and `logs/texture_material_parse_godot_20260501_141537.log`.
- Ran normal window scene startup after material hookup: exit 0, no non-MCP error hits; logs saved to `logs/texture_material_run_stdout_20260501_141626.log` and `logs/texture_material_run_godot_20260501_141626.log`.
- Generated texture tiling preview screenshot at `artifacts/screenshots/texture_tile_preview_20260501_141626.png`; checked 2x2 repeats for wall, floor, and door-frame albedo textures.
- Ran Godot 4.6.2 headless parse after adding UVs to U meshes: exit 0, no error hits; logs saved to `logs/texture_material_uv_parse_stdout_20260501_142055.log` and `logs/texture_material_uv_parse_godot_20260501_142055.log`.
- Ran normal window scene startup after adding UVs: exit 0, no non-MCP error hits; logs saved to `logs/texture_material_uv_run_stdout_20260501_142137.log` and `logs/texture_material_uv_run_godot_20260501_142137.log`.
- Captured the current Godot editor window and created an annotated UV scale guide screenshot at `artifacts/screenshots/godot_uv_scale_annotated_20260501_142700.png`.
- Screenshot check: PASS; the image marks the visible texture scale issue, the material resource files to open, and the Inspector `UV1 > Scale` fields to adjust.
- Checked selected wall material sources after the color-difference report: ordinary wall Mesh nodes use `material_override = ExtResource("18_wall_mat")`, `WallOpeningBody.gd` preloads the same `res://materials/backrooms_wall.tres`, and sampled wall albedo horizontal/vertical average brightness bands are effectively uniform.
- Tried Godot MCP scene-node property inspection; the current MCP server could not connect to the editor because port 6505 was already owned by another GoPeak instance, so this diagnostic used static file checks instead.
- Added 4 `Ceiling_Room_*` StaticBody ceiling slabs to the baked scene and runtime `SceneBuilder.gd` generation.
- Added 4 `CeilingLightPanel_Room_*` visual MeshInstance panels that protrude slightly below the ceiling.
- Added 4 separate `CeilingLight_Room_*` `OmniLight3D` nodes under `LevelRoot/Lights`.
- Added `materials/backrooms_ceiling.tres` and `materials/backrooms_ceiling_light.tres`.
- Ran static ceiling/light count checks: 4 ceilings, 4 light panels, 4 OmniLights, and matching runtime generation.
- Ran Godot 4.6.2 headless editor parse for the ceiling/light pass: exit 0; only existing warning was nested `project.godot` under `godot后室新`.
- Ran normal window scene startup with `--quit-after 8`: exit 0, no error hits.

- Changed `scripts/camera/CameraController.gd` from fixed follow offset to third-person follow/orbit with mouse capture, mouse-look, `Esc` release, and touch-drag rotation.
- Changed `scripts/player/PlayerController.gd` to use camera-relative movement and `Shift` sprint.
- Updated `scenes/mvp/FourRoomMVP.tscn` CameraRig exported values and Camera3D FOV for the lower third-person view.
- Ran Godot 4.6.2 headless editor parse for the third-person camera/control pass: exit 0; only existing warning was nested `project.godot` under `godot后室新`.
- Ran normal window scene startup with `--quit-after 8`: exit 0; only error hit was GoPeak MCP runtime port 7777 already occupied by another Godot instance.
- Ran static follow-up log checks for `CameraController`, `PlayerController`, script errors, and forbidden placeholders: PASS.
- Adjusted the third-person camera to match the closer screenshot framing: distance 1.55m, target height 1.15m, pitch 6 degrees, and Camera3D FOV 60.
- Added limited camera orbit: yaw offset clamps to +/-90 degrees around the player's movement-facing direction instead of allowing unrestricted 360-degree rotation.
- Added automatic yaw recentering after 0.45s without manual mouse/touch rotation.
- Ran Godot 4.6.2 headless editor parse for the close limited-camera pass: exit 0; only existing warning was nested `project.godot` under `godot后室新`.
- Ran normal window scene startup with `--quit-after 8`: exit 0; only error hit was GoPeak MCP runtime port 7777 already occupied by another Godot instance.
- Ran static follow-up log checks for `CameraController`, `PlayerController`, script errors, and forbidden placeholders: PASS.
- Lowered the third-person camera framing while preserving full character visibility: distance 1.8m, target height 1.0m, pitch 3 degrees, Camera3D FOV 62.
- Changed `PlayerController.gd` so backward-dominant input returns no visual-facing update; `S` / down arrow now backpedals instead of turning the character.
- Changed `CameraController.gd` to read `get_camera_heading_direction()` from the player for recentering, so backward velocity no longer rotates the camera heading.
- First parse for this pass found a Godot 4.6 Variant inference warning treated as error; fixed it with an explicit `Variant` annotation.
- Re-ran Godot 4.6.2 headless editor parse: exit 0; only existing warning was nested `project.godot` under `godot后室新`.
- Ran normal window scene startup with `--quit-after 8`: exit 0; only error hit was GoPeak MCP runtime port 7777 already occupied by another Godot instance.
- Ran static follow-up log checks for `CameraController`, `PlayerController`, script errors, and forbidden placeholders: PASS.
- Fixed backpedal body orientation: when `S` / down arrow is backward-dominant, `PlayerController.gd` now faces the body opposite the movement vector, so the character backs up while looking forward instead of staying sideways.
- Ran Godot 4.6.2 headless editor parse for the backpedal body recenter pass: exit 0; only existing warning was nested `project.godot` under `godot后室新`.
- Ran normal window scene startup with `--quit-after 8`: exit 0; only error hit was GoPeak MCP runtime port 7777 already occupied by another Godot instance.
- Ran static follow-up log checks for `CameraController`, `PlayerController`, script errors, and forbidden placeholders: PASS.
- Swapped mouse/touch vertical look direction by changing `CameraController.gd` pitch input from subtracting to adding `relative_motion.y`.
- Ran Godot 4.6.2 headless editor parse for the vertical look inversion pass: exit 0; only existing warning was nested `project.godot` under `godot后室新`.
- Ran normal window scene startup with `--quit-after 8`: exit 0; only error hit was GoPeak MCP runtime port 7777 already occupied by another Godot instance.
- Ran static follow-up log checks for `CameraController`, `PlayerController`, script errors, and forbidden placeholders: PASS.

## Validation Result

PASS

Latest global grime experiment validation:
- Texture generation: PASS, 9 PNGs created under `materials/textures/grime/` with true transparent corners/backgrounds and non-opaque alpha bodies.
- Contact-AO ancestry: PASS, `CONTACT_AO_EXPERIMENT_VALIDATION PASS wall=21 floor=4 door_frame=4 ceiling=4`; log `logs/grime_contact_ao_validate_20260503_232129.log`.
- Grime bake: PASS, `GRIME_EXPERIMENT_BAKE PASS path=res://scenes/mvp/experiments/FourRoomMVP_grime_experiment.tscn ceiling=8 baseboard=15 corner=10 total=33`; log `logs/grime_experiment_bake_20260503_232025.log`.
- Grime validation: PASS, `GRIME_EXPERIMENT_VALIDATION PASS ceiling=8 baseboard=15 corner=10`; log `logs/grime_experiment_validate_20260503_232129.log`.
- Screenshot validation: PASS for a first visual inspection screenshot, saved at `artifacts/screenshots/grime_experiment_20260503 232817.png`.
- Active forbidden-pattern scan: PASS for old mask and room-specific logic. Transparency hits are expected/isolated: foreground local cutout plus experiment-only grime overlays requested by the user; log `logs/grime_forbidden_scan_20260503_235012.log`.
- Base-scene merge: not performed. This remains an experiment pending user visual acceptance.

Latest foreground cutout texture preservation validation:
- Base Phase 3 occlusion: PASS, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/foreground_cutout_texture_phase3_20260503_222721.log`.
- Contact-AO experiment occlusion/material validation: PASS, `CONTACT_AO_EXPERIMENT_VALIDATION PASS wall=21 floor=4 door_frame=4 ceiling=4`; log `logs/foreground_cutout_texture_contact_ao_20260503_223017.log`.
- Screenshot validation: PASS for wall texture remaining visible while the local player-area cutout is active; screenshot `artifacts/screenshots/foreground_cutout_texture_20260503 223354.png`.
- Active forbidden-pattern scan: PASS except the existing approved `materials/foreground_occlusion_cutout.gdshader` local cutout `ALPHA`; log `logs/foreground_cutout_texture_forbidden_scan_20260503_223552.log`.

Latest contact-AO experiment UV-scale validation:
- Experiment bake: PASS, `CONTACT_AO_EXPERIMENT_BAKE PASS`; log `logs/contact_ao_uvscale_bake_20260503_215522.log`.
- Experiment material/UV validation: PASS, `CONTACT_AO_EXPERIMENT_VALIDATION PASS wall=21 floor=4 door_frame=4 ceiling=4`; log `logs/contact_ao_uvscale_validate_20260503_215822.log`.
- Screenshot validation: PASS for corrected floor tile scale in the experiment copy; screenshot `artifacts/screenshots/contact_ao_experiment_20260503 215907.png`.
- Active forbidden-pattern scan: PASS except the existing approved `materials/foreground_occlusion_cutout.gdshader` local cutout `ALPHA`; log `logs/contact_ao_uvscale_active_forbidden_scan_20260503_220445.log`.
- Base-scene merge: not performed. This remains an experiment copy pending user visual acceptance.

Latest upright wall UV validation:
- Scene bake: PASS, `BAKE_FOUR_ROOM_SCENE PASS`; log `logs/wall_uv_upright_bake_20260503_004457.log`.
- Generated mesh rule validation: PASS, now includes vertical UV direction check; log `logs/wall_uv_upright_ValidateGeneratedMeshRules_20260503_004535.log`.
- Clean rebuild / canonical doorway rule: PASS; log `logs/wall_uv_upright_ValidateCleanRebuildScene_20260503_004535.log`.
- Material lighting: PASS; log `logs/wall_uv_upright_ValidateMaterialLightingRules_20260503_004535.log`.
- Scene shadows: PASS; log `logs/wall_uv_upright_ValidateSceneShadows_20260503_004536.log`.
- Floor coverage: PASS, `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.050`; log `logs/wall_uv_upright_ValidateFloorCoverage_20260503_004536.log`.
- Phase 3 occlusion: PASS; log `logs/wall_uv_upright_ValidatePhase3Occlusion_20260503_004538.log`.
- Wall visual diagnostic: PASS for shared generated mesh/material/tangent state after UV flip; log `logs/wall_uv_upright_DiagnoseWallVisuals_20260503_004743.log`.

Latest canonical scene object generation validation:
- Scene bake: PASS, `BAKE_FOUR_ROOM_SCENE PASS`; log `logs/canonical_type_bake_20260503_002034.log`.
- Clean rebuild / canonical doorway rule: PASS, `CLEAN_REBUILD_SCENE_VALIDATION PASS`; log `logs/canonical_type_clean_validation_20260503_002236.log`.
- Generated mesh rule validation: PASS, `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/canonical_type_generated_mesh_validation_20260503_002111.log`.
- Material lighting validation: PASS, `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; log `logs/canonical_type_material_validation_20260503_002331.log`.
- Scene shadows: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; log `logs/canonical_type_shadows_validation_20260503_002415.log`.
- Floor coverage: PASS, `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; log `logs/canonical_type_floor_validation_20260503_002332.log`.
- Phase 3 occlusion: PASS, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/canonical_type_occlusion_validation_20260503_002458.log`.
- Light flicker, seam-grime removal, monster saved scale, monster AI, and free camera orbit: PASS.
- MCP editor inspection: BLOCKED by editor plugin disconnected state, not by scene content. Saved scene and Godot validation scripts confirm the canonical rule.

Latest full clean rebuild validation:
- Godot 4.6.2 parse: PASS, exit 0; log `logs/clean_rebuild_parse_20260502_145855.log`.
- Scene bake: PASS, `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; log `logs/clean_rebuild_bake_20260502_145935.log`.
- Clean rebuild structure: PASS, `CLEAN_REBUILD_SCENE_VALIDATION PASS`; log `logs/clean_rebuild_ValidateCleanRebuildScene.gd_20260502_150056.log`.
- MCP scene-tree inspection: PASS, `LevelRoot` contains `Geometry` and `Areas`; `Rooms` is absent.
- Generated mesh rule validation: PASS; log `logs/clean_rebuild_ValidateGeneratedMeshRules.gd_20260502_150056.log`.
- Material-lighting rule validation: PASS; log `logs/clean_rebuild_ValidateMaterialLightingRules.gd_20260502_150056.log`.
- Scene shadow validation: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; log `logs/clean_rebuild_ValidateSceneShadows.gd_20260502_150056.log`.
- Floor coverage regression: PASS, `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; log `logs/clean_rebuild_ValidateFloorCoverage.gd_20260502_150056.log`.
- Phase 3 foreground occlusion regression: PASS; log `logs/clean_rebuild_ValidatePhase3Occlusion.gd_20260502_150056.log`.
- Light flicker regression: PASS; log `logs/clean_rebuild_ValidateLightFlicker.gd_20260502_150056.log`.
- Seam/contact-detail removal regression: PASS; log `logs/clean_rebuild_ValidateSeamGrime_20260502_150256.log`.
- Monster saved-scale and monster AI regressions: PASS; logs `logs/clean_rebuild_ValidateMonsterSavedScale.gd_20260502_150056.log` and `logs/clean_rebuild_ValidateMonsterAI.gd_20260502_150056.log`.
- Active residue scan: PASS, no legacy `LevelRoot/Rooms` or old floor/seam node references in active generator/scene; log `logs/clean_rebuild_active_residue_scan_20260502_150225.log`.
- Short normal startup: PASS for startup/no crash; scene kept running until the bounded timeout stopped it; log `logs/clean_rebuild_startup_20260502_150143.log`.

Latest type-based wall generation validation:
- Godot 4.6.2 parse: PASS, exit 0; log `logs/typed_wall_parse_20260502_143243.log`.
- Scene bake: PASS, exit 0; log `logs/typed_wall_bake_20260502_143312.log`.
- Static light/layer validation: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; log `logs/typed_wall_ValidateSceneShadows.gd_20260502_143411.log`.
- Generated mesh rule validation: PASS, `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/typed_wall_ValidateGeneratedMeshRules.gd_20260502_143411.log`.
- Material-lighting validation: PASS, `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; log `logs/typed_wall_ValidateMaterialLightingRules.gd_20260502_143411.log`.
- Floor coverage regression: PASS; log `logs/typed_wall_ValidateFloorCoverage.gd_20260502_143411.log`.
- Phase 3 foreground occlusion regression: PASS; log `logs/typed_wall_ValidatePhase3Occlusion.gd_20260502_143411.log`.
- Light flicker regression: PASS; log `logs/typed_wall_ValidateLightFlicker.gd_20260502_143411.log`.
- Seam/contact detail removal regression: PASS; log `logs/typed_wall_ValidateSeamGrime.gd_20260502_143411.log`.
- Monster saved-scale regression: PASS; log `logs/typed_wall_ValidateMonsterSavedScale.gd_20260502_143411.log`.
- Short normal startup: PASS, exit 0; log `logs/typed_wall_startup_20260502_143446.log`.
- Forbidden-pattern scan: PASS with expected docs hits and approved foreground cutout shader `ALPHA`; log `logs/typed_wall_forbidden_scan_20260502_143532.log`.

Latest UV/tangent direction validation:
- Godot 4.6.2 parse: PASS, exit 0; log `logs/wall_tangent_parse_20260502_133848.log`.
- Scene bake: PASS, `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; log `logs/wall_tangent_bake_20260502_133848.log`.
- Generated mesh/tangent rule validation: PASS, `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/wall_tangent_generated_20260502_133954.log`.
- Material-lighting rule validation: PASS, `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; log `logs/wall_tangent_material_20260502_133954.log`.
- Shadow/light-layer validation: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; log `logs/wall_tangent_shadows_20260502_133954.log`.
- Wall visual diagnostic: PASS, log `logs/wall_tangent_diag_20260502_133955.log`; vertical wall/opening tangent signs are unified to `+`.
- Floor coverage regression: PASS, `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.061`; log `logs/wall_tangent_floor_20260502_134122.log`.
- Phase 3 foreground occlusion regression: PASS, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/wall_tangent_phase3_20260502_134123.log`.
- Light flicker regression: PASS, log `logs/wall_tangent_flicker_20260502_134123.log`.
- Seam/contact detail rollback regression: PASS, `SEAM_GRIME_REMOVAL_VALIDATION PASS`; log `logs/wall_tangent_seam_20260502_134123.log`.
- Short normal startup: PASS, exit 0; log `logs/wall_tangent_startup_20260502_134204.log`.
- Visual screenshot: PASS, `artifacts/screenshots/wall_tangent_visual_20260502_134323.png` shows visible floor tile material instead of a black floor.

Latest runtime visual-lighting unification validation:
- Godot 4.6.2 parse: PASS, exit 0; log `logs/visual_unify_parse_stdout_20260502_122645.log`.
- Scene bake: PASS, `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; log `logs/visual_unify_bake_stdout_20260502_122718.log`.
- MCP scene inspection: PASS, selected wall/opening meshes use `backrooms_wall.tres`, `Floor_Room_D` uses `backrooms_floor.tres`, and `LevelRoot/Lights/WorldEnvironment` exists.
- Material-lighting rule validation: PASS, `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; log `logs/visual_unify_material_stdout_20260502_122755.log`.
- Shadow/ambient validation: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; log `logs/visual_unify_shadows_stdout_20260502_122755.log`.
- Generated mesh render-rule regression: PASS, `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/visual_unify_generated_mesh_stdout_20260502_122755.log`.
- Floor coverage regression: PASS, `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; log `logs/visual_unify_floor_stdout_20260502_122755.log`.
- Phase 3 foreground occlusion regression: PASS, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/visual_unify_phase3_stdout_20260502_122755.log`.
- Light flicker regression: PASS, `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 min_interval=28.0 bright_range=1.25-1.85 base=1.050 dim=0.105 bright=1.680 panel_base=1.100 panel_dim=0.132 panel_bright=1.760`; log `logs/visual_unify_flicker_stdout_20260502_122755.log`.
- Seam/contact detail rollback regression: PASS, `SEAM_GRIME_REMOVAL_VALIDATION PASS`; log `logs/visual_unify_seam_removal_stdout_20260502_122755.log`.
- Short normal startup: PASS, exit 0; log `logs/visual_unify_startup_stdout_20260502_122855.log`.
- MCP debug run/stop: PASS; runtime output had only existing GDScript naming warnings.
- Active forbidden-pattern scan: PASS; only active hit is the approved `materials/foreground_occlusion_cutout.gdshader` `ALPHA` use.

Latest material-lighting/shadow readability validation:
- Godot 4.6.2 parse: PASS, exit 0; log `logs/material_light_parse_stdout_20260502_104609.log`.
- Scene bake after SceneBuilder root fix: PASS, `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; log `logs/material_light_rebake_stdout_20260502_104512.log`.
- Material-lighting rule validation: PASS, `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; log `logs/material_light_rules_stdout_20260502_104609.log`.
- Shadow/readability validation: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; log `logs/material_light_shadows_stdout_20260502_104609.log`.
- Light flicker regression: PASS, `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 min_interval=28.0 bright_range=1.25-1.85 base=1.050 dim=0.105 bright=1.680 panel_base=1.100 panel_dim=0.132 panel_bright=1.760`; log `logs/material_light_flicker_stdout_20260502_104609.log`.
- Generated mesh render-rule regression: PASS, `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/material_light_generated_mesh_stdout_20260502_104609.log`.
- Floor coverage regression: PASS, `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; log `logs/material_light_floor_stdout_20260502_104609.log`.
- Phase 3 foreground occlusion regression: PASS, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/material_light_phase3_stdout_20260502_104609.log`.
- Short normal startup: PASS, exit 0; log `logs/material_light_startup_stdout_20260502_104644.log`.
- Forbidden-pattern scan: PASS; log `logs/material_light_forbidden_scan_20260502_104722.log`.

Latest ceiling-light coverage validation:
- Godot 4.6.2 parse: PASS, exit 0; log `logs/light_coverage_parse_stdout_20260502_111500.log`.
- Scene bake: PASS, `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; log `logs/light_coverage_bake_stdout_20260502_111510.log`.
- Baked scene light property check: PASS, all four `CeilingLight_Room_*` nodes save `omni_range = 6.0` and `omni_attenuation = 0.78`.
- Shadow/coverage validation: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; log `logs/light_coverage_shadows_stdout_20260502_111520.log`.
- Light flicker regression: PASS, `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 min_interval=28.0 bright_range=1.25-1.85 base=0.820 dim=0.082 bright=1.312 panel_base=1.100 panel_dim=0.132 panel_bright=1.760`; log `logs/light_coverage_flicker_stdout_20260502_111520.log`.
- Floor coverage regression: PASS, `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.063`; log `logs/light_coverage_floor_stdout_20260502_111520.log`.
- Phase 3 foreground occlusion regression: PASS, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/light_coverage_phase3_stdout_20260502_111520.log`.
- Generated mesh render-rule regression: PASS, `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/light_coverage_generated_mesh_stdout_20260502_111520.log`.
- Short normal startup: PASS, exit 0; log `logs/light_coverage_startup_stdout_20260502_111540.log`.

Latest generated mesh render-rule validation:
- Godot 4.6.2 parse: PASS, exit 0; log `logs/generated_mesh_rules_parse_stdout_20260502_100332.log`.
- Generated mesh render-rule validation: PASS, `GENERATED_MESH_RULES_VALIDATION PASS`; log `logs/generated_mesh_rules_validation2_stdout_20260502_100530.log`.
- Scene bake: PASS, `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; log `logs/generated_mesh_rules_bake_stdout_20260502_100425.log`.
- Baked scene material check: PASS, `WallOpening_P_DA/Mesh` now saves `material_override = ExtResource("18_wall_mat")`, the same `backrooms_wall.tres` material as ordinary walls.
- Floor coverage regression: PASS, `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.061`; log `logs/generated_mesh_rules_floor_stdout_20260502_100602.log`.
- Phase 3 foreground occlusion regression: PASS, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/generated_mesh_rules_phase3_stdout_20260502_100602.log`.
- Scene shadow regression: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; log `logs/generated_mesh_rules_shadows_stdout_20260502_100603.log`.
- Short normal startup: PASS, exit 0; log `logs/generated_mesh_rules_startup_stdout_20260502_100630.log`.

Latest seam/contact-detail rollback validation:
- Godot 4.6.2 parse after rebake: PASS, exit 0; log `logs/remove_seam_parse_after_bake_stdout_20260502_094003.log`.
- Seam grime removal validation: PASS, `SEAM_GRIME_REMOVAL_VALIDATION PASS`; log `logs/remove_seam_validation_stdout_20260502_094027.log`.
- Floor coverage regression: PASS, `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; log `logs/remove_seam_floor_stdout_20260502_094049.log`.
- Phase 3 foreground occlusion regression: PASS, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; log `logs/remove_seam_phase3_stdout_20260502_094049.log`.
- Short normal startup: PASS, exit 0; log `logs/remove_seam_startup_stdout_20260502_094110.log`.
- Residue search: PASS, no active seam-grime nodes, material references, or generated texture files remain.
- Forbidden-pattern search: PASS, with only the known approved `materials/foreground_occlusion_cutout.gdshader` `ALPHA` usage.

Latest regular floor visual validation:
- Godot 4.6.2 parse: PASS, exit 0; logs `logs/floor_visual_regular_parse_stdout_20260502_022505.log` and `logs/floor_visual_regular_parse_godot_20260502_022505.log`.
- Scene bake: PASS, `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; logs `logs/floor_visual_regular_bake_stdout_20260502_022605.log` and `logs/floor_visual_regular_bake_godot_20260502_022605.log`.
- Floor coverage and regular visual validation: PASS, `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.063`; logs `logs/floor_visual_regular_validation2_stdout_20260502_022627.log` and `logs/floor_visual_regular_validation2_godot_20260502_022627.log`.
- Phase 3 foreground occlusion regression: PASS, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=2 door_hidden_count=4`; logs `logs/floor_visual_regular_phase3_stdout_20260502_022657.log` and `logs/floor_visual_regular_phase3_godot_20260502_022657.log`.
- Short normal startup: PASS, exit 0; logs `logs/floor_visual_regular_startup_stdout_20260502_022657.log` and `logs/floor_visual_regular_startup_godot_20260502_022657.log`.
- Final floor residue search: PASS, old strip floor visuals are absent from the active generator and baked scene.

Latest third-person free-orbit camera validation:
- Godot 4.6.2 parse: PASS, exit 0; logs `logs/camera_free_orbit_parse_stdout_20260502_020859.log` and `logs/camera_free_orbit_parse_godot_20260502_020859.log`.
- Free-orbit camera validation: PASS, `CAMERA_FREE_ORBIT_VALIDATION PASS yaw_delta=2.700 stationary_delta=0.000 moving_delta=0.000 pitch=-0.087..0.209`; logs `logs/camera_free_orbit_validation_stdout_20260502_020929.log` and `logs/camera_free_orbit_validation_godot_20260502_020929.log`.
- Phase 3 foreground occlusion regression: PASS, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=2 door_hidden_count=4`; logs `logs/camera_free_orbit_phase3_stdout_20260502_020958.log` and `logs/camera_free_orbit_phase3_godot_20260502_020958.log`.
- Short normal startup: PASS, exit 0; clean logs `logs/camera_free_orbit_startup_clean_stdout_20260502_021027.log` and `logs/camera_free_orbit_startup_clean_godot_20260502_021027.log`.

Latest foreground occlusion edge smoothing validation:
- Godot 4.6.2 parse: PASS, exit 0; logs `logs/occlusion_linger_parse_stdout_20260502_001900.log` and `logs/occlusion_linger_parse_godot_20260502_001900.log`.
- Phase 3 occlusion validation: PASS, `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; logs `logs/occlusion_linger_phase3_stdout_20260502_001930.log` and `logs/occlusion_linger_phase3_godot_20260502_001930.log`.
- Camera recenter regression: PASS, `CAMERA_RECENTER_VALIDATION PASS stationary_offset=0.660 moving_offset=0.013`; logs `logs/occlusion_linger_camera_stdout_20260502_002000.log` and `logs/occlusion_linger_camera_godot_20260502_002000.log`.
- Short normal startup: PASS, exit 0; logs `logs/occlusion_linger_startup_stdout_20260502_002000.log` and `logs/occlusion_linger_startup_godot_20260502_002000.log`.
- Touched-file forbidden-pattern check: PASS.
- Recurring non-blocking runtime error: the open Godot editor already owns MCP runtime port 7777 during normal startup.

Latest mechanism archive documentation validation:
- Documentation-only change. No Godot runtime validation required.
- Added `docs/MECHANICS_ARCHIVE.md` and mirrored it under `四房间MVP_Agent抗遗忘执行包/docs/MECHANICS_ARCHIVE.md`.
- Updated `docs/PROGRESS.md`, `docs/DECISIONS.md`, root `CURRENT_STATE.md`, and mirror docs.
- Archive mirror hash check: PASS.
- Forbidden-pattern check on the new archive files: PASS.

Latest monster reverse-locomotion animation validation:
- Godot 4.6.2 parse: PASS, exit 0; logs `logs/monster_reverse_anim_parse_stdout_20260501_234421.log` and `logs/monster_reverse_anim_parse_godot_20260501_234421.log`.
- Monster AI / locomotion animation validation: PASS, `MONSTER_AI_VALIDATION PASS state=WANDER flee_z=1.355 animation=road_creature_reference_skeleton|Walk`; logs `logs/monster_reverse_anim_ai_stdout_20260501_234448.log` and `logs/monster_reverse_anim_ai_godot_20260501_234448.log`.
- Floor coverage regression: PASS, `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; logs `logs/monster_reverse_anim_floor_stdout_20260501_235046.log` and `logs/monster_reverse_anim_floor_godot_20260501_235046.log`.
- Monster saved scale validation: PASS, `MONSTER_SAVED_SCALE_VALIDATION PASS saved_scale=(0.953989, 0.387199, 0.688722) runtime_scale=(0.953989, 0.387199, 0.688722)`.
- Scene shadow regression: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`.
- Short normal startup: PASS, exit 0; logs `logs/monster_reverse_anim_startup_stdout_20260501_235121.log` and `logs/monster_reverse_anim_startup_godot_20260501_235121.log`.
- Touched-file forbidden-pattern check: PASS.
- Recurring non-blocking runtime error: the open Godot editor already owns MCP runtime port 7777.

Latest floor/monster panic validation:
- Godot 4.6.2 parse: PASS, exit 0; logs `logs/floor_monster_parse_stdout_20260501_232840.log` and `logs/floor_monster_parse_godot_20260501_232840.log`.
- Floor coverage validation: PASS, `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.053`; logs `logs/floor_coverage_final_stdout_20260501_233500.log` and `logs/floor_coverage_final_godot_20260501_233500.log`.
- Monster panic/route validation: PASS, `MONSTER_AI_VALIDATION PASS state=WANDER flee_z=1.738 animation=road_creature_reference_skeleton|Walk`; logs `logs/panic_monster_ai_stdout_20260501_233422.log` and `logs/panic_monster_ai_godot_20260501_233422.log`.
- Monster saved scale validation: PASS, `MONSTER_SAVED_SCALE_VALIDATION PASS saved_scale=(0.953989, 0.387199, 0.688722) runtime_scale=(0.953989, 0.387199, 0.688722)`; logs `logs/monster_saved_scale_final_stdout_20260501_233500.log` and `logs/monster_saved_scale_final_godot_20260501_233500.log`.
- Scene shadow regression: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; logs `logs/floor_monster_shadows_stdout_20260501_233529.log` and `logs/floor_monster_shadows_godot_20260501_233529.log`.
- Short normal startup: PASS, exit 0; logs `logs/floor_monster_startup_stdout_20260501_233529.log` and `logs/floor_monster_startup_godot_20260501_233529.log`.
- Touched-file forbidden-pattern check: PASS.
- Recurring non-blocking runtime error: the open Godot editor already owns MCP runtime port 7777.

Latest brighter-light validation:
- Godot 4.6.2 parse: PASS, exit 0; logs `logs/brighter_lights_parse_stdout_20260501_230809.log` and `logs/brighter_lights_parse_godot_20260501_230809.log`.
- Light flicker validation: PASS, `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 min_interval=28.0 bright_range=1.25-1.85 base=0.820 dim=0.082 bright=1.312 panel_base=1.100 panel_dim=0.132 panel_bright=1.760`; logs `logs/brighter_lights_flicker_stdout_20260501_230835.log` and `logs/brighter_lights_flicker_godot_20260501_230835.log`.
- Scene shadow regression: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; logs `logs/brighter_lights_shadows_stdout_20260501_230905.log` and `logs/brighter_lights_shadows_godot_20260501_230905.log`.
- Short normal startup: PASS, exit 0; logs `logs/brighter_lights_startup_stdout_20260501_230905.log` and `logs/brighter_lights_startup_godot_20260501_230905.log`.
- Touched-file forbidden-pattern check: PASS.
- Recurring non-blocking runtime error: the open Godot editor already owns MCP runtime port 7777.

Latest saved-scale/random-light-flicker validation:
- Godot 4.6.2 parse: PASS, exit 0; logs `logs/saved_monster_random_flicker_parse_stdout_20260501_225647.log` and `logs/saved_monster_random_flicker_parse_godot_20260501_225647.log`. The only warning was the existing nested `project.godot` under `res://godot后室新`.
- Monster saved scale validation: PASS, `MONSTER_SAVED_SCALE_VALIDATION PASS saved_scale=(0.953989, 0.387199, 0.688722) runtime_scale=(0.953989, 0.387199, 0.688722)`; logs `logs/saved_monster_scale_stdout_20260501_225809.log` and `logs/saved_monster_scale_godot_20260501_225809.log`.
- Light flicker validation: PASS, `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 min_interval=28.0 base=0.650 dim=0.065 panel_base=0.850 panel_dim=0.102`; logs `logs/random_light_flicker_validation_stdout_20260501_225714.log` and `logs/random_light_flicker_validation_godot_20260501_225714.log`.
- Monster AI regression: PASS, `MONSTER_AI_VALIDATION PASS state=WANDER flee_z=5.983 animation=road_creature_reference_skeleton|Walk`; logs `logs/saved_scale_monster_ai_stdout_20260501_225844.log` and `logs/saved_scale_monster_ai_godot_20260501_225844.log`.
- Scene shadow regression: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; logs `logs/random_flicker_shadows_stdout_20260501_225845.log` and `logs/random_flicker_shadows_godot_20260501_225845.log`.
- Short normal startup: PASS, exit 0; logs `logs/saved_scale_random_flicker_run_stdout_20260501_225845.log` and `logs/saved_scale_random_flicker_run_godot_20260501_225845.log`.
- Touched-file forbidden-pattern check: PASS.
- Recurring non-blocking runtime error: the open Godot editor already owns MCP runtime port 7777.

Latest ceiling-light flicker validation:
- Godot 4.6.2 parse: PASS, exit 0; logs `logs/light_flicker_parse_stdout_20260501_224532.log` and `logs/light_flicker_parse_godot_20260501_224532.log`. The only warning was the existing nested `project.godot` under `res://godot后室新`.
- Light flicker validation: PASS, `LIGHT_FLICKER_VALIDATION PASS lights=4 base=0.650 dim=0.065 panel_base=0.850 panel_dim=0.102`; logs `logs/light_flicker_validation_stdout_20260501_224801.log` and `logs/light_flicker_validation_godot_20260501_224801.log`.
- Scene shadow regression: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; logs `logs/light_flicker_shadows_stdout_20260501_224830.log` and `logs/light_flicker_shadows_godot_20260501_224830.log`.
- Short normal startup: PASS, exit 0; logs `logs/light_flicker_run_stdout_20260501_224830.log` and `logs/light_flicker_run_godot_20260501_224830.log`.
- Touched-file forbidden-pattern check: PASS.

Previous camera recenter validation, superseded by the free-orbit update:
- Godot 4.6.2 parse: PASS, exit 0; logs `logs/camera_recenter_parse_stdout_20260501_222106.log` and `logs/camera_recenter_parse_godot_20260501_222106.log`. The only warning was the existing nested `project.godot` under `res://godot后室新`.
- Camera recenter validation: PASS, `CAMERA_RECENTER_VALIDATION PASS stationary_offset=0.660 moving_offset=0.013`; logs `logs/camera_recenter_validation_stdout_20260501_222146.log` and `logs/camera_recenter_validation_godot_20260501_222146.log`.
- Player animation regression: PASS, `PLAYER_ANIMATION_VALIDATION PASS movement=mixamo_com idle=idle_generated`; logs `logs/camera_recenter_player_validation_stdout_20260501_222221.log` and `logs/camera_recenter_player_validation_godot_20260501_222221.log`.
- Monster AI regression: PASS, `MONSTER_AI_VALIDATION PASS state=WANDER flee_z=5.543 animation=road_creature_reference_skeleton|Walk`; logs `logs/camera_recenter_monster_validation_stdout_20260501_222221.log` and `logs/camera_recenter_monster_validation_godot_20260501_222221.log`.
- Short normal startup: PASS, exit 0; logs `logs/camera_recenter_run_stdout_20260501_222221.log` and `logs/camera_recenter_run_godot_20260501_222221.log`.
- Touched-file forbidden-pattern check: PASS.
- Recurring non-blocking runtime error: the open Godot editor already owns MCP runtime port 7777.

Latest monster flee-route validation:
- Godot 4.6.2 parse: PASS, exit 0; logs `logs/monster_escape_route_parse_stdout_20260501_221126.log` and `logs/monster_escape_route_parse_godot_20260501_221126.log`. The only warning was the existing nested `project.godot` under `res://godot后室新`.
- Monster AI validation: PASS, `MONSTER_AI_VALIDATION PASS state=WANDER`; logs `logs/monster_escape_route_validation_stdout_20260501_221155.log` and `logs/monster_escape_route_validation_godot_20260501_221155.log`.
- The new Room_D regression validates that the monster selects a portal escape route and makes progress toward P_CD or P_DA instead of fleeing into the north wall.
- Short normal startup: PASS, exit 0; logs `logs/monster_escape_route_run_stdout_20260501_221223.log` and `logs/monster_escape_route_run_godot_20260501_221223.log`.
- Touched-file forbidden-pattern check: PASS.
- Recurring non-blocking runtime error: the open Godot editor already owns MCP runtime port 7777.

Latest scene-light shadow validation:
- Godot 4.6.2 parse: PASS, exit 0; logs `logs/scene_shadows_parse_stdout_20260501_215655.log` and `logs/scene_shadows_parse_godot_20260501_215655.log`. The only warning was the existing nested `project.godot` under `res://godot后室新`.
- Shadow setup validation: PASS, `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; logs `logs/scene_shadows_validation_stdout_20260501_215746.log` and `logs/scene_shadows_validation_godot_20260501_215746.log`.
- Player animation regression: PASS, `PLAYER_ANIMATION_VALIDATION PASS movement=mixamo_com idle=idle_generated`; logs `logs/scene_shadows_player_validation_stdout_20260501_215818.log` and `logs/scene_shadows_player_validation_godot_20260501_215818.log`.
- Monster AI regression: PASS, `MONSTER_AI_VALIDATION PASS state=WANDER`; logs `logs/scene_shadows_monster_validation_stdout_20260501_215818.log` and `logs/scene_shadows_monster_validation_godot_20260501_215818.log`.
- Short normal startup: PASS, exit 0; logs `logs/scene_shadows_run_stdout_20260501_215818.log` and `logs/scene_shadows_run_godot_20260501_215818.log`.
- Touched-file forbidden-pattern check: PASS for implementation files. Documentation still contains the existing rule text mentioning `current_room` / `visited_rooms`, which is not implementation logic.
- Recurring non-blocking runtime error: the open Godot editor already owns MCP runtime port 7777.

Latest monster MVP validation:
- Monster model inspection: PASS, `guai1.glb` has 9 animations and a 58-bone skeleton; logs `logs/monster_model_inspect_stdout_20260501_212504.log` and `logs/monster_model_inspect_godot_20260501_212504.log`.
- Godot 4.6.2 parse: PASS, exit 0; logs `logs/monster_ai_parse_stdout_20260501_213852.log` and `logs/monster_ai_parse_godot_20260501_213852.log`. The only warning was the existing nested `project.godot` under `res://godot后室新`.
- Monster AI validation: PASS, `MONSTER_AI_VALIDATION PASS state=WANDER`; logs `logs/monster_ai_validation_stdout_20260501_213809.log` and `logs/monster_ai_validation_godot_20260501_213809.log`.
- Short normal startup: PASS, exit 0; logs `logs/monster_ai_run_stdout_20260501_213950.log` and `logs/monster_ai_run_godot_20260501_213950.log`.
- Touched-file forbidden-pattern check: PASS.

Latest idle retune validation:
- Player pose inspection: PASS, `PLAYER_CURRENT_ANIMATION name=idle_generated playing=true`, final idle `foot_delta=0.00`, `toe_delta=0.00`; logs `logs/idle_replace_final_pose_stdout_20260501_211124.log` and `logs/idle_replace_final_pose_godot_20260501_211124.log`.
- Godot 4.6.2 parse: PASS; logs `logs/idle_replace_final_parse_stdout_20260501_211057.log` and `logs/idle_replace_final_parse_godot_20260501_211057.log`.
- Player animation validation: PASS, `PLAYER_ANIMATION_VALIDATION PASS movement=mixamo_com idle=idle_generated`; logs `logs/idle_replace_final_validation_stdout_20260501_211152.log` and `logs/idle_replace_final_validation_godot_20260501_211152.log`.
- Player collision validation: PASS, `PLAYER_ANIMATION_COLLISION_VALIDATION PASS player_x=-2.533`; logs `logs/idle_replace_final_collision_stdout_20260501_211153.log` and `logs/idle_replace_final_collision_godot_20260501_211153.log`.
- Short normal startup: PASS; logs `logs/idle_replace_final_run_stdout_20260501_211218.log` and `logs/idle_replace_final_run_godot_20260501_211218.log`.
- Animation inspection: PASS, `idle_generated length=6.000`; logs `logs/idle_replace_final_inspect_stdout_20260501_211153.log` and `logs/idle_replace_final_inspect_godot_20260501_211153.log`.
- Touched-file forbidden-pattern check: PASS.
- Documentation sync check: PASS.

## Current Blocking Issue

No current global grime experiment blocker. The first reusable grime pass is isolated in `FourRoomMVP_grime_experiment.tscn`, validates as AO-derived, uses only small non-colliding structural-edge overlays, and has 9 true-alpha PNG variants. Remaining decision is user visual acceptance of grime strength/coverage before any base-scene or generator merge.

No current foreground cutout texture blocker. The wall-texture disappearance was caused by the cutout shader replacing the wall material without repeat-enabled texture sampling and without ShaderMaterial parameter copying. The local cutout now preserves texture, UV scale, UV offset, and normal texture for both the accepted base wall materials and the contact-AO experiment materials. Manual playtest is still needed to judge cutout radius/feather aesthetics.

No current contact-AO UV-scale blocker. The enlarged floor-tile look was caused by the experimental shader losing `uv1_scale`; the experiment now passes explicit floor/wall/door-frame UV scale into the shader and validates those parameters. Remaining decision is user visual acceptance before any base merge.

No current upright wall UV blocker. The active generated wall, wall-opening, wall-joint, ceiling-side, and door-frame UV rules now map vertical `v` upward, and validation rejects the old reversed vertical UV direction. Manual visual playtest is still needed to confirm the subjective wallpaper/stain direction in the editor/game viewport.

No current canonical scene object generation blocker. The remaining doorway inconsistency was caused by old direction-specific mesh generation and non-uniform door-frame scale. Wall openings and door frames now use canonical local U meshes, x/z direction is handled by rotation, and validation rejects non-identity scale or non-canonical local dimensions. Manual visual playtest is still needed because the Godot editor may show an unsaved `(*)` in-memory scene until reloaded from disk.

No current full clean rebuild blocker. The saved scene no longer contains `LevelRoot/Rooms`; all active geometry has been regenerated under `LevelRoot/Geometry`, room metadata is under `LevelRoot/Areas`, and Godot MCP plus automated validation confirm the split. Manual visual playtest is still needed because the already-open Godot editor can display an unsaved `(*)` in-memory version until the scene is reloaded from disk.

No current type-based wall generation blocker. Solid walls and wall openings are now generated through one wall-piece entry path, door frames use the same static visual layer rule, and all room static geometry is lit through one shared static layer rather than room-specific visual layers. Manual visual playtest is still needed to judge the subjective look, but the structural source of per-room wall lighting differences has been removed.

No current UV/tangent direction blocker. The floor visual triangle order has been corrected, generated vertical wall/opening/door-frame faces now use a shared tangent basis, and validation plus a desktop screenshot confirm the floor is visible instead of black. Manual playtest is still needed for final subjective wall-shadow consistency across all four rooms.

No current runtime visual-lighting unification blocker. The selected walls and floor already shared material assignments; the remaining mismatch was addressed globally by matching the foreground cutout shader's diffuse rule, reducing normal strength, adding a single low ambient `WorldEnvironment`, and enforcing those rules in validation. Manual visual playtest is still needed to judge the final subjective look in the editor/game viewport.

No current unified wall-generation blocker. Ordinary walls, wall joints, portal wall openings, ceilings, door frames, and floor visuals now validate against one generated mesh/material rule. Manual visual playtest is still needed to confirm the subjective look in the editor/game viewport, especially the previously dark inner wall face and the floor shadow readability under real ceiling lights.

No current material-lighting/shadow readability blocker. Wall, floor, door-frame, and ceiling materials now use the same Mobile diffuse rule, normal-map strength is restrained, and all four real room lights are brighter with lower shadow bias for more readable floor/actor contact shadows. Manual playtest is still needed for subjective brightness and shadow strength.

No current ceiling-light coverage blocker. All room lights now use `omni_range = 6.0` with slower falloff, while still casting real shadows and keeping the existing flicker behavior. Manual editor/gameplay visual check should confirm room corners and doorway-adjacent areas are no longer outside the lamp projection.

No current generated mesh render-rule blocker. Generated portal wall openings, door frames, and floor visual panels now share one render rule with UV/normal/tangent arrays and explicit material overrides. Manual visual playtest should confirm `WallOpening_P_DA` and the other generated portal walls no longer show black shading under the editor/game lighting.

No current seam/contact-detail rollback blocker. The active generator and baked scene no longer contain seam-grime nodes or references to `backrooms_seam_grime`; manual visual playtest should confirm the cleaner pre-grime look is restored.

No current regular floor visual blocker. The old two-strip visual floor has been replaced by four regular per-room visual panels with world-coordinate UVs, while the single continuous `Floor_WalkableCollision` remains in charge of movement physics. Manual visual playtest should confirm the square floor texture now reads aligned and regular.

No current foreground occlusion edge-smoothing blocker. Automated validation confirms local cutouts persist for the immediate clear frame and restore after the release delay while collisions stay active. Manual gameplay check is still needed for subjective timing.

No current mechanism archive blocker. `docs/MECHANICS_ARCHIVE.md` now records the current reusable systems and the update protocol for future accepted mechanics.

No current monster reverse-locomotion animation blocker. The automated check confirms forward local movement plays Walk/Run forward and backward local movement plays it in reverse. Manual visual tuning may still be needed if the reverse playback looks too mechanical with the current imported Run clip.

No current floor seam blocker. Runtime and baked scenes still use one continuous walkable collision hull, and the visual floor is now regular per-room panels instead of the old strip pair. Automated floor ray sampling plus an edge monster check passed.

No current monster panic/fall blocker. The monster now panic-detects nearby players even outside its forward cone, starts FLEE with a short speed boost, has reduced movement collision for door/wall clearance, uses floor snap, and recovers to the last safe floor position if it drops below the floor. Manual tuning may still be needed if the flee feels too fast in the small MVP rooms.

No current brighter-light blocker. Base room lights are brighter in both the baked scene and runtime builder, and bright flicker spikes now rise above base brightness while still restoring afterward. Manual visual tuning may still be needed if the room becomes too washed out under Mobile rendering.

No current monster saved-scale blocker. `GameBootstrap.gd` now preserves the editor-saved monster scale when moving it to the spawn marker, so manual size edits in `FourRoomMVP.tscn` should carry into demo runtime.

No current random-light-flicker blocker. The flicker is intentionally rare: after a randomized startup delay and a randomized cooldown, each frame only has a low probability chance to trigger one flicker burst.

No current ceiling-light flicker blocker. The flicker frequency and strength are tunable in `scripts/lighting/LightingController.gd`: `flicker_interval_min/max`, `flicker_steps_min/max`, `dim_energy_min/max`, and `bright_energy_min/max`.

No current free-orbit camera blocker. The behavior is now: mouse/touch yaw can orbit freely through 360 degrees, player movement does not trigger camera recentering, and pitch remains clamped for usability. Manual visual tuning may still be needed for `mouse_sensitivity`, `touch_sensitivity`, pitch limits, and camera distance.

No current monster flee-routing blocker. This is still not full navmesh pathfinding; it is an MVP route picker that uses the current room and connected portals as waypoints. It should reduce the visible "standing still against a wall" problem while keeping the behavior small enough for the current four-room demo.

No current scene-light shadow blocker. Shadows are property-validated in both the baked scene and runtime build path. Manual visual tuning may still be needed for shadow strength/readability because the project uses Mobile rendering and multiple room lights can soften or overlap shadows near doorways.

No current monster MVP blocker. The current behavior is intentionally simple: no pathfinding/navmesh, no attack, no damage, no door logic, and no multiplayer sync. It uses direct movement with collision response, forward FOV + raycast vision, flee-on-sight, random wander, and occasional idle look-around.

No current player-animation blocker. The current `zhujiao.glb` only contains one authored animation clip, so movement states share `mixamo_com` until separate walk/run/backpedal clips are provided. Idle now uses generated `idle_generated`: lower body and hips come from the model Rest Pose to keep both feet planted, upper body samples `mixamo_com` at `idle_pose_time=1.55`, and breathing/head-glance motion is layered on top. Root motion from the GLB is disabled so visual mesh movement stays aligned with the `CharacterBody3D` collision capsule.

No current Phase 3 blocker. Foreground occlusion validation passed:
- Current contents were backed up before testing.
- Godot 4.6.2 editor parse exited 0.
- Normal window scene startup exited 0.
- Automated Phase 3 validation exited 0 with `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1`.
- Door-frame occlusion tuning validation also exited 0 with `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`.
- Local cutout tuning validation also exited 0 with `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`.
- The occlusion test applied a local cutout material to the foreground wall mesh while keeping its collision enabled.
- The door-frame tuning test applied local cutout materials to `WallOpening_P_AB` and `DoorFrame_P_AB` together while keeping `Collision_Top` enabled.
- Current behavior no longer hides the whole mesh: validation now checks that blocking meshes stay visible, receive a cutout `ShaderMaterial`, then restore their original material override.
- Only runtime error hit was the existing GoPeak MCP runtime port 7777 being occupied by another Godot instance.

Historical camera/control status:

No current camera/control blocker. Third-person camera/control validation passed:
- Godot 4.6.2 editor parse exited 0.
- Normal window scene startup exited 0.
- No `CameraController.gd` or `PlayerController.gd` script errors were found.
- Only runtime error hit was the existing GoPeak MCP runtime port 7777 being occupied by another Godot instance.
- Latest camera tuning pass is also validated: close third-person framing remains, but yaw is now free 360-degree orbit and no longer recenters automatically.
- Latest lower-camera/backpedal pass is validated: full-character lower camera parameters are set, and `S` / down arrow moves backward while the body faces forward instead of sideways or turning around.
- Latest vertical look inversion pass is validated: mouse/touch vertical camera input is swapped and the scene still parses/runs without player or camera script errors.

Historical Phase 2 blocker status: GoPeak MCP runtime validation passed:
- Runtime connected.
- Player moved right by about 2.25m after injected input.
- Player collision blocked west wall at x≈-2.62.
- At that time, the old camera followed with offset about `(0, 5, 4)` and angle about 51.34 degrees; this has now been superseded by the third-person orbit camera.
- Screenshot saved and visually checked.
- Final runtime output had no errors.

- Integrated door-frame validation also passed:
- The old split nodes `DoorFrame_P_*_South/North/West/East/Header` are no longer present.
- The baked scene and runtime generator now use 4 `DoorFrame_P_*` U-shaped visual MeshInstances.
- Each frame stops at y=2.18, below the 2.55m wall top.
- The wall above each doorway is represented by 4 `WallHeader_P_*` StaticBody wall headers.
- Static checks, Godot parse, normal window run, and Godot MCP scene-tree inspection all passed.
- Documentation sync check also passed for root `docs/` and the execution package copy.
- Door-frame dimension sync passed: all four `DoorFrame_P_*` visuals now share the user-adjusted dimensions from `DoorFrame_P_AB`, with correct axis swap for x-axis doorways.
- Door-frame mesh topology sync passed: door frames are now generated from one U-profile extrusion, with old three-box saved mesh references removed from the scene.
- Wall-opening topology sync passed: the wall around each portal is now one `WallOpening_P_*` body, old visual/collision segment nodes are deleted, and collision is owned by the replacement body.
- Wall-opening editor selection fix passed: middle wall openings now expose selectable/saved child nodes in the scene tree instead of relying only on transient script-created children.
- Wall-opening/door-frame material alignment passed: generated U meshes now use lit light gray material, matching outer wall lighting/shadow behavior.
- Texture material pass passed: wall, floor, door-frame texture assets and material resources are wired into the baked scene and runtime builder; generated U meshes now include UVs.
- Ceiling/light pass passed: each room has a separate ceiling slab, ceiling-light panel, and independent `OmniLight3D`; Godot parse and short window startup both exited 0.
- Latest wall-connection fix: added missing northwest return wall and 10 explicit wall-joint filler blocks; static checks, Godot parse, and normal window run checks all passed.

Quick check helper scripts:
- `open_latest_scene.bat` opens `res://scenes/mvp/FourRoomMVP.tscn` in the Godot 4.6.2 editor from disk.
- `run_latest_demo.bat` runs the current main scene directly and keeps a console window open after exit.
- Godot console headless parse check for the open-scene command exited 0; latest log: `logs/bat_command_parse_20260501_120626.log`.
- Normal window run check for the `run_latest_demo.bat` command path exited 0; latest logs: `logs/run_latest_demo_window_check_stdout_20260501_121542.log` and `logs/run_latest_demo_window_check_godot_20260501_121542.log`.
- Headless run check is not reliable on this setup: Godot 4.6.2 crashed in headless mode with signal 11.

## Next Step

Manual visual review for global grime experiment:
- Run `run_grime_experiment.bat` or open `scenes/mvp/experiments/FourRoomMVP_grime_experiment.tscn`.
- Check the base wall-floor edge, ceiling-wall edge, and only some inner wall-wall corners. Expected result: a very light old/unclean feel without black outlines, large whole-wall stains, blood, dramatic damage, or repeated identical corners.
- If accepted, the next implementation step is to promote the `GrimeOverlayBuilder` rules into the normal room-generation flow. If not accepted, tune only the experiment copy and PNG generation first.

Manual visual review for foreground cutout:
- Run the current demo or the contact-AO experiment and put the camera behind a wall so the player is occluded.
- Expected result: only the player-area oval/soft cutout becomes transparent; the rest of the wall keeps the same wallpaper texture instead of turning into a flat solid color.
- If the texture is accepted, only tune cutout size/feather subjectively; do not switch back to whole-wall hiding.

Manual visual review for the contact-AO experiment:
- Open or run `scenes/mvp/experiments/FourRoomMVP_contact_ao_experiment.tscn`.
- Check that floor tile density matches the accepted base scene and that the AO/contact darkening is subtle at wall bases, wall corners, ceiling turns, and door-frame edges.
- If accepted, merge the shader/material values into the base generator/material flow. If not accepted, keep tuning only the experiment copy.

Manual visual playtest for the door-frame inset and pale floor pass:
- Run `run_latest_demo.bat` or reload `scenes/mvp/FourRoomMVP.tscn` from disk.
- Check each `DoorFrame_P_*` from both sides. Expected result: the outer frame edge covers/alines with the wall opening edge without leaving a visible gap, while the inner frame edge is inset from the wall-opening U edge; there should be no striped coplanar overlap at the vertical/horizontal doorway edge.
- Check floor color under normal room lights. The source tile is now pale white/light beige, but the scene's warm Backrooms lights will still tint it yellow in play. If the floor still reads too yellow, the next grounded adjustment should tune floor material color or room light warmth, not distort the tile UV/grid.
- Screenshot evidence from this pass: `artifacts/screenshots/four_room_doorframe_20260503 205320.png`.

Visual experiment workflow for future polish:
- Before changing accepted scene/material behavior, copy the current baseline into an experiment variant.
- Apply new AO/contact-shadow/edge-darkening ideas only to the copy first.
- Use subtle ambient-occlusion style darkening at wall bases, wall corners, door-frame edges, and ceiling turns; do not use black line art, large dark strips, transparent overlay sheets, or one-off per-instance fixes.
- Capture screenshots and run targeted validation before merging values back into the base generator/material resources.

Manual visual playtest for upright wall UVs:
- Reload `scenes/mvp/FourRoomMVP.tscn` from disk or run `run_latest_demo.bat`.
- Check ordinary walls, wall joints, portal wall openings, and door frames from player height.
- Expected result: wallpaper/stain direction reads upright across all vertical surfaces. If the wall still feels mirrored horizontally, the next fix should be a shared U-axis rule, not per-wall edits.

Manual visual playtest for canonical scene object generation:
- Reload `scenes/mvp/FourRoomMVP.tscn` from disk or run `run_latest_demo.bat`.
- Compare the two doorway directions: `DoorFrame_P_AB` / `WallOpening_P_AB` and `DoorFrame_P_BC` / `WallOpening_P_BC`.
- Expected result: same local U-shape proportions, same material/lighting rule, no stretched side, no one-sided odd trim, and no direction-specific visual mismatch. Differences should be only placement/rotation.
- Future scene additions should follow the same standard: one generator/module per object type, instances adjusted by specs/data and transforms only.

Manual visual playtest for the full clean rebuild:
- If the editor tab still shows `(*) FourRoomMVP.tscn`, close that scene or reload it from disk before judging; otherwise Godot may keep showing the old unsaved in-memory scene.
- Use `open_latest_scene.bat` to open the saved scene from disk, or `run_latest_demo.bat` to run the demo.
- In the scene tree, `LevelRoot` should contain `Geometry` and `Areas`, not `Rooms`.
- Select wall, floor, ceiling, and door-frame nodes under `LevelRoot/Geometry`. They are rebuilt construction pieces from one generator path. `LevelRoot/Areas` should contain only four metadata room nodes and no Mesh/Collision children.
- If any visual issue remains, fix through the shared generator/material/light rules rather than editing one old room piece.

Manual visual playtest for type-based wall generation:
- Run `run_latest_demo.bat` or open `open_latest_scene.bat`.
- Compare ordinary solid walls, `WallJoint_*` fillers, `WallOpening_P_*` wall bodies, and `DoorFrame_P_*` trim. The wall bodies should no longer differ because they belong to different rooms.
- In the Inspector, all static room visuals should either omit `layers` because they are on the default layer or show layer 1; all four `CeilingLight_Room_*` masks should be `257`.
- If a wall still appears different, inspect actual light/shadow occlusion or foreground cutout state first; do not reintroduce room-specific wall visual layers.

Manual visual playtest for UV/tangent direction fix:
- Run `run_latest_demo.bat` or use the already-open Godot editor scene.
- Check the floor in the room where it previously appeared black; it should render as the pale tile material and receive player/monster shadows from the room light.
- Compare x-facing and z-facing portal wall/opening faces (`WallOpening_P_AB`, `WallOpening_P_BC`, `WallOpening_P_CD`, `WallOpening_P_DA`). They now use one generated vertical tangent basis, so normal-map lighting should no longer look like a different wall rule just because the wall direction changed.
- If a wall still looks different, first verify whether it is real light direction/shadow occlusion rather than material or UV/tangent mismatch.

Manual visual playtest for runtime visual-lighting unification:
- Use `run_latest_demo.bat` or the already-open Godot editor scene.
- Revisit the two inner wall faces from the latest screenshots and compare them with ordinary wall segments and `WallJoint_*` blocks. They now share material, mesh rule, cutout shader light mode, and ambient baseline.
- Check the floor under the player/monster. It should be lighter and more readable, while character/monster shadows still come from the real ceiling `OmniLight3D` lights.
- If a face still looks different, first identify whether it is real shadow direction, active foreground cutout state, or material mismatch. Keep fixes in shared lighting/material rules, not one-off wall color edits.

Manual visual playtest for unified generated wall/floor rule:
- Run `run_latest_demo.bat` or use the already-open editor scene.
- Check the wall shown in the latest screenshot, the center `WallJoint_Center`, and all portal wall faces. They should use the same texture density/material response rule as the rest of the walls, not a darker special case.
- Check the floor under and around the player/monster under a ceiling light. Shadows now use lower bias and full opacity from the real `OmniLight3D` lights; no fake blob shadow or transparent plane was added.
- If one face still looks different, first inspect whether it is actual light/shadow direction versus material mismatch. Do not hand-brighten one wall mesh unless a later art direction explicitly calls for it.

Manual visual playtest for unified wall/floor lighting:
- Run `run_latest_demo.bat`.
- Stand near the two inner portal walls shown in the latest screenshot and compare them with ordinary outer walls; they should no longer read as a different dark wall rule.
- Check the floor under/around the player and monster. Shadows should come from ceiling `OmniLight3D` lights and be more readable, without fake blob decals or transparent dark planes.
- If the scene is now too bright overall, tune `CEILING_LIGHT_ENERGY` in `scripts/core/SceneBuilder.gd` and rebake; keep the material rule shared instead of hand-tuning individual wall meshes.

Manual visual playtest for ceiling-light coverage:
- Open `open_latest_scene.bat` or run `run_latest_demo.bat`.
- Check all four rooms from floor height and third-person view, especially corners, wall bases, and doorway-adjacent floor/wall areas.
- Confirm the lamp projection reaches the full room footprint without turning the whole scene flat or overexposed.
- If coverage is now acceptable but the scene feels too bright, tune `light_energy` separately from `omni_range`; do not reduce coverage radius back to 4.2m.

Manual visual playtest for generated wall render rules:
- Open `open_latest_scene.bat` or run `run_latest_demo.bat`.
- Select/check `WallOpening_P_DA/Mesh`, `WallOpening_P_BC/Mesh`, `WallOpening_P_CD/Mesh`, and `WallOpening_P_AB/Mesh`.
- Confirm their wall texture, brightness, and normal-map lighting read consistently with ordinary `Wall_*` BoxMesh walls.
- If a wall still appears dark only from one side or under a specific light, treat the next investigation as lighting/shadow/normal direction, not material-resource mismatch.

Manual visual playtest for clean room edges:
- Open `open_latest_scene.bat` or run `run_latest_demo.bat`.
- Check wall-floor edges, ceiling-wall edges, and door-frame/wall joins.
- Confirm the added dirty bands/contact traces are gone and the scene reads like the cleaner pre-grime version.
- Confirm there are no hidden leftover seam meshes in the scene tree under walls, ceilings, wall openings, or door frames.

Manual visual playtest for regular floor panels:
- Open `open_latest_scene.bat` or run `run_latest_demo.bat`.
- Check the floor from Room_A -> Room_B -> Room_C -> Room_D and confirm the square floor texture scale stays aligned across room boundaries.
- Confirm there are no old south/north strip overlaps, no irregular visual floor join, and no visible floor gap at portals.
- Room_D remains intentionally narrower than Room_A; the fix is that its floor is now a regular room panel, not a shifted strip segment.

Manual visual playtest for foreground occlusion edge smoothing:
- Run `run_latest_demo.bat`.
- Stand where a foreground wall hides the player, then move forward/back so the camera/player line crosses the wall boundary.
- Confirm the wall no longer flashes back for one frame as the camera crosses the edge.
- If it feels like the cutout lingers too long, tune `cutout_release_delay` in `scripts/camera/ForegroundOcclusion.gd`.

For future accepted mechanics in this verification room:
- Update `docs/MECHANICS_ARCHIVE.md` with files, behavior, tuning knobs, validation, known limits, and reuse notes.
- Mirror the archive and progress/decision updates under `四房间MVP_Agent抗遗忘执行包/docs/`.

Manual visual playtest for monster locomotion animation:
- Run `run_latest_demo.bat`.
- Approach the monster from the side or behind and watch the first panic step plus door turns.
- Confirm it turns and runs when possible, and if it briefly backs up, the leg motion reverses instead of forward-running in place.
- If it still looks too mechanical, tune `reverse_locomotion_dot`, `flee_turn_speed`, and `run_animation_speed` in `scripts/monster/MonsterController.gd`.

Manual visual playtest for floor and monster panic:
- Run `run_latest_demo.bat`.
- Chase the monster through Room_D and doorways; confirm it does not drop through the floor or snag at the wall/door edge.
- Approach the monster from behind or the side at close range; it should immediately switch to a more startled fast flee.
- If flee feels too fast, tune `flee_speed`, `flee_start_speed`, `flee_acceleration`, and `run_animation_speed` in `scripts/monster/MonsterController.gd`.

Manual visual playtest for brighter ceiling lights:
- Run `run_latest_demo.bat`.
- Confirm normal room brightness is easier to read but not overexposed.
- Wait for a rare flicker and confirm the bright part visibly flashes brighter than the normal light level, then restores.
- If it is too bright, tune `light_energy` in `FourRoomMVP.tscn` / `SceneBuilder.gd`, `emission_energy_multiplier` in `materials/backrooms_ceiling_light.tres`, or `bright_energy_min/max` in `scripts/lighting/LightingController.gd`.

Manual visual playtest for saved monster scale:
- Run `run_latest_demo.bat`.
- Confirm the runtime monster size matches the editor-saved size shown in `FourRoomMVP.tscn`.
- If the size still feels wrong, adjust the `MonsterRoot/Monster` instance scale in the editor and save the scene; runtime placement should preserve it.

Manual visual playtest for random light flicker:
- Run `run_latest_demo.bat`.
- Wait in a room long enough to check that flickers are rare and irregular rather than fixed-frequency.
- If it is still too frequent, lower `flicker_chance_per_second` or raise `flicker_interval_min/max` in `scripts/lighting/LightingController.gd`.

Manual visual playtest for ceiling-light flicker:
- Run `run_latest_demo.bat`.
- Stay in a room for 10-30 seconds and watch for a rare short sequence of dim/bright flickers.
- Confirm the room lighting and the ceiling light panel both flicker, then restore.
- If it happens too often or too strongly, tune the `LightingController.gd` flicker interval and dim/bright energy ranges.

Manual visual playtest for free third-person camera:
- Run `run_latest_demo.bat`.
- Click to capture mouse, then drag left/right through multiple full angles. The camera should orbit freely and never snap back because of movement.
- Move with `WASD` / arrow keys and confirm movement remains camera-relative. `S` / down arrow should still backpedal rather than turn.
- If orbit feels too fast/slow, tune `mouse_sensitivity`, `touch_sensitivity`, `min_pitch_degrees`, `max_pitch_degrees`, or `distance` in `scripts/camera/CameraController.gd`.

Manual visual playtest for monster flee routing:
- Run `run_latest_demo.bat`.
- Enter Room_D and approach the monster from the south side.
- Confirm it tries to run toward P_CD or P_DA and cross into another room instead of pushing into the north/west wall.
- If it chooses an odd door too often, tune `flee_repath_interval`, `flee_portal_exit_distance`, and route scoring weights in `MonsterController.gd`.

Manual visual playtest for scene-light shadows:
- Run `run_latest_demo.bat`.
- Check the player shadow under the Room_A ceiling light.
- Walk into nearby rooms and confirm the shadow follows scene lights instead of appearing as a fake decal.
- Check the monster in Room_D and confirm its body casts onto the floor from the Room_D ceiling light.
- If the shadows are too weak/harsh, tune ceiling `OmniLight3D` energy/range/shadow settings after confirming mobile performance.

Manual visual playtest for the monster MVP:
- Run `run_latest_demo.bat`.
- Find the monster in Room_D near `Spawn_Monster_D`.
- Check whether its scale reads correctly beside the player.
- Approach from in front and confirm it flees instead of approaching.
- Approach from behind or far away and confirm it keeps wandering/occasionally stopping.
- Tune `wander_speed`, `flee_speed`, `vision_distance`, `vision_fov_degrees`, `flee_memory_time`, and `idle_look_degrees` in `scripts/monster/MonsterController.gd` if the feel is wrong.

Manual visual playtest for the player animation:
- Run `run_latest_demo.bat`.
- Check whether `mixamo_com` now stays glued to the collision body while walking/sprinting/backpedaling, with no visual floating or wall pass-through.
- Stop movement and check that the player blends into `idle_generated`, both feet appear planted, breathing is visible but not exaggerated, and the occasional head left/right glance reads naturally.
- If the motion looks wrong, replace or re-export `zhujiao.glb` with separate idle/walk/run/backpedal animation clips, then remap the exported clip names in `PlayerController.gd`.

Manual visual playtest Phase 3 in the Godot editor or with `run_latest_demo.bat`:
- Move the camera/player near foreground walls and ceilings.
- Confirm the player remains visible while collisions still block movement.
- Tune the occluder group or hit list if a wall/ceiling hides too aggressively or flickers.
- After visual acceptance, continue the remaining Phase 4 polish such as exterior VOID treatment and light/material tuning.
## 2026-05-04 VSCode grime PNG preview diagnosis

Current objective:
- Diagnose why the generated grime PNGs appear invisible or hard to see in VSCode.

Current progress:
- Confirmed `artifacts/screenshots/grime_texture_contact_sheet_20260504.png` exists and is a valid RGB preview sheet.
- Confirmed all 9 grime source PNGs exist under `materials/textures/grime/` and are valid RGBA true-alpha PNGs.
- Confirmed no project `.vscode/settings.json` file is hiding the image folders.
- Root cause: the source grime PNGs are intentionally transparent and subtle. Their maximum alpha ranges from 92 to 140 out of 255, so VSCode's direct image preview can make them look nearly blank depending on preview background and zoom.

Files changed:
- `CURRENT_STATE.md`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- `Get-ChildItem artifacts/screenshots -Filter '*grime*'`
- `Get-ChildItem materials/textures/grime -Filter '*.png'`
- Python/Pillow PNG validation for contact sheet and grime source textures.

Validation result: PASS

Current blocking issue:
- None for file validity. Visual strength remains a separate tuning issue.

Next step:
- Use the RGB contact sheet for human review, or create/refresh opaque-background preview sheets whenever transparent grime assets are generated.

## 2026-05-04 Codex/VSCode inline image render clarification

Current objective:
- Diagnose the user's clarification that the image is not merely faint, but appears as a broken image placeholder in the Codex/VSCode chat panel.

Current progress:
- Rechecked the preview image file and generated an embedded HTML preview at `artifacts/screenshots/grime_texture_contact_sheet_20260504_preview.html`.
- Copied the same PNG to a pure ASCII path: `C:\Users\sigeryang\codex_image_preview\grime_texture_contact_sheet_20260504.png`.
- The ASCII-path image renders through the local image viewer tool, so the PNG itself is valid.
- If the user still sees a broken image placeholder inside the chat panel, the failure is in the Codex/VSCode inline image rendering layer, not in the generated PNG.

Files changed:
- `CURRENT_STATE.md`
- `artifacts/screenshots/grime_texture_contact_sheet_20260504_preview.html`
- `open_grime_texture_preview.bat`

Commands run:
- Copied the preview PNG to `C:\Users\sigeryang\codex_image_preview\`.
- Created a base64-embedded HTML preview for reliable browser viewing.
- Viewed the ASCII-path PNG through the local image viewer tool.

Validation result: PASS

Current blocking issue:
- Codex/VSCode chat may still fail to render inline tool images for the user.

Next step:
- Use `open_grime_texture_preview.bat` or open the HTML preview directly when reviewing generated transparent textures.

## 2026-05-04 Image2 grime 50 percent alpha pass

Current objective:
- Make the grime visible enough for review by using image2-generated natural stain shapes and approximately 50% maximum texture alpha.

Current progress:
- Terminated two leftover Godot headless screenshot processes from an interrupted screenshot command.
- Generated an image2 grime atlas and stored copies under `materials/textures/grime/source/`.
- Archived the earlier procedural grime PNGs under `materials/textures/grime/archive/`.
- Added `scripts/tools/extract_image2_grime_textures.py` to extract the 3x3 image2 atlas into reusable true-alpha PNGs.
- Replaced all 9 grime PNGs under `materials/textures/grime/` with image2-derived variants.
- Updated `scripts/visual/GrimeOverlayBuilder.gd` so overlay material alpha is `1.0`; the PNG alpha now carries the requested strength instead of being multiplied down twice.
- Updated `scripts/tools/ValidateGrimeExperiment.gd` to validate full-image alpha maxima near the 50% pass.
- Updated `open_grime_texture_preview.bat` to open the latest image2 preview HTML.
- Re-baked `scenes/mvp/experiments/FourRoomMVP_grime_experiment.tscn`.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md`
- `materials/textures/grime/*.png`
- `materials/textures/grime/source/image2_grime_atlas_20260504_005000.png`
- `materials/textures/grime/archive/`
- `artifacts/screenshots/grime_texture_image2_contact_sheet_20260504_005000.png`
- `artifacts/screenshots/grime_texture_image2_contact_sheet_20260504_005000.html`
- `open_grime_texture_preview.bat`
- `scripts/tools/extract_image2_grime_textures.py`
- `scripts/tools/ValidateGrimeExperiment.gd`
- `scripts/visual/GrimeOverlayBuilder.gd`
- `scenes/mvp/experiments/FourRoomMVP_grime_experiment.tscn`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- `Get-CimInstance Win32_Process` to identify interrupted Godot screenshot processes.
- `Stop-Process -Id 29184,57528 -Force`
- `python scripts\tools\extract_image2_grime_textures.py --atlas ... --timestamp 20260504_005000`
- Godot bake: `--headless --path . --script res://scripts/tools/BakeGrimeExperiment.gd`
- Godot validation: `--headless --path . --script res://scripts/tools/ValidateGrimeExperiment.gd`
- Synced `docs/PROGRESS.md` and `docs/DECISIONS.md` to the execution package mirror.

Validation result: PASS

Current blocking issue:
- No automated blocker. Needs user visual review in the grime experiment before merging into the base scene.

Next step:
- Open `open_grime_texture_preview.bat` to inspect the new texture sheet, then run `run_grime_experiment.bat` for in-scene visual review if the texture strength is acceptable.

## 2026-05-04 Procedural maze fixed-layout pipeline test

Current objective:
- Build a stable Backrooms procedural maze generation pipeline and first fixed-layout test scene without modifying `scenes/mvp/FourRoomMVP.tscn`.

Current progress:
- Added module metadata registry at `data/proc_maze/module_registry.json`.
- Added module placeholder scenes under `scenes/proc_maze/modules/`.
- Added graph-first pipeline scripts: `ModuleRegistry.gd`, `MapGraphGenerator.gd`, `MapValidator.gd`, `ProcMazeSceneBuilder.gd`, `SceneValidator.gd`, `DebugView.gd`, and `TestProcMazeMap.gd`.
- Added tools: `BakeTestProcMazeMap.gd`, `ValidateTestProcMazeMap.gd`, and `CaptureTestProcMazeMapLayout.gd`.
- Added test scene `scenes/tests/Test_ProcMazeMap.tscn`.
- Added direct run helper `run_proc_maze_test.bat`.
- Fixed-layout test uses seed `2026050401` and generator version `proc_maze_fixed_layout_v0.1`.
- Output counts: 37 modules, 18 main-path nodes, 10 branches, 4 loops, 6 dead ends, 5 large/hub rooms, 3 special reserved rooms, 37 active ceiling lights.
- The scene is generated from module footprints and graph connectors; no arbitrary wall placement is stored as hand-authored scene design.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `data/proc_maze/module_registry.json`
- `scenes/proc_maze/modules/*.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scripts/proc_maze/*.gd`
- `scripts/tools/BakeTestProcMazeMap.gd`
- `scripts/tools/ValidateTestProcMazeMap.gd`
- `scripts/tools/CaptureTestProcMazeMapLayout.gd`
- `run_proc_maze_test.bat`
- `artifacts/screenshots/test_proc_maze_layout.png`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- Godot parse: `--headless --path . --quit`
- Godot bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeMap.gd`
- Godot validation: `--headless --path . --script res://scripts/tools/ValidateTestProcMazeMap.gd`
- Godot layout capture: `--headless --path . --script res://scripts/tools/CaptureTestProcMazeMapLayout.gd`
- Godot scene startup: `--headless --path . --scene res://scenes/tests/Test_ProcMazeMap.tscn --quit-after 10`
- Forbidden-pattern scans for old visibility masks, room-specific conditionals, visited-room logic, and alpha/blend usage.

Validation result: PASS

Validation evidence:
- `logs/proc_maze_bake_20260504_020652.log`
- `logs/proc_maze_validate_20260504_020738.log`
- `logs/proc_maze_layout_capture_20260504_021812.log`
- `logs/proc_maze_scene_startup_20260504_022603.log`
- Layout screenshot: `artifacts/screenshots/test_proc_maze_layout.png`

Current blocking issue:
- Headless 3D viewport screenshot script `CaptureTestProcMazeMapScreenshot.gd` timed out and was stopped; topology screenshot is currently generated via direct graph image capture instead.
- Headless render metrics report `fps=1.0`, `draw_calls=0`; real editor/window metrics still need a normal runtime check if exact draw calls are required.

Next step:
- User visual acceptance of `run_proc_maze_test.bat` / `scenes/tests/Test_ProcMazeMap.tscn`.
- After fixed-layout acceptance, implement the random topology generator using the same registry, validator, scene builder, and debug view. Do not skip directly to random generation before the fixed layout is approved.

## 2026-05-04 Procedural maze macro loop experience pass

Current objective:
- Make the fixed-layout procedural map's main macro loop read clearly in player experience, not only in top-down topology, while reducing patch-like connector chunks in the right-middle area.

Current progress:
- Updated fixed generator version to `proc_maze_fixed_layout_v0.5_macro_loop_experience`.
- Made `N05` the explicit macro split A and `N12` the explicit macro merge B by changing both to the new `hub_room_partitioned` module.
- Removed the near-split route-A/route-B cross connection and moved the pre-split small loop return before `N05`, so `N05` now has one inbound and two route exits.
- Reworked the lower macro route into a compound room arc using `large_room_with_side_chamber`, `large_room_split_ew`, `normal_room`, and L-shaped room modules instead of tiny patch connectors.
- Kept the upper macro route corridor-biased with long/narrow/L/offset corridor modules.
- Added `hub_room_partitioned` module metadata and shared internal partition generation.
- Strengthened macro-loop validation: no internal route cross-edge, split degree exactly 3, merge degree exactly 3, route A corridor pressure, route B expanded-room count, and route B compound-room count.
- Rebaked both playable and no-ceiling preview test scenes.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- `四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md`
- `data/proc_maze/module_registry.json`
- `scenes/proc_maze/modules/hub_room_partitioned.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `scripts/proc_maze/MapGraphGenerator.gd`
- `scripts/proc_maze/MapValidator.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/proc_maze/SceneValidator.gd`
- `artifacts/screenshots/test_proc_maze_layout.png`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- Godot parse: `--headless --path . --quit`
- Godot bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeMap.gd`
- Godot structure validation: `--headless --path . --script res://scripts/tools/ValidateTestProcMazeMap.gd`
- Godot playable validation: `--headless --path . --script res://scripts/tools/ValidateProcMazePlayable.gd`
- Godot no-ceiling bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeNoCeilingPreview.gd`
- Godot no-ceiling validation: `--headless --path . --script res://scripts/tools/ValidateProcMazeNoCeilingPreview.gd`
- Godot layout capture: `--headless --path . --script res://scripts/tools/CaptureTestProcMazeMapLayout.gd`
- Godot playable startup: `--headless --path . --quit-after 5 res://scenes/tests/Test_ProcMazeMap.tscn`
- Godot no-ceiling startup: `--headless --path . --quit-after 5 res://scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- Forbidden-pattern scans for negative/mirrored scale, room-specific names, fake corridors, transparent/fade patterns, and mask usage.

Validation result: PASS

Validation evidence:
- `logs/proc_maze_macro_experience_parse_20260504_151000.log`
- `logs/proc_maze_macro_experience_bake_20260504_151030.log`
- `logs/proc_maze_macro_experience_validate_structure_20260504_151040.log`
- `logs/proc_maze_macro_experience_validate_playable_20260504_151050.log`
- `logs/proc_maze_macro_experience_no_ceiling_bake_20260504_151100.log`
- `logs/proc_maze_macro_experience_no_ceiling_validate_20260504_151110.log`
- `logs/proc_maze_macro_experience_layout_capture_20260504_151120.log`
- `logs/proc_maze_macro_experience_startup_playable_20260504_151130.log`
- `logs/proc_maze_macro_experience_startup_no_ceiling_20260504_151140.log`
- Layout screenshot: `artifacts/screenshots/test_proc_maze_layout.png`

Current metrics:
- seed `2026050401`
- total rooms `38`
- main path `18`
- branches `10`
- loop count `4`
- macro loops `1`
- macro cycle length `14`
- largest simple cycle length `14`
- macro route A length `8`
- macro route B length `8`
- small loops `2`
- dead ends `4`
- large rooms `6`
- internal large rooms `3`
- hubs `3`
- narrow corridors `9`
- normal corridors `7`
- normal rooms `14`
- large width spaces `5`
- hub width spaces `3`
- overlap `false`
- door to wall `false`

Current blocking issue:
- No automated blocker. Needs in-editor/player visual review to judge whether the split A and merge B are now readable enough from the third-person camera.

Next step:
- Open `run_proc_maze_test.bat` and inspect the main macro loop from the player perspective, especially the `N05` split, the upper corridor route, the lower compound-room route, and the `N12` merge.

## 2026-05-04 Procedural maze space-type refactor pass

Current objective:
- Reduce patch-like small connector chains in the fixed proc-maze map.
- Make spaces read as clear types: true corridors, L-shaped rooms, compound large rooms, hub rooms, and area anchor rooms.
- Keep node count from increasing and preserve the existing wall/opening/frame/material/AO/light/player systems.

Current progress:
- Updated fixed generator version to `proc_maze_fixed_layout_v0.6_space_type_refactor`.
- Reduced total generated spaces from 38 to 36 by removing the old `B19` and `B21` short-connector chain.
- Replaced the pre-split branch chain with:
  - `B18` as `large_room_offset_inner_door`, a compound area-0 anchor room.
  - `B20` as a notched `room_wide`, a wider room connector rather than a short square patch.
- Changed several dead-end or side rooms from ordinary `normal_room` to stronger `room_wide` modules: `B23`, `B32`, and `B33`.
- Changed the area-2 special loop connector `B29` from a long straight corridor to `corridor_offset`, reducing overuse of long hallway rectangles.
- Superseded the earlier L-room internal baffle pass: `room_l_shape` now relies on occupied-cell L footprints and generated boundary walls only, because freestanding baffles created non-passable slits.
- Offset the internal doorway gaps in `large_room_split_ns` and `large_room_split_ew` so compound large rooms do not create straight external-door-to-internal-door sightlines.
- Strengthened validation:
  - ordinary rectangular room count now includes `normal_room`, not only the unused `plain_rect` kind;
  - ordinary rectangular rooms must stay below 35 percent;
  - declared routes fail if 3 ordinary rectangles appear in a row;
  - declared routes fail if 3 short connector spaces appear in a row;
  - each area must contain an anchor room, not only a generic recognizable corridor feature;
  - true long corridor count is capped at 5.
- Rebaked both playable and no-ceiling preview test scenes.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md`
- `scripts/proc_maze/MapGraphGenerator.gd`
- `scripts/proc_maze/MapValidator.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/proc_maze/SceneValidator.gd`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `artifacts/screenshots/test_proc_maze_layout.png`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- Godot parse: `--headless --path . --quit`
- Godot bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeMap.gd`
- Godot structure validation: `--headless --path . --script res://scripts/tools/ValidateTestProcMazeMap.gd`
- Godot playable validation: `--headless --path . --script res://scripts/tools/ValidateProcMazePlayable.gd`
- Godot no-ceiling bake: `--headless --path . --script res://scripts/tools/BakeTestProcMazeNoCeilingPreview.gd`
- Godot no-ceiling validation: `--headless --path . --script res://scripts/tools/ValidateProcMazeNoCeilingPreview.gd`
- Godot layout capture: `--headless --path . --script res://scripts/tools/CaptureTestProcMazeMapLayout.gd`
- Godot playable startup: `--headless --path . --quit-after 5 res://scenes/tests/Test_ProcMazeMap.tscn`
- Godot no-ceiling startup: `--headless --path . --quit-after 5 res://scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- Forbidden-pattern scans for negative/mirrored scale, room-specific names, fake corridors, transparent/fade patterns, and mask usage.

Validation result: PASS

Validation evidence:
- `logs/proc_maze_space_refactor_parse_20260504_160000.log`
- `logs/proc_maze_space_refactor_bake_20260504_160020.log`
- `logs/proc_maze_space_refactor_validate_structure_20260504_160030.log`
- `logs/proc_maze_space_refactor_validate_playable_20260504_160040.log`
- `logs/proc_maze_space_refactor_no_ceiling_bake_20260504_160050.log`
- `logs/proc_maze_space_refactor_no_ceiling_validate_20260504_160100.log`
- `logs/proc_maze_space_refactor_layout_capture_20260504_160110.log`
- `logs/proc_maze_space_refactor_startup_playable_20260504_160120.log`
- `logs/proc_maze_space_refactor_startup_no_ceiling_20260504_160130.log`
- Layout screenshot: `artifacts/screenshots/test_proc_maze_layout.png`

Current metrics:
- seed `2026050401`
- total rooms `36`
- main path `18`
- branches `8`
- loop count `4`
- macro loops `1`
- macro cycle length `14`
- largest simple cycle length `14`
- macro route A length `8`
- macro route B length `8`
- small loops `2`
- dead ends `4`
- long corridors `5`
- L-turn corridors `2`
- L-shaped rooms `4`
- internally partitioned large rooms `4`
- hubs `3`
- ordinary rectangular rooms `5`
- special rooms `2`
- narrow corridors `8`
- normal corridors `5`
- overlap `false`
- door to wall `false`

Current blocking issue:
- No automated blocker. This is still a spatial-feel pass, so final acceptance needs player-view inspection.

Next step:
- Run `run_proc_maze_test.bat` and check whether the pre-split branch, L-shaped rooms, compound large rooms, and macro loop now read as memorable spaces instead of small patch connectors.

## 2026-05-04 - No-Slit Ambient Pass

Current objective:
- Remove meaningless non-passable narrow slits from generated spaces.
- Make no-direct-light areas visibly darker by reducing world ambient.

Current progress:
- Removed the extra freestanding internal baffles from `room_l_shape` generation. L-shaped rooms now use occupied-cell L footprints and boundary walls for turn occlusion.
- Increased internal large-room split/offset passage gaps to `INTERNAL_PASSAGE_WIDTH = 1.60`.
- Added a `SceneValidator` regression guard: an L-shaped room fails if it owns any internal wall.
- Lowered shared world ambient energy from `0.10` to `0.07`.
- Rebaked MVP and both proc-maze test scenes.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md`
- `scripts/core/SceneBuilder.gd`
- `scripts/tools/ValidateSceneShadows.gd`
- `scripts/proc_maze/MapGraphGenerator.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scripts/proc_maze/SceneValidator.gd`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `artifacts/screenshots/test_proc_maze_layout.png`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- Godot bake: `res://scripts/tools/BakeFourRoomScene.gd`
- Godot MVP validations: `ValidateCleanRebuildScene.gd`, `ValidateMaterialLightingRules.gd`, `ValidateSceneShadows.gd`, `ValidateLightFlicker.gd`, `ValidateGeneratedMeshRules.gd`
- Godot proc-maze bake/validations: `BakeTestProcMazeMap.gd`, `ValidateTestProcMazeMap.gd`, `ValidateProcMazePlayable.gd`
- Godot no-ceiling bake/validation: `BakeTestProcMazeNoCeilingPreview.gd`, `ValidateProcMazeNoCeilingPreview.gd`
- Godot layout capture: `CaptureTestProcMazeMapLayout.gd`
- Bounded startup smoke tests for `Test_ProcMazeMap.tscn`, `Test_ProcMazeMap_NoCeilingPreview.tscn`, and `FourRoomMVP.tscn`.
- `rg` scans for `LRoom`, negative/mirrored scale patterns, room-specific legacy names, and forbidden proc-maze patterns.

Validation result: PASS

Validation evidence:
- `logs/mvp_bake_no_slit_ambient_20260504_153221.log`
- `logs/mvp_validate_clean_no_slit_ambient_20260504_153221.log`
- `logs/mvp_validate_material_lighting_no_slit_ambient_20260504_153221.log`
- `logs/mvp_validate_shadows_no_slit_ambient_20260504_153221.log`
- `logs/mvp_validate_shadows_after_restore_20260504_154457.log`
- `logs/mvp_validate_light_flicker_no_slit_ambient_20260504_153221.log`
- `logs/mvp_validate_generated_mesh_no_slit_ambient_20260504_153221.log`
- `logs/proc_maze_bake_no_slit_ambient_20260504_153221.log`
- `logs/proc_maze_validate_structure_no_slit_ambient_20260504_153221.log`
- `logs/proc_maze_validate_playable_no_slit_ambient_20260504_153221.log`
- `logs/proc_maze_no_ceiling_bake_no_slit_ambient_20260504_153221.log`
- `logs/proc_maze_no_ceiling_validate_no_slit_ambient_20260504_153221.log`
- `logs/proc_maze_layout_capture_no_slit_ambient_20260504_153221.log`
- `logs/proc_maze_validate_structure_no_lroom_internal_guard_20260504_153506.log`
- `logs/proc_maze_validate_playable_no_lroom_internal_guard_20260504_153506.log`
- `logs/proc_maze_no_ceiling_validate_no_lroom_internal_guard_20260504_153506.log`
- `logs/proc_maze_startup_no_slit_ambient_20260504_153334.log`
- `logs/proc_maze_no_ceiling_startup_no_slit_ambient_20260504_153334.log`
- `logs/mvp_startup_no_slit_ambient_20260504_153334.log`

Current metrics:
- generator version `proc_maze_fixed_layout_v0.7_no_slit_darker_ambient`
- seed `2026050401`
- total rooms `36`
- main path `18`
- branches `8`
- loop count `4`
- macro loops `1`
- macro cycle length `14`
- largest simple cycle length `14`
- macro route A length `8`
- macro route B length `8`
- small loops `2`
- dead ends `4`
- long corridors `5`
- L-turn corridors `2`
- L-shaped rooms `4`
- internally partitioned large rooms `4`
- hubs `3`
- ordinary rectangular rooms `5`
- special rooms `2`
- narrow corridors `8`
- normal corridors `5`
- overlap `false`
- door to wall `false`
- active lights `36`

Current blocking issue:
- No automated blocker. Visual acceptance still needs player-view inspection for darkness level and whether L-shaped rooms now avoid screenshot-style slits.

Next step:
- Run `run_proc_maze_test.bat` and inspect L-shaped rooms plus compound large rooms from player view. If still too bright, lower ambient in small increments before changing direct light strength.

## 2026-05-04 - Reference Style Texture Pass

Current objective:
- Adjust the shared Backrooms visual style toward the user's references: old yellow-green vertical wallpaper, gray-beige trim/baseboards/door frames, speckled acoustic ceiling tiles, and long fluorescent diffuser panels.
- Keep the change in shared materials and module generation rules, not per-room hand placement.

Current progress:
- Added deterministic generated texture assets for wall, floor, door-frame/trim, ceiling, and ceiling-light diffuser materials.
- Updated wall material UV alignment so the wallpaper reads as vertical wall covering instead of repeated debug-like bands.
- Added shared baseboard generation to the MVP `SceneBuilder` and proc-maze `ProcMazeSceneBuilder`.
- Proc-maze boundary walls, opening walls, internal large-room partitions, and hub partitions now receive trim through the same generation path.
- Changed ceiling light panels from short box panels to longer, narrower diffuser panels.
- Kept existing ambient/light/shadow settings and proc-maze topology/space-type validation intact.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- `四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/CODEX_FRESH_SESSION_PROMPT.md`
- `四房间MVP_Agent抗遗忘执行包/docs/HANDOFF_20260504_PROC_MAZE.md`
- `scripts/tools/generate_reference_style_textures.py` (removed)
- `materials/backrooms_wall.tres`
- `materials/backrooms_door_frame.tres`
- `materials/backrooms_ceiling.tres`
- `materials/backrooms_ceiling_light.tres`
- `materials/textures/backrooms_wall_albedo.png`
- `materials/textures/backrooms_wall_normal.png`
- `materials/textures/backrooms_floor_albedo.png`
- `materials/textures/backrooms_floor_normal.png`
- `materials/textures/backrooms_door_frame_albedo.png`
- `materials/textures/backrooms_door_frame_normal.png`
- `materials/textures/backrooms_ceiling_albedo.png` (removed)
- `materials/textures/backrooms_ceiling_normal.png` (removed)
- `materials/textures/backrooms_ceiling_light_albedo.png` (removed)
- `materials/textures/backrooms_ceiling_albedo.png`
- `materials/textures/backrooms_ceiling_normal.png`
- `materials/textures/backrooms_ceiling_light_albedo.png`
- `scripts/tools/generate_reference_style_textures.py`
- `scripts/core/SceneBuilder.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `scenes/debug/BaseResourceGallery.tscn`
- `artifacts/screenshots/reference_style_texture_contact_sheet_20260504.png`
- `artifacts/screenshots/test_proc_maze_map.png`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- `python scripts\tools\generate_reference_style_textures.py`
- Godot parse: `--headless --path . --quit`
- Godot MVP bake/validations: `BakeFourRoomScene.gd`, `ValidateCleanRebuildScene.gd`, `ValidateMaterialLightingRules.gd`, `ValidateGeneratedMeshRules.gd`, `ValidateSceneShadows.gd`
- Godot proc-maze bake/validations: `BakeTestProcMazeMap.gd`, `ValidateTestProcMazeMap.gd`, `ValidateProcMazePlayable.gd`
- Godot no-ceiling bake/validation: `BakeTestProcMazeNoCeilingPreview.gd`, `ValidateProcMazeNoCeilingPreview.gd`
- Godot layout capture: `CaptureTestProcMazeMapLayout.gd`
- Gallery bake/validation: `BakeBaseResourceGallery.gd`, `ValidateBaseResourceGallery.gd`
- Non-headless visual capture: `CaptureTestProcMazeMapScreenshot.gd`

Validation result: PASS

Validation evidence:
- `logs/reference_style_parse_20260504_1635.log`
- `logs/reference_style_bake_four_room_20260504_1635.log`
- `logs/reference_style_validate_clean_rebuild_20260504_1635.log`
- `logs/reference_style_validate_material_lighting_20260504_1635.log`
- `logs/reference_style_validate_generated_mesh_rules_20260504_1635.log`
- `logs/reference_style_validate_scene_shadows_20260504_1635.log`
- `logs/reference_style_bake_proc_maze_20260504_1635.log`
- `logs/reference_style_validate_proc_maze_20260504_1635.log`
- `logs/reference_style_validate_proc_maze_playable_20260504_1635.log`
- `logs/reference_style_bake_proc_maze_no_ceiling_20260504_1635.log`
- `logs/reference_style_validate_proc_maze_no_ceiling_20260504_1635.log`
- `logs/reference_style_capture_layout_20260504_1644.log`
- `logs/reference_style_bake_gallery_20260504_1604.log`
- `logs/reference_style_validate_gallery_20260504_1604.log`
- `logs/reference_style_capture_proc_window_20260504_1637.log`

Visual evidence:
- `artifacts/screenshots/reference_style_texture_contact_sheet_20260504.png`
- `artifacts/screenshots/test_proc_maze_map.png`

Current metrics:
- generator version `proc_maze_fixed_layout_v0.7_no_slit_darker_ambient`
- seed `2026050401`
- total rooms `36`
- main path `18`
- branches `8`
- loop count `4`
- macro loops `1`
- macro cycle length `14`
- largest simple cycle length `14`
- macro route A length `8`
- macro route B length `8`
- small loops `2`
- dead ends `4`
- long corridors `5`
- L-turn corridors `2`
- L-shaped rooms `4`
- internally partitioned large rooms `4`
- hubs `3`
- ordinary rectangular rooms `5`
- special rooms `2`
- narrow corridors `8`
- normal corridors `5`
- active lights `36`

Current blocking issue:
- No automated blocker. Visual acceptance still needs player-view inspection against the user's references.
- Headless viewport screenshot helpers use Godot's dummy texture path and can fail/hang. For viewport screenshots, run capture scripts without `--headless` and keep `--quit-after` bounded.

Next step:
- Run `run_proc_maze_test.bat` and inspect from player view whether the wallpaper, ceiling grid, baseboards, and diffuser lights match the reference direction closely enough.
- If accepted, refine only small material/modeling details such as trim profile depth or diffuser brightness. Do not add per-room decorative fixes.

## 2026-05-04 - Reference Style Revert

Current objective:
- Revert the just-applied reference-style visual pass back to the previous accepted look.
- Keep the existing proc-maze topology, corridor sizing, no-slit L-room rule, darker ambient, wall/door/shadow/AO validations, and player scale unchanged.

Current progress:
- Restored previous wall and door-frame texture PNGs from `E:\godot后室_backups\godot后室_backup_20260501_155923`.
- Regenerated the previous uniform floor texture through `RegenerateUniformFloorTextures.gd`.
- Restored prior material parameters for wall, door-frame, ceiling, and ceiling-light materials.
- Removed the baseboard generation path from the MVP builder and proc-maze builder.
- Restored room ceiling-light panel size from `Vector3(2.2, 0.08, 0.42)` to `Vector3(1.2, 0.08, 0.7)`.
- Rebaked MVP and both proc-maze test scenes so saved scenes no longer contain `Baseboard` / `Trim` nodes.
- Removed the reverted reference-style generator script and unused ceiling/diffuser source textures.

Files changed:
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- `四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/CODEX_FRESH_SESSION_PROMPT.md`
- `四房间MVP_Agent抗遗忘执行包/docs/HANDOFF_20260504_PROC_MAZE.md`
- `scripts/tools/generate_reference_style_textures.py` (removed)
- `materials/backrooms_wall.tres`
- `materials/backrooms_door_frame.tres`
- `materials/backrooms_ceiling.tres`
- `materials/backrooms_ceiling_light.tres`
- `materials/textures/backrooms_wall_albedo.png`
- `materials/textures/backrooms_wall_normal.png`
- `materials/textures/backrooms_floor_albedo.png`
- `materials/textures/backrooms_floor_normal.png`
- `materials/textures/backrooms_door_frame_albedo.png`
- `materials/textures/backrooms_door_frame_normal.png`
- `materials/textures/backrooms_ceiling_albedo.png` (removed)
- `materials/textures/backrooms_ceiling_normal.png` (removed)
- `materials/textures/backrooms_ceiling_light_albedo.png` (removed)
- `scripts/core/SceneBuilder.gd`
- `scripts/proc_maze/ProcMazeSceneBuilder.gd`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/tests/Test_ProcMazeMap.tscn`
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
- `artifacts/screenshots/test_proc_maze_map.png`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- `RegenerateUniformFloorTextures.gd`
- Godot parse: `--headless --path . --quit`
- Godot MVP bake/validations: `BakeFourRoomScene.gd`, `ValidateCleanRebuildScene.gd`, `ValidateMaterialLightingRules.gd`, `ValidateGeneratedMeshRules.gd`, `ValidateSceneShadows.gd`
- Godot proc-maze bake/validations: `BakeTestProcMazeMap.gd`, `ValidateTestProcMazeMap.gd`, `ValidateProcMazePlayable.gd`
- Godot no-ceiling bake/validation: `BakeTestProcMazeNoCeilingPreview.gd`, `ValidateProcMazeNoCeilingPreview.gd`
- Non-headless visual capture: `CaptureTestProcMazeMapScreenshot.gd`
- `rg` scan confirmed no `Baseboard`, `baseboard`, or `Trim` remains in the target scenes/builders.
- Post-cleanup Godot parse/material/proc-maze validations after deleting unused reference-style source files.

Validation result: PASS

Validation evidence:
- `logs/revert_reference_style_regen_floor_20260504_1655.log`
- `logs/revert_reference_style_parse_20260504_1656.log`
- `logs/revert_reference_style_bake_four_room_20260504_1656.log`
- `logs/revert_reference_style_validate_clean_rebuild_20260504_1656.log`
- `logs/revert_reference_style_validate_material_lighting_20260504_1656.log`
- `logs/revert_reference_style_validate_generated_mesh_rules_20260504_1656.log`
- `logs/revert_reference_style_validate_scene_shadows_20260504_1656.log`
- `logs/revert_reference_style_bake_proc_maze_20260504_1656.log`
- `logs/revert_reference_style_validate_proc_maze_20260504_1656.log`
- `logs/revert_reference_style_validate_proc_maze_playable_20260504_1656.log`
- `logs/revert_reference_style_bake_proc_maze_no_ceiling_20260504_1656.log`
- `logs/revert_reference_style_validate_proc_maze_no_ceiling_20260504_1656.log`
- `logs/revert_reference_style_capture_proc_window_20260504_1658.log`
- `logs/revert_reference_style_parse_after_cleanup_20260504_1706.log`
- `logs/revert_reference_style_validate_material_after_cleanup_20260504_1706.log`
- `logs/revert_reference_style_validate_proc_maze_after_cleanup_20260504_1706.log`

Current metrics:
- generator version `proc_maze_fixed_layout_v0.7_no_slit_darker_ambient`
- seed `2026050401`
- total rooms `36`
- main path `18`
- branches `8`
- loop count `4`
- macro loops `1`
- macro cycle length `14`
- largest simple cycle length `14`
- macro route A length `8`
- macro route B length `8`
- small loops `2`
- dead ends `4`
- long corridors `5`
- L-turn corridors `2`
- L-shaped rooms `4`
- internally partitioned large rooms `4`
- hubs `3`
- ordinary rectangular rooms `5`
- special rooms `2`
- narrow corridors `8`
- normal corridors `5`
- active lights `36`

Current blocking issue:
- No automated blocker.
- The reverted reference-style script and unused ceiling/diffuser source textures were removed. Historical screenshots/logs may still exist under `artifacts/` and `logs/`.

Next step:
- Open `run_proc_maze_test.bat` and confirm the visual effect is back to the previous accepted look.

## Texture Tool And Launcher Cleanup - 2026-05-04

Current objective:
- Remove obsolete root startup launchers and add a simple beginner-facing texture/UV adjustment tool that writes directly to the project material and texture files.

Current progress:
- Removed old root `.bat` startup files that pointed at obsolete galleries, visual experiments, latest-demo shortcuts, and Codex starter helpers.
- Kept only the two proc-maze test launchers plus the new texture tool launcher.
- Added a local Python web tool under `codex_tools/texture_tool/` for replacing shared material textures and editing UV scale/offset, color, roughness, normal strength, and light emission settings.
- The tool backs up overwritten texture files to `materials/textures/_texture_tool_backups/`.
- The tool has a bounded Godot sync/import action that writes logs under `logs/texture_tool_sync_*.log`.

Files changed:
- Added `codex_tools/texture_tool/texture_tool_server.py`.
- Added `start_texture_tool.bat`.
- Removed root launchers:
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

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py`
- `python codex_tools\texture_tool\texture_tool_server.py --self-test`
- Local HTTP smoke test against `http://127.0.0.1:8765/api/materials`, then the test Python server process was stopped.
- Process cleanup: stopped old Godot `run_latest_demo.log` runtime processes left from removed launchers; kept the active editor process and its editor-launched scene process.

Validation result: PASS

Validation evidence:
- Python compile: PASS.
- Texture tool self-test: `TEXTURE_TOOL_SELF_TEST PASS materials=5`.
- HTTP smoke test: `TEXTURE_TOOL_HTTP_PASS materials=5 first=wall`.
- Root `.bat` list now contains only `run_proc_maze_no_ceiling_preview.bat`, `run_proc_maze_test.bat`, and `start_texture_tool.bat`.
- No `texture_tool_server.py` Python service remains after validation.
- Remaining Godot processes are the active editor and its editor-launched scene, not the removed old launchers.

Current blocking issue:
- No automated blocker.
- Texture replacement/UV edits are intentionally user-driven; visual acceptance still requires opening `start_texture_tool.bat`, saving changes, syncing/importing, then checking in Godot.

Next step:
- Use `start_texture_tool.bat` to open the local texture UI, select a shared material, replace PNG/JPG/WEBP textures or adjust UV, click `保存材质`, optionally click `同步导入`, then verify in `run_proc_maze_test.bat`.

## Texture Tool Model Preview - 2026-05-04

Current objective:
- Add a real-time model preview to the texture/UV tool so the user can judge texture scale on a wall/floor/ceiling/door/light sample before saving.

Current progress:
- Added a `模型实时预览` section below the texture thumbnails.
- The preview shows a simple room-corner model with wall, floor, ceiling, door frame, and light panel surfaces.
- The selected material surface is highlighted and uses the current albedo texture/color.
- UV scale and offset input changes update the preview immediately, before saving.
- If a material has no texture yet, the preview uses the selected color plus a simple grid so scale and target surface remain visible.

Files changed:
- `codex_tools/texture_tool/texture_tool_server.py`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py`
- `python codex_tools\texture_tool\texture_tool_server.py --self-test`
- Stopped stale `python -m http.server 8765` process because it was occupying the texture tool port and was not the tool server.
- Temporary texture tool server run with `--no-browser`, API/root HTML smoke checks, and Edge headless screenshot capture.

Validation result: PASS

Validation evidence:
- Python compile: PASS.
- Texture tool self-test: `TEXTURE_TOOL_SELF_TEST PASS materials=5`.
- HTTP/API smoke test: PASS.
- Edge headless screenshot: `artifacts/screenshots/texture_tool_model_preview_20260504.png` (`430839` bytes).
- No `texture_tool_server.py` Python service remains after validation.

Current blocking issue:
- No automated blocker.
- If the user already has the old texture tool page open, they must close/reopen `start_texture_tool.bat` or refresh after restarting the server to load the new preview UI.

Next step:
- Reopen `start_texture_tool.bat`, select a material, adjust UV, and verify the `模型实时预览` surface updates before saving.

## MVP Room Launcher Restored - 2026-05-04

Current objective:
- Restore a clear MVP verification-room launcher after cleanup removed the old ambiguous `run_latest_demo.bat` helper.

Current progress:
- Confirmed `scenes/mvp/FourRoomMVP.tscn` still exists.
- Confirmed `scenes/modules/PlayerModule.tscn` still exists.
- Added `run_mvp_room.bat` as the current direct launcher for the MVP mechanism verification room.
- Kept the old `run_latest_demo.bat` name removed so the root folder does not regain unclear "latest" shortcuts.
- `run_mvp_room.bat` only pauses on error; normal Godot exit closes the command window.

Files changed:
- `run_mvp_room.bat`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `docs/CLEANUP_CANDIDATES_20260504.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- `docs/MECHANICS_ARCHIVE.md`
- mirror package docs under `四房间MVP_Agent抗遗忘执行包/docs/`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- Scene/file checks for `scenes/mvp/FourRoomMVP.tscn`, `scenes/modules/PlayerModule.tscn`, and Godot 4.6.2 executable path.
- Short headless MVP startup: `--headless --path . --scene res://scenes/mvp/FourRoomMVP.tscn --quit-after 3 --log-file logs\run_mvp_room_headless_check_20260504_185530.log`.

Validation result: PASS

Validation evidence:
- Root `.bat` list now contains `run_mvp_room.bat`, `run_proc_maze_no_ceiling_preview.bat`, `run_proc_maze_test.bat`, and `start_texture_tool.bat`.
- MVP headless startup exited `0`.
- The MVP startup log includes an MCP runtime port-in-use warning from the already-open editor/runtime, but Godot still exited `0`; this is non-blocking for the launcher.

Current blocking issue:
- No automated blocker.

Next step:
- Use `run_mvp_room.bat` when a mechanic or material change needs quick validation inside the MVP verification room.

## Texture Tool WebGL Preview And Folder Buttons - 2026-05-04

Current objective:
- Replace the fake CSS perspective preview with a real browser WebGL 3D preview and add source-folder buttons for material and texture files.

Current progress:
- Replaced the old model-preview DOM stack with a WebGL canvas.
- The WebGL preview renders a simple 3D room sample with wall, floor, ceiling, door-frame boxes, doorway opening, and ceiling light panel.
- The selected material is applied to its corresponding 3D surfaces and updates live when UV scale, UV offset, color, or emission settings change.
- The preview supports drag-to-rotate and mouse-wheel zoom.
- Added `打开材质文件夹` in the material settings card.
- Added `打开文件夹` next to each texture replacement button.
- Added `/api/open-folder`, which opens Explorer only for project-contained material/texture paths.
- Added `--port` support for test runs so validation can use a temporary port without taking over the normal `8765` tool port.
- Closed the previously running old `texture_tool_server.py` process on port `8765` so reopening `start_texture_tool.bat` loads the new WebGL version.

Files changed:
- `codex_tools/texture_tool/texture_tool_server.py`
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- mirror package docs under `四房间MVP_Agent抗遗忘执行包/docs/`

Commands run:
- `git status --short` -> not a git repository.
- `git diff --stat` -> not a git repository.
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py`
- `python codex_tools\texture_tool\texture_tool_server.py --self-test`
- Temporary server on port `8766`, HTML/API smoke checks, and Edge headless screenshot capture with virtual-time wait.
- Process check and cleanup: no `texture_tool_server.py` process remains after closing the old normal-port server.

Validation result: PASS

Validation evidence:
- Python compile: PASS.
- Texture tool self-test: `TEXTURE_TOOL_SELF_TEST PASS materials=5`.
- HTTP/API smoke test: PASS.
- Edge screenshot: `artifacts/screenshots/texture_tool_webgl_preview_wait_20260504.png` (`409955` bytes).

Current blocking issue:
- No automated blocker.

Next step:
- Reopen `start_texture_tool.bat` to load the WebGL preview. Use drag/scroll in the preview to inspect texture scale, and use the folder buttons to access source material/texture files.

## Pause Handoff - Texture Tool Layer UV Controls - 2026-05-05

Current objective:
- Pause implementation and hand off the next texture-tool UI change to a fresh Codex session.

Current progress:
- Created `docs/HANDOFF_20260505_TEXTURE_TOOL_LAYER_UV.md`.
- The handoff records the latest user request: layer controls do not clearly distinguish horizontal vs vertical scale, and there is no vertical position control.
- Closed two running `python codex_tools\texture_tool\texture_tool_server.py` processes before ending this session.

Files changed:
- `docs/HANDOFF_20260505_TEXTURE_TOOL_LAYER_UV.md`
- `CURRENT_STATE.md`

Commands run:
- Texture tool process check found two running `texture_tool_server.py` processes.
- Closed both texture tool server processes.
- Rechecked process list: `NO_TEXTURE_TOOL_SERVER`.

Validation result: PASS

Validation evidence:
- No texture tool server process remains after cleanup.
- No feature code was modified in this pause/handoff step.

Current blocking issue:
- Implementation is intentionally paused for a new session.

Next step:
- In the next session, read `docs/HANDOFF_20260505_TEXTURE_TOOL_LAYER_UV.md` and implement explicit X/Y layer scale plus vertical offset controls in `codex_tools/texture_tool/texture_tool_server.py`.
