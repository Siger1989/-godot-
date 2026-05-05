# DECISIONS閿濇粌鍑＄涵顔款吇閹垛偓閺堫垰鍠呯粵?
閺堫剚鏋冩禒鍓佹暏娴滃酣妲诲?Agent 閸欏秴顦查弨鐟板綁鐠侯垳鍤庨妴鍌炴珟闂堢偟鏁ら幋閿嬫绾喛顩﹀Ч鍌︾礉閸氾箑鍨稉宥堫洣閹恒劎鐐曟潻娆庣昂閸愬磭鐡ラ妴?
## D093: FourRoomMVP is the direct editable monster-size source

Current accepted rules:

- `FourRoomMVP.tscn` itself is the editable source of truth for monster size. The user should open the MVP scene and adjust the direct child monster nodes under `MonsterRoot`.
- `MonsterRoot` in `FourRoomMVP.tscn` must remain a direct editable `Node3D`, not an instance of `scenes/modules/MonsterSizeSource.tscn`.
- The MVP size room keeps exactly one source node per monster type: `Monster`, `Monster_Red_KeyBearer_MVP`, and `NightmareCreature_A_MVP`.
- Generated duplicate types must alias to those source nodes: `normal_b` reads `MonsterRoot/Monster`, and `nightmare_b` reads `MonsterRoot/NightmareCreature_A_MVP`.
- `scripts/monster/MonsterSizeSource.gd` reads saved transforms from `res://scenes/mvp/FourRoomMVP.tscn` and instantiates the appropriate monster template for other scenes.
- `open_monster_size_source.bat` and `open_mvp_monster_room.bat` should open `res://scenes/mvp/FourRoomMVP.tscn`.
- This supersedes D090's separate `MonsterSizeSource.tscn` workflow and the earlier dual-Nightmare source arrangement in D092.

## D092: FourRoomMVP red hunter, cabinet key, keyed outer exit, and dual Nightmare sonar

Current accepted rules:

- `FourRoomMVP.tscn` is the active compact mechanics scene for this APK pass; `project.godot` currently points to `res://scenes/mvp/FourRoomMVP.tscn`.
- As superseded by D093, the editable MVP monster-size room now contains one source per monster type: `Monster`, `Monster_Red_KeyBearer_MVP` as the red hunter, and `NightmareCreature_A_MVP`.
- The red hunter keeps `monster_role = "red"` and the red visual treatment, but it must not carry, expose, or drop the escape key. It attacks any living creature it can see and faces the prey during attacks.
- The escape key is an independent pickup resource at `scenes/modules/EscapeKeyPickup.tscn`, currently placed as `LevelRoot/Props/CabinetTop_EscapeKey` on the Room_B cabinet.
- The outer exit is in Room_C's north wall. `SceneBuilder.gd` owns the generated `WallOpening_Exit_C_North` and `DoorFrame_Exit_C_North`; `FourRoomMVP.tscn` owns the keyed door instance `Door_Exit_C_North_Keyed`.
- `DoorComponent.gd` owns locked-door behavior through `requires_escape_key`; the player still uses the normal `E` interaction path.
- Nightmare monsters remain hearing-only. They do not use player vision, and both emit periodic sonar-like calls via `NightmareSonarAudio`.
- Focused regressions for this setup are `ValidateFourRoomMVPMonsterSet.gd`, `ValidateNightmareHearingAI.gd`, `ValidateMonsterSizeSource.gd`, and `ValidateCleanRebuildScene.gd`.

## D091: NightmareCreature_A is the active hearing-only MVP monster

`CreatureZombie_A` has been removed from active project assets and MVP/resource scenes. `NightmareCreature_A` is now the imported gameplay monster used in `FourRoomMVP`.

Current accepted rules:

- Active Nightmare gameplay uses `assets/backrooms/monsters/NightmareCreature_Monster.tscn`, which wraps `NightmareCreature_A.tscn` and attaches `MonsterController.gd`.
- The editable source node is `MonsterSizeSource.tscn/NightmareCreature_A_MVP`; user size/transform edits should still happen in `MonsterSizeSource.tscn`.
- `monster_role = "nightmare"` must not use player vision. It detects only player movement/footstep noise, chases while the player is moving, investigates the last heard position after the player stops, and attacks only when close.
- Normal monsters should not treat the Nightmare monster as a visual threat for their flee behavior.
- `ValidateNightmareHearingAI.gd` is the focused regression for this behavior.
- This decision supersedes the candidate-only status in D089 for MVP gameplay. Attribution and production licensing notes for `NightmareCreature_A` still apply.

## D090: MonsterSizeSource is the editable monster size source

Monster sizing should no longer be copied by hand across MVP, resource review, and generated monster spawning.

Current accepted rules:

- Superseded by D093: the editable source is now `res://scenes/mvp/FourRoomMVP.tscn`, under its direct `MonsterRoot`.
- The user should adjust one direct child per monster type in the MVP scene when changing global monster size.
- Future generated monster spawns should read transforms through `scripts/monster/MonsterSizeSource.gd`, not assign hardcoded root scales.
- Resource-showcase rebuilds should copy scale from `FourRoomMVP.tscn` through `MonsterSizeSource.gd` for monster entries.
- `ValidateMonsterSizeSource.gd` is the focused regression for the source scene.
- `NightmareCreature_A_MVP` is now controller-backed gameplay. Any future imported monsters must still be integrated explicitly before gameplay use.

## D089: NightmareCreature_A has validated candidate animation mapping but is not gameplay-wired

`NightmareCreature_A` is the preferred imported-monster gameplay candidate for a later pass because it is much lower-poly than `CreatureZombie_A` and uses `CC-BY-4.0`, but it must remain candidate-only until explicitly wired and tested.

Current accepted rules:

- `assets/backrooms/monsters/NightmareCreature_A.tscn` may store candidate gameplay animation metadata for idle, walk, run, attack, death, hit, and roar.
- `MonsterController.gd` may expose optional `attack_animation` and `death_animation` fields. If those fields are empty or invalid, the controller must fall back to `idle_animation` so existing simple monsters keep their old behavior.
- Configured attack and death animations should not be forced to loop.
- `ValidateNightmareCreatureAnimationMapping.gd` is the focused regression for the candidate mapping.
- Candidate mapping does not mean gameplay integration is complete. A future pass still needs a controller-backed scene, collision/scale checks, attribution handling, optional hit/roar/death behavior, and FourRoomMVP runtime validation.
- Do not add this imported candidate to proc-maze gameplay while the large layout remains paused.

## D088: Imported third-party monsters are showcase-only until mapped and cleared

User-provided monster GLBs may be added to the project resource library and unified showcase before gameplay integration, but they are not automatically production/gameplay-ready.

Current accepted rules:

- Imported monster resource GLBs belong under `res://assets/backrooms/monsters/`.
- Each imported monster should have a lightweight wrapper `.tscn` with source title, author, license, triangle count, animation count, and a display height/scale decision.
- New imported monsters should appear in `res://scenes/tests/Test_NaturalPropsShowcase.tscn` and be preserved by `BuildNaturalPropScenes.gd`.
- `ValidateResourceShowcase.gd` should include them so future showcase rebuilds cannot silently drop them.
- `ValidateImportedMonsterAssets.gd` is the focused regression for imported monster metadata and basic display viability.
- Do not attach imported monster GLBs to `MonsterController.gd` until their rig, animation names, root motion, collision shape, scale, and behavior mapping are explicitly handled.
- License matters: `CreatureZombie_A` is `CC-BY-NC-4.0`, so it is acceptable only for non-commercial prototype/showcase use unless a proper license is obtained. `NightmareCreature_A` is `CC-BY-4.0`, but still needs attribution handling and technical integration before production use.
- Triangle budget matters: high-poly imports such as `CreatureZombie_A` need optimization before mobile gameplay use.

## D087: FourRoomMVP is the compact monster mechanic test room

While the large proc-maze layout is paused for a possible redesign, monster behavior can be tested in `scenes/mvp/FourRoomMVP.tscn`.

Current accepted rules:

- Do not use proc-maze scene placement or baking for this compact mechanics test.
- `MonsterRoot/Monster` remains the original normal monster path for existing bootstrap and validation compatibility.
- The compact MVP monster test set is exactly two normal monsters, one red key-bearer, and one Nightmare hearing monster:
  - `Monster`
  - `Monster_Normal_B`
  - `Monster_Red_KeyBearer_MVP`
  - `NightmareCreature_A_MVP`
- The red MVP test monster uses `monster_role = "red"` and `attach_escape_key = true`; it must create the visible `ChestEscapeKey` and expose `has_escape_key = true`.
- The FourRoomMVP scene/player use `mvp_player_immortal = true`. Red-monster hits against that player are test hits only and must not call player damage.
- Red-versus-normal combat remains asymmetric: one normal counter-hit removes more than half of red health, and two normal counter-hits can kill the red monster and drop `EscapeKeyPickup`.
- `ValidateFourRoomMVPMonsterSet.gd` is the regression for this compact test setup.
- Monster collision validation must account for the accepted nonuniform monster root scale when comparing local visual bounds to world movement limits.

## D086: Pause proc-maze placement while layout may change

When the user is considering a large map-layout redesign, do not keep changing generated proc-maze placement, door locations, prop density, or baked scene layout.

Current accepted rules:

- Large-scene layout/placement work is paused until the new layout direction is clear.
- Control/system fixes that do not commit to a layout may continue when requested.
- Phone hiding must provide an explicit exit button while inside a locker, because the normal player interaction prompt is hidden while interaction is locked.
- The locker interior exit affordance is `HideLockerExitButtonLayer/ExitHideButton` with text `E 出来`.
- Phone sprint should be visible as a clear `跑步` button in the right-thumb area, not as an ambiguous tiny one-character control.
- Do not add extra proc-maze lockers, move existing proc-maze prop placements, bake a new large scene, or export a layout-dependent APK during this pause.

## D085: New resources go into one unified showcase scene

All authored gameplay/resource assets should have a visible instance in one shared resource showcase scene so the user can review scale, material, and style in one place.

Current accepted rules:

- The unified showcase scene is `res://scenes/tests/Test_NaturalPropsShowcase.tscn`.
- The root launcher is `run_resource_showcase.bat`, and its log is `logs/run_resource_showcase.log`.
- The showcase currently contains the first 15 natural props, `OldOfficeDoor_A`, `HideLocker_A`, `PlayerModule`, a normal `MonsterModule`, and the red key-bearer monster.
- Future new small props, doors, hideables, characters, monsters, or reusable resource assets should be added to this same showcase unless the user explicitly asks for a separate specialist scene.
- `BuildNaturalPropScenes.gd` must preserve the unified additions when regenerating the natural-prop wrappers/showcase.
- `ValidateResourceShowcase.gd` is the regression for required showcase contents and current monster scale.
- The showcase is an interactive review scene, not a static gallery. It should keep orbit camera control, wheel zoom, resource selection, focus, runtime rotation, runtime scale, and reset controls.
- Runtime scale changes inside the showcase are temporary review adjustments only. Permanent size changes must be made deliberately in the authored model or wrapper scene.
- New proc-maze monster instances must use the user's FourRoomMVP-tuned monster scale `(0.953989, 0.387199, 0.688722)`. `MonsterModule.tscn` and `TestProcMazeMap.gd` both preserve that scale so generated normal/red monsters do not revert to the old default size.

## D084: Proc-maze guidance arrows and red monster key are generator/runtime owned

Exit-guidance graffiti in the large proc-maze MVP should remain generated from the graph path to the exit, not hand-placed into the baked scene.

Current accepted rules:

- Guidance arrows are created by `ProcMazeSceneBuilder.gd` under `LevelRoot/GuidanceGraffiti`.
- Arrow placement must keep a safe side distance from door frames and a small positive offset from the wall surface to avoid clipping, z-fighting, or sitting on top of a door trim.
- `ValidateGuidanceGraffiti.gd` must check the generated `door_side_offset` and `wall_offset` metadata so future changes cannot silently reintroduce the doorway-overlap bug.
- Red and normal monsters in `scenes/tests/Test_ProcMazeMap.tscn` should be spawned by `TestProcMazeMap.gd` from generated module metadata, not hand-added to one baked scene position.
- The red key-bearer is identified through `monster_role = "red"` and `attach_escape_key = true`.
- The visible escape key is owned by `MonsterController.gd` as a runtime child named `ChestEscapeKey`, so it follows the red monster when the monster moves.
- The chest key should be visually obvious and readable in mobile play, but it should remain a lightweight mesh made from simple parts and should not add collision.
- `ValidateProcMazeMonsterKey.gd` is the regression for red monster count, red visual material, key presence, and visible gold key parts.
- This decision covers the visual key-bearer pass only. Full red-monster combat, key pickup/drop, and key-locked exit victory logic should be implemented and validated as a separate gameplay pass.

## D083: Mobile joystick must be inset from the phone corner

The mobile movement joystick should sit in the lower-left thumb zone, not tight against the screen corner.

Current accepted rules:

- Default joystick radius is `92` and default margin is `Vector2(126, 126)`, placing the center about `218px` from the left and bottom edges.
- Touch-start detection should use the comfortable area around the joystick center, controlled by `mobile_joystick_start_radius_multiplier`, instead of relying only on a fixed screen-left percentage cutoff.
- Keep the visible joystick and accepted touch area aligned; do not move only the art without updating `_is_mobile_stick_start()` validation.
- Future phone-feel tuning should adjust `mobile_joystick_margin`, `mobile_joystick_radius`, or `mobile_joystick_start_radius_multiplier` in `PlayerController.gd`, then rerun `ValidateMobileControls.gd` and rebuild the APK.

## D082: Android export toolchain lives on D drive

Android APK export for this project is now configured around the D-drive toolchain under `D:\GodotAndroid`.

Current accepted rules:

- Java SDK path: `D:\GodotAndroid\jdk-17`.
- Android SDK path: `D:\GodotAndroid\android-sdk`.
- Debug keystore path: `D:\GodotAndroid\keystores\debug.keystore`.
- Godot 4.6.2 Android export templates are stored at `D:\GodotAndroid\godot_export_templates\4.6.2.stable`.
- The required Godot template lookup path under `%APPDATA%\Godot\export_templates\4.6.2.stable` is a junction to the D-drive template directory. Do not replace it with a full C-drive copy unless explicitly requested.
- Android SDK packages installed for export include platform-tools, `platforms;android-35`, `build-tools;35.0.0`, `build-tools;35.0.1`, `cmake;3.10.2.4988404`, and `ndk;28.1.13356709`.
- Android export requires `rendering/textures/vram_compression/import_etc2_astc=true` in `project.godot`; without it, Godot 4.6 can fail Android export validation with an empty configuration-error message.
- Empty proc-maze module `.tscn` placeholders must remain valid Godot scenes with a root `Node3D`, because export scans resources even if runtime generation only uses their paths as metadata.
- The current debug APK target remains `builds/android/backrooms_proc_maze_mvp_debug.apk`.

## D081: Proc-maze MVP export target owns generated natural-prop placement and mobile controls

The large playable MVP target is now `scenes/tests/Test_ProcMazeMap.tscn`. Natural environmental props in this scene must be generated by the proc-maze builder, not hand-edited into the baked scene, so future rebuilds and exports keep the same placement rules.

Current accepted rules:

- `project.godot` main scene points at `res://scenes/tests/Test_ProcMazeMap.tscn` for the large-scene MVP target.
- Proc-maze props live under generated `LevelRoot/Props` and use existing reusable authored GLB wrapper scenes.
- Placement is driven by space metadata, solid-wall candidates, and sparse deterministic selection. Do not add `if Room_A/Room_B/...` or hand-place baked proc-maze scene nodes.
- Blocking props must stay out of generated door clearances, entrance/exit/special markers, and corridor spaces.
- Corridors should mainly receive wall details such as vents, electric boxes, and pipes; floor blockers belong in wider room-like spaces, near walls/corners.
- The hideable locker may appear sparsely as a reusable proc-maze prop through its existing `interactive_hideable` component.
- Mobile movement is handled by `PlayerController.gd` through a left-bottom virtual joystick on Android/iOS/touch devices. It feeds the same movement vector as keyboard input.
- The visible interaction button remains the phone-friendly tap target and continues to call the same interaction path as keyboard `E`.
- Android export uses the `Android` preset in `export_presets.cfg`, targeting `builds/android/backrooms_proc_maze_mvp_debug.apk` with arm64-v8a. The preset excludes `artifacts/`, `logs/`, `docs/`, `codex_tools/`, and `builds/`.
- Producing an APK requires local Godot Android export templates, Java SDK, Android SDK paths, and ETC2/ASTC texture import enabled. The current accepted local installation is the D-drive setup in D082.

## D080: Hideable lockers use authored GLBs and component-limited slit vision

Hideable environmental props are reusable authored assets with explicit interaction components. They should not be built as final Godot primitive art or hardcoded to one room.

Current accepted rules:

- Hideable prop references are image2 modeling references only. Do not use reference-board PNGs as direct final textures.
- `HideLocker_A` is authored in Blender and exported as an independent GLB under `assets/backrooms/props/furniture/`.
- `HideLocker_A` front art should read as one integrated cabinet door with upper viewing slits, not as a separate lower board plus unrelated upper grille.
- Godot may add a reusable wrapper scene, simple `StaticBody3D + BoxShape3D` collision, metadata, hide/camera/exit markers, and an interaction component.
- Godot must not use final `BoxMesh`, `CSG`, or `PlaneMesh` primitive art for the locker body.
- Hideable lockers use the persistent `interactive_hideable` group and expose `interact_from()` so the player `E` path can interact without room-specific logic.
- The player should show a visible interaction button/prompt near usable hideables. The button must call the same interaction path as keyboard `E`, not a separate hide-only shortcut.
- Entering a hideable locker locks player movement, hides the player model, temporarily disables player collision, moves the camera to a slit anchor, narrows FOV, and clamps view yaw/pitch.
- A close player facing the cabinet front should be allowed to enter without needing exact marker alignment; interaction should be judged against the front face area.
- Hideable slit-view mouse vertical look currently uses the inverted Y behavior requested for the locker peek view.
- Hideable slit masks should use fully opaque black core blocks. Any defocus effect belongs in soft edge feather strips, not in making the main black blocks transparent.
- Slit-view restriction is owned by `HideableCabinetComponent` exports (`peek_fov`, `peek_yaw_limit_degrees`, `peek_pitch_limit_degrees`) so future lockers can tune it per asset.
- The slit-view UI mask is a camera/player interaction overlay, not a world-space black/gray visibility-cover mesh and not part of the formal visibility system.
- Pressing `E` again must restore player visibility/collision, movement, camera FOV/transform, and camera controller processing.
- Resource review belongs in a showcase/test scene first, but small/new props should also get at least one deliberate `FourRoomMVP` placement for player-view validation unless the user explicitly asks for resource-only work.
- `HideLocker_A` is currently placed as `LevelRoot/Props/RoomC_HideLocker_A` in Room_C, near the east wall and facing inward.
- MVP hideable placement must stay sparse: near walls/corners/side areas, not in door centers, not in room centers, and not repeated through every doorway or room.

## D079: Selected doors use Blender-authored GLBs and must not fill every frame

Backrooms door assets follow the same authored-asset pipeline as natural props. A door may be a physical blocker, but it must be intentionally placed and must not turn every door frame into the same repeated obstacle.

Current accepted rules:

- Door references are image2 modeling references only. Do not use reference-board PNGs as direct final textures.
- Door art is authored in Blender and exported as an independent GLB under `assets/backrooms/props/doors/`.
- Godot wrapper scenes may add `DoorComponent`, resource metadata, a hinge pivot, simple `StaticBody3D + BoxShape3D` collision, and selected placement.
- Godot must not use final `BoxMesh`, `CSG`, or `PlaneMesh` primitive art for door assets.
- `OldOfficeDoor_A` is currently a closed old-office door sized for the existing MVP frame and placed only at `LevelRoot/Doors/Door_P_BC_OldOffice_A`.
- Other FourRoomMVP door frames must remain without this selected door unless a future placement pass intentionally adds different doors.
- Door collision must not block every route in the MVP room.
- Interactive doors should use `DoorComponent.interact_from()` / `open_toward_direction()` so the door can choose its open angle from the player's facing direction.
- The player `interact` action is bound to `E` for the current MVP debug interaction path.
- Runtime scene rebuilds must relink selected doors to matching portals by `portal_id`; do not rely only on manually baked `door_node_path` values.
- Portal open/closed state should be read from the linked door component, while the door owns open/close animation and collision.

## D078: Problem natural props may use simple blocker collisions and generated low-res material textures

When a natural prop visibly lets the player stand inside it, the wrapper scene should use a simple mobile-safe collision shape instead of leaving the prop nonblocking. This is allowed for small props only when their placement is already outside doors, room centers, and main routes.

Current accepted rules:

- `Bucket_A`, `Mop_A`, and `Chair_Old_A` use reusable wrapper `StaticBody3D + BoxShape3D` collisions because they are visible clipping risks in the current FourRoomMVP placement.
- New prop collisions must remain simple. Do not use complex mesh collision for these natural environment props.
- Collision expectations belong in `scripts/tools/ValidateNaturalProps.gd` so future wrapper rebuilds cannot silently remove them.
- Material realism for these props should be authored in Blender/source assets and exported through GLB, not patched as final BoxMesh/CSG/PlaneMesh art inside Godot.
- Low-resolution generated procedural albedo textures are acceptable for old plastic, cloth/vinyl, and beige furniture when they are created from code or authored source, not copied from image2/reference boards.
- Keep colors restrained and old-office compatible. More realism should mean subtle grain, wear, dust, and edge scuffs, not high-saturation colors, logos, text, warning marks, blood, or gameplay hints.
- If a currently open DEBUG window shows stale prop materials or collisions, relaunch it after import/build so Godot reloads the updated GLBs and wrapper scenes.

## D077: Natural environment props use Blender-authored reusable GLBs

Backrooms natural environment props are authored assets, not final Godot primitive placeholders. The first reusable batch must stay on the image2 reference -> Blender model -> individual GLB -> Godot wrapper scene -> sparse scene placement pipeline.

Current accepted rules:

- Reference images are only modeling references; they must not be used as direct textures on props.
- Final props are individual GLBs under `assets/backrooms/props/<category>/`, with matching reusable `.tscn` wrapper scenes.
- Godot may manage import, wrapper scenes, simple collisions, resource organization, screenshots, and placement; it must not use BoxMesh/CSG/PlaneMesh as final natural prop art.
- Props must avoid text, arrows, numbers, warning signs, logos, blood, monster marks, gameplay hints, and high-saturation modern/scifi styling.
- Wrapper collisions stay simple. Larger path blockers use BoxShape3D; small, wall, pipe, and detail props should usually remain nonblocking for mobile performance.
- FourRoomMVP prop placement belongs under `LevelRoot/Props` and must remain sparse: near walls/corners/side areas, away from door centers, room centers, and main walkable routes.
- Any tool that rebuilds and saves FourRoomMVP must assign owners for generated `Geometry`, `Areas`, `Portals`, `Markers`, `Lights`, and `Props` before saving, otherwise baked geometry can be lost.
- Editable `.blend` sources can live under `artifacts/blender_sources/`, but that folder should stay ignored by Godot import through `.gdignore`.

## D076: Texture layer scale is split into horizontal and vertical controls

Texture-tool layer composition must expose size and placement in terms a non-technical user can understand. A single `scale_min` / `scale_max` pair is not clear enough once grime needs separate width, height, and wall-foot/ceiling-side placement tuning.

Current accepted rules:

- Layer UI should show horizontal scale minimum/maximum as left-right width controls.
- Layer UI should show vertical scale minimum/maximum as up-down height controls.
- Each layer may define `position_y_offset` from `-1.0` to `1.0`; positive values move the overlay downward.
- Edge-anchored top/bottom layers must not clamp the offset back to the same edge. They may move partly outside the canvas and be cropped, so bottom positive-down values visibly move toward/past the wall foot and negative values move upward into the wall.
- Preview composition and saved composition must use the same backend placement calculation.
- Existing configs with only `scale_min` / `scale_max` remain valid; when split fields are missing, the old uniform scale range is used for both X and Y.
- Saved/new layer payloads may retain legacy `scale_min` / `scale_max` as fallback metadata, but the UI should not present those old ambiguous labels as the primary controls.
- Runtime random wall grime should receive the same authoring intent through `size_x_scale`, `size_y_scale`, `top_offset`, and `bottom_offset` so Godot walls do not drift away from the tool settings.

## D075: Grime layers own probability, random rotation, and wall-aligned edge masks

Wall grime should look like stains on a surface, not pasted rectangular image cards. Texture-tool layer controls and runtime wall grime must keep the stain shape random while keeping wall-edge masks aligned to the wall.

Current accepted rules:

- Each grime layer may define `probability` from `0.0` to `1.0`; this controls whether each random candidate placement appears.
- Each grime layer may define random stain rotation, but rotation applies to the stain image/sample only.
- Top/bottom/left/right mask feathering must be generated after rotation, so the mask stays aligned to wall edges.
- Top grime must start at the ceiling-side edge and fade downward. Bottom grime must start at the wall-foot edge and fade upward.
- `bottom_fade` and `top_fade` masks must include horizontal edge feathering to avoid hard rectangular seams.
- Runtime wall grime must sample with the same material UV scale/offset as the base wall texture, so saved UV offset changes affect actual game grime placement.
- Texture-tool compose/sync should persist current UV/material controls before generating textures or rebaking Godot scenes.

## D074: Texture-tool wall preview must use the same vertical image orientation as generated walls

The texture tool's WebGL model preview is a parity tool for the actual generated wall material. It must not silently flip the image vertically after the generated wall UV rule maps image bottom to the wall foot.

Current accepted rules:

- WebGL preview texture upload must keep `UNPACK_FLIP_Y_WEBGL=false` for the 3D model preview.
- Wall preview geometry keeps the same wall-height UV convention as `GeneratedMeshRules.gd` and `WallOpeningBody.gd`.
- The wall layer runtime config is generated from texture-tool layer settings, so top/bottom layer placement affects the actual runtime grime shader.
- A bottom-only wall layer should preview and bake as bottom/wall-foot grime. A top-only wall layer should preview and bake as ceiling-side grime.
- If the texture tool server is running during edits, close/relaunch it so the browser loads the new embedded WebGL code.

## D073: Wall grime is runtime-randomized, not baked into one fixed albedo

The user's intent is that wall grime varies across surfaces at runtime. A texture-tool random composition that writes one dirty `backrooms_wall_albedo.png` is not enough, because every wall then repeats the same random result.

Current accepted rules:

- The wall base albedo remains the clean/base wall texture.
- Wall overlay candidate images are collected into `materials/textures/backrooms_wall_runtime_grime_atlas.png`.
- Wall layer placement/count/opacity/band settings are summarized into `materials/textures/backrooms_wall_runtime_grime_config.json`.
- Wall grime placement is sampled in `contact_ao_surface.gdshader` from the runtime atlas, using per-wall material seeds.
- The shader must use the runtime config's top/bottom weights instead of hardcoded equal top/bottom placement.
- Solid walls, doorway wall pieces, internal walls, and WallJoint/corner pillar surfaces should receive seeded wall material instances through the shared builders.
- The texture tool may rebuild the runtime grime atlas for wall layers, but wall layer generation must not replace the wall albedo with a single fixed random composite.
- If an already-open Godot DEBUG/game window shows stale grime, close and relaunch it after sync/bake so resource and scene-local material wrappers reload.

## D072: Wall texture vertical mapping uses wall foot as image bottom

Ordinary generated wall boxes and doorway wall/opening pieces must not use different vertical UV origins for the same wall material. A mesh-local center origin makes lower-wall grime and repeated horizontal bands appear at different heights than the opening wall beside a door frame.

Current accepted rules:

- Wall faces map the texture bottom to the wall foot/floor side and the texture top to the ceiling side.
- Vertical wall-face UV V is derived from global wall height, not from each box mesh's local center.
- Solid generated wall boxes pass explicit world-UV parameters through `GeneratedMeshRules.build_box_mesh`.
- `WallOpeningBody.gd` remains on the same full-wall-height rule.
- The texture tool WebGL preview must follow this same rule for generated solid walls so preview and in-game grime placement match.
- `ValidateGeneratedMeshRules.gd` should reject regular wall/opening meshes whose vertical UV V no longer matches full-wall-height placement.
- This is a shared generation/material rule, not permission to hand-edit individual wall or door-frame nodes in baked scenes.

## D071: Texture-tool sync must rebake generated scenes

The texture tool writes shared `.tres` material files and PNG textures, but generated MVP/proc scenes can also contain scene-local `ShaderMaterial` wrappers created by `ContactShadowMaterial.gd`. Those wrappers copy material parameters such as UV scale, roughness, normal depth, and tint when the scene is baked.

Current accepted rules:

- Texture-tool "sync" must not stop at Godot resource import.
- Sync must also rebake `scenes/mvp/FourRoomMVP.tscn`, `scenes/tests/Test_ProcMazeMap.tscn`, and `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`.
- This keeps scene-local contact-shadow wrappers aligned with the shared `.tres` materials.
- If a Godot DEBUG/game window is already running, it may still show stale resources; close and relaunch the run window after sync.

## D070: Contact shadows use material-level darkening under Mobile

The project targets Godot 4.6.2 Mobile renderer. Godot warns that Environment SSAO is only available in Forward+ or Compatibility, so SSAO must not be treated as the accepted Mobile solution for junction grounding.

Current accepted rules:

- Wall/floor/ceiling/door-frame grounding uses a material-level contact-shadow ShaderMaterial wrapper, built from the existing shared material textures, colors, roughness, UV scale, and normal maps.
- The wrapper is generated by `scripts/visual/ContactShadowMaterial.gd` and uses `materials/shaders/contact_ao_surface.gdshader`.
- MVP may apply the wrapper to walls, floors, ceilings, and door frames because its fixed 2x2 grid matches the shader's simple floor/ceiling boundary assumptions.
- Proc-maze applies the wrapper only to walls, wall openings, internal walls, and door frames. Proc floors and ceilings keep their original materials to avoid false grid bands across a large arbitrary map.
- Runtime tuning belongs in `scripts/lighting/LightingTuningPanel.gd`, with controls for contact-shadow enable, strength, and maximum darkening.
- Validators may accept the contact-shadow wrapper as preserving the underlying shared material rule, but should still reject unrelated material replacements.
- Do not reintroduce SSAO as the formal Mobile contact-shadow path unless the renderer target changes or a tested compatibility decision is made.

## D069: Texture tool model preview should use game-scale doorway geometry

The texture tool's WebGL model preview should be treated as a material inspection aid for the real game scene, not a decorative approximation.

Current accepted rules:

- Doorway and door-frame preview dimensions should match the generated MVP/proc-maze constants where practical.
- The preview uses `6.0m` room size, `2.55m` wall height, `0.20m` wall thickness, `1.15m` wall opening width, `0.95m` frame inner width, `0.10m` frame trim, `0.16m` frame depth, and `2.18m` frame outer height.
- The wall should be represented as a real opening with side/header segments, not a full wall with a black rectangle.
- The door frame should read as a U-shaped frame using the same canonical dimensions as `DoorFrameVisual.gd`.
- If exact visual parity is still required later, prefer a shared exported preview mesh description over hand-maintaining divergent JavaScript dimensions.

## D068: Texture overlay layers support deletion, blend modes, and feathered masks

The beginner texture tool may provide per-layer compositing controls for grime/stain workflows.

Current accepted rules:

- Deleting a layer must persist immediately and must not be restored by stale DOM collection.
- Layers may choose blend modes: normal, multiply, screen, darken, lighten, overlay, soft light, hard light, and difference.
- Layers may use generated masks: none, soft rectangular edge, bottom fade, top fade, or radial fade.
- Mask feather is stored per layer and applied to the overlay alpha before blending.
- These controls are authoring-time texture composition features; they should write to the existing material texture slot and keep the base snapshot rule intact.

## D067: Proc-maze playable scene owns a runtime lighting tuning panel

The playable proc-maze test scene may include an in-scene light controller for visual tuning without modifying the MVP baseline scene.

Current accepted rules:

- The controller lives under `Systems/LightingTuningPanel` in `scenes/tests/Test_ProcMazeMap.tscn`.
- `ESC` shows/hides the panel and releases mouse capture.
- Clicking outside the panel hides it and returns mouse capture to gameplay.
- Controls may tune runtime light color, energy, range, attenuation, lamp-panel emission, ambient color/energy, and flicker enable.
- Runtime light tuning must refresh `LightingController`'s cached flicker baseline, otherwise flicker can restore stale values.
- The no-ceiling preview scene must not keep the playable UI/player runtime nodes.
- This is not permission to alter `scenes/mvp/FourRoomMVP.tscn` unless the user explicitly asks.

## D066: Texture tool supports base plus random overlay layers

The beginner texture tool may generate material textures through a base-plus-overlays workflow instead of requiring one fixed replacement PNG.

Current accepted rules:

- The base albedo texture is preserved as a snapshot before layer composition, so repeated saves do not keep dirtying an already composited output unless the user resets the base.
- Overlay layers may own a pool of candidate images.
- Random overlay mode chooses from the selected pool by seed/count/scale/placement settings, so a grime layer can vary between several stain images.
- Layer composition writes back to the existing material texture slot and backs up the previous output image.
- This is a texture/material authoring tool feature, not permission to add runtime random material swaps or per-room hand-edited decals.

## D065: Proc-maze doorways require entry reveal clearance

Door frames must not open directly into an abrupt wall or full-height internal partition. Each generated proc-maze opening owns a short reveal/entry buffer on both sides of the doorway.

Current accepted rules:

- Doorway reveal clearance is generated from graph/opening data, not by hand-moving baked wall nodes.
- Large-room and hub internal partitions must be trimmed or split if they intrude into the reveal buffer.
- Scene validation must reject solid boundary walls or internal partition walls inside the reveal buffer.
- `has_door_reveal_blocker=false` is required for accepted proc-maze bakes.
- The rule must preserve existing wall opening bodies, door-frame visuals, material assignments, collisions, light placement, and Mobile renderer constraints.

If a later layout needs a tight corner near a door, it should be represented as a clear room/corridor module with enough passable entry space, not as a wall starting immediately behind the frame.

## D064: Long proc-maze lamps use distributed real light sources

A long rectangular ceiling-light panel must not be lit by one full-strength central point source. That creates a visible center hotspot and contradicts the fixture shape.

Current proc-maze rule:

- A visible lamp fixture may own one or more real `OmniLight3D` sources.
- Short/room fixtures may keep one source.
- Long corridor fixtures use distributed sources along the panel's long axis.
- Distributed sources use lower per-source energy, shorter range, and stronger attenuation than a single full room light.
- Runtime flicker operates per fixture owner, so every source under the same long panel dims/brightens together.
- Validators track both `active_light_count` for visible fixtures and `active_light_source_count` for real light sources.

The current fixed proc-maze test validates at `active_light_count=28` and `active_light_source_count=38`.

## D063: Proc-maze ceiling lights are optional and must avoid walls

Procedural maze modules do not require one ceiling light per space. Lamps should support spatial readability without cluttering narrow passages.

Current accepted rules:

- Narrow corridors, L-turn corridors, T junctions, offset corridors, and short non-long corridor modules may be intentionally unlit.
- Light panels must be placed from generated module rules, not by hand-editing individual rooms.
- A ceiling panel must fit inside the module's occupied-cell footprint with clearance.
- A ceiling panel must not overlap boundary wall bodies or internal full-height partition walls in XZ.
- Each visual panel must have one or more matching real `OmniLight3D` sources, and each real source must have one matching visual panel.
- No-ceiling overview validation must use `active_light_count`, not total room count.

The current fixed proc-maze test validates at `rooms=36`, `active_light_count=28`, and `active_light_source_count=38`, leaving 8 narrow/complex spaces without ceiling-light fixtures. If a later layout adds new narrow corridor types, update both `ProcMazeSceneBuilder.gd` and `SceneValidator.gd` so the skip rule and validation rule stay aligned.

## D056: Warm ambient stays low and direct lights carry local readability

The Backrooms scenes should not rely on high warm world ambient to keep unlit corners readable.

Shared generated scenes now use `WORLD_AMBIENT_ENERGY = 0.07`. Direct ceiling lights are slightly stronger, but their falloff is also stronger:

- Four-room MVP: `CEILING_LIGHT_ENERGY = 1.12`, `CEILING_LIGHT_RANGE = 6.0`, `CEILING_LIGHT_ATTENUATION = 0.92`
- Proc-maze tests: `CEILING_LIGHT_ENERGY = 1.18`, `CEILING_LIGHT_RANGE = 6.2`, `CEILING_LIGHT_ATTENUATION = 0.92`

Keep range stable unless a later request explicitly asks for wider coverage. Increasing range would undo the intended local light / darker corner contrast.

Validation should accept darker ambient and stronger attenuation, while still requiring real `OmniLight3D` shadows, static/actor light masks, and non-zero readable light energy.

## D055: Procedural corridors use narrower width tiers than rooms

Procedural maps must make corridors read as corridors, not as long rectangular rooms.

The proc-maze registry now uses a smaller spatial cell size and explicit width tiers:

- `narrow_corridor`: 1 cell / 2.5m
- `normal_corridor`: 2 cells / 5.0m
- `normal_room`: 3 cells / 7.5m
- `large_room` / `hub_room`: 4 cells / 10.0m

Corridor modules must use corridor types such as `corridor_narrow_straight`, `corridor_long_straight`, `corridor_l_turn`, `corridor_t_junction`, and `corridor_offset`. Do not represent a corridor by using a normal rectangular room module with a long aspect ratio.

Long corridors must have a more extreme length/width ratio than rooms. Ordinary rooms must not exceed the room aspect threshold and must stay visibly wider than corridors. Large rooms and hubs must remain wider than normal rooms and may carry internal partitions, side chambers, and offset internal door structures.

Graph validation must reject:

- missing corridor width tiers,
- missing required corridor module types,
- corridor widths that approach normal room width,
- long corridors whose aspect ratio is not directional enough,
- normal rooms that become corridor-like strips,
- corridors with too many graph connections or uncontrolled side doors.

Scene construction still uses the same generated wall, opening, door-frame, material, ceiling, AO/contact-lighting, and validation rules. The width-tier change is a proc-maze module/layout rule, not permission to hand-place walls, use negative scale, stretch wall bodies, or alter `scenes/mvp/FourRoomMVP.tscn`.

## D001閿涙瓉VP 閸︽澘娴樼紒鎾寸€?

闁插洨鏁ら崶娑欏煣闂?2x2 闂傤厾骞嗛敍?
```text
Room_D  <---->  Room_C
  ^              ^
  |              |
  v              v
Room_A  <---->  Room_B
```

## D002閿涙矮绮?0 閹碱厼缂撻敍灞肩瑝娣囶喗妫柨娆掝嚖閸掑棙鏁?

閺冄冧紣缁嬪鍣烽崙铏瑰箛閻ㄥ嫰绮﹂悧鍥モ偓浣轰紗閻楀洢鈧線鈧繑妲戦悧鍥モ偓渚€浼勭純鈺呮晩娴ｅ秲鈧礁澧犻弲顖炵矋閻滆崵鎷戞晶娆欑礉娑撳秳缍旀稉鐑樻拱濞嗏€崇杽閻滄澘鐔€绾偓閵?
## D003閿涙碍膩閸ф瀵叉导妯哄帥

閹村潡妫块妴渚€妫妴浣轰紖閵嗕赋ortal閵嗕礁褰茬憴浣光偓褋鈧礁澧犻弲顖炰紕閹嘎扳偓涓廵bug 閸掑棙膩閸ф鐤勯悳鑸偓?
## D004閿涙艾褰茬憴浣光偓褌绗夐弰顖涘煣闂傛潙绱戦崗?
娑撳秷鍏橀悽?`current_room` / `visited_rooms` 閻╁瓨甯撮崘鍐茬暰閹村潡妫块弰鍓с仛閵嗗倹娓剁紒鍫濈安閺€顖涘瘮閸栧搫鐓欑痪褍褰茬憴浣光偓褍鎷扮拋鏉跨箓閵?
## D005閿涙艾澧犻弲顖炰紕閹革紕瀚粩?
閸撳秵娅欓柆顔藉皡閸欘亣袙閸愬磭娴夐張铏规箙娑撳秷顫嗛悳鈺侇啀閻ㄥ嫰妫舵０姗堢礉娑撳秴寮稉搴㈠灛娴滃绯犻梿?/ 鐠佹澘绻?/ 閺堫亞鐓￠崠鍝勭厵闁槒绶妴?
## D006閿涙氨浼呴弶鍨嫲閻喎鐤勯悘顖氬帨閸掑棛顬?

閻忣垱婢?Mesh 閺勵垰褰茬憴浣哄⒖娴ｆ搫绱滾ight3D 閺勵垳鍙庨弰搴㈢爱閵嗗倻浼呴弶澶哥瑝閸欘垵顫嗘稉宥囩搼娴滃海浼呴崗澶婂彠闂傤厹鈧?
## D007閿涙艾顦绘晶?/ VOID

婢舵牕顣炬径鏍︽櫠韫囧懘銆忛弰顖炵拨閼瑰弶鍨ㄩ弳妤勫 VOID閿涘奔绗夐弰鍓с仛姒涘嫯澹婄€广倕鍞存晶娆戠剨閵?
## D008閿?D 濡€崇€锋惔鎾茬瑢娑撴槒顫楀Ο鈥崇€?

`E:\godot閸氬骸顓籠3D濡€崇€穈 娴ｆ粈璐熼崥搴ｇ敾 3D 濡€崇€锋惔鎾扁偓淇檢hujiao.glb` 娴ｆ粈璐熼悳鈺侇啀娑撴槒顫楀Ο鈥崇€烽敍灞芥躬 Phase 2 閻溾晛顔嶆稉搴ｆ祲閺堟椽妯佸▓鍨复閸忋儯鈧繖guai1.glb` 瑜版挸澧犳禒鍛稊娑撳搫鎮楃紒顓熲偓顏嗗⒖濡€崇€烽崐娆撯偓澶涚礉娑撳秴婀幀顏嗗⒖ AI 鐞氼偄鍘戠拋绋垮鐎圭偟骞囬幀顏嗗⒖闁槒绶妴?
## D009閿涙odot 閻╊喗鐖ｉ悧鍫熸拱

閺堫剟銆嶉惄顔讳簰閸氬孩瀵?Godot 4.6.2 閸掓湹缍旈崪宀勭崣鐠囦降鈧繖project.godot` 娴ｈ法鏁?Godot 4.6 閻楄鈧勭垼鐠佸府绱遍崥搴ｇ敾閼存碍婀伴妴浣告簚閺咁垰鎷版宀冪槈濞翠胶鈻兼导妯哄帥閸忕厧顔?Godot 4.6.2閵?
## D010閿涙氨些閸斻劎顏〒鍙夌厠閻╊喗鐖?

閺堫剟銆嶉惄顔讳簰閹靛婧€缁夌粯顦叉稉铏规窗閺嶅浄绱滸odot 妞ゅ湱娲版担璺ㄦ暏 Mobile 濞撳弶鐓嬮崳銊ｂ偓鍌氭簚閺咁垬鈧焦娼楃拹銊ｂ偓浣轰紖閸忓鎷伴崥搴㈡埂閺佸牊鐏夐崥搴ｇ敾闁姤瀵滅粔璇插З缁旑垱鈧嗗厴妫板嫮鐣荤拋鎹愵吀閿涘奔绗夋妯款吇娴ｈ法鏁?Forward+ 娑撴挸鐫樻妯奸獓閺佸牊鐏夐妴?
## D011閿涙艾缍嬮崜?MVP 缁屾椽妫垮В鏂剧伐

瑜版挸澧?MVP 娑撳秳绻氶悾娆忋亯閼鸿鲸婢橀敍灞肩┒娴滃孩鏋╂穱顖濐潒閺屻儳婀呴崪宀€些閸斻劎顏拫鍐槸閵嗗倸顣炬姗€鍣伴悽?2.55m閿涘苯顣惧▓闈涘帒鐠佸摜瀹?0.04m 閻ㄥ嫯浜ゅ顕€鍣搁崣鐘虫降濞戝牓娅庣紓鏍帆閸ｃ劏顫嬬憴鎺嶇瑓閻ㄥ嫬顣剧憴鎺戞嫲闂傘劌褰涚紓婵嬫閵?
## D012閿涙艾婀撮棃顫瑢闂傘劍绀婄亸浣界珶

瑜版挸澧?MVP 娑撳秴鍟€娴ｈ法鏁ゅВ蹇庨嚋閹村潡妫块崡鏇犲閸︾増婢橀幏鍏煎复閿涘本鏁奸悽銊よ⒈閸ф绻涚紒顓炴勾閺夎儻顩惄鏍︾瑓閹烘帒鎷版稉濠冨笓閹村潡妫块崠鍝勭厵閿涘苯鍣虹亸鎴濆彙娴滎偉绔熼棁鑼闯閵嗗倹鐦℃稉?Portal 娴ｈ法鏁ゆ稉銈勬櫠缁斿鐓撮崝鐘辩瑐濡?闂傘劍銈ｇ紒鍕灇 U 閸ㄥ娴愮€规岸妫鍡礉閻劋绨柆顔荤秶闂傘劍绀婃笟褑绔熼妴浣风瑐濞屽灝鎷版晶娆愵唽閹恒儳绱抽妴鍌炴，濡わ綀顩惄?y=2.11 閸掓澘顣炬い?y=2.55閿涘瞼鏆愭担搴濈艾 2.15m 闂傘劍绀婃妯哄娴犮儵浼╅崗宥嗙暙閻ｆ瑦铆缂傛縿鈧倿妫幍鍥モ偓浣哥磻閸忓啿濮╅悽璇叉嫲闂傘劎濮搁幀渚€鈧槒绶悾娆忓煂 Phase 5閵?
## D013閿涙odot MCP 閹恒儱鍙嗛弬鐟扮础

Phase 2 鏉╂劘顢戞灞炬暪娴兼ê鍘涙担璺ㄦ暏 GoPeak Godot MCP閵嗕敬oPeak 娴犮儵銆嶉惄顔鹃獓閺傜懓绱￠幒銉ュ弳閿涙瓉CP 闁板秶鐤嗛崘娆忓弳 `.codex/config.toml`閿涘瓘odot addon 閸愭瑥鍙?`addons/auto_reload`閵嗕梗addons/godot_mcp_editor`閵嗕梗addons/godot_mcp_runtime`閿涘奔绗夐崗鍫滄叏閺€鐟板弿鐏炩偓 Codex 闁板秶鐤嗛妴渚皁dex 闂団偓鐟曚線鍣告潪?闁插秴鎯庨崥搴㈠閼冲€燁嚢閸欐牗鏌婃晶?MCP server閵?
## D014閿涙瓍hase 2 閻╁憡婧€鐠烘繄顬?

鏉╂劘顢戠憴鍡氼潡闁插洨鏁?`follow_offset=(0, 5, 4)`閵嗕梗look_at_offset=(0, 1, 0)`閵嗗倽顕氶柊宥囩枂鏉╂劘顢戝ù瀣繁缁?51鎺?閺傛粈鍒婄憴鍡礉濮?`(0, 6, 5)` 閺囨挳鈧倸鎮庣粔璇插З缁旑垶妲勭拠浼欑礉娑撴柧绗夐弨鐟板綁娑撴槒顫楀Ο鈥崇€峰В鏂剧伐閵?## D015: Door-frame seam sealing

Door-frame side posts intentionally overlap 0.06m into each portal opening. This avoids relying on exact edge-to-edge contact, which left visible vertical slits in the editor view. Door headers span the full outer width of both side posts. Door panels, open/close logic, and portal state wiring remain reserved for Phase 5.
## D016: Wall connection fillers

Wall segments must not rely on exact edge contact at corners or T-junctions. The MVP uses explicit `WallJoint_*` filler blocks at major wall intersections and a `Wall_A_NorthWestReturn` boundary wall for the Room_A/Room_D width offset. This keeps the prototype geometry closed while preserving the modular wall and portal data model.

## D017: Integrated door-frame visuals

Door frames are visual U-shaped trim meshes generated by one `DoorFrame_P_*` MeshInstance per portal through `DoorFrameVisual.gd`. They are not separate side-post/header wall blocks, and they do not touch the wall top. The wall above each opening is modeled separately as `WallHeader_P_*` StaticBody wall geometry, keeping collision and wall sealing owned by the wall system. The door-frame visual mesh itself must be generated as one extruded U-shaped profile, not as three joined boxes.

The current visual size is based on the user-adjusted `DoorFrame_P_AB` transform: depth scale `1.4412847`, span scale `0.947737`. Doorways whose frame spans the x-axis swap these scale axes.

Portal wall openings are also modeled as replacement bodies, not hidden old parts. Each `WallOpening_P_*` is one `StaticBody3D` that owns a monolithic U-shaped visual mesh and simple box collisions for the left side, right side, and top. The project avoids using the render mesh itself as player collision here because simple primitive collisions are cheaper and more stable on mobile while still being owned by the replacement wall-opening body.

Generated wall-opening and door-frame whitebox meshes use the same lit light gray material as the current wall whitebox. They should match outer wall lighting/shadow behavior until Phase 4 replaces the whitebox look with final wall, door, and lighting materials.

## D018: Prototype Backrooms Texture Materials

The current wall, floor, and door-frame visuals use generated 1024px tileable texture assets under `materials/textures/` and material resources under `materials/`. This is a targeted user-requested material pass, not full Phase 4 completion: lighting panels, real Light3D tuning, and exterior VOID material treatment still remain separate Phase 4 work.

## D019: Ceilings and ceiling lights

Ceilings were restored by explicit user request after the open-top debugging pass. Each room owns a separate `Ceiling_Room_*` StaticBody with a visible Mesh and collision so Phase 3 foreground occlusion can target ceiling meshes independently from walls.

Ceiling-light visuals and real lighting stay separate: `CeilingLightPanel_Room_*` MeshInstance nodes are visible lamp panels, while `CeilingLight_Room_*` `OmniLight3D` nodes live under `LevelRoot/Lights`. This preserves the rule that hiding a lamp mesh must not automatically disable the real light source.

## D020: Third-person camera and common controls

The runtime MVP camera now uses a close behind-the-player third-person follow view instead of the old high fixed offset from D014. Movement is camera-relative: `WASD` / arrow keys move relative to the current camera view, `Shift` sprints, mouse click captures the pointer, mouse movement rotates the view, `Esc` releases the pointer, and touch drag rotates the camera for mobile-oriented testing.

Manual camera yaw now follows D036: free 360-degree third-person orbit with no movement-triggered recenter. Earlier front-arc yaw limits were a temporary tuning pass and should not be treated as the current control rule.

Mouse/touch vertical look uses the user-requested swapped direction: vertical relative motion is added to camera pitch rather than subtracted.

Backward input is treated as backpedal, not a turn command. `S` / down arrow moves opposite the camera-facing direction and makes the body face forward, so the character backs up while looking forward instead of turning around or staying sideways after a previous turn.

## D021: Foreground occlusion is mesh-local visual cutout

Phase 3 uses Camera -> Player raycasts against bodies in the `foreground_occluder` group. It changes only the affected visual `MeshInstance3D` materials, keeps `StaticBody3D` and `CollisionShape3D` active, and does not participate in visibility-memory logic.

The current visual treatment is a local player-area cutout through `materials/foreground_occlusion_cutout.gdshader`: the center around the character becomes transparent and the edge feathers smoothly back to the normal material. This is the only allowed Phase 3 `ALPHA` use; large transparent walls, gray overlays, black masks, and visibility-system fade planes remain forbidden.

The automated validation script is `scripts/tools/ValidatePhase3Occlusion.gd`. It verifies that foreground wall/opening/door-frame meshes remain visible, receive a cutout `ShaderMaterial`, keep collision enabled, and restore original material overrides after the camera/player line is clear.

## D022: Door frames follow foreground occlusion visually

Door frames remain visual trim meshes, not player-blocking physics bodies. Phase 3 foreground occlusion hides them by linking `WallOpening_P_*` occluders to the matching `DoorFrame_P_*` and by checking the Camera -> Player line against the U-shaped door-frame profile.

This keeps door-frame collision out of movement while preventing floating visible frames after the wall/opening mesh has been hidden. The validation script checks that `WallOpening_P_AB` and `DoorFrame_P_AB` hide and restore together while wall-opening collision stays enabled.

## D023: Current player GLB animation mapping

`zhujiao.glb` currently exposes one `AnimationPlayer` at `ModelRoot/zhujiao/AnimationPlayer` with one skeletal animation, `mixamo_com`, length about 2.042 seconds.

Until separate walk/run/backpedal clips are exported into the GLB, the MVP maps `mixamo_com` to movement states: walk 1.0x, sprint 1.25x, backpedal -0.8x.

Because no authored idle clip exists in the current model, `PlayerController.gd` generates `idle_generated` instead of reusing a frozen movement frame. The generated idle skips POSITION tracks, uses the model Rest Pose for hips/lower-body rotations so both feet stay planted, samples upper-body rotation/scale/value data from `mixamo_com` at `idle_pose_time=1.55`, loops at 6.0 seconds, adds slightly stronger upper-body breathing through `idle_breath_degrees=1.8`, and adds occasional head/neck left-right glance motion through `idle_head_look_degrees=9.0`. It is played whenever movement input is released.

The imported `mixamo_com` clip contains a `mixamorig_Hips_01` POSITION track with large forward displacement. That root-motion track must stay disabled for the MVP; otherwise the skinned visual mesh drifts away from the `CharacterBody3D` collision capsule and appears to float or pass through walls. `PlayerController.gd` disables animation POSITION tracks by default through `lock_animation_root_motion`.

## D024: Monster MVP behavior

`guai1.glb` is now the first scene monster. It lives in `scenes/modules/MonsterModule.tscn` and is controlled by `scripts/monster/MonsterController.gd`.

The first monster AI stays intentionally small and isolated: no navmesh/pathfinding, no attack, no damage, no door logic, and no multiplayer sync. It uses direct `CharacterBody3D` movement, collision response, and three states: `WANDER`, `IDLE_LOOK`, and `FLEE`.

Forward vision is a horizontal FOV cone plus a physics raycast to the player. When the monster sees the player, it flees using the Run animation. When it does not see the player, it wanders, occasionally stops, plays Idle, and looks left/right.

The monster keeps a short flee memory through `flee_memory_time=1.5`; this prevents it from immediately cancelling flee after turning away and losing the player from its forward cone.

Monster Idle, Walk, and Run animations are looped, and POSITION tracks are disabled so imported root motion cannot detach the visual mesh from the `CharacterBody3D` collision body.

## D025: Scene-light shadows for actors

Player and monster shadows must come from real scene lights, not fake blob decals or transparent dark planes.

The four room ceiling lights are `OmniLight3D` nodes with `shadow_enabled = true` in both the baked scene and runtime `SceneBuilder.gd` output.

Ceiling light panel meshes do not cast shadows. This keeps the visible lamp panel from blocking its own light while preserving the separation between lamp mesh and real light source.

Player and monster controllers recursively set imported model `MeshInstance3D` nodes to `SHADOW_CASTING_SETTING_ON`. This keeps shadow setup robust even when the GLB internal mesh hierarchy changes.

## D026: Monster flee routing uses portals before full navmesh

The monster should not flee by only moving opposite the player's position. In the four-room MVP, that can make it press into a wall and look stationary.

Until a full navigation mesh is introduced, `MonsterController.gd` uses the existing room and portal nodes as lightweight flee routing data. While fleeing, it detects the current room area, scores connected portals, moves toward the selected portal, then targets a point just inside the connected room.

Route scoring prefers exits farther from the player and avoids the player's current area when another connected room is available. If the monster hits a wall or makes too little progress, it repaths instead of continuing to push into the same obstruction.

This remains an MVP behavior layer, not the final chase/pathfinding system.

## D027: Camera manual yaw holds while idle

Superseded by D036. This was the previous limited-orbit control rule: manual camera yaw from mouse/touch drag should not auto-recenter while the player is stationary.

The current rule is free third-person orbit, with no movement-triggered yaw recenter and no front-arc yaw clamp.

## D028: Ceiling light flicker uses real light energy

Backrooms light flicker is implemented in `LightingController.gd` as a rare runtime effect on existing ceiling lights. It changes `OmniLight3D.light_energy` so the room lighting and actor shadows react to the flicker.

Matching `CeilingLightPanel_*` meshes keep rendering; each panel gets a duplicated `StandardMaterial3D` at runtime and only its emission energy is adjusted. Real lights are not hidden or disabled by lamp mesh visibility, preserving the existing separation between lamp visuals and real Light3D nodes.

The trigger is intentionally not a fixed per-light interval. The controller waits through a randomized startup delay, then after each flicker burst applies a random global cooldown. Once cooldown ends, a low per-second probability check decides whether a burst starts. Current defaults are `startup_delay_min/max = 18/45`, `flicker_interval_min/max = 28/70`, and `flicker_chance_per_second = 0.018`.

The current visual tuning keeps normal ceiling lights brighter than the first pass: baked and runtime `OmniLight3D.light_energy` defaults are `0.82`, the ceiling-light panel material emission is `1.10`, and bright flicker spikes use `bright_energy_min/max = 1.25/1.85` so the "on" part of a flicker visibly flashes above the base room brightness.

Ceiling-light coverage must include the full room footprint, including corners and doorway-adjacent floor/wall areas. Runtime and baked `CeilingLight_Room_*` nodes currently use `omni_range = 6.0` and `omni_attenuation = 0.78`; do not lower these back to the earlier 4.2m range unless a different multi-light or baked-lighting scheme replaces this MVP setup. `ValidateSceneShadows.gd` checks the range and falloff in both baked and runtime scenes.

## D029: Monster spawn preserves editor-saved scale

Manual monster size adjustments are made on the `MonsterRoot/Monster` instance in `FourRoomMVP.tscn`. Runtime placement must preserve that saved transform scale.

`GameBootstrap.gd` therefore updates only `monster.global_position` when placing the monster at `Spawn_Monster_D`; it must not replace the monster `Basis` with identity. The current saved monster scale is `(0.953989, 0.387199, 0.688722)`, and `ValidateMonsterSavedScale.gd` verifies runtime scale matches the saved scene scale.

## D030: Floor collision is one continuous walkable hull

Floor visuals and floor physics are separated for the four-room MVP. `Floor_SouthStrip` and `Floor_NorthStrip` remain visual strips so their texture layout stays readable, but they no longer own their own collision shapes.

All walkable floor contact is handled by one continuous `Floor_WalkableCollision` `StaticBody3D` generated in both baked scene data and runtime `SceneBuilder.gd`. This avoids a physics seam between visual floor strips and gives fast-moving monsters a stable floor under door and room-boundary crossings.

## D031: Monster panic response favors immediate escape

The monster should feel startled when the player gets close. Forward cone vision still exists, but `panic_distance` triggers flee through line of sight even if the player is outside the monster's forward cone.

The monster keeps the portal-based flee route from D026, but the first moments of FLEE now apply a short start boost, higher flee acceleration, and faster Run animation playback. The movement collision is intentionally smaller than the full visual silhouette so the creature does not snag on door frames and wall edges during escape. The saved scene instance scale remains preserved by D029.

## D032: Monster locomotion animation follows local movement direction

Monster Walk and Run animations are root-motion-disabled locomotion clips. The controller owns actual movement, so animation playback direction must follow the character body's local velocity rather than assuming the body is always moving forward.

`MonsterController.gd` compares horizontal velocity against the monster's current forward direction. If the monster is moving backward relative to its facing direction, Walk/Run playback uses a negative speed scale so leg motion reverses. Flee also uses a faster turn speed so the preferred behavior is still "turn and run away"; reverse playback covers brief backing-up moments caused by panic starts, route changes, or wall/door avoidance.

## D033: FourRoomMVP is the mechanism verification room

`scenes/mvp/FourRoomMVP.tscn` is the current mechanism verification room for the project. Mechanics accepted here should be recorded in `docs/MECHANICS_ARCHIVE.md` before they are reused in larger maps.

This room is allowed to stay compact and test-focused. Later production rooms should reuse the module scenes, controllers, materials, validation scripts, and data patterns proven here instead of copying ad hoc scene edits.

When a mechanism changes, update the archive, `docs/PROGRESS.md`, root `CURRENT_STATE.md`, and the execution-package mirror docs. Add a decision entry only when the behavior becomes a stable rule.

## D034: Foreground occlusion uses probe hysteresis

Foreground occlusion should not restore a wall mesh immediately on the first clear frame. When the camera/player line crosses a wall boundary, immediate restoration can reveal the wall for one frame even though the player is still visually near the occluded region.

`ForegroundOcclusion.gd` therefore uses multiple camera-aligned target probes, bidirectional line checks, and a short cutout release delay. The system still uses local cutout materials only; it must not switch to whole-wall fade panels, large overlays, or disabled collision.

## D035: Contact grime mesh pass is removed

Superseded by direct user feedback on 2026-05-02. The global wall-floor, wall-ceiling, and door-edge grime mesh pass made the four-room prototype look cluttered and has been removed from the active generator and baked scene.

Do not reintroduce skirting/baseboard strips, wall-base grime bands, ceiling grime bands, or door-frame seam grime by default. Future contact-detail work should be a separate art pass with a clear preview before it is applied globally.

The removal validator is `scripts/tools/ValidateSeamGrime.gd`, which now expects no `seam_grime`, `wall_seam_grime`, `ceiling_seam_grime`, or `door_seam_grime` nodes and no active `backrooms_seam_grime` material/texture assets.

## D036: Third-person camera uses free orbit

The current MVP uses a common third-person free-orbit camera. Mouse and touch yaw are not clamped to the player's front 180 degrees and do not auto-recenter when movement starts.

Only vertical pitch is clamped to keep the camera usable around the player. Player movement remains camera-relative, so `WASD` / arrow keys move relative to the current camera view, and backward input remains backpedal behavior handled by `PlayerController.gd`.

Do not reintroduce movement-triggered yaw recentering or front-arc yaw limits unless a later lock-on, aim, or fixed-camera mode explicitly owns that behavior.

## D037: Floor visuals are regular per-room panels

Visual floors should not be built from two large overlapping strip meshes. The previous south/north strip setup caused irregular visible joins and inconsistent floor-texture scale.

The four-room MVP now uses one regular floor visual panel per room with world-coordinate UVs, while movement physics remains on one continuous `Floor_WalkableCollision` body. Visual floor panels must not own collision.

Room_D is still intentionally narrower than Room_A as part of the layout, but its floor visual is its own regular rectangular panel rather than a shifted strip segment.

## D038: Generated visual meshes share one render rule

Script-generated visual meshes that use normal-mapped materials must be built through `scripts/scene/GeneratedMeshRules.gd` or an equivalent shared path that provides matching vertex, normal, UV, and tangent arrays.

This applies to generated portal wall openings, door frames, and floor visual panels. They must also set `MeshInstance3D.material_override` to the expected material instead of relying only on `ArrayMesh.surface_set_material()`. This keeps editor preview, runtime rebuilds, foreground-occlusion material restore, and Mobile renderer lighting behavior aligned with ordinary BoxMesh walls and floors.

Do not add new generated wall, trim, or floor meshes with missing tangents when using `backrooms_wall.tres`, `backrooms_floor.tres`, or `backrooms_door_frame.tres`, because those materials use normal maps and can shade dark/black on generated faces without tangent data.

The automated regression for this rule is `scripts/tools/ValidateGeneratedMeshRules.gd`.

## D039: Backrooms materials use one Mobile lighting rule

Wall, portal wall-opening, floor, ceiling, and door-frame visuals should not be individually brightened or darkened to fix one bad-looking face. The current MVP uses one Mobile-friendly material-lighting rule instead:

- `backrooms_wall.tres`, `backrooms_floor.tres`, `backrooms_door_frame.tres`, and `backrooms_ceiling.tres` use Lambert Wrap diffuse lighting.
- Normal-map strength stays restrained on Mobile: wall normal scale `0.22`, floor normal scale `0.28`, and door-frame normal scale `0.24`.
- Runtime-generated and baked meshes must keep the same material override assignments validated by `ValidateMaterialLightingRules.gd` and `ValidateGeneratedMeshRules.gd`.

Room illumination and actor shadows must still come from real `OmniLight3D` ceiling lights, not fake blob decals, transparent dark planes, or per-wall overlay meshes. Current room light energy is `1.05`, range is `6.0`, attenuation is `0.78`, shadow bias is `0.02`, shadow normal bias is `0.35`, and shadow opacity is `1.0`.

`SceneBuilder.gd` should resolve its own scene root when rebuilding, not depend on `get_tree().current_scene`, so tool-script rebakes and runtime builds keep the same generated floor/wall/light transforms.

## D040: Walls and ceilings use one generated mesh rule

Ordinary wall bodies, `WallJoint_*` filler blocks, portal wall-opening visuals, ceilings, door frames, and floor visuals must not mix ad hoc mesh generation paths when they use the Backrooms material set.

The current rule is:

- Wall and ceiling box visuals are generated through `GeneratedMeshRules.build_box_mesh()` with explicit vertices, normals, UVs, and tangents.
- Portal wall openings, door frames, and floor visuals continue to use `GeneratedMeshRules.build_array_mesh()`.
- Simple primitive collisions remain separate from render meshes for mobile stability.
- Portal wall-opening UVs use the same wall world-size rule as ordinary walls instead of per-opening normalized UVs.
- The only intentional `BoxMesh` use left in the MVP room is the ceiling-light panel visual, which uses its own light-panel material and does not cast shadows.

Do not fix a dark or mismatched wall by hand-brightening one mesh. If a wall looks inconsistent, first check whether it follows the generated mesh rule, material override rule, UV/tangent rule, and real-light shadow rule. The automated regression is `scripts/tools/ValidateGeneratedMeshRules.gd`.

## D041: Runtime cutouts and ambient fill share the same lighting rule

Foreground occlusion cutouts must not make a wall look like a different material while the local player-area hole is active. `materials/foreground_occlusion_cutout.gdshader` therefore uses the same Lambert Wrap diffuse rule as the standard Backrooms materials, and `ForegroundOcclusion.gd` continues to copy the source material albedo, texture, normal map, roughness, and UV scale into the temporary shader material.

The four-room MVP also uses one low-strength `WorldEnvironment` under `LevelRoot/Lights` to provide a consistent warm ambient baseline across wall, floor, ceiling, door-frame, and portal-opening faces. Current ambient tuning is color `Color(1.0, 0.9, 0.66)` with energy `0.18` and zero sky contribution.

This ambient fill is not a fake shadow/decal layer. It must stay a scene lighting resource, and actor shadows must still come from the real ceiling `OmniLight3D` nodes. The automated regressions are `ValidateSceneShadows.gd`, `ValidateMaterialLightingRules.gd`, `ValidateGeneratedMeshRules.gd`, and the active forbidden-pattern scan.

## D042: Room lights use explicit render layers

Superseded by D044 after user feedback on 2026-05-02. This room-specific light-layer split caused the prototype to feel like different walls followed different rules.

Static room visuals must not all stay on the default render layer when multiple room lights are active. Floors, ceilings, outer walls, wall joints, portal wall openings, and door frames use room render-layer masks generated by `SceneBuilder.gd`; shared portal visuals receive both adjacent room layers.

Each `CeilingLight_Room_*` uses a matching `light_cull_mask` and `shadow_caster_mask` plus the actor layer, so room lighting does not flood every other wall/floor surface. Player and monster imported meshes use the actor light layer while still casting real shadows.

Backrooms wall, floor, door-frame, ceiling, and foreground cutout materials should use backface culling in the Mobile renderer. Two-sided wall rendering is avoided because it can make otherwise identical wall meshes preview with inconsistent backside lighting.

## D043: Generated wall tangents use one vertical basis

Generated room visuals that use Backrooms normal-mapped materials must not derive different vertical tangent handedness solely from x-facing versus z-facing UV winding. That makes the same wall texture look like a different material on different wall directions.

`GeneratedMeshRules.gd` now uses a shared vertical-wall tangent basis for generated vertical faces: tangent is `Vector3.DOWN.cross(normal)` and tangent sign is positive. This keeps wall, wall-opening, wall-joint, door-frame, and ceiling side faces aligned for Mobile normal-map lighting.

Floor visuals still use their world-coordinate UVs and explicit top-face triangle order from `SceneBuilder.gd`. If a floor appears black, check face winding and material culling before changing light energy or adding overlays.

The automated regression is `scripts/tools/ValidateGeneratedMeshRules.gd`, with `scripts/tools/DiagnoseWallVisuals.gd` used for tangent/normal diagnostics.

## D044: Walls are generated by type, not by room

Rooms define space, area metadata, portal connectivity, and marker placement. They must not make the same wall component render differently just because it belongs to Room_A, Room_B, Room_C, or Room_D.

`SceneBuilder.gd` now uses one wall-piece list and one wall-piece creation entry:

- `type = "solid"` creates solid wall segments and wall-joint filler blocks.
- `type = "opening"` creates wall bodies with doorway openings.
- Door frames remain a separate trim component, but they use the same static visual layer rule as wall bodies.

All static room visuals use `STATIC_GEOMETRY_LAYER`: floors, ceilings, solid walls, wall openings, door frames, and ceiling light panels. Actor meshes stay on `ACTOR_LIGHT_LAYER`. All four room lights use `STATIC_GEOMETRY_LAYER | ACTOR_LIGHT_LAYER`, so visual differences should come from actual geometry/light/shadow/cutout state, not from room-specific wall rendering masks.

Do not reintroduce per-room wall visual layers to fix one dark wall. If a wall looks wrong, inspect component type generation, material override, UV/tangent data, real light/shadow direction, and foreground cutout state first. The current regression is `scripts/tools/ValidateSceneShadows.gd`.

## D045: Four-room shell is generated as geometry plus areas

The MVP room shell must not use `LevelRoot/Rooms` as a mixed container for floors, walls, ceilings, door frames, and room metadata. The saved scene and runtime rebuild now separate these concerns:

- `LevelRoot/Geometry` owns physical and visual construction pieces: continuous floor collision, per-room floor panels, solid walls, wall joints, portal wall openings, U-shaped door frames, ceilings, and ceiling-light panels.
- `LevelRoot/Areas` owns room metadata nodes only: room ID, area ID, bounds, and portal IDs.
- `LevelRoot/Portals`, `LevelRoot/Markers`, and `LevelRoot/Lights` remain separate system roots.

`SceneBuilder.gd` deletes any legacy `LevelRoot/Rooms` node during build before recreating the room shell. `BakeFourRoomScene.gd` saves the rebuilt roots, and `MonsterController.gd` reads room area metadata from `LevelRoot/Areas`.

Do not fix future layout issues by restoring a mixed `Rooms` container or by hand-editing old room pieces. Rebuild by component type under `Geometry`, and keep room nodes as metadata under `Areas`. The regression for this rule is `scripts/tools/ValidateCleanRebuildScene.gd`.

## D046: Scene objects use canonical type generators

Scene construction pieces must be generated by component type, not by room name, direction, or one-off editor fixes. Future scene work should reuse one canonical generator per type, then adjust only parameters and placement data.

Current canonical rules:

- Solid walls, wall joints, and ceilings use the shared generated box rule in `GeneratedMeshRules.build_box_mesh()`.
- Doorway wall bodies use one canonical local U-wall mesh in `WallOpeningBody.gd`; x/z orientation is handled by node rotation, not by separate x/z mesh branches.
- Door frames use one canonical local U-frame mesh in `DoorFrameVisual.gd`; x/z orientation is handled by node rotation, not non-uniform scale.
- Doorway wall bodies and door frames must keep `scale = Vector3.ONE`.
- Rooms describe space and connectivity only. They must not change how the same wall, opening, frame, floor, ceiling, light, prop, or actor component is generated.

The accepted production standard is: add new scene object types through one reusable generator/module path, place instances through specs/data, and reject direction-specific mesh logic unless the component type itself genuinely requires a different physical shape. `ValidateCleanRebuildScene.gd` now checks canonical wall-opening and door-frame scale, yaw, dimensions, and uniform portal placement.

## D047: Vertical wall UVs increase upward

Generated vertical room surfaces must map their texture V coordinate in the same direction as local height: higher `y` means higher UV `v`. This keeps wall wallpaper, stains, normal detail, doorway wall openings, door frames, wall joints, and ceiling side faces from appearing globally upside down.

Current rule:

- `GeneratedMeshRules.build_box_mesh()` maps box visual V as positive height or depth for the selected face axes.
- `WallOpeningBody.gd` maps U from local span and V from positive local `y`.
- `DoorFrameVisual.gd` maps U across the frame width and V from positive local `y`.
- `ValidateGeneratedMeshRules.gd` rejects vertical generated triangles whose UV `v` does not increase with height.

Do not fix upside-down wallpaper by flipping individual wall instances or texture resources. Fix the shared generated UV rule for the component type and rebake the scene.

## D048: Wall visuals must not render coplanar floor/ceiling caps

The four-room shell should avoid visible z-fighting by construction, not by hiding one problem mesh or hand-moving a single wall. Solid wall segments and wall-joint filler blocks now meet at edges instead of overlapping through each other: wall span length is `ROOM_SIZE - WALL_JOINT_SIZE`, currently `5.64m`.

Ordinary wall and wall-joint visual meshes must render vertical faces only. Their collision boxes can still be full boxes, but the rendered bottom/top cap faces are omitted so they do not fight the floor top plane or ceiling underside. Wall and doorway visuals extend beyond floor/ceiling contact to hide edge cracks without adding coplanar horizontal faces. The current ceiling-edge overlap is `0.08m`, raised from the earlier `0.025m` after a visible ceiling-wall light leak was found in the editor.

Doorway wall bodies and door-frame visuals must build explicit side-face UVs. Narrow reveal/trim faces should map by depth and height/span, not reuse the front wall UV blindly, because that collapses the texture into one-pixel vertical stripes.

If future room pieces show comb-like floor edges, striping near wall corners, black wall-floor seams, or flashing/stretched door side faces, first check for coplanar render faces, overlapping wall/joint spans, and side-face UVs. Do not solve that class of bug by changing texture color, light energy, or per-instance material settings.

The regressions are `ValidateGeneratedMeshRules.gd` and `ValidateCleanRebuildScene.gd`.

## D049: Visual polish uses experiment copies before base merge

New visual polish must not be applied directly to the accepted base scene/materials first. The workflow is:

- Copy the current accepted baseline scene/material/texture/script state into an experiment variant.
- Apply the new visual idea only in the experiment variant.
- Capture screenshots under `artifacts/screenshots/` and run the smallest useful validation scripts.
- Keep the experiment only if it improves the look without breaking geometry, UVs, collision, shadows, or mobile readability.
- Merge the accepted values back into the base generator/material resources only after visual acceptance.

This is especially important for subtle Backrooms contact detail. Wall bases, wall corners, door-frame edges, and ceiling turns may use light ambient-occlusion style contact shadows or gradual darkening, but they must not be black lines, large overlay strips, transparent scene-covering planes, or per-instance hacks.

Future AO/contact-shadow work should be tested as a copied scene or copied material set first. The base `FourRoomMVP.tscn`, `SceneBuilder.gd`, and shared material resources should remain the stable playable reference until the experiment passes visual review.

## D050: Global grime is separate from contact AO

AO/contact darkening and grime are separate systems.

- AO/contact darkening handles seams, volume, floor-wall contact, ceiling-wall contact, corners, and door-frame edge depth.
- Grime handles only subtle aging and non-repetition: light dust, yellowing, pale gray-brown dirt, and mild mold-gray traces.

The first grime implementation is experiment-only:

- `scripts/visual/GrimeOverlayBuilder.gd` is the reusable placement entry.
- `scripts/tools/BakeGrimeExperiment.gd` layers grime on top of `FourRoomMVP_contact_ao_experiment.tscn` and writes `FourRoomMVP_grime_experiment.tscn`.
- `materials/textures/grime/` contains 9 true-alpha PNG variants: 3 `CeilingEdge_Grime`, 3 `Baseboard_Dirt`, and 3 `Corner_Grime`.

Grime overlays are allowed only when they stay small, structural, non-colliding, and validated. They must not become whole-wall stains, black lines, fake visibility masks, floor-covering transparent sheets, blood, dramatic damage, or per-room hand fixes. Room-specific variation must come from deterministic `room_seed`-style random choices of variant, opacity, strength, length, and size, not from `if Room_A/Room_B/...` logic.

Do not merge grime into the accepted base scene until the experiment screenshot is visually accepted. The current regression is `scripts/tools/ValidateGrimeExperiment.gd`.

## D051: Image2 grime uses texture alpha, not double alpha multiplication

The accepted grime experiment direction is now image-generated, natural, structural grime. The first procedural grime set was archived and replaced by an image2-derived atlas extraction workflow.

Current rule:

- The image2 source atlas is stored under `materials/textures/grime/source/`.
- Old generated grime PNGs are archived under `materials/textures/grime/archive/` before replacement.
- The 9 project grime PNGs remain true-alpha PNGs under `materials/textures/grime/`.
- The visible grime strength is controlled by the texture alpha itself, with max alpha kept near 50%.
- `GrimeOverlayBuilder.gd` must not multiply that down with another low material alpha. Overlay material alpha stays `1.0`; the PNG alpha carries the fade.

Do not reintroduce the previous double attenuation pattern (`texture alpha * low material alpha`) because it makes the grime disappear in-game and makes review misleading.

## D052: Procedural maps must be graph first, module built, then scene validated

Large Backrooms maps must not be hand-built by placing arbitrary walls in a scene. The production order is:

- `ModuleRegistry` defines module metadata and permissions.
- `MapGraphGenerator` creates only an abstract graph and footprints.
- `MapValidator` checks graph counts, reachability, area loops, connector compatibility, no overlap, and no door-to-wall cases.
- `ProcMazeSceneBuilder` instantiates modules and shared generated construction pieces only after the graph passes.
- `SceneValidator` checks scene counts, material preservation, wall height, identity scale, doors, overlaps, lights, FPS/draw-call metrics, and errors.
- `DebugView` visualizes nodes, connectors, main path, branches, loops, dead ends, special rooms, and validation failures.

All future room and corridor additions should enter through typed module metadata, not per-room special cases. Walls, floors, ceilings, `WallOpeningBody`, and `DoorFrameVisual` must use the same shared generation rules and must pass material through script parameters so rebuilds do not fall back to defaults.

Allowed transforms for generated module placement are translation plus 0/90/180/270 rotation. Negative scale, mirrored scale, non-uniform scale, and stretching wall bodies are forbidden. Doorways must be connector-to-connector, never door-to-wall.

`scenes/tests/Test_ProcMazeMap.tscn` is the current fixed-layout procedural map test scene. It is deliberately separate from `scenes/mvp/FourRoomMVP.tscn`; the four-room baseline remains untouched unless the user explicitly accepts a merge.

## D053: Procedural test maps reuse the gameplay modules

Playable procedural test scenes must reuse the same gameplay modules that were proven in the four-room MVP instead of copying movement or camera logic into the map generator.

Current rule:

- `TestProcMazeMap.gd` may create or keep `PlayerRoot/Player`, `CameraRig/Camera3D`, `Systems/LightingController`, and `Systems/ForegroundOcclusion`.
- Player spawn comes from generated map metadata, specifically the marker whose `marker_type` is `Entrance`, not from a hard-coded room name.
- The third-person camera continues to use `CameraController.gd`; player movement continues to use `PlayerController.gd`.
- The overview camera may remain for editor inspection, but the gameplay camera must be current when the scene runs.
- Baked test scenes should keep `PlayerModule.tscn` as an external scene instance. Do not expand GLB/model internals into generated map scenes unless there is a specific authored override to save.

The regression for this rule is `scripts/tools/ValidateProcMazePlayable.gd`.

## D054: Procedural maps get a separate no-ceiling full-map preview

Generated map preview scenes are for layout inspection, not for close third-person gameplay.

Current rule:

- Keep playable generated scenes separate from preview generated scenes.
- `scenes/tests/Test_ProcMazeMap.tscn` remains the playable test map with `PlayerRoot/Player`, `CameraRig/Camera3D`, and gameplay systems.
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn` is the no-ceiling full-map preview.
- The preview scene must be built by the same graph/module/scene-builder pipeline as the playable scene, with `preview_without_ceiling = true` and `preview_full_map_camera = true`.
- The preview scene uses the root `Camera3D` as a pulled-back orthogonal god-view camera. It should not default to the gameplay camera or player-follow camera.
- The preview scene omits ceiling meshes/collisions but keeps floors, walls, openings, door frames, debug labels, markers, and lighting references visible enough for layout inspection.

Do not satisfy a future "preview scene" request by only creating a playable near-camera scene. The regression is `scripts/tools/ValidateProcMazeNoCeilingPreview.gd`.
## D039: Procedural maze modules are type-generated

Large procedural maps must not be hand-built from arbitrary wall edits or from one-off room-specific geometry. They use a `ModuleRegistry` entry per reusable module type, graph nodes with metadata, and one shared scene-building path for floors, walls, ceilings, openings, door frames, lights, and debug markers.

Rooms are only spatial modules connected by connectors. Wall bodies, wall openings, door frames, long corridors, L-turns, hubs, and internally partitioned large rooms are generated by type rules. Later layout work should adjust module metadata, occupied cells, connector positions, and placement data rather than creating per-room exceptions.

Non-rectangular modules must carry occupied-cell metadata. Validators and builders must use those occupied cells instead of only the bounding rectangle, otherwise L-shaped spaces become fake rectangles and can recreate the old door/wall/UV/overlap bugs.

For 30-45 node Backrooms test maps, plain rectangular rooms must stay below 40 percent and every generated map should include real long corridors, L-shaped paths, recognizable rooms, hubs, internal large-room structures, local loops, and dead ends. If these quotas fail, the map should be rejected instead of saved.

## D057: Macro loops must read as experiential route splits

Large procedural maps must not pass macro-loop validation only because a cycle exists in top-down graph data. The player route should clearly present a split point, two different route experiences, and a later merge point.

Current fixed-layout rule:

- The primary macro loop has an explicit split node A and merge node B.
- Split A should have one inbound connection and two outgoing route choices.
- Merge B should have two incoming macro-route connections and one onward connection.
- Route A and route B must not be cross-wired by local internal edges between the split and merge, because that turns the macro loop into patch-like local connectivity.
- The corridor-biased route should include enough long/narrow/L/offset corridor pressure to feel constrained and directional.
- The room-biased route should include enough expanded spaces, with at least two compound large/hub spaces, to feel like a different spatial language.
- Small loops are still allowed, but they must not obscure the main split/merge structure.

The fixed test map now uses `N05` as split A and `N12` as merge B. `N05` and `N12` use `hub_room_partitioned` so both decision points are recognizable in the scene, not only in the debug graph.

The regression is `scripts/proc_maze/MapValidator.gd` macro-loop validation plus `scripts/tools/ValidateTestProcMazeMap.gd`.

## D058: Spatial identity beats connector patching

Procedural maps should not improve complexity by adding chains of small square rooms or short connector chunks. When the layout needs connection, prefer one of these in order:

- a true long corridor if the player should feel constrained and directional;
- an L-turn or offset corridor if the route should bend and hide the next space;
- a wide or L-shaped room if the connection should feel like a room;
- a compound large room if several small connector pieces can be merged into one memorable space.

Current validation treats `normal_room` as an ordinary rectangular room for monotony and ratio checks. Ordinary rectangles must stay below 35 percent of the map. Declared main/macro/small-loop routes must fail if they contain 3 ordinary rectangular rooms in a row or 3 short connector spaces in a row.

Each area must contain at least one anchor room: `l_room`, `recognizable_room`, `large_internal`, `hub`, or `special`. A corridor shape alone does not satisfy the anchor-room requirement.

L-shaped room modules must get their turn and sight break from occupied-cell L footprints and their generated boundary walls. Do not add freestanding internal L-room baffles; they create non-passable decorative slits. Compound large-room split modules should offset internal doorway gaps so internal doors do not line up as straight external-door-to-external-door sightlines.

The regression is `scripts/proc_maze/MapValidator.gd` plus `scripts/proc_maze/SceneValidator.gd`.

## D059: No non-passable decorative slits

Generated procedural spaces must not contain narrow gaps that look like passages but cannot fit the player. Internal partitions must either connect cleanly as full-height walls or leave a doorway-sized passage.

Current rule:

- `room_l_shape` modules use occupied-cell L footprints only; no extra freestanding internal baffle walls.
- `SceneValidator` fails if an L-shaped room owns any `proc_internal_wall`.
- Internal split and offset-door large-room passages use `INTERNAL_PASSAGE_WIDTH = 1.60`, wider than the normal exterior door opening.
- Ambient light baseline is now `WORLD_AMBIENT_ENERGY = 0.07`, so areas without direct ceiling-light contribution read darker.

The regression is `scripts/proc_maze/SceneValidator.gd`, `scripts/tools/ValidateTestProcMazeMap.gd`, `scripts/tools/ValidateProcMazePlayable.gd`, and `scripts/tools/ValidateSceneShadows.gd`.

## D060: Reference-style surfaces experiment is reverted

This reference-style pass was tested and then reverted at the user's request on 2026-05-04. It is retained here only as historical context, not as the current accepted visual baseline.

The reverted experiment followed the user's reference images: yellow-green aged vertical wallpaper, gray-beige baseboard/door-frame trim, speckled acoustic ceiling panels, and warm fluorescent diffuser panels.

This style must stay in shared material resources and shared generator rules:

- wall, floor, door-frame/trim, ceiling, and light diffuser textures were generated by `scripts/tools/generate_reference_style_textures.py`, which was removed during the revert;
- `backrooms_wall.tres`, `backrooms_door_frame.tres`, `backrooms_ceiling.tres`, and `backrooms_ceiling_light.tres` are the shared material entry points;
- baseboards are generated by `SceneBuilder.gd` and `ProcMazeSceneBuilder.gd`, not hand-placed in individual rooms;
- proc-maze baseboards are allowed on boundary walls, opening-wall segments, and internal partition walls, but they must remain trim visuals and must not become gameplay collision or wall-count hacks;
- viewport screenshots should be captured without `--headless` and with a bounded `--quit-after`, because headless capture can use Godot's dummy texture path.

Do not reintroduce debug UV-arrow textures, one-off decorative planes, transparent grime strips, or per-room material exceptions as the accepted style path.

## D061: Current visual baseline is the pre-reference-style look

After the 2026-05-04 revert, the accepted current visual baseline is back to the previous material set:

- wall and door-frame PNGs restored from `E:\godot閸氬骸顓籣backups\godot閸氬骸顓籣backup_20260501_155923`;
- floor PNGs regenerated by `scripts/tools/RegenerateUniformFloorTextures.gd`;
- ceiling material is a flat opaque surface with no ceiling albedo/normal texture;
- ceiling-light material is the previous warm flat emissive material with no diffuser texture;
- room ceiling-light panels use `Vector3(1.2, 0.08, 0.7)`;
- no generated `Baseboard` / `Trim` nodes are part of the accepted current scene or proc-maze builders.
- the reverted reference-style generator script and unused ceiling/diffuser source textures are not part of the current baseline.

Do not reapply the reference-style generated textures, generated baseboards, or long diffuser panels unless the user explicitly asks to try that direction again.

## D062: Root launchers stay minimal, texture edits go through the shared tool

The root folder should not accumulate old one-off startup shortcuts. Current accepted root launchers are:

- `run_proc_maze_test.bat`
- `run_proc_maze_no_ceiling_preview.bat`
- `run_mvp_room.bat`
- `run_resource_showcase.bat`
- `start_texture_tool.bat`

Obsolete root launchers for galleries, old previews, latest-demo shortcuts, visual experiments, or Codex starter helpers were removed on 2026-05-04.

`run_mvp_room.bat` is the explicit MVP mechanism verification-room launcher. Do not restore `run_latest_demo.bat` as the active helper name; it is too ambiguous and was part of the old launcher clutter.

Texture iteration should use `start_texture_tool.bat` when the user wants direct replacement and UV tuning. The tool edits shared material `.tres` files and shared texture files directly:

- wall: `materials/backrooms_wall.tres`
- floor: `materials/backrooms_floor.tres`
- door frame: `materials/backrooms_door_frame.tres`
- ceiling: `materials/backrooms_ceiling.tres`
- light panel: `materials/backrooms_ceiling_light.tres`

Overwritten texture images must be backed up to `materials/textures/_texture_tool_backups/`. Tool-launched servers or validation processes must be closed after use; do not leave extra Godot/Python test processes running.

The texture tool should include an immediate model-context preview, not only flat texture thumbnails. The preview does not replace Godot scene validation, but it should let the user see the currently selected material on a simple room-corner model and update live when UV scale, UV offset, color, or emission inputs change.

The preview should be a real browser WebGL 3D sample, not a CSS-only fake perspective. It may stay lightweight and local, but it should support drag rotation, wheel zoom, live UV changes, and selected-material application to wall/floor/ceiling/door/light sample surfaces.

The tool may open Windows Explorer for source convenience, but only through validated project-contained material and texture paths. Do not add arbitrary path-opening endpoints.
