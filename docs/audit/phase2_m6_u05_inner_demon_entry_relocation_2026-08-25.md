# P2-M6-U05 心魔入口归位 READY 审计

- 日期：2026-08-25
- 基线：`f6daaa534290e25e6eee0bc0bb686abb500f5823`
- 分支：`codex/phase2-m6-u05-inner-demon-entry-relocation-20260825`
- 生产候选：`7d6c2b3a2ceb1fbe6391eeb200b90bbd831ce05c`
- 结论：`READY`（P0/P1/P2 = 0）

## 范围与生产行为

冻结方案 §11.2 明确“心魔不出现在主菜单或地图，入口放到角色突破页面”。本纵切仅
删除主菜单重复心魔按钮及对应 import；角色面板生产代码未改，仍由
`innerDemonProgressProvider` 与 `resolveInnerDemonPanel` 决定突破阻断区，并经原
`Navigator` 进入 `InnerDemonScreen`。

未做江湖地图、地点迁移、心魔 Screen 删除，也未改变解锁、突破、战斗、失败、奖励、
schema/saveVersion、YAML、数值、概率、经济或 narrative。因此不得据此宣告 U05、
U06、M6 或二阶段完成。

## 红绿证据

实现前运行：

```text
flutter test --no-pub test/features/main_menu/presentation/main_menu_inner_demon_entry_relocation_test.dart
0 pass / 2 fail
```

两项失败分别证明原锁定态和满足 Ch6 门槛态仍显示“心魔境”。删除重复入口后同命令
`2/2 PASS`；角色面板新增测试点击“突破”并确认 `InnerDemonScreen` 已入栈。

## 验证矩阵

| 门禁 | 结果 |
|---|---:|
| 新增迁移 + 主菜单 + 角色面板联合 | 85/85 PASS |
| 主菜单、角色面板、心魔相邻域 | 178/178 PASS |
| `flutter analyze --no-pub lib test tool` | 0 issue |
| 根 `flutter analyze --no-pub` | 0 issue |
| `flutter test --no-pub` | 5369/5369 PASS |
| `dart format --set-exit-if-changed` | 0 changed |
| `git diff --check` | PASS |

根分析前在已跟踪独立子包 `tools/phase0minus_probe` 执行 `flutter pub get --offline` 补齐
ignored package metadata；无 tracked 越界。

## 独立只读复核

独立 reviewer 结论 P0=0、P1=0、P2=0，建议 READY，并确认：

- 主菜单锁定态、原 Ch6 解锁态均不再渲染心魔按钮；
- 角色突破区仍走原 provider/policy 与 `InnerDemonScreen`；
- 未新增地图或临时入口，未改变心魔业务语义；
- 变更文件全在精确白名单内，无 schema/YAML/数值/文案越界。

## 收口判定

代码、测试、审计与真相源均在登记白名单内；READY 标记应建立在本审计提交之上。
main 与 origin/main 未修改、未 push。
