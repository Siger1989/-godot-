# Handoff 2026-05-05: Imported Monsters And FourRoomMVP Test Room

## Superseding Update 2026-05-06: MVP Direct Editable Monster Source

The editable monster-size source has moved into the MVP room itself:

- `FourRoomMVP.tscn` now owns a direct editable `MonsterRoot`; it is no longer an instance of `scenes/modules/MonsterSizeSource.tscn`.
- The MVP room keeps exactly one source node per monster type: `Monster`, `Monster_Red_KeyBearer_MVP`, and `NightmareCreature_A_MVP`.
- `Monster_Normal_B` and `NightmareCreature_B_MVP` were removed from the MVP room; generated aliases still use the single saved source nodes (`normal_b -> Monster`, `nightmare_b -> NightmareCreature_A_MVP`).
- `scripts/monster/MonsterSizeSource.gd` now reads saved transforms from `res://scenes/mvp/FourRoomMVP.tscn` for generated and resource-showcase scaling.
- `open_monster_size_source.bat` and `open_mvp_monster_room.bat` open `res://scenes/mvp/FourRoomMVP.tscn` for size editing.
- Focused validation and the Android export passed after this change; the current APK is `builds/android/backrooms_four_room_mvp_debug.apk`.

## Superseding Update 2026-05-06: Red Hunter, Cabinet Key, Keyed Exit, Dual Nightmare

The compact FourRoomMVP mechanics baseline has been updated again:

- Superseded by the direct-MVP-source update above: the MVP size room now keeps one source per monster type instead of five active source monsters.
- The red hunter no longer carries or drops the escape key. It attacks any living creature it can see and faces its prey while attacking.
- The escape key is now `LevelRoot/Props/CabinetTop_EscapeKey`, an instance of `scenes/modules/EscapeKeyPickup.tscn`, placed on the Room_B cabinet and collected with the existing `E` pickup path.
- Room_C has a north outer-wall exit: `SceneBuilder.gd` generates `WallOpening_Exit_C_North` and `DoorFrame_Exit_C_North`, and the scene places `Door_Exit_C_North_Keyed` there.
- `DoorComponent.gd` supports `requires_escape_key`; without the key, the exit door stays locked.
- Both Nightmare monsters are hearing-only and emit periodic sonar calls using `assets/audio/nightmare_sonar_call.wav`.
- `project.godot` currently points to `res://scenes/mvp/FourRoomMVP.tscn` so the APK opens the compact MVP room.
- Focused validation: `ValidateMonsterSizeSource.gd`, `ValidateFourRoomMVPMonsterSet.gd`, `ValidateNightmareHearingAI.gd`, `ValidateCleanRebuildScene.gd`, `ValidateGeneratedMeshRules.gd`, and forced `ValidateMobileControls.gd`.

## Superseding Update 2026-05-05: Creature Removed, Nightmare Active

This handoff's original imported-monster baseline has been superseded:

- `CreatureZombie_A` was deleted from active project assets and removed from `MonsterSizeSource.tscn`, the resource showcase, rebuild scripts, and validators.
- `NightmareCreature_A` is now active through `assets/backrooms/monsters/NightmareCreature_Monster.tscn`.
- `MonsterSizeSource.tscn/NightmareCreature_A_MVP` is the user-editable source for Nightmare size and transform.
- The active Nightmare visual has been lowered inside `NightmareCreature_Monster.tscn` so the source-scene visible bounds are floor-aligned.
- Nightmare uses `monster_role = "nightmare"` and is hearing-only: it does not use player vision, hears player movement, chases current footsteps, investigates the last heard position after silence, and attacks at close range.
- The current compact MVP monster set is now `Monster`, `Monster_Normal_B`, `Monster_Red_KeyBearer_MVP`, and `NightmareCreature_A_MVP`.
- Current focused validation includes `scripts/tools/ValidateNightmareHearingAI.gd`.

## Current State

The project is still the Backrooms Godot 4.6.2 Mobile-renderer prototype at:

`E:\godot后室`

This folder is not a git repository. The next session should still run:

```powershell
git status --short
git diff --stat
```

Both commands are expected to fail with "not a git repository"; record that in `CURRENT_STATE.md` when starting work.

## Read First

Do not rely on chat history. In the next session, read these first:

1. `docs/CODEX_FRESH_SESSION_PROMPT.md`
2. `README.md`
3. `CURRENT_STATE.md`
4. `docs/AGENT_START_HERE.md`
5. `docs/PROGRESS.md`
6. `docs/DECISIONS.md`
7. `docs/FORBIDDEN_PATTERNS.md`
8. `docs/ACCEPTANCE_CHECKLIST.md`
9. `docs/HANDOFF_20260504_PROC_MAZE.md`
10. `docs/HANDOFF_20260505_TEXTURE_TOOL_LAYER_UV.md`
11. `docs/HANDOFF_20260505_IMPORTED_MONSTERS_AND_MVP_TEST.md`

## Latest Completed Work

### Imported Monster Resources

The user placed two monster GLBs under `E:\godot后室\新增资源`. They have been copied into the Godot resource library:

- `assets/backrooms/monsters/CreatureZombie_A.glb`
- `assets/backrooms/monsters/NightmareCreature_A.glb`

Godot imported both and extracted embedded textures beside the GLBs.

Wrapper scenes now exist:

- `assets/backrooms/monsters/CreatureZombie_A.tscn`
- `assets/backrooms/monsters/NightmareCreature_A.tscn`

Both are visible in the unified resource showcase:

- `scenes/tests/Test_NaturalPropsShowcase.tscn`
- launcher: `run_resource_showcase.bat`
- screenshot evidence: `artifacts/screenshots/resource_showcase_imported_monsters_20260505.png`

The showcase now validates `22` resources.

### Model Analysis

`CreatureZombie_A`:

- Source title: `Creature_ Zombie`
- Author: `Kapi777`
- License: `CC-BY-NC-4.0`
- Approx triangles: `51716`
- Meshes/materials/images: `5` meshes, `5` materials, `10` embedded texture images
- Animations: `21`
- Display height metadata: about `1.69m`
- Current status: showcase/prototype only. It is high-poly for mobile and non-commercial licensed, so do not treat it as production-safe gameplay content without license and optimization work.

`NightmareCreature_A`:

- Source title: `Nightmare Creature 1#`
- Author: `Idk`
- License: `CC-BY-4.0`
- Approx triangles: `6718`
- Meshes/materials/images: `1` mesh, `1` material, `3` embedded texture images
- Animations: `22`
- Display height metadata: about `1.29m`
- Current status: better gameplay candidate, but still needs collision, animation mapping, attribution handling, and AI hookup before gameplay use.

Important: neither imported monster is wired to `MonsterController.gd` yet. Their rigs and animation names differ from the existing monster module.

### FourRoomMVP Monster Test Room

The compact MVP room is now the current monster-mechanic test room:

- scene: `scenes/mvp/FourRoomMVP.tscn`
- launcher: `run_mvp_room.bat`

`MonsterRoot` contains:

- `Monster` - original normal monster, kept for compatibility with bootstrap and old validators.
- `Monster_Normal_B` - second normal monster.
- `Monster_Red_KeyBearer_MVP` - red key-bearer monster.

The scene/player are marked:

- `mvp_player_immortal = true`

Red monster attacks against that player are nonlethal test hits only.

The reusable current monster module is:

- `scenes/modules/MonsterModule.tscn`

Its BoxShape collision was enlarged to cover the currently accepted user-tuned monster visual scale:

- `Vector3(0.953989, 0.387199, 0.688722)`

## Current Pause / Do Not Do

The user explicitly paused large-scene layout work:

- Do not bake or alter `scenes/tests/Test_ProcMazeMap.tscn` placement/layout unless the user asks.
- Do not add extra proc-maze lockers, move prop density, change exit-door placement, or export a layout-dependent APK during this pause.
- Control/resource work can continue if requested.

## Important Decisions

Latest decision entries:

- `D088`: imported third-party monsters are showcase-only until mapped and cleared.
- `D087`: `FourRoomMVP` is the compact monster mechanic test room.
- `D086`: proc-maze placement is paused while layout may change.
- `D085`: new resources go into the unified showcase scene.

## Main Files Changed Recently

Imported monster resource pass:

- `assets/backrooms/monsters/CreatureZombie_A.glb`
- `assets/backrooms/monsters/CreatureZombie_A.tscn`
- `assets/backrooms/monsters/CreatureZombie_A_*`
- `assets/backrooms/monsters/NightmareCreature_A.glb`
- `assets/backrooms/monsters/NightmareCreature_A.tscn`
- `assets/backrooms/monsters/NightmareCreature_A_*`
- `scenes/tests/Test_NaturalPropsShowcase.tscn`
- `scripts/tools/BuildNaturalPropScenes.gd`
- `scripts/tools/ValidateResourceShowcase.gd`
- `scripts/tools/ValidateImportedMonsterAssets.gd`
- `scripts/tools/CaptureNaturalPropScene.gd`

MVP monster test pass:

- `scenes/mvp/FourRoomMVP.tscn`
- `scenes/modules/MonsterModule.tscn`
- `scripts/monster/MonsterController.gd`
- `scripts/tools/ValidateFourRoomMVPMonsterSet.gd`
- `scripts/tools/ValidateMonsterAI.gd`
- `scripts/tools/ValidateMonsterCollisionLimit.gd`

State/docs:

- `CURRENT_STATE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`

## Validation Commands

Godot executable:

```powershell
$godot='C:\Users\sigeryang\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe'
```

Useful validations:

```powershell
& $godot --headless --path . --quit --log-file logs\next_parse.log
& $godot --headless --path . --script res://scripts/tools/ValidateImportedMonsterAssets.gd --log-file logs\next_validate_imported_monsters.log
& $godot --headless --path . --script res://scripts/tools/ValidateResourceShowcase.gd --log-file logs\next_validate_resource_showcase.log
& $godot --headless --path . --script res://scripts/tools/ValidateFourRoomMVPMonsterSet.gd --log-file logs\next_validate_mvp_monsters.log
& $godot --headless --path . --script res://scripts/tools/ValidateMonsterAI.gd --log-file logs\next_validate_monster_ai.log
& $godot --headless --path . --script res://scripts/tools/ValidateMonsterSavedScale.gd --log-file logs\next_validate_monster_scale.log
& $godot --headless --path . --script res://scripts/tools/ValidateMonsterCollisionLimit.gd --log-file logs\next_validate_monster_collision.log
```

Showcase capture:

```powershell
$env:CAPTURE_SCENE_PATH='res://scenes/tests/Test_NaturalPropsShowcase.tscn'
$env:CAPTURE_MODE='showcase'
$env:CAPTURE_OUTPUT_PATH='res://artifacts/screenshots/resource_showcase_next.png'
& $godot --path . --resolution 1600x900 --script res://scripts/tools/CaptureNaturalPropScene.gd --log-file logs\next_capture_resource_showcase.log
```

## Latest Passing Logs

- `logs\import_new_monster_assets_import_20260505.log`
- `logs\import_new_monster_assets_parse_final_20260505.log`
- `logs\import_new_monster_assets_validate_final_20260505.log`
- `logs\import_new_monster_resource_showcase_validate_final_20260505.log`
- `logs\import_new_monster_resource_showcase_capture_20260505.log`
- `logs\mvp_monster_set_parse_final_20260505.log`
- `logs\mvp_monster_set_validate_final_20260505.log`
- `logs\mvp_monster_set_ai_after_collision_20260505.log`
- `logs\mvp_monster_set_saved_scale_after_collision_20260505.log`
- `logs\mvp_monster_set_collision_scaled_validator_20260505.log`
- `logs\mvp_monster_set_mobile_controls_20260505.log`

## Known Warnings

- Godot may report `Detected another project.godot at res://godot后室新`; this was already known.
- Importing `CreatureZombie_A.glb` reported a duplicate animation-name warning for `Creeping_Eat`; validation still passed.
- Godot headless parse may report leaked ObjectDB/resource messages at exit. Treat those as non-blocking unless a validator fails.

## Process Cleanup Rule

Before ending a session, check for texture tool server processes:

```powershell
$procs = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'python.exe' -and $_.CommandLine -like '*texture_tool_server.py*' }
foreach ($proc in $procs) { Stop-Process -Id $proc.ProcessId -Force }
```

At the end of the latest session, no `texture_tool_server.py` process remained.

## Recommended Next Task Options

1. Inspect resources with `run_resource_showcase.bat`.
2. If selecting a new gameplay monster, prefer `NightmareCreature_A` first because it is much lower poly and has a less restrictive license.
3. For gameplay integration, do a separate pass:
   - choose which monster;
   - map idle/walk/run/attack/death animation names;
   - disable unwanted root motion;
   - add simple collision;
   - adapt or extend `MonsterController.gd`;
   - validate in `FourRoomMVP` before touching proc-maze.
4. Keep proc-maze layout paused unless the user explicitly gives a new layout direction.

## Suggested New Session Prompt

```text
继续 E:\godot后室 项目。

不要依赖聊天历史。请先读取：
docs/CODEX_FRESH_SESSION_PROMPT.md

然后按顺序读取 README.md、CURRENT_STATE.md、docs/AGENT_START_HERE.md、docs/PROGRESS.md、docs/DECISIONS.md、docs/FORBIDDEN_PATTERNS.md、docs/ACCEPTANCE_CHECKLIST.md、docs/HANDOFF_20260504_PROC_MAZE.md、docs/HANDOFF_20260505_TEXTURE_TOOL_LAYER_UV.md、docs/HANDOFF_20260505_IMPORTED_MONSTERS_AND_MVP_TEST.md。

先运行：
git status --short
git diff --stat

注意：当前目录不是 git 仓库，这两个命令失败是预期结果，但仍要记录。

当前大场景布局工作暂停，不要改 proc-maze 布局或重新烘焙大地图，除非我明确要求。

当前最新成果：
- FourRoomMVP 是怪物机制测试房，里面有两只普通怪和一只红色钥匙怪，玩家在 MVP 房间内不死亡。
- 新增资源里的两个怪物已经进入 assets/backrooms/monsters/ 和资源展示场景。
- CreatureZombie_A 高面数且 CC-BY-NC，只作展示/原型参考。
- NightmareCreature_A 更适合作为后续玩法候选，但还没接 AI。

从这里继续。
```
