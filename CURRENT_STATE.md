# CURRENT_STATE

## 当前进度

- 项目已整理为 Godot 4.3 可运行结构，主要 demo 位于 `backrooms_mobile_demo`。
- 小场景 `scenes/levels/Visibility_Blend_Test.tscn` 已用于测试门后记忆显示。
- 写实墙纸、地板、天花贴图已生成并接入 `assets/textures/backrooms/`。
- 地板颜色实时明暗变化已处理，地面改为稳定材质表现。
- 门框顶部异常和地板偏暗问题已调整。
- 门关闭后，门后房间进入静态记忆状态，不再显示实时灯光和灯板。
- 主角已替换为用户提供的 GLB 模型，模型资源位于 `assets/models/player.glb`。
- 主场景已加入 `人物展示` 调试窗口，可实时调整主角高度、朝向、上下、左右、前后偏移，并保存配置。
- 主 Demo 和小测试场景的天花板面片已默认关闭，避免拉远镜头时半透明顶板闪烁。
- 已检查 GLB：包含 1 套骨骼 skin、27 个关节、1 个名为 `Armature` 的动画片段，时长约 9.67 秒。
- 主角动作已接入状态机：idle 静止姿势加轻微呼吸，walk 播放 `Armature`，run 用更高速度播放同一动作。
- 跑步时前臂已做姿态修正：将 `LeftForeArm` / `RightForeArm` 少量混回 idle 姿势，降低小臂抬起幅度。
- GitHub 仓库已确定为 `https://github.com/Siger1989/-godot-.git`，后续每次阶段性完成后更新交接并推送。

## 已验证

- `validate_all.bat` 已通过。
- 关键验证包含 `VISIBILITY_CLOSED_MEMORY_OK`。
- 主角模型验证包含 `PLAYER_MODEL_OK`。
- 关门记忆截图已生成到 `screenshots/visibility_blend_closed_memory.png`。
- 静止截图确认人物已不再保持 T-pose。

## 关键文件

- `scripts/environment/Level0_Demo.gd`
- `scripts/environment/RoomPrototypeSection.gd`
- `scripts/environment/VisibilityBlendSection.gd`
- `scripts/environment/VisibilityBlendTest.gd`
- `scripts/environment/VisibilityBlendDoor.gd`
- `scripts/player/PlayerModelVisual.gd`
- `scripts/ui/PlayerModelAdjustPanel.gd`
- `scripts/tools/ValidatePlayerModel.gd`
- `scripts/tools/ValidateVisibilityClosedMemory.gd`
- `validate_all.bat`
- `HANDOFF.md`
- `AGENTS.md`

## 下一步

- 继续在主 Demo 中目测人物模型比例、地板亮度、门框顶部和记忆房间显示效果。
- 如需微调人物比例，使用右侧 `人物展示` 面板滑条后点击保存。
- 如仍有视觉问题，优先用截图定位，再做小范围调整并更新本文件。
- 每次结束前更新 `HANDOFF.md` 或本文件，并提交推送到 GitHub。
