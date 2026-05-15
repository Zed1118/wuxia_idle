# W15 反审 + C-2 收尾 closeout(2026-05-15)

> 写给下次开局者(Mac Opus 自己)。本会话从 W15 整批闭环 `8c33922`(tag
> `v0.5.2-w15`)接力,B → A → C 三件套 + 反审撞二重错。
>
> 起点 `8c33922` → 终点 `e79ce47`(2 commits,已 push)。

---

## 1. 一句话结论

W15 整批闭环后开局即查,Mac 端复审 35 件 yaml 段数**撞二重错纠正 #38**(closeout §3.6 加和算术错 70→75,像样货 1 段是派单 §3.2 规定非 DeepSeek 漏配,Codex 装备详情屏 04 WARN 是 spec 误抄),挂账 #38 撤回。同时完成 memory 3 条沉淀 + DeepSeek polish 二合一派单(已 push)+ C-2 子项(banner skill name 升级)。**631/631 测试,analyze 0 issues**。C-1(扩 outcome 引用 tier 1-2/7 池)留下波蹔 DeepSeek polish closeout 后派新 encounter 套餐。

---

## 2. 会话密度统计

- **commits**:2(`59ec359` 反审 + 派单 / `e79ce47` C-2 banner)
- **新增 push**:2(均 Mac)
- **派单**:1(DeepSeek polish 二合一)
- **测试**:净 +4(627 → 631)
- **memory 沉淀**:3 条(MEMORY.md 现 42 项)
  - `reference_pen_wuxia_flutter_run` 加 schtasks Access denied → Start-Process fallback
  - 新建 `feedback_red_line_test_semantics`(红线测试要写约束语义)
  - 新建 `feedback_closeout_numbers_grep`(closeout 数字必 grep 实测,含撞二重错 meta 教训)
- **新增文件**:2
  - `lib/ui/encounter/encounter_outcome_banner_test.dart`(test/ui/encounter/ 新目录)
  - `docs/handoff/deepseek_w15_polish_dispatch_2026-05-15.md`
- **修改文件**:5
  - `PROGRESS.md`(反审 + C-2 + 下一步段更新,98 行内)
  - `docs/handoff/week15_full_closeout_2026-05-15.md`(§1/§3.4/§3.6/§4.4/§5.2/§5.5/§6 反审纠错)
  - `lib/ui/encounter/encounter_dialog.dart`(banner skill name lookup)
  - `~/.claude/projects/-Users-a10506/memory/MEMORY.md` + 3 memory 文件

### 关键 commits

```
e79ce47  feat(W15 C-2): 奇遇 outcome banner 显 SkillDef.name 替换 raw skillId  Mac
59ec359  docs(W15): #38 反审撤回 + closeout 数字纠错 + DeepSeek polish 派单(二合一)  Mac
```

---

## 3. 关键决策与产出

### 3.1 memory 3 条沉淀(B 任务)

W15 整批 closeout §4 工程教训沉淀到全局 memory:
- **schtasks Access denied fallback**:RDP 已登录时用 Start-Process 直启 Debug exe,不走 schtasks。两路径选择策略写清
- **红线测试要写约束语义**(W15 #36 教训):写"白名单/集合自洽/范围"不写"具体数字/计数/列表",前者抗内容演进
- **closeout 数字必 grep 实测**(W15 #35 → 撞二重错 meta 教训):写完此 memory 立刻 grep 复审,直接撞出 §3.6 加和算术错 + 派单 §3.2 误读,memory 教训的活实例

### 3.2 反审撞二重错(#38 撤回)

写完 `feedback_closeout_numbers_grep.md` memory 立刻 grep 验证 — 本应 5min 走流程,撞出二重错:

| 错锚 | 实测 | 错误原因 |
|---|---|---|
| closeout §3.6 自审"实测 70 段" | 实测 **75 段** | 5+5+10+10+15+15+15 加和算术错(罗列对、加和错) |
| 像样货 5 件 1 段"是 DeepSeek 漏配" | 派单 §3.2 明文"各 1 段" | 自审时没回查派单源头 |
| Codex 装备详情屏 04 WARN | 实际 PASS,详情屏整体 **7/7** | 装备详情屏派单 spec 误抄了错误 PROGRESS"预期 2 段" |

**#38 撤回**:挂账基于双重错前提。DeepSeek polish 派单从三合一(像样货 +5 段 / 35 招 description / 翳字)减为二合一(只 35 招 description + 翳字)。

**反审教训** ⇒ `feedback_closeout_numbers_grep.md` + W15 closeout §4.4 重写"派单 spec 的预期也要 grep 验证,视觉验收 WARN 三层归因(spec 预期 / 文案数据 / UI 渲染)按优先级追"。

### 3.3 DeepSeek polish 二合一派单(A 任务)

文档 `docs/handoff/deepseek_w15_polish_dispatch_2026-05-15.md` 已推 origin。任务清单:
- **任务 1**:`data/encounter_skills.yaml` 35 招 description 全 TODO_NARRATIVE → 1-2 句武学描述(体例对齐 skills.yaml,22 招映射 narrativeInsightId 参考 `data/narratives/techniques/insights/<id>.yaml` 主题统一)
- **任务 2**:`data/events/xiao_zhen_wen_yi.yaml` 「翳」字 polish(可选,非强制)

派单提示词(待用户发 Pen):
```
项目:挂机武侠 (F:\Projects\wuxia_idle)
git pull --rebase --autostash 拉最新代码,
读 docs/handoff/deepseek_w15_polish_dispatch_2026-05-15.md
完成任务 1(encounter_skills 35 招 description)+ 任务 2(翳字 polish 可选)。
预计 1.5-2h。closeout 后 push 即结束,不联系派单方。
```

### 3.4 C-2 banner skill name 升级(C 任务)

W14-3-A 收尾 C-2 子项。`encounter_dialog.dart:315` `showEncounterOutcomeBanner` UnlockSkillApplied 摘要从 raw skillId(`skill_encounter_ting_yu_jian`)升级为 SkillDef.name 中文招名(「听雨剑」)。

实现:
- 新增 `_resolveSkillName(skillId)`:`GameRepository.isLoaded` 兜底 + `skillDefs[id]?.name ?? skillId` nullable lookup,test fixture 不全 / id 未注册降级回 raw id(无 throw)
- 不动 caller(`encounter_hook.dart` / `encounter_debug_picker.dart` 调用签名兼容)
- 不动其它 OutcomeApplied case(AttributeBonus / AttributeCapReached / NoneOutcome 保持原文案)

test:`test/ui/encounter/encounter_outcome_banner_test.dart`(新目录)4 case:
- 已注册 skill_encounter_ting_yu_jian → "领悟新招:听雨剑"
- 未注册 skill_encounter_does_not_exist → "领悟新招:skill_encounter_does_not_exist"(降级)
- AttributeBonusApplied(enlightenment, 1) → "悟性 +1"
- NoneOutcome → "心中默念,继续前行"

**631/631**(627 → +4),analyze 0 issues。

### 3.5 C-1 留下波理由

C-1(扩 outcome 引用 tier 1-2/7 池补 7 阶覆盖度)实际边界:
- 当前 21 encounter,9 unlockSkill 引用集中 tier 3-6
- **tier 1-2 池 10 招全 0 引用**(早期段奇遇未覆盖)
- **tier 7 池 4/5 未引用**

可行路径(用户拍板选 1):
1. ~~改现有 outcomeMapping 加 unlockSkill 次要 effect~~(改 schema,跨多文件)
2. ~~Mac 端预占 new encounters.yaml 数据 + 留 TODO_NARRATIVE~~(events red line 拦)
3. **等 DeepSeek polish closeout 后,Mac 数值 + DeepSeek 文案打包派新 encounter 套餐**(选)

下波派单提示词候选(可在 DeepSeek polish closeout 后基于 35 招 description 内容主题挑选 tier 1-2/7 池招式重写):见 §5.3 下波候选第 2 项。

---

## 4. 工程教训

### 4.1 写完 memory 立刻撞活实例(反审有效性)

写 `feedback_closeout_numbers_grep.md` 时只是把 W15 #35 自报 75 → 自审 70 当作教训历史。grep 复审本应只是流程性验证。**结果直接撞出双重错** — 自审 70 反过来是错的,原 75 才是对。

**meta 教训**:memory 教训不只是历史记录,**写完立刻应用**会暴露未察觉的当前错锚。这个 pattern 跨项目通用 — 任何新写的 feedback memory 都值得"立刻试用一次"。

### 4.2 closeout §3.6 加和算术错

`5+5+10+10+15+15+15` 凭印象写成 70,实际 75。**罗列对、加和错**比"凭印象口算总数"更隐蔽 — 看似已经分项验证了。**对策**:`awk -F: '{sum+=$2} END {print sum}'` 一行实测加和,不要手算。已写入 `feedback_closeout_numbers_grep.md`。

### 4.3 派单 spec 误抄 PROGRESS(错锚传播)

装备详情屏派单 spec 写 "04 像样货钢刀预期 2 段" 时,Mac 端**抄了 PROGRESS / closeout §3.6 错误的"像样货应 2 段"**,没回查 W15 #35 派单源头 §3.2 明文"各 1 段"。Codex 按 spec 比对截图标 WARN,但 spec 预期本身就错。

**教训**:派单 spec 的"预期值"必须 grep 源头(派单原文 / yaml 实测),不能信任中间层 PROGRESS / closeout 的自审数字。已写入 W15 closeout §4.4 + `feedback_closeout_numbers_grep.md`。

### 4.4 二重错的链路传播

错锚一旦进 PROGRESS 会快速向下游传播:
```
W15 #35 自审 §3.6 "实测 70 段" + "像样货应 2 段"
  ↓
PROGRESS Line 13 已完成段(下次开局必读)
  ↓
装备详情屏派单 spec §4.2 "04 预期 2 段"
  ↓
Codex 视觉验收 closeout 04 WARN
  ↓
W15 整批 closeout §3.4 "WARN 是 DeepSeek 漏配"
  ↓
W15 整批 closeout §5.2/§5.5 派单候选 #38 "像样货补 5 段"
  ↓
A 派单提示词草案三合一(像样货 + 描述 + 翳字)
```

整条链没被打断,直到本会话开局即查才反审撞墙。**幸运的是:DeepSeek 还没接 polish 派单**,否则 1.5-2h DeepSeek 工作量直接浪费。

---

## 5. 下次开局必读

### 5.1 顺序

1. **PROGRESS.md** 「当前阶段」+「下一步」+「已知偏差」(行 1-65)
2. **本文档**(W15 反审 + C-2 closeout)
3. **W15 整批 closeout 修正版** `week15_full_closeout_2026-05-15.md` §3.6 + §4.4(2026-05-15 反审纠错段)
4. **CLAUDE.md** §5 红线 + §12 待人类决策清单
5. `git pull --rebase --autostash` 看 DeepSeek polish closeout 是否已 push

### 5.2 状态快照

- **HEAD = `e79ce47`**,工作树 clean,在 main,与 origin/main 同步
- **tag `v0.5.2-w15` 已 push**(本会话**不新增 tag**,因为只 polish 不达 minor 标记)
- **631/631 测试**,analyze 0 issues
- `data/lore/`:35 yaml × **75 段**(确认实测,不再是 70)
- `data/encounter_skills.yaml`:35 招(22 narrativeInsightId 映射 + 13 留空,**description 仍全 TODO_NARRATIVE** — 等 DeepSeek polish)
- `data/encounters.yaml`:21 条 encounter,9 unlockSkill 引用集中 tier 3-6(tier 1-2 / 7 池未覆盖,见 C-1 候选)
- DeepSeek polish 派单已 push 在 `docs/handoff/deepseek_w15_polish_dispatch_2026-05-15.md`,**user 是否已发 Pen 不确定**(下次开局先 git pull 看 DeepSeek 是否已 closeout)
- 3 端协作:Mac Opus / Pen Codex(空闲)/ Pen Windows DeepSeek(可能在跑 polish)

### 5.3 下波候选(按优先级)

| 候选 | 推荐档位 | 工作量 | 阻塞? |
|---|---|---|---|
| **A. DeepSeek polish closeout 合并 PROGRESS**(若已 push) | sonnet | 15-30min | 看 DeepSeek 是否已 push |
| **B. C-1 收尾 扩 outcome 引用 tier 1-2/7 池新 encounter 套餐** | opus + DeepSeek 派 | Mac 1-2h + DeepSeek 1-2h | 等 DeepSeek polish 后 |
| **C. Pen 端视觉验收装备详情屏 真机** | Codex 派单 | Codex 1h | 需 Pen flutter run + 库存页路径 |
| **D. #37 剩 17 orphan events 第 2 批挂回** | opus | 1-2h | 先评估 17 主题(悬崖/青楼/荒原/古船/古井) |
| **E. Phase 5 #2 DDD 目录整理 + 屏 Consumer 化收尾** | xhigh + 用户拍板 | 半天起 | 升档 |
| **F. #30 闭关 3 维度接 service** | — | — | 阻塞 §12 #7 节气清单决策 |
| **G. #34 stage drop 视觉验收 Pen 环境改善** | Codex 派单 | Codex 1h | 配 ≥1080 屏 + 库存页入口 |
| **H. Pen-only T64 test fail 排查** | sonnet | 30min | Mac 不重现 |

**推荐起手顺序**(下次开局):
1. `git pull` 看 DeepSeek polish 是否已 closeout
2. 已 closeout → **A**(合并 description 进 PROGRESS,run test 验)→ 然后 **B 派单**(基于 description 主题挑 tier 1-2/7 池招式重写 encounter outcome)
3. 未 closeout → **D 起手**(opus 1-2h Mac 独作),或 **C 派单 Codex 视觉验收**

### 5.4 模型建议

- A(合并 description):sonnet
- B(C-1 数值层):opus
- D(#37 第 2 批挂回):opus(评估主题 + 写 trigger + 红线测试)
- C / G(Codex 派单):Mac Opus 写 spec sonnet 即可

---

## 6. 不在本会话处理的事项(留挂账)

- **C-1 收尾 扩 outcome 引用 tier 1-2/7 池**(等 DeepSeek polish closeout 后新 encounter 套餐)
- **#28 闭关 widget e2e test**(Phase 5 DDD 级)
- **#30 闭关 3 维度接 service**(阻塞 §12 #7 节气清单决策)
- **#31 main_menu「问鼎九霄」widget test**(pumpAndSettle 死循环)
- **#34 stage drop 视觉验收硬截图**(配 ≥1080 屏幕 + 库存页快捷入口)
- **#37 剩 17 orphan events 第 2 批挂回**
- **Pen-only T64 test fail**(`.dart_tool/build` cache stale 推测)
- **3 段 lore Pen 真机验收**(重器/宝物/神物,等 stage drop / craft 路径打通)

---

**文档结束。下次会话 /clear 后从 §5 开局起手。HEAD `e79ce47` 已 push,A 派单提示词待用户拷贝发 Pen。**
