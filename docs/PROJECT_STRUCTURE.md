# Project Structure

## Runtime Entry

- `project.godot`
  - Main scene: `res://scenes/ui/LoginMenu.tscn`
  - Autoloads:
    - `MCPRuntime`
    - `GDSyncBootstrap`
    - `GameSession`
- `run_game.bat`
  - Formal player-facing launcher.
  - Uses the project main scene and does not override with a debug scene.

## Gameplay Scenes

- `scenes/ui/LoginMenu.tscn`
  - Startup screen.
  - Selects single-player, create online room, or join online room.
- `scenes/tests/Test_ProcMazeMap.tscn`
  - Formal playable large proc-maze scene.
  - Also used by direct debug launcher.
- `scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn`
  - Layout preview/debug scene.
- `scenes/mvp/FourRoomMVP.tscn`
  - Smaller mechanics verification room.

## Main Scripts

- `scripts/proc_maze/`
  - Map generation, scene building, debug view, scene validation, and formal proc-maze runtime setup.
- `scripts/gameplay/`
  - Session state, GD-Sync bootstrap, online bridge, keys, red alarm, lockers/hideables, and pickups.
- `scripts/player/`
  - Player controller, health/game-over, crouch, sprint, mobile controls, interaction.
- `scripts/monster/`
  - Monster AI, size source, animation/source metadata.
- `scripts/lighting/`
  - Runtime lighting controller and tuning UI.
- `scripts/scene/`
  - Doors, portals, room module markers, hideable components, wall opening helpers.
- `scripts/tools/`
  - Headless validation, bake/capture tools, showcase controllers, and debug utilities.

## Root Launchers

- `run_game.bat`: formal game with login and online room flow.
- `run_proc_maze_test.bat`: direct large-maze debug run.
- `run_proc_maze_no_ceiling_preview.bat`: map layout preview.
- `run_monster_showcase.bat`: monster showcase/debug run.
- `run_resource_showcase.bat`: resource showcase.
- `run_mvp_room.bat`: compact MVP mechanics test room.
- `start_texture_tool.bat`: texture/material editing tool.
- `_godot_env.bat`: shared Godot executable resolver used by launchers.

## Online Mode

- `scripts/gameplay/GDSyncBootstrap.gd`
  - Reads GD-Sync keys from ProjectSettings, environment variables, `res://local_gdsync_keys.cfg`, or `user://gdsync_keys.cfg`.
  - Lazily creates `/root/GDSync` only when online play is requested.
- `scripts/gameplay/GameSession.gd`
  - Stores player name, room code, mode, online status.
  - Creates or joins a GD-Sync lobby before entering the maze.
- `scripts/gameplay/OnlineGameBridge.gd`
  - Runs inside `Test_ProcMazeMap`.
  - First-pass online bridge for basic remote-player transform display.

Secret policy:

- `local_gdsync_keys.cfg` is intentionally ignored by Git.
- Use `local_gdsync_keys.example.cfg` as the local file shape.
- Do not commit the GD-Sync private key into `project.godot`, scripts, docs, or launcher files.

## Validation

Current launcher/online checks:

- `scripts/tools/ValidateProjectLaunchers.gd`
- `scripts/tools/ValidateLoginMenu.gd`
- `scripts/tools/ValidateGDSyncIntegration.gd`

Core gameplay checks to keep running after related edits:

- `scripts/tools/ValidateProcMazePlayable.gd`
- `scripts/tools/ValidateTestProcMazeMap.gd`
- `scripts/tools/ValidateMonsterAI.gd`
- `scripts/tools/ValidateNightmareHearingAI.gd`
- `scripts/tools/ValidateRedAlarmAttractionAI.gd`
- `scripts/tools/ValidateHideableLocker.gd`
