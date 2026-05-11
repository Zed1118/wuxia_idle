# T32 子提交 5 Windows 视觉验收 + 收尾 Handoff

> **状态**：Mac 端代码完工（333/333 全绿），等 Windows Pen 视觉验收反馈。  
> **建立日期**：2026-05-11  
> **下次会话起手必读**：本文件 + `PROGRESS.md` + `phase2_summary.md` 骨架。

---

## 一、当前进度快照

| 项 | 状态 |
|---|---|
| 分支 | `feat/phase2-equipment`（与 origin 同步） |
| 测试 | 333/333 全绿，`flutter analyze` 0 issues |
| 完成子提交 | T32 #22a/#22b/#22c/#22d/#22e/#22f + 子提交 4 |
| 待办 | 子提交 5：Windows 视觉验收 → 填 summary → tag → 合并 main |
| 上次会话最后 commit | `964d39f` phase2_summary 骨架 + PROGRESS 清账 |

---

## 二、Windows Pen 视觉验收 prompt（已发用户，留存备份）

```
你在 Windows 端，wuxia_idle 项目，Mac+DeepSeek 双端协作。本次只做视觉验收，不写代码。

【步骤】
1. cd 到 wuxia_idle 项目目录
2. git fetch && git checkout feat/phase2-equipment && git pull
3. flutter pub get
4. flutter analyze（预期 0 issues）
5. flutter test（预期 333/333 全绿）
6. flutter run -d windows

【验收路径 · 截 6 张图】

启动后看到 MainMenu（5 按钮 + 标题"挂机武侠 · 调试主菜单"）→ 截图 1
按钮顺序：Phase 1 战斗测试 / Phase 2 调试场景 / 角色面板 / 装备仓库 / 心法面板

点「Phase 1 战斗测试」→ 应跳到原 BattleTestMenu 4 场景按钮（A/B/C/D）
→ 返回 → 不截图（回归验证，已知通）

点「Phase 2 调试场景」→ Phase2TestMenu 4 场景按钮 P1/P2/P3/P4 可见 → 截图 2

点「P1 · 强化曲线」→ 跳 InventoryScreen，应看到 1 件 +0 利器·龙泉剑（tier 利器）→ 截图 3
点装备 row → EnhanceDialog 弹出（强化 Tab，磨剑石 1000 / 心血结晶 100 余量）→ 截图 4
（可选）连点强化按钮 5-10 次看成功/失败抖动效果 + 心血结晶涨

返回 MainMenu → 点「Phase 2 调试场景」→ 点「P3 · 散功代价」
→ 跳 TechniquePanelScreen，应看到 1 主修（刚猛/名家功 yuanMan 1500/1500 progress）
+ 1 辅修（阴柔/名家功 daCheng）→ 截图 5
点辅修条尾「设为主修」→ DispelConfirmDialog 弹出
（应显示 内力 10000→5000 / 修炼度 1500→750 / 层回退 warning）→ 截图 6
（可选）点确认散功 → SnackBar「散功完成」 → 主修切换为阴柔，原刚猛回退到 daCheng/750

【可能踩坑】
- Isar dart:ffi web 不支持（挂账 #18），千万别 flutter build web
- Windows desktop 编译首跑慢，正常 1-3 min
- 中文字体 BMP 外字符显示已知问题（T16 已修），如有异常截图反馈

【报告格式】
- 6 截图按编号附上
- 路径不通的步骤指出具体卡点（exception trace / 哪个按钮无反应）
- analyze / test 输出底部 5 行贴出
```

---

## 三、Pen 反馈后的处理路径

### A. 全部通过（无 bug）

1. 把 6 截图存到 `docs/screenshots/phase2/`（目录不存在则建）
2. 填充 `phase2_summary.md`：
   - §二 数值验收表「待填」字段补蒙卡实测百分比 + 截图 Markdown 链接
   - §四 性能基准补 FPS / 强化连点延迟
3. `git tag v0.2.0-phase2`
4. `git checkout main && git merge --no-ff feat/phase2-equipment -m "[merge] Phase 2 装备+心法系统"`
5. `git push origin main --tags`
6. 在 PROGRESS.md 已完成段加一行 "v0.2.0-phase2 tag + main 合并" + 把 T32 整段挪到归档区
7. 写 git tag message 时引用 phase2_summary.md 章节

### B. 有 bug

1. 按 Pen 报告分类：UI 显示 bug / 数据 bug / 性能问题
2. **不要**直接修——先开 plan，跟用户确认修复范围（避免拉低 T32 验收节奏）
3. 修完后单独 commit 标注 `[T32] #22 fixup: <description>`
4. 让 Pen 重跑视觉验收，闭环验收路径回到 A

---

## 四、本次会话改动清单（git log T32 子提交 3-4）

```
964d39f [T32] phase2_summary 骨架 + PROGRESS 清账冲刺压到 90 行
b87826b [T32] 子提交 4 phase2_scenarios_test：4 场景纯数值断言（11 用例）
55914fb [T32] PROGRESS 同步 #22c-#22f 子提交 3 销账
340983f [T32] #22f Phase2TestMenu widget test：销账 T32 子提交 3 收尾
4e3a0f0 [T32] #22e 切 home 入口：BattleTestMenu → MainMenu
461728e [T32] #22d MainMenu + Phase2TestMenu：5 按钮分发 + 4 场景种子入口
1338d58 [T32] #22c Phase2SeedService：4 场景种子工厂 + 真 Isar 落地验收
```

---

## 五、关键决策记录（不要在新会话重新讨论）

- **P2/P4 战斗 stub 决策（B 方案）**：Phase2TestMenu 的 P2/P4 按钮跳 InventoryScreen/CharacterPanelScreen 看 fixture，不跑真战斗。`character_to_battle` 转换 helper 留 Phase 3 接师徒传承一并做。理由：避免子提交 3 体量爆炸，共鸣 99→100 数值正确性已在 phase2_scenarios_test P2 group 3 用例覆盖。
- **角色固定 id=1**：Phase2SeedService 4 个种子都写 `ch.id = 1`，MainMenu / Phase2TestMenu 跳 `CharacterPanelScreen(characterId: 1)` / `TechniquePanelScreen(characterId: 1)` 不查 Isar 取 id。
- **物料行强制创建**：每场景必创 `InventoryItem(moJianShi)` + `InventoryItem(xinXueJieJing)` 两行（即便 quantity=0），匹配 `EnhancementService.persistResult` fail-fast 约定。
- **widget test 不接真 Isar（挂账 #23）**：testWidgets FakeAsync 与 Isar 异步 IO 不兼容，真落地走 service-level test。Phase 5 Riverpod 3.x + IsarProvider 注入时统一。
- **P3 散功 fixture**：主修 `tech_gangmeng_mingjia` yuanMan/1500/progressToNext=1500，辅修 `tech_yinrou_mingjia` daCheng/progressToNext=900。算法对照 `DispelService._recalcLayerByRollback` 文档示例一致，散功后预期 (daCheng, 750) + IF 5000。
- **PROGRESS.md 行数控制**：当前 90 行，下次清账冲刺再压。T28-T31 详条已归档（git log + phase2_tasks.md 都有）。

---

## 六、风险点

- Pen Windows 端首跑 Isar 可能踩 `path_provider` / `IsarSetup.init` 路径问题——本会话 Mac 端测过临时目录路径 OK，Windows 端用 `getApplicationDocumentsDirectory` 应该没问题，但如果 Pen 反馈"启动崩溃"，第一时间检查 IsarSetup 初始化路径
- 截图 5「TechniquePanelScreen 主修/辅修都显示」的渲染依赖 `characterAllTechniquesProvider`，如果种子写完 provider 未 invalidate 可能空白——已在 Phase2TestMenu push 前调 seedPx，理论上 push 后页面首次构建会读最新 Isar 状态
- Mac 端 `flutter test` 全绿不代表 Windows 端 0 issues，Windows Pen 跑 test 前先把 `flutter pub get` 跑全
