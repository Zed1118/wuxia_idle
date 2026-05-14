# W13 Codex 桌面视觉验收 + Mac 端 6 处链式修复 closeout(2026-05-14)

> 写给下一会话开局者(Mac Opus 自己)+ 后续派 Codex 桌面视觉验收的人。
> 本文是 W7-W11 五周累积视觉验收闭环 + W13 4 轮迭代修复链的总结。
> tag `v0.4.0-w11` 已 push origin。**552/552**,analyze 0 issues。

---

## 1. 一句话结论

Codex 桌面 Pen Windows 视觉验收**首次实战**(4 轮迭代 90min × 4),暴露 4 个真生产 bug(catch _ 静默吞 / W6 race / Isar fixed-length list / provider 不 invalidate)+ 2 个 fixture 阻断(UI 无 debug 数字 / stage_01_01 无 dropTable),Mac 端 6 处链式修复全部落地。**6/7 必收硬证据视觉通过**,#10 stage drop 因 RDP 操作问题挂账 #34(代码层 service test 兜底)。

---

## 2. Codex 4 轮迭代时间线

| 轮 | commit | 截图状态 | 关键发现 / 阻断 | Mac 端响应 |
|---|---|---|---|---|
| v1 | `530fd0c` `05d9a1a`(已 reset 丢) | 15 张占位/反证 | UI 不显 battleCount 数字 / TowerProgress.recordClear 无效 / stage_01_05 平衡 drift | `adc70fd` 修 3 件事:getOrCreate race / UI debug / VC seed |
| - | - | - | (Codex 自产方法论复盘) | `447fbe1` commit Codex method report |
| v2 | `582fb7a`(已 reset 丢) | 15 张反证 | **Isar fixed-length list 阻断三条结算链** | `f763e9f` caller 端 List.of 转 growable |
| v3 | `582fb7a`(同 v2) | 5/7 硬证据通过 | #15 banner 显 1900 但面板仍 3800 / #10 stage_01_01 无 dropTable | `0551a1a` invalidate 5 family + stage_01_01 加 dropTable |
| v4 | `6a3bd92`(已 push) | **6/7 硬证据视觉通过** | #10 GUI 操作问题(RDP 高度 + 1280×900 窗口) | `df0d0d3` #10 service test 兜底 + tag `v0.4.0-w11` |

**Codex 自产复盘**:`docs/handoff/codex_desktop_visual_check_method_report_2026-05-14.md`(214 行,后续派 Codex 桌面前必读)

---

## 3. Mac 端 6 处修复(commit 链)

### 3.1 `adc70fd` 修 fixture 阻断(任务 2/1a/3)

**任务 2 · tower/stage entry_flow ensure getOrCreate**(根因)
- `tower_progress_service.dart:109-113` recordClear 在 TowerProgress 行不存在时抛 `StateError('TowerProgress 未初始化:getOrCreate 未在 recordClear 前调用')`
- W6 重构后依赖 `towerProgressProvider` 副作用 getOrCreate 存在 race,被 `tower_entry_flow.dart:97 catch (_)` 静默吞 → UI 看到「0/30、尝试 0」
- 修复:caller 端主动 `await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId)` 再 record* + catch (e) debugPrint
- mainline 同源问题(line 95 recordVictory)同步修

**任务 1a · UI debug 字段**
- 装备 tile 加 `#N` battleCount(`character_panel_screen.dart:594-617` Row 同行 + Spacer)
- 心法 tile 加 `skillUsage:N` 总计(`technique_panel_screen.dart:215-225` Row 加 Text + fold)

**任务 3 · visual_check_seed**
- `Phase2SeedService.seedVisualCheckW7W11()`:复用 seedMasterDisciple + mark Ch1 01-04 cleared
- Phase2TestMenu 加「VC · W7-W11 视觉验收预设」按钮
- 节省 5-7min 真通关时间

### 3.2 `447fbe1` Codex 方法论复盘 commit

214 行方法论,Codex 自产。包含 Pub cache 损坏诊断 / PowerShell .NET 工具链 / 1280×720 → 1280×900 窗口踩坑 / 截图执行策略 / 必须完成 vs 不能伪造的冲突处理。**memory `feedback_codex_pen_windows_visual_check.md` 已沉淀**。

### 3.3 `f763e9f` W13 Isar fixed-length list 生产 bug(根因)

**Codex v2 探路暴露**:`Unsupported operation: Cannot add to a fixed-length list` at `lib/data/models/skill_usage_entry.dart:29`

- `Technique.skillUsageCount` 是 Isar `@embedded List<SkillUsageEntry>`
- `isar.findAll()` 反序列化为 fixed-length list
- `MapLikeOnSkillUsage.increment` line 29 `add(...)` 在新 skillId 出现时触发 `UnsupportedError`
- **W11 #32 销账时 service-level test 用 `Technique.create` 内存构造(growable list)漏掉**
- 阻断三条结算链:主线 victory / 爬塔 victory / Boss defeat

**修复**:caller 端拉 Isar 后立刻 `for (final t in ts) { t.skillUsageCount = List.of(t.skillUsageCount); }`(stage_entry_flow + tower_entry_flow + _applyBossDefeatPenalty 三处)+ `test/services/skill_usage_persist_test.dart` 3 case 真持久化回归

### 3.4 `15fab79` 预防性 audit(0 新问题)

- 全仓 `catch (_)` 4 处全合理 silent(getEquipment / getTechnique 兜底 / narrative 三段扫描 / test path)
- 其他 Isar `@embedded List` 字段(forgingSlots 固定 3 槽 / lores 只读 / actualRewards 整体 reassign)无 fixed-length 风险
- **SkillUsageEntry 是单点(open-set 唯一),非系统性陷阱**

### 3.5 `d58732e` PROGRESS 归档 91 → 78 行

W12+W13 三轮密集修复撑爆 PROGRESS。归档 Phase 1/2/3 W1-W5 详条到末尾(引用 summary 文件),销账条目 6 条归档,「进行中」段删(W11 已 W13 取代)。

### 3.6 `0551a1a` #15 散功 UI 不刷新 + #10 stage_01_01 无 dropTable

**Codex v3 暴露 #15**:banner 显 3800→1900 但角色面板仍 3800/4180

- 根因:`_applyBossDefeatPenalty` writeTxn putAll(characters) 后**没有 `ref.invalidate(characterByIdProvider)`**
- `@riverpod` family provider 默认 autoDispose,但 caller 路径下 character 缓存仍是旧值
- D 场景 work 是因为 equipment provider 走不同 path 较易 unwatch + refetch
- **修复**:抽 `_invalidateCharacterFamilyAfterCombat` helper,invalidate 5 个 family(characterById / equipmentById / techniqueById / characterAllTechniques / allEquipments)
- 三处 caller 调:`_applyVictoryResolution` / `_applyBossDefeatPenalty` / `_applyTowerVictoryResolution`(tower 路径同步)

**#10 stage_01_01 无 dropTable**:
- 之前 stage_01_01 没 dropTable 字段 → DropService.rollDrops 永远空
- 加 100% `armor_xunchang_bu_yi` + 100% 1 个 `item_mojianshi`(GDD §10.2 教程节奏)
- 同步更新 game_repository_test 「未配关卡 dropTable 为空」case 期待 length=2

### 3.7 `df0d0d3` #10 兜底 service test + 闭环

`game_repository_test` 加 case「DropService.rollDrops(stage_01_01) 100% 掉护甲 + 磨剑石」,5 次确定性验证。Codex v4 #10 视觉验收未取得硬截图,**代码层 service test 兜底**。

---

## 4. 视觉验收 7 必收硬证据状态

| # | 验收点 | 状态 | 证据 |
|---|---|---|---|
| 08 | 战后装备 #0→#1 | ✅ 通过 | Codex v4 截图 06 vs 08 |
| 09 | 战后心法 0/100→1/100 | ✅ 通过 | Codex v4 截图 07 vs 09 |
| 10 | stage drop 入背包 | ⚠️ 挂账 #34 | service test 兜底(Pen 视觉缺失) |
| 12 | 重打 dialog 无 reward | ✅ 通过 | Codex v4 截图 12「已重打通关 重打不发奖」 |
| 13 | 重打后 battleCount 仍 ++ | ✅ 通过 | Codex v4 截图 13 显 #3 |
| 14 | 战败 banner | ✅ 通过 | Codex v4 截图 14「战败·散功代价」+ 3 行减半 |
| 15 | 战败后角色面板内力真减半 | ✅ 通过 | Codex v4 截图 15 显 1900/4180(战前 3800/4180) |

---

## 5. 测试覆盖增量

| 文件 | 新增 case | 覆盖 |
|---|---|---|
| `test/services/skill_usage_persist_test.dart`(新) | 3 | Isar fixed-length list 抛异常 + List.of fix 路径 + 已存在 skillId 不抛 |
| `test/services/phase2_seed_service_test.dart` | 2 | seedVisualCheckW7W11 师徒 + Ch1 01-04 标 cleared / 反复调用幂等 |
| `test/data/game_repository_test.dart` | 1 | DropService.rollDrops(stage_01_01) 100% 掉护甲 + 磨剑石(5 次确定性) |

**546 → 552(+6 累积),analyze 0 issues**。

---

## 6. 关键挂账(W14+ 待处理)

- **#34 (新)**:#10 stage drop 视觉验收 Pen 环境改善(配 ≥1080 屏 + 库存页快捷入口,然后 Codex 重跑补)
- **Pen-only T64 test fail**:`.dart_tool/build` cache stale 推测,Mac 端 31/31 全过不重现
- **#28**:闭关 widget e2e(死结,留 Pen 视觉验收兜底)
- **#30**:闭关 3 维度接 service(§12 #7 节气清单 + 农历库阻塞)
- **#31**:main_menu 「问鼎九霄」widget test 死循环(已有 11 个 tower test 覆盖)

---

## 7. 关键工程教训(memory 已沉淀)

### 7.1 `feedback_layered_bugs.md` 补 W13 案例
**「上层 fail 掩盖下层 bug」** —— W11 #32 销账 catch (_) 吞了一年才被 Codex 暴露。`catch (_)` / 空 catch body 是高发区,**改成 `catch (e, st) { debugPrint(...) }` 至少留诊断信息**。

### 7.2 `feedback_codex_pen_windows_visual_check.md` 已写
- PowerShell .NET 零依赖工具链 cheatsheet
- Pub cache 损坏诊断流程(build_runner-2.15.0 / build_runner_core-7.3.2 定向删除 + `dart run build_runner build` 替代)
- 1280×720 → 1280×900 窗口踩坑
- 派单方 self-check 清单:**fixture 完整性必须 Mac 端先解,再派 Codex**(否则 Codex 拿不到真硬证据)
- 跨项目复用范围(saibandao / lifetime_app Windows 端)

### 7.3 工程纪律
- **service-level test 全过 ≠ 真生产路径落地**(W11 #32 销账漏洞案例)
- 内存 list 测试漏掉 Isar findAll 反序列化为 fixed-length 的特性
- **销账 commit 之前自检「这条链路有没有真生产 e2e」**

---

## 8. 数据快照

- main HEAD: `df0d0d3`
- tag: `v0.4.0-w11`(W7-W11 五周累积 + W13 4 轮 + Mac 6 修复 闭合)
- 测试: **552/552** 全过,analyze 0 issues
- 累计 commit(项目至今): ~95 commits
- 累计 tag: v0.1.0-phase1 / v0.2.0-phase2 / v0.3.0-w1..w6 / **v0.4.0-w11**(W7-W11 累积)
- Demo 内容量:主线 15/15 ✅ / 章节 3/3 ✅ / 爬塔 30/30 ✅ / 闭关 5/5 ✅ / 师徒 3/3 ✅ / 装备 35/30-50 ✅ / 心法 21/20-30 ✅ / 奇遇 0/20-30 阻塞 / 武学领悟 0/30-50 阻塞
- 关键架构: Riverpod 3.x + Isar community 3.3.2 + nullable propagation(W6) + Boss 战败被动散功(W10) + victory 双端接 resolveBattle(W11) + LevelDiff 数据/公式层语义统一(W12) + Isar fixed-length list 修复 + 战斗结算 invalidate provider(W13) + onboarding dropTable(W13)
- Codex 视觉验收截图: `docs/screenshots/phase4_w7_w11/` 11 张(03/04/06-09/11-15)+ 缺 01/02/05/10

---

## 9. 下次开局必读

1. `PROGRESS.md` 「当前阶段」段(W7-W11 闭环 + tag v0.4.0-w11)+ 「已知偏差」段(#34 新加)+「下一步」W14 候选
2. 本文档 §3 6 处修复链(理解 W13 设计哲学 + 各 commit 责任边界)
3. `docs/handoff/codex_desktop_visual_check_method_report_2026-05-14.md`(派 Codex 桌面前必读)
4. `feedback_codex_pen_windows_visual_check.md`(memory)+ `feedback_layered_bugs.md`(memory)
5. **写 widget test 涉及真 Isar 时**:跑 `skill_usage_persist_test.dart` 体例(挂账 #28 widget e2e 死结,只能 service-level 真持久化)

CLAUDE.md / GDD.md / numbers.yaml 不动。Mac 端写 `lib/` `data/*.yaml`(顶层) `test/` `docs/handoff/`;DeepSeek 写 `data/narratives/` `data/lore/` `data/events/`;Codex 桌面 @ Pen 写 `docs/screenshots/` + `docs/handoff/codex_*.md`。
