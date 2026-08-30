# M4 战斗音效按帧聚合计划

## 结果合同

- 单一目标：把 Phase 0A 战斗屏从“每条事件逐次播音”改为同拍音效计划，命中按出手方分组且每组只播一个最高语义音效，Boss 蓄力警告优先进入计划。
- 基线：`7a617fc31421ac8c70deaa1942307c1013a11968`，承接 M4 生存目标 clean Gate 候选。
- 不扩张项：不增音频资产、不改音量/数值、schema/存档、文案、敌人/技能、低特效设置或全局 `SoundManager`；不启动 M3，不 merge/push。
- 人工边界：真实扬声器的层次、响度、疲劳感与 Boss 警告辨识度挂账，自动化只证明播放次数、资产选择、优先顺序和生产屏消费。

## 固定验收门

1. 同一 fixed frame 内，同一出手方阵营的 20 条普通命中只计划一个命中 SFX；玩家与敌方同拍命中可各保留一组。
2. 同组命中按 `ultimate > critical > normal` 选一个代表音效，不按目标数叠播；相同资产全帧去重。
3. `Phase0aBossChargeStarted` 复用既有 `battleChargeStart`，且在同拍计划中排在普通动作/命中之前。
4. 既有 Q/R、防御、胜负、死亡静默语义不变；生产 `Phase0aBattleScreen` 只消费帧计划，不再逐事件直接播放。
5. 破坏证红：生产屏退回逐事件播放时，多命中 widget 用例必须红；Boss 警告退化为空时优先级用例必须红。
6. targeted、邻接、analyze、整仓 format、macOS Debug build、持锁全量与独立 Gate 全绿，最终 worktree clean。

## 路线与预验证

- 依据交接章程 §11.1 表现层预授权，采用“事件保持原样、只在播放前按 fixed frame 规划”的方案；没有改 reducer、事件、数值或全局音频后端。
- 有效真红：新增帧聚合测试在生产 API 缺失时编译失败；先修正过一次错误的防御事件夹具，不把无效夹具失败计入证据。
- 初步绿：帧计划与真实 `Phase0aBattleScreen` 接线 `10/10`，音效/防御/Boss/伤害聚合邻接 `27/27`，analyze 为 `No issues found`。
- 最终 full/analyze/format、双向真红与 detached Gate 原文由 tip 绑定的外置 receipt 对撞，不把本段预验证冒充 Gate。

## 后置挂账

- 真人在 24 active 密度下确认多目标技能不再叠爆、普通打击仍有力度、Boss 蓄力能从混战中被听见。
- 低特效/背景人群/震屏/闪光设置、专属 Boss 警告素材与跨平台声学矩阵属于后续 M4 表现/性能子门。
- 守阵和追击仍等待实体耐久、路线/检查点与延误护卫生产语义，不在本批猜默认。
