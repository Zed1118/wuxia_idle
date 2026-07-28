# Ch20「东入阳关」章级设计 spec — 武圣段中章 · 夜批自主拍板(晨间可推翻)

**日期**:2026-07-28(夜批·用户睡眠授权自主推进) · **载体**:main 直落
**承**:段级 spec `2026-07-28-wusheng-arc-ch19-21-design.md` §10 前瞻 + §12 难度定调(A 基调) · Ch19「旧路照人」章尾(合镜东行·前面是阳关)
**前置实测**:HEAD `ecdbe4a4` · main 全量 4712/0(合并态实测) · 19 章 95 关 · cap 45

## 1. Phase 0 实测(2026-07-28 夜批现测)

| 维度 | 实测值 |
|---|---|
| stage_20 存在性 | **0**(净) |
| Ch19 曲线终点 | HP 58000 · 攻 2000 · 速 380 · diffMult 20.8 · exp Σ482 · cumExp 4569 |
| tier7 敌招闲置 | lingqiao_fang 组(3·全新)/ gangmeng_nei 组(3·全新)/ gangmeng_ult·lingqiao_ult(基础组 ult 未用) |
| 真解档位 canon | `skills.yaml:3027`「取 7000 留 Ch20/21 各一档(候选 7400 / 7800)」→ **本章 7400** |
| 神物账 | 11 件 · Ch19 投 4(po_jun_dao/xuan_huang_pao/tian_wen_jian/kun_lun_pei)· **余 7** |
| 人物锚 | **送关旧部** `enemy_zongShi_liangzhouci_songguan_jiubu`(16_01 阳关外驿道 · zongShi·qiMeng·**gangMeng** · 立绘 `liangzhou_songguan_jiubu.png` 在库) |
| 生产可见性现值 | strings `chapter19Title:1441/Hint:1460`+两 switch · mainMenuMainlineHint「19 章 95 关」:1405 · status_summary `<=19`:156 |
| stale 注释 | Ch19 批已修(numbers:1392/masters:4 grep 证) |

## 2. 章级拍板(六项 · 夜批自主全 A)

| # | 决策点 | 拍定 | 理由 |
|---|---|---|---|
| 1 | **章名** | **「东入阳关」** | 与 Ch4「西出阳关」整弧对仗;回望弧第二拍=真正过关东归 |
| 2 | **关序** | 旧驿东行→望关→关下→关门→**关册**(黑石→驿道→阳关,地理正推) | 既有人物天然落 {4,5},Boss 位体例不动 |
| 3 | **末 Boss** | 新人物**记关人**(wuSheng·yuanShu=cap 47 同层·lingQiao)·关册题眼:登记过每个西行名字的人,等一个能销账的东归者 | 19_05 体例(末 Boss=cap 同层);lingQiao 平衡三章 school 分布 |
| 4 | **真解** | **`skill_yang_guan_you_gu_ren`「阳关有故人」**(tier7·lingQiao·mult **7400**·mainline_drop·记关人本命,chargeSkill 双用) | 与 Ch18 真解「阳关无故人」一字反转,双重镜像收弧;7400=canon 预留档;撞名 grep 0 |
| 5 | **神物第二批 4 件** | `weapon_shenwu_huan_meng_bian` / `weapon_shenwu_hun_yuan_chui` / `armor_shenwu_bing_can_yi` / `accessory_shenwu_she_li_zhu`(余 3 件恰给 Ch21:1w+1a+1acc 自平衡) | 4+4+3 分配;本批 2w+1a+1acc |
| 6 | **机制层** | 20_04 送关旧部:**vuln 0.18 + chargeCounter 两相位**(章中首带 vuln=段级「复合化」台阶);20_05 记关人:**vuln 0.12 + cycleVulnerability 2:0.06 + 两相位(0.9/0.5)**;两值实装后探针校准可调 | 段级拍板 7A「复合方向·不预钉」+§12 定调 A(参与度与时长,不追威胁) |

## 3. 五关设计

| 关 | 名 | 敌 | 层 | school | HP | 攻 | 速 | diffMult | exp | 敌招 |
|---|---|---|---|---|---|---|---|---|---|---|
| 20_01 | 旧驿东行 | 换马人(新) | shuLian | lingQiao | 58200 | 2000 | 382 | 21.0 | 86 | lingqiao basic+skill(喘息) |
| 20_02 | 望关 | 望关卒(新) | shuLian | yinRou | 58400 | 2000 | 384 | 21.2 | 88 | yinrou basic+skill(喘息) |
| 20_03 | 关下 | 关下石户(新) | jingTong | gangMeng | 58600 | 2000 | 386 | 21.4 | 90 | gangmeng basic+skill+**ult**(ult 化起点·gangmeng_ult 首用) |
| 20_04 | 关门 | **送关旧部**(16_01 复出·gangMeng 沿定) | jingTong | gangMeng | 58800 | 2000 | 388 | 21.6 | 110 | **gangmeng_nei 组×3**(全新首用)·chargeSkill=nei_ult·Boss |
| 20_05 | 关册 | **记关人**(新) | yuanShu | lingQiao | **59000** | 2000 | 390 | 21.8 | 131 | **lingqiao_fang 组×3**(全新首用)+真解双用·Boss |

- 曲线延 Ch19 体例:HP +200 步(段中不回落·末=段级 §7 预算 59000)· 速 +2 · diffMult +0.2 · exp Σ**505**(cumExp 4569→**5074**)。
- cap **45→47**(within-tier·wuSheng 内,releaseTier 不变,**非 cross-tier**,无三系连动)。
- requiredRealm 全 wuSheng · 20_01 无 prevStageId(章首体例)· Boss 位 {4,5} · 敌招零新增(段级拍板 4A)。

## 4. 叙事(13 篇 · 回望弧第二拍)

- chapter_20 卷首尾 + 5 opening + 5 victory + 20_04/20_05 defeat = 13 篇,~6000 字带内。
- 题眼:**关册销账**——四十年来只添行不销行的册子,第一次有人回来划掉自己的名字;「西出阳关无故人」在关门里侧被翻过来。
- 人物连续性:送关旧部=16_01「送人出关」者,东归者他**得接一回**;半面镜(已合)贴肋 motif 延续。
- **动笔前必核 canon(Phase 0.5)**:阳关/嘉峪关两关口关系——`chapter_19` epilogue「四十年前有个背剑的从那道关门出去」vs Ch5 canon 李寒行程「折回嘉峪关」(`chapter_05:6`),Ch16/Ch4/Ch5 原文先读再动笔,**不得顺手编设定**。
- 风格词(wuSheng 文化弧):湛然/寂照/圆融/化机 · 黑名单/现代词 grep 0。

## 5. reconcile 站点(§8 段级清单 19→20 平移 · within-tier 版)

- count 95→**100**:CSV byte-lock 重生 / game_repository mainlineCount / narrative completeness 章循环 [1..20] / balance_simulator / readable_tempo 终章 19_05→20_05。
- boss 敌 40→**42** / catalog 53→**55** / skill 计数 **217→218 / 257→258 三站点** + cap 断言 `numbers_config_progression_release_cap_test` 45→47。
- progression 逐值实测禁猜:release_budget 首通 / idle_horizon 缺口+下沿(连续三章下调 45→40→35→30,本章续测)/ enhancement_material_supply 结晶上界。
- 生产可见性:chapter_list _chapters+20 / strings chapter20Title·Hint+两 switch / mainMenuMainlineHint「20 章 100 关」/ status_summary ≤20 / boss_memory chNum。
- GDD 状态块(cap 47 / 20 章 100 关)+§8.1 章表+招式池 · wave_b 白名单+新真解 · known_missing +11 图(前缀 `ruguan_*`)+ standee overrides +5。

## 6. 红线守卫

- Boss HP ≤59000 < 60000 · 攻钉 2000 · 真解 7400 ≤8000 · 敌招全 tier7 不降档。
- 20_01 无 prevStageId · 末 Boss chargeSkillId ∈ skillIds 双用 canon · cycleVulnerability key=周目数(≥2)且必先配 vulnerability(Ch19 spec 踩过的坑)。
- 机制只走减伤方向(§5.4 例外条款);在线=离线;§5.1 反主流不碰。
- 破坏证红 commit 后做:真解 mult 7400→9000 RED / 摘 dropSkillManualId RED,各还原复绿。
