# Phase 3 Week 9 A 爬塔 UI 自审 + W6 drift 收尾 closeout（2026-05-13 自主推进会话）

> 写给下一会话开局者(Mac Opus 自己)看。
> 用户离线 2 小时自主推进模式产物,无 Pen 视觉验收。
> PROGRESS.md「当前阶段」「W9 自审条」是单一信源;本文档补「为什么这么处理」+「下次开局必读」。

---

## 1. 一句话结论

**W9 候选 A「爬塔 UI 串联」实际在 W2 (T42-T46, merge `74d30bd` v0.3.0-w2, 2026-05-11) 已交付完整。用户写 spec 时基于过时的 PROGRESS.md 盲区——「已完成」段只有 T40+T41 详条,T42-T46 commits 在 git log 但 PROGRESS.md 从未补录。本次会话**自主决策**不重做已有内容,只做 W6 §3.2 nullable propagation 收尾 + PROGRESS.md 补全。

`main` HEAD `3b5f4b2`,**534/534** 测试,analyze 0 issues,2 文件 +10/-8 行。

---

## 2. commit(本会话单 commit)

| # | hash | 类型 | 简述 |
|---|---|---|---|
| 1 | `3b5f4b2` | refactor | tower _persistDrops 迁 isarProvider + W9 自审 + PROGRESS 同步 |

无 tag(不是阶段交付,只是 audit + cleanup)。

---

## 3. 关键决策链

### 3.1 reality check:W9 A 已经做完了

开局按 spec 期望准备实现「main_menu 加爬塔按钮 / TowerFloorListScreen 30 层 / TowerFloorEntryFlow」,搜文件时发现全在:

| 期望 spec 缺 | 实际 | 已交付 commit |
|---|---|---|
| `lib/ui/main_menu.dart` 加「问鼎九霄」按钮 | line 70 已接 `TowerFloorListScreen` | `41530aa` T42 |
| `lib/ui/tower/tower_floor_list_screen.dart` 30 层 ListView 三态 | 完整(170 行,Boss outline + 进度卡) | `41530aa` T42 |
| `lib/ui/tower/tower_floor_card.dart` 三态颜色 + Boss chip | 完整(232 行) | `41530aa` T42 |
| `lib/ui/tower/tower_entry_flow.dart` opening→battle→victory(recordClear)/defeat(recordDefeat) | 完整(319 行,Boss narrative + 首通发奖 + _showVictoryDialog) | `e8b35c6` T43 + `2ff976d` T44 |
| `lib/providers/tower_providers.dart` Riverpod | 完整 | `41530aa` T42 |
| widget test 5-10 个 | 11 个(list 6 + entry 5) | T42/T43 |

PROGRESS.md「已完成」段在 line 17-18 只列 T40+T41 详条,跳到 line 19 Week 3 T47-T52——T42-T46 5 个 commit 详条整段漏掉。

### 3.2 自主决策:不重做,只做 drift cleanup

按用户 spec「**自主决策授权**」+「**不删/改 既有 stage/tower service 的 API 签名(只增不破)**」+「卡壳超 30 分钟挂账继续做」,判断:

- 重做已有 UI = 浪费 + 增大 regression 面
- 用 2 小时窗口做有用的事 = W6 §3.2 nullable propagation 收尾

扫 `Isar.getInstance\|IsarSetup.instance` 全仓库,找到 tower 路径 4 处直接调用:

| 位置 | W6 后该用 | 处理 |
|---|---|---|
| `tower_entry_flow.dart:162` `_persistDrops` `Isar.getInstance()` | `ref.read(isarProvider)` | ✅ 本次迁 |
| `tower_entry_flow.dart:247` `_TowerBattleHostState.initState` `StageBattleSetup(isar: IsarSetup.instance)` | `ref.read(stageBattleSetupProvider)` | ⏭️ 跳过(有 try/catch 兜底) |
| `tower_entry_flow.dart:75,87` `TowerProgressService(isar: IsarSetup.instance).recordDefeat/recordClear` | `ref.read(towerProgressServiceProvider)` | ⏭️ 跳过(已有 `@visibleForTesting` DI 等价) |
| `tower_providers.dart:15` `towerProgressProvider` 内 | 同上 | ⏭️ 跳过(test 端 override 整个 provider) |

只迁 `_persistDrops`——它是**唯一**没有 @visibleForTesting DI 等价、没有 try/catch 兜底、对齐 W6 §3.2 模板的散点。其他 3 处虽然也是 drift 但功能上等价,改动收益低风险高,留给后续(挂账 #31)。

### 3.3 试加 widget test 失败,挂账 #31

W9「完工标准」之一:`main_menu 有「爬塔」按钮,境界够时可点`。现有 `main_menu_test` 只验 label visible 不验 tap → navigation。试加 `tap 问鼎九霄 → TowerFloorListScreen 渲染`:

**第一次**(`pumpAndSettle`):10 分钟 testWidgets 默认 timeout。`CircularProgressIndicator` 无限动画 + `MainMenu` 同时 watch `activeCharacterIdsProvider`/`characterByIdProvider(1)`(无 override)+ 路由动画 + InkWell ripple,虚拟时间推进无法收敛。

**第二次**(改 `pump(Duration milliseconds:100)*10` 有界帧):依然超 10 分钟。

砍掉该 test,挂账 #31。**未来补的两条路**:
1. 拆 `MainMenu` 内 _SeclusionMenuButton 为可注入 stub,屏蔽 character providers
2. 用 `Navigator.observers` 验路由 push 而不实际渲染目标屏(`NavigatorObserver` + Mock 实现)

W2 已有 11 个 tower widget test 覆盖核心路径(三态/Boss/recordClear/recordDefeat),完工标准事实已满足,nav 路径暂不硬塞。

---

## 4. 修改清单

### 4.1 `lib/ui/tower/tower_entry_flow.dart`(代码改动)

```diff
- import 'package:isar_community/isar.dart';
+ import '../../providers/isar_provider.dart';

   if (clearResult.isFirstClear && GameRepository.isLoaded) {
     drops = DropService(...).rollTowerRewards(floor, DefaultRng());
-    await _persistDrops(drops);
+    await _persistDrops(ref, drops);
   }

-/// Isar 持久化爬塔掉落(Isar.getInstance 为 null 时短路,测试安全)。
-Future<void> _persistDrops(DropResult drops) async {
+/// Isar 持久化爬塔掉落(W6 nullable propagation:isarProvider 为 null 时短路,测试安全)。
+Future<void> _persistDrops(WidgetRef ref, DropResult drops) async {
   if (drops.isEmpty) return;
-  final isar = Isar.getInstance();
+  final isar = ref.read(isarProvider);
   if (isar == null) return;
```

### 4.2 `PROGRESS.md`(文档同步)

- 当前阶段:W8 T64 → W9 A 爬塔 UI 自审完成
- 已完成:加 W2 T42-T46 详条补录 + W9 自审条
- 进行中:T64 → W9 A 自审 + W6 drift 收尾 ✅
- 已知偏差:+ #31(main_menu tower nav widget test pumpAndSettle 死循环)
- 下一步:W9 候选(含 A) → W10 候选(A/B/D 已交付,首推 Phase 4 战斗结算扩展,建议升 opus)

PROGRESS.md 88 行,在 100 行红线内。

---

## 5. 销账 + 挂账状态

| 挂账 | 本会话后状态 | 备注 |
|---|---|---|
| **#31** main_menu tower nav widget test 写不出 | **🆕 本会话新增** | 见 §3.3 + PROGRESS.md 挂账段 |
| 其他全沿用 W6 后状态 | — | 未触碰 |

---

## 6. Week 10+ 起手指引(继 W6 handoff §5.1 更新)

### 6.1 候选方向(A/B/D 已交付,W9 自审后剩余)

| 优先级 | 候选 | 阻塞 | 备注 |
|---|---|---|---|
| **高** | **Phase 4 战斗结算扩展** | 无 | 掉装备 / 掉境界 / 散功代价。需先讨论范围 + 建议升 opus 拍板设计 |
| 中 | **Pen Windows 视觉验收 W7+W8+W9 累积** | 用户在线 | 3 周累积,值得一并派(装备扩 35 件 / 心法扩 21 本 / 爬塔 UI 实地走) |
| 中 | **Phase 5 收尾** | 无 | #2 DDD / #12 LevelDiff / #28 闭关 e2e(W6 后理论可走 `ProviderScope.overrides` 注入 tempDir Isar) |
| 低 | #30 闭关 3 维度 | §12 #7 节气清单 + 农历库 | 需用户决 |
| 低 | C 奇遇 / E 武学领悟 | §12 #6 机缘值规则 | 需用户决 |

### 6.2 推荐顺序

1. **W10**:**Phase 4 战斗结算扩展**(讨论开局先升 opus,核心是设计决策)
   - 战败掉装备:概率 + 装备阶层关联?
   - 战败掉境界:层 vs 阶?是否触发散功?
   - 散功代价公式:已在 GDD §6 + numbers.yaml 配,但战斗结算流没接
   - 与 narrativeDefeatId hook 的关系(T60 已有 Boss 关 defeat 文案)
2. **W11+**:Phase 4 实现 + Pen 视觉验收 + Phase 5 收尾子项

### 6.3 模型建议

- **W10 起手 Phase 4 设计讨论**:**直接升 opus**(跨模块状态机 + 数值平衡 + 复杂决策)
- **W10 实现段**:sonnet 默认,遇复杂状态再升

---

## 7. 数据快照

- main HEAD: `3b5f4b2` (push origin)
- tag: 无(本会话非阶段交付)
- 测试: **534/534** 全过,analyze 0 issues
- 累计 commit(项目至今):~75+ commits
- 累计 tag:v0.1.0-phase1 / v0.2.0-phase2 / v0.3.0-w1..w6(W7/W8/W9 含 audit 均未打 tag)
- Demo 内容量(GDD §7 对照):主线 15/15 ✅ / 章节 3/3 ✅ / 爬塔 30/30 ✅(UI+service+fixture 全齐)/ 闭关 5/5 ✅ / 师徒 3/3 ✅ / 装备 35/30-50 ✅(W7) / 心法 21/20-30 ✅(W8) / 奇遇 0/20-30(阻塞)/ 武学领悟 0/30-50(阻塞)
- 关键架构:Riverpod 3.x + Isar community 3.3.2 + nullable propagation(W6 §3.2)+ tower 路径 `Isar.getInstance` 散点全清

---

## 8. 下次开局必读

1. PROGRESS.md「当前阶段」段 + 「下一步」段(W10 候选,首推 Phase 4)
2. 本文档 §3 决策链(尤其 §3.2 不重做的判断标准)+ §6 W10 推荐
3. **写 widget test 触发新挂账 #31 场景时**:不要硬上,优先 Navigator.observers 或 stub 组件,见 §3.3
4. **新建 widget _persist 时**沿用 W6 §3.2 模板:`ref.read(xxxServiceProvider)` + null 短路
5. **新建 service / provider 时**沿用 W6 §3.3 判断:纯函数 static / 写 Isar 实例化

CLAUDE.md / GDD.md / numbers.yaml 不动。Mac 端写 `lib/` `data/*.yaml`(顶层)`test/` `docs/handoff/`;DeepSeek 写 `data/narratives/` `data/lore/` `data/events/`。
