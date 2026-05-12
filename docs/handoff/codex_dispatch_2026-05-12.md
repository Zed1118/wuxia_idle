# Codex 夜班派单记录 — 2026-05-12

> 写给 2026-05-13 凌晨 3 点重置后回来的 Mac 端 Opus 自己看。
> 也作为「Mac Opus 临时下线时派 Codex 顶 Mac 端备份」的实战参考样本。

## 背景

Mac 端 Claude Opus 4.7 因用量上限暂时下线（2026-05-13 凌晨 3 点重置），Codex 桌面版（GPT-5 高规格）首次进入项目顶 Mac 端备份角色。AGENTS.md v1.1 同晚刚 commit 入仓。原定夜班只规划 4 文档 commit（PROGRESS / phase3_summary / phase3_tasks Week 4 spec / AGENTS.md 入仓），实际派了 **12 轮**，全部零事故，远超原定计划。

## 今晚 12 个 Codex commit 时间线

| # | hash | 类型 | 任务标识 | 简述 |
|---|---|---|---|---|
| 1 | d4374c5 | 文档 | 任务 2 | 首次 commit AGENTS.md v1.1 Codex 启动指南 入仓 |
| 2 | 5857c7c | 文档 | 任务 3 | PROGRESS Week 3 完成 + Week 4 候选指引 |
| 3 | 5cacf43 | 文档 | 任务 4 | phase3_summary 追加 Week 3 闭关交付摘要 |
| 4 | 3792ae8 | 文档 | 任务 5 | phase3_tasks Week 4 C/D/E 候选 spec 草案 |
| 5 | 1832aa3 | 文档 | F1 | 章节锚点核对修正（修复上一轮 prompt 误标 §8.2 为奇遇） |
| 6 | 69994e8 | 文档 | F2 | Week 4 起手前人类决策清单（§12 #5/#6/#10/#11 整理） |
| 7 | beebec4 | 工程清理 | F4 | 清理 widget test 未使用 import，恢复 analyze 0 issues |
| 8 | 25739ca | 文档 | G1 | DEMO_PROGRESS Demo 完成度地图（对照 GDD §7-§8） |
| 9 | a54c4bd | 文档 | G2 | Week 4 起手 issue 清单 C/D/E（每方向 4-6 个 issue） |
| 10 | 4f29eae | 文档 | H2 | yaml 完整性审计报告（id 唯一性 + 跨文件引用，docs/audits/） |
| 11 | b3f3613 | 代码 | I1 | refactor: 抽取 screen_shake + tier_colors helper（清 Phase 5 #21） |
| 12 | 52ea058 | 测试 | I2 | DamageCalculator 25 个边界 case（境界差/暴击/克制/修炼度/红线全档） |

## 当前状态快照

- 分支：`feat/phase3-seclusion`，工作区干净
- 测试：457 → 492（+35，I2 边界 case 25 个 + I1 helper 单测 10 个）
- flutter analyze：0 issues
- push / merge / tag：全部否（每轮红线全守）
- saveVersion：0.4.0（Week 3 T48 升的，未变）

## 明天接手优先顺序

1. **先看 yaml 完整性审计报告**（4f29eae，`docs/audits/yaml_integrity_2026-05-12.md`）→ 处理任何 ⚠ 阻塞标记
   - ⚠ 注意：当晚用户没回应「审计有无阻塞性发现」的追问，自己读全文判断
2. **review 两个代码 commit 的 diff**：
   - I1 b3f3613：纯重构，行为零变化，2 处 screen_shake inline + 3 处 EquipmentTier `_tierColor` inline 替换为 helper 调用；金光 sin 公式（不在 #21 范围）保留未动 — 这是 Codex 主动判断，不是疏忽
   - I2 52ea058：25 个新测试在 `damage_calculator_test.dart` 末尾新 group，期望值含手算注释
3. **通览 10 个文档 commit**（看 git log 即可，commit message 已经清晰）
4. **跟用户对 Week 4 方向**：走 `phase3_tasks.md` 末尾的「§Week 4 起手 issue 清单（C/D/E）」一条一条过
5. **用户跑完 T52** Pen 视觉验收 → merge feat/phase3-seclusion → main → tag v0.3.0-w3
6. **起手 Week 4 T53**（具体方向看用户决定 C 奇遇 / D 师徒 / E 武学领悟）
7. **美术方向 5 个关键决策讨论**（用户当晚认同今晚不动美术；详见末尾「待办」段）

## Codex 表现评估（升级建议）

原定临时顶 1 晚，实际证据：

- **11 轮纪律全守**：不 push / 不 merge / 不 tag / 不动既禁文件，每轮单 commit 干净
- **标记真问题不瞎修**：F1 章节锚点修正 — Codex 在写奇遇 spec 时主动停下来标记「GDD §8.2 实际是爬塔不是奇遇，prompt 给错了章节」，没盲从 prompt
- **F3 健康检查兜底有效**：发现昨晚遗留的 unused_import warning（Mac Opus 自己漏的），按 prompt 要求停下不修，等人类决定
- **行为零变化的重构能力**：I1 抽 helper 后测试 +10 全过，颜色值精确一致，金光 sin 公式独立判断不在 #21 范围所以不抽 — 这是判断力
- **公式期望值手算精度**：I2 25 个边界 case 期望值全对（容差 ≤1.1%，遵守 Phase 1 5 战例精度约定），说明 Codex 能正确解读 DamageCalculator 7 阶段公式
- **入场检查三件套自检纪律**：每次新会话都跑 git log + flutter analyze + flutter test，状态对不上立刻停下

**建议**：可考虑写入 AGENTS.md 作为常态备份角色（不只是 emergency 顶夜班）。但仍需保留每轮红线明文 + 入场检查 + 双绿门禁的派单工程纪律。

## 派 Codex 的工程纪律模板（可复用样板）

1. **新会话 prompt 必须自包含**：角色（Mac 端备份 ≠ DeepSeek）+ 项目状态摘要 + 期望 commit 历史前几行 + 本次任务 + 红线 全部重写在 prompt 顶部，不假设 Codex 记得任何上下文
2. **入场检查三件套**：`git log --oneline -N` + `flutter analyze` + `flutter test`，全对再开任务，任一不对立刻停下贴差异
3. **任务阶段化**：阶段 A 审计（不写代码）→ B 实施 → C 双绿验证 → D 单 commit，禁止跳阶段
4. **红线模板每轮重申**：不 push / merge / tag、单 commit ≤300 行、行为零变化、不动既有公共类型 / service 签名 / 公式
5. **测试不过的归因纪律**：优先怀疑期望值算错，禁止改 lib/ 公式；任何工具异常停下贴输出，不自补修
6. **lib/ 写权限按需开放**：默认不让动 lib/；要开放时明确列出本轮唯一可动的文件清单
7. **挂账提前清的边界**：选 Phase 5 挂账里「边界清晰 / 行为不变 / 测试可回归」的项（I1 #21 helper 抽取就是教科书样本），避免选「涉及多方设计决策」（#23 widget test 改造）或「跨 Phase 边界」（#25 Phase 4 fixture）的项

## 待办 / 挂账

| 项 | 状态 | 处理时机 |
|---|---|---|
| T52 Pen 视觉验收 | 待用户白天 Windows 物理机跑 | 用户主导 |
| Week 4 方向 C/D/E 三选一 | 决策材料齐备（spec / 决策清单 / 起手 issue / DEMO 完成度地图） | Opus + 用户讨论 |
| 美术方向 5 个关键决策 | 用户认同今晚不动；待 Week 4 方向定 + Phase 3 收尾后正式讨论 | 风格基调 / 出图工具 / 商业授权 / 外包模式 / 占位替换 milestone |
| Phase 5 #21 helper 抽取 | ✅ 本轮 I1 已清 | — |
| Phase 5 #23 widget test 改造 | 仍挂账 | 等 Riverpod 3.x + IsarProvider 注入时一并 |
| Phase 5 #25 P1 fixture 缺主修 | 仍挂账（Phase 4 任务边界）| Phase 4 重写 fixture 时 |

## 红线守住情况（12 轮全核对）

| 红线 | 守住情况 |
|---|---|
| 不 push 到 remote | ✅ 12/12 |
| 不 merge → main | ✅ 12/12 |
| 不 tag | ✅ 12/12 |
| 不动 lib/（I1/I2 除外的所有轮） | ✅ 10/10 |
| 不动 data/*.yaml 数值 | ✅ 12/12 |
| 不动 data/narratives/ data/lore/ data/events/ | ✅ 12/12 |
| 不改 GDD / CLAUDE / numbers / data_schema / IDS_REGISTRY | ✅ 12/12 |
| I1 lib/ 写权限例外：仅新建 helper + 替换 inline 5 处 | ✅ 范围严守 |
| I2 仅动 test/core/combat/damage_calculator_test.dart 一个文件 | ✅ 范围严守 |
| 单 commit ≤300 行 | ✅ 12/12 |
| 行为零变化（I1） | ✅（457 现有测试全过，颜色值精确一致） |
| 双绿验证通过才 commit | ✅ 12/12 |
