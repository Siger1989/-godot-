# CURRENT_STATE

## 当前进度

- 项目已整理为 Godot 4.3 可运行结构，主要 demo 位于 `backrooms_mobile_demo`。
- 小场景 `scenes/levels/Visibility_Blend_Test.tscn` 已用于测试门后记忆显示。
- 写实墙纸、地板、天花贴图已生成并接入 `assets/textures/backrooms/`。
- 地板颜色实时明暗变化已处理，地面改为稳定材质表现。
- 门框顶部异常和地板偏暗问题已调整。
- 门关闭后，门后房间进入静态记忆状态，不再显示实时灯光和灯板。
- 小场景验证过的关门记忆规则已同步到主游戏：已访问但不可见房间只保留静态结构记忆，不再显示 `light_mesh`、真实灯光和 detail/dynamic 内容。
- 小场景的房间关系规则已同步到主游戏：开门邻房不会直接变成 `PARTIAL_VISIBLE`，未进入前保持 `UNKNOWN`，进入后才变 `VISIBLE`，离开后变 `VISITED`。
- 主游戏 `OutOfBoundsVoid` 改为只保留碰撞、不渲染视觉，避免出现灰色大块遮挡。
- 主游戏可见距离参数已对齐小场景：clear 7.5、dim 13.0、black 19.0。
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
- 主游戏关门记忆验证包含 `MAIN_CLOSED_MEMORY_OK`。
- 主游戏开门邻房保持 `UNKNOWN` 的关系已纳入 `MAIN_CLOSED_MEMORY_OK` 验证。
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
- `scripts/tools/ValidateMainClosedMemory.gd`
- `scripts/tools/ValidateVisibilityClosedMemory.gd`
- `validate_all.bat`
- `HANDOFF.md`
- `AGENTS.md`

## 下一步

- 继续在主 Demo 中目测人物模型比例、地板亮度、门框顶部和主游戏关门记忆显示效果。
- 如需微调人物比例，使用右侧 `人物展示` 面板滑条后点击保存。
- 如仍有视觉问题，优先用截图定位，再做小范围调整并更新本文件。
- 每次结束前更新 `HANDOFF.md` 或本文件，并提交推送到 GitHub。
- 每次交付时给出当前可启动入口：默认使用 `run_game.bat`；需要分享给别人时再导出 Windows/Web 包。

## 2026-04-29 方案调整

- 当前主游戏结构暂时不再继续修补。
- 后续优先从已敲定的小场景延申，保持小场景中已经确认过的连续地面、房间关系和记忆显示逻辑。
- 回头需要先对齐新方案，再把小场景扩展成正式游戏流程。

## 2026-04-30 小场景视觉连续性

- 已调整 `Visibility_Blend_Test`：可被物理视线看到的地板、墙面、踢脚线、转角件会继续使用原贴图显示，不再因为目标房间逻辑状态仍是 `UNKNOWN` 就直接变黑。
- 转角柱从黑色/脏墙材质改为同墙布材质，并缩小厚度，减少墙布转角处的黑边。
- 小场景仍保留未知区域遮挡；本次只处理眼前可见范围的墙布和地面连续性。
- 已继续修正同类视觉 bug：墙/地板/踢脚线/转角件不再使用 `UNKNOWN`/`VISITED` 的黑灰平面材质；大墙块改为多点采样可见性，避免只因中心点不可见就整面变黑；灯板和灯光改为平滑权重显示，减少走到阈值时瞬间亮起。
- 已恢复物理视线遮挡原则：当前房间不再被强行整块设为实时可见，结构 mesh 会根据射线可见性平滑进入实时显示；失去视线后保留静态贴图记忆，灯和动态内容只淡出、不进入记忆状态。
- 摄像机挡墙淡出从瞬间切换改为平滑过渡，降低移动时墙面闪烁。
- 摄像机穿透/淡出的墙体现在会显示轻微的深色切线，方便后续区分“镜头切面”和正常墙布；切线不参与房间记忆或物理遮挡。
- 灯光逻辑已拆分：`Light3D` 负责真实照亮墙面，不再要求玩家直接看见灯板；灯板 mesh 只代表玩家能看到的发光表面，并拆成多段按视线遮挡显示。`VISITED` 记忆房间仍会关闭灯和灯板，避免记忆画面出现实时动态。
- 小场景的地板和墙段已拆成更小的可见性单元，避免继续按整间房/整面墙隐藏。每个小块按物理射线独立进入实时或灰暗记忆状态，并新增玩家视野多边形的深色切线，用于标识真实可见边界。
- 已修正墙板小块化后的误判：墙/踢脚线可见性采样改为采玩家朝向的墙面表面，不再采墙体中心，避免墙板被自己的碰撞体误挡后整片变成灰黑记忆。
- 未知/遮挡墙面的兜底显示已改为灰暗静态墙布，不再直接隐藏成黑洞；灰暗墙布亮度也上调，避免看起来像墙面坏块。
- 已修正“走到走廊后身后灯消失、返回初始点后走廊灯消失”的回归：灯板和真实灯不再被 `VISITED` 房间状态强制关闭，而是由水平物理视线决定；关门后的已访问房间仍保持静态记忆，不显示实时灯光。
- `has_line_of_sight` 改为固定视线高度的水平射线，避免高处灯板绕过墙体导致误亮；新增验证覆盖初始看走廊灯、走廊看身后灯、返回后看走廊灯三条路径。
- 已继续修正“走到走廊后后方整房间突然变黑”：结构显示不再按整房间 `VISITED` 兜底记忆，只有真正被看见过的墙/地板块才进入静态记忆；实时可见块直接显示原贴图，不再大面积混入灰黑记忆色。
- 小场景真实灯光不再由“当前房间可见”直接整房间打开，而是由物理可见的地板/灯板驱动；同时收紧地板采样点和射线容差，门板宽度加到 1.56，避免关门后门缝把门后房间误判为可见。
- 已按新规则调整视野切线和记忆显示：遮挡切线只在物理视野跳变处画柔和直线；看过但当前被遮挡的墙/地板块显示为不受实时光照影响的灰色静态记忆；从未见过的区域不再用灰墙布兜底，直接保持全黑。
