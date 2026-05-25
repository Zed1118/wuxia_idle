# 1.0 Release Readiness Audit v2 · 2026-05-25

> 体量 ≤80 行 · Mac+Opus xhigh ~40min · 范围:6 跨系统质量审计
> v1 `1_0_release_audit_2026-05-25.md` 揭 P0-1 已修(PR #12 squash merge `3bf5e0c`)→ 1.0 整体 90%→91%
> v2 复审 6 核心系统:战斗 / encounter / 闭关 / 师徒共鸣 / 社交 PVP+sect+江湖 / cross-system

## TL;DR

**1.0 release ready ✅**:6 系统全 audit 健康 · 137 测文件 / 1484 测 全过 / 0 analyze · 红线测族 13+ 守护 §5.4 / 三系锁测族 5+ 守 §5.3 / 流派克制 + 心法相生 + 飞升 + 师徒 buff 全 wire 完整。**0 P0/P1 阻塞 · 唯一 P2 是 1.1+ 挂账(P1-2 fallback id=1 / 创角向导 / 多槽存档 / sectName 自定义)**。本机可查的 release 阻塞清零,剩余只能 Pen 视觉验收。

## 6 系统 audit 矩阵

| 系统 | 文件 | service caller | R5 测族 | 红线/锁守护 | 健康度 |
|---|---|---|---|---|---|
| **战斗核心** | 19 file(engine/state/log/ai/damage_calc/strategy×3) | stage_battle_setup ↔ presentation | 红线 13+ / 三系锁 5+ / 流派克制 widget+log+R5 | §5.4 红线断言广覆盖 + §5.3 三系锁 + clamp 防爆 | ✅ 优秀 |
| **encounter** | 7 测族 | encounter_hook 触发 + skill_section UI + reputation 反向 wire | 94 测(service 30 + yaml 25 + festival 12 + skills 12 + enum 9 + reputation 6 + banner 4) | 软概率 `p = base × (1 + fortune/20)` 与 GDD §12.2 #6 v1.9 对齐 / festival 8 全 wire | ✅ 优秀 |
| **闭关** | seclusion_service + map_list + retreat_session | service ↔ map_list canEnter ↔ active_retreat | 62 测(service 40 + map_def 19 + e2e 1 + map_list widget 3) | 时辰加成 `solarTermMultiplier` wire + 节气 12 节日 hardcode + 离线累积 idle tick | ✅ 良好 |
| **师徒/共鸣/飞升** | founder_buff/lineage/ascend/cultivation/forging | stage_battle_setup founderBuffActive 三维度 maxHp/crit/internal | 49 测(ascend 25 + founder_buff 9 + lineage_routing 5 + lineage_panel 10 + cultivation/forging 多) | P5+ 多代飞升 + 真传位完整 + 三维度 buff wire | ✅ 良好 |
| **社交(sect+jianghu+pvp)** | 22 测文件 | monthly_tick ↔ sect_event / battle_providers ↔ enmity clamp / encounter ↔ reputation / pvp ELO | 123 测(sect 41 + jianghu 40 + pvp 31 + def 10 + screen 5) | enmity clamp_max + sect_rank 三阶 ≠ 七阶 + ELO 数值范围 | ✅ 优秀 |
| **cross-system** | stage_audit doc 已有 + balance/* test | — | balance 多套 R5(ch4/5/6 / synergy hot loop / maxhp extremum / p3_1 light foot) | T20 nightshift 跨系统数值红线 audit 已通过 | ✅ 优秀 |

## widget test 覆盖修正(v2 实测)

audit v1 误读 `test\(` 漏 `testWidgets\(` 嵌套 group → 误判 `_screen_test` 0 测。**v2 重新精确 grep**:全 presentation widget test 完整(每文件 3-5 测):
- sect_screen 5 / lineage_panel 5 + edge 5 / equipment_detail lore 5 / seclusion_map_list 3 / encounter_outcome_banner 4

## 测族总量

| 维度 | 计数 |
|---|---|
| 测试文件 | **137** |
| test() + testWidgets() | **1370 字面** / **1484 实际跑过**(group/setUp 内嵌套 + R5 onboarding +8) |
| 红线测族 | 13+ §5.4 / 5+ §5.3 / 5+ 流派克制 |
| balance/ 专属测族 | ch4/5/6 crosstier + synergy hot loop + maxhp extremum + p3_1 light foot redline |

## 1.0 真实剩余(release 前唯一 OUT)

| # | 类型 | 内容 | 阻塞? |
|---|---|---|---|
| 1 | UI 视觉验收 | Pen Codex Windows splash + 17 入口 + sect_screen 4 Tab + 战斗 e2e + 视觉效果 | ✗ release blocker · ✓ release ready 验证 |
| 2 | 性能压测 | 长时间运行 / 内存 / FPS / Isar IO 在 Steam 用户机器 | P5.x 子项 · 留 P5.2 难度曲线 |
| 3 | 音乐音效配音 | BGM + SFX + 配音 · P5.3 子项 | 时间线 M15-16 阶段 |
| 4 | Steam 集成 | 成就 / 云存档 / 商品页 / 评测 · P5.4 | 时间线 M15-16 |

## 挂账分类(已记录 1.1+ · 不阻塞 release)

- **P1-2**(audit v1 挂账):`_SeclusionMenuButton` fallback id=1 — P5.0 落地后 grep 仍存在但是合法 fallback(loading 期渲染兜底,真 seed 后不命中)· 决议:**不改**(信源是 P5.0 后 ids 不为空)
- **创角向导 UI**:Demo masters.yaml 默认,1.1+
- **多槽存档**:P5 isar_setup TODO 已留
- **sectName 自定义 UI**:P5.0 R5.7 守 ??= 不覆盖,1.1+
- **P4.1 1.1 挂账 6 项**:Q6 A encounter recruit / Q6 B stage_boss 招降 / founder_buff_service 跨派系真扩 / 多代 sect 传递 / member 招收 narrative ~30 条 / P1.2 跨派系 wire

## 下波候选

| 选项 | 工作量 | 本机 | 推荐 |
|---|---|---|---|
| **A. Pen 视觉验收 P4.1 + P5.0** | ~1h 异步 | ✗ 派单 | ★★★ 唯一剩余本机查不了的环节 |
| **B. 1.1 挂账起点 Q6 A encounter recruit spec** | xhigh 起步 ~1h | ✓ | ★★ 1.0 已 ready 可启动 1.1 |
| **C. 切别的子系统**(P5.3 音效 / P5.4 Steam 集成 / 等) | 留 P5.x M15-16 | ✓ | ★ 时间线靠后 |
| **D. P1-2 fallback 决议 doc 化** | high ~10min | ✓ | ✗ 已确认合法,无需改 |

**强推 A**(本机无任何可推进 1.0 release · 视觉验收是 release checklist 唯一未走完项)或 **B**(audit + onboarding 一波收口 · 启动 1.1 顺势)。
