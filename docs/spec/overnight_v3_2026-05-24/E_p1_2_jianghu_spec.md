# Worktree E · P1.2 江湖恩怨 + 声望 spec 草案(Q1-Q5 默认决议版)

> 分支:`feat/p1_2_spec` · 路径:`../wuxia_idle-p12-spec` · 模型:**opus xhigh** · 估时:~2h
> 上游 phase0:`docs/phase0/p1_2_jianghu_enmity_phase0_2026-05-24.md`(Q1-Q5 候选清单)
> 沿例:`docs/spec/p2_3_ascension_spec_2026-05-24.md`(9 节 spec 体例)+ `docs/spec/p3_2_mass_battle_spec_2026-05-24.md`
> **重大边界**:本 worktree **只起 spec doc · 0 实装**。用户起床改 Q1-Q5 后,根据新决议改 spec,再起新 worktree 实装。

## 0. 起会话第一动作

```bash
cd ../wuxia_idle-p12-spec
git pull --rebase origin main
cat docs/spec/overnight_v3_2026-05-24/E_p1_2_jianghu_spec.md
```

读完 spec 后:
1. 读 `docs/phase0/p1_2_jianghu_enmity_phase0_2026-05-24.md`(Q1-Q5 候选 · 全文)
2. 读 `docs/spec/p2_3_ascension_spec_2026-05-24.md`(spec 9 节体例)
3. 读 GDD.md §12.1 / §12.2 / §5.2 / §5.4(红线 + 江湖恩怨/声望占位)
4. 读 `lib/features/inheritance/`(founder_buff_service 体例参考)
5. 读 `lib/features/battle/` 中 `attackPowerMultiplier` 接入(P3.1.B view layer 体例)

## 1. 任务范围

**核心 deliverable**:基于 phase0 Q1-Q5 的「默认决议版」起草 spec doc · 用户起床改 Q1-Q5 决议后,只需改 spec 不需要重写。

### Q1-Q5 默认决议(本 spec 假设)

| Q | 默认决议 | 理由 |
|---|---|---|
| Q1 §12.1 + §12.2 合批/拆批 | **B 拆批**:声望先 ~4-6h · enmity 后 ~6-8h | 降单波风险 · 用户 8h v2 后偏好小步快跑 |
| Q2 NpcRelation schema 粒度 | **B 稀疏 NpcRelation{source,target,type,level}** | 全连接 N×N 矩阵爆 schema · 单向 enmity 不够表达 |
| Q3 触发维度 | **A stage_boss kill + B encounter NPC** | C 心法 / D narrative 留 1.1 扩 · A+B 覆盖 Demo §8.4 主轴 |
| Q4 NPC 反应影响 | **A UI narrative + B 战斗 ±15-25%** | 沿 P3.1.B `attackPowerMultiplier` view layer 体例 · D 援军 stage 留 1.1 |
| Q5 声望分阶 | **A 沿 §5.2 七阶节奏** | 锁三系 · 不为 P1.2 单开新阶 anti-pattern |

⚠ **本 spec 是基于默认决议的「示意稿」· 不替代用户拍板**。用户起床改 Q1-Q5 → 改 spec(可能批 sec 2/3/4/5 改) → 实装。

### spec doc 体例(沿 p2_3_ascension_spec 9 节)

```
docs/spec/p1_2_jianghu_enmity_spec_2026-05-24.md(新)
├── 0. Q1-Q5 决议(用户拍板后填 · 本批默认决议占位)
├── 1. 范围(in / out)
├── 2. schema 改动(Isar Reputation + NpcRelation Collections)
├── 3. service 层(ReputationService / NpcRelationService / EncounterIntegration)
├── 4. UI 接入(ReputationPanelScreen + Hud 角标 + narrative 分支)
├── 5. 战斗整合(attackPowerMultiplier 接入 enmity ≥ 阈值)
├── 6. 数据流(yaml schema + 加载层)
├── 7. R5 红线测族(声望覆盖 7 阶 · enmity 阈值 · 战斗 buff)
├── 8. Batch 拆分(B1 schema · B2 trigger · B3 UI · B4 R5/doc)
└── 9. 估时 + 风险 + 挂账
```

**OUT(本 worktree 不做)**:
- ❌ 实装任何 Isar Collection / Service / UI / 测试
- ❌ 改 numbers.yaml(数值留 spec 引用 numbers.yaml.<key> · 实装时再加)
- ❌ 改 GDD.md / data_schema.md(留用户审稿)
- ❌ Q1-Q5 拍板(只用默认决议起 spec · 用户改后用户改 spec 或新会话改)

## 2. 自主决策清单

| 决策点 | 默认决议 |
|---|---|
| spec doc 体例 | 沿 p2_3_ascension_spec_2026-05-24.md 9 节 · 不超 150 行 |
| Batch 拆分粒度 | B1 schema 2h · B2 trigger 2h · B3 UI 1.5h · B4 R5/doc 1.5h(沿 phase0 估时) |
| R5 测族数 | ~10-12 测(声望 7 阶 / enmity 4 阈值 / buff 3 维) |
| 实装顺序假设 | 声望先(独立子系统)→ enmity 后(依赖声望) · 沿 Q1=B 拆批默认 |
| 与 P3.4 sect_reputation 隔离 | spec 加 1 行「P3.4 sect 维度独立 · 不共用 Reputation Collection」 |

## 3. 估时与里程碑

| 里程碑 | 估时 | 产出 |
|---|---|---|
| M1 phase0 + p2_3 spec 体例阅读 | ~20min | 内化体例 |
| M2 §0-3 起草(决议 + 范围 + schema + service) | ~40min | spec 前 4 节 |
| M3 §4-7 起草(UI + battle + 数据流 + R5) | ~40min | spec 中 4 节 |
| M4 §8-9 起草(Batch + 估时风险) | ~15min | spec 尾 2 节 |
| M5 终审 + push + 草稿 PR | ~15min | doc ≤150 行 + PR |

## 4. 实装边界自查(写 spec 时遵守)

- 写 schema 时引用 `lib/features/<module>/domain/` 类似体例(找 1-2 个具体例子写 dart 块)
- 写 service 时引用 `founder_buff_service.dart` / `ascend_service.dart` 体例
- 写 UI 时引用 `LineagePanelScreen` / `AscensionScreen` 体例
- 写 battle 接入时引用 `LightFootStrategy.attackPowerMultiplier` 体例(P3.1.B)
- 写 R5 时引用 `derived_stats_*_test.dart` + 跨阶红线测族体例
- **不发明新 abstraction** · 全沿已实装体例

## 5. PR 体例

```bash
git add docs/spec/p1_2_jianghu_enmity_spec_2026-05-24.md
git commit -m "[spec] P1.2 江湖恩怨 + 声望 spec 草案(Q1-Q5 默认决议版)"
git push -u origin feat/p1_2_spec
gh pr create --draft --title "[spec] P1.2 江湖恩怨 + 声望(默认决议草案)" --body "$(cat <<'EOF'
## 概要
基于 phase0 Q1-Q5 「默认决议版」起 P1.2 spec doc。**用户起床改 Q1-Q5 决议后再改 spec 再实装**,本 PR 仅 spec 草案 0 实装。

## 默认决议(用户可改)
- Q1 拆批(声望先 ~4-6h · enmity 后 ~6-8h)
- Q2 稀疏 NpcRelation
- Q3 stage_boss kill + encounter NPC
- Q4 UI narrative + 战斗 ±15-25%(沿 P3.1.B)
- Q5 沿 §5.2 七阶

## 改动
- `docs/spec/p1_2_jianghu_enmity_spec_2026-05-24.md` (新 ≤150 行)
- 0 code / 0 schema / 0 数值 / 0 GDD 改

## 用户起床操作建议
1. 改 spec §0 决议表(Q1-Q5 用户实际拍板)
2. 若决议偏离默认大 → spec §2-7 局部改
3. 起新 worktree 跑实装(spec §8 Batch 1)
EOF
)"
```

会话清理建议:**必须清理**(spec 单波闭环 · 实装是下一个 worktree)
