# Backrooms Proc Maze MVP

正式游玩入口：双击 `run_game.bat`。

`run_game.bat` 会读取 `project.godot` 的主场景 `res://scenes/ui/LoginMenu.tscn`，登录界面里的单人、创建房间、加入房间都会进入同一个正式大迷宫场景：

- `res://scenes/tests/Test_ProcMazeMap.tscn`

常用入口：

- `run_game.bat`: 正式游玩，包含登录界面、单人流程、GD-Sync 联机房间流程。
- `run_proc_maze_test.bat`: 直接进入大迷宫调试，不经过登录界面。
- `run_proc_maze_no_ceiling_preview.bat`: 顶视/无天花地图预览，用来检查布局。
- `run_monster_showcase.bat`: 怪物展示和调试。
- `run_resource_showcase.bat`: 资源展示。
- `run_mvp_room.bat`: 小 MVP 房间机制验证。
- `start_texture_tool.bat`: 材质和贴图工具。

已移除的旧调试入口：

- `run_feature_anchor_map.bat`
- `run_feature_room_preview.bat`
- `open_monster_size_source.bat`
- `open_mvp_monster_room.bat`

联机说明：

- 项目已加入 GD-Sync 插件运行时代码和 `GameSession` / `OnlineGameBridge` 接入。
- 私钥不要提交到 Git。调试时可使用本地忽略文件 `local_gdsync_keys.cfg`，格式参考 `local_gdsync_keys.example.cfg`。
- 未配置 GD-Sync 密钥时，单人模式正常可用；创建/加入房间会停在登录界面并提示缺少密钥。

项目结构和入口分类见 `docs/PROJECT_STRUCTURE.md`。
