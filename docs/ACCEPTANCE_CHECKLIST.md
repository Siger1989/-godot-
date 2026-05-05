# ACCEPTANCE_CHECKLIST｜阶段验收清单

每阶段必须通过后才能进入下一阶段。

---

## Contact shadow acceptance

- [ ] Mobile renderer does not rely on SSAO for accepted contact darkening.
- [ ] Contact-shadow materials derive from shared wall/floor/ceiling/door-frame materials and preserve texture/UV/normal rules.
- [ ] MVP contact darkening applies to walls, floors, ceilings, and door frames.
- [ ] Proc-maze contact darkening applies to walls, wall openings, internal walls, and door frames; proc floors/ceilings keep existing materials.
- [ ] Runtime lighting panel exposes contact-shadow enable, strength, and maximum darkening.
- [ ] Validators pass with contact-shadow material wrappers.

## Proc-maze lighting acceptance

- [ ] Ceiling light panels do not overlap boundary walls or internal partition walls.
- [ ] Narrow corridors, L-turn corridors, T junctions, offset corridors, and short connector spaces may be unlit.
- [ ] No-ceiling preview validates against `active_light_count`, not total room count.
- [ ] Visual panels and real `OmniLight3D` nodes remain separate but paired by owner module.
- [ ] Long rectangular lamp panels use distributed real light sources, not one full-strength center point.
- [ ] Fixes are generator/validator rules, not hand edits in baked test scenes.

## Proc-maze doorway acceptance

- [ ] Door frames do not open directly into an abrupt full-height wall or internal partition.
- [ ] Large-room/hub internal partitions are trimmed or split around doorway reveal buffers.
- [ ] `SceneValidator.gd` reports `has_door_reveal_blocker=false`.
- [ ] Doorway fixes are generated from module/opening rules, not hand edits in baked test scenes.

## Proc-maze runtime lighting controller acceptance

- [ ] Playable proc-maze scene contains `Systems/LightingTuningPanel`.
- [ ] `ESC` shows/hides the panel and releases mouse capture.
- [ ] Clicking outside the panel hides it and captures mouse back for gameplay.
- [ ] Controls affect runtime light color, light energy/range/attenuation, lamp-panel emission, ambient color/energy, and flicker enable.
- [ ] Lighting changes refresh the flicker controller baseline.
- [ ] No-ceiling preview does not keep the runtime UI/player systems.
- [ ] `scenes/mvp/FourRoomMVP.tscn` is not modified unless explicitly requested.

## Texture tool layered overlay acceptance

- [ ] A material can keep a base albedo snapshot and compose overlay layers above it.
- [ ] A layer can upload multiple candidate images and randomly choose from that pool.
- [ ] Layer controls include placement, opacity, blend mode, count, scale range, and seed.
- [ ] Added layers can be deleted from the browser UI and stay deleted after save/reload.
- [ ] Blend modes include normal, multiply, screen, darken, lighten, overlay, soft light, hard light, and difference.
- [ ] Each layer can use a mask mode and adjustable feather before compositing.
- [ ] Composition writes to the existing material texture slot and backs up the previous output.
- [ ] The texture tool process is closed after validation when opened by Codex.

## Phase 0 验收

- [ ] 目录结构存在。
- [ ] 基础脚本文件存在。
- [ ] `data/four_room_mvp_layout.yaml` 存在。
- [ ] 没有旧黑片 / 灰片 / 透明片逻辑。
- [ ] 没有旧 `VisibilityBlendTest.gd` / `VisibilityBlendSection.gd` 依赖。

## Phase 1 验收

- [ ] 四个房间存在。
- [ ] 四个房间形成闭环。
- [ ] 玩家可以从 A -> B -> C -> D -> A。
- [ ] 墙高、门宽、房间比例符合规范。
- [ ] Portal 都有唯一 ID。
- [ ] 占位点存在：PlayerSpawn、MonsterSpawn、ItemSpawn、EventTrigger、ExitPoint。

## Phase 2 验收

- [ ] 玩家移动顺畅。
- [ ] 玩家碰撞正常。
- [ ] 相机跟随稳定。
- [ ] 相机角度约 45°~55°。
- [ ] 玩家在画面中清晰可见。

## Phase 3 验收

- [ ] 前景墙挡住玩家时，玩家仍清晰可见。
- [ ] 没有黄色透明玻璃墙。
- [ ] 没有灰色大平面。
- [ ] 没有黑色大三角。
- [ ] 墙体碰撞仍存在。
- [ ] 前景遮挡不影响可见性系统。

## Phase 4 验收

- [ ] 室内有后室感。
- [ ] 墙纸材质统一。
- [ ] 地板纹理清楚不糊。
- [ ] 灯板和真实 Light3D 是分离节点。
- [ ] 外墙外侧是黑色 VOID，不显示黄色内墙材质。

## Phase 5 验收

- [ ] 门能开关。
- [ ] 门动画基本自然。
- [ ] Portal 能读取门状态。
- [ ] 门状态不写死在房间脚本里。

## Phase 6 验收

- [ ] 当前可见区域正常显示。
- [ ] 已见不可见区域为灰色记忆。
- [ ] 从未看过区域为黑色未知。
- [ ] 地板、墙、门、灯板使用一致规则。
- [ ] 没有黑片 / 灰片漂浮错位。
- [ ] 没有房间级 visited 替代区域级 seen。

## Phase 7 验收

- [ ] 门洞视线边界是连续直线切线。
- [ ] 不出现整房间突然显示。
- [ ] 不透墙。
- [ ] 不出现马赛克边界。
- [ ] 门状态影响通视。

## Phase 8 验收

- [ ] Debug 开关存在。
- [ ] 可见性、前景遮挡、灯光、门状态可以独立排查。
- [ ] 新增房间时只需新增 area / portal / prefab / data。
- [ ] Agent 输出说明如何扩展到大地图。
