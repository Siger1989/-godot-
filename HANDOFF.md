# HANDOFF

## 2026-04-29 交接

### 仓库

- GitHub remote: `https://github.com/Siger1989/-godot-.git`
- 项目目录: `backrooms_mobile_demo`
- Godot 版本: 4.3 stable

### 当前状态

- 主 Demo 可运行，入口为 `scenes/main/Main.tscn`。
- 主角已替换为用户提供的 GLB：`assets/models/player.glb`。
- GLB 包含骨骼和 1 个 `Armature` 动画片段。
- 已接入人物状态动作：idle、walk、run。
- 跑步时前臂已做轻微压低修正。
- 右侧 `人物展示` 面板可调整人物高度、朝向、上下、左右、前后偏移。
- 天花板半透明面片已默认关闭，避免拉远镜头闪烁。
- 门关闭后的房间记忆状态已处理，不再显示实时灯板和动态内容。
- 小场景验证过的关门记忆规则已同步到主游戏 `RoomPrototypeSection`。
- 主游戏中已访问但不可见房间只显示静态结构记忆，不显示 `light_mesh`、真实灯光和 detail/dynamic 内容。

### 验证

- `validate_all.bat` 已通过。
- 关键结果包括：
  - `MAIN_SCENE_OK`
  - `PLAYER_MODEL_OK`
  - `MAIN_CLOSED_MEMORY_OK`
  - `FOG_TEST_OK`
  - `ROOM_PROTOTYPE_OK`
  - `VISIBILITY_BLEND_OK`
  - `VISIBILITY_CLOSED_MEMORY_OK`

### 下次继续

- 回家后 clone 仓库，先读 `CURRENT_STATE.md` 和本文件。
- 运行 `run_game.bat` 查看主 Demo。
- 如要继续视觉调参，优先调整人物展示窗口、地板亮度、门框和记忆房间显示。
- 每次完成一轮修改后，更新本文件或 `CURRENT_STATE.md`，提交并推送。
- 每次交付时给出当前可启动入口：默认使用 `run_game.bat`；需要分享给别人时再导出 Windows/Web 包。
