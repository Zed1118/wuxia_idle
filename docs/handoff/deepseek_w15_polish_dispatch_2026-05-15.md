# DeepSeek W15 polish 派单 · 二合一(2026-05-15)

> 项目:挂机武侠 (F:\Projects\wuxia_idle)
>
> 派单方:Mac Opus
> 接单方:DeepSeek @ Pen Windows
> 派单 commit:本文档 push 后即派
> 预计工作量:DeepSeek 1.5-2h(主要在任务 1)
>
> **本派单原为三合一(像样货 +5 段 / 35 招 description / 翳字)。任务"像样货补第 2 段"已于 2026-05-15 反审撤回**(详 `week15_full_closeout_2026-05-15.md` §3.6:closeout 自审"实测 70 段"为加和算术错,实际 75 段;像样货 5 件 1 段是 W15 #35 派单 §3.2 明文规定,DeepSeek 按规定交付,**无漏配**)。当前只剩任务 1(35 招 description)+ 任务 2(翳字 polish)。

---

## 0. 派单前必做

```powershell
# Pen 工作目录
Set-Location F:\Projects\wuxia_idle

# 拉最新代码(应到 HEAD 包含本派单文件的 commit 或更新)
git pull --rebase --autostash

# 自检状态
git log --oneline -5
git status -s
```

预期 HEAD 包含本派单 commit。工作树 clean。

---

## 1. 必读清单

| 文件 | 用途 |
|---|---|
| `docs/handoff/week15_full_closeout_2026-05-15.md` | W15 整批闭环 closeout(本派单的上游背景)。重点读 §3.3 + §3.6 + §4.4 |
| `data/encounter_skills.yaml` | 任务 1 主体,35 招 yaml 全文 |
| `data/skills.yaml` | 任务 1 体例参考(21 心法 × 3 招 = 63 招的 description 写法) |
| `data/narratives/techniques/insights/*.yaml` | 任务 1 主题统一参考(22 招已映射 narrativeInsightId,引用对应 insight 主题) |
| `data/events/xiao_zhen_wen_yi.yaml` | 任务 2 主体 |
| `WINDOWS_DEEPSEEK_GUIDE.md` §6 | 文案规范总则(基调 / 词汇 / 红线) |
| `CLAUDE.md` §5.6 | 不写数值红线(描述里不能出现具体数值) |

---

## 2. 任务清单

### 任务 1 · encounter_skills.yaml 35 招 description 补文案

**目标**:35 招 `description: TODO_NARRATIVE` 全部补成 1-2 句武学描述。

**约束**:
- **只改 description 字段**,不动 id / name / type / powerMultiplier / internalForceCost / cooldownTurns / requiresManualTrigger / visualEffect / tier / **narrativeInsightId**(已有的 22 招映射保留)
- 体例对齐 `data/skills.yaml` 现有招式 description(简洁、武学气质、不写数值)
- 已有 narrativeInsightId 映射的 22 招参考对应 `data/narratives/techniques/insights/<id>.yaml` 的 narrative 主题,**保持主题统一**(听雨剑这一招的 description 与 ting_yu_jian insight 的意境共鸣)
- 留空 narrativeInsightId 的 13 招(基础步法/呼吸/暗器/拳法/火电类)按招式 name + tier + visualEffect 自由发挥武学描述,**不强行套主题**
- 描述里**不写具体数值**(GDD §5.6 红线:不写"伤害 1500""速度 +20"等)
- 描述里不写网游词汇(legendary / epic / 史诗 / 传说级 等)
- 描述里不写 UI 名词(slot / cooldown / 内力消耗 等)
- ultimate=true(requiresManualTrigger 字段)的招式可加"大招气质"

**体例参考**(skills.yaml 现有):
```yaml
- id: skill_skybreak_slash
  description: 一剑劈下,带着山岳之势,刀光似要劈开天幕。
```

```yaml
- id: skill_listen_rain
  description: 静坐听雨,剑随雨势,雨密则剑密,雨稀则剑稀。
```

**ultimate 体例参考**:
```yaml
- id: skill_ultimate_xxx
  description: 凝十年功力于一击,剑出无悔,招式终了再无气力。
```

### 任务 2 · "翳"字 polish(可选)

**目标**:`data/events/xiao_zhen_wen_yi.yaml` 的 title「小镇问翳」中"翳"字过于生僻(Codex round3 OCR 误读为"翁")。

**约束**:
- **可选**:改成更常见字(保留音/意/文学气),或保留不动(文学性强,音义独特)
- 你判断,改不改都行
- 如改:同步检查 yaml 里其它字段是否引用了"翳"字,保持一致性
- **不要因为改这一个字就大改文案**

**纠错记录**:Codex round3 OCR 误读不是 bug,但记录在派单备选清单作 polish 候选。

---

## 3. 边界(硬约束)

不动的文件 / 字段(任何任务都不许动):
- `lib/` 任何 Dart 代码
- `data/*.yaml` 数值字段(only description / title)
- `GDD.md` / `CLAUDE.md` / `WINDOWS_DEEPSEEK_GUIDE.md` / `numbers.yaml` / `IDS_REGISTRY.md` / `data_schema.md`
- `data/narratives/` / `data/lore/`(不在本派单范围)
- `data/events/` 除 `xiao_zhen_wen_yi.yaml`(任务 2)
- `data/encounter_skills.yaml` 除 description 字段(任务 1)
- 任何 test / docs 除你的 closeout

---

## 4. 校验

任务 1:
```powershell
# yaml 解析(如装 python)
python -c "import yaml; yaml.safe_load(open('data/encounter_skills.yaml', encoding='utf-8'))"

# 35 招 description 全填(应返回 0)
Select-String -Path data/encounter_skills.yaml -Pattern 'description: TODO_NARRATIVE' | Measure-Object | Select Count
```

任务 2(如改):
```powershell
python -c "import yaml; yaml.safe_load(open('data/events/xiao_zhen_wen_yi.yaml', encoding='utf-8'))"
```

派单方 Mac 端在 closeout 后会跑 `flutter test` + `flutter analyze` 终验,DeepSeek 不需要跑 Flutter 测试。

---

## 5. 完成动作

1. **commit 体例**:可一个 commit 或两个 commit(任务 1 + 任务 2 分开),由你判断
   - 一个 commit:`feat(W15 polish): encounter_skills 35 招 description + xiao_zhen_wen_yi 翳字 polish`
   - 两个 commit:`feat(W15 polish): encounter_skills 35 招 description 补文案` + `polish(W15): xiao_zhen_wen_yi 标题翳字调整`(或不改第二个就不 commit)
2. **closeout 文件**:`docs/handoff/deepseek_w15_polish_closeout_2026-05-15.md`,内容包括:
   - 任务 1 实际填了多少招(应该 35)
   - 22 招映射 narrativeInsightId 的描述是否参考了 insights 主题(你的判断)
   - 任务 2 是否改了"翳"字 + 改成什么 / 没改的理由
   - 踩坑记录(yaml 解析 / 体例困惑等)
3. **push 即结束**,不联系派单方。派单方下次会话开局会自取 closeout 合并 PROGRESS。

---

## 6. 提示

- **22 招映射 narrativeInsightId 是有意义的纪律**(W15 #36 销账锚点),写 description 时尊重映射,主题统一会让玩家通过 insights + description 双线感受到武学的内涵
- **13 招留空 narrativeInsightId 也是有意义的**(基础步法/呼吸/暗器/拳法/火电类 insights 无对应主题),不要硬塞主题,按招式 name 自由发挥即可
- 体例参考 skills.yaml 但**不必照搬**,encounter_skills 是奇遇专属池,可以比 skills.yaml 多一点"奇遇感"(残卷 / 偶然得 / 江湖传)

---

**派单结束。预计 1.5-2h。push 完毕即派单关闭。**
