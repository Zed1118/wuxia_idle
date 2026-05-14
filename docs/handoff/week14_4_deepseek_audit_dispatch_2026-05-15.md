# W14-4 DeepSeek 派单 · lore/events/insights orphan audit + IDS_REGISTRY 修正(2026-05-15)

> 派单方:Mac Opus
> 执行方:DeepSeek @ Pen Windows Claude Code
> 沟通契约:DeepSeek 自主推进,完工 commit + push + 通知 Mac。

---

## 1. 背景

W14-3 整批闭环(tag `v0.5.0-w14`)后 Mac 端做 DeepSeek 领地 inventory,发现:

| 项 | 现状 | gap |
|---|---|---|
| `data/events/` | 38 yaml | encounters.yaml 引用 **15 个**,**23 个 orphan**(早期写未挂上)|
| `data/lore/` | 46 yaml | equipment.yaml **35 件** → 46>35 有 orphan / 命名不对齐 |
| `data/narratives/techniques/insights/` | 35 yaml | encounter_skills.yaml **35 招** → 数量对上但对应关系未审计 |
| `IDS_REGISTRY.md` | 自报 143 ID | 实际 238(挂账 #4)+ W14-2/W14-3 新 ID 待补 |

本派单做 **audit 型清理 + 文档修正**,**不写新文案**(新作文案留下次派单)。

---

## 2. 工作规范

### 2.1 你的领地(不变)

- `data/narratives/` `data/lore/` `data/events/`
- `IDS_REGISTRY.md`(本派单含修正,自家文档)

### 2.2 不动

- `lib/` `test/`
- `data/*.yaml` 顶层(`encounters.yaml` / `equipment.yaml` / `encounter_skills.yaml` / `numbers.yaml` 等 — Mac 领地)
- `data/masters.yaml` / `data/stages.yaml` / `data/techniques.yaml` / `data/skills.yaml` 等数值层
- `PROGRESS.md` / `GDD.md` / `CLAUDE.md`(Mac 维护)
- Codex 桌面在跑 W14-3 round2 视觉验收,不动 `docs/screenshots/` / `docs/handoff/codex_*.md`

### 2.3 操作类型

- ✅ orphan yaml 归档(挪到 `data/<type>/_archive/`)或重命名匹配 id
- ✅ 缺失文件标记(在 audit report 列出,**本派单不补新文案**)
- ✅ `IDS_REGISTRY.md` 改数 + 补 W14-2/W14-3 新 ID 表
- ❌ 新作文案(opening/body 文字)— 留下次

---

## 3. 任务清单

### 3.1 任务 A · lore 与 equipment 对齐 audit(必做)

**步骤**:
1. 读 `data/equipment.yaml` 拿 35 件装备 id 全集
2. 读 `data/lore/` 46 个 yaml 文件名(去 `.yaml` 后缀)
3. 对齐:
   - **完全匹配**(lore 文件名 = equipment id):保留
   - **lore orphan**(yaml 顶层 id 不在 equipment 35 件中):
     - 若文案质量合格 → 挪到 `data/lore/_archive/` 保留(以后扩装备时可复用)
     - 若已明确是早期废弃命名 → 挪到 `_archive/`,在 audit report 标"待删"
   - **equipment 缺 lore**:标记 audit report,**本派单不补**,留下次

**输出**:
- 文件操作:必要的 `mv` 到 `_archive/`
- audit report 段落:`§4.1 lore audit`

### 3.2 任务 B · events 与 encounters.yaml 对齐 audit(必做)

**步骤**:
1. 读 `data/encounters.yaml` 抽 15 个 encounter id 全集
2. 读 `data/events/` 38 个 yaml 文件名
3. 对齐:
   - **完全匹配**(38 中含 encounters 引用的 15):保留
   - **orphan event**(events yaml 不在 encounters.yaml 引用中):
     - 23 个 orphan 可能是早期 W11-W13 留下未挂上的草稿
     - 挪到 `data/events/_archive/`(保留文案,以后扩 encounters 时复用)
     - 在 audit report 列出 23 个 orphan id + 简要题材摘要(让 Mac 后续选哪些挂回 encounters)

**注意**:**不要删任何 yaml,只做归档**。

**输出**:
- 文件操作:`mv` 23 orphan 到 `_archive/`
- audit report 段落:`§4.2 events audit` + orphan list 23 条

### 3.3 任务 C · insights vs encounter_skills 对齐 audit(必做)

**步骤**:
1. 读 `data/encounter_skills.yaml` 抽 35 招 id(去 `skill_encounter_` 前缀)
2. 读 `data/narratives/techniques/insights/` 35 个 yaml 文件名(去 `.yaml`)
3. 对齐策略:命名约定**对应关系待定**,本次仅 audit 出对比表
   - 35 ↔ 35 数量对上是巧合还是设计?
   - `ting_yu_jian.yaml` 在 insights/ 且 `skill_encounter_ting_yu_jian` 在 encounter_skills.yaml — **去前缀匹配**
   - 用"去前缀匹配"规则,对 35 ↔ 35 算匹配率

**输出**:
- audit report 段落:`§4.3 insights audit`,含匹配率 + 失配 id 列表
- **本派单不补、不挪**,只输出 audit。后续 Mac + DeepSeek 决定命名约定后再统一

### 3.4 任务 D · IDS_REGISTRY.md 修正(必做)

**步骤**:
1. 统计所有 yaml 中 id 总数(Mac 端估算 238 个):
   - 章节 3 + 关卡 15 + 装备 35 + 心法 21 + 招式 63 + 奇遇 15 + encounter_skills 35 + 闭关 5 + 师徒 3 + 节气 N + 物品 N + ...
2. 修"自报 143"→ 实际数(精确到当前 commit)
3. 补 W14-2/W14-3 新增 ID 表:
   - W14-2 新 12 条 encounter id(gu_jian_zhong_yin / cang_jing_ge_wu 等,见 `encounters.yaml`)
   - W14-3-A 35 条 encounter_skill id(`skill_encounter_*` 前缀)
   - W14-2 新增 biome 枚举(15 值)/ weather 枚举(5 值)— 这些虽然在 lib/ 但 ID 系统层可登记
4. 加版本标记(v1.1 W14-3 整批闭环)

**输出**:
- `IDS_REGISTRY.md` 直接修改

---

## 4. audit report 模板

新建 `docs/handoff/deepseek_audit_w14_4_2026-05-15.md`,结构:

```markdown
# DeepSeek W14-4 audit report(2026-05-15)

## 1. 结论
<一句话:任务 A/B/C/D 完成情况>

## 2. 数据快照
- HEAD: <commit hash>
- equipment.yaml: 35 件
- encounters.yaml: 15 条
- encounter_skills.yaml: 35 招
- lore/: 46 → N 主目录 + M archive
- events/: 38 → 15 主目录 + 23 archive
- insights/: 35

## 3. 任务 A 完成情况
- 匹配 lore: X 个
- orphan 归档: Y 个(列出 id + 简要题材)
- equipment 缺 lore: Z 个(列出 id,留下次补)

## 4. 任务 B 完成情况
- 匹配 events: 15 个(encounters.yaml 全引用)
- orphan 归档: 23 个(列出 id + 简要题材摘要 1 行)

## 5. 任务 C 完成情况
- 去前缀匹配率: X/35
- 失配 insights(在 insights 但不在 encounter_skills): id 列
- 失配 encounter_skills(在 encounter_skills 但不在 insights): id 列
- 建议:<DeepSeek 给一句话方向建议:对齐命名还是分两套体系>

## 6. 任务 D 完成情况
- IDS_REGISTRY.md 修正项:
  - 自报数 143 → 改为 N(精确数)
  - 新增 ID 表 W14-2/W14-3 段落

## 7. 文件操作清单
<git diff --stat 的摘要>
```

---

## 5. 完工流程

1. 完成 §3 任务 A-D
2. `git status` 应看到:
   - 部分 lore yaml 挪入 `_archive/`
   - 23 events yaml 挪入 `_archive/`
   - `IDS_REGISTRY.md` 修改
   - 新建 `docs/handoff/deepseek_audit_w14_4_2026-05-15.md`
3. `git add -A && git commit -m "audit(W14-4): lore/events orphan 归档 + IDS_REGISTRY 修正"`
4. `git push origin main`
5. 通知 Mac 端拉取审阅 audit report

---

## 6. 注意

- Codex 桌面在跑 W14-3 round2 视觉验收(`docs/screenshots/w14_3_round2_*.png` + `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md`)。DeepSeek **不动这些文件**,git push 时若 conflict 走 `git pull --rebase --autostash`(Codex 已先 push 也无所谓,文件领地隔离)
- 游戏 wuxia_idle.exe 在 Pen 上跑,但 DeepSeek 静态操作 yaml 不冲突
- 不要尝试"顺便"补 lore/events/insights 新文案 — 那是下一批的事

---

**派单结束。任务 A-D 顺序执行,output 落 audit report + 必要文件操作 + IDS_REGISTRY 修正。**
