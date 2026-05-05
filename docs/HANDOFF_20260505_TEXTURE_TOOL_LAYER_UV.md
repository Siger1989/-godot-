# Handoff 2026-05-05 - Texture Tool Layer UV Controls

## Current Objective

暂停当前实现，交接给下一次 Codex session 继续。

下一步目标是改进贴图调整器的图层控制，让小白也能明确控制脏迹图层：

- 明确横向缩放和纵向缩放，不再只显示不清楚的“最小缩放 / 最大缩放”。
- 增加图层上下位置调节，让顶部/底部/墙脚脏迹可以上下移动。
- 生成器预览、保存后的颜色贴图、Godot 实际游戏材质三者尽量保持一致。
- 不继续改程序地图生成，也不动 FourRoomMVP 基准布局，除非为了验证贴图显示。

## User's Latest Request

用户指出当前图层面板里：

- 看不出哪个是横向缩放，哪个是纵向缩放。
- 不能调上下位置。

截图位置在贴图调整器的“图层合成”区域，当前字段包括：

- 出现概率 0-1
- 随机数量
- 随机旋转角度
- 最小缩放
- 最大缩放
- 底部高度比例
- 随机 seed

## Required Next Change

在 `codex_tools/texture_tool/texture_tool_server.py` 中改图层数据和 UI：

1. 将图层缩放拆成明确的 X/Y：
   - `横向缩放最小`
   - `横向缩放最大`
   - `纵向缩放最小`
   - `纵向缩放最大`

2. 增加上下位置控制：
   - 建议字段名：`position_y_offset`
   - UI 文案：`上下偏移 -1~1（正数向下）`
   - 合成时对最终贴图位置做 Y 偏移，并 clamp 到贴图范围内。

3. 保持向后兼容：
   - 老配置里的 `scale_min` / `scale_max` 仍然能读取。
   - 如果新字段不存在，用老的 uniform scale 作为 X/Y 默认值。

4. 生成器预览和保存结果都必须使用同一套图层计算，不要只改 UI。

## Suggested Implementation Details

`codex_tools/texture_tool/texture_tool_server.py`：

- `_default_layer()` 增加：
  - `scale_x_min`
  - `scale_x_max`
  - `scale_y_min`
  - `scale_y_max`
  - `position_y_offset`

- `_sanitize_layer()`：
  - 分别 sanitize X/Y scale range。
  - 如果新字段缺失，fallback 到旧的 `scale_min` / `scale_max`。
  - `position_y_offset` clamp 到 `-1.0 .. 1.0`。

- `_scaled_overlay()`：
  - 现在是 uniform scale：
    - `scale = rng.uniform(scale_min, scale_max)`
  - 改为：
    - `scale_x = rng.uniform(scale_x_min, scale_x_max)`
    - `scale_y = rng.uniform(scale_y_min, scale_y_max)`

- `_overlay_position()`：
  - 对 top / bottom / center / full 都应用 `position_y_offset`。
  - 正数向下，负数向上。
  - 最终 `y` clamp 到 `0 .. canvas_height - overlay_height`。

- JS `collectLayersFromDom()`：
  - 收集新字段。
  - 老字段可以保留写回，但不要再作为 UI 主字段。

- `newLayerData()`：
  - 默认加新字段。

UI 文案建议：

- `横向缩放最小`
- `横向缩放最大`
- `纵向缩放最小`
- `纵向缩放最大`
- `上下偏移 -1~1（正数向下）`
- 将 `底部高度比例` 改成更通用的 `顶部/底部影响高度比例` 或 `边缘影响高度比例`。

## Runtime Shader Optional Follow-up

如果需要让 Godot 实际运行时的随机脏迹也响应 X/Y 缩放和上下偏移，需要继续改：

- `scripts/tools/build_runtime_wall_grime_atlas.py`
- `materials/shaders/contact_ao_surface.gdshader`
- `scripts/visual/ContactShadowMaterial.gd`

建议新增运行时配置：

- `size_x_scale`
- `size_y_scale`
- `top_offset`
- `bottom_offset`

但本次优先先让贴图工具合成结果正确、UI 清晰。

## Validation To Run Next Session

先运行项目启动检查：

```powershell
Set-Location -LiteralPath 'E:\godot后室'
git status --short
git diff --stat
```

注意：当前目录之前不是 git repo，这两个命令可能报 `not a git repository`，但仍然要执行并记录。

基础验证：

```powershell
python -m py_compile codex_tools\texture_tool\texture_tool_server.py
python codex_tools\texture_tool\texture_tool_server.py --self-test
```

如果改了 JS，建议提取 HTML 中脚本到临时文件并跑：

```powershell
node --check <extracted-js-file>
```

如果改了 Godot 运行时材质/着色器，再跑 Godot bake/validate：

```powershell
$godot = 'C:\Users\sigeryang\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path . --script res://scripts/tools/BakeFourRoomScene.gd --log-file logs\handoff_bake_mvp.log
& $godot --headless --path . --script res://scripts/tools/ValidateGeneratedMeshRules.gd --log-file logs\handoff_validate_mesh.log
& $godot --headless --path . --script res://scripts/tools/ValidateSceneShadows.gd --log-file logs\handoff_validate_shadows.log
```

## Process Cleanup Rule

用户明确要求：每次开了贴图工具服务，结束时要关掉。

检查并关闭：

```powershell
$procs = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'python.exe' -and $_.CommandLine -like '*texture_tool_server.py*' }
foreach ($proc in $procs) { Stop-Process -Id $proc.ProcessId -Force }
```

当前交接时已经关闭了两个旧的 `texture_tool_server.py` 进程。

## Files To Read Next Session

按用户要求，不依赖聊天历史，先读：

- `docs/CODEX_FRESH_SESSION_PROMPT.md`
- `README.md`
- `CURRENT_STATE.md`
- `docs/AGENT_START_HERE.md`
- `docs/PROGRESS.md`
- `docs/DECISIONS.md`
- `docs/FORBIDDEN_PATTERNS.md`
- `docs/ACCEPTANCE_CHECKLIST.md`
- `docs/HANDOFF_20260504_PROC_MAZE.md`
- `docs/HANDOFF_20260505_TEXTURE_TOOL_LAYER_UV.md`

## Suggested New Session Prompt

复制下面这段给新 session：

```text
继续 E:\godot后室 项目。

不要依赖聊天历史。请先读取：
docs/CODEX_FRESH_SESSION_PROMPT.md

然后按里面的顺序读取 README.md、CURRENT_STATE.md、docs/AGENT_START_HERE.md、docs/PROGRESS.md、docs/DECISIONS.md、docs/FORBIDDEN_PATTERNS.md、docs/ACCEPTANCE_CHECKLIST.md、docs/HANDOFF_20260504_PROC_MAZE.md、docs/HANDOFF_20260505_TEXTURE_TOOL_LAYER_UV.md。

先运行：
git status --short
git diff --stat

当前先不要继续地图生成，先处理贴图调整器 UI。
最新问题是：图层合成里看不出哪个是横向缩放、哪个是纵向缩放，并且不能调上下位置。

请修改 codex_tools/texture_tool/texture_tool_server.py：
1. 把图层缩放拆成横向缩放最小/最大、纵向缩放最小/最大。
2. 增加上下偏移 -1~1（正数向下）。
3. 合成预览和生成保存都必须使用这些新参数。
4. 老配置里的 scale_min/scale_max 要兼容。
5. UI 文案要让小白能直接看懂。

如果需要让 Godot 实际运行时随机脏迹也同步这些参数，再改 scripts/tools/build_runtime_wall_grime_atlas.py、materials/shaders/contact_ao_surface.gdshader、scripts/visual/ContactShadowMaterial.gd。

验证后更新 CURRENT_STATE.md、docs/PROGRESS.md、docs/DECISIONS.md。
结束前必须关闭 python codex_tools\texture_tool\texture_tool_server.py 进程，不要留下后台服务。
```

