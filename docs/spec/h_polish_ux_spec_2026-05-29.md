# H 段:内容打磨 + UX spec

> 起草:2026-05-29 · 5h 挂机 Batch A1 · 对应 RELEASE_CHECKLIST §H v1.9
> H 从 nice-to-have 升「完成游戏」主聚焦段。spec 形式化打磨路径,避免凭感觉抽风。

## 1. 目标

CHECKLIST H 6 子项 0/6 → 6/6。1.0 ship 前游戏体验三段(上手 30min / 中期 2-3h / 后期 5h+)全可玩、卡点诊断闭环、UX 微调、内容文案最终 polish。

## 2. 拆 Batch

| Batch | 内容 | Claude 推 | 用户办 | 估时 |
|---|---|---|---|---|
| **H1 上手 30min audit** | 新手引导 / 第一次战斗 / 装备掉落仪式感 / 主菜单 first impression / Phase 0 grep 玩家上手路径 | 100% | — | ~2h |
| **H2 中期 2-3h audit** | 装备 / 心法 / 师徒 / 闭关 玩法深度 / 升阶仪式感 / 共鸣度首次解锁 / 章节切换 | 100% | — | ~2h |
| **H3 后期挑战 audit** | Ch4-6 主线 + 心魔 + 群战 + 轻功 + 飞升 全玩家路径流畅度 + 难度曲线 | 100% | — | ~3h |
| **H4 D4 卡点诊断联动** | balance_simulator 跑出的卡点 / 秒杀点 → H 段映射 stage / numbers 调整 | 100% | — | ~1h |
| **H5 UX 微调** | 空状态文案 / 错误处理 / loading 反馈 / 翻页流畅度 / Snackbar 体例统一 / 长列表性能 | 90% | UI 操作验收 | ~3h |
| **H6 内容文案最终 polish** | typo 全 lib 扫 / 古风一致性 audit / 主线叙事流畅度 review / lore 段过 fluency check | 100% | — | ~4h |

**总 Claude 推 ~15h** · 用户操作:UI 验收 + UX 微调反馈

## 3. 决策点

| # | 问题 | 推荐默认 |
|---|------|---------|
| H-Q1 | 上手 30min 体验目标:玩家能完成 stage_01_01-1_03? | **stage_01_01-1_05 全过**(Ch1 完整体验) |
| H-Q2 | 中期通关率目标:Ch3 通关率 ≥ 70%? | **≥ 60%**(留 ship 前调高) |
| H-Q3 | 后期挑战:Ch6 飞升仪式必通 vs 可选? | **必通**(GDD §3 七阶节奏完整体验)|
| H-Q4 | UX 体例统一规范:本批补 `docs/UX_GUIDELINES.md` 还是不补? | **补 1 份 ≤80 行**(typo / loading / 空状态 / 错误 4 类规范)|
| H-Q5 | 文案 polish 范围:全 narratives/lore/events 一遍?还是只 Ch1-3 主线? | **全 narratives/lore + Ch1-3 events 重点**(Ch4-6 ship 前再二轮)|
| H-Q6 | closed beta(D6)和 H 段 audit 串行 vs 并行? | **H 段先完成 → closed beta**(自验先于他验)|

## 4. 子任务粒度(可立即派单)

### H1 上手 30min
- **H1.1**:Phase 0 grep `OnboardingService` + `main_menu_screen` + `stage_entry_flow` 上手路径(无遗漏 widget)
- **H1.2**:`docs/handoff/h1_onboarding_audit.md` ≤80 行 · stage_01_01 第一次战斗节奏 / 装备首次掉落 / Tutorial chip 触发清单
- **H1.3**:卡点候选清单(若有 → numbers tune 联动)

### H2 中期 2-3h
- **H2.1**:Ch2-3 装备 / 心法搭配深度 audit(主流派 build 多元性)
- **H2.2**:师徒 E.1 收徒触发 / 闭关 PoC 首次体验 / 共鸣度首次解锁
- **H2.3**:章节切换叙事 + UI 切换 + 难度曲线 jump 平滑度

### H3 后期挑战
- **H3.1**:Ch4-6 主线 + 心魔 + 群战 + 轻功 + 飞升 全玩家路径走查
- **H3.2**:跨派系战斗 / Boss 招降 / 飞升仪式 体验是否流畅
- **H3.3**:晚期内容厚度 vs 早期 audit(防虎头蛇尾)

### H4 D4 联动
- **H4.1**:balance_simulator csv 输出 → 映射 stage_id + numbers.yaml 行号
- **H4.2**:卡点 stage 调难度曲线 + 秒杀点调玩家路径

### H5 UX 微调
- **H5.1**:全 lib grep `SnackBar` 体例统一(色 / 时长 / icon)
- **H5.2**:空状态 widget audit(空背包 / 空徒弟 / 空奇遇 / 空声望)
- **H5.3**:loading widget 体例(CircularProgressIndicator vs Skeleton vs Shimmer)
- **H5.4**:错误处理(ErrorBuilder 全 wire / 图片缺失 fallback)
- **H5.5**:长列表性能(ListView.builder + lazy load · feedback_listview_widget_test_viewport)
- **H5.6**:`docs/UX_GUIDELINES.md` 起草(若 H-Q4 拍是)

### H6 文案 polish
- **H6.1**:全 `data/narratives/` 古风一致性 audit(Tier 风格梯度 · memory `project_wuxia_idle_ch4_cultural_arc`)
- **H6.2**:全 `data/lore/` 装备典故 audit(80 文件 170 段)
- **H6.3**:Ch1-3 events typo + 叙事流畅度(每个 event ≤ 7-8 行)
- **H6.4**:UiStrings 全段 grep typo + 古风一致性

## 5. 红线 / 风险

- **不破现有 1519 测族**(每 Batch 收尾 verify)
- **GDD §5.4 数值红线**不破:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000
- **UX 微调不要过度抽象**(memory `feedback_avoid_over_engineer_abstraction`):3 处不一样不抽,5+ 处不一样再考虑
- **文案 polish 风险**:lore 段每 typo 改是 commit 噪音 → 整批 lore 一次 commit
- **审美主观**:UX 微调 / 文案 polish 风险点高 → 用户最终拍板 + Claude 提候选 doc
- **H 段 vs D 段冲突**:H 卡点诊断需 D4 balance_simulator 数据驱动 → H4 串 D4

## 6. 验收

- [ ] H1 上手 30min 玩家全过 stage_01_01-01_05 + tutorial chip 全触发
- [ ] H2 Ch2-3 装备 / 心法 / 师徒 / 闭关 4 系统玩法深度 audit 通过
- [ ] H3 Ch4-6 + 心魔 + 群战 + 轻功 + 飞升 全 systems 流畅度通过
- [ ] H4 D4 卡点诊断 → numbers tune 闭环
- [ ] H5 UX 微调 4 类(空状态 / loading / 错误处理 / Snackbar)体例统一 + UX_GUIDELINES doc
- [ ] H6 全 narratives + lore + events typo / 古风 / 叙事流畅度 review 通过

## 7. 依赖 / 阻塞关系

- H4 卡点诊断依赖 D4 balance_simulator csv 数据
- H6 文案 polish 不阻塞 H1-H5 工程(可并行)
- H 段闭环 → D6 closed beta(GD §D)
- H 段不阻塞 E / F / G 段

## 8. closeout / 验收 doc

- 每 Batch 完成后:`docs/handoff/m15_h_<batch>_closeout_<date>.md` ≤80 行
- 最终段:`docs/handoff/m15_h_full_closeout_<date>.md` + CHECKLIST §H 6/6 全勾 + PROGRESS 顶段对齐

---

**核心提示**:H 段是"游戏好不好玩"的最后一公里。比 D 段(性能 / 数值红线)更主观,需 Claude + 用户双拍板。H1-H3 audit 完成后,再启 D6 closed beta(他人验)→ 反馈回收 → ship。
