# Backrooms Mobile Demo

Godot 4.3 单机纵切片 Demo。当前版本不依赖外部素材，使用 Godot 原生 3D 网格和运行时程序纹理搭建 Backrooms Level 0 的大空间、低吊顶、荧光灯、旧地毯和黄绿色墙纸方向。

## 当前工程

- 主工程目录：`backrooms_mobile_demo`
- 主入口场景：`res://scenes/main/Main.tscn`
- 主地图脚本：`res://scripts/environment/Level0_Demo.gd`
- 当前运行版本：Godot 4.3 stable，OpenGL 兼容渲染
- 原始参考目录：`../backrooms-mobile-demo-(4.2)`
- 备份目录：`../backup_before_v4_boundary_fog_monster_patch`

## 运行

双击根目录脚本：

- `open_editor.bat`：打开编辑器
- `run_game.bat`：运行主 Demo
- `run_fog_test.bat`：运行基础房间雾测试场景
- `run_room_prototype.bat`：运行房间状态原型
- `run_visibility_blend_test.bat`：运行物理可见性混合测试
- `validate_all.bat`：无界面跑全部验证脚本

Godot 路径统一放在 `tools/godot_env.bat`。如果本机路径不同，可以先在命令行设置 `GODOT_CONSOLE_EXE` 和 `GODOT_EDITOR_EXE`，再运行这些脚本。

## 操作

- `WASD` / 方向键：移动
- `Shift`：奔跑
- `E`：互动、拾取、开门、操作电箱
- `Q` / `R`：旋转镜头
- `Z`：切换镜头远近
- `Esc`：重新开始

## 玩法闭环

从起始开阔区出发，收集 3 个保险丝，进入电气间修复配电箱，然后去远端出口区打开金属门。黑影实体会在危险长廊和北侧重复房间附近巡逻，靠太近会失败。

## 目录职责

- `scenes/main`：游戏主入口
- `scenes/levels`：主关卡和可见性测试关卡
- `scenes/characters`：玩家和黑影实体场景
- `scenes/items`：保险丝、电箱、出口门
- `scenes/modules`：门、墙、地面、灯、房间体积等模块
- `scenes/ui`：HUD、移动端占位 UI 和结果界面
- `scripts/core`：流程、目标、互动和设置
- `scripts/environment`：关卡生成、门、房间雾、墙体淡出和可见性实验
- `scripts/player`：玩家控制和测试玩家
- `scripts/ai`：黑影实体和巡逻辅助
- `scripts/tools`：截图和验证脚本
- `tools`：本地批处理共享配置

## 验证

`validate_all.bat` 会依次运行：

1. `ValidateMainScene.gd`
2. `ValidateFogTest.gd`
3. `ValidateRoomPrototype.gd`
4. `ValidateVisibilityBlendTest.gd`

这些验证只检查场景加载和关键逻辑状态，不替代真机手感、灯光和性能测试。

无界面验证时 Godot 4.3 可能输出 `mesh_get_surface_count` 的重复渲染日志，当前记录在 `KNOWN_ISSUES.md`。
