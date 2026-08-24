# P2-M6-U05 主菜单角落工具区 READY 审计

- 日期：2026-08-25
- 基线：`30d6b1a3e9405e8ea7915803fa6f93b0e8d817e6`
- 分支：`codex/phase2-m6-u05-main-menu-corner-tools-20260825`
- 生产候选：`ed3087b72aca28068cca1155ddec47ba825b0700`
- 结论：`READY`（P0/P1/P2 = 0）

## 范围与生产行为

按冻结方案 §11.1，仅把资源总览与设置从一级玩法内容区移入主菜单右上角常驻工具区，
并与既有退出按钮并列。资源继续进入 `ResourceOverviewScreen`，设置继续调用
`SettingsPanel.show`，退出继续调用 `AppExit.confirmAndQuit`。启动门禁、四个一级入口、
条件入口门控与业务写入均未改变。

明确未做：U06 江湖地图与地点迁移、排行榜归位、Screen 删除、schema/saveVersion、
YAML、数值、概率、奖励、经济、解锁阈值或 narrative 变更。因此不得据此宣告
U05、M6 或二阶段完成。

## 红绿证据

实现前运行：

```text
flutter test --no-pub test/features/main_menu/presentation/main_menu_corner_tools_test.dart
0 pass / 6 fail
```

六项失败分别证明旧资源/设置卡片仍占内容区、右上角工具缺失、资源/设置真实去向无法
从角落触达，以及三种桌面视口缺少目标工具。实现后同命令 `6/6 PASS`。

## 验证矩阵

| 门禁 | 结果 |
|---|---:|
| 角落工具纵切 | 6/6 PASS |
| 角落工具 + 主菜单联合 | 57/57 PASS |
| 主菜单、资源总览、设置相邻域 | 128/128 PASS |
| `flutter analyze --no-pub lib test tool` | 0 issue |
| 根 `flutter analyze --no-pub` | 0 issue |
| `flutter test --no-pub` | 5366/5366 PASS |
| `dart format --set-exit-if-changed` | 0 changed |
| `git diff --check` | PASS |

根分析首次因已跟踪独立子包 `tools/phase0minus_probe` 缺少本地 package metadata 派生
1,943 项导入错误；在该子包执行 `flutter pub get --offline` 后原命令复跑为 0 issue。
补齐动作只生成 ignored 元数据，无 tracked 越界。

## 独立只读复核

独立 reviewer 核对当前候选，结论 P0=0、P1=0、P2=0，建议 READY。复核确认：

- 内容区不再显示资源总览玩法卡片或设置分组；
- 资源、设置、退出三项均处于右上常驻工具区并复用真实生产去向；
- 900×720、1280×720、1440×900 测试覆盖无 overflow/异常；
- 无 schema、数值、门控、奖励、叙事或白名单越界。

## 收口判定

代码、测试、审计与真相源均在登记白名单内；READY 标记应建立在本审计提交之上。
main 与 origin/main 未修改、未 push。
