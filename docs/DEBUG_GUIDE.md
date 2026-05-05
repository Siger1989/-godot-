# DEBUG_GUIDE｜调试开关规范

## 必备 Debug 开关

建议放在 `DebugOverlay` 或全局 debug 配置中：

```gdscript
var show_area_ids := false
var show_portals := false
var show_visible_polygon := false
var show_memory := false
var show_foreground_hits := false
var show_light_ranges := false
var show_void_walls := false
```

## Debug 目的

| 开关 | 目的 |
|---|---|
| show_area_ids | 确认房间/区域 ID 是否正确 |
| show_portals | 确认门/门洞连接关系 |
| show_visible_polygon | 确认当前可见区域 |
| show_memory | 确认已见记忆区域 |
| show_foreground_hits | 确认相机前景遮挡命中 |
| show_light_ranges | 确认 Light3D 范围 |
| show_void_walls | 确认外墙 VOID 面 |

## 截图自检

每阶段建议至少截 1 张图：

- Phase 1：四房间总览图。
- Phase 2：玩家 + 相机视角图。
- Phase 3：前景墙遮挡测试图。
- Phase 4：材质灯光图。
- Phase 6：黑 / 灰 / 正常三态图。
- Phase 7：门洞切线图。
