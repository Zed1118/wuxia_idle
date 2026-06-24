# 接通 11 招未接线 encounter skill（2026-06-25 · overnight 自主推进）

> 状态：design（用户睡觉离线，自主拍板推进，feedback_user_offline_autonomous）
> 阶段：1.0 长线打磨期 · 健康报告 #3 收口
> 范围：**纯内容 + 接线层**（encounters.yaml + events/ 文案），0 碰战斗数值/红线/引擎
> 模型：opus

## 1. 背景 & 定性

健康报告（`project_health_review_2026-06-25.md` #3）查出：encounter_skills.yaml 池 40 招，仅 29 招被 encounter `unlockSkill` outcome 引用，**11 招零引用 → 玩家无法解锁获得**。

定性结论（已 code-grounded 调查，详对话）：**漏接（已创作内容搁浅），非有意预留**——11 招全有完整武侠文案（非占位）、tier 跨早期（含 tier1）、违背池「奇遇解锁」用途、零延期标注。唯一解锁路径 = encounter `unlockSkill` outcome → 写 `SaveData.skillUnlockProgress`（encounter_service.dart:298）。

**处置 = 方案 A 接线**：给 11 招各配一个 `techniqueInsight` 奇遇，让已创作内容玩家可得。

## 2. 11 招接线映射表

每招配 1 个 techniqueInsight encounter（沿 `bamboo_listen_rain` 体例），trigger 难度按 tier 递增（fortuneRequired 2→8 + biome/weather 分钟门槛），outcomeMapping 3 项：`insight_success`(unlockSkill) / `practice_partial`(attributeBonus +1) / `skip`(none 隐式)。

| # | skill | tier | type | encounter id | trigger | fortuneReq | practice attr |
|---|-------|------|------|-------------|---------|-----------|---------------|
| 1 | jian_bu 渐步 | 1 | power | `shan_jing_wu_bu` 山径悟步 | biome mountainPath 120 | 2 | agility |
| 2 | tun_tu 吞吐 | 1 | power | `gu_si_tu_na` 古寺吐纳 | biome temple 120 | 2 | constitution |
| 3 | huo_du 活渡 | 2 | power | `du_kou_cuo_ying` 渡口错影 | biome dock 180 + rain 60 | 3 | agility |
| 4 | lie_huo 烈火诀 | 4 | power | `da_mo_zhang_yan` 大漠掌炎 | biome desert 300 + clear 120 | 5 | enlightenment |
| 5 | fei_xian 飞仙步 | 4 | power | `xuan_ya_ling_xu` 悬崖凌虚 | biome cliff 300 | 5 | agility |
| 6 | jin_gang 金刚不坏 | 5 | power | `jiang_xin_heng_jin` 江心横劲 | biome dock 360 | 6 | constitution |
| 7 | shan_he 山河剑 | 5 | power | `fei_pu_lian_jian` 飞瀑练剑 | biome cliffWaterfall 360 | 6 | enlightenment |
| 8 | lei_dian 雷电诀 | 5 | ultimate | `shan_dian_yin_lei` 山巅引雷 | biome mountainPath 360 + rain 120 | 6 | enlightenment |
| 9 | qian_kun 乾坤掌 | 6 | power | `bian_chui_tui_zhang` 边陲推掌 | biome frontier 420 | 7 | enlightenment |
| 10 | lie_yan 烈焰焚天 | 6 | ultimate | `huang_sha_fen_kong` 黄沙焚空 | biome desert 420 + clear 180 | 7 | enlightenment |
| 11 | xuan_bing 玄冰诀 | 6 | ultimate | `xue_ya_ning_han` 雪崖凝寒 | biome cliff 420 + snow 180 | 8 | agility |

trigger 主题匹配招式：步法→mountainPath/cliff、内息→temple、渡/闪→dock、火→desert+clear、剑/激流→cliffWaterfall、雷→mountainPath+rain、寒→cliff+snow、天地之势→frontier。

attributeKey 合法值仅 4：constitution/enlightenment/agility/fortune（无 strength）。掌剑悟道类给 enlightenment(悟性)，步法身法给 agility，内息护体给 constitution。

## 3. 文案规范（content_guide.md + wuxia-content skill）

每招 `events/<id>.yaml`：id(=encounters id 强对齐 §8.1) / title(4字诗意) / opening(镜头切入·古龙铺氛围40+金庸物候60·长短交错) / choices×3。
- choice1 → outcome_id `insight_success`（悟成）
- choice2 → outcome_id `practice_partial`（半得）
- choice3 → outcome_id `skip`（离去）

禁忌（硬核对）：无现代词 / 无虚构地名（用通用地貌：山径/古寺/渡口/悬崖/飞瀑/大漠/雪崖/边陲，非「思过崖」式虚构专名）/ 器物建筑植物细到品类 / 情绪投射环境。

## 4. 验证

- C2 启动期强校验（本周期刚加）会强制：11 个新 encounter 必有对应 events 文件 + outcome_id 全在 outcomeMapping → 漏写即 fail-fast。
- 全量测试（encounter_yaml_test 数量断言会变 57→68，需同步更新）+ analyze 0。
- encounters ↔ events id 1:1（57→68 对齐）。
- 0 碰 numbers.yaml / 战斗红线 / skills 倍率。

## 5. 顺手收口（健康报告 #4）

`encounter_skills.yaml` 头注「共 35 招」stale → 改「共 40 招」（实测）。

## 6. 范围外

不裁池、不改 11 招 def 本身（倍率/文案）、不动 narrativeInsightId 映射、不碰战斗数值。
