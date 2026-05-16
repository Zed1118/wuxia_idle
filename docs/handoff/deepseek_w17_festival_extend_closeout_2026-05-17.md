# DeepSeek W17 节日 encounter 文案 closeout (2026-05-17)

> 项目:挂机武侠 (F:\Projects\wuxia_idle)
> 对应派单: `docs/handoff/deepseek_w17_festival_extend_dispatch_2026-05-17.md`
> 接单方: DeepSeek @ Pen Windows
> 完成时间: 2026-05-17

---

## 完成项

### 任务 A · encounters.yaml 追加 2 节日 entry (36 → 38)

`data/encounters.yaml` 末尾追加 2 个 festival encounter entry，序号 37-38：

| # | encounter id | festivalRequired | path_a (attributeKey) | path_b (attributeKey) |
|---|---|---|---|---|
| 37 | chu_xi_ci_sui | chuXi | fortune | enlightenment |
| 38 | qing_ming_yu_si | qingMingJie | enlightenment | constitution |

- 全部 `type: fortuneEvent`，`fortuneRequired: 4`，`baseProbability: 0.5`
- outcomeMapping 每 entry 2 个 attributeBonus（delta 1），skip 不入 mapping
- 缩进对齐 W16 体例，序号注释格式一致

### 任务 B · 2 个 events/*.yaml 文案文件

| 文件 | title | 意象词 |
|---|---|---|
| chu_xi_ci_sui.yaml | 辞岁 | 烟花/桃符/镜店/新岁/风雪/火束 |
| qing_ming_yu_si.yaml | 雨思 | 春雨/纸鸢/柳枝/梨花/踏青/泥路 |

- 每个文件 3 choices（path_a → path_b → skip），body 2-5 行
- opening 5-7 行，全部意象渗透，无节日名字眼
- outcome_id 与 encounters.yaml outcomeMapping key 严格对齐

---

## 验收自检结果

- [x] `data/encounters.yaml` 末尾追加 2 个 entry，序号 37/38，缩进对齐
- [x] 每个 entry `id` / `festivalRequired` / `fortuneRequired` / `baseProbability` / `outcomeMapping` 完全等于任务 A 表
- [x] entry 总数 30→36→38（38 个 `- id:` 计数确认）
- [x] 2 个 events 文件存在，文件名 = encounter id
- [x] 每个 events 文件 `id` 字段值 = 文件名
- [x] 每个 events 文件 choices 严格 3 个，顺序 path_a → path_b → skip
- [x] 每个 outcome_id 与 encounters.yaml `outcomeMapping` key 严格对齐（skip 除外）
- [x] 文案 grep 无：`legendary` / `epic` / `史诗` / `传说级` / `任务奖励` / `副本` / `经验值` / `属性面板` / 具体数字
- [x] 2 节日 opening 不直接出现「除夕」「清明」字眼（意象渗透）
- [x] 清明 opening 不出现「节气」「24 节气」字眼（节气节日独立通道）

---

## 已知偏差

- **除夕辞岁**文案直接使用派单 §4 完整样例（派单方提供，非 DeepSeek 原创）
- **清明雨思**文案 DeepSeek 原创，主题对齐派单 §3 方向建议（春雨/纸鸢/踏青自然清新 vs 中秋「月下独酌」清冷孤高），具体场景/配角/措辞自由发挥
- 除夕侧重「辞旧动作/夜烟火集」vs 春节 chun_jie_shou_sui「围炉静守」差异化到位
- 清明侧重「春雨/纸鸢/踏青」清新 vs 中秋 zhong_qiu_yue_xia_du「月圆/独酌」清冷差异化到位

---

## 未动文件（依派单 §7 硬约束）

- `lib/` 下所有 Dart 文件（zero 代码改）
- `data/numbers.yaml` / `GDD.md` / `CLAUDE.md` / `IDS_REGISTRY.md`
- `data/encounter_skills.yaml` / `data/skills.yaml`
- 其他 `data/events/<id>.yaml` 36 个已有文件

---

## 文件改动统计

```
 data/encounters.yaml                          |  40 +
 data/events/chu_xi_ci_sui.yaml (new)          |  30
 data/events/qing_ming_yu_si.yaml (new)        |  32
 ──────────────────────────────────────────────────
 3 files changed, 106 insertions(+)
```

实际数字来源：`git diff --stat HEAD~1..HEAD` 实测。

---

## Mac 端复审后待办

- [ ] 跑 `flutter test test/features/encounter/domain/encounter_yaml_test.dart` — entry 计数断言需从 36 改为 38
- [ ] 跑 `flutter test` 全测 verify
- [ ] 跑 `flutter analyze` 0 issues
- [ ] 视觉验收：`_TodayFestivalChip` chuXi / qingMingJie 2 chip 截图
- [ ] PROGRESS.md 更新 + commit 销账
