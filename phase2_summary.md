# Phase 2 交付总结

> **状态**：v0.2.0-phase2 交付（T32 子提交 5 视觉验收 2026-05-11 完成）。

**里程碑**：v0.2.0-phase2（2026-05-11 tag）  
**范围**：T19-T32，装备系统 + 心法系统 + 战斗联动 + 4 调试场景验收

---

## 一、交付功能清单

| 任务 | 交付物 |
|---|---|
| T19 | EquipmentFactory 装备生成 + Rng 抽象（固定种子可复现 / 蒙卡区间） |
| T20 | EnhancementService 强化 +1-+49 + 心血结晶保底（4 段成功率 / penalty half-full） |
| T21 | ForgingService 开锋 3 槽 + EquipmentDef.specialSkillCandidates（unlock / 互斥 / 校验） |
| T22 | 装备战斗加成整合 + 师承内力上限 +5%/件 + 11 战例验收（+0/+12/+19/+49 / 师承 0-4 件） |
| T23 | TechniqueLearningService 4 类校验 fail-fast（tier 上限 / 主修存在 / 辅修槽满 / 领悟点） |
| T24 | CultivationService 修炼度累积 + progressToNext yaml 化（jiJing 封顶 6500） |
| T25 | DispelService 散功（算法 A）：progress×0.5 + layer 反向回退 + 内力×0.5 in-place |
| T26 | BattleResolutionService 纯函数（装备 battleCount++ / 主修 CultivationService / 辅修计数） |
| T27 | DropService 装备掉落 + sealed class DropEntry + StageDef.dropTable yaml |
| T28 | 角色面板 UI：4 块布局 + 主修/辅修标签 + cultivationLayer + 速度无主修兜底 |
| T29 | 装备仓库 UI + EnhanceDialog（预览 / 强化按钮 / 保底按钮 / shake / 金光） |
| T30 | 开锋 UI：TabBar 切换强化/开锋 + ForgingPanel 3 槽 + 词条 AlertDialog 二确 |
| T31 | 心法面板 UI + DispelConfirmDialog（三行代价 / 层回退 warning / 二确） |
| T32 #22a-b | service.persistResult writeTxn：销账强化/开锋/散功的 widget→Isar 落地 |
| T32 #22c | Phase2SeedService 4 场景种子工厂（writeTxn 清表 + 物料行 fail-fast 兼容） |
| T32 #22d | MainMenu 5 按钮分发 + Phase2TestMenu 4 场景按钮入口 |
| T32 #22e | main.dart home 切 BattleTestMenu → MainMenu |
| T32 #22f | Phase2TestMenu widget test + SnackBar 兜底验证 |
| T32 子提交 4 | phase2_scenarios_test.dart 11 用例 4 场景纯数值断言 |

**测试覆盖**：333 个测试，全部通过（待 Pen Windows 视觉验收 5-6 截图补 spec §507）。

---

## 二、数值验收（4 调试场景实测对照）

> 数据来源：`test/services/phase2_scenarios_test.dart` 11 用例。

| 场景 | 关键断言 | 预期 | 实测 | 误差 |
|---|---|---|---|---|
| P1 强化曲线 | +1-10 段固定 100% 成功（10 次蒙卡 0 失败） | 100% | 100% | 0% |
| P1 强化曲线 | +14-15 蒙卡 1000 次成功率 ≈ 75% | 0.70-0.80 | 0.759 (seed=42) | 1.2% |
| P1 强化曲线 | cap=19 时 +0→+19 走完 + 第 20 次 capped | capped | capped | — |
| P2 共鸣触发 | battleCount=99 → shengShu / bonus=1.0 | 1.00 | 1.00 | 0% |
| P2 共鸣触发 | battleCount=100 → chenShou / bonus=1.10 | 1.10 | 1.10 | 0% |
| P2 共鸣触发 | effectiveAttack 99→100 +10% | base×1.10 | base×1.10 | 0% |
| P3 散功代价 | yuanMan/1500 + IF 10000 → daCheng/750 + IF 5000 | spec §502 | 命中 | 0% |
| P3 散功代价 | 主修易主 + 旧主修变辅修 + 层回退 1 + progressToNext 重设 900 | spec §502 | 命中 | 0% |
| P4 全栈对比 | +19 强化裸装 = base × 1.95 | 195 | 195 | 0% |
| P4 全栈对比 | +19 + xinJianTongLing(×1.30) = base × 2.535 | 253 | 253 | 0% |
| P4 全栈对比 | 全栈 (+ forge attack +15%) ≈ base × 2.915，比裸装 2.92× | 291 / 2.92× | 命中 | 0% |

### 视觉验收（Windows Pen，2026-05-11，6 截图）

| # | 截图 | 关键验收点 | 结论 |
|---|---|---|---|
| 1 | [MainMenu](docs/screenshots/phase2/01_main_menu.png) | 标题「挂机武侠·调试主菜单」+ 5 按钮顺序 + 副标题摘要 | ✅ |
| 2 | [Phase2TestMenu](docs/screenshots/phase2/02_phase2_test_menu.png) | P1/P2/P3/P4 4 场景按钮 + 种子摘要副标题 | ✅ |
| 3 | [P1 装备仓库](docs/screenshots/phase2/03_p1_inventory.png) | 利器(1) / +0 / tier 金色 / 「生疏」开锋状态 | ⚠️ 装备名未渲染（见挂账 #24） |
| 4 | [P1 强化弹窗](docs/screenshots/phase2/04_p1_enhance_dialog.png) | 强化/开锋 Tab / 100% 成功率 / 磨剑石 1000 / 心血结晶 100 / +0→+1 预览 | ✅ 数值全对（装备名同 #24） |
| 5 | [P3 心法面板](docs/screenshots/phase2/05_p3_technique_panel.png) | 主修刚猛/圆满 1500/1500 + 辅修阴柔/大成 0/900 + 设为主修按钮 | ✅ |
| 6 | [P3 散功二确](docs/screenshots/phase2/06_p3_dispel_dialog.png) | 内力 10000→5000 / 修炼度 1500→750 / 红字层回退 warning / 取消+确认散功 | ✅ |

---

## 三、已知问题 / Phase 3 待办

| # | 问题 | 优先级 | 备注 |
|---|---|---|---|
| #22 P2/P4 战斗 stub | Phase2TestMenu P2/P4 跳 InventoryScreen/CharacterPanel 看 fixture | 中 | character_to_battle 转换 helper 留 Phase 3 接师徒传承一并做 |
| #23 widget test 不接真 Isar | testWidgets FakeAsync 与 Isar 异步 IO 不兼容 | 中 | Phase 5 Riverpod 3.x + IsarProvider 注入时统一 |
| #24 装备名未渲染 | inventory_row + enhance_dialog 显示「武器」而非「龙泉剑」（EquipmentDef.name 未接 UI） | 中 | T32 子提交 5 Pen 视觉验收发现，不影响数值/流程，Phase 3 起手第一个 fixup |
| #2 lib/ 目录 flat vs CLAUDE.md DDD | — | 低 | Phase 5 整理 |
| #4 IDS_REGISTRY.md 自报错（143 vs 实际 238） | — | 低 | 等 DeepSeek 改 |
| #18 flutter build web 被 Isar dart:ffi 阻塞 | — | 中 | Phase 5 切 Isar 4.x |
| #21 shake / tier 颜色 / 金光 helper 未抽 | — | 低 | Phase 5 抽 effects/screen_shake.dart + theme/tier_colors.dart |

> 已解决挂账（Phase 1 + Phase 2 期间）：#1/#5/#13/#14/#15/#16/#19/#20/#22a-f 见 PROGRESS.md 归档区。

---

## 四、性能基准

| 指标 | 实测（Mac M 芯片，debug 模式） |
|---|---|
| 全量测试套件（333 用例）运行时长 | ~8 秒 |
| Phase 2 场景测试（phase2_scenarios_test，11 用例） | <1 秒（纯数值，无 Isar） |
| Phase 2 service 真 Isar 测试（4 个 \*\_persist\_test，13 用例） | ~2 秒（含 setUp/tearDown Isar 启停） |
| `flutter analyze` | 0 issues（~2 秒） |
| 战斗 UI 动画 FPS / 强化 100 连点延迟 | 暂未采集（本次仅做视觉验收，FPS profiler 留 Phase 3 接入） |

---

## 五、后续阶段一句话概览

- **Phase 3**（下一阶段）：主线关卡 / 爬塔 / 闭关地图 / 奇遇事件 / 师徒传承 / 武学领悟 / 角色生成（属性 roll）/ 心法相生组合
- **Phase 4**：接 DeepSeek 文案 + 剧情 + 新手引导 + "昨晚发生的事"摘要 UI
- **Phase 5**：迁 Isar 4.x / Riverpod 3.x / 美术 AI 出图 / MSIX 打包 / shake/tier_colors helper 抽

---

## 六、分支与合并策略

- **三分支**：feat/phase2-equipment（本分支，T19-T32 全部 commits）
- **合并方式**：`git merge --no-ff feat/phase2-equipment` 到 main（与 Phase 1 同策略，保留 phase 边界）
- **tag**：`v0.2.0-phase2` 打在 merge commit 上
