# 第 4 梯队 · 秘籍获得仪式小升级

## 范围

- 仅升级已有 `SkillTreasureContent` 的获得展示质感。
- 保持 `presentSkillTreasure` 触发契约不变:真解首通与残页集齐走重仪式,未集齐残页仍走轻提示。
- 不改掉落概率、残页阈值、解锁、背包写入、战斗或奖励结算逻辑。
- 不做残页来源聚合。

## 验收标准

- 真解首通展示更像得卷:有卷宗标签、说明短句、招式名和卷轴式 fallback。
- 残页集齐展示区别于真解:使用残篇合卷语气。
- `imagePath == null` 与不存在资产均不崩溃。
- minor 残页和 none 仍不展示重仪式。
- Widget test 覆盖新展示文案与既有触发契约。

## 验证

- `flutter test test/features/cultivation/presentation/skill_treasure_overlay_test.dart`
- `flutter analyze`
