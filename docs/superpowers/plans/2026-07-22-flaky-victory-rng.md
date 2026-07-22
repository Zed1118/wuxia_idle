# 2026-07-22 flaky 根治:apply_victory_resolution 装备事件数断言

> 恢复点文档(随分支 kimi/flaky-victory-rng-20260722 提交,基于 main 5396706e)。
> worktree:`.worktrees/flaky-rng`。

## 任务

`test/features/mainline/presentation/apply_victory_resolution_test.dart`
「胜利全量」用例 equipmentObtained 事件数断言 flaky(2026-07-19 全量并发曾见 2 条未复现)。

## 复现记录(修复前实测)

- worktree 首次 20 连跑 20/20 EXIT=1 —— 是 **codegen 缺失**(新 worktree 未跑
  `dart run build_runner build`,Isar schema / riverpod provider 未生成),
  非目标 flaky;补跑 build_runner 后恢复。
- codegen 后 20 连跑:**19 绿 1 红(run 7,失败率 5%)**。
- 失败断言原文(`胜利全量` 用例,文件 L371 附近):

  ```
  Expected: an object with length of <1>
    Actual: [Instance of 'GameEvent', Instance of 'GameEvent']
  命中 2 条: [得 铁剑|于「测试普通关」得 铁剑…|[weapon_xunchang_tie_jian, 1]|…,
             得 长剑|于「测试普通关」得 长剑…|[weapon_xiangyang_chang_jian, 2]|…]
  ```

## 根因(一句话)

`applyVictoryResolution` 用**无种子** `DefaultRng()`(`stage_entry_flow.dart:826`)
驱动 `BattleResolutionService.resolve`,resolve 对每场胜利额外 roll 稀有彩头
(`battle_resolution.dart:211-230` → `drop_service.dart:155` `selectRareBonusTier`,
一周目 5%/1.5% 独立命中,`numbers.yaml:2036-2037`),命中即 `dropResult.equipments`
多一件高阶装备 → `stage_entry_flow.dart:908-918` 每件写一条 equipmentObtained
事件 → 断言 hasLength(1) 偶发变 2;单次「胜利全量」理论失败率
1-(0.95×0.985)≈6.4%,与实测 5% 吻合。

## 修复方案与取舍

- **选用**:测试层 override `numbersConfigProvider` —— 重解 `data/numbers.yaml`
  摘掉 `rare_bonus_drop` 段(`RareBonusDropConfig.fromYaml({})` → empty →
  enabled=false → rollRareBonus 永不命中),全文件经 `runWithRef` 注入。
  只改测试文件,断言语义(固定掉落 1 件 = 事件 1 条)不变。
- **不选改生产 RNG 接线**:`stage_entry_flow.dart:826` 直 new `DefaultRng()`
  而非走 `rngProvider`;改成 `ref.read(rngProvider)` 才能注入 seed,但任务
  纪律明确「不改生产 RNG 接线」,且生产行为(彩头概率)本就应随机,无病。
- **不选改断言**:断言本身语义正确,flaky 来自真实随机源而非断言写错;
  放宽为 `hasLength(drops.equipments.length)` 会让断言与数据源同源、失去校验力。

## 验收进度

- [x] 修前 20 连跑复现(1/20 失败,断言原文在案)
- [x] 修复实施(仅测试文件)
- [x] 修后 20 连跑全绿(20/20 EXIT=0)
- [x] 相关域 targeted 绿(test/features/mainline 153 全绿)
- [x] flutter analyze 0 issue(No issues found, 12.2s)
- [x] 批末全量 flutter test --no-pub 0 fail(实测 4626 全绿,基线 4626 持平,约 5 分钟)
- [x] dart format + commit(4089fb3c)
- [ ] push + draft PR(Zed1118/wuxia_idle)
