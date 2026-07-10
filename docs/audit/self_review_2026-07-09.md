# 阶段性自测审查 · 2026-07-09

## 本轮目标

- 自测当前改动是否能覆盖用户提出的“看不出差别”问题。
- 推进战斗节奏、扫荡战备 UX、桃花岛概览、GDD 同步与素材缺口盘点。
- 保持项目红线：不做传统体力、不做日课、不阻断主线首通。

## 结论

- 主线首通节奏已从“保底 10 秒但真实动作偏少”调整为“配置化单拍 2.2 秒 + 胜利保底 14 秒”。
- 当前诊断平均展示动作行 5.5，估算展示 15.3 秒；首 30 分钟与单人 Ch1-6 回归均通过。
- 技能伤害占比约 38.4%，普攻仍有 61.6%，比“技能过早收尾”更接近可读战斗。
- 扫荡战备文案明确为“只限制已通关主线重复扫荡”，不消耗首通、普通战斗、离线收益。
- 桃花岛底部概览改为“岛务概览 / 三项状态 / 分区职能”，提高字号字重，降低长句密度。

## 素材缺口

- `battleUlt` SFX：仍为 `realmAdvance` 临时转用，目标 800-1600ms。
- `battleChargeStart` SFX：仍为 `defeat` 临时转用，目标 500-1200ms。
- 桃花岛地图素材 `assets/maps/taohuaIsland.webp` 已接入并通过 widget/asset 审计，不属于当前阻塞缺口。

## 仍需注意

- 部分早期或满配 ceiling 剖面的真实动作行仍低于“普通 6 / Boss 9”的诊断目标；目前用 14 秒可读保底兜住视觉停留。
- 如果用户试玩后仍觉得“发生得太少”，下一步不建议继续硬抬 HP，优先做首通脚本化展示帧：开局亮相、首个技能慢镜、Boss 蓄力提示、破招成功题字。
- 后续强力副本建议接“副本凭证”或世界观入场物，不复用扫荡战备。

## 自测命令

```bash
flutter test --no-pub -j1 --reporter expanded test/tools/readable_first_clear_tempo_diagnostic_test.dart test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart test/features/onboarding/onboarding_first_30min_battle_test.dart
```

输出报告：

- `test/tools/output/readable_first_clear_tempo_2026-07-09.md`
- `test/tools/output/readable_first_clear_tempo_2026-07-09.csv`
