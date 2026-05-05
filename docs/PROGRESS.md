# PROGRESS

## MVP Direct Editable Monster Size Source

2026-05-06:
- Changed `FourRoomMVP.tscn` itself into the editable monster-size source. `MonsterRoot` is now a direct editable node in the MVP scene instead of an instance of `scenes/modules/MonsterSizeSource.tscn`.
- The MVP monster-size room now keeps exactly one source node per monster type: `Monster`, `Monster_Red_KeyBearer_MVP`, and `NightmareCreature_A_MVP`.
- Removed duplicate MVP source nodes `Monster_Normal_B` and `NightmareCreature_B_MVP`; generated aliases still map `normal_b -> MonsterRoot/Monster` and `nightmare_b -> MonsterRoot/NightmareCreature_A_MVP`.
- `MonsterSizeSource.gd` now reads saved transforms from `res://scenes/mvp/FourRoomMVP.tscn` using the packed scene state, then instantiates the appropriate monster template for generated/resource scenes.
- Updated the launcher: `open_monster_size_source.bat` now opens `res://scenes/mvp/FourRoomMVP.tscn`, and `open_mvp_monster_room.bat` calls the same launcher.
- Patched `LightingController.gd` to ignore freed light sources during validation cleanup.
- Validation passed: Godot parse, `ValidateMonsterSizeSource.gd`, `ValidateFourRoomMVPMonsterSet.gd`, `ValidateNightmareHearingAI.gd`, `ValidateMonsterSavedScale.gd`, `ValidateResourceShowcase.gd`, `ValidateProcMazeMonsterKey.gd`, `InspectMonsterSizeSourceBounds.gd`, `ValidateCleanRebuildScene.gd`, `ValidateGeneratedMeshRules.gd`, `ValidateMonsterAI.gd`, forced `ValidateMobileControls.gd`, and `ValidateImportedMonsterAssets.gd`.
- Android APK export passed: `builds/android/backrooms_four_room_mvp_debug.apk`, `303419004` bytes, `apksigner verify --verbose` passed with v2/v3 signature schemes.

## Red Hunter, Cabinet Key, Keyed Exit, Dual Nightmare Sonar

2026-05-06:
- Changed the compact MVP monster set to two normal monsters, one red hunter, and two active hearing-only Nightmare monsters.
- The red monster no longer carries or drops the escape key. It keeps `monster_role = "red"`, is visually red, attacks any living creature it can see, and snaps/holds its facing direction toward the prey during attacks.
- Added `scenes/modules/EscapeKeyPickup.tscn` and placed `CabinetTop_EscapeKey` on top of `RoomB_Maintenance_Cabinet`; the existing player `E` pickup path collects it through the `escape_key_pickup` group.
- Added a keyed outer exit in Room_C: `SceneBuilder.gd` now generates `WallOpening_Exit_C_North` and `DoorFrame_Exit_C_North`, and `FourRoomMVP.tscn` places `Door_Exit_C_North_Keyed` there.
- `DoorComponent.gd` now supports `requires_escape_key`; without the key it stays locked and plays the locked-door rattle, with the key it opens through the normal door interaction path.
- Added `NightmareCreature_B_MVP` to `MonsterSizeSource.tscn`. Both Nightmare monsters remain hearing-only and now emit periodic sonar-like calls through `NightmareSonarAudio`.
- Generated/imported `assets/audio/nightmare_sonar_call.wav`.
- Changed `project.godot` main scene to `res://scenes/mvp/FourRoomMVP.tscn` for this APK pass so the phone build opens the compact MVP room with the new mechanics.
- Updated the Android preset output path to `builds/android/backrooms_four_room_mvp_debug.apk`.
- Validation passed: Godot parse, FourRoom bake, monster-size source, FourRoomMVP monster/keyed-exit mechanics, Nightmare hearing AI, resource showcase, clean rebuild, generated mesh rules, Monster AI, forced mobile controls, proc-maze red-hunter regression, imported monster assets, and monster bounds inspection.
- Android APK export passed: `builds/android/backrooms_four_room_mvp_debug.apk`, `303406716` bytes. `apksigner verify --verbose` passed with v2/v3 signature schemes after setting `JAVA_HOME=D:\GodotAndroid\jdk-17`.

## Creature Removed And Nightmare Hearing AI Activated

2026-05-05:
- Deleted the active project `CreatureZombie_A*` resource files from `assets/backrooms/monsters/` and removed `CreatureZombie_A_MVP` from the editable monster source, MVP validation, resource showcase, and rebuild scripts.
- Added `assets/backrooms/monsters/NightmareCreature_Monster.tscn` as the active controller-backed Nightmare monster.
- `MonsterSizeSource.tscn` now contains four MVP monsters: two normal monsters, the red key-bearer, and `NightmareCreature_A_MVP`.
- Grounded the active Nightmare visual in the source scene; bounds inspection now reports the visual bottom at about `y=-0.001`.
- Nightmare uses `monster_role = "nightmare"` and does not use player vision. It hears player movement, chases the current sound source, investigates the last heard position when the player stops, and attacks when close.
- Player footsteps were lowered from `-10 dB` to `-17 dB`, reduced to `5.6m` max distance, slowed slightly, and given subtler pitch variation. Monster footsteps were lowered from `-7 dB` to `-13 dB`, reduced to `7m`, and slowed slightly.
- Validation passed: Godot parse, imported monster validation, Nightmare animation mapping, Nightmare hearing AI, monster-size source, FourRoomMVP monster set, resource showcase, original Monster AI, saved scale, collision limit, and bounds inspection.

## Reloaded Correct CreatureZombie GLB From Downloads

2026-05-05:
- Reloaded `CreatureZombie_A` from the user-provided file `C:\Users\sigeryang\Downloads\creature__zombie.glb`.
- SHA256 confirmed this Downloads file matches the project GLB, but the old project import/cache files were still deleted and regenerated as requested.
- Removed old `CreatureZombie_A.glb`, `.glb.import`, and extracted `CreatureZombie_A_*` texture/import files under `assets/backrooms/monsters/`.
- Copied the Downloads GLB back into `assets/backrooms/monsters/CreatureZombie_A.glb` and ran Godot import.
- Kept the corrected wrapper transform so `CreatureZombie_A_MVP` displays at about `1.69m` tall in `MonsterSizeSource.tscn`.
- Validation passed: imported monster validation with real visual height, monster-size source validation, FourRoomMVP monster set, resource showcase, bounds inspection, and forbidden-pattern scan.

## CreatureZombie Visibility Fix

2026-05-05:
- Confirmed the user's report: `CreatureZombie_A_MVP` existed in `MonsterSizeSource.tscn`, but the visible mesh was effectively invisible because the wrapper model was only about `0.012m` tall.
- Fixed `assets/backrooms/monsters/CreatureZombie_A.tscn` so the wrapped GLB now displays at about `1.69m` high near its source-scene marker.
- Added `InspectMonsterSizeSourceBounds.gd` for direct bounds diagnostics.
- Strengthened `ValidateImportedMonsterAssets.gd` to check actual visible mesh height, not only source metadata.
- Synced `NightmareCreature_A_Showcase` scale to the current `MonsterSizeSource.tscn` scale after validation caught it was stale.
- Validation passed: Godot parse, imported monster validation with actual visual height, monster-size source validation, and resource showcase validation.

## Monster Size Source Selection Helpers

2026-05-05:
- Clarified that the two new imported models are already in `MonsterSizeSource.tscn`: `CreatureZombie_A_MVP` and `NightmareCreature_A_MVP`.
- Added `EditorSelectHandles` markers to `MonsterSizeSource.tscn` because nested imported GLB skeleton/mesh internals can be hard to select directly in the editor viewport.
- Added `MonsterSizeSourceRuntime.gd` so these editor-only selection markers are removed at runtime.
- Validation passed: Godot parse, monster-size source validation, and FourRoomMVP monster set validation.

## Monster Size Source Launcher

2026-05-05:
- Added `open_monster_size_source.bat` at the project root.
- It opens Godot editor directly to `res://scenes/modules/MonsterSizeSource.tscn` for monster size adjustment.
- Static validation passed: launcher, target scene, and Godot GUI executable all exist.

## Editable Monster Size Source Scene

2026-05-05:
- Added `scenes/modules/MonsterSizeSource.tscn` as the editable source scene for monster size and transform review.
- Put all current monsters into that source scene: two normal controller-backed monsters, the red key-bearer monster, `CreatureZombie_A`, and `NightmareCreature_A`.
- Updated `FourRoomMVP.tscn` so `MonsterRoot` is an instance of `MonsterSizeSource.tscn`; the old `MonsterRoot/Monster` path remains valid for bootstrap and regression scripts.
- Added `scripts/monster/MonsterSizeSource.gd` so generated scenes can duplicate named templates from the source scene instead of assigning hardcoded scales.
- Updated proc-maze monster generation to use the source templates for normal/red monsters. No proc-maze scene was saved or rebaked in this pass.
- Updated resource-showcase rebuild and validation so monster display scales come from `MonsterSizeSource.tscn`.
- Added `ValidateMonsterSizeSource.gd` and updated related validators so later user size edits in the source scene remain the accepted source of truth.
- Validation passed: Godot parse, monster-size source validation, FourRoomMVP monster set, saved scale, Monster AI, collision limit, imported monster validation, Nightmare animation mapping, resource showcase, proc-maze monster-key rebuild validation, and forbidden-pattern scan.

## NightmareCreature Gameplay Candidate Animation Mapping

2026-05-05:
- Continued from `docs/HANDOFF_20260505_IMPORTED_MONSTERS_AND_MVP_TEST.md` without touching the paused proc-maze layout.
- Confirmed the handoff baseline still passes: project parse, imported monster validation, resource showcase validation, FourRoomMVP monster-set validation, Monster AI, saved scale, and collision limit.
- Added optional `attack_animation` and `death_animation` exports to `MonsterController.gd`; unconfigured monsters keep the old idle fallback, so the existing `MonsterModule` behavior is unchanged.
- Configured attack/death animations to be non-looping when those optional names are set.
- Added validated candidate gameplay animation metadata to `NightmareCreature_A.tscn`: idle, walk, run, attack, death, hit, and roar.
- Added `ValidateNightmareCreatureAnimationMapping.gd`, which checks that the mapped animation names exist in the imported GLB and that the shared monster controller exposes the new fields.
- Validation passed: Godot parse, new Nightmare mapping validator, imported monster validation, resource showcase validation, FourRoomMVP monster set validation, Monster AI, saved scale, collision limit, and before/after forbidden-pattern scans.
- This is still a candidate-mapping-only pass. `NightmareCreature_A` is not yet attached to `MonsterController` as an active gameplay monster.

## New Session Handoff

2026-05-05:
- Added `docs/HANDOFF_20260505_IMPORTED_MONSTERS_AND_MVP_TEST.md` for the next Codex session.
- The handoff records the imported monster resources, resource-showcase status, FourRoomMVP monster test room, current proc-maze layout pause, validation commands/logs, cleanup rule, and suggested new-session prompt.

## Imported New Monster Resources To Showcase

2026-05-05:
- Added the two user-provided GLBs from `E:\godot后室\新增资源` into `assets/backrooms/monsters/` as `CreatureZombie_A.glb` and `NightmareCreature_A.glb`.
- Godot imported both GLBs and extracted embedded texture files beside the library copies.
- Created wrapper scenes `CreatureZombie_A.tscn` and `NightmareCreature_A.tscn` with restrained display scaling, source metadata, license metadata, animation-count metadata, and triangle-count metadata.
- Added both imported monsters to the unified resource showcase scene under `Characters`; `ValidateResourceShowcase.gd` now expects `22` resources.
- Updated `BuildNaturalPropScenes.gd` so future showcase rebuilds preserve these imported monster resources.
- Added `ValidateImportedMonsterAssets.gd` to validate wrapper metadata, visible meshes, animation counts, estimated display heights, and triangle counts.
- Updated showcase capture framing and saved `artifacts/screenshots/resource_showcase_imported_monsters_20260505.png`.
- Analysis: `CreatureZombie_A` is high-poly at about `51716` triangles, has `21` animations, and uses `CC-BY-NC-4.0`; keep it showcase/prototype-only unless licensed and optimized. `NightmareCreature_A` is about `6718` triangles with `22` animations under `CC-BY-4.0`, making it the better gameplay candidate after collision and animation mapping.
- Validation passed: Godot import, Godot parse, imported-monster validation, resource showcase validation, and non-headless showcase capture.

## FourRoomMVP Monster Mechanic Test Set

2026-05-05:
- Added the current monster behavior test set directly to `scenes/mvp/FourRoomMVP.tscn`, not to the paused large proc-maze layout.
- `MonsterRoot` now contains exactly three MVP test monsters: existing `Monster` as a normal monster, `Monster_Normal_B` as the second normal monster, and `Monster_Red_KeyBearer_MVP` as the red key-bearer.
- Marked the MVP scene/player with `mvp_player_immortal = true`; red-monster hits against that player now record a nonlethal test hit and skip damage calls.
- Red monsters with `attach_escape_key = true` now set `has_escape_key = true` while creating the visible chest key.
- Enlarged the reusable monster module BoxShape collision so the current visible monster body is covered at the accepted MVP monster scale.
- Added `ValidateFourRoomMVPMonsterSet.gd` for the compact test room: verifies two normal monsters, one red key-bearer, chest key visual, monster placement inside MVP bounds, nonlethal player-hit behavior, and normal counter-damage killing the red monster after two hits.
- Updated old Monster AI and collision validators so they still test the original `MonsterRoot/Monster` path without being disturbed by the extra MVP test monsters and nonuniform scale.
- Validation passed: Godot parse, FourRoomMVP monster-set validation, Monster AI, Monster saved scale, Monster collision limit, and forced mobile controls.

## Pause Scene Layout, Mobile Hide/Sprint Controls

2026-05-05:
- Paused large proc-maze layout/placement work because the user may redesign the map layout.
- Reverted the partial proc-maze locker-placement rule change started in this turn; no new large-scene prop placement or scene bake was kept.
- Added a dedicated locker interior exit button in `HideableCabinetComponent.gd`: while hiding, phones now get `E 出来`, which exits the locker even though normal player interaction is locked.
- Enlarged and relabeled the phone sprint control in `PlayerController.gd` to `跑步`, keeping it in the right-thumb area.
- Finished missing non-layout monster/audio helper functions from the interrupted gameplay pass so the project parses: monster audio players, red-monster light flicker call, red attack/counter-damage/key-drop helpers, and target collider checks.
- Imported the generated local WAV audio resources under `assets/audio/`.
- Validation passed: Godot import, Godot parse, forced mobile-controls validation with `sprint_button=true`, and hideable locker validation including the new exit button.
- Still paused: extra cabinet scene placement, outer-wall locked exit-door placement, full layout bake, screenshots, and APK export.

## Proc-maze Exit Location Screenshot

2026-05-05:
- Added `scripts/tools/CaptureProcMazeExitOverview.gd` for full-map no-ceiling preview screenshots with exit-location markup.
- Generated `artifacts/screenshots/proc_maze_exit_overview_marked_20260505.png`.
- In the marked screenshot, the red circle is the main-route door frame into the current exit room, `DoorFrame_E_N16_N17`, and the orange circle is the current `Exit` marker in room `N17`.
- Current limitation recorded: the generated map has an `Exit` marker/exit room, but a separate key-locked final escape door with victory logic is not implemented yet.

## Interactive Resource Showcase Controls

2026-05-05:
- Added `scripts/tools/ResourceShowcaseController.gd` and attached it to `res://scenes/tests/Test_NaturalPropsShowcase.tscn`.
- `run_resource_showcase.bat` now opens a controllable resource viewer instead of a static display: right mouse drag orbits the camera, wheel zooms, left click selects a resource, `Q/E` rotates selection, `+/-` scales selection, `R` resets, `F` focuses selection, and `0`/Home returns to the full scene.
- Added on-screen Chinese buttons for previous/next, focus, full view, rotate, scale, and reset, so the controls are discoverable without reading code.
- The scale control is runtime-only for review and does not save permanent model size changes.
- Updated `BuildNaturalPropScenes.gd` so future natural-prop showcase rebuilds preserve the interactive controller.
- Extended `ValidateResourceShowcase.gd` to require the controller script and review UI.
- Visual evidence: `artifacts/screenshots/resource_showcase_controls_20260505.png`.
- Validation passed: Godot parse, resource showcase validation, and non-headless showcase screenshot capture.

## Unified Resource Showcase And Monster Default Scale

2026-05-05:
- Added `run_resource_showcase.bat` at the project root. It launches `res://scenes/tests/Test_NaturalPropsShowcase.tscn` and writes `logs/run_resource_showcase.log`.
- Promoted `Test_NaturalPropsShowcase.tscn` into the unified resource display scene. It now contains the original 15 natural props plus `OldOfficeDoor_A`, `HideLocker_A`, `PlayerModule`, a normal `MonsterModule`, and a red key-bearer monster.
- Added `ValidateResourceShowcase.gd`; validation currently passes with `20` resources and monster scale `(0.953989, 0.387199, 0.688722)`.
- Updated `BuildNaturalPropScenes.gd` so future prop rebuilds keep the unified showcase additions instead of overwriting the scene with only natural props.
- Folded the user's adjusted FourRoomMVP monster scale into `scenes/modules/MonsterModule.tscn` and proc-maze monster spawning. The large proc-maze scene now creates all three monsters at the same default size as the user's MVP-tuned monster.
- Rebaked `scenes/tests/Test_ProcMazeMap.tscn` and re-exported the Android debug APK after the monster scale change.
- Visual evidence: `artifacts/screenshots/resource_showcase_all_assets_20260505.png`.
- Validation passed: Godot parse, resource showcase, Monster saved scale, proc-maze bake, red key-bearer validation, proc-maze prop validation, forced mobile controls validation, natural props validation, resource showcase capture, Android export, launcher static path check, and texture-tool process cleanup.

## Proc-maze Guidance Arrows And Red Monster Key

2026-05-05:
- Moved generated graffiti arrows farther away from door frames and the wall surface, fixing the visible overlap/clipping case where an arrow sat too close to a doorway.
- Guidance arrows are still generated by `ProcMazeSceneBuilder.gd` from the exit-shortest-path logic; they are not hand-placed in the baked scene.
- Added validation metadata for guidance arrows: `door_side_offset` and `wall_offset`.
- Added `ValidateGuidanceGraffiti.gd` checks so future rebuilds reject arrows that are too close to the door frame or wall surface.
- Added proc-maze monster spawning in `TestProcMazeMap.gd`: two normal monsters plus one `Monster_Red_KeyBearer` now spawn in the large playable MVP scene.
- Added `monster_role` / `attach_escape_key` support to `MonsterController.gd`. The red monster receives a red material override and creates a visible gold `ChestEscapeKey` child on its upper body.
- Added `ValidateProcMazeMonsterKey.gd` to verify the red key-bearer, red body material, and visible gold chest-key parts.
- Captured visual evidence:
  - `artifacts/screenshots/guidance_arrow_spacing_20260505.png`
  - `artifacts/screenshots/red_monster_chest_key_20260505_r3.png`
- Rebuilt Android debug APK: `builds/android/backrooms_proc_maze_mvp_debug.apk`, `269268783` bytes.
- Validation passed: Godot parse, proc-maze bake, guidance graffiti validation, red-monster key validation, proc-maze prop regression, forced mobile controls validation, Android export, and `apksigner verify`.
- Remaining follow-up: full red-monster combat/key-drop/key-exit gameplay is not implemented in this pass.

## Mobile Joystick Inset Tuning

2026-05-05:
- Fixed the phone joystick being too close to the bottom-left corner.
- Updated `PlayerController.gd` defaults: joystick radius `74 -> 92`, edge margin `Vector2(34, 34) -> Vector2(126, 126)`. This moves the joystick center from about `108px` off the left/bottom edges to about `218px`.
- Added `mobile_joystick_start_radius_multiplier = 3.0` and relaxed start detection around the joystick center, so the player can begin movement from a wider comfortable thumb area instead of needing to press precisely on the visible base.
- Extended `ValidateMobileControls.gd` to check joystick edge inset and comfortable start acceptance.
- Validation passed: Godot parse, mobile controls, proc-maze prop regression, Android debug export, and `apksigner verify`.
- Rebuilt APK: `builds/android/backrooms_proc_maze_mvp_debug.apk`, `268853211` bytes.
- ADB was available but no phone was connected, so the APK was not auto-installed.

## D-drive Android Toolchain And APK Export

2026-05-05:
- Installed the full Android export toolchain under `D:\GodotAndroid`: JDK 17, Android SDK command-line tools/packages, Godot 4.6.2 Android export templates, and debug keystore.
- Added a junction from Godot's expected export template version directory in `%APPDATA%` to `D:\GodotAndroid\godot_export_templates\4.6.2.stable`, so the actual template APK files stay on D drive.
- Configured Godot editor settings to use:
  - `D:\GodotAndroid\jdk-17`
  - `D:\GodotAndroid\android-sdk`
  - `D:\GodotAndroid\keystores\debug.keystore`
- Completed Android SDK packages required for Godot 4.6 export: platform-tools, Android 35 platform, build-tools `35.0.0`/`35.0.1`, CMake `3.10.2.4988404`, and NDK `28.1.13356709`.
- Updated `export_presets.cfg` with explicit Android keystore/options and kept the export target at `builds/android/backrooms_proc_maze_mvp_debug.apk`.
- Enabled `rendering/textures/vram_compression/import_etc2_astc=true` in `project.godot` and reimported resources. Godot 4.6 Android export validation silently fails without this setting on Windows.
- Added a simple project `icon.svg` and configured it as the app icon.
- Repaired the empty 20-byte proc-maze module placeholder `.tscn` files by adding minimal `Node3D` roots, removing export-time parse errors while preserving the registry scene paths.
- Final APK export passed: `builds/android/backrooms_proc_maze_mvp_debug.apk`, `268849115` bytes.
- `apksigner verify --verbose` passed with v2/v3 signature schemes.
- Regression validation passed after export changes: Godot parse, proc-maze prop validation, and forced mobile controls validation.
- Remaining non-blocking note: Godot reports that the nested `godot后室新/project.godot` is ignored.

## Proc-maze Natural Props, Mobile Controls, And APK Prep

2026-05-05:
- Added generated large-scene prop placement to `ProcMazeSceneBuilder.gd`. The proc-maze builder now creates `LevelRoot/Props` on rebuild and instantiates existing reusable GLB wrapper scenes by space type and solid-wall candidates.
- Current large scene placement validates at `34` props: `23` floor/near-wall props, `11` wall props, and `1` hideable locker across `20` modules. Blocking props are rejected near generated door portals, entrance/exit markers, and corridor spaces.
- Kept the authored-asset pipeline intact: proc-maze placement uses existing `Box_*`, cleaning, furniture, industrial, and `HideLocker_A` wrapper scenes. No final BoxMesh/CSG/PlaneMesh prop art was added.
- Added a phone movement layer to `PlayerController.gd`: a left-bottom virtual joystick appears on Android/iOS/touch devices and contributes to the same movement vector as keyboard input. The existing on-screen interaction button still calls the same `E` interaction path.
- Added `ValidateProcMazeProps.gd` and `ValidateMobileControls.gd`.
- Changed `project.godot` main scene from `FourRoomMVP` to `res://scenes/tests/Test_ProcMazeMap.tscn`, so the large scene is the playable/export target.
- Added `export_presets.cfg` with an Android debug preset for `builds/android/backrooms_proc_maze_mvp_debug.apk`, arm64-v8a only, and export filters excluding development artifacts/logs/docs/tools/build output.
- Added `.gdignore` under `artifacts/` and `builds/` to keep screenshots and generated build output out of Godot resource import.
- Rebaked `scenes/tests/Test_ProcMazeMap.tscn` and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`.
- Validation passed: Godot parse, proc-maze structure/playable, proc-maze prop placement, mobile controls, no-ceiling preview, natural prop regression, door regression, hideable locker regression, generated mesh rules, and screenshot capture.
- Visual evidence:
  - `artifacts/screenshots/proc_maze_props_mobile_main_20260505.png`
  - `artifacts/screenshots/proc_maze_props_focus_20260505.png`
- APK export was later unblocked by installing the Android toolchain on D drive and enabling ETC2/ASTC import. Final APK: `builds/android/backrooms_proc_maze_mvp_debug.apk`.

## Hideable Locker Asset And Slit View

2026-05-05:
- Generated an image2 reference board for `HideLocker_A` at `artifacts/references/hideables/HideLocker_A_reference_20260505.png`.
- Authored the locker in Blender through `scripts/tools/create_hideable_locker_blender.py`, then exported/imported `assets/backrooms/props/furniture/HideLocker_A.glb` and source `artifacts/blender_sources/hideables/HideLocker_A.blend`.
- The model is a restrained old beige-gray standing metal locker with upper horizontal viewing slits, hinge/handle details, subtle edge wear, bottom dust, and generated procedural old-metal albedo textures. The image2 board is only a reference, not a final texture.
- Reworked the front model so the lower cabinet face is one wider integrated door panel (`HideLocker_A_front_door_one_piece_panel`) with upper slits, instead of reading as a separate inset lower board.
- Slightly enlarged the authored upper slit spacing in Blender by reducing rail height and increasing slit spacing, then re-exported/reimported the GLB.
- Created reusable wrapper `assets/backrooms/props/furniture/HideLocker_A.tscn` with `HideableCabinetComponent`, `Model`, `StaticBody3D + BoxShape3D`, hide/camera/exit markers, and the persistent `interactive_hideable` group.
- Extended `PlayerController.gd` so the existing `E` interaction first checks nearby hideable props, then falls back to the existing door interaction path.
- Tightened hideable interaction usability: a player close to the cabinet front and facing it can enter without exact marker alignment.
- Added a visible player interaction button: near a hideable locker it shows `E 进入`, and clicking it calls the same path as keyboard `E`; near interactive doors it shows `E 开门` / `E 关门`.
- `HideableCabinetComponent.gd` now supports entering/exiting with `E`: player movement is locked, player collision is disabled while hidden, the camera moves to the slit anchor, FOV narrows to `34`, yaw/pitch are clamped to `18°/8°`, and a slit-shaped UI mask limits visible screen area.
- The locker slit-view mouse Y axis is inverted from the previous pass; black mask blocks are fully opaque, with soft edge strips used only to suggest a slight defocused frame.
- Added `scenes/tests/Test_HideableLockerShowcase.tscn` as the resource display scene.
- Added `ValidateHideableLocker.gd` and `CaptureHideableLockerScene.gd` for asset/interaction validation and outside/inside screenshots.
- Placed one validated MVP instance at `scenes/mvp/FourRoomMVP.tscn` -> `LevelRoot/Props/RoomC_HideLocker_A`, in Room_C near the east wall, facing inward and away from the two nearby door openings.
- Updated the natural prop rebuild/validation path so future natural-prop rebuilds preserve hideable props, and the natural prop validator still counts the original 16 natural placements separately from hideable MVP props.
- Added `mvp_room_c` screenshot mode for direct MVP placement review.
- Added `mvp_prompt` screenshot mode for checking the MVP locker placement with the player and visible interaction button.
- Validation passed: Python compile, Blender export, Godot import, wrapper/showcase build, hideable interaction validation, door interaction regression, natural prop validation, generated mesh rules validation, player animation validation, player collision validation, final primitive scan, cache cleanup, and targeted process cleanup.
- Visual evidence:
  - `artifacts/screenshots/hideable_locker_showcase_20260505_154726.png`
  - `artifacts/screenshots/hideable_locker_slit_view_20260505_160403.png`
  - `artifacts/screenshots/hideable_locker_mvp_room_c_20260505_163757.png`
  - `artifacts/screenshots/hideable_locker_mvp_prompt_20260505_170200.png`
  - `artifacts/screenshots/hideable_locker_slit_view_20260505_172927.png`

## Door Gap And E Interaction

2026-05-05:
- Fixed the visible slit above `OldOfficeDoor_A` by increasing the Blender-authored door panel height from `2.05m` to `2.09m`, then re-exporting/reimporting the GLB.
- Rebuilt the wrapper so the door now has a real hinge setup: `DoorComponent` root -> `HingePivot` -> `Model` and `CollisionBody`. The model and simple BoxShape collision rotate together.
- Added door interaction methods in `DoorComponent.gd`: `open_toward_direction()`, `interact_from()`, animated target angle, and the `interactive_door` group.
- Added `interact` input bound to `E` in `PlayerController.gd`. The player now finds the closest facing door in range and opens it toward the player's current facing direction; pressing again closes it.
- Updated `SceneBuilder.gd` so runtime rebuilds relink selected door instances to their matching portal by `portal_id`, keeping `PortalComponent.is_open()` aligned with door state.
- Extended `ValidateBackroomsDoorProps.gd` to check door height, hinge pivot, collision, E binding, player interaction, door animation, and portal state before/after interaction.
- Validation passed: Python compile, Godot parse, Blender export, Godot import, door wrapper/FourRoom build, door interaction validation, natural props validation, clean rebuild validation, generated mesh rules validation, player animation validation, player collision validation, MVP startup smoke, forbidden primitive scan, and touched-path forbidden-pattern scan.
- Visual evidence:
  - `artifacts/screenshots/door_p_bc_interaction_20260505_145851.png`
  - `artifacts/screenshots/door_p_bc_open_interaction_20260505_145851.png`

## Selected Old-Office Door Asset

2026-05-05:
- Generated an image2 reference board for `OldOfficeDoor_A` under `artifacts/references/doors/OldOfficeDoor_A_reference_20260505.png`.
- Built the door as a real Blender-authored metric asset instead of final Godot primitive art: old beige/yellowed panel, dull handle/hinges, subtle bottom grime, edge wear, and generated procedural door-panel albedo.
- Exported/imported the independent GLB at `assets/backrooms/props/doors/OldOfficeDoor_A.glb`.
- Created reusable Godot wrapper `assets/backrooms/props/doors/OldOfficeDoor_A.tscn` with `DoorComponent`, a `Model` child, and simple `StaticBody3D + BoxShape3D` collision.
- Placed one selected door only at `FourRoomMVP.tscn` portal `P_BC` as `LevelRoot/Doors/Door_P_BC_OldOffice_A`; other door frames remain open.
- Added `ValidateBackroomsDoorProps.gd` and a `door_p_bc` screenshot mode for focused checks.
- Added `artifacts/references/.gdignore` and removed generated `.import` files under `artifacts/references/` so reference boards remain modeling references and are not treated as Godot resources.
- Validation passed: Blender script compile/export, GLB material inspection, Godot import, wrapper/placement build, door validation, natural prop validation, clean rebuild validation, generated mesh rules validation, forbidden primitive scan, focused screenshot capture, cache cleanup, and final process cleanup.
- Visual evidence:
  - `artifacts/screenshots/backrooms_door_p_bc_20260505_133648.png`
  - `artifacts/screenshots/backrooms_door_p_bc_wide_20260505_133821.png`

## Natural Prop Collision And Material Realism

2026-05-05:
- Fixed visible player clipping for the current problem props by adding simple `StaticBody3D + BoxShape3D` wrapper collisions to `Bucket_A`, `Mop_A`, and `Chair_Old_A`.
- Kept the new blockers sparse and placement-safe: `ValidateNaturalProps.gd` confirms the blocking props are still away from door openings and room centers.
- Improved the Blender-authored assets instead of adding Godot primitive art: bucket rim/inner shadow/scuffs, mop handle wear and cloth variation, and chair vinyl/fabric edge wear and stains.
- Added small generated procedural albedo textures for old blue-gray plastic, old cloth, old tan vinyl, and old beige furniture. These are code-generated material textures, not reused reference images.
- Re-exported all 15 GLBs, reimported them in Godot, regenerated wrapper scenes/showcase/FourRoomMVP placement, and added focused capture modes for the cleaning corner and old chair.
- Validation passed: Python compile, GLB material/texture inspection, Godot import, wrapper/FourRoom build, natural prop validation, clean rebuild validation, generated mesh rules validation, prop primitive scan, Python cache cleanup, and process cleanup.
- Final visual checks saved:
  - `artifacts/screenshots/natural_props_collision_materials_textured_final_room_b_close_20260505_131135.png`
  - `artifacts/screenshots/natural_props_collision_materials_textured_final_room_c_chair_20260505_131206.png`

## Texture Tool Edge-Layer Vertical Offset Visibility

2026-05-05:
- Fixed bottom/top layer vertical offset so edge-anchored grime can visibly move. Previously a bottom/墙脚 layer started at the bottom edge and positive-down offset was clamped back to the same place.
- Bottom layers now offset relative to the bottom influence band: positive values move down and are clipped at the wall foot, while negative values move up into the wall. Top layers follow the same positive-down rule.
- `_blend_overlay()` now safely crops overlays that move partly outside the canvas, which makes edge offset usable instead of silently clamping the overlay back inside.
- Updated runtime random wall grime in `contact_ao_surface.gdshader` to use the same edge-band offset behavior, keeping texture-tool preview and in-game wall grime aligned.
- Validation passed: Python compile, image-level offset comparison, texture-tool self-test, runtime wall grime atlas/config rebuild, generated mesh validation, Python cache cleanup, and final process cleanup. No texture-tool server process remains.

## Natural Environment Props Batch 1

2026-05-05:
- Generated four image2 reference boards for the required Backrooms natural prop groups: boxes, cleaning props, old furniture, and industrial maintenance pieces.
- Built the first 15 low/mid-poly Blender assets at metric scale: `Box_Small_A`, `Box_Medium_A`, `Box_Large_A`, `Box_Stack_2_A`, `Box_Stack_3_A`, `Bucket_A`, `Mop_A`, `CleaningClothPile_A`, `Chair_Old_A`, `SmallCabinet_A`, `MetalShelf_A`, `ElectricBox_A`, `Vent_Wall_A`, `Pipe_Straight_A`, and `Pipe_Corner_A`.
- Exported each asset as an individual GLB into the required `res://assets/backrooms/props/...` category folders, then imported them in Godot.
- Created reusable wrapper scenes for all 15 props. Simple BoxShape collision is enabled only on path-blocking larger props: medium/large boxes, box stacks, small cabinet, and metal shelf.
- Added `scenes/tests/Test_NaturalPropsShowcase.tscn` for asset size/material review.
- Placed 16 prop instances into `scenes/mvp/FourRoomMVP.tscn` under `LevelRoot/Props`: Room_A corner boxes, Room_B maintenance/cleaning wall, Room_C storage/old-office side, and Room_D wall/pipe/cloth details.
- Kept placement sparse and natural: floor blockers are away from door openings and room centers; wall props are elevated and nonblocking.
- Fixed Blender 5.1 material export so GLBs carry actual kraft cardboard, dull gray metal, blue-gray plastic, and beige furniture colors instead of default white.
- Validation passed: Blender script compile, GLB material inspection, Godot GLB import, wrapper/showcase/FourRoom build, `ValidateNaturalProps.gd`, `ValidateCleanRebuildScene.gd`, `ValidateGeneratedMeshRules.gd`, implementation forbidden-pattern scan, final prop primitive scan, Python cache cleanup, and process cleanup.
- Screenshots saved under `artifacts/screenshots/`: `natural_props_before_four_room_cutaway_20260505.png`, `natural_props_after_four_room_cutaway_20260505.png`, `natural_props_showcase_20260505.png`, `natural_props_after_room_a_20260505.png`, `natural_props_after_room_b_20260505.png`, and `natural_props_after_room_c_cutaway_20260505.png`.

## Texture Tool Layer X/Y Scale And Vertical Offset

2026-05-05:
- Split layer-composition scale controls into explicit horizontal width range (`scale_x_min` / `scale_x_max`) and vertical height range (`scale_y_min` / `scale_y_max`).
- Added per-layer `position_y_offset` from `-1.0` to `1.0`; positive values move overlays downward. Edge-anchored top/bottom layers now crop at the canvas edge instead of being clamped back to the same position.
- Preserved legacy `scale_min` / `scale_max` compatibility by using old uniform scale fields as X/Y defaults when new fields are missing.
- Updated `/api/layers/preview` and `/api/layers/compose` to use the same split-scale and vertical-offset calculation.
- Updated beginner-facing UI labels so the layer panel names horizontal width, vertical height, and positive-down offset directly.
- Propagated the new wall-layer settings into runtime random grime: the atlas config now writes `size_x_scale`, `size_y_scale`, `top_offset`, and `bottom_offset`, and `contact_ao_surface.gdshader` / `ContactShadowMaterial.gd` apply them at runtime.
- Validation passed: Python compile, texture-tool self-test, inline legacy/new-field compatibility test, embedded JS syntax check, Godot parse, touched-file forbidden-pattern scan, runtime grime atlas/config rebuild, temporary HTTP smoke test, Python cache cleanup, and final process cleanup. No texture-tool server process remains.

## Grime Layer Probability, Rotation, And Edge Feather

2026-05-05:
- Added per-layer `probability` to the texture tool. Random grime candidates now appear only when they pass the layer probability, so a layer can be sparse without lowering opacity.
- Added per-layer random rotation controls. Rotation is applied to the stain image first; the wall-aligned mask is regenerated afterward, so top/bottom/left/right feathering does not rotate with the stain.
- Top and bottom grime placement is now edge-anchored: top grime starts at the ceiling-side edge and fades downward; bottom grime starts at the wall-foot edge and fades upward.
- `bottom_fade` and `top_fade` masks now also apply horizontal edge feathering to avoid visible rectangular left/right seams.
- Runtime wall grime atlas tiles also get horizontal alpha feathering.
- Runtime grime now uses the same material UV scale/offset as the base wall texture, and texture-tool compose/sync saves current UV/material controls before generation or Godot rebake.
- Rebaked `FourRoomMVP.tscn`, `Test_ProcMazeMap.tscn`, and `Test_ProcMazeMap_NoCeilingPreview.tscn`.
- Validation passed: runtime atlas/config build, Python compile, texture-tool self-test, embedded JS check, Godot parse, MVP/proc/no-ceiling bakes, generated mesh validation, scene shadow validation, proc-maze structure/playable validations, and no-ceiling validation. The texture-tool server process was closed afterward.

## Texture Tool Wall UV Preview Parity

2026-05-05:
- Fixed the wall WebGL preview's vertical texture orientation. The model preview no longer flips uploaded images with `UNPACK_FLIP_Y_WEBGL`, matching the current generated-wall rule where image bottom maps to the wall foot and image top maps to the ceiling side.
- Added `materials/textures/backrooms_wall_runtime_grime_config.json`, generated from the wall layer settings.
- Runtime wall grime now uses layer-derived top/bottom weights and band size. A bottom-only layer now bakes as bottom-only runtime grime instead of the shader randomly choosing top and bottom equally.
- Rebaked `FourRoomMVP.tscn`, `Test_ProcMazeMap.tscn`, and `Test_ProcMazeMap_NoCeilingPreview.tscn`; baked wall materials now include `random_grime_top_weight=0.0` and `random_grime_bottom_weight=2.0` for the current wall layer setup.
- Validation passed: runtime atlas/config build, texture-tool compile/self-test/embedded JS check, Godot parse, MVP/proc/no-ceiling bakes, generated mesh validation, scene shadow validation, proc-maze structure/playable validations, and no-ceiling validation. The texture-tool server process was closed afterward.

## Runtime Random Wall Grime

2026-05-05:
- Replaced the fixed baked wall-grime workflow with runtime random wall grime.
- Wall layer generation now rebuilds `materials/textures/backrooms_wall_runtime_grime_atlas.png` from the selected wall overlay candidate pool, while `materials/textures/backrooms_wall_albedo.png` remains the clean/base wall texture.
- `contact_ao_surface.gdshader` samples the runtime grime atlas per wall seed, so top/bottom grime varies across solid walls, doorway wall pieces, internal walls, and WallJoint/corner pillar surfaces instead of repeating one composited PNG everywhere.
- MVP and proc-maze builders now assign seeded wall material instances to solid walls, opening walls, and wall-like corner/joint pillars.
- Wall vertical UV mapping now treats the image bottom as the wall foot and the image top as the ceiling side, matching texture-tool top/bottom layer controls in the generated scene.
- Rebaked `FourRoomMVP.tscn`, `Test_ProcMazeMap.tscn`, and `Test_ProcMazeMap_NoCeilingPreview.tscn`.
- Validation passed: runtime atlas build, texture-tool compile/self-test/embedded JS check, Godot parse, MVP bake, generated mesh validation, scene shadow validation, proc-maze bake/structure/playable validations, and no-ceiling bake/validation. `ValidateMaterialLightingRules.gd` still reports unrelated floor material settings and was not changed.

## Wall UV Origin Unified

2026-05-05:
- Unified ordinary generated wall boxes and wall-opening pieces to a wall-foot/global-Y vertical UV origin.
- This removes the center-origin mismatch where long ordinary walls could show a horizontal grime/repeat band that did not line up with doorway wall pieces.
- Updated the texture tool WebGL preview so solid generated walls use the same wall-foot UV origin as the actual game mesh.
- Extended `ValidateGeneratedMeshRules.gd` to reject regular wall/opening meshes whose vertical wall UV V no longer follows wall-foot/global Y.
- Rebaked `FourRoomMVP.tscn`, `Test_ProcMazeMap.tscn`, and `Test_ProcMazeMap_NoCeilingPreview.tscn`.
- Validation passed: texture-tool compile/self-test/embedded JS check, Godot parse, MVP bake, generated mesh/material/shadow validations, proc-maze bake/structure/playable validations, and no-ceiling bake/validation. Three stale texture-tool server processes were closed after validation.

## Texture Tool Actual Wall UV Preview

2026-05-05:
- Fixed the WebGL generator preview so solid wall boxes use the same center-origin UV behavior as `GeneratedMeshRules.build_box_mesh`.
- Kept wall-opening preview UVs separate through a `WallOpeningBody`-style path, so door-opening surfaces are not falsely treated as ordinary solid boxes.
- This makes horizontal grime/repeat lines visible in the tool preview when they will appear on actual generated solid walls.
- Validation passed: Python compile, texture-tool self-test, embedded JS syntax check. The old texture-tool Python process was closed so relaunch loads the new preview.

## Texture Tool Sync Rebakes Generated Scenes

2026-05-05:
- Fixed the remaining texture-tool-to-game mismatch where `.tres` material settings were saved but baked scene-local contact-shadow materials still held old parameters.
- `/api/sync` now performs Godot resource import and then rebakes `FourRoomMVP.tscn`, `Test_ProcMazeMap.tscn`, and `Test_ProcMazeMap_NoCeilingPreview.tscn`.
- Verified the wall material changed from stale baked `uv_scale = Vector2(0.1, 0.1)` to `Vector2(1, 1)` in MVP and proc scenes after sync.
- Validation passed: Python compile, texture-tool self-test, embedded JS syntax check, and full texture-tool sync/rebake path.

## Texture Tool Game UV Parity

2026-05-04:
- Fixed the WebGL model preview UV density mismatch against generated game meshes.
- The preview now follows the same broad rules as the game generator: wall/opening boxes use `world_size / 6.0`, floor uses `world_size / 12.0`, ceiling uses `world_size / 6.0`, and door-frame preview UVs use normalized frame dimensions.
- This makes low material UV values such as `0.1` read as stretched/large in the tool, matching what the generated Godot scene does.
- Validation passed: Python compile, texture-tool self-test, and embedded JS syntax check.

## Contact Shadow And Live Texture Preview

2026-05-04:
- Added Mobile-compatible material-level contact darkening through `scripts/visual/ContactShadowMaterial.gd`; this replaces the attempted SSAO path because Godot 4.6.2 reports SSAO is not available with the Mobile renderer.
- MVP generated walls, floors, ceilings, and door frames now use contact-shadow ShaderMaterial wrappers derived from the existing shared materials.
- Proc-maze generated walls, wall openings, internal walls, and door frames use the same contact-shadow path; proc floors and ceilings keep their existing materials to avoid false grid bands across large maps.
- The playable proc-maze `ESC` lighting panel now includes controls for closure/contact shadow enable, strength, and maximum darkening.
- Updated proc-maze and MVP validators so the contact-shadow material wrapper is accepted as preserving the material rule while still rejecting unrelated material mismatches.
- Finished the texture tool live preview pass: UV changes now affect flat previews, unsaved layer compositions are previewed through `/api/layers/preview`, and the WebGL model preview is sticky beside the material controls with closer zoom/reset buttons.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`, `scenes/tests/Test_ProcMazeMap.tscn`, and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`.
- Validation passed: texture-tool compile/self-test/JS/HTTP preview, Godot parse, MVP material/mesh/shadow validations, proc-maze bake/structure/playable/no-ceiling validations. The temporary texture-tool server was stopped and the stale background texture-tool process was closed.

## Texture Tool Game-Scale Preview

2026-05-04:
- Replaced the WebGL texture-tool preview's simplified doorway/frame with game-scale geometry.
- Preview constants now match the current MVP/proc-maze rules: `6.0m` room size, `2.55m` wall height, `0.20m` wall thickness, `1.15m` wall opening width, `0.95m` door-frame inner width, `0.10m` trim width, `0.16m` frame depth, and `2.18m` frame outer height.
- The preview wall is now built as a doorway opening with side/header wall segments instead of a full wall plus fake dark rectangle.
- The preview door frame is now a U-shaped frame using the canonical dimensions from `DoorFrameVisual.gd` / proc-maze builder rules.
- Validation passed: Python compile, texture-tool self-test, embedded JS syntax check, and temporary HTTP smoke check. The temporary HTTP server was stopped afterward.

## Texture Tool Layer Controls

2026-05-04:
- Fixed overlay layer deletion in `start_texture_tool.bat`'s web UI. The delete button now saves the already-filtered layer list instead of re-reading the old DOM and restoring the deleted layer.
- Expanded layer blend modes to include normal, multiply, screen, darken, lighten, overlay, soft light, hard light, and difference.
- Added per-layer mask controls: none, soft edge rectangle, bottom fade, top fade, and radial fade.
- Added per-layer mask feather control from `0.0` to `0.5`; feathering is applied to overlay alpha before compositing.
- Validation passed: Python compile, texture-tool self-test, embedded JS syntax check, temporary HTTP smoke check, and direct alpha-mask unit check. The temporary HTTP server was stopped afterward.

## Proc-maze Runtime Lighting Tuning Panel

2026-05-04:
- Added `scripts/lighting/LightingTuningPanel.gd` as a runtime `CanvasLayer` under `Systems/LightingTuningPanel` in the playable proc-maze scene.
- Pressing `ESC` shows/hides the light controller and releases mouse capture. Clicking outside the panel hides it and captures the mouse back for gameplay.
- The panel controls light color, light strength, range, attenuation, lamp-panel emission, ambient color, ambient energy, and flicker enable.
- The proc-maze runtime now starts with a less-yellow warm-white light tint while leaving `scenes/mvp/FourRoomMVP.tscn` unmodified.
- `LightingController.gd` now exposes `refresh_light_cache()` so runtime tuning becomes the flicker baseline, and it reuses unique lamp-panel materials instead of duplicating them repeatedly.
- Validation passed: parse, proc-maze bake/structure/playable, no-ceiling bake/validation, shared light-flicker regression, and shared scene-shadow regression.

## Texture Tool Layered Random Overlays

2026-05-04:
- Extended `start_texture_tool.bat`'s local web tool with a new `图层合成` section.
- Each material can now keep a base albedo snapshot and one or more overlay layers.
- Overlay layers support multi-file candidate pools. When random mode is enabled, the layer chooses from the selected pool using seed, count, scale range, placement, and opacity controls.
- The default layer is `bottom_grime`, intended for wall-floor dirt, stains, and lower-wall grime.
- Compositing writes back to the material's existing albedo texture slot, backs up the previous output texture, and keeps Godot reading the same `.tres` material path.
- Added APIs for layer state, candidate upload, composition, and base reset. Validation passed: texture-tool self-test, local HTTP GET checks, Python compile, and embedded JS syntax check.

## Proc-maze Doorway Reveal Clearance

2026-05-04:
- Added a generated doorway reveal buffer to prevent walls or internal partitions from starting immediately behind a proc-maze door frame.
- `ProcMazeSceneBuilder.gd` now builds reveal rectangles for both sides of each opening and trims/splits large-room or hub internal partition walls that would intrude into that entry zone.
- Door reveal clearance is a shared generator rule, not a baked-scene hand edit. The playable and no-ceiling proc-maze scenes were rebaked from the same module rules.
- `SceneValidator.gd` now rejects solid boundary walls or internal partition walls inside a doorway reveal and reports `has_door_reveal_blocker`.
- Generator version is now `proc_maze_fixed_layout_v0.10_door_reveal_clearance`.
- Validation passed: parse, proc-maze bake, no-ceiling bake, structure validation, playable validation, and no-ceiling validation. Current metrics include `door_to_wall=false` and `door_reveal_blocker=false`.

## Proc-maze Distributed Long Light Sources

2026-05-04:
- Fixed the long ceiling-light issue where a rectangular lamp visually looked long but the real light came from one bright center point.
- Long proc-maze lamp panels now create multiple weaker `OmniLight3D` sources along the panel's long axis while keeping one visible panel Mesh.
- Current fixed-map metrics: `rooms=36`, `light fixtures=28`, `real light sources=38`. Long corridor fixtures use 3 sources in the current layout.
- Distributed sources use lower per-source energy, shorter range, and stronger attenuation than a full single room light, reducing the center hotspot and spreading illumination along the fixture.
- `LightingController.gd` now groups multiple source lights by fixture owner for flicker, so a distributed lamp still behaves as one lamp.
- `SceneValidator.gd` and no-ceiling validation now distinguish fixture count from real source count and validate that every real source sits under its owner panel.
- Generator version is now `proc_maze_fixed_layout_v0.9_distributed_long_lights`.
- Rebaked only `scenes/tests/Test_ProcMazeMap.tscn` and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`; `scenes/mvp/FourRoomMVP.tscn` was not modified.
- Validation passed: Godot parse, proc-maze bake/structure/playable/no-ceiling validations, plus shared MVP `ValidateLightFlicker.gd` and `ValidateSceneShadows.gd`.

## Proc-maze Ceiling Light Placement

2026-05-04:
- Changed proc-maze ceiling lights from mandatory one-per-space placement to safe optional placement.
- `ProcMazeSceneBuilder.gd` now computes a light layout per module and skips narrow or complex corridor spaces where a ceiling panel would clip walls or make the choke feel cluttered.
- Required-unlit cases include narrow corridors, L-turn corridors, T junctions, offset corridors, and short non-long corridor modules. Long corridors and rooms still get lights only when the panel fits the occupied-cell footprint with wall clearance.
- Light panels and matching `OmniLight3D` nodes now carry owner/type metadata so validators can associate a lamp with its generated module.
- `SceneValidator.gd` now rejects panels outside the owner footprint, panels overlapping walls/internal partitions, missing visual/real-light pairs, and lamps inside spaces that should remain unlit.
- `ValidateProcMazeNoCeilingPreview.gd` now validates against `active_light_count` instead of assuming every room has a lamp.
- Generator version is now `proc_maze_fixed_layout_v0.8_light_spacing_unlit_narrow`.
- Rebaked only `scenes/tests/Test_ProcMazeMap.tscn` and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`; `scenes/mvp/FourRoomMVP.tscn` was not modified.
- Validation passed: parse, proc-maze bake, proc-maze structure validation, playable validation, no-ceiling bake, and no-ceiling validation. Current metrics: `rooms=36`, `lights=28`, `narrow_corridor=8`, `overlap=false`, `door_to_wall=false`.

## Reference Style Revert

2026-05-04:
- Reverted the reference-style texture/trim pass at the user's request.
- Restored previous wall and door-frame texture PNGs from `E:\godot后室_backups\godot后室_backup_20260501_155923`, and regenerated the previous uniform floor texture with `RegenerateUniformFloorTextures.gd`.
- Restored material parameters for `backrooms_wall.tres`, `backrooms_door_frame.tres`, `backrooms_ceiling.tres`, and `backrooms_ceiling_light.tres`.
- Removed the newly added baseboard generation path from `SceneBuilder.gd` and `ProcMazeSceneBuilder.gd`.
- Restored room ceiling-light panel size to `Vector3(1.2, 0.08, 0.7)`.
- Removed the reverted reference-style generator script and unused ceiling/diffuser texture source files.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`, `scenes/tests/Test_ProcMazeMap.tscn`, and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`; saved scenes no longer contain `Baseboard` / `Trim` nodes.
- Validation passed: Godot parse, MVP bake/clean/material-lighting/generated-mesh/shadow validations, proc-maze bake/structure/playable/no-ceiling validations, and non-headless player-view screenshot capture.

## Reference Style Material Pass

2026-05-04:
- Added a reference-style material pass based on the user's wall/door/ceiling examples: yellow-green vertical wallpaper, gray-beige trim, speckled acoustic ceiling tiles, and warm fluorescent diffuser panels.
- Added `scripts/tools/generate_reference_style_textures.py`; generated deterministic albedo/normal PNGs for wall, floor, door-frame/trim, ceiling, and ceiling-light diffuser materials, plus `artifacts/screenshots/reference_style_texture_contact_sheet_20260504.png`.
- Updated shared materials: `backrooms_wall.tres`, `backrooms_door_frame.tres`, `backrooms_ceiling.tres`, and `backrooms_ceiling_light.tres`. Wall UVs are aligned so the wallpaper bottom wear stays near the base instead of repeating as a horizontal band.
- Added unified baseboard generation to `scripts/core/SceneBuilder.gd` and `scripts/proc_maze/ProcMazeSceneBuilder.gd`. Trim is generated for solid walls, opening-wall segments, proc-maze boundary walls, and proc-maze internal partition walls through shared builder rules.
- Changed ceiling-light panels to longer/narrower diffuser panels while keeping the current OmniLight energy/range/attenuation and darker ambient baseline.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`, `scenes/tests/Test_ProcMazeMap.tscn`, `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`, and `scenes/debug/BaseResourceGallery.tscn`.
- Validation passed: Godot parse, MVP bake/clean/material-lighting/generated-mesh/shadow validations, proc-maze bake/structure/playable/no-ceiling validations, and BaseResourceGallery bake/validation. Non-headless viewport capture saved `artifacts/screenshots/test_proc_maze_map.png`.

## Lighting Balance Tightening

2026-05-04:
- Lowered the shared warm world ambient baseline so areas without direct light no longer stay as evenly bright. MVP and proc-maze generated scenes now use `ambient_light_energy = 0.10` instead of `0.18`.
- Slightly increased direct ceiling-light strength while increasing falloff: MVP generated lights use `light_energy = 1.12`, `omni_range = 6.0`, `omni_attenuation = 0.92`; proc-maze generated lights use `light_energy = 1.18`, `omni_range = 6.2`, `omni_attenuation = 0.92`.
- Kept light range unchanged so the stronger lights do not spread farther; the intended result is brighter near-light zones with darker off-axis/corner areas.
- Updated `ValidateSceneShadows.gd` to validate the new darker ambient / stronger falloff range.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`, `scenes/tests/Test_ProcMazeMap.tscn`, and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`. Validation passed: MVP clean rebuild, material/lighting rules, scene shadows, light flicker, generated mesh rules, proc-maze structure/playable/no-ceiling validations, and bounded startup checks.

## Player Scale And Ceiling-Wall Seam

2026-05-04:
- Preserved the user's saved MVP player visual scale as the global player-module visual rule. The user had scaled the `FourRoomMVP.tscn` `PlayerRoot/Player` instance to `1.4666373`; this was folded into `scenes/modules/PlayerModule.tscn` by changing `ModelRoot.scale` from `0.1` to `0.14666373`.
- Removed the extra MVP scene-instance player scale so `FourRoomMVP.tscn` no longer double-scales the player. Proc-maze and future scenes now inherit the same visual player size from `PlayerModule.tscn`.
- Kept the player capsule collision at the previous 0.28m radius / 1.6m height. Scaling the whole collision by 1.466x would approach or exceed the current 2.15m door clearance and risks door-frame snagging.
- Fixed the visible ceiling-wall seam/light leak without reintroducing coplanar wall top caps. `SceneBuilder.gd` and `WallOpeningBody.gd` now extend generated wall/opening vertical side faces 0.08m into the ceiling instead of 0.025m.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`. Validation passed: clean rebuild, generated mesh rules, material/lighting rules, scene shadows, Phase 3 occlusion, MVP startup, and proc-maze playable validation.

## Procedural Maze Corridor Width Tiers

2026-05-04:
- Reworked proc-maze spatial sizing so corridors and rooms no longer share the same 6m-wide grid language.
- `data/proc_maze/module_registry.json` is now `proc_maze_registry_v0.3_corridor_width_tiers` with `cell_size=2.5` and explicit width tiers: `narrow_corridor` = 1 cell / 2.5m, `normal_corridor` = 2 cells / 5.0m, `normal_room` = 3 cells / 7.5m, and `large_room` / `hub_room` = 4 cells / 10.0m.
- Added explicit corridor module IDs: `corridor_narrow_straight`, `corridor_long_straight`, `corridor_l_turn`, `corridor_t_junction`, and `corridor_offset`.
- Rebuilt the fixed 37-node test layout around a "room opens -> corridor narrows -> room opens again" rhythm. The map now validates at `narrow_corridor=11`, `normal_corridor=7`, `normal_room=12`, `large_width=5`, `hub_width=2`.
- Removed old same-width corridor/room module usage from the proc-maze graph (`corridor_long_3`, `corridor_long_5`, `corridor_2x1`, `room_narrow_long`, `room_1x1`, etc. are not used by the current target scenes).
- `MapValidator.gd` now rejects corridor width tiers that are too close to normal room width, long corridors with insufficient aspect ratio, normal rooms that are too corridor-like, missing required corridor module types, and corridors with too many graph connections/side doors.
- `ProcMazeSceneBuilder.gd`, `TestProcMazeMap.gd`, and `DebugView.gd` now use the 2.5m proc-maze cell size. Corridor ceiling-light panels are elongated along corridor direction while preserving the existing light/material system.
- Rebaked both `scenes/tests/Test_ProcMazeMap.tscn` and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`. `scenes/mvp/FourRoomMVP.tscn` was not modified.
- Validation passed: parse, bake, structure validation, playable movement, no-ceiling preview bake/validation, layout capture, and bounded startup checks.

## New Session Handoff

2026-05-04:
- Updated `docs/CODEX_FRESH_SESSION_PROMPT.md` as the current entry point for a new Codex session.
- Added `docs/HANDOFF_20260504_PROC_MAZE.md` with the current proc-maze status, key files, validation metrics, and next steps.
- Added `docs/CLEANUP_CANDIDATES_20260504.md` so cleanup can be done deliberately without deleting accepted scenes, models, or validation evidence.
- Mirrored the same handoff documents into `四房间MVP_Agent抗遗忘执行包/docs/`.
- Removed two non-evidence transient logs: empty `logs/run_proc_maze_no_ceiling_preview.log` and failed/hung `logs/proc_maze_variety_screenshot_20260504.log`.

## Procedural Maze Space Variety

2026-05-04:
- Reworked the fixed proc-maze test from mostly rectangular rooms into a module-type-based layout using `proc_maze_fixed_layout_v0.2_space_variety`.
- Added registry coverage for the requested space types: long corridors, L-turn corridors, T junctions, L-shaped rooms, wide/narrow recognizable rooms, 3-door/4-door hubs, and internally partitioned large-room variants.
- The generated test map now uses real occupied-cell shapes instead of treating every footprint as a plain bounding rectangle. L-shaped modules create L-shaped floor/ceiling/collision, and large-room modules add reusable internal partition walls.
- The current fixed map validates at `rooms=37`, `main=18`, `branches=10`, `loops=4`, `dead=5`, `long=5`, `l_turn=7`, `l_room=4`, `internal_large=3`, `hubs=2`, `plain_rect=5`, `special=2`.
- `MapValidator.gd` now rejects maps that break the new variety rules: too many plain rectangles, missing per-area long/L/recognizable structures, repeated room signature + door positions, too many straight visible door chains, or more than two adjacent long corridors.
- `SceneValidator.gd` now validates large-room internal structures and uses occupied cells for overlap checks.
- Rebaked both `scenes/tests/Test_ProcMazeMap.tscn` and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`. The four-room MVP scene was not modified.
- Validation passed: structure, playable movement, no-ceiling preview, startup checks, and source forbidden-pattern scans. Layout evidence: `artifacts/screenshots/test_proc_maze_layout.png`.

## Procedural Maze No-Ceiling Preview

2026-05-04:
- Added a separate preview scene at `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`.
- This preview is not the playable third-person scene. It disables `PlayerRoot`, `CameraRig`, and runtime player systems, then uses the root `Camera3D` as an orthogonal pulled-back god-view camera.
- The preview is generated by the same proc-maze pipeline and module rules as `Test_ProcMazeMap.tscn`; it does not hand-place walls or change module geometry rules.
- The preview omits ceiling meshes/collisions while keeping floors, walls, wall openings, door frames, markers, debug labels, and ceiling lights visible for full-map inspection.
- Added `open_proc_maze_no_ceiling_preview.bat` and `run_proc_maze_no_ceiling_preview.bat`.
- Validation passed: `rooms=37`, `floors=37`, `walls=101`, `openings=40`, `frames=40`, `lights=37`, `ceilings=0`, `camera_size=120.36`, `player=false`.
- Latest logs: `logs/proc_maze_no_ceiling_fullmap_bake_20260504.log`, `logs/proc_maze_no_ceiling_fullmap_validate_20260504.log`, and `logs/proc_maze_no_ceiling_fullmap_startup_20260504.log`.

## Procedural Maze Playable Test

2026-05-04:
- `scenes/tests/Test_ProcMazeMap.tscn` is now playable with the existing player module and third-person camera. The fixed-layout generated maze remains separate from `scenes/mvp/FourRoomMVP.tscn`.
- `scripts/proc_maze/TestProcMazeMap.gd` now owns the test-scene gameplay hookup: `PlayerRoot/Player`, `CameraRig/Camera3D`, `Systems/LightingController`, and `Systems/ForegroundOcclusion`.
- Player spawn is data-driven from the generated `Entrance` marker instead of a room-specific spawn name. Current validated start is `Marker_N00` at `(3, 0.05, 3)`.
- `scripts/tools/ValidateProcMazePlayable.gd` verifies that the player, gameplay camera, lighting/occlusion systems, entrance placement, and forward movement work after a rebuild. Validation passed with player movement from `(3.0, 0.05, 3.0)` to `(8.090853, 0.000838, 3.0)`.
- `scripts/tools/BakeTestProcMazeMap.gd` now preserves external instance boundaries when saving, so `PlayerModule.tscn` is referenced as a scene instance instead of expanding the GLB internals into the test map.
- Latest validation logs: `logs/proc_maze_playable_bake_20260504_4.log`, `logs/proc_maze_playable_validate_structure_20260504_2.log`, `logs/proc_maze_playable_movement_20260504_2.log`, and `logs/proc_maze_playable_scene_startup_20260504.log`.

## Current Phase Status

Phase 3 foreground occlusion MVP is implemented and automatically validated. Player animation, free third-person camera orbit, saved monster scale, random ceiling-light flicker, the first monster MVP, and the full clean four-room rebuild are also implemented and automatically validated. Do manual visual playtest/tuning before widening scope.

## Canonical Scene Object Generation Standard

2026-05-03:
- Fixed the follow-up wall UV direction issue at the shared generator level. Wall, wall-joint, ceiling-side, wall-opening, and door-frame vertical UVs now increase upward instead of using the previous negative-height V direction.
- Updated `GeneratedMeshRules.gd`, `WallOpeningBody.gd`, and `DoorFrameVisual.gd` so same-type generated vertical faces share the upright UV rule.
- `ValidateGeneratedMeshRules.gd` now rejects generated vertical triangles whose UV `v` does not increase with local height.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; validation passed: `BAKE_FOUR_ROOM_SCENE PASS`, `GENERATED_MESH_RULES_VALIDATION PASS`, `CLEAN_REBUILD_SCENE_VALIDATION PASS`, `MATERIAL_LIGHTING_RULES_VALIDATION PASS`, `SCENE_SHADOW_VALIDATION PASS`, `FLOOR_COVERAGE_VALIDATION PASS`, and `PHASE3_OCCLUSION_VALIDATION PASS`.
- `DiagnoseWallVisuals.gd` still reports shared generated mesh/material/tangent rules for walls, wall joints, and wall openings after the UV flip.

2026-05-03:
- Accepted the production standard that scene objects are generated by component type, not by room name, wall direction, or one-off editor edits. Future layout work should adjust specs, parameters, and placement data while keeping one generator/module path per object type.
- Fixed the remaining direction-specific doorway issue: `WallOpeningBody.gd` now builds one canonical local U-wall mesh and rotates the body for z-axis openings; collision children stay in the same local canonical layout.
- Fixed `DoorFrameVisual.gd` the same way: door frames now build one canonical local U-frame mesh and rotate for z-axis doors. The previous x/z coordinate branches and non-uniform door-frame scaling were removed.
- `SceneBuilder.gd` now creates all door frames with `scale = Vector3.ONE`; door-frame trim/depth constants are shared for all four portals.
- `ValidateCleanRebuildScene.gd` now rejects wall openings or door frames that use non-identity scale, wrong canonical yaw, wrong span axis, non-uniform portal width, or non-canonical local mesh dimensions.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`. The saved scene now has `WallOpening_P_AB` / `DoorFrame_P_AB` rotated for the z-axis and `WallOpening_P_BC` / `DoorFrame_P_BC` unrotated for the x-axis, with the same local mesh dimensions and shared materials.
- Validation: `BAKE_FOUR_ROOM_SCENE PASS`; `CLEAN_REBUILD_SCENE_VALIDATION PASS`; `GENERATED_MESH_RULES_VALIDATION PASS`; material lighting, scene shadows, floor coverage, Phase 3 occlusion, light flicker, seam-grime removal, monster saved scale, monster AI, and free camera orbit validations passed.
- MCP editor inspection was attempted, but the current Godot editor instance reported "Godot Editor not connected" to the MCP tool. The same node properties were verified through the saved scene and Godot validation scripts.

## Full Clean Four-Room Rebuild

2026-05-02:
- Rebuilt the saved four-room MVP scene from the unified wall/floor/ceiling/door-frame generators instead of continuing to edit the legacy `LevelRoot/Rooms` container.
- `SceneBuilder.gd` now removes any legacy `LevelRoot/Rooms` node during build.
- Baked room shell geometry now lives under `LevelRoot/Geometry`: continuous floor collision, four regular floor visuals, walls, wall joints, portal wall openings, single-piece U-shaped door frames, ceilings, and ceiling-light panels.
- Room logic metadata now lives under `LevelRoot/Areas`: four room area nodes with room IDs, area IDs, bounds, and portal IDs. These nodes contain no geometry.
- `MonsterController.gd` now reads room area metadata from `LevelRoot/Areas`; portals stay under `LevelRoot/Portals`.
- `BakeFourRoomScene.gd` now owns and saves `Geometry`, `Areas`, `Portals`, `Markers`, and `Lights`.
- Added `scripts/tools/ValidateCleanRebuildScene.gd`, which fails if `LevelRoot/Rooms` returns or if geometry and area metadata are mixed again.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; MCP scene-tree inspection confirmed `LevelRoot` now contains `Portals`, `Lights`, `Props`, `Markers`, `Geometry`, and `Areas`, with no `Rooms` child.
- Validation: Godot 4.6.2 parse passed; `BAKE_FOUR_ROOM_SCENE PASS`; `CLEAN_REBUILD_SCENE_VALIDATION PASS`; generated mesh rules, material lighting rules, scene shadows, floor coverage, Phase 3 occlusion, light flicker, seam-grime removal, monster saved scale, monster AI, active residue scan, and short startup all passed.

## Type-Based Wall Generation Cleanup

2026-05-02:
- Reworked the four-room generator so walls are generated by component type rather than by room ownership.
- `SceneBuilder.gd` now uses one `_get_wall_piece_specs()` list and one `_create_wall_piece()` entry point for wall bodies. A wall piece with `type = "solid"` creates a solid wall/joint body; a wall piece with `type = "opening"` creates a wall body with a doorway opening.
- Removed the separate room/area-based wall-opening generation path from the builder loop. Door frames remain a separate trim component, but they share the same static visual layer as walls.
- Static room geometry now uses one `STATIC_GEOMETRY_LAYER`: floors, ceilings, solid walls, wall openings, door frames, and ceiling light panels. Room area IDs remain metadata for room/portal/marker systems, not a reason to render one wall differently.
- All four ceiling lights now use the same static + actor mask (`257`) so lighting is no longer split by Room_A/B/C/D wall ownership.
- `ValidateSceneShadows.gd` now validates the single static layer rule instead of room-specific layer masks.
- Backed up the pre-refactor scene to `scenes/mvp/backups/FourRoomMVP.before_type_wall_refactor_20260502_142609.tscn`, then rebaked `scenes/mvp/FourRoomMVP.tscn`.
- Validation: Godot 4.6.2 parse passed; scene bake passed; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; `GENERATED_MESH_RULES_VALIDATION PASS`; `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; floor coverage, Phase 3 occlusion, light flicker, seam-grime removal, monster saved scale, forbidden-pattern scan, and short startup all passed.

## UV/Tangent Direction And Floor Visibility

2026-05-02:
- Treated the latest "UV direction reversed" observation as two related generated-mesh issues: floor face orientation under backface culling, and vertical wall tangent-basis inconsistency for normal-mapped materials.
- Fixed the per-room visual floor ArrayMesh triangle/UV order in `SceneBuilder.gd`, then rebaked `scenes/mvp/FourRoomMVP.tscn`.
- Updated `GeneratedMeshRules.gd` so vertical generated faces use a shared wall tangent basis (`Vector3.DOWN.cross(normal)` with a positive tangent sign) instead of deriving mixed signs from each face's UV winding.
- Updated `ValidateGeneratedMeshRules.gd` to reject generated vertical wall/opening/door-frame/ceiling side faces that regress to the old mixed tangent basis.
- `DiagnoseWallVisuals.gd` now reports ordinary walls, wall joints, and portal wall openings with unified vertical tangent signs. Before this pass, z-facing and x-facing openings used different tangent sign patterns and could make the same normal map read as different lighting.
- Visual screenshot check saved `artifacts/screenshots/wall_tangent_visual_20260502_134323.png`; the floor renders as the pale tile material instead of a black background.
- Validation: Godot 4.6.2 parse passed; `BAKE_FOUR_ROOM_SCENE PASS`; `GENERATED_MESH_RULES_VALIDATION PASS`; `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.061`; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; `LIGHT_FLICKER_VALIDATION PASS`; `SEAM_GRIME_REMOVAL_VALIDATION PASS`; short startup exited 0.

## Light-Layer Wall/Floor Visual Consistency

2026-05-02:
- Compared the user-selected "normal" portal walls (`WallOpening_P_AB` and `WallOpening_P_CD`) against other wall openings, ordinary wall boxes, wall joints, floor visuals, and ceiling lights.
- Confirmed through MCP and `scripts/tools/DiagnoseWallVisuals.gd` that the saved meshes already shared the same Backrooms wall material and generated `ArrayMesh` render path; the mismatch was not a missing material resource.
- Fixed the actual scene-wide lighting rule issue: previously every static visual stayed on default render layer `1`, and all ceiling lights used full `light_cull_mask` / `shadow_caster_mask`, so multiple room lights filled the same wall/floor shadows unevenly.
- `SceneBuilder.gd` now assigns explicit room render layers for static walls, floors, ceilings, door frames, and portal wall openings. Shared portal visuals receive both adjacent room layers.
- Each `CeilingLight_Room_*` now lights only its room layer plus the actor layer, and casts shadows only for that same mask. This keeps real room projection and actor shadows while reducing cross-room light flooding.
- `WallOpeningBody.gd` now owns a saved/runtime `visual_layers` property so portal wall children keep the same render-layer rule after script rebuilds.
- Player and monster imported `MeshInstance3D` nodes now move onto the actor light layer while preserving real shadow casting.
- Backrooms wall, floor, door-frame, ceiling, and foreground cutout materials now use backface culling instead of two-sided rendering, reducing backside lighting artifacts in the Mobile/editor preview.
- Ambient fill was reduced from `0.26` to `0.18` after layer isolation so floor and character shadows remain readable.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`.
- Validation: Godot 4.6.2 parse passed; `BAKE_FOUR_ROOM_SCENE PASS`; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; `GENERATED_MESH_RULES_VALIDATION PASS`; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; `LIGHT_FLICKER_VALIDATION PASS`; `SEAM_GRIME_REMOVAL_VALIDATION PASS`; `MONSTER_AI_VALIDATION PASS`; short startup exited 0. The recurring MCP port 7777 stderr line is the known non-blocking conflict when the editor already owns the runtime server port.

## Runtime Visual Lighting Unification

2026-05-02:
- Reconnected Godot MCP after the Codex restart and inspected the scene through MCP. The selected portal wall meshes and wall-joint meshes already pointed to `res://materials/backrooms_wall.tres`; the floor pointed to `res://materials/backrooms_floor.tres`, so the remaining mismatch was a runtime visual-lighting response problem rather than a per-wall material assignment problem.
- Fixed the foreground-occlusion cutout shader so it now uses `diffuse_lambert_wrap`, matching the standard Backrooms wall material diffuse rule. This avoids walls being lit differently while the local player-area cutout material is active.
- Added one low-strength `WorldEnvironment` under `LevelRoot/Lights` in both baked and runtime builds. It uses warm color ambient light at energy `0.26` to give every room surface the same baseline illumination while preserving real `OmniLight3D` room lights and real actor shadows.
- Further restrained normal-map strength for Mobile readability: wall `0.22`, floor `0.28`, and door frame `0.24`. The floor material also has a small albedo multiplier so the tile texture does not read as a dark overlay.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; MCP confirmed `LevelRoot/Lights/WorldEnvironment` is present in the saved scene.
- Updated `ValidateSceneShadows.gd` so baked and runtime scenes fail if the ambient environment is missing or outside the accepted low-fill range.
- Updated `ValidateMaterialLightingRules.gd` so the stricter wall/floor/door-frame normal-strength limits and floor brightness rule are enforced.
- Validation: Godot 4.6.2 parse passed; `BAKE_FOUR_ROOM_SCENE PASS`; `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; `GENERATED_MESH_RULES_VALIDATION PASS`; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; `LIGHT_FLICKER_VALIDATION PASS`; `SEAM_GRIME_REMOVAL_VALIDATION PASS`; short startup exited 0; MCP debug run started and stopped successfully. Active forbidden-pattern scan found only the approved `foreground_occlusion_cutout.gdshader` `ALPHA` use.

## Unified Wall Mesh Generation And Floor Shadow Readability

2026-05-02:
- Fixed the remaining wall-surface inconsistency by removing the mixed ordinary-wall `BoxMesh` path. Ordinary walls, wall-joint filler blocks, ceilings, portal wall openings, door frames, and floor visuals now all use generated `ArrayMesh` render data when they carry Backrooms materials.
- Added `GeneratedMeshRules.build_box_mesh()`, which builds box visuals with explicit vertex, normal, UV, and tangent arrays. This makes regular walls and `WallJoint_*` filler blocks follow the same render rule as the already-generated portal openings and floor panels.
- Changed `SceneBuilder.gd` so `_create_box()` uses the shared generated mesh path for wall and ceiling visuals while keeping simple `BoxShape3D` collision for mobile stability.
- Changed `WallOpeningBody.gd` UVs from per-opening normalized UVs to the same wall world-size UV rule, so doorway wall faces no longer use a different texture density rule from regular walls.
- Tightened real ceiling-light shadow tuning for floor readability: `shadow_bias = 0.02`, `shadow_normal_bias = 0.35`, and `shadow_opacity = 1.0`. This keeps projection/shadow behavior on real `OmniLight3D` lights instead of fake floor decals or transparent shadow planes.
- Expanded `ValidateGeneratedMeshRules.gd` so it now rejects ordinary walls/joints or ceilings that fall back to `BoxMesh` while using the Backrooms material set.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; `Wall_South_A/Mesh`, `WallJoint_Center/Mesh`, ceilings, wall openings, door frames, and floor panels all validate under the shared generated mesh rule. The only remaining `BoxMesh` resources in the scene are the four ceiling-light visual panels.
- Validation: Godot 4.6.2 parse passed; `BAKE_FOUR_ROOM_SCENE PASS`; `GENERATED_MESH_RULES_VALIDATION PASS`; `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; `LIGHT_FLICKER_VALIDATION PASS`; `SEAM_GRIME_REMOVAL_VALIDATION PASS`; short normal startup exited 0. Forbidden-pattern scan found only the approved `foreground_occlusion_cutout.gdshader` `ALPHA` use.

## Unified Material Lighting And Shadow Readability

2026-05-02:
- Fixed the latest visual inconsistency where floor lighting read too flat/dark and two inner portal-wall faces could appear much darker than the rest of the wall set.
- Standardized `backrooms_wall.tres`, `backrooms_floor.tres`, `backrooms_door_frame.tres`, and `backrooms_ceiling.tres` on Lambert Wrap diffuse lighting for the Mobile renderer so identical wall rules do not produce harsh face-to-face brightness shifts.
- Reduced the normal-map strength on wall and door-frame materials from `0.45` to `0.32`, and floor normal strength from `0.60` to `0.42`, keeping texture detail while reducing blackened normals under point lights.
- Raised runtime and baked room light energy from `0.82` to `1.05`; all four ceiling lights now also save `shadow_bias = 0.035`, `shadow_normal_bias = 0.8`, and `shadow_opacity = 0.9` for more readable contact shadows from the real scene lights.
- Hardened `SceneBuilder.gd` so rebuilds use the builder's owning scene root instead of relying on `get_tree().current_scene`; this prevents tool-script rebakes from preserving stale room child transforms such as an offset `Floor_Room_A`.
- Added `scripts/tools/ValidateMaterialLightingRules.gd`, validating baked and runtime wall/floor/door-frame/ceiling material assignments and the unified diffuse/normal-strength rules.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; `Floor_Room_A` is back at identity transform, and all four `CeilingLight_Room_*` nodes save the new light and shadow settings.
- Validation: Godot 4.6.2 parse passed; `BAKE_FOUR_ROOM_SCENE PASS`; `MATERIAL_LIGHTING_RULES_VALIDATION PASS`; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; `LIGHT_FLICKER_VALIDATION PASS lights=4 ... base=1.050 ...`; `GENERATED_MESH_RULES_VALIDATION PASS`; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; short normal startup exited 0. The only recurring runtime warning was the known non-blocking MCP port 7777 conflict when the editor already owns that port.

## Ceiling Light Coverage

2026-05-02:
- Fixed incomplete room coverage from the ceiling light projection. The previous `OmniLight3D.omni_range = 4.2` could miss room corners and doorway-adjacent areas in a 6m room because the center ceiling light to floor-corner distance is roughly 4.8m before any margin.
- Added shared runtime constants in `SceneBuilder.gd`: `CEILING_LIGHT_RANGE = 6.0` and `CEILING_LIGHT_ATTENUATION = 0.78`.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; all four `CeilingLight_Room_*` nodes now save `omni_range = 6.0`, `omni_attenuation = 0.78`, `light_energy = 0.82`, and `shadow_enabled = true`.
- Updated `ValidateSceneShadows.gd` so baked and runtime scenes fail if any ceiling light range is too small or falloff is too steep for full-room coverage.
- Validation: Godot 4.6.2 parse passed; `BAKE_FOUR_ROOM_SCENE PASS`; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; `LIGHT_FLICKER_VALIDATION PASS`; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.063`; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; `GENERATED_MESH_RULES_VALIDATION PASS`; short normal startup exited 0 with only the known non-blocking MCP port warning when the editor owns port 7777.

## Generated Mesh Render Rules

2026-05-02:
- Diagnosed the recurring dark/black wall issue on selected `WallOpening_P_*` meshes. These portal-opening walls are generated `ArrayMesh` geometry, while ordinary walls are `BoxMesh` geometry.
- The generated U-shaped wall/opening meshes were using the wall material as a surface material but were not fully following the same render data path as ordinary walls. Because the Backrooms materials use normal maps, missing tangent data can make generated faces shade incorrectly under Mobile lighting.
- Added `scripts/scene/GeneratedMeshRules.gd` as the shared helper for script-generated visual meshes.
- `WallOpeningBody.gd`, `DoorFrameVisual.gd`, and the regular floor visual mesh generation in `SceneBuilder.gd` now build ArrayMeshes with vertex, normal, UV, and tangent arrays.
- Generated wall openings, door frames, and floor visual panels now also set `material_override` to their expected material, matching ordinary wall/floor/trim behavior in editor preview, foreground occlusion restore, and runtime rebuilds.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; `WallOpening_P_DA/Mesh` and the other generated portal walls now save `material_override = backrooms_wall.tres`.
- Validation: Godot 4.6.2 parse passed; `GENERATED_MESH_RULES_VALIDATION PASS`; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.061`; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; short normal startup exited 0 with only the known non-blocking MCP port warning when the editor owns port 7777.

## Third-Person Free Orbit Camera

2026-05-02:
- Changed `CameraController.gd` from the earlier +/-90 degree yaw clamp and movement-triggered recenter model to a common third-person free orbit camera.
- Mouse and touch drag now rotate the camera yaw freely through 360 degrees; only pitch remains clamped by `min_pitch_degrees` and `max_pitch_degrees`.
- The camera no longer recenters when the player moves. The selected orbit angle stays under player control until the next mouse/touch drag.
- Existing controls remain: click captures mouse, `Esc` releases mouse, `WASD` / arrow keys move relative to the camera, `Shift` sprints, and `S` / down arrow remains backpedal rather than turn.
- `scripts/tools/ValidateCameraRecenter.gd` now validates the new free-orbit behavior despite its legacy filename.
- Validation: Godot 4.6.2 parse passed; `CAMERA_FREE_ORBIT_VALIDATION PASS yaw_delta=2.700 stationary_delta=0.000 moving_delta=0.000 pitch=-0.087..0.209`; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=2 door_hidden_count=4`; short normal startup exited 0.

## Seam Grime And Contact Detail Removed

2026-05-02:
- Reverted the global seam grime/contact-detail pass by user request because the added base/ceiling/door contact marks made the prototype look visually cluttered.
- Removed the `SceneBuilder.gd` generation of `WallSeamGrime`, `CeilingSeamGrime`, `DoorSeamGrime`, and `DoorFrameSeamGrime`.
- Removed the generated seam material and texture assets: `materials/backrooms_seam_grime.tres`, `materials/textures/backrooms_seam_grime_albedo.png`, and its `.import`.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`; the baked scene no longer references `backrooms_seam_grime` and has no `seam_grime` nodes.
- `scripts/tools/ValidateSeamGrime.gd` now validates the removal state and reports `SEAM_GRIME_REMOVAL_VALIDATION PASS`.
- Validation: Godot 4.6.2 parse passed after rebake; `SEAM_GRIME_REMOVAL_VALIDATION PASS`; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; short normal startup exited 0 with only the known non-blocking MCP port warning when the editor owns port 7777.

## Regular Floor Visual Panels

2026-05-02:
- Replaced the old visual floor pair `Floor_SouthStrip` / `Floor_NorthStrip`. Those two differently sized strips made the overall floor outline and tile texture join read as irregular.
- `SceneBuilder.gd` now generates one regular visual floor panel per room: `Floor_Room_A`, `Floor_Room_B`, `Floor_Room_C`, and `Floor_Room_D`.
- Visual floor panels are `MeshInstance3D` only, have no collision, and use world-coordinate UVs so the square floor texture aligns consistently across room boundaries.
- Physics still uses the single continuous `Floor_WalkableCollision` body so the player and monster keep stable floor contact across seams.
- Validation: Godot 4.6.2 parse passed; `BAKE_FOUR_ROOM_SCENE PASS path=res://scenes/mvp/FourRoomMVP.tscn`; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.063`; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=2 door_hidden_count=4`; short normal startup exited 0.

## Foreground Occlusion Edge Smoothing

2026-05-03:
- Fixed the foreground occlusion cutout material so it remains a local player-area mask without turning the whole occluding wall into a flat untextured color.
- `materials/foreground_occlusion_cutout.gdshader` now uses repeat-enabled albedo/normal samplers and applies `UV * uv_scale + uv_offset`.
- `ForegroundOcclusion.gd` now preserves source material parameters for both accepted `StandardMaterial3D` walls/door frames and the contact-AO experiment `ShaderMaterial` walls.
- `ValidatePhase3Occlusion.gd` now verifies the cutout keeps original wall/door-frame texture and UV scale in the base scene.
- `ValidateContactAOExperiment.gd` now verifies a contact-AO ShaderMaterial wall keeps its texture and UV scale after foreground cutout is applied.
- Screenshot evidence: `artifacts/screenshots/foreground_cutout_texture_20260503 223354.png`.
- Validation passed: `PHASE3_OCCLUSION_VALIDATION PASS`, `CONTACT_AO_EXPERIMENT_VALIDATION PASS`, and active forbidden-pattern scan found only the approved local cutout `ALPHA`.

2026-05-02:
- Fixed the one-frame wall flash that could appear when the player was occluded and forward/back movement made the camera/player line cross a wall boundary.
- `ForegroundOcclusion.gd` now casts multiple camera-aligned probe rays around the player target instead of relying on only the center line.
- Occlusion probing is now bidirectional, so a wall can still be detected when the camera is very close to or just past the wall plane.
- Cutout materials now use a short release delay (`cutout_release_delay = 0.16`) before restoring the original wall material. This keeps the local cutout alive across boundary frames and avoids visible wall flicker while moving.
- `ValidatePhase3Occlusion.gd` now verifies that wall openings, door frames, and foreground walls keep their local cutout for the immediate clear frame, then restore after the release delay.
- Validation: Godot 4.6.2 parse passed; `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; `CAMERA_RECENTER_VALIDATION PASS stationary_offset=0.660 moving_offset=0.013`; short normal startup exited 0; touched-file forbidden-pattern check passed.

## Four-Room Mechanism Archive

2026-05-01:
- Established `docs/MECHANICS_ARCHIVE.md` as the reusable mechanism record for the current four-room verification scene.
- The archive now records the room's role as a sandbox for validating scene layout, floor collision, wall/door-frame geometry, materials, ceiling lights, flicker, shadows, camera/control behavior, player animation, foreground occlusion, and monster MVP behavior.
- Added an update protocol: accepted mechanics should record purpose, files, behavior, tuning knobs, validation scripts, known limits, reuse notes, and mirror updates under `四房间MVP_Agent抗遗忘执行包/docs/`.
- Validation: documentation-only change; no Godot runtime validation required.

## Monster Saved Scale

2026-05-01:
- `GameBootstrap.gd` now places `MonsterRoot/Monster` at `Spawn_Monster_D` by changing only `global_position`, preserving the editor-saved monster rotation and scale.
- Current saved `FourRoomMVP.tscn` monster instance scale is `(0.953989, 0.387199, 0.688722)`.
- Added `scripts/tools/ValidateMonsterSavedScale.gd`.
- Validation: `MONSTER_SAVED_SCALE_VALIDATION PASS saved_scale=(0.953989, 0.387199, 0.688722) runtime_scale=(0.953989, 0.387199, 0.688722)`; monster AI regression passed; normal startup exited 0.

## Floor Coverage And Monster Panic Tuning

2026-05-01:
- Added locomotion-direction-aware monster animation playback.
- `MonsterController.gd` now compares the monster's actual horizontal velocity with its body forward direction while `Walk` or `Run` is playing. If the body is moving backward relative to its facing direction, the locomotion animation speed becomes negative so the legs play in reverse instead of forward-running while sliding backward.
- Added `flee_turn_speed = 18.0` so fleeing usually turns the body toward the escape direction faster; reverse playback is used only when the body is actually backing up during a turn or obstruction.
- `ValidateMonsterAI.gd` now verifies forward movement plays the locomotion animation forward and backward movement plays it in reverse.
- Validation: Godot 4.6.2 parse passed; `MONSTER_AI_VALIDATION PASS state=WANDER flee_z=1.355 animation=road_creature_reference_skeleton|Walk`; `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.066`; saved monster scale passed; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; short startup exited 0; touched-file forbidden-pattern check passed.

2026-05-01:
- Replaced the two separate floor-strip collisions with one continuous `Floor_WalkableCollision` body in both baked `FourRoomMVP.tscn` and runtime `SceneBuilder.gd` generation.
- `Floor_SouthStrip` and `Floor_NorthStrip` now remain visual floor meshes only; this removes the physics seam between the two strips while preserving the current floor texture layout.
- Reset the baked south floor mesh local transform to identity so the visual strip no longer has a small saved offset from its parent.
- Narrowed the monster movement collision from `0.86 x 0.68 x 2.28` to `0.62 x 0.62 x 1.30`, increased safe margin to `0.07`, and moved the collision forward to reduce wall/door snagging while preserving the saved monster instance scale.
- `MonsterController.gd` now uses `floor_snap_length = 0.28`, stores the last safe floor position, and recovers the monster if it drops below `y=-0.18`.
- Monster fear response is stronger: near-player panic detection works even outside the forward cone, vision is wider/longer, flee speed is `3.4`, flee acceleration is `40`, start impulse is `3.1`, flee memory is `2.4`, and Run animation speed is `1.7`.
- Added `scripts/tools/ValidateFloorCoverage.gd`; `ValidateMonsterAI.gd` now checks near-behind panic detection and immediate flee start speed.
- Validation: `FLOOR_COVERAGE_VALIDATION PASS samples=118 monster_y=0.053`; `MONSTER_AI_VALIDATION PASS state=WANDER flee_z=1.738 animation=road_creature_reference_skeleton|Walk`; saved monster scale passed; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; short startup exited 0; touched-file forbidden-pattern check passed.

## Ceiling Light Flicker

2026-05-01:
- Raised normal ceiling-light brightness for the current playable scene and runtime generation: room `OmniLight3D.light_energy` is now `0.82` instead of `0.65`.
- Raised the visible ceiling-light panel material emission from `0.85` to `1.10`.
- Raised bright flicker spikes in `LightingController.gd` to `bright_energy_min/max = 1.25/1.85`, and allowed panel emission to spike up to the same multiplier.
- Validation: `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 min_interval=28.0 bright_range=1.25-1.85 base=0.820 dim=0.082 bright=1.312 panel_base=1.100 panel_dim=0.132 panel_bright=1.760`; Godot 4.6.2 parse passed; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; short startup exited 0; touched-file forbidden-pattern check passed.

2026-05-01:
- Retuned flicker away from fixed-feeling per-light intervals.
- Runtime flicker now uses one global randomized startup delay, then a random cooldown after each burst; once cooldown ends, each frame has only a low probability chance to trigger a burst.
- Defaults are now `startup_delay_min/max = 18/45`, `flicker_interval_min/max = 28/70`, and `flicker_chance_per_second = 0.018`.
- Validation: `LIGHT_FLICKER_VALIDATION PASS lights=4 chance=0.018 min_interval=28.0 base=0.650 dim=0.065 panel_base=0.850 panel_dim=0.102`; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; normal startup exited 0; touched-file forbidden-pattern check passed.

2026-05-01:
- `LightingController.gd` now manages all nodes in the `ceiling_light` group and triggers rare, short flicker bursts independently at runtime.
- Flicker changes real `OmniLight3D.light_energy` and duplicates each matching `CeilingLightPanel_*` material so its emission energy follows the same dim/bright pattern.
- The mechanism keeps lamp meshes visible and does not bind real light enablement to panel visibility.
- Added `scripts/tools/ValidateLightFlicker.gd`.
- Validation: Godot 4.6.2 parse exited 0; `LIGHT_FLICKER_VALIDATION PASS lights=4 base=0.650 dim=0.065 panel_base=0.850 panel_dim=0.102`; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; normal startup with `--quit-after 8` exited 0; touched-file forbidden-pattern check passed.

## Camera Recenter Control

2026-05-01:
- Changed `CameraController.gd` so manual mouse/touch yaw offset no longer auto-recenters while the player is stationary.
- This was a temporary control model and is now superseded by the 2026-05-02 free-orbit camera: camera yaw no longer clamps to the front arc and no longer recenters when movement starts.
- Added `scripts/tools/ValidateCameraRecenter.gd` to validate stationary hold and movement-triggered recenter.
- Validation: Godot 4.6.2 parse exited 0; `CAMERA_RECENTER_VALIDATION PASS stationary_offset=0.660 moving_offset=0.013`; player animation and monster AI regressions passed; normal startup exited 0; touched-file forbidden-pattern check passed. The only recurring runtime error line was the existing MCP runtime port 7777 already being occupied by the open editor.

## Scene Light Shadows

2026-05-01:
- Enabled real shadow casting on the four room `OmniLight3D` ceiling lights in both baked `FourRoomMVP.tscn` and runtime `SceneBuilder.gd` generation.
- Set ceiling light panel meshes to `SHADOW_CASTING_SETTING_OFF` so the visible lamp panels do not block their own light source.
- `PlayerController.gd` and `MonsterController.gd` now recursively set imported character/monster `MeshInstance3D` nodes to cast shadows.
- Added `scripts/tools/ValidateSceneShadows.gd` to validate baked and runtime scene shadow setup.
- Validation: Godot 4.6.2 parse exited 0; `SCENE_SHADOW_VALIDATION PASS baked=true runtime=true`; player animation and monster AI regression validations passed; normal startup with `--quit-after 8` exited 0. The only recurring runtime error line was the existing MCP runtime port 7777 already being occupied by the open editor.

## Monster MVP

2026-05-01:
- Improved flee behavior so the monster tries to escape through connected room portals instead of only running directly away from the player.
- `MonsterController.gd` now detects the current room area from `LevelRoot/Rooms`, scores connected portals under `LevelRoot/Portals`, and routes toward a portal plus an exit point just inside the connected room.
- Flee route scoring prefers exits farther from the player, avoids routes into the player's current area when possible, and repaths if the monster hits a wall or makes too little progress.
- `ValidateMonsterAI.gd` now includes a Room_D regression case where direct away-from-player movement would run into the north wall; validation requires progress toward P_CD or P_DA instead.
- Validation: Godot 4.6.2 parse exited 0; `MONSTER_AI_VALIDATION PASS state=WANDER`; normal startup with `--quit-after 8` exited 0; touched-file forbidden-pattern check passed. The only recurring runtime error line was the existing MCP runtime port 7777 already being occupied by the open editor.

2026-05-01:
- Added `scenes/modules/MonsterModule.tscn`, using `res://3D模型/guai1.glb` as the scene monster model.
- Added `scripts/monster/MonsterController.gd`.
- Monster behavior is isolated to the monster module and currently supports `WANDER`, `IDLE_LOOK`, and `FLEE`.
- Forward vision uses a horizontal FOV cone plus a physics raycast line-of-sight check to the player.
- When the player is seen, the monster flees using the Run animation; when not seeing the player, it wanders, occasionally stops, plays Idle, and looks left/right.
- Added `flee_memory_time=1.5` after validation showed the monster otherwise stopped fleeing immediately after turning away from the player.
- Monster Idle, Walk, and Run animations are looped and POSITION tracks are disabled to avoid root-motion drift from the `CharacterBody3D`.
- `GameBootstrap.gd` places `MonsterRoot/Monster` at `LevelRoot/Markers/Spawn_Monster_D`.
- Added `scripts/tools/ValidateMonsterAI.gd`.
- Validation: model inspection passed with 9 animations and 58 skeleton bones; Godot 4.6.2 parse exited 0; `MONSTER_AI_VALIDATION PASS state=WANDER`; normal startup with `--quit-after 8` exited 0; touched-file forbidden-pattern check passed.

## Player Animation Hookup

2026-05-01:
- Inspected `res://3D模型/zhujiao.glb` through `ModelRoot/zhujiao/AnimationPlayer`.
- The current GLB exposes one skeletal animation, `mixamo_com`, length about 2.042 seconds. No separate idle/walk/run/backpedal clips are present in the imported model.
- `PlayerController.gd` now plays `mixamo_com` for movement: walk 1.0x, sprint 1.25x, backpedal -0.8x. Idle uses generated `idle_generated` because no authored idle animation is available in the GLB.
- Added `scripts/tools/InspectPlayerAnimations.gd` and `scripts/tools/ValidatePlayerAnimation.gd`.
- Validation: inspection passed, Godot 4.6.2 editor parse exited 0, `PLAYER_ANIMATION_VALIDATION PASS animation=mixamo_com`, and normal window startup with `--quit-after 8` exited 0.

2026-05-01:
- Fixed the movement-animation drift caused by root motion in the GLB.
- Track inspection found `mixamorig_Hips_01` has one POSITION track with about 1515.96 units of Z displacement across `mixamo_com`, which made the skinned visual mesh leave the `CharacterBody3D` capsule.
- `PlayerController.gd` now disables animation POSITION tracks when `lock_animation_root_motion` is true, keeping model movement driven by `CharacterBody3D` while preserving bone rotation animation.
- Added `scripts/tools/InspectPlayerAnimationTracks.gd` and `scripts/tools/ValidatePlayerAnimationCollision.gd`.
- Validation: track inspection shows `TRACK 027 type=POSITION enabled=false`; player animation validation passed; west-wall collision validation passed with `PLAYER_ANIMATION_COLLISION_VALIDATION PASS player_x=-2.533`; normal startup exited 0.

2026-05-01:
- Added generated idle playback for the stopped state.
- `PlayerController.gd` initially creates `idle_generated` from a stationary pose sampled from `mixamo_com`, skips POSITION tracks, adds a subtle upper-body breathing loop, and plays it when movement input is released. The later 2026-05-01 retune below supersedes the idle pose and loop timing.
- The generated idle can be tuned with `idle_source_animation`, `idle_pose_time`, and `idle_breath_degrees`.
- Validation: `AnimationPlayer` now reports `idle_generated` and `mixamo_com`; `PLAYER_ANIMATION_VALIDATION PASS movement=mixamo_com idle=idle_generated`; collision validation still passed with `player_x=-2.533`; normal startup exited 0. The only recurring error line during validation was MCP port 7777 already being occupied by the open Godot editor.

2026-05-01:
- Retuned generated idle so the player no longer idles on a one-foot-raised source key.
- `PlayerController.gd` now builds `idle_generated` with lower body and hips from the model Rest Pose, so both feet are planted instead of freezing a walk-frame leg pose. Upper body samples `mixamo_com` at `idle_pose_time=1.55`.
- The generated idle loop is 6.0 seconds, breathing is slightly stronger at `idle_breath_degrees=1.8`, and head/neck bones add occasional left/right glance motion through `idle_head_look_degrees=9.0`.
- Added `scripts/tools/InspectIdlePoseCandidates.gd`, `scripts/tools/InspectGeneratedIdlePoseCandidates.gd`, `scripts/tools/InspectPlayerPoseStates.gd`, and `scripts/tools/InspectUpperIdlePoseCandidates.gd` to compare foot/toe bone heights and upper-body pose quality before locking the default pose. The final generated idle measured `foot_delta=0.00` and `toe_delta=0.00`.
- Validation: Godot 4.6.2 parse exited 0; pose inspection confirmed `PLAYER_CURRENT_ANIMATION name=idle_generated playing=true`; `PLAYER_ANIMATION_VALIDATION PASS movement=mixamo_com idle=idle_generated`; `PLAYER_ANIMATION_COLLISION_VALIDATION PASS player_x=-2.533`; short normal startup exited 0; touched-file forbidden-pattern check passed.

## Phase 3 Foreground Occlusion MVP

2026-05-01:
- Replaced whole-mesh `visible=false` foreground occlusion with local player-area cutouts.
- Added `materials/foreground_occlusion_cutout.gdshader`, a camera-aligned oval cutout shader with feathered alpha transition from hidden center to normal visible material.
- `ForegroundOcclusion.gd` now temporarily applies per-mesh `ShaderMaterial` overrides to hit foreground walls, wall openings, and door frames, then restores each mesh's original material override when clear.
- The mesh nodes stay visible and collision remains active; only the local player region is cut through visually.
- Validation: Godot 4.6.2 parse passed; Phase 3 validation passed with `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; normal startup exited 0. The only runtime error line was the existing MCP runtime port 7777 already being occupied by another Godot instance.
- Forbidden-pattern note: the only `ALPHA` hit in touched Phase 3 files is the local cutout shader itself, which is the allowed Phase 3 cutout path and not a large transparent wall/overlay.

2026-05-01:
- Fixed the manual visual issue where `DoorFrame_P_*` stayed visible after the foreground wall/opening was hidden.
- `ForegroundOcclusion.gd` now hides/restores the matching `DoorFrame_P_*` when a `WallOpening_P_*` occluder is hit.
- It also checks the Camera -> Player line against the U-shaped door-frame visual profile, so lower trim/header pieces without player collision can still hide when they block the player view.
- Door-frame participation is visual-only: no player-blocking door-frame collision was added, and wall-opening collision remains enabled.
- Validation: Godot 4.6.2 parse passed; Phase 3 validation passed with `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1 door_hidden_count=2`; normal startup exited 0. The only runtime error line was the existing MCP runtime port 7777 already being occupied by another Godot instance.

2026-05-01:
- Backed up current project contents to `E:\godot后室_backups\godot后室_backup_20260501_155923` before testing.
- Replaced the `ForegroundOcclusion.gd` skeleton with Camera -> Player raycast occlusion.
- The MVP hides/restores only `MeshInstance3D` children of hit `foreground_occluder` bodies; `StaticBody3D` and `CollisionShape3D` remain active.
- Wired `ForegroundOcclusion` in `FourRoomMVP.tscn` to `CameraRig/Camera3D` and `PlayerRoot/Player`.
- Added `scripts/tools/ValidatePhase3Occlusion.gd` to validate that a foreground wall mesh hides while its collision remains enabled, then restores when clear.
- Validation: baseline parse/run passed; implementation parse passed; validation script passed with `PHASE3_OCCLUSION_VALIDATION PASS hidden_count=1`; final normal startup exited 0. The only runtime error line was the existing MCP runtime port 7777 already being occupied by another Godot instance.

## Third-Person Camera And Common Controls

2026-05-01:
- Swapped mouse/touch vertical look direction in `CameraController.gd` by changing pitch input to add vertical relative motion.
- Validation: Godot 4.6.2 headless editor parse exited 0; normal window scene startup with `--quit-after 8` exited 0. The only runtime error line was the existing MCP runtime port 7777 already being occupied by another Godot instance.

2026-05-01:
- Fixed backpedal body orientation: when `S` / down arrow is backward-dominant, the character now faces opposite the movement vector so it backs up while looking forward instead of staying sideways after a turn.
- Validation: Godot 4.6.2 headless editor parse exited 0; normal window scene startup with `--quit-after 8` exited 0. The only runtime error line was the existing MCP runtime port 7777 already being occupied by another Godot instance.

2026-05-01:
- Lowered the third-person camera angle while keeping the full character visible: distance 1.8m, target height 1.0m, pitch 3 degrees, and Camera3D FOV 62.
- Changed backward input behavior so `S` / down arrow backpedals only; it no longer updates character facing or the camera recenter heading.
- `CameraController.gd` now uses the player's explicit heading direction for recentering instead of raw body velocity, preventing backward movement from being interpreted as a turn.
- Validation: the first Godot 4.6.2 parse caught a Variant inference warning treated as error; after explicit typing, editor parse exited 0 and normal window scene startup with `--quit-after 8` exited 0. The only runtime error line was the existing MCP runtime port 7777 already being occupied by another Godot instance.

2026-05-01:
- Tuned the third-person camera closer to the user-provided screenshot framing: distance 1.55m, target height 1.15m, pitch 6 degrees, and Camera3D FOV 60.
- Limited manual camera yaw to +/-90 degrees around the player's movement-facing direction, so the camera no longer rotates freely through 360 degrees.
- Added natural yaw recentering after 0.45s without mouse/touch rotation.
- Validation: Godot 4.6.2 headless editor parse exited 0; normal window scene startup with `--quit-after 8` exited 0. The only runtime error line was the existing MCP runtime port 7777 already being occupied by another Godot instance.

2026-05-01:
- Changed the runtime camera from the old high fixed follow angle to a common behind-the-player third-person view.
- `CameraController.gd` now supports mouse-look orbit, click-to-capture mouse, `Esc` to release mouse, and touch-drag rotation for mobile-oriented testing.
- `PlayerController.gd` now moves relative to the camera direction instead of fixed world axes.
- Added common keyboard controls: `WASD` / arrow keys for movement and `Shift` for sprint.
- Updated the baked `FourRoomMVP.tscn` camera rig values and widened camera FOV to 65 for the closer third-person view.
- Validation: Godot 4.6.2 headless editor parse exited 0; normal window scene startup with `--quit-after 8` exited 0. The only runtime error line was the existing MCP runtime port 7777 already being occupied by another Godot instance.

## Ceiling And Ceiling Light Pass

2026-05-01:
- Restored one independent ceiling/roof slab per room in the baked scene and runtime `SceneBuilder.gd` generation.
- Added one ceiling-light visual panel per room; each panel protrudes slightly below the ceiling instead of being flush.
- Added one separate `OmniLight3D` per room under `LevelRoot/Lights`, keeping the visible lamp mesh separate from the real light source.
- Added `materials/backrooms_ceiling.tres` and `materials/backrooms_ceiling_light.tres`.
- Validation: static counts passed with 4 ceilings, 4 light panels, and 4 OmniLights; Godot 4.6.2 editor parse exited 0; normal window startup with `--quit-after 8` exited 0 with no error hits.

## Utility Scripts

2026-05-01:
- Added `open_latest_scene.bat` to open `res://scenes/mvp/FourRoomMVP.tscn` from disk with Godot 4.6.2.
- Added `run_latest_demo.bat` to run the current main scene directly with Godot 4.6.2.
- Fixed bat path quoting by trimming the trailing slash from `%~dp0`.
- Updated `run_latest_demo.bat` to keep a console window open and write `logs/run_latest_demo.log`.
- Normal window run check with `--quit-after 20` passed; headless mode crashed in this Godot setup and should not be used as the demo validation path.

## Door Frame Seam Fix

2026-05-01:
- Shifted all door-frame side posts 0.06m inward so they overlap the door opening edges instead of only touching them.
- Expanded top header meshes/shapes to span the full outer width of both side posts.
- Updated both baked scene geometry and runtime `SceneBuilder.gd` generation.
- Validation: static overlap checks passed; Godot editor parse exited 0; normal window run exited 0. The only runtime error line was the existing MCP port 7777 already being occupied.

## Wall Connection Fix

2026-05-01:
- Added `Wall_A_NorthWestReturn` to close the exposed outer wall segment caused by Room_D being narrower than Room_A.
- Added 10 `WallJoint_*` filler blocks at key corners and T-junctions so walls no longer rely on exact edge contact.
- Updated both baked scene geometry and runtime `SceneBuilder.gd` generation.
- Validation: static wall-joint checks passed; Godot editor parse exited 0; normal window run exited 0 with no error hits.

## Door Frame Integration Fix

2026-05-01:
- Replaced split door-frame side-post/header blocks with 4 integrated `DoorFrame_P_*` visual MeshInstances.
- Added `scripts/scene/DoorFrameVisual.gd`; each door frame is generated as one U-shaped mesh in a single node.
- Door frames now sit inside the wall thickness and stop at y=2.18, below the 2.55m wall top.
- The area above each doorway is wall geometry: 4 `WallHeader_P_*` StaticBody nodes, not door-frame pieces.
- Updated both baked `FourRoomMVP.tscn` and runtime `SceneBuilder.gd`.
- Validation: old split `DoorFrame_P_*_South/North/West/East/Header` nodes count is 0; new `DoorFrame_P_*` count is 4; `WallHeader_P_*` count is 4.
- Godot editor parse exited 0; normal window run exited 0; Godot MCP scene-tree check confirmed the new nodes.

## Door Frame Dimension Sync

2026-05-01:
- Used the saved user-adjusted `DoorFrame_P_AB` transform scale as the source size: depth scale `1.4412847`, span scale `0.947737`.
- Applied the same physical door-frame dimensions to `DoorFrame_P_BC`, `DoorFrame_P_CD`, and `DoorFrame_P_DA`.
- X-axis doorway frames swap the scale axes so depth and span remain visually consistent.
- Updated runtime `SceneBuilder.gd` to generate the same scaled frames.
- Validation: static transform checks passed; Godot 4.6.2 headless parse exited 0 with no error hits.

## Door Frame Monolithic Mesh

2026-05-01:
- Reworked `DoorFrameVisual.gd` so the frame is generated from one U-shaped profile extruded through wall depth.
- Removed the previous internal three-box construction (`left side + right side + top header`) from the visual mesh generator.
- Removed saved door-frame `ArrayMesh_*` references from `FourRoomMVP.tscn`; door-frame mesh data now comes from the script-generated U profile.
- Validation: static mesh-topology checks passed; Godot 4.6.2 headless parse exited 0; normal window scene startup with `--quit-after 8` exited 0 with no error hits.

## Wall Z-Fighting Visual Cleanup

2026-05-03:
- Diagnosed the latest wall screenshot as likely coplanar/overlapping render geometry, not a pure UV inversion.
- Changed wall span generation from slight overlap (`6.04m`) to edge-to-edge spans (`5.64m`) against wall-joint blocks.
- Added optional horizontal-cap omission to `GeneratedMeshRules.build_box_mesh()`.
- Solid walls and wall-joint visuals now render side faces only; collision boxes remain full boxes.
- Doorway wall bodies skip floor/ceiling profile cap edges; door-frame visuals skip floor cap edges at the feet.
- Follow-up screenshot showed two remaining problems: black edge seams at floor/ceiling contact and stretched one-pixel-looking doorway side-face UVs.
- Wall/joint visuals now extend `0.025m` beyond floor/ceiling contact without horizontal caps.
- Portal wall bodies now extend `0.025m` beyond floor/ceiling contact and use explicit side-face UVs.
- Door-frame feet now extend `0.02m` below floor contact and use explicit side-face UVs for narrow trim/reveal faces.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`.
- Validation: bake, generated mesh rules, clean rebuild, material lighting, scene shadows, floor coverage, Phase 3 occlusion, and short startup all passed.

## Wall Opening Body Cleanup

2026-05-01:
- Replaced each portal wall opening with one `WallOpening_P_*` StaticBody driven by `scripts/scene/WallOpeningBody.gd`.
- Deleted old `Wall_AB/BC/CD/DA_*Segment` nodes and old `WallHeader_P_*` nodes from the baked scene instead of hiding their Mesh children.
- Removed unused old segment/header `BoxMesh` and `BoxShape3D` resources from `FourRoomMVP.tscn`.
- `WallOpeningBody.gd` owns one monolithic U-shaped visual mesh and simple box collisions for left side, right side, and top; collision no longer depends on old nodes.
- Runtime `SceneBuilder.gd` now creates the same `WallOpening_P_*` bodies.
- Validation: static cleanup checks passed; Godot 4.6.2 parse and short window run exited 0; Godot MCP scene tree confirmed 4 wall-opening nodes and no old portal wall segment/header nodes.

## Wall Opening Editor Selection Fix

2026-05-01:
- Added explicit saved `Mesh`, `Collision_Left`, `Collision_Right`, and `Collision_Top` child nodes under each `WallOpening_P_*`.
- Updated `WallOpeningBody.gd` to assign the edited scene root as owner for any dynamically created editor children.
- This makes the middle wall opening geometry visible and selectable in the Godot scene tree/viewport instead of depending on transient tool-script children.
- Validation: static child-node checks passed; Godot 4.6.2 parse and short window run exited 0; Godot MCP scene tree confirmed all wall opening children are present.

## Wall Opening And Door Frame Material Alignment

2026-05-01:
- Unified `WallOpeningBody.gd` and `DoorFrameVisual.gd` generated mesh materials to `Color(0.72, 0.76, 0.78)`.
- Removed `BaseMaterial3D.SHADING_MODE_UNSHADED` from generated wall-opening and door-frame materials so inner wall pieces match the outer wall light/shadow behavior.
- Validation: static lit-material consistency and touched-file forbidden-pattern checks passed; Godot 4.6.2 parse exited 0; short window startup exited 0.

## Backrooms Texture Material Pass

2026-05-01:
- Generated realistic seamless Backrooms-style texture sources with the built-in image generation tool: yellowed wall wallpaper, worn off-white vinyl floor tile, and pale gray painted door-frame trim.
- Exported 1024px project-local albedo/normal texture PNGs under `materials/textures/`.
- Added `backrooms_wall.tres`, `backrooms_floor.tres`, and `backrooms_door_frame.tres` material resources.
- Replaced baked scene floor/wall whitebox material overrides with the new floor/wall materials.
- Updated runtime `SceneBuilder.gd` so regenerated floor and wall boxes use the same materials.
- Updated `WallOpeningBody.gd` and `DoorFrameVisual.gd` to use material resources and generate UVs for the script-built U meshes.
- Validation: static texture/material checks passed; Godot 4.6.2 parse and short window startup passed; texture 2x2 repeat preview saved to `artifacts/screenshots/texture_tile_preview_20260501_141626.png`.

## Visual Experiment Safety Standard

2026-05-03:
- Added the first experiment-only global reusable grime system on top of contact AO. The accepted base `scenes/mvp/FourRoomMVP.tscn` was not merged with this visual pass.
- Generated 9 true-alpha PNG grime variants under `materials/textures/grime/`: 3 `CeilingEdge_Grime`, 3 `Baseboard_Dirt`, and 3 `Corner_Grime`. The assets contain only soft transparent stain bodies, not wall/floor base color.
- Added `scripts/visual/GrimeOverlayBuilder.gd` as the shared placement entry. It reads room metadata and portals generically, then uses deterministic room seeds for whether to generate, which variant to use, opacity, strength, length, and size.
- Added `scripts/tools/BakeGrimeExperiment.gd`, `scripts/tools/ValidateGrimeExperiment.gd`, and `scripts/tools/CaptureGrimeExperimentScreenshot.gd`.
- Built `scenes/mvp/experiments/FourRoomMVP_grime_experiment.tscn` from the contact-AO experiment with 8 ceiling-edge strips, 15 baseboard strips, and 10 corner strips.
- Validation passed: `CONTACT_AO_EXPERIMENT_VALIDATION PASS wall=21 floor=4 door_frame=4 ceiling=4`; `GRIME_EXPERIMENT_VALIDATION PASS ceiling=8 baseboard=15 corner=10`.
- Screenshot evidence: `artifacts/screenshots/grime_experiment_20260503 232817.png`.
- Base-scene merge: not performed. Next step is user visual acceptance of strength/coverage before promoting the builder into the normal room-generation flow.

2026-05-04:
- Added the first fixed-layout procedural Backrooms maze pipeline without modifying `scenes/mvp/FourRoomMVP.tscn`.
- New test scene: `scenes/tests/Test_ProcMazeMap.tscn`.
- New module metadata registry: `data/proc_maze/module_registry.json`.
- New module placeholder scenes under `scenes/proc_maze/modules/`.
- New pipeline scripts:
  - `scripts/proc_maze/ModuleRegistry.gd`
  - `scripts/proc_maze/MapGraphGenerator.gd`
  - `scripts/proc_maze/MapValidator.gd`
  - `scripts/proc_maze/ProcMazeSceneBuilder.gd`
  - `scripts/proc_maze/SceneValidator.gd`
  - `scripts/proc_maze/DebugView.gd`
  - `scripts/proc_maze/TestProcMazeMap.gd`
- New tools:
  - `scripts/tools/BakeTestProcMazeMap.gd`
  - `scripts/tools/ValidateTestProcMazeMap.gd`
  - `scripts/tools/CaptureTestProcMazeMapLayout.gd`
  - `run_proc_maze_test.bat`
- Fixed-layout test output: seed `2026050401`, generator version `proc_maze_fixed_layout_v0.1`, 37 modules, 18-node main path, 10 branches, 4 loops, 6 dead ends, 5 large/hub rooms, 3 special reserved rooms, 37 ceiling lights.
- Validation passed: no footprint overlap, no door-to-wall connection, module metadata present, all rotations are 0/90/180/270, generated nodes keep identity scale, and wall/opening/frame/floor/ceiling materials are preserved.
- Logs:
  - `logs/proc_maze_bake_20260504_020652.log`
  - `logs/proc_maze_validate_20260504_020738.log`
  - `logs/proc_maze_layout_capture_20260504_021812.log`
  - `logs/proc_maze_scene_startup_20260504_022603.log`
- Layout validation screenshot: `artifacts/screenshots/test_proc_maze_layout.png`.
- Note: headless viewport screenshot via `CaptureTestProcMazeMapScreenshot.gd` timed out and was stopped. The non-viewport layout capture is the current visual artifact for topology verification.

2026-05-04:
- Strengthened the fixed procedural map's macro-loop experience without modifying `scenes/mvp/FourRoomMVP.tscn`.
- New generator version: `proc_maze_fixed_layout_v0.5_macro_loop_experience`.
- Made `N05` the explicit split A and `N12` the explicit merge B by using the new `hub_room_partitioned` module at both points.
- Removed the near-split cross-link that made the loop feel like local patch connectivity instead of two clear routes.
- Moved the early local loop return before the split, so split A now reads as one inbound path branching into an upper route and lower route.
- Rebuilt the lower route as a compound-room arc with `large_room_with_side_chamber`, `large_room_split_ew`, a normal-room connector, and L-shaped room spaces.
- Kept the upper route corridor-biased through long, narrow, L-turn, and offset corridor spaces.
- Added validation checks for macro-loop route separation, exact split/merge degrees, corridor pressure on route A, expanded-room pressure on route B, and at least two compound large/hub spaces on route B.
- Added `hub_room_partitioned` metadata and shared internal partition construction.
- Rebaked `scenes/tests/Test_ProcMazeMap.tscn` and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`.
- Validation passed: 38 rooms, 1 macro loop, macro cycle length 14, largest simple cycle 14, route A length 8, route B length 8, 2 small loops, 4 dead ends, 6 large rooms, 3 internal large rooms, 3 hubs, no overlap, no door-to-wall.
- Latest logs:
  - `logs/proc_maze_macro_experience_bake_20260504_151030.log`
  - `logs/proc_maze_macro_experience_validate_structure_20260504_151040.log`
  - `logs/proc_maze_macro_experience_validate_playable_20260504_151050.log`
  - `logs/proc_maze_macro_experience_no_ceiling_bake_20260504_151100.log`
  - `logs/proc_maze_macro_experience_no_ceiling_validate_20260504_151110.log`
  - `logs/proc_maze_macro_experience_layout_capture_20260504_151120.log`
  - `logs/proc_maze_macro_experience_startup_playable_20260504_151130.log`
  - `logs/proc_maze_macro_experience_startup_no_ceiling_20260504_151140.log`

2026-05-04:
- Reworked the fixed proc-maze map around clearer space types instead of more small connector pieces.
- New generator version: `proc_maze_fixed_layout_v0.6_space_type_refactor`.
- Reduced generated spaces from 38 to 36 by removing the old short connector nodes `B19` and `B21`.
- Replaced the area-0 pre-split branch with a compound large room (`B18`, `large_room_offset_inner_door`) feeding a notched wide room (`B20`, `room_wide`) before reconnecting to the main route.
- Converted side/dead-end ordinary rectangles into stronger wide-room anchors where they fit: `B23`, `B32`, and `B33`.
- Changed `B29` from a long straight corridor to `corridor_offset`, keeping the special loop but reducing long-rectangle overuse.
- Added L-room internal baffles in this pass, later superseded by the no-slit rule that L rooms use occupied-cell L footprints and generated boundary walls only.
- Offset the internal doorway gaps in `large_room_split_ns` and `large_room_split_ew`, so compound large rooms no longer create centered straight-through sightlines.
- Strengthened validation: ordinary rectangles now include `normal_room`; ordinary rectangle ratio is capped at 35 percent; declared routes reject 3 ordinary rectangles or 3 short connector spaces in a row; every area must contain an anchor room; true long corridors are capped at 5.
- Validation passed: 36 rooms, 1 macro loop, macro cycle length 14, route A length 8, route B length 8, 2 small loops, 4 dead ends, 5 true long corridors, 4 L rooms, 4 internal large rooms, 3 hubs, 5 ordinary rectangular rooms, no overlap, no door-to-wall.
- Latest logs:
  - `logs/proc_maze_space_refactor_bake_20260504_160020.log`
  - `logs/proc_maze_space_refactor_validate_structure_20260504_160030.log`
  - `logs/proc_maze_space_refactor_validate_playable_20260504_160040.log`
  - `logs/proc_maze_space_refactor_no_ceiling_bake_20260504_160050.log`
  - `logs/proc_maze_space_refactor_no_ceiling_validate_20260504_160100.log`
  - `logs/proc_maze_space_refactor_layout_capture_20260504_160110.log`
  - `logs/proc_maze_space_refactor_startup_playable_20260504_160120.log`
  - `logs/proc_maze_space_refactor_startup_no_ceiling_20260504_160130.log`

2026-05-04:
- Replaced the procedural grime texture set with an image2-generated natural grime atlas extraction workflow.
- Added `scripts/tools/extract_image2_grime_textures.py`; it archives the old grime PNGs, stores the image2 atlas source, extracts the 3x3 atlas into 9 true-alpha PNGs, clears transparent borders, and generates an HTML/PNG preview sheet.
- Updated the grime texture set so the stain body itself reaches roughly the requested 50% alpha at the strongest points while keeping soft faded edges.
- Updated `scripts/visual/GrimeOverlayBuilder.gd` so grime material alpha stays at `1.0`; PNG alpha now controls strength directly and avoids double attenuation.
- Updated `scripts/tools/ValidateGrimeExperiment.gd` to validate the 50% texture-alpha pass and full-pixel alpha maxima.
- Re-baked `scenes/mvp/experiments/FourRoomMVP_grime_experiment.tscn` with 8 ceiling-edge strips, 15 baseboard strips, and 10 corner strips.
- Validation passed: `GRIME_EXPERIMENT_BAKE PASS path=res://scenes/mvp/experiments/FourRoomMVP_grime_experiment.tscn ceiling=8 baseboard=15 corner=10 total=33`; `GRIME_EXPERIMENT_VALIDATION PASS ceiling=8 baseboard=15 corner=10`.
- Preview helper updated: `open_grime_texture_preview.bat` opens `artifacts/screenshots/grime_texture_image2_contact_sheet_20260504_005000.html`.
- Base-scene merge: not performed. This remains an experiment pending visual acceptance.

2026-05-04:
- Removed non-passable L-room slit generation from proc-maze: `room_l_shape` now relies on occupied-cell L footprints and generated boundary walls only.
- Deleted the generated L-room internal baffles (`LRoomSightBreak_NS` / `LRoomReturn_EW`) from `ProcMazeSceneBuilder.gd` and rebaked both proc-maze test scenes.
- Added a `SceneValidator` guard so any future L-shaped room with `proc_internal_wall` fails validation.
- Increased compound large-room internal passage gaps to `INTERNAL_PASSAGE_WIDTH = 1.60`.
- Lowered shared world ambient energy from `0.10` to `0.07` in both the MVP `SceneBuilder` and proc-maze builder; updated shadow validation range to `0.05..0.09`.
- Rebaked `scenes/mvp/FourRoomMVP.tscn`, `scenes/tests/Test_ProcMazeMap.tscn`, and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`.
- Validation passed: MVP bake/clean/material-lighting/shadow/light-flicker/generated-mesh, proc-maze bake/structure/playable/no-ceiling/layout capture, and bounded startup smoke tests for MVP plus both proc-maze scenes.

2026-05-03:
- Built `scenes/mvp/experiments/FourRoomMVP_contact_ao_experiment.tscn` as a copied contact-AO visual experiment. The accepted base `scenes/mvp/FourRoomMVP.tscn` was not merged with this visual pass.
- Fixed the experiment floor-tile scale issue: the custom contact-AO shader now has explicit `uv_scale` / `uv_offset`, and the bake script passes the original material scales into the experiment copy: floor `(12, 12)`, wall `(4.475, 3.77)`, and door frame `(1.2, 2.0)`.
- `ValidateContactAOExperiment.gd` now fails if the experiment loses those UV-scale values or if wall/opening/door-frame rebuilds drop the contact-AO ShaderMaterial.
- Validation passed: `CONTACT_AO_EXPERIMENT_BAKE PASS`, `CONTACT_AO_EXPERIMENT_VALIDATION PASS wall=21 floor=4 door_frame=4 ceiling=4`, and screenshot `artifacts/screenshots/contact_ao_experiment_20260503 215907.png`.

2026-05-03:
- Accepted the workflow rule that new visual ideas must be tested on copied experiment variants first, not applied directly to the accepted base scene/materials.
- AO/contact-shadow style polish for wall bases, wall corners, door-frame edges, and ceiling turns should be subtle and gradual. It must not become black outline lines, large dark strips, transparent overlays, or one-off per-instance fixes.
- Required workflow for visual polish: copy the current baseline, adjust the copy, capture screenshots, run targeted validation, then merge only accepted values back into the base generator/material resources.
- Current base scene remains `scenes/mvp/FourRoomMVP.tscn`; current direct-run helper remains `run_latest_demo.bat`.

## 当前阶段

Phase 3：前景遮挡

## 阶段状态

- [x] Phase 0：清洁启动与项目结构
- [x] Phase 1：四房间闭环基础场景
- [x] Phase 2：玩家与相机
- [ ] Phase 3：前景遮挡
- [ ] Phase 4：材质、灯板、真实灯光、VOID 外墙
- [ ] Phase 5：门交互与 Portal 状态
- [ ] Phase 6：可见性三态
- [ ] Phase 7：门洞切线可见性
- [ ] Phase 8：Debug 与扩展准备

## 当前禁止进入的阶段

Phase 3 未通过运行验收前，不要做：

- 怪物 AI
- 联机同步
- 程序化生成
- 大地图
- 复杂 UI
- 完整道具系统
- 剧情事件
- 复杂音频系统
- 可见性三态
- 门洞切线可见性
- 材质灯光细化

## 当前必须遵守

- 不使用黑片 / 灰片 / 透明片盖场景作为正式效果。
- 前景遮挡是独立模块。
- 可见性系统不写房间特例。
- 所有核心模块可调试。
- 新增房间、门、灯时优先写入数据和模块，不写一次性逻辑。
- `E:\godot后室\3D模型\zhujiao.glb` 已作为 Phase 2 玩家主角模型接入。

## 已完成

- Phase 0：复制 `docs/` 和 `data/` 到项目根目录。
- Phase 0：创建 Godot 4 项目骨架 `project.godot`。
- Phase 0：创建空主场景 `scenes/mvp/FourRoomMVP.tscn`。
- Phase 0：创建模块场景占位。
- Phase 0：创建核心脚本、场景脚本、相机脚本、可见性脚本、灯光脚本、Debug 脚本骨架。
- Phase 0：创建 `CURRENT_STATE.md`、`logs/`、`artifacts/screenshots/`。
- Phase 1：`SceneBuilder` 生成四房间基础场景。
- Phase 1：生成 4 个房间、16 段墙、地板、天花和 4 个 Portal。
- Phase 1：生成 PlayerSpawn、MonsterSpawn、ItemSpawn、EventTrigger、ExitPoint 占位点。
- Phase 1：Room_D 使用 5.2m 宽度，并将中心调整到 x=0.4，使右边缘对齐共享墙，保证闭环门洞连续。
- Phase 2：创建 `PlayerModule.tscn`。
- Phase 2：创建 `PlayerController.gd`，支持 WASD / 方向键移动、CharacterBody3D、重力和移动朝向反馈。
- Phase 2：接入 `res://3D模型/zhujiao.glb` 作为玩家模型。
- Phase 2：主场景实例化玩家，并由 `GameBootstrap` 定位到 `Spawn_Player_A`。
- Phase 2：`CameraRig` 增加当前 Camera3D，并跟随玩家。
- Phase 2 验收准备：已安装 GoPeak Godot MCP addon，并添加项目级 Codex MCP 配置；重启后 MCP 工具已可用。
- Phase 2：通过 GoPeak MCP 运行验收，玩家移动、碰撞、相机跟随、相机角度和截图观察均通过。
- 基础场景修正：四个 Portal 已补齐上框/门楣，当前为两侧立柱 + 上框的 U 型固定门框；门楣覆盖 y=2.11 到 y=2.55，门扇和开关逻辑留到 Phase 5。

## 最近一次修改

日期：2026-05-01
修改文件：
- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/MVP_SPEC.md`
- `.codex/config.toml`
- `open_latest_scene.bat`
- `run_latest_demo.bat`
- `project.godot`
- `addons/auto_reload/`
- `addons/godot_mcp_editor/`
- `addons/godot_mcp_runtime/`
- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/modules/PlayerModule.tscn`
- `scripts/core/SceneBuilder.gd`
- `scripts/player/PlayerController.gd`
- `scripts/camera/CameraController.gd`
- `scripts/core/GameBootstrap.gd`
- `四房间MVP_Agent抗遗忘执行包/docs/DECISIONS.md`
- `四房间MVP_Agent抗遗忘执行包/docs/MVP_SPEC.md`
- `四房间MVP_Agent抗遗忘执行包/data/four_room_mvp_layout.yaml`
- `四房间MVP_Agent抗遗忘执行包/docs/PROGRESS.md`

修改内容：
- 目标 Godot 版本改为 4.6.2，`project.godot` 使用 Godot 4.6 特性标记。
- 渲染器从 Forward+ 改为 Mobile，项目后续按手机移植优先。
- 将四房间基础几何、Portal、占位点和玩家实例烘入 `FourRoomMVP.tscn`，方便直接打开场景查看。
- 新增玩家模块。
- 新增玩家控制脚本。
- 接入主角模型 `zhujiao.glb`。
- 将 `zhujiao.glb` 在玩家模块内缩放到 0.1 倍，修正模型相对 6m 房间过大的问题。
- 玩家胶囊碰撞调整为半径 0.28m、高 1.6m，移动速度调整为 2.6m/s。
- 修正 `PlayerController.gd` 在 Godot 4.6.2 下的 `physical_keycode` enum 类型警告。
- 按编辑器观察反馈移除主场景和运行时生成逻辑中的天花板。
- 墙高从 3.0m 降到 2.55m。
- 墙段长度增加约 0.04m 轻微重叠，用于消除墙角和门口缝隙。
- 将 4 个分房间地板改为上下两块连续地板，减少共享边露缝。
- 每个 Portal 两侧增加门框封边柱，遮住门洞侧边接缝。
- 每个 Portal 增加 `DoorFrame_*_Header` 上框/门楣，并将门楣高度加厚到 0.44m，补齐固定 U 型门框。
- 找到 Godot 4.6.2 WinGet 可执行文件路径。
- 选定 GoPeak 作为 Phase 2 运行验收的 Godot MCP 方案。
- 从 npm 包内容安装 GoPeak addon 到项目 `addons/`。
- 新增项目级 `.codex/config.toml`，注册 `godot` MCP server。
- 在 `project.godot` 启用 GoPeak editor/runtime/auto-reload 插件。
- 相机跟随目标设为 `PlayerRoot/Player`。
- 相机偏移从 `(0, 6, 5)` 收近到 `(0, 5, 4)`，角度仍约 51°，移动端阅读性更好。
- 启动后将玩家放到 `Spawn_Player_A` 并重置相机。
- 使用 GoPeak MCP 运行 `scenes/mvp/FourRoomMVP.tscn` 并完成 Phase 2 运行验收。
- 使用 GoPeak MCP 验证 4 个门框上框存在，且玩家可从 Room_A 穿过 P_AB 门洞。

验收结果：PASS

验证：
- 玩家移动代码存在：PASS，`PlayerController.gd` 使用 `CharacterBody3D` 和 `move_and_slide()`。
- 基础输入存在：PASS，运行时注册 WASD / 方向键。
- 玩家碰撞体存在：PASS，`PlayerModule.tscn` 包含 CapsuleShape3D。
- 主角模型引用存在：PASS，`PlayerModule.tscn` 引用 `res://3D模型/zhujiao.glb`。
- 主角模型比例：PASS，`ModelRoot` 缩放为 `Vector3(0.1, 0.1, 0.1)`。
- 天花板移除：PASS，`FourRoomMVP.tscn` 和 `SceneBuilder.gd` 均不再生成 Ceiling 节点。
- 墙高调整：PASS，墙高为 2.55m，墙体中心 y=1.275m。
- 缝隙修正：PASS，墙段生成尺寸增加 0.04m 轻微重叠。
- 地面拼接修正：PASS，主场景和 `SceneBuilder` 都使用 `Floor_SouthStrip` / `Floor_NorthStrip` 连续地板。
- 门洞封边：PASS，主场景和 `SceneBuilder` 都包含 8 个 `DoorFrame_*` 封边柱。
- 门框上沿：PASS，主场景和 `SceneBuilder` 都包含 4 个 `DoorFrame_*_Header` 上框/门楣，门楣覆盖 y=2.11 到墙顶 y=2.55。
- 门洞通行：PASS，运行时从 P_AB 门洞穿过后玩家到达 x≈6.19，门框上沿没有阻挡玩家。
- 相机跟随配置存在：PASS，主场景 `CameraRig` 指向 `../PlayerRoot/Player`。
- 相机角度约 45°~55°：PASS，`follow_offset=(0,5,4)`，运行测得约 51.34°。
- 禁止方案搜索：PASS，`rg` 被系统拒绝执行，已用 PowerShell 在实现文件中替代搜索。
- 旧 `VisibilityBlendTest.gd` / `VisibilityBlendSection.gd` 依赖：PASS，未发现。
- 场景资源引用解析：PASS，已用 UTF-8 读取校验中文路径。
- 主场景可查看结构：PASS，静态场景包含 4 个房间、4 个 Portal、5 个占位点、玩家实例和当前相机。
- Mobile 渲染目标：PASS，`project.godot` 使用 `renderer/rendering_method="mobile"`。
- Godot 4.6.2 可执行文件：PASS，WinGet 安装目录中存在 console/gui 版本。
- GoPeak addon 安装：PASS，`addons/auto_reload`、`addons/godot_mcp_editor`、`addons/godot_mcp_runtime` 均存在。
- 项目级 MCP 配置解析：PASS，`.codex/config.toml` 可被 TOML 解析且 Godot 路径存在。
- Godot 项目解析：PASS，`--headless --path . --quit` 退出码 0。
- GoPeak 插件加载：PASS，`--headless --editor --path . --quit` 日志显示 AutoReload 和 MCP Runtime 已加载。
- 禁止方案搜索：PASS，已用 PowerShell 在项目实现文件中搜索，第三方 `addons/` 不纳入游戏视觉实现判断。
- 当前 Codex MCP 工具可见性：PASS，重启后 `mcp__godot__` 工具已可用。
- 实际玩家移动：PASS，MCP 注入 `move_right` 后玩家向右移动约 2.25m。
- 玩家碰撞：PASS，持续向西墙移动后停在 x≈-2.62，未穿墙。
- 相机跟随：PASS，运行测得相机相对玩家偏移约 `(0, 5, 4)`。
- 截图观察：PASS，截图保存到 `artifacts/screenshots/phase2_mcp_runtime_20260501_113727.png`，玩家位于画面中心附近并可见。
- 脚本诊断：PASS，`PlayerController.gd` 和 `CameraController.gd` 无 LSP diagnostics。
- 运行日志：PASS，最终 MCP 运行输出无 errors。
- 门框补洞验证：PASS，最新日志保存到 `logs/door_frame_header_seal_validation_20260501_115656.json`，截图保存到 `artifacts/screenshots/door_frame_header_seal_20260501_115656.png`。

未解决问题：
- Phase 2 无阻塞问题。
- Phase 3 尚未实现：前景墙挡住玩家时，需要隐藏或 cutout 前景墙 Mesh，保留碰撞。

下一步：
- 进入 Phase 3：前景遮挡。只做 Camera -> Player raycast、命中前景墙 Mesh 显隐或局部 cutout，不做可见性三态。

## Texture Tool And Launcher Cleanup - 2026-05-04

目标：
- 清理根目录旧启动项。
- 添加一个小白可直接使用的贴图替换/UV 调整小工具，保存后直接写入项目共享材质和贴图文件。

修改内容：
- 删除旧根目录启动项：资源画廊、grime/contact AO 实验、latest demo、旧 no-ceiling preview shortcut、Codex starter helper。
- 保留当前目标启动项：`run_proc_maze_test.bat`、`run_proc_maze_no_ceiling_preview.bat`。
- 新增 `start_texture_tool.bat`。
- 新增 `codex_tools/texture_tool/texture_tool_server.py`。
- 工具支持选择墙面、地面、门框、天花板、灯板材质。
- 工具支持替换颜色贴图/凹凸贴图，调整 `uv1_scale`、`uv1_offset`、颜色、粗糙度、法线强度、灯板自发光。
- 替换已有贴图前会备份到 `materials/textures/_texture_tool_backups/`。
- `同步导入` 使用 Godot headless bounded run，日志写入 `logs/texture_tool_sync_*.log`。

验收结果：PASS

验证：
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py`：PASS。
- `python codex_tools\texture_tool\texture_tool_server.py --self-test`：PASS，读取 5 个材质。
- 本地 HTTP 冒烟测试 `/api/materials`：PASS，返回 5 个材质，测试服务已关闭。
- 根目录 `.bat` 只剩 `run_proc_maze_no_ceiling_preview.bat`、`run_proc_maze_test.bat`、`start_texture_tool.bat`。

下一步：
- 打开 `start_texture_tool.bat`，在浏览器里替换贴图或调 UV，保存并同步导入后，用 `run_proc_maze_test.bat` 查看效果。

## Texture Tool Model Preview - 2026-05-04

目标：
- 在贴图工具里加入贴图上模型后的实时预览，避免只看单张贴图缩略图判断比例。

修改内容：
- 在贴图缩略图下方新增 `模型实时预览` 区域。
- 预览模型包含墙面、地面、天花板、门框和灯板。
- 当前选中的材质会被高亮，并把当前贴图或颜色实时应用到对应表面。
- 调整 `UV 缩放`、`UV 偏移`、颜色和灯板自发光时，预览立即更新，不需要先保存。
- 没有贴图的材质会用当前颜色加简单网格显示，方便判断目标表面和比例。

验收结果：PASS

验证：
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py`：PASS。
- `python codex_tools\texture_tool\texture_tool_server.py --self-test`：PASS。
- 本地 API/HTML 冒烟测试：PASS。
- Edge 无头截图：`artifacts/screenshots/texture_tool_model_preview_20260504.png`。
- 验证用的临时贴图工具服务已关闭。

注意：
- 若旧工具页面已经打开，需要关闭当前工具命令行窗口后重新双击 `start_texture_tool.bat`，新版页面才会加载。

## MVP Room Launcher Restored - 2026-05-04

目标：
- 恢复 MVP 验证房间的直接启动入口，避免清理旧 `latest demo` 快捷方式后无法快速进入四房间测试。

修改内容：
- 新增 `run_mvp_room.bat`。
- 启动场景为 `res://scenes/mvp/FourRoomMVP.tscn`。
- 日志写入 `logs/run_mvp_room.log`。
- 正常退出时命令行窗口会直接关闭；只有出错时才暂停并显示日志尾部。
- 保持旧 `run_latest_demo.bat` 删除状态，避免继续使用含义不清的旧启动项。

验收结果：PASS

验证：
- `scenes/mvp/FourRoomMVP.tscn` 存在：PASS。
- `scenes/modules/PlayerModule.tscn` 存在：PASS。
- Godot 4.6.2 console executable 存在：PASS。
- MVP headless 短启动退出码 `0`：PASS，日志 `logs/run_mvp_room_headless_check_20260504_185530.log`。

说明：
- 日志里的 MCP runtime 端口占用提示来自已打开的编辑器/运行时，不影响本次 MVP 启动验证。

## Texture Tool WebGL Preview And Folder Buttons - 2026-05-04

目标：
- 把贴图工具里的假透视预览改成真实 WebGL 3D 预览。
- 在材质/贴图位置增加打开文件夹按钮，方便直接访问源文件。

修改内容：
- `模型实时预览` 现在使用 WebGL canvas 渲染 3D 样板间。
- 样板间包含墙面、地面、天花板、门框盒子、门洞和灯板。
- 当前选中的材质会贴到对应 3D 表面。
- UV 缩放、UV 偏移、颜色、自发光输入变化会实时刷新预览。
- 预览支持鼠标拖动旋转和滚轮缩放。
- `UV 和材质` 卡片右上新增 `打开材质文件夹`。
- 每个贴图缩略图旁新增 `打开文件夹`。
- 后端新增 `/api/open-folder`，只允许打开项目内材质/贴图路径。
- 工具新增 `--port` 参数，便于验证时使用临时端口，不占用正常 `8765`。

验收结果：PASS

验证：
- `python -m py_compile codex_tools\texture_tool\texture_tool_server.py`：PASS。
- `python codex_tools\texture_tool\texture_tool_server.py --self-test`：PASS。
- 临时端口 `8766` HTML/API 冒烟测试：PASS。
- Edge 无头截图：`artifacts/screenshots/texture_tool_webgl_preview_wait_20260504.png`。
- 已关闭旧的 `8765` 贴图工具服务，重新双击 `start_texture_tool.bat` 会加载新版。
