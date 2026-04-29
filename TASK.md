# TASK

## 当前版本状态

- Godot 4.3 项目骨架和运行脚本已统一。
- 主场景：`res://scenes/main/Main.tscn`
- 主关卡：`res://scenes/levels/Level0_Demo.tscn`
- 主玩法闭环：收集 3 个保险丝、修复电箱、打开出口门、避开黑影。
- 关卡内容由程序生成：墙体、地面、吊顶、灯光、门、道具和占位角色。
- 已加入房间状态雾、开门局部显隐、镜头遮挡墙体淡出、物理可见性混合测试。
- `validate_all.bat` 可无界面验证主场景加载和三个可见性测试。

## 已完成

- Level 0 大空间程序布局
- 低矮吊顶、荧光灯、旧墙纸、地毯、旧胶片 UI overlay
- 玩家、斜俯视镜头、移动、奔跑、互动
- 3 个保险丝、电气间、出口门、结算
- 普通门、锁门、封死门
- 黑影实体巡逻与追逐
- 基础 HUD 和移动端按钮占位
- 房间可见性原型和验证脚本

## 暂不整理的内容

- `../backrooms-mobile-demo-(4.2)` 保留为原始参考版本。
- `../backup_before_v4_boundary_fog_monster_patch` 保留为补丁前备份。
- `screenshots/*.png` 是测试截图输出，默认被 `.gitignore` 忽略。
- `.godot/` 是 Godot 编辑器缓存，默认忽略。
- Godot 4.3 headless 验证可能输出 `mesh_get_surface_count` 噪声，见 `KNOWN_ISSUES.md`。

## 下一步建议

- 导入真实墙纸、地毯、吊顶 PBR 材质，并记录到 `ASSET_LICENSES.md`。
- 替换程序人形为授权角色模型，至少包含 idle/walk/run。
- 调整碰撞、灯光数量和移动端性能。
- 为 Web 导出安装模板并生成 `exports/web/`。
- 给主玩法闭环补一条自动化验证：保险丝收集、电箱修复、出口胜利。
