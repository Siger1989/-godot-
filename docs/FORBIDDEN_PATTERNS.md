# FORBIDDEN_PATTERNS｜禁止方案与搜索清单

这些不是建议，而是硬性禁止。每个阶段前后都要搜索一次。

## 1. 禁止的视觉实现路线

- 不准用大面积黑色 Mesh / 灰色 Mesh 覆盖场景作为正式可见性效果。
- 不准用漂浮遮罩平面盖地板、墙、门、灯板。
- 不准为了前景遮挡把墙做成黄色半透明玻璃。
- 不准一块一块地让墙/地板显隐，导致马赛克边界。
- 不准靠近门洞后整房间直接显示。
- 不准使用房间级 visited 代表整个房间都看过。

## 2. 禁止的架构写法

- 不准所有功能塞进一个大脚本。
- 不准写 `if Room_A / Room_B / Room_C / Room_D` 作为可见性核心逻辑。
- 不准门状态写死在房间脚本里。
- 不准灯板 Mesh 和真实 Light3D 绑定成同一个显隐开关。

## 3. 必跑搜索命令

在项目根目录运行：

```bash
rg "door_visibility_mask_mesh|door_wall_mask_mesh|door_visibility_cutline_mesh" .
rg "_append_mask_quad|_append_reveal_mask|_append_vertical_wall_masks|_append_horizontal_wall_masks" .
rg "CAMERA_FADE_MIN_ALPHA|CAMERA_FADE_RADIUS" .
rg "ALPHA\s*=|blend_mode|transparency" .
rg "if .*Room_A|if .*Room_B|if .*Room_C|if .*Room_D" .
rg "visited\[.*room|visited_rooms|current_room" .
```

## 2026-05-04 proc-maze lighting forbidden patterns

- Do not force one ceiling light into every generated proc-maze space.
- Do not place ceiling light panels in narrow corridors, L-turn corridors, T junctions, offset corridors, or other short connector spaces where they can clip walls or make the space visually cluttered.
- Do not hand-move individual `CeilingLightPanel_*` or `CeilingLight_*` nodes in baked test scenes to fix overlap.
- Do not solve lamp/wall overlap by disabling wall collision, shrinking walls, using negative scale, or adding one-off invisible blockers.
- Do not light a long rectangular panel with one full-strength center point source.
- Keep visual light panels and real `OmniLight3D` nodes separate; one visible panel must match one or more real sources when a module has lighting.

## 2026-05-04 proc-maze doorway forbidden patterns

- Do not let a full-height wall or internal partition start immediately behind a generated door frame.
- Do not fix abrupt doorway walls by hand-moving baked `Wall_*`, `InternalWall_*`, `WallOpening_*`, or `DoorFrame_*` nodes.
- Do not solve a doorway blocker by disabling collision, hiding the wall, using negative scale, or adding an invisible blocker.
- Doorway clearance must come from opening/reveal generation rules and must validate with `has_door_reveal_blocker=false`.

## 2026-05-03 exception

- Small structural grime decals are allowed only through the validated global grime system (`GrimeOverlayBuilder.gd` / `ValidateGrimeExperiment.gd`) and only as subtle edge aging.
- This exception does not allow visibility masks, large wall/floor cover sheets, fake shadow planes, or per-room hand fixes.

说明：

- `ALPHA` 不是绝对禁止，但只能用于 `ForegroundOcclusion` 的局部 cutout，不能用于黑/灰可见性覆盖。
- 如果搜索结果命中旧遮罩逻辑，必须停止并解释，不能继续新增功能。
