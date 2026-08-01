# 战斗界面样板还原度 95+ 实施计划

> 日期：2026-08-01<br>
> 状态：**已复核待实施**（本轮只完成外审 triage、计划与 worktree 初始化）<br>
> 基点：`main@acc31ee8`<br>
> 分支：`codex/battle-ui-fidelity-95`<br>
> worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-ui-fidelity-95`<br>
> 修复规格：`docs/spec/2026-08-01-battle-ui-sample-fidelity-95-repair-report.md`

## 1. 目标与完成定义

把战斗界面从当前黄金帧 `81/100`、生产泛化 `72/100` 提升到二者分别 `>=95/100`；
最终分继续取 `min(G, P)`，不得用黄金 fixture 抵消生产路由缺陷。

完成必须同时具备：

- 黄金帧 G1-G5 复评 `>=95`，各核心分项得分率 `>=90%`；
- 生产泛化 P1-P5 复评 `>=95`，各核心分项得分率 `>=90%`；
- 一票否决项全部通过；
- 1280x720、1440x900、1672x941 三视口与五类生产场景有截图证据；
- 全量测试、静态分析、红线扫描、残留扫描全部通过；
- Codex 人工视觉复核与用户终拍通过；
- 不误提交 `.g.dart`、capture、日志和临时 probe。

## 2. 已完成的外审 triage

附录 A 已按 `CLAUDE.md §8.2` 先证伪后采纳，结论为 3 条成立、4 条部分成立、0 条未验证照收：

| 项 | 判定 | 已进入正文的约束 |
|---|---|---|
| A.1 | 成立 | `HpBar` 仅 4 个生产调用点，直接统一本体，不建战场专用分支 |
| A.2 | 成立 | 顶部保留单一主警报；角色层保留暗绛小印，增加双/三敌同步蓄势 Gate |
| A.3 | 部分成立 | 新增纯程序化断魂庄场景，但不预设它是“最极端浮贴”象限 |
| A.4 | 成立 | 守住 gauntlet audit 的 `sceneBackgroundPath == null` 与 boss BGM 契约 |
| A.5 | 部分成立 | 保留 before/hash；按 ROI/允许变化 mask 做 diff，不要求有意改动区域全屏 0 像素 |
| A.6 | 部分成立 | 基线更新到 4792 tests、79 routes、`acc31ee8`；commit 数应为 8，不是 5 |
| A.7 | 部分成立 | MAE/IoU 不证明 G3；bbox/面积比仅作辅证，人工评分与用户终拍作最终判断 |

完整命令输出、反证与取舍见修复规格附录 A；实施时不得只看汇总表跳过证据。

## 3. 边界与禁改项

- 不改母版 `docs/spec/battle_ui_stage_command_desk_v2_2026-07-15.png` 来迁就 current。
- 不给 `battle_audit_gauntlet*` 人工补 `sceneBackgroundPath`；生产入口本来就是纯程序化背景。
- 不复活 Boss 常驻 warning 图标、行囊自动填满、debug tree 大改等 rejected task。
- 不新增独立 `HpBar` battle style；先统一组件本体，除非后续出现新的真实复用反证。
- 不把固定 audit fixture 的专用人物/七签/行囊丰富度计入生产泛化分。
- 不用全局 MAE/IoU 单独宣称 95，不用黑盒总分覆盖人工量表。
- 不在 Dart 中新增中文文案或散写战斗数值；不改玩法、平衡、存档 schema。
- 每个实施切片只解决一个视觉问题簇，验证通过后小提交；提交信息使用中文动宾。

## 4. 可恢复切片

### 切片 0：把视觉验收工具变成可信证据

**目标**：reference/current 真正分离，截图、清单、诊断层与差异报告可复现。

**主要文件**：

- `tools/visual_capture/analyze_battle_v2_fidelity.py`
- `tools/visual_capture/visual_capture.sh`
- `test/tools/visual_capture_test.py`
- `test/features/debug/application/visual_acceptance_plan_test.dart`
- `test/features/debug/visual_acceptance_gauntlet_coverage_test.dart`
- `test/features/debug/visual_route_test.dart`

**步骤**：

1. 先写失败测试，证明 reference 与 current 同图/同路径会被拒绝。
2. 固化 reference SHA-256、capture manifest、路由、视口、commit 与时间戳。
3. 让 analyzer 输出全场 MAE、边缘 IoU、语义区域、人物 bbox/面积/Boss 比例及 unavailable 原因。
4. 增加 ROI/允许变化 mask 的 before/after 比较；只对明确未改区域允许 `changed_pixels == 0` Gate。
5. 保持 gauntlet audit 的 null background 与 boss BGM 断言。

**Gate**：工具测试全绿；交换 current/reference 可观察到合理差异；manifest 缺层时明确失败或降级，
不得静默给高分。

**建议提交**：`校准战斗视觉验收证据`

### 切片 1：公共 HUD 去现代化并守住多敌蓄势信息

**目标**：血条、蓄势警报、Boss 数字环与样板统一，同时不丢双/三敌蓄势信息。

**主要文件**：

- `lib/features/battle/presentation/widgets/hp_bar.dart`
- `lib/features/battle/presentation/widgets/character_avatar.dart`
- `lib/features/battle/presentation/widgets/battle_banners.dart`
- 对应 widget/golden/语义测试

**步骤**：

1. 以失败测试锁定 4 个 `HpBar` 调用点和目标几何/材质，直接统一组件本体。
2. 顶部横幅继续显示最临近的一个主警报；每个蓄势角色显示不抢脸的暗绛小印。
3. 建立可重复双敌与三敌同步蓄势 fixture，覆盖心魔镜像真实生产语义。
4. 检查窄视口、Boss、受击、空血、长名字与可访问语义。

**Gate**：双/三敌蓄势时每个蓄势者均可辨认；顶部信息不重叠；`HpBar` 无分支漂移；
相关 widget/golden/route 测试通过。

**建议提交**：`统一战斗血条与蓄势提示`

### 切片 2：统一案台响应式语言

**目标**：1280x720 不再整套换皮，1440/1672 保持同一材质、层级和签牌语言。

**主要文件**：

- `lib/features/battle/presentation/widgets/stage_command_desk.dart`
- `lib/features/battle/presentation/widgets/skill_command_strip.dart`
- `lib/features/battle/presentation/widgets/battle_pouch.dart`
- `lib/features/battle/presentation/battle_screen.dart`
- 对应 layout/widget/golden 测试

**步骤**：

1. 用连续尺寸预算替代 `height >= 190` 一刀切换皮。
2. 保住名帖、七签、朱印、耗气与行囊层级；只压缩间距与次级装饰。
3. 覆盖七签、少签、长技能名、禁用、冷却、自动战斗与战备空态。

**Gate**：三个正式视口无 overflow、遮挡或语义丢失；设计语言连续；G4 人工评分达到目标。

**建议提交**：`统一战斗案台响应式布局`

### 切片 3：提升人物与场景的量产融合

**目标**：不同美术背景、纯程序化背景、Boss、3v3 与群战均有稳定接地和景深。

**主要文件**：

- `lib/features/battle/presentation/widgets/character_avatar.dart`
- `lib/features/battle/presentation/widgets/battle_scene_background.dart`
- `lib/features/battle/presentation/widgets/battlefield.dart`
- `lib/features/debug/application/visual_acceptance_plan.dart`
- `lib/features/debug/application/visual_route.dart`
- 对应视觉 route 与测试

**代表矩阵**：

| 类别 | 路由 | 必拍视口 |
|---|---|---|
| 黄金 fixture | `battle_tap_live` | 1280、1440、1672 |
| 常规主线 | 报告 §8.2 指定 mainline route | 1280、1440 |
| 高明度/强结构 | 报告 §8.2 指定 tower route | 1280、1440 |
| 多人/群战 | 报告 §8.2 指定 3v3 route | 1280、1440 |
| 纯程序化 | `battle_audit_gauntlet_02` | 1280、1440 |

**步骤**：

1. 保存每条 before 与 SHA-256，再实施轮廓、明度、接地、遮罩和景深调整。
2. 逐路由按人物/HUD/背景 ROI 生成 after/diff；记录允许变化与意外变化。
3. 人物 bbox、面积比、暗部 P05 只作机器辅证；结合母版进行 Codex 人工 G3/P2 评分。
4. 纯程序化 gauntlet 不补假背景，专门检查暗部融合、护法结界 tag 与 3v3 密度。

**Gate**：五类矩阵无浮贴、脚底悬空、轮廓吃没或背景抢脸；MAE/IoU 防回退通过；
G3/P2 必须由人工评分与用户终拍确认，机器绿不自动算 95。

**建议提交**：`改善战斗人物与场景融合`

### 切片 4：动态状态与桌面交互终验

**目标**：静态终帧之外，动态战斗和桌面操作没有视觉或交互回归。

**覆盖状态**：普攻、受击、暴击、蓄势、双/三敌蓄势、破招、Boss、濒死、胜负、暂停、
技能 hover/点击、键鼠焦点、窗口缩放。

**步骤**：

1. 跑生产 fixture 与真实战斗路径，检查动画期间布局稳定和提示优先级。
2. 运行三个视口和五类场景的最终截图矩阵。
3. 按 G/P 量表独立打分，列出剩余扣分；任一项不到门槛则回到对应切片。
4. 由用户完成最终终拍，不以实现者自评代替。

**Gate**：G、P 分别 `>=95`；动态语义清晰；用户终拍通过；一票否决项为零。

**建议提交**：`完成战斗样板九十五分验收`

## 5. 每切片固定验证模板

```bash
# fresh worktree 初始化（已完成；.g.dart 均被忽略）
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 静态与目标测试
flutter analyze --no-pub
flutter test --no-pub <本切片相关测试>

# audit route 契约
flutter test --no-pub \
  test/features/debug/application/visual_acceptance_plan_test.dart \
  test/features/debug/visual_acceptance_gauntlet_coverage_test.dart \
  test/features/debug/visual_route_test.dart

# 收口
flutter test --no-pub --reporter compact
git diff --check
git status --short
```

每切片另做：

- 数值/文案/高频日志/残留扫描；
- 1280x720 与 1440x900 真实截图，影响黄金构图时再加 1672x941；
- 保存 manifest、SHA-256、before/after 与人工评分；
- 明确记录未运行的验证及剩余风险，不得用“应该没问题”替代证据。

## 6. 当前基线与恢复点

**已完成**：

- 报告附录 A 七项逐条独立复核，成立部分已合并进正文；
- 桌面报告状态更新为“已复核待实施”，代码态更新为 `acc31ee8`；
- 创建分支 `codex/battle-ui-fidelity-95` 和独立 worktree；
- `flutter pub get` 完成；
- `dart run build_runner build --delete-conflicting-outputs` 完成，写出 128 个 gitignored outputs；
- `flutter analyze --no-pub`：`No issues found`；
- 主 checkout 同一 HEAD 的全量基线：`+4792: All tests passed!`；
- battle visual acceptance route 容量：79（73 dynamic + 6 deterministic）。

**下一步唯一入口**：从“切片 0：把视觉验收工具变成可信证据”开始，先写 reference/current
同图拒绝的失败测试；本轮没有修改任何战斗代码、数据或资产。

**已知风险**：

- 主 checkout 原先已有未跟踪文件
  `docs/spec/2026-08-01-battle-ui-sample-fidelity-95-repair-report.md`；它属于用户既有内容，
  不删除、不覆盖。复核版只在本分支 worktree 中纳入跟踪。
- `--delete-conflicting-outputs` 在当前 build_runner 版本已被忽略，但生成成功。
- 断魂庄旧 before 目录 `build/visual_acceptance/gauntlet_audit_20260801/` 实际不存在；
  triage 新抓图只作事实核查，正式实施需按统一 manifest 重建 before 基线。

## 7. 合并前 `CLAUDE.md §8.2` Gate

- [ ] 生产验证证据齐全，不只跑固定 fixture；
- [ ] targeted tests 覆盖本切片真实改动；
- [ ] 红线检查通过；
- [ ] 残留项与已知风险有明确结论；
- [ ] 1280x720、1440x900，必要时 1672x941 的 UI 证据齐全；
- [ ] 所有新外审意见先进入 triage，先证伪再采纳；
- [ ] 无中文文案/数值常量散写进 Dart；
- [ ] 无高频 `debugPrint`、`.g.dart`、capture、log 或临时 probe 误提交；
- [ ] commit message 使用中文动宾；
- [ ] 用户终拍通过后才可标记 READY。
