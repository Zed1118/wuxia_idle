# DeepSeek W16 节日 encounter 文案 closeout (2026-05-16)

> 项目:挂机武侠 (F:\Projects\wuxia_idle)
> 对应派单: `docs/handoff/deepseek_w16_festival_dispatch_2026-05-16.md`
> 接单方: DeepSeek @ Pen Windows
> 完成时间: 2026-05-16

---

## 完成项

### 任务 A · encounters.yaml 追加 6 节日 entry (30 → 36)

`data/encounters.yaml` 末尾追加 6 个 festival encounter entry，序号 31-36：

| # | encounter id | festivalRequired | path_a (attributeKey) | path_b (attributeKey) |
|---|---|---|---|---|
| 31 | chun_jie_shou_sui | chunJie | fortune | enlightenment |
| 32 | yuan_xiao_guan_deng | yuanXiao | fortune | agility |
| 33 | duan_wu_du_long_zhou | duanWu | constitution | enlightenment |
| 34 | qi_xi_xi_qiao | qiXi | agility | enlightenment |
| 35 | zhong_qiu_yue_xia_du | zhongQiu | enlightenment | agility |
| 36 | chong_yang_deng_gao | chongYang | constitution | fortune |

- 全部 `type: fortuneEvent`，`fortuneRequired: 4`，`baseProbability: 0.5`
- outcomeMapping 每 entry 2 个 attributeBonus（delta 1），skip 不入 mapping
- 缩进对齐现有 entries，序号注释格式一致

### 任务 B · 6 个 events/*.yaml 文案文件

| 文件 | title | 意象词 |
|---|---|---|
| chun_jie_shou_sui.yaml | 守岁夜 | 红灯/爆竹/围炉/子夜钟响/雪 |
| yuan_xiao_guan_deng.yaml | 观灯夜 | 花灯/灯谜/人潮/汤圆/月 |
| duan_wu_du_long_zhou.yaml | 渡龙舟 | 龙舟/艾草/雄黄/菖蒲/江涛 |
| qi_xi_xi_qiao.yaml | 乞巧夜 | 银河/针线/星光/穿针/桥 |
| zhong_qiu_yue_xia_du.yaml | 月下独酌 | 圆月/桂花酒/清光/剑影/雁鸣 |
| chong_yang_deng_gao.yaml | 登高 | 山道/菊酒/茱萸/松针/陡崖 |

- 每个文件 3 choices（path_a → path_b → skip），body 2-4 行
- opening 5-7 行，全部意象渗透，无节日名字眼
- outcome_id 与 encounters.yaml outcomeMapping key 严格对齐

---

## 验收自检结果

- [x] `data/encounters.yaml` 末尾追加 6 个 entry，序号 31-36，缩进对齐
- [x] 每个 entry `id` / `festivalRequired` / `fortuneRequired` / `baseProbability` / `outcomeMapping` 完全等于任务 A 表
- [x] 6 个 events 文件存在，文件名 = encounter id
- [x] 每个 events 文件 `id` 字段值 = 文件名
- [x] 每个 events 文件 choices 严格 3 个，顺序 path_a → path_b → skip
- [x] 每个 outcome_id 与 encounters.yaml `outcomeMapping` key 严格对齐（skip 除外）
- [x] 文案 grep 无：`机缘 +` / `身法 +` / `legendary` / `epic` / `史诗` / `传说级` / `任务奖励` / `副本` / `经验值` / `属性面板`
- [x] 6 节日 opening 不直接出现「春节」「元宵」「端午」「七夕」「中秋」「重阳」字眼

---

## 已知偏差

- **春节守岁夜**文案直接使用派单 §3 完整样例（派单方提供，非 DeepSeek 原创）
- 其余 5 节日 DeepSeek 原创，主题对齐派单 §4 方向建议，具体场景/配角/措辞自由发挥

---

## 未动文件（依派单 §7 硬约束）

- `lib/` 下所有 Dart 文件（zero 代码改）
- `data/numbers.yaml` / `GDD.md` / `CLAUDE.md` / `IDS_REGISTRY.md`
- `data/encounter_skills.yaml` / `data/skills.yaml`
- 其他 `data/events/<id>.yaml` 30 个已有文件

---

## 文件改动统计

```
 data/encounters.yaml                          | 120 +
 data/events/chun_jie_shou_sui.yaml (new)      |  30
 data/events/yuan_xiao_guan_deng.yaml (new)    |  32
 data/events/duan_wu_du_long_zhou.yaml (new)   |  32
 data/events/qi_xi_xi_qiao.yaml (new)          |  33
 data/events/zhong_qiu_yue_xia_du.yaml (new)   |  32
 data/events/chong_yang_deng_gao.yaml (new)    |  33
 ──────────────────────────────────────────────────
 7 files changed, 120 insertions(+), 192 new lines
```

实际数字来源：`git diff --stat HEAD` + `wc -l` 实测。

---

## Mac 端复审后待办

- [ ] 跑 `flutter test test/data/encounter_yaml_test.dart` — entry 计数断言需从 30 改为 36
- [ ] 跑 `flutter test` 全测 verify
- [ ] 跑 `flutter analyze` 0 issues
- [ ] 视觉验收：_TodayFestivalChip 调系统时间到节日日测试
- [ ] PROGRESS.md 更新 + commit 销账
