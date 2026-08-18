# Phase 0C 工程嵌入验收批(2026-08-18)

> 分支 `feat/phase0c-engineering-embed-verify-0818` · 基于 main `a767fe91`
> 性质=Phase 0C 工程嵌入裁决批(验证为主 + 一处表现实装:Esc 暂停)
> 上位=v2 方案 §11 Phase 0C / `docs/spec/2026-08-13-phase0a-gameplay-greybox-spec.md`

## 背景

Phase 0 验证期四阶段(0−/0A/0B/0C)中,0−(Mac PASS / Windows 后置)、
0A 灰盒(`MAC_AND_STRATEGY_PASS`)、0B 美术(方向锁定)已收口;生产表现层
Batch 1–9C 已合 main(`phase0a_battle_playable` 等路由在产)。0C 工程嵌入
尚无独立裁决。用户 2026-08-18 拍板:6 人真人 Gate 与 Windows 实机后置,
先推进工程可执行项——本批即 0C。

## 摸底结论(本批前置勘察)

1. **技术栈**:根 `pubspec.yaml` 无 Flame;生产层
   `lib/features/battle/{domain,application,presentation}/phase0a/` 为纯
   Flutter 实现(reducer + session + Ticker 驱动)。Flame 仅为隔离探针载体,
   未进生产——0C「Flame 保留与否」裁决据此可下:**探针隔离保留,生产不引入**。
2. **存档隔离**:phase0a 三层源码 grep 零 `Isar/save` 引用;隔离是架构级
   保证(非调用者自觉)。
3. **生命周期**:`_Phase0aBattleScreenState` 单 Ticker + FocusNode,
   initState 建 / dispose 拆,成对。
4. **缺口**:① 无 Esc 暂停(spec §3.1 要求 `Esc` 暂停/继续,暂停时不记性能
   样本);② 无 50 次进退稳定性专项;③ 无窗口缩放/重建专项。

## 实装内容

1. **Esc 暂停/继续**(实装):screen 接 `Escape` 键切换暂停态;暂停时
   Ticker 帧不推进 domain(不记样本)、HUD 显示暂停提示;继续恢复。
   文案走 data(不硬编码中文)——若既有暂停文案域可复用则复用,否则登记。
2. **0C 稳定性测试**(新增):
   - 50 次进退:widget 反复 mount/unmount `Phase0aBattleScreen`(真实
     fixture 驱动,禁 fake flow),断言零异常、dispose 后 Ticker 无泄漏;
   - 输入有效性:每 N 次进退后注入键盘指令,断言仍有真实事件产出
     (输入不失效);
   - 暂停/恢复:Esc 暂停后 step 无事件,继续后恢复;
   - 窗口缩放:1280×720 ↔ 1440×900 ↔ 1152×648 切换下整屏可构建无异常。
3. **存档零污染测试**(新增):真实 flow 驱动一整局(至终局)前后,断言
   Isar 未初始化 / 未产生任何持久化写(架构守卫钉,防未来接线回归)。
4. **裁决报告**(新增文档 `docs/phase0/2026-08-18-phase0c-engineering-embed.md`):
   按 v2 §11 0C 通过条件逐项给 PASS/PENDING/N-A,明确 Windows 与真人后置、
   性能对照口径(纯 Flutter 生产层 vs Flame 探针非同载体,帧时间对照需
   后续 Mac Profile 采集,本批以 reducer 吞吐基准替代)。

## 验收标准

- [x] Esc 暂停/继续实装 + 测试钉(暂停中零 domain 推进)
- [x] 50 次进退稳定性测试绿(零异常 + 输入不失效)
- [x] 窗口缩放三视口测试绿
- [x] 存档零污染守卫测试绿
- [x] `flutter analyze --no-pub` 0 issue
- [x] 全量 `flutter test` 5167/0(基线 5161 + 本批 6,逐值吻合)
- [x] 裁决报告落 docs/phase0/2026-08-18-phase0c-engineering-embed.md
- [x] 破坏证红:反向补丁撤暂停实装 → 恰 3 红锚暂停语义 → 还原复绿 6/6

## 红线

- 不动 domain 规则(reducer/数值);只加表现层暂停与测试
- 不接生产存档/奖励/根导航;不引入 Flame 进根应用
- 暂停文案不硬编码中文(走 UiStrings.phase0aPausedBanner)

## 当前恢复点

- **状态**:实装完成,收账前终态
- **commit 链**:RP0 计划档 → Esc 暂停实装 `68317574` → 0C 测试组 `eb2d490d` → 裁决报告+计划档终态
- **下一步**:merge main → PROGRESS 插登记条 → push → CI 盯守(预期 5167)
- **阻塞项**:无
