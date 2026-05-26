# 会话 closeout · 2026-05-26 P4.1 1.1 polish · 候选 1+3 一波

> 体量 ≤60 行 · Mac+Opus 4.7 xhigh 主对话 ~30-45min(同会话续 Q6B 三项收齐后 cache warm 0.20-0.25× 锚)
> 范围:候选 3 character_panel sect NPC 集成 + 候选 1 文案扩 8 段
> 起点 main:`215df8c`(Q6B PR #15 squash)· 终点 main:`<PR>` squash

## TL;DR

P4.1 1.1 sect 子系统全 polish 收尾 ✅:① 候选 3 `_SectMembershipRow` widget(`character_panel_screen.dart:_LineageSection` 内 50 行 + `playerSectIdProvider` + `sectMembersProvider` + filter 排 founder/当前 character)+ UiStrings 2 段;② 候选 1 文案扩 8 段(Q6A 3 events outcome body 4→7-8 行 + 5 sect_candidates lore 3→6-7 行 · 加 NPC 背景细节/动机)。**1505 测全过 / 0 analyze · 1.0 release ~93% 维持 + sect 子系统全 polish 完整收尾**。

## 1. 流水

| 阶段 | 内容 | 实测 |
|---|---|---|
| Phase 0 | grep events 数 + character_panel 现状 + sect listMembers + UiStrings 体例 | ~10min |
| 候选 3 widget | `_SectMembershipRow` ConsumerWidget(沿 `_LineageDisciplesRow` 体例 50 行)+ Lineage Section build 加 + UiStrings 2 段 + import sect_providers | ~10min |
| 候选 1 文案 8 段 | 3 events accept/decline body 深度扩 + 5 sect_candidates lore 背景细节 | ~15-20min |
| verify + commit + PR | analyze 0 / test 1505 / commit + PR squash | ~5min |

## 2. 关键决策(自主)

1. **跳过 spec doc**:候选 3 改动小(50 行 widget · Q1-Q5 全 default · 沿 _LineageDisciplesRow 体例)+ 候选 1 纯文案 — 不必单立 spec doc
2. **跳过 widget test**:character_panel widget 极简(filter 1 行 · 沿 _LineageRow widget 体例)· trust the build + 1505 baseline 维持(memory `feedback_isar_widget_test_deadlock`)
3. **文案扩深度策略**:NPC 背景细节(母亲早逝 7 岁练剑 / 玉门关血流一夜 / 师弟出事自请放逐 / 杂学半生求归处 / 父亲炸塌成年礼)+ 性格动机 · 古风克制不滥情
4. **过滤 logic**:`!m.isFounder && m.id != character.id`(排玩家自己 + 排当前 character active · 避免显自己)
5. **空状态**:「门派人少」(sect.id null 或 0 NPC 同语义 · 4 字简洁)

## 3. 速度精度新锚(memory `feedback_opus_xhigh_interactive_duration` 续)

| task | 精度 | 备注 |
|---|---|---|
| polish 候选 1+3(spec sonnet baseline 1.5-2h xhigh)| **0.20-0.25×**(实测 ~30-45min)| 同会话续 Q6B 三项收齐后 cache warm + 改动小 + 文案熟例 · 沿 founder_buff 0.13-0.20× 锚附近 |

## 4. 不变量 + 下波

- **不变量沿用**:§5.4 红线 / §5.3 三系锁 / Riverpod / Isar / character_panel 1359 行 widget 0 破 / sect_screen 0 改 / 数据 schema 0 改 / Isar saveVersion 0.14.0 不动 · 1497→1505 测 baseline 维持
- **1.1 挂账续**:Pen 视觉验收 三项链路 + 文案 polish · `stageBossFailRecoverProb` 战败收降(P5+/1.1) · `candidateRefs` rng pick · stage_04_05+ 池扩 · Boss 招降 narrative(走 stage_<id>_boss_recruit 路径需 spec 扩 · 留 1.1)· events 文案再扩
- **下波候选**:① Pen Codex 视觉验收 三项链路(用户启 Pen · 异步 30-60min)② 切其他子系统(必须清理 · memory `feedback_clear_session_timing`)③ 收尾

---

**P4.1 1.1 polish 候选 1+3 一波 ✅** · 1 PR squash merge · 1505 测全过 · sect 子系统全 polish 完成 · 1.0 release ~93% 维持
