# P5+ UI polish 续作 closeout(A 批)

> 日期:2026-05-24 凌晨 / 模型:Opus 4.7 high / 工时 ~50min
> 主 cwd `/Users/a10506/Desktop/挂机武侠` @ main · 直推 main(无 PR)· 单 worktree
> 上游 closeout:`p5_lineage_full_closeout_2026-05-24.md`(P5+ ④+⑤ 合并 batch)
> 8h autonomous 流批 1/5(A)· v2 改进版

## TL;DR

P5+ ④+⑤ 合并 batch 留挂账的 4 项 UI polish 收尾 ✅(2 commit `154211b → 82fb235`)。`listDiscipleTargets` 加 `!isFounder` 过滤防 P5+ 多代飞升时已 promoted disciple 再次入下拉(语义循环);character_panel + LineagePanel 加多代传承 chip(prev.length > 1 时显「{N} 代传承」);AscensionScreen confirm dialog + complete snackbar 显接任弟子名。1291 → **1293 pass / 1 skip / 0 analyze**(+R5.9 2 测)。

## 改动总览

| 文件 | 改动 | 行数 |
|---|---|---|
| `lib/features/ascension/application/ascend_service.dart` | listDiscipleTargets 加 `!c.isFounder` 过滤 + doc 注扩 | +9/-2 |
| `lib/features/character_panel/presentation/character_panel_screen.dart` | _LineageHeritageRow 加多代 chip 副行(prev.length > 1 时显「{N} 代传承」 N = prevLen + 1) | +24/-3 |
| `lib/features/character_panel/presentation/lineage_panel_screen.dart` | _HeritageRow 末尾加多代 chip Container | +22/-0 |
| `lib/features/ascension/presentation/ascension_screen.dart` | _showConfirmDialog 加 promotedDiscipleName 参数 · dialog Column 显「门派衣钵:{N}」 · snackbar 追加「 · {N} 接掌门派」 | +43/-12 |
| `lib/shared/strings.dart` | 加 2 段(ascensionConfirmDialogPromotedLine + ascensionCompletePromotedSuffix) | +4/-1 |
| `test/features/ascension/application/ascend_service_test.dart` | R5.9 group 2 测(gen0 baseline + gen1 promote=2 后 d2 排除 d3 仍在) | +41/-1 |

合计 +143/-19 · 5 lib + 1 test

## R5.9 测族(2 测)

| 测 | 断言 |
|---|---|
| gen0 baseline | 无 promoted · listDiscipleTargets 返 {d2, d3}(全 disciple 都在 target) |
| gen1 promote=2 后 | d2 已 isFounder=true → 不在 target list(主断言) · d3 仍在(未误伤) · 顺手 sanity check d2.isFounder=true 防 setup 漂移 |

测族 R5.1-5.8 18 → **R5.1-5.9 20 测**(ascend_service_test 全过 0.4s)

## 工作量复盘

| step | 估 | 实测 | 备注 |
|---|---|---|---|
| Phase 0 grep + 4 改动定位 | 15min | ~10min | 上波 P5+ ④+⑤ 同 context 复用决策 0 重读 |
| A.1 Service + R5.9 | 20min | ~15min | 一行过滤 + 2 测沿 R5.6 体例 |
| A.2-A.4 UI 3 改 + UiStrings 2 段 | 30min | ~20min | _LineageRow Column 套 + chip Container · dialog content Column 重构 |
| 全仓 test + analyze 验证 | 5min | ~5min(bg 并行) | 1293 pass / 0 issues |
| A.5 closeout doc(本) | 15min | ~10min(写中) | doc ≤80 行严控 |

实测 ~50min vs spec 估 1.5-2h · 精度 0.42-0.55×(memory `feedback_opus_xhigh_interactive_duration` high 档 0.5-0.7× 锚点稳定)

## 不变量沿用

GDD §5.4 红线 0 改 · §5.3 三系锁死 · CLAUDE.md v1.10 · founder_buff_service 0 改 · AscendService.performAscend 接口 0 改(只加 listDiscipleTargets 过滤一行)· 详 [`CLAUDE.md`](../../CLAUDE.md)

## 挂账下批

- ✅ ~~A.1 listDiscipleTargets 过滤~~ · ✅ ~~A.2 character_panel 多代 chip~~ · ✅ ~~A.3 LineagePanel 多代 chip~~ · ✅ ~~A.4 dialog/snackbar 含 promoted 名~~
- narrative「太祖→祖师→新祖师」叙事弧留 P5+ 真做飞升 narrative 扩展时同步(本批挂账 → P5+ narrative 扩展)
- 多代 chip widget test(本批未加 · 风险 > 收益)留 P5+ visual regression batch(优先级低)
- 8h autonomous 流继续推进:B 批(视觉验收 + MJ 派单 spec)· C 批(1.0 stage_audit)· D 批(P1.2 江湖恩怨地基预备)· E 批(memory sink + 起床 handoff)
