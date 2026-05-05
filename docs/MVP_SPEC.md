# MVP_SPEC｜四房间环形 MVP 场景视觉规范

本文是完整需求源。Agent 不应每次整篇塞入上下文，而应通过标签检索需要的段落。

## 检索标签列表

- `[HARD-REQUIREMENTS]`
- `[MVP-SCOPE]`
- `[FOUR-ROOM-LAYOUT]`
- `[BASE-GAME-ELEMENTS]`
- `[ASSET-LIBRARY]`
- `[VISUAL-STYLE]`
- `[CAMERA]`
- `[FOREGROUND-OCCLUSION]`
- `[VISIBILITY-3STATE]`
- `[PORTAL-VISIBILITY]`
- `[LIGHTING]`
- `[VOID-WALL]`
- `[MODULES]`
- `[DIRECTORY]`
- `[PHASES]`
- `[ACCEPTANCE]`
- `[DEBUG]`
- `[EXTENSION]`
- `[FORBIDDEN]`

检索示例：

```bash
rg "\[FOUR-ROOM-LAYOUT\]" docs/MVP_SPEC.md -n -A 40
rg "\[FOREGROUND-OCCLUSION\]" docs/MVP_SPEC.md -n -A 50
rg "\[FORBIDDEN\]" docs/MVP_SPEC.md docs/FORBIDDEN_PATTERNS.md -n -A 60
```

---

## [HARD-REQUIREMENTS] 本次重开的硬要求

本次从 0 搭建一个干净的四房间环形 MVP，不继承旧错误实现。

禁止：

- 不允许用大面积黑色 Mesh / 灰色 Mesh 覆盖场景作为正式可见性效果。
- 不允许用漂浮遮罩面去盖地板、墙、灯板。
- 不允许做半透明黄色玻璃墙来解决前景遮挡。
- 不允许每个房间写 `if RoomA / RoomB / RoomC` 这种特例。
- 不允许所有系统塞进一个大脚本。
- 不允许先做大地图再回头修基础视觉。

必须：

- 先搭建四房间环形 MVP。
- 所有房间、门、灯、墙、地板模块化。
- 所有核心系统能单独开关和调试。
- 后续扩展大场景时，只新增房间模块 / 门模块 / 数据，不重写核心逻辑。

---

## [MVP-SCOPE] MVP 范围

本次只做场景视觉 MVP 和基础结构，不做完整玩法。

必须有：

- 4 个房间。
- 4 个 Portal / 门洞 / 门连接。
- 1 个玩家。
- 1 个稳定相机。
- 房间墙、地板、天花、门。
- 灯板 Mesh + Light3D。
- 前景墙遮挡处理。
- 当前可见 / 已见记忆 / 未知黑区的基础能力。
- 外墙黑色 VOID。
- Debug 开关。

暂不做：

- 怪物 AI。
- 多人联机同步。
- 程序化大地图生成。
- 完整 UI。
- 复杂道具系统。
- 复杂剧情事件。
- 存档系统。
- 复杂音频系统。

可以放占位点：怪物出生点、道具点、事件点、出口点。

---

## [FOUR-ROOM-LAYOUT] 四房间闭环布局

四个房间按 2 x 2 排列：

```text
Room_D  <---->  Room_C
  ^              ^
  |              |
  v              v
Room_A  <---->  Room_B
```

闭环动线：

```text
Room_A -> Room_B -> Room_C -> Room_D -> Room_A
```

房间职责：

| 房间 | 名称 | 作用 | 视觉重点 |
|---|---|---|---|
| Room_A | StartRoom | 玩家出生房间 | 标准后室基准风格 |
| Room_B | LightRoom | 灯光测试房间 | 灯板、阴影、光照范围 |
| Room_C | ObjectiveRoom | 目标房间 | 出口/目标点/测试道具 |
| Room_D | NarrowRoom | 压迫感房间 | 稍窄、更暗、相机遮挡测试 |

尺寸建议：

| 对象 | 建议尺寸 |
|---|---|
| Room_A | 6m x 6m |
| Room_B | 6m x 6m |
| Room_C | 6m x 6m |
| Room_D | 5.2m x 6m，可稍窄 |
| 墙高 | MVP 当前 2.55m，移动端斜俯视优先 |
| 墙厚 | 0.16m - 0.25m |
| 门宽 | 1.0m - 1.2m |
| 门高 | 2.1m - 2.25m |
| 灯板 | 1.2m x 0.45m 或 1.5m x 0.5m |

Portal：

| Portal | 连接 | 类型 | 初始状态 |
|---|---|---|---|
| P_AB | Room_A ↔ Room_B | 普通门 | 打开 |
| P_BC | Room_B ↔ Room_C | 可开关门 | 半开或关闭 |
| P_CD | Room_C ↔ Room_D | 门洞 | 打开 |
| P_DA | Room_D ↔ Room_A | 可开关门 | 关闭 |

---

## [BASE-GAME-ELEMENTS] 基础游戏元素

必须有：

- PlayerSpawnPoint。
- MonsterSpawnPoint，占位即可。
- ItemSpawnPoint，占位即可。
- EventTriggerPoint，占位即可。
- ExitPoint，占位即可。
- 简单目标点放在 Room_C。
- 门交互提示可以是临时文字。

---

## [ASSET-LIBRARY] 3D 模型库

`E:\godot后室\3D模型` 作为后续 3D 模型库。

- `zhujiao.glb`：玩家主角模型，Phase 2 玩家与相机阶段接入。
- `guai1.glb`：后续怪物模型候选，只做资产记录；当前 MVP 阶段不提前实现怪物 AI。

---

## [VISUAL-STYLE] 场景视觉风格

目标：后室 + 轻微半写实 + 简洁统一 + 可扩展移动端风格。

渲染目标：Godot 4.6.2 Mobile 渲染器，优先兼容手机性能预算。

墙面：黄米色 / 淡黄旧墙纸，轻微纹理，不高反光。  
地面：黄棕 / 暗米色地毯或地板，纹理清楚，不糊，不马赛克。  
门：简单木门 / 老旧门，比墙略深。  
灯板：白色或暖白矩形，简洁，不夸张。  
外墙：黑色 / 暗色 VOID，不显示室内黄色墙纸。

---

## [CAMERA] 相机规范

- 斜俯视，不要纯上帝视角。
- 建议俯角 45°~55°。
- 中近距离。
- 玩家位于画面中下或中心偏下。
- 镜头不要太高，避免墙像矮围栏。
- 镜头不要太远，保留室内压迫感。

---

## [FOREGROUND-OCCLUSION] 前景遮挡规范

当前景墙挡住玩家：

正确：

- 挡住玩家的前景墙局部挖空或隐藏。
- 玩家始终清晰可见。
- 不影响墙体碰撞。
- 不影响真实视线阻挡。
- 不影响可见性三态。

错误：

- 黄色半透明玻璃墙。
- 灰色大平面。
- 黑色大三角。
- 一块一块透明墙片。
- 大范围 alpha 淡出。

MVP 可接受：

- Camera -> Player raycast 命中前景墙 Mesh。
- 命中 Mesh 隐藏。
- 离开遮挡后恢复显示。
- StaticBody / CollisionShape 保持不动。

---

## [VISIBILITY-3STATE] 可见性三态

三种状态：

1. 当前可见区域：正常显示。
2. 已见记忆区域：灰色记忆状态，不是纯黑。
3. 从未看过区域：黑色未知。

要求：

- 规则全局统一，不针对某房间写特例。
- 墙、地面、门、灯板都遵守同一套结果。
- 不使用漂浮黑片 / 灰片作为最终视觉。
- 已见记录应是区域级，不是整房间 visited。

---

## [PORTAL-VISIBILITY] 门洞切线可见性

通过门洞看另一空间时，边界必须是连续几何切线：

```text
玩家眼点 -> 门洞左边缘
玩家眼点 -> 门洞右边缘
```

要求：

- 不透墙。
- 门关闭时不通视。
- 门开启时按开口范围通视。
- 不出现整房间突然显示。
- 不出现马赛克边界。
- 不用地砖 tile 中心点判断可见性。

---

## [LIGHTING] 灯板与真实灯光

灯板 Mesh 和真实 Light3D 必须分离。

- 灯板 Mesh 是可见物体。
- Light3D 是照明源。
- 灯板不可见不等于灯光关闭。
- 灯光偏暖白，略压抑。
- 每个房间至少一个灯板和一个 Light3D。

---

## [VOID-WALL] 外墙 / VOID 黑面

外墙外侧必须是黑色 / 暗色 VOID。

禁止：

- 外墙外侧显示黄色室内墙纸。
- 用灰色透明片盖住外墙外侧。

MVP 可接受：

- 外墙外侧直接用黑色 opaque 材质。
- 或外墙只渲染室内侧，外侧用黑色封边。

---

## [MODULES] 模块化结构

建议模块：

- `SceneBuilder`：搭建房间、墙、地板、门、灯。
- `RoomModule`：单个房间数据与节点容器。
- `WallModule`：墙体、内外侧材质、碰撞。
- `DoorComponent`：门开关、动画、碰撞。
- `PortalComponent`：区域连接、门洞数据、门状态读取。
- `CameraController`：相机跟随。
- `ForegroundOcclusion`：前景遮挡。
- `LightingController`：灯板和 Light 管理。
- `VisibilitySolver`：当前可见区域。
- `VisibilityMemory`：已见区域。
- `VisibilityRenderer`：三态显示。
- `DebugOverlay`：调试可视化。

---

## [DIRECTORY] 推荐目录结构

```text
/scenes
  /mvp
    FourRoomMVP.tscn
  /modules
    RoomModule.tscn
    WallModule.tscn
    DoorModule.tscn
    CeilingLightModule.tscn
    PortalModule.tscn
    SpawnPointModule.tscn
/scripts
  /core
    SceneBuilder.gd
    GameBootstrap.gd
  /scene
    RoomModule.gd
    WallModule.gd
    PortalComponent.gd
    DoorComponent.gd
  /camera
    CameraController.gd
    ForegroundOcclusion.gd
  /visibility
    VisibilitySolver.gd
    VisibilityMemory.gd
    VisibilityRenderer.gd
  /lighting
    LightingController.gd
    CeilingLightComponent.gd
  /debug
    DebugOverlay.gd
/materials
  Wall_Backrooms.tres
  Floor_Carpet.tres
  Door_Wood.tres
  CeilingLight_Emissive.tres
  Void_Black.tres
/data
  four_room_mvp_layout.yaml
/docs
  AGENT_START_HERE.md
  MVP_SPEC.md
  TASKS_PHASED.md
  PROGRESS.md
```

---

## [PHASES] 开发阶段

按 `docs/TASKS_PHASED.md` 执行，不要跳阶段。

---

## [ACCEPTANCE] 验收标准

按 `docs/ACCEPTANCE_CHECKLIST.md` 执行，不通过不进入下一阶段。

---

## [DEBUG] Debug 开关

按 `docs/DEBUG_GUIDE.md` 执行。

---

## [EXTENSION] 扩展到大场景规则

后续扩展到大地图时：

- 新房间 = 新 `RoomModule` + data。
- 新门 = 新 `DoorModule` + `PortalComponent`。
- 新灯 = 新 `CeilingLightModule`。
- 新区域 = 新 area 数据。
- 不改核心可见性逻辑。
- 不写房间名特例。
- 所有系统保持可调试。

---

## [FORBIDDEN] 禁止方案

详见 `docs/FORBIDDEN_PATTERNS.md`。本段是摘要：

- 不盖黑片 / 灰片。
- 不做黄玻璃前景墙。
- 不写房间特例。
- 不用整房间 visited。
- 不把灯板和 Light 当成同一个开关。
- 不把所有逻辑塞进一个脚本。
