# P3.3 PVP Phase 4 UI + Phase 5 narrative stub · closeout

> 日期:2026-05-24 / nightshift T15(Opus 4.7 / branch `nightshift/T15`)
> 上游:9733f2e Phase 2 schema + 665a4d9 Phase 3 logic + 本批 Phase 4 UI + Phase 5 stub
> spec:`docs/spec/p3_3_pvp_spec_2026-05-24.md` §5/§6/§7/§8

## TL;DR

- main_menu 入口 14→15(MassBattle 后 Leaderboard 前)+ UiStrings PVP 段 16 string
- PvpScreen 三态 shell(locked stage_05_05 / available RankBadge + match + history / cleared 无终态)
- RankBadgeWidget(ELO → 7 阶段位段窗 200)+ PvpHistoryList(空态 + 胜负标识)
- pvp_providers.dart Riverpod wire(NoopPvpSync + currentElo 默认 1200 + history empty stub)
- data/lore/pvp/pvp_event_first_blood.yaml 1 条 narrative stub(完整 8-12 留挂账)
- R4/R5 8 测全 pass + main_menu 30 测无 regression

## 改动总览

| 文件 | 行数 | 说明 |
|---|---:|---|
| lib/shared/strings.dart | +29 | mainMenuPvp + Hint + pvpTitle/Locked/Match/History/Rank/EloLabel 16 string |
| lib/features/main_menu/presentation/main_menu.dart | +6 | PVP _MenuButton 插 MassBattle 后 Leaderboard 前 |
| lib/features/pvp/application/pvp_providers.dart | +44 (新) | pvpSync/pvpService/currentElo/pvpRecentRecords 4 provider |
| lib/features/pvp/presentation/pvp_screen.dart | +135 (新) | ConsumerWidget 三态 + match button snackbar shell |
| lib/features/pvp/presentation/widgets/rank_badge_widget.dart | +119 (新) | ELO 7 阶映射 + 进度条 + nextRankName |
| lib/features/pvp/presentation/widgets/pvp_history_list.dart | +138 (新) | List<PvpRecord> + 空态 + 对手段位 + 胜/负/和 |
| data/lore/pvp/pvp_event_first_blood.yaml | +9 (新目录) | Phase 5 stub 1 条(首胜) |
| test/features/pvp/pvp_screen_test.dart | +180 (新) | R4/R5 8 测(3 三态 + 3 RankBadge + 1 History + 1 yaml schema) |
| test/features/main_menu/.../main_menu_test.dart | ~+10/-10 | 14→15 InkWell + 顺序断言加 PVP |

## R4/R5 测族结果

```
flutter test test/features/pvp/  → 33/33 pass(原 25 schema + 8 新 screen)
flutter test test/features/main_menu/  → 30/30 pass(原 14→15 入口 0 regression)
flutter analyze lib/features/pvp lib/features/main_menu lib/shared/strings.dart  → No issues
```

- R5.1 三态:locked 无 RankBadge / available 显全套 / SnackBar tap 触发
- R5.2 RankBadge 段窗 200 边界:0/999/1000/1199/1200/.../1999/2000/2500 全过
- R5.3 nextRankName:武圣段返 null,其余返下一段
- R5.4 History 胜/负标识 + ELO delta 着色
- R4.1 narrative yaml schema:id/trigger.kind/title/opening/text_on_rank_up 五字段 + 黑名单 5 词 0 命中

## 挂账(本批 OUT · 留下波 / 1.1+)

- **Phase 5 narrative 完整 8-12 条**(初战 2 + 连胜 3 场 2 + 7 段位晋级各 1 + 降段 1):本批仅 ship `pvp_event_first_blood.yaml` 1 条示范 schema · narrative loader wire + GameEventService 触发 hook 同期落
- **PVP 真持久化(Isar wire)**:PvpRecord/PvpSnapshot 已建 schema 但未注册到 `IsarSetup._allSchemas`(本 task 白名单不含 isar_setup.dart),Phase 5+ 真持久化时一并加 + bump saveVersion 0.13.0
- **当前 ELO 真持久化**:SaveData.pvpElo 字段 + 跨 session 沿用 · 本批 `currentPvpEloProvider` 静态返 1200(initial)
- **Match button 真战斗 wire**:读玩家阵容 + PvpService.match + 战后 Isar 入库 + ELO 持久化 · 本批 SnackBar shell 仅显 placeholder
- **Supabase 真接 SupabasePvpSync**(D 方案 future-proof):pubspec + Edge Function 上探 12h+ 留 1.1+,本批 NoopPvpSync 默认注入
- **OpponentPickList(可选)**:spec §5 留扩,Phase 4 Noop 单一对手不弹

## 工作量复盘

- 估时(spec §8):Phase 4 ~2h + Phase 5 narrative + closeout ~2h = ~4h opus xhigh
- 实际(nightshift):Phase 0 reality check + 5 lib 文件 + 1 yaml + 2 test 文件 + 本 doc · 一次性 analyze + test 全过 0 reroll
- 关键节流点:① PvpHistoryList 取 records prop 不直接 watch Isar(避 isar_setup.dart 改动 + widget test viewport 复杂度)② Match button shell 化 SnackBar(避 character_providers 依赖膨胀)③ RankBadgeWidget rankInfo/nextRankName 提 static 便测族纯单测

## 后续 PROGRESS 顶段建议(closeout 内挂账,本 task 不 sync)

- nightshift T15 P3.3 Phase 4+5 COMPLETED:UI 全 shell + narrative 1 stub + R4/R5 8 测全过
- 下波 batch 候选:`p3_3_pvp_phase5_full_2026-05-2X` — narrative 8-12 yaml + loader wire + Isar 持久化(saveVersion 0.13.0)+ Match button 真战斗 wire + PROGRESS/ROADMAP/GDD §12.3 三 sync
