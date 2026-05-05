# AGENT_START_HERE

你正在从 0 搭建：**后室多人联机手游｜四房间环形 MVP 场景视觉规范**。

## 每次开始必须先读

按顺序读取：

1. `docs/PROGRESS.md`
2. `docs/DECISIONS.md`
3. `docs/TASKS_PHASED.md` 中的当前阶段
4. `docs/FORBIDDEN_PATTERNS.md`
5. `docs/ACCEPTANCE_CHECKLIST.md` 中的当前阶段验收项
6. 只在需要细节时，用检索标签读取 `docs/MVP_SPEC.md`

## 当前硬原则

- 不修旧工程；从干净小场景开始。
- 不用黑片、灰片、透明片覆盖场景作为正式视觉效果。
- 不写 `if Room_A / Room_B / Room_C / Room_D` 房间特例。
- 不把所有逻辑塞进一个大脚本。
- 每次只执行一个阶段。
- 每次完成后必须更新 `docs/PROGRESS.md`。
- 当前阶段没通过验收，不进入下一阶段。

## MVP 场景结构

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

## 每轮输出格式

```text
当前阶段：Phase X - 名称
本轮读取：
- docs/PROGRESS.md
- docs/TASKS_PHASED.md / Phase X
- docs/FORBIDDEN_PATTERNS.md
- docs/ACCEPTANCE_CHECKLIST.md / Phase X

本轮目标：
1.
2.
3.

将修改文件：
- path/file.gd
- path/scene.tscn

执行结果：
- 完成了什么
- 没完成什么

自检：
- 禁止方案搜索：通过 / 未通过
- 阶段验收：通过 / 未通过
- 截图观察：通过 / 未通过 / 未执行，原因

已更新：docs/PROGRESS.md
下一步：继续 Phase X / 不能进入下一阶段的原因
```
