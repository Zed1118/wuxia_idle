# P1 #44 延续典故 yaml 抽取 · Mac 端 wire 完成 closeout · 2026-05-19

> Mac + Opus 4.7 主对话续推进(2026-05-19 下午,sonnet ~50min),起自 P1 #45+#37 cleanup closeout (HEAD `0a92358`) 之后,4 commit 销账 P1 #44 Mac 端。终态 HEAD `d6913a4`。

## §1 起手会话状态

- HEAD `0a92358`(P1 #45+#37 cleanup closeout 后)
- 测试 1111 pass + 1 skip + 0 issues / PROGRESS.md 79 行
- 用户选 4 决策(候选 1 起手 reality check 后):
  - ① Pool 结构:按装备拆池(每件 yaml 各有 2 池)
  - ② 抽样:纯随机(`Random()`)
  - ③ 兜底:Fallback 现有 Dart 模板
  - ④ 双端拆分:Mac 先 wire,DeepSeek 后补文案

## §2 4 commit 一览

| commit | 任务 | 文件改动 | +/- lines |
|---|---|---|---|
| `8a99d39` | Phase 1 LoreContent schema 扩 | 2 | +76/-4 |
| `f221c02` | Phase 2 GameEventService 读 yaml + Random 注入 + fallback | 2 | +249/-5 |
| `06136a1` | Phase 4 DeepSeek 派单 spec | 1 (新) | +173 |
| `d6913a4` | Phase 5 PROGRESS.md 更新 | 1 | +5/-4 |

4 commit 全 push origin/main,工作树干净。

## §3 关键设计决策

- **占位符约定**:`{source}` / `{boss_name}` / `{stage_name}` 走变量;`{equip_name}` **不传**,yaml 按装备拆池直写具体兵器名(符合 GDD §6.6 装备典故个性化语义,避免"此 {equip_name}" 这种弱表达)
- **Fallback 链**:LoreLoader.load → placeholder(文件缺失/损坏)→ 池为空 → UiStrings Dart 模板兜底。渐进式迁移友好,Mac 可独立 merge main 不阻塞 DeepSeek
- **Random 注入**:`GameEventService(isar, {loreLoader, random})` 可选注入,测试用 `Random(seed)` deterministic,生产默认 `Random()`
- **LoreContent 默认值兜底**:新字段 `continuedLoreObtainedPool / continuedLoreBossDefeatedPool` 改为 `const []` 可选默认,避免 `equipment_detail_screen*_test.dart` 等下游 stub LoreContent 缺字段 break

## §4 PROGRESS.md 状态变化

| 项目 | 起手 | 终态 |
|---|---|---|
| HEAD | `0a92358` | `d6913a4` |
| 测试 | 1111 pass + 1 skip | **1117 pass + 1 skip**(+6 case) |
| analyze | 0 issues | 0 issues |
| 总行数 | 79 | **80**(守 ≤80 目标,#45 已销账行 + 已完成段压缩) |
| P1 #44 | 完全待办 | **部分销账**(Mac 端 100% / DeepSeek 端 0%) |
| P1 剩余挂账 | #37 部分 + #43 + #44 | #37 部分 + #43 + #44 文案 |

## §5 下波候选

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| ① | DeepSeek 35 件文案补齐 | DeepSeek 主导 | 3-5h | Windows 端推进,Mac 端到位后做红线 case 验收 + 可选删 Dart fallback |
| ② | #43 高阶占位补齐 21-30 层 | **opus xhigh** + DeepSeek | 5-8h | Demo 必交付(GDD §7),18 条 skill + baoWu 掉表 |
| ③ | 美术 PoC + 水墨 LoRA 调研 | opus + 用户主导 | 6-10h | M4 硬门槛,技术选型先讨论 |
| ④ | lao_jing_hui_xiang 拍板 | — | 5-10min | inn 拟合略牵强 vs 继续封档 |

## §6 硬约束沿用

- GDD §5.4 数值红线 / §5.6 不硬编码 / §6.6 延续典故个性化
- Mac+Opus 不动 GDD.md / CLAUDE.md / numbers.yaml / WINDOWS_DEEPSEEK_GUIDE.md / data/lore/<id>.yaml 文案(DeepSeek 领地)
- 占位符花括号 `{var}` 形式;不识别 `{{var}}` / `<var>` / `${var}`
- LoreLoader 默认空 list 兜底体例延用(W15 #35 placeholder 体例)
- Riverpod 3.x 用 `.value` 不 `.valueOrNull`
- Mac git 走代理需 `HTTP_PROXY=""` 前缀

## §7 closeout

本会话定位:**P1 #44 Mac 端 wire 销账 + DeepSeek 派单**。4 commit 同子系统(LoreLoader / GameEventService / spec / PROGRESS)连贯推进,无技术债遗留。下波 ① DeepSeek 主导 / ② / ③ 均跨子系统或升档新会话起点,**建议清理会话**。
