# W15 LoreLoader 接入会话 closeout(2026-05-15)

> 写给下次开局者(Mac Opus 自己)。本会话从 W15 开局会话 closeout(`c979abb`)
> 接力,推进单一子系统:75 段 lore 的加载层 + 配置链路打通。
> 起点 `c979abb` → 终点 `7392f8d`(2 个 commit,已 push origin/main)。

---

## 1. 一句话结论

W15 开局会话暴露的"75 段 lore 0 加载机制"硬缺口本会话**销账**:新建 `LoreLoader`(纯 Dart 按需加载)+ 35 件 equipment.yaml `presetLoreIds: []` 填上自身 id + GameRepository 启动 async fail-fast 校验。**preset 按需读 yaml 不写 Isar,Equipment.lores 留给"延续典故"动态追加**。test 614 → **621**,analyze 0 issues。Codex 暂不可连接,dialog round3 派单(`8138271`)留下波。

---

## 2. 会话密度统计

- **commits**:2 个(均 Mac,已 push)
- **派单**:0(纯单端任务)
- **销账**:1 个(closeout §5.2 列下波候选「LoreLoader 建立 + presetLoreIds 接入」)
- **新增测试**:+7(6 单测 + 35 yaml 真实加载红线)
- **新增文件**:2(`lib/data/lore_loader.dart` / `test/data/lore_loader_test.dart`)

### 全 commits

```
7953acb  feat(W15): LoreLoader + presetLoreIds 接入 fail-fast 校验   Mac
7392f8d  docs(W15): PROGRESS 销账 LoreLoader 接入 + 下波候选更新     Mac
```

---

## 3. 关键决策与产出

### 3.1 范围拍板:B + (a) 按需加载,不写 Isar

开工前给用户 3 档(A 纯加载层 / B 加载层 + 配置链路 / C 实例化路径接入)+ 2 选项((a) 按需 / (b) 写 Isar)。**用户拍板 B + (a)**。

理由:
- **按需 (a)** 与现有 loader 体例(NarrativeLoader / EncounterEventLoader)一致;`Equipment.lores: List<Lore>` Isar 字段留给"延续典故"动态追加,语义隔离干净
- **B(中等)** 链路打通 fail-fast 校验,但不动装备实例化(避免改 drop / craft / 测试一大圈)。**C 留给装备详情页 UI 落地时再做**

### 3.2 reality check 修正了 closeout §5.2 的工作量估算

开局会话 closeout §5.2 推荐"sonnet / 1h",实际:
- `lib/data/models/lore.dart` Isar @embedded class **已存在**(不是从零建)
- `EquipmentDef.presetLoreIds: List<String>` **字段已有 + fromYaml 已读**
- `Equipment.lores: List<Lore>` Isar 嵌入字段**已有**
- 实际工作量 ≈ 40min(读体例 + 写代码 + 测试)

### 3.3 LoreLoader 实现(commit `7953acb`)

```dart
// lib/data/lore_loader.dart
class LoreSegment { final String text; ... }
class LoreContent {
  final String id, name;
  final List<LoreSegment> defaultLore;
  final bool isPlaceholder;
  factory LoreContent.placeholder(String id) => ...;
  factory LoreContent.fromYaml(Map<String, dynamic> y) => ...;
}
class LoreLoader {
  static Future<LoreContent> load(String loreId, {loader}) async {
    try { return LoreContent.fromYaml(...); }
    catch (_) { return LoreContent.placeholder(loreId); }
  }
}
```

体例完全对齐 `EncounterEventLoader`:单一路径 `data/lore/<id>.yaml` + placeholder 兜底 + 注入式 loader。

### 3.4 equipment.yaml 35 件填 presetLoreIds(commit `7953acb`)

35 件全部 `presetLoreIds: []` → `[<装备 id>]`(perl 一行批改 + Python 自洽核验)。装备 id 与 lore yaml 文件名 100% 一致(开工前已 diff 验证)。

```perl
perl -i -pe 'BEGIN{$cur=""}
  if(/^\s*-\s+id:\s*(\S+)/){$cur=$1}
  s/presetLoreIds:\s*\[\]/presetLoreIds: [$cur]/'
data/equipment.yaml
```

### 3.5 GameRepository fail-fast 校验(commit `7953acb`)

`loadAllDefs()` 末尾、`_enforceRedLines()` 之后加 async `_validatePresetLoreReferences(equipmentDefs, load)`:

- 遍历所有 EquipmentDef.presetLoreIds 元素 await LoreLoader.load
- placeholder → StateError(yaml 缺失/损坏)
- content.id != loreId → StateError(yaml 内 id 不自洽)
- defaultLore 空 → StateError(空文件不算 lore)
- **兼容 test fixture**:presetLoreIds 空时整个跳过(不触 yaml)— 35 文件级开销 < 50ms 串行 await 启动期可接受

### 3.6 测试 +7

- 6 单测仿 narrative_loader_test 体例:正常 / 缺省 / 文件不存在 / yaml 损坏 / 顶层非 map / placeholder 字段约定
- 1 红线测试:`data/lore/` 35 真实 yaml 全可解析 + 文件名 == id + name 非空 + default_lore 非空 + 每段 text 非空

---

## 4. 工程教训

### 4.1 开工前 Read 关键文件,不凭印象估工作量

开局会话 closeout §5.2 推荐"sonnet / 1h" — 但 `lib/data/models/lore.dart` / `EquipmentDef.presetLoreIds` / `Equipment.lores` 三个关键工件**全已存在**。**Reality check 改了任务定性**:不是"从零建 lore 加载子系统",而是"补缺失的 loader + 把字段填上 + 加校验"。

**教训**:开工前 `grep -l Lore lib/data/` 或 `find lib -name "*lore*"` 几秒钟就能知道现状,别凭"上一会话 closeout 推荐"直接进推荐工时。

### 4.2 范围 + 设计选项一起给用户拍板,避免反复来回

开工前一次性给:
- 范围 A / B / C 三档(纯加载层 / + 配置链路 / + 实例化路径)
- 设计选项 (a) 按需 / (b) 写 Isar

让用户一次性拍板"B + (a)",节省 2-3 轮反复。**比"开干 → 半路问 → 改方向"高效**。

### 4.3 fail-fast 校验放 async 阶段,sync 红线保持纯净

GameRepository.`_enforceRedLines()` 是 sync,我没硬塞 lore 校验进去(那要把 sync 函数改 async,影响 9 个调用点),而是在 async 的 `loadAllDefs()` 末尾、sync 红线之后另起 `_validatePresetLoreReferences` async 函数。**职责切清:sync 红线纯校验内存数据 / async 校验涉文件 IO**。

### 4.4 perl 一行批改 + py 核验:数据迁移的安全做法

35 件 yaml 改 `presetLoreIds` 不用 35 次 Edit(`[]` 字符串重复 35 次 Edit 唯一性失败),而是:
1. **perl -i -pe** 单行批量替换(扫上下文记 `- id:`,遇 `[]` 替换为 `[$cur]`)
2. **Python re 双重核验**:扫每个 `presetLoreIds` 行,确认其值 == 上方最近的 `- id:`
3. 备份 `/tmp/equipment.yaml.bak` + diff 全量看

零失败、零幻觉。比手工 Edit 35 次稳健。

---

## 5. 下次开局必读

### 5.1 顺序

1. **PROGRESS.md** 「当前阶段」+「下一步」
2. **本文档**(W15 LoreLoader 接入教训)
3. 选读:`week15_open_session_closeout_2026-05-15.md`(W15 上一会话教训 + Codex 派单 §5.5 提示词)
4. **CLAUDE.md** §5 红线 + §12 待人类决策清单

### 5.2 下波候选(按优先级)

| 候选 | 推荐档位 | 工作量 | 涉及端 | 阻塞? |
|---|---|---|---|---|
| **C. dialog round3 Codex 验**(派单已 push `8138271`,Codex 不可连接) | 纯协调 | Mac 0 / Codex 90min | Mac + Codex | Codex 通后即可 |
| **#37 23 orphan events 挂回** | sonnet | 1-2h | Mac + DeepSeek | 先要决策"23 条选哪些复活" |
| **encounter_skills.yaml 剩余 34 招 narrativeInsightId** | DeepSeek 主 | Mac 0 | DeepSeek | 派单未起草 |
| **装备实例化消费 lore + 装备详情页 UI**(W15 LoreLoader 接入后下一步) | opus | 半天-1 天 | Mac | 先定装备详情页设计 |
| **W14-3-A 收尾**(扩 outcome + victory NarrativeReader 提示) | sonnet | 1h | Mac + DeepSeek | 无 |
| **Phase 5 #2 DDD 目录整理** | xhigh + 用户拍板 | 半天起 | Mac | 升档 |
| **#30 闭关 3 维度接 service** | — | — | 阻塞 §12 #7 | — |

### 5.3 环境状态

- **HEAD = `7392f8d`**,工作树 clean,在 main,与 origin/main 同步,无 W15 tag
- **621/621 测试,analyze 0 issues**(W14 610 → W15 三销账 +11)
- **75 段 lore 已通过启动 fail-fast 校验**(75 段 yaml 全可加载 + id 自洽)
- **装备实例化路径未动**:`Equipment.lores` Isar 字段仍空,UI 拿装备**还看不到 preset lore** — 等装备详情页 UI 设计落地
- Pen 端 wuxia_idle / WuxiaRun schtasks 状态未知(W15 本会话未启动 Pen)
- `data/lore/` 主目录 35 yaml × 75 段(W15 #35 产),`_archive/` 45 段未动
- `data/events/` 主目录 15 个(W14 状态),`_archive/` 23 orphan(W14-4 audit)
- `data/encounter_skills.yaml` 35 招 + ting_yu_jian 有 narrativeInsightId 映射

### 5.4 Codex 派单提示词(Codex 通后直接发,与上一 closeout §5.5 同)

```
项目:挂机武侠 (F:\Projects\wuxia_idle)

git pull --rebase --autostash 拉最新代码(应到 HEAD 7392f8d 或更新),
读派单开干:docs/handoff/codex_dispatch_w15_dialog_round3_2026-05-15.md

任务:用 Phase2TestMenu「VC-EVENT · 触发奇遇 debug」按钮 → encounter
debug picker 强制触发,抽样 6 条 W14-2/W14-3-B 新文案(du_kou_chun_yu /
gu_dao_xue_ji / lu_pang_xian_xian / qun_xia_tu / xiao_zhen_wen_yi /
ye_xing_xun_dao),出 12 张主截图(opening + outcome body 各一)。

工作流:
- §4.1 启动前 dart run build_runner build --delete-conflicting-outputs
- §4.2 schtasks Session 1 启 wuxia_idle.exe(GUI 必须 Console session)
- §4.3 窗口 1280×900,截图前 SetWindowPos HWND_TOPMOST 防抢前台
- §5.2 6 对截图存 docs/screenshots/w15_round3/(新建目录),命名 r3-Na/Nb
- §5.3 剩余 6 条可选 quick scan opening(时间允许才补)
- §6 红线对照 WINDOWS_DEEPSEEK_GUIDE.md §6.5

参考踩坑:
- round1: docs/handoff/codex_w14_3c_visual_check_2026-05-14.md
- round2: docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md
- WuxiaRun Running ≠ 桌面可见,枚举 MainWindowHandle 二次确认
- 旧 exe 锁 kernel_blob.bin,build 前 Stop-Process wuxia_idle

完成后写 closeout:docs/handoff/codex_w15_dialog_round3_visual_check_
2026-05-15.md(派单 §8 给了模板),push 即结束。不联系派单方。
```

---

## 6. 不在本会话处理的事项(留挂账)

- **#28 闭关 widget e2e test**(Phase 5 DDD 级,留 Pen 视觉验收兜底)
- **#30 闭关 3 维度接 service**(阻塞 §12 #7 节气清单决策)
- **#31 main_menu「问鼎九霄」widget test**(pumpAndSettle 死循环)
- **#34 stage drop 视觉验收硬截图**(配 ≥1080 屏幕 + 库存页快捷入口)
- **#37 23 orphan events 挂回**(下波候选,先要拍板复活清单)
- **Pen-only T64 test fail**(`.dart_tool/build` cache stale 推测)
- **encounter_skills.yaml 剩余 34 招 narrativeInsightId**(W15 #36 留下波 DeepSeek)
- **装备实例化消费 lore + 装备详情页 UI**(W15 LoreLoader 接入后下一步,需定 UI 设计)

---

**文档结束。下次会话从 PROGRESS.md 当前阶段 + 本文档 §5.2 候选起手,推荐起手:Codex 通则发 dialog round3 + 并行 #37 拍板或 W14-3-A 收尾;Codex 不通则 W14-3-A / #37 / 装备详情页 UI 设计选一开。**
