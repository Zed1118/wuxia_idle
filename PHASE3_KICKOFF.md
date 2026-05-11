# Phase 3 起点 · Kickoff

> 上一阶段：v0.2.0-phase2 已交付（2026-05-11，merge `5efe8d5`）+ #24 装备名 fixup 落地（`5ce76f5`）。
> 新会话起手必读：本文件 + `PROGRESS.md` + `GDD.md §7-§8` + `CLAUDE.md §7 + §12`。

---

## 一、最新状态快照

| 项 | 状态 |
|---|---|
| 分支 | `main`（HEAD `5ce76f5`，origin 同步） |
| 测试 | 335/335 全绿，`flutter analyze` 0 issues |
| 最新 tag | `v0.2.0-phase2` (5efe8d5) |
| 当前阶段 | Phase 2 已收尾，Phase 3 待规划（phase3_tasks.md 未建） |
| 已合并分支 | feat/phase2-equipment（no-ff，含 T19-T32 全部 commits）、fix/24-equipment-name（ff） |

## 二、本次会话交付（2026-05-11 第 2 段）

1. **T32 子提交 5 收尾**：
   - 6 截图 Windows Pen 视觉验收（5 ✅ + 1 ⚠️ → 衍生 #24）
   - `phase2_summary.md` 填充：P1 蒙卡实测 0.759 (seed=42)、6 截图 markdown 链接、§四 性能基准说明改"暂未采集"
   - `docs/screenshots/phase2/` 归档 6 截图（01-06）
   - tag `v0.2.0-phase2` 打在 merge commit `5efe8d5`，已 push origin

2. **#24 装备名 fixup**（`fix/24-equipment-name` → main ff，`5ce76f5`）：
   - `inventory_screen.dart _Row.build`：def 查询从 onTap 提到 build 顶（同步 + try/catch 兜底 null）；Row 加 `def.name` 列（Flexible + maxLines:1 + ellipsis）
   - `enhance_dialog.dart _Header`：新增可空 `def` 参数；preview header Column 顶部加 `def.name` 主标题（16px w700）
   - 2 widget test（inventory + enhance_dialog 各 1）用 `weapon_liqi_long_quan` 验证「龙泉剑」显示
   - PROGRESS.md 销账 #24 挪归档区

## 三、Phase 3 范围（GDD §7-§8 + CLAUDE.md §7）

| 项目 | 数量 | 备注 |
|---|---|---|
| 主线关卡 | 15-20 | 3 章（学武出山 / 武林初识 / 名扬江湖），剧情字数 3000-5000（DeepSeek） |
| 爬塔 | 30 层 | 3 小 Boss [5/15/25 层] + 3 大 Boss [10/20/30 层] |
| 闭关地图 | 5 | 兵器/心法/属性/共鸣/... 偏向不同（待 CLAUDE §12 #5 决策） |
| 奇遇 | 20-30 | encounters.yaml（你）+ events/ DeepSeek |
| 师徒传承 | 祖师+大弟子+二弟子 | 遗物受三系锁死（CLAUDE §5.3），细节挂账 §12 #10 |
| 武学领悟 | 30-50 招 | + 20-30 触发条件（机缘值累积规则挂账 §12 #6） |
| 心法相生组合 | ≥ 5 | techniques.yaml |
| 角色生成 | 4 属性 roll | 总和 16-24（单项范围挂账 §12 #2） |

## 四、起手第一议题（不要直接开 phase3_tasks.md）

跟用户讨论 Phase 3 范围切分 + 里程碑。三个潜在切法：

- **A. 数据 model 优先**：先建主线/爬塔/闭关/奇遇 的 Isar collection + yaml schema + repository + service（先打地基，UI 留 Week 2-3）。优势：测试驱动、UI 改动隔离；劣势：前 1-2 周看不到"游戏感"。
- **B. 主线优先**：先做 1 章主线 + 关卡服务 + 主线 UI 玩通，再开爬塔/闭关。优势：早期能玩；劣势：后续加新系统可能反推改主线 model。
- **C. 师徒传承优先**：解锁 Phase 2 遗留挂账 #22（P2/P4 战斗 stub），`character_to_battle` helper + 师徒数据 model 先做。优势：清积压；劣势：与 Phase 3 主推「主线/爬塔/闭关」无直接关系。

讨论敲定后再开 `phase3_tasks.md`（Phase 1/2 的 tasks 文档体例参考 phase1_tasks.md / phase2_tasks.md）。

## 五、CLAUDE §12 待决项（Phase 3 期间会触发）

实现到对应位置时**主动停下问用户**，不要凭训练数据补脑：

| # | 待决项 | 触发时机 |
|---|---|---|
| 1 | 境界 7 层 vs 心法 9 层名重叠（6 个完全重叠） | UI 显示主修/辅修层级前 |
| 2 | 基础属性单项数值范围（总和 16-24，单项？σ？） | CharacterGenerator 实现前 |
| 4 | 暴击系数 1.5-2.5 分布规则 + 防御率公式 | 战斗公式补完时 |
| 5 | 闭关 5 地图产出公式 | 闭关 service 实现前 |
| 6 | 武学领悟"机缘值"累积规则 | 领悟系统实现前 |
| 10 | 师承遗物细节（传递时机/多徒弟/buff 累代/部位冲突） | 师徒传承 model 实现前 |
| 11 | 祖师爷门派 buff（接口预留即可） | 师徒传承 service 起手 |

详见 `CLAUDE.md §12`（共 13 条）。

## 六、Phase 2 遗留挂账（Phase 3 期间会碰到）

- **#22 P2/P4 战斗 stub**：character_to_battle helper 留到师徒传承一并做（潜在切法 C）
- **#23 widget test 不接真 Isar**：Phase 5 Riverpod 3.x + IsarProvider 注入时统一
- **#2 / #18 / #21**：Phase 5 集中处理（DDD 目录 / Isar 4.x web / shake+tier_colors helper）

详见 `PROGRESS.md` §已知偏差。

## 七、关键约束（每次开局必读，与 CLAUDE.md 一致）

- 数值红线：普伤 ≤8000、玩家血 ≤20000、内力 ≤15000、装备攻击 ≤2000（GDD §5.2）
- 三系锁死：境界 ↔ 装备阶 ↔ 心法阶 一一对应，含师承遗物（CLAUDE §5.3）
- 反主流不做：体力/每日任务/抽卡/VIP/分解/快进券 等（CLAUDE §5.1）
- 在线=离线，不做"挂机加速"
- 不硬编码数值（`numbers.yaml`）、不硬编码中文文案（`lib/ui/strings.dart` + `data/narratives|lore|events/`）
- `writeTxn` 用 `IsarSetup.instance.writeTxn(...)` 包装
- 不动 `GDD.md` / `CLAUDE.md` / `numbers.yaml` / `data_schema.md` / `IDS_REGISTRY.md`（DeepSeek 领地或硬约束源）
- Mac 端写 `lib/`、`data/*.yaml`（顶层）、`test/`；DeepSeek 写 `data/narratives/|lore/|events/`

## 八、模型档位建议

Phase 3 跨模块大改 + 多个数据 model 设计 + 跨表关联，**建议升 xhigh** 后再开规划讨论。开新会话时主动提示用户升档。
