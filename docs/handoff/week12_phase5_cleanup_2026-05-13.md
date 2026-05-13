# Phase 5 收尾 #12 销账 + #28 探路终结（2026-05-13 W12 会话）

> 写给下一会话开局者（Mac Opus 自己）看。
> 用户接 W11 closeout 后继续 W12，本会话两阶段：
>   阶段 1（high）：#12 LevelDiff 语义统一销账
>   阶段 2（xhigh）：#28 闭关 widget e2e 探路 5 轮失败 → 终结判不可解
> PROGRESS.md「当前阶段」/「已知偏差 #28」是单一信源；本文档补「为什么 #28 这条路走不通」+「真要解的工作量边界」+「下次开局必读」。

---

## 1. 一句话结论

W12 是 Phase 5 收尾**整理性会话**，无代码新功能。#12 LevelDiff 数据层 vs 公式层语义统一（commit `0771c90`），#28 闭关 widget e2e 经 xhigh 5 轮 fake_async 边界探路确认不可解，挂账描述更新（commit `fb6d777`）。`main` HEAD `fb6d777`，**546/546** 测试保持，analyze 0 issues。

---

## 2. commit 列表（本会话 2 个）

| # | hash | 类型 | 简述 |
|---|---|---|---|
| 1 | `0771c90` | refactor | phase5 LevelDiff 数据层与公式层语义统一（销账 #12） |
| 2 | `fb6d777` | docs | #28 探路终结判不可解（W6 后 5 轮 fake_async 边界失败） |

无 tag。

---

## 3. #12 关键设计决策

### 3.1 数据层兜底 `2.5 → 1.0`

**原状**：`numbers.yaml` `diff_3_or_more.attacker: null`，`LevelDiffModifier.fromYaml` 兜底 `?? diff2.attacker(=2.5)`。

**问题**：数据层兜底值（2.5）与公式层 `RealmUtils.realmDiffModifier` 硬编码 `1.0`（GDD §5.5「已碾压无须放大」）语义割裂。两端都「正确」，但数据层兜底字段实际无人读，是数据真空，未来误读会出 bug。

**改造**：数据层兜底改 `1.0`（单位元），公式层 switch 第 4 分支统一走 `mod.diff3OrMore`，删除「公式层硬编码 1.0 / 不读字段」特例。

**结果**：两端语义统一，yaml 表达式仍保 `null`（兜底逻辑保留），运行时行为零变化（之前公式层就取 1.0，现在数据层兜底也是 1.0）。

### 3.2 为什么不改 yaml 直接写 1.0

yaml 保留 `null` 表达「设计上无定义，因为已被碾压不需要数值放大」的语义意图；数据层兜底 1.0 是「字段非空契约」。两层信息互补，不冗余。

---

## 4. #28 关键诊断（5 轮失败根因 + 真解路径）

### 4.1 起步设计与挂账描述偏差

挂账原描述：「W6 service 注入后理论可走 `ProviderScope.overrides` 注入 tempDir Isar」。

**实际入手发现**：3 屏（`SeclusionMapListScreen` / `SeclusionSetupScreen` / `ActiveRetreatScreen`）**直接走 `IsarSetup.instance` 单例**，不走 `seclusionServiceProvider`（W6 drift）。所以 `ProviderScope.overrides` 不起作用，唯一可行的「测试侧注真 Isar」方式是 setUp 内 `IsarSetup.init(tempDir)` —— 屏会读到这个真 Isar。

### 4.2 5 轮失败路径

| 轮 | 改动 | 结果 |
|---|---|---|
| 1 | `pumpAndSettle()` 全程 | 10min timeout，tap 山林后 setup 不出现 |
| 2 | 引入 `settle = runAsync(Future.delayed(150ms)) + pump×6` | 同 1，6s 内直接 expect fail |
| 3 | `find.text('山林')` → `find.ancestor(InkWell)` | 同 2，InkWell 找到了但 tap 仍无效 |
| 4 | `settle` 加长（200ms + pump×8 × 100ms） | 同 3，1s 报错 |
| 5 | 嵌入诊断 reason（InkWell 总数 / tap 后 list/setup/snack count） | print 被 reporter 抑制看不到，testWidgets 10min 超时 |

### 4.3 根因（fake_async vs native Isar zone 边界）

```
testWidgets 体 (fake_async zone)
  └─ pumpWidget → initState
      └─ _activeFuture = SeclusionService.getActiveSession(...)  // ← 在 fake_async zone 创建
          └─ Isar query 是 native ffi 调用，completion 由 root zone 触发

tap → _onMapTap (async)
  └─ await _activeFuture                                          // ← 创建 zone 是 fake_async
                                                                      completion callback 必须派发回 fake_async
  └─ Navigator.push(SetupScreen)                                  // ← 永远到不了
```

`tester.runAsync(Future.delayed)` 切到真实 zone 跑时间，让 Isar native 操作有机会完成，但 future 完成的 dart-side 回调要派发回**创建 zone**（fake_async）；fake_async 不消费这种跨 zone 派发的 microtask（或消费但未在 `pump` 期间被推进） → `await` 永远 stuck → push 不发生 → 内部 10min testWidgets timeout。

这是 `flutter_test` 框架结构性限制，不是 settle 长度或 finder 命中问题（v4 1s 内就报错排除了时长不够）。

### 4.4 真要解 #28 的工作量边界

| 必做 | 工作量 |
|---|---|
| ① 3 屏改 `ConsumerStatefulWidget` + 全部走 `ref.read(seclusionServiceProvider)` | ~50 行 diff |
| ② 抽 `SeclusionServiceContract` abstract（让 provider 可注非 Isar fake） | service 层重构，~80 行 |
| ③ e2e widget test 用 fake service（纯 fake_async 内完成） | ~200 行 |
| **合计** | **~330 行 / 跨 service + provider + 3 屏 + test，xhigh 1-2 轮** |

这是 W6 drift 完整收尾 + service interface 重构，属 Phase 5 #2 DDD 整理级，**不在 #28 单挂账原范围**。用户拍板放弃 #28，留 Pen 视觉验收兜底（list+setup 屏渲染已有 `seclusion_map_list_screen_test` 覆盖）。

### 4.5 给未来开局者的 "Don't"

- 不要再 try `tester.runAsync` + 真 Isar 路径，5 轮已穷尽
- 不要被 PROGRESS.md 早期描述「W6 后理论可走」误导，那个理论错了（W6 只解了 service 层注入，没解 widget 端注入）
- 如果决定真解 #28，先做 4.4 的 ①②③，**绑成一个 xhigh 工程**而不是单挂账

---

## 5. 销账 + 挂账状态

| 挂账 | 本会话后状态 | 备注 |
|---|---|---|
| **#12** LevelDiffModifier 数据层 vs 公式层语义不同 | **✅ 销账** | 数据层兜底 1.0 + 公式层统一查表 |
| **#28** 闭关 widget 端到端 test 缺失 | **挂账描述更新（不销）** | xhigh 5 轮探路确认不可解；真解需 Phase 5 DDD 级工程；留 Pen 兜底 |

其他挂账状态沿用 W11 closeout 后。

---

## 6. Pen 视觉验收

**本会话无新增视觉验收点**。W7-W11 累积 Pen 验收待派（详 `week11_victory_resolution_2026-05-13.md` §6）。

---

## 7. Week 13+ 起手指引

### 7.1 候选方向（按可推进度排序）

| 优先级 | 候选 | 阻塞 | 模型建议 |
|---|---|---|---|
| **高** | **Pen Windows 视觉验收 W7-W11 五周累积一并派** | 用户在线 | n/a |
| **中** | **Phase 5 #2 DDD 目录整理**（顺手做 + 屏 Consumer 化收尾 → 可重新捡回 #28） | 需先讨论范围 | xhigh |
| 低 | #30 闭关 3 维度 | §12 #7 节气清单 + 农历库 | 需用户决 + high |
| 低 | C 奇遇 / E 武学领悟 | §12 #6 机缘值规则 | 需用户决 + xhigh |

### 7.2 不要做

- 不要再单独尝试 #28（5 轮探路已锁死，要做就和 DDD 整理捆绑）
- 不要修 PROGRESS.md #28 描述回老话（「W6 后理论可走」），那个描述被实测推翻

### 7.3 模型选型建议

- **Pen 验收派单**：n/a（用户跑 Pen）
- **Phase 5 #2 DDD 整理**：先和用户讨论范围 + 拆分边界，**xhigh** 起步
- **#30 闭关 3 维度**：先解 §12 #7 节气清单决策，再 **high** 落实数值
- **C/E 奇遇 / 武学领悟**：§12 #6 机缘值规则先决，**xhigh** 系统接入

---

## 8. 数据快照

- main HEAD: `fb6d777`（push pending 用户决定）
- tag: 无（待 Pen 视觉验收 W7-W11 累积一并打 v0.4.0-w11）
- 测试: **546/546** 全过，analyze 0 issues
- 累计 commit（项目至今）：~79 commits
- 累计 tag：v0.1.0-phase1 / v0.2.0-phase2 / v0.3.0-w1..w6（W7-W12 累积未打）
- Demo 内容量（GDD §7 对照）：主线 15/15 ✅ / 章节 3/3 ✅ / 爬塔 30/30 ✅ / 闭关 5/5 ✅ / 师徒 3/3 ✅ / 装备 35/30-50 ✅ / 心法 21/20-30 ✅ / 奇遇 0/20-30（阻塞）/ 武学领悟 0/30-50（阻塞）
- 关键架构：Riverpod 3.x + Isar community 3.3.2 + nullable propagation（W6）+ Boss 战败被动散功（W10）+ victory 双端接 resolveBattle（W11）+ LevelDiff 数据层/公式层语义统一（W12）

---

## 9. 下次开局必读

1. PROGRESS.md「当前阶段」+「已知偏差 #28」段（W6 drift + fake_async 边界）+「下一步」段（W13 候选）
2. 本文档 §4 #28 5 轮失败根因 —— **避免重蹈覆辙**
3. 本文档 §7.1 W13 候选 + 模型建议
4. **写 widget test 涉及真 Isar 时**：直接走 service-level 测试（`seclusion_service_test.dart` 模板），不要再尝试 widget test 接真 Isar
5. **遇 fake_async 内 await native ffi future 卡死**：本会话 §4.3 是教科书案例，直接引用本文档

CLAUDE.md / GDD.md / numbers.yaml 不动（W12 改 numbers.yaml 仅是注释行更新，未碰平衡值）。Mac 端写 `lib/` `data/*.yaml`（顶层）`test/` `docs/handoff/`；DeepSeek 写 `data/narratives/` `data/lore/` `data/events/`。
