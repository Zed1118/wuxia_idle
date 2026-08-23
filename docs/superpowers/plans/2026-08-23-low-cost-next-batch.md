# 2026-08-23 低消下一批执行计划

## 目标

按已拍板方案完成四个原子批次：Phase 0A 普攻真气单一来源、断魂庄槽位稳定
seed、丹房/残页/熟练度证据刷新、资质六档水墨视觉。主 agent 负责设计、
审查、整合与最终验证；子 agent 只承担只读审计和边界清晰的机械工作。

分支：`main`（基线 `833138ba`，每批独立 commit 并在验证通过后 push）。

## 冻结边界

- 不改玩法数值，不调整丹房、残页概率/阈值或熟练度曲线。
- 不新增存档字段，不迁移或重算旧断魂庄会话 seed。
- 不恢复旧 3v3，不新增筛选、排序、属性或资质玩法。
- 不做依赖维护、不 deploy；不突破 GDD/CLAUDE 数值红线。

## 批次与验收

### A · Phase 0A 普攻真气单一来源

- 删除 `phase0a_arena.moves.basic_qi_delta` 的 production 镜像消费。
- 玩家及敌人普攻 intent 均读取快照真实 basic `SkillDef.qiDelta`。
- 缺真实 basic 时 mapper fail-closed，不回退 0。
- targeted mapper/reducer 测试、149 条生产内容画像及全量测试通过。

### B · 断魂庄 slotId 稳定 seed

- 仅新建 run 按不可变 `SaveData.slotId` 稳定派生 seed。
- 同槽稳定、跨槽不同；旧 run（含 seed=0）恢复后原值不变。
- 失败、恢复、奖励选择、补给和门票事务回归通过；不 bump schema。

### C · 经济与熟练度证据刷新

- 基于当前 105 主线关、49 塔层与 Phase 0A 同核补充诊断。
- 输出丹房分段/一次结算一致性、残页集齐分布、熟练度全内容画像。
- 产物只给出证据和风险，不自动提出或落地数值改动。

### D · 资质六档水墨视觉

- 抽共享只读 badge，输入已有 `RarityTier` 与出生点数。
- 六档以档名、边框、印章形态与极淡底纹密度区分，颜色保持低饱和。
- 接入创建、招募、角色档案；不改变档位计算。
- widget/semantics/focus/mouse 回归和 1280×720、1440×900 双视口 smoke 通过。

## 切片顺序与恢复点

1. A 红测 → 单一来源实现 → targeted → 149 画像 → commit/push。
2. B 红测 → seed helper/接线 → 事务回归 → commit/push。
3. C 三份诊断按独立文件完成并生成证据 → commit/push。
4. D 共享组件 → 三页接线 → 自动与双视口验收 → commit/push。
5. 整合态 analyze、全量测试、redline/diff 检查，更新 BACKLOG/NEXT 总账。

当前收口态：A/B 已独立验证并推送；C 三份可复现诊断与 D 三页共享印鉴均已实现，
双视口后台窗口截图和主 agent 复核通过。待整合态全量测试、文档 commit、push 与
远端 CI 验证。

## 残留风险

- A 会改变真实战斗真气循环，必须用全内容画像观察胜负、timeout、技能释放与
  极值伤害，不能只凭单元测试验收。
- B 只保证关卡 RNG seed；奖励装备词条仍沿既有 caller 注入 RNG，不在本批
  擅自改为同一随机流。
- C 的自动画像不等价于真人体验，只作为后续调值决策输入。
- D 的灰度结构测试不能替代最终观感，但本批按用户取消真人六份 Gate 的口径，
  以自动双视口和主 agent 截图复核验收。
