# 2026-08-28 试玩输入阻塞诊断计划

## 结果合同

- 单一目标：在基线 `1ba913a633beb0fd8f9b47764161f47c54260707` 上，用第 8 章 slot1 与 CGEvent 实测确定移动和数字技 1–6 失效的可证伪根因。
- 验收分母：D1 移动证据、D2 六槽绑定/UI 证据、D3 不超过 80 行的诊断报告、风险匹配验证、receipt、clean READY/BLOCKED tip，共 6 项。
- 当前基线：分支 `codex/p2-d1-input-blocker-diagnosis-20260828`，HEAD 与唯一基线相同，工作树 clean，禁区零 diff。
- 关键阻塞：需先取得真实 Flutter macOS 窗口、CGEvent 键事件和生产战斗内部状态的同时实测。
- 预期增量：将 D1/D2 从 0/2 未定性推进到 2/2 有实测值的确定结论；命中禁修边界则交付真实 BLOCKED，不冒充修复。
- 成本上限：无可靠 usage 读数；按真实墙钟执行，约 90 分钟无证据进展即停线重评。
- 非目标：不改设计、数值、schema/saveVersion、玩家可见新 UI、禁区文件、main；不 push/merge/revert。

## 验收清单

- 生产路径：第 8 章真实 slot1 进入 `Phase0aBattleScreen`，CGEvent 驱动，实时读窗口 bounds。
- 实测证据：`_handleKey` / `_heldMovementKeys` / `intentsFor` / reducer position，以及六槽绑定、`equipped.length`、技能封印渲染。
- 修复边界：仅允许纯输入层、状态机、渲染层确定性 bug；若改 `lib/`，必须补红线测试并做删支点/强制退化两向破坏证红。
- 质量门：targeted、`flutter analyze --no-pub lib test tool`、整仓 format check、加锁全量 test、diff check；逐条记录 reporter 末行和 `[E]` 数。
- 红线影响：预期不触及数值硬线、三系锁死、在线=离线、反主流或文案/数值硬编码。
- 残留风险：实时驱动可改动存档；必须用冷备与收工 SHA 对撞并在报告/receipt 披露。

## 当前恢复点

- 状态：`[BLOCKED]` 收工。唯一基线的真实第 8 章战斗无法复现全局移动/技能失效，只证实未绑定数字键零反馈；补 UI 提示命中禁修边界。
- 已完成：冷备；CGEvent+实时 bounds 三轮生产取证；D1/D2 结论；46 行诊断报告；探针精确还原；slot1–3 回复权威 SHA。
- 下一步：执行端无后续施工；等待协调者依本报告与外置 receipt 独立复核，不合并、不推送。
- 已跑验证：targeted `28/28` + `4/4` + `18/18`；analyze 0 issue；format 1626/0 changed；加锁全量 `5643/5643`、`[E]=0`。
- 阻塞项：原真人组合现象在指定基线/存档/CGEvent 路径下不成立；无证据授权猜测焦点、实例或键位原因。
