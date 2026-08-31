# P2 M5 心魔个人进度结果合同

## 唯一目标

- task：`P2-M5-INNER-DEMON-PERSONAL-PROGRESS`。
- 基线：`ef2a8fe20a70f4aca90a272186cf7c936e364008`。
- 将 M5 心魔“记录作用域”从存档全局事实修正为实际参战角色个人事实，使固定矩阵由 `36/42` 推进到 `37/42`。

## 生产合同

1. 心魔胜利继续由既有 `applyVictoryResolution` 在同一事务写入 U09 `RewardClaimReceipt`，不新增写 owner。
2. 个人进度以 receipt 的 `contentId + participantId` 为事实；存档级 `MainlineProgress.clearedStageIds` 继续承担全局内容链、周目和宗门首通语义，不再作为角色个人通关事实。
3. 角色面板与 `InnerDemonScreen(characterId)` 必须读取同一角色 family；一个角色通关不得令另一角色显示已通或获得重打入口。
4. 旧档没有可证明实际参与者的心魔 receipt 时保持个人进度为空，不从全局通关事实猜人或伪造回填。

## 验证与停止线

- production settlement → receipt → personal provider → 角色面板/心魔列表形成连续证据。
- 破坏证红：移除 `participantId` 过滤后，“另一角色不得继承”用例必须失败。
- targeted、analyze、整仓 format、锁保护全量、项目 Gate、合并 push 与精确 SHA CI 全部通过后才关闭本切片。
- 只关闭心魔记录一格；顶层 M5 在剩余五格关闭前保持 `0/1 BLOCKED`。

## 禁止范围

- 不改 schema/saveVersion、奖励、数值、概率、经济、解锁阈值、YAML TUNING、技能或战斗规则。
- 不伪造旧档个人通关，不启动 M3/M7。
- 真人桌面和 Windows 实机继续挂账，不冒充正式 M5/Phase 2 验收。
