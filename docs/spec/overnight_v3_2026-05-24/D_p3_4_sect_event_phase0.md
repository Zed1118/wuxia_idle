# Worktree D · P3.4 门派事件 Phase 0 6 维 + P1.2 依赖梳理

> 分支:`phase0/p3_4_sect_event` · 路径:`../wuxia_idle-sect-p0` · 模型:**opus high** · 估时:~1.5h
> 上游:GDD.md §12 + ROADMAP_1_0.md(P3.4 占位)+ memory `feedback_phase0_grep_two_axes`
> 依赖锚:P1.2 江湖恩怨/声望(D 批 phase0 doc · 用户起床拍板)+ P5+ 师徒传承(已实装)
> 沿例:`docs/phase0/p1_2_jianghu_enmity_phase0_2026-05-24.md`(D 批 Phase 0 体例)

## 0. 起会话第一动作

```bash
cd ../wuxia_idle-sect-p0
git pull --rebase origin main
cat docs/spec/overnight_v3_2026-05-24/D_p3_4_sect_event_phase0.md
```

读完 spec 后:
1. 读 `docs/phase0/p1_2_jianghu_enmity_phase0_2026-05-24.md`(P1.2 依赖锚)
2. 读 memory `feedback_phase0_grep_two_axes`(6 维 grep 体例)
3. 读 GDD.md §12.4(门派事件占位)
4. 读 ROADMAP_1_0.md(P3.4 段)
5. 读 `lib/features/inheritance/`(P5+ 师徒系统现状 · sect 概念是否已隐式存在)

## 1. 任务范围

**核心 deliverable**:
- Phase 0 6 维 grep 全跑(沿 P1.2 体例):
  - A schema(Sect / SectEvent / SectTask / SectBuilding / SectDisciple)
  - B caller(谁会调用 SectService)
  - C 邻近系统(FounderBuffService / DiscipleService / InheritanceService 现状 · sect 已隐式?)
  - D UI widget(SectPanel / SectEventScreen / SectMissionScreen 候选)
  - E 红线层(GDD §12 门派事件占位 + ROADMAP P3.4)
  - F 公式层(numbers.yaml sect / event 段)
- **P3.4 与 P1.2 依赖梳理**(独立段):
  - P1.2 声望 / NpcRelation 是否是 P3.4 sect_reputation 的前置?
  - P3.4 门派事件触发是否依赖 NPC 关系网?
  - 是否能 P3.4 先于 P1.2 实装(独立 sect_reputation)?
- 5 项 Q&A 候选清单(起床用户拍板 · **无推荐**):
  - Q1 sect 粒度:A 玩家自建门派(Founder 即开派) / B 加入既有门派(选少林/武当...) / C 双轨可切
  - Q2 sect_event 类型:A 比武大会(PVP-lite) / B 弟子任务(挂机外包) / C 门派危机(防御战) / D A+B+C 全
  - Q3 sect_reputation 与 P1.2 声望关系:A 独立轴 / B 共用 P1.2 reputation / C P3.4 派生于 P1.2 NpcRelation
  - Q4 sect_building 是否做:A 是(建主殿/藏经阁/演武场) / B 否(纯抽象 sect_level) / C P3.4 否 1.1 做
  - Q5 与 P5+ 师徒系统整合:A sect 即 lineage(founder=掌门 · disciple=门人) / B 独立(sect 包 founder + 多代 lineage)/ C P5+ 飞升后才解锁 sect 升级
- 输出 `docs/phase0/p3_4_sect_event_phase0_2026-05-24.md`(≤80 行)
- 输出 GDD §12.x 升档草案段

**OUT(不做)**:
- ❌ 实装任何 sect code
- ❌ 拍板 Q1-Q5
- ❌ 改 GDD.md / numbers.yaml
- ❌ 与 P1.2 strong coupling 假设(用 if-then 列依赖,不预设)

## 2. Phase 0 6 维 grep 命令(参考)

```bash
# A schema
grep -rEi "class\s+(Sect|SectEvent|SectTask|SectBuilding|SectDisciple)" lib/ --include='*.dart'
# B caller
grep -rEi "SectService|sectService|enterSect|joinSect" lib/ --include='*.dart'
# C 邻近(P5+ 师徒)
ls lib/features/inheritance/
grep -rEi "门派|sect" lib/ data/ --include='*.dart' --include='*.yaml' | head -30
# D UI
grep -rEi "(Sect|Lineage).*(Screen|Widget|Page)" lib/ --include='*.dart'
# E 红线层
grep -nEi "门派|sect|宗派" GDD.md ROADMAP_1_0.md
# F 公式层
grep -nEi "sect|宗" numbers.yaml
```

## 3. 自主决策清单

| 决策点 | 默认决议 |
|---|---|
| sect 是否已隐式存在 | inheritance 模块 founder/lineage 是 sect 基础 · 列已有 vs 缺失对照 |
| P1.2 强依赖判定 | Q3 列 A/B/C 3 候选 · 不预设 strong coupling |
| GDD §12.x 升档草案 | 沿 P1.2 体例 · 列触发/红线/数据流 |
| Q&A 候选数 | 每 Q 3-4 选项 · 不推荐 |

## 4. 估时与里程碑

| 里程碑 | 估时 | 产出 |
|---|---|---|
| M1 6 维 grep + inheritance 现状阅读 | ~30min | grep 输出 + 现状段 |
| M2 P3.4 ↔ P1.2 依赖梳理 | ~20min | 依赖段 |
| M3 Q1-Q5 候选起草 | ~25min | Q&A 表 |
| M4 GDD §12.x 升档草案 | ~10min | 草案段 |
| M5 phase0 doc 完稿 + push + 草稿 PR | ~15min | doc ≤80 行 + PR |

## 5. PR 体例

```bash
git add docs/phase0/p3_4_sect_event_phase0_2026-05-24.md
git commit -m "[phase0] P3.4 门派事件 · 6 维 reality check + P1.2 依赖梳理 + Q1-Q5 候选"
git push -u origin phase0/p3_4_sect_event
gh pr create --draft --title "[phase0] P3.4 门派事件 Phase 0 + P1.2 依赖" --body "$(cat <<'EOF'
## 概要
P3.4 门派事件 Phase 0 6 维 reality check + 与 P1.2(江湖恩怨/声望)依赖梳理 + Q1-Q5 主轴未拍板候选。**不实装**。

## 改动
- `docs/phase0/p3_4_sect_event_phase0_2026-05-24.md` (新)
- 0 code / 0 schema / 0 数值 / 0 GDD 改

## 验证
- 6 维 grep 结论列具体 hit 文件:行号
- inheritance 模块现状段(sect 隐式 vs 显式)
- P3.4 与 P1.2 依赖梳理 3 维(声望 / NpcRelation / 触发)
- Q1-Q5 候选 ≥ 3 选项/Q · 无推荐
EOF
)"
```

会话清理建议:**必须清理**(Phase 0 单波闭环)
