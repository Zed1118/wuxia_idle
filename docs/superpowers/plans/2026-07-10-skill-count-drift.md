# Skill Count Drift Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 机器复核 `skills.yaml`、`encounter_skills.yaml` 与 GDD 总池口径，并销账过期的 246 drift 记录。

**Architecture:** 不手工猜数量；复用 YAML parser/现有 repository 加载测试得到 206+40=246。GDD 已有正确分项时只补守卫和更新 PROGRESS，不重复改设计内容。

**Tech Stack:** Dart YAML loader、flutter_test、Markdown。

---

### Task 1: 数据计数守卫

**Files:**
- Modify: `test/data/game_repository_test.dart` 或新增 `test/data/skill_count_contract_test.dart`
- Verify: `data/skills.yaml`, `data/encounter_skills.yaml`, `GDD.md`

- [ ] **Step 1: 写测试加载 production repository，断言通用/战斗池 206、奇遇池 40、合并后的 `skillDefs` 246 且 id 无重复。**
- [ ] **Step 2: 运行测试；若实数不是 206/40/246，先以数据实数订正 GDD，不改 YAML 内容凑数。**
- [ ] **Step 3: 确认 GDD 表格和解释段使用相同三项数字。**
- [ ] **Step 4: 从 PROGRESS 删除“GDD 246 vs skills.yaml 实数 drift”遗留，改为已证伪/已守卫。**
- [ ] **Step 5: 提交**：`git commit -m "Guard skill count contract"`。

## 当前恢复点

- 状态：只读核实完成。
- 最后完成：GDD 已明确 206+40=246，原债务是单文件口径误判。
- 下一步：批次 C 后新增机器守卫并销账 PROGRESS。
- 已跑验证：人工读取 GDD 计数段。
- 阻塞项：无。

