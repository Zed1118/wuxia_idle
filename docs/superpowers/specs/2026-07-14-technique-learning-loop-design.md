# 心法学习闭环（学新心法接线）· 设计

> 2026-07-14 用户拍板：可学范围 = **境界内全部可学**；入口 = **技能面板心法区**。
> 来源：backlog §十三 #1（07-14 全量审查后专业玩法评估第一项）。分支 `feat/technique-learning-loop`。

## 1. 问题

GDD §4.2 明定「学习新心法需消耗领悟点」，但 `TechniqueLearningService.learn` 全仓 0 业务 caller：玩家无任何主动学新心法的通道，新心法只随收徒进队，祖师心法阶终身锁定在开局选择。领悟点（insightPoints）产出链与凝练消费链均已 live，学习是缺失的第二个 sink。

## 2. 拍板后的形态

- **可学列表** = `techniques.yaml` 全集中该角色**未持有**的心法；`tier ≤ RealmUtils.techniqueTierCapOf(realmTier)` 可学，超阶项灰显「境界不足」（承 §5.3「可观摩不可修」体例）。
- **成本** = `numbers.yaml combat…learning_cost`（主修 500 / 辅修 100 领悟点，现成配置，**不动数值**）。
- **角色范围** = 技能面板当前角色（founder 与弟子同规则）。
- **主修**：仅在无主修时可学为主修；换主修仍走散功（§4.3 语义不动）。辅修 ≤3（learn 服务现校验）。
- **确定性消费**：无概率、无日课、无新道具（反抽卡精神；被拒的「心法残卷合成本」「相生缺口提示」「换主修损失预览」不碰）。
- **叙事口径**：闭关参悟所得（领悟点=参悟积累，学习=参悟成书）。

## 3. 实装切面

1. **编排服务** `TechniqueLearnFlowService`（cultivation/application，镜像 `InsightExchangeService` 体例：自持 Isar、自开 writeTxn、result 对象）：校验（角色存在/def 存在/未持有）→ 委托 `TechniqueLearningService.learn` 四态校验 → 同事务落库（Technique put + 扣 insightPoints + 写 mainTechniqueId/assistTechniqueIds + `recordTechniqueLearned` 事件）。
2. **事件** `GameEventService.recordTechniqueLearned`（#4 补实装，`GameEventType.techniqueLearned` 枚举已存在、EnumType.name 零 schema 风险）；退役头注「#4 不实装」条目。
3. **UI**：`_MeridianOverviewPanel` 后加常驻「研习新心法」行（沿凝练 H1 批3 先例：常驻显领悟点，无可学项/0 点时灰显）→ `PaperDialog` 可学列表（按 7 阶分组，行内显流派/速度加成/成本，超阶灰显）→ per-row 研习按钮 → 二确 `PaperDialog`（无主修时可选学为主修/辅修）→ SnackBar 反馈 + invalidate（characterById / characterAllTechniques family）。
4. **文档订正**：`insight_exchange_service.dart:43`「不开学心法 UI」注释、`game_event_service` #4 注释、`numbers.yaml learning_cost`「待接入」注释（仅注释，不动值）、CLAUDE §5.3「学心法 UI 属 Phase 5+」句（v1.38）、backlog §十三 #1 勾账、GDD 无需改（实装即兑现 §4.2 原文）。

## 4. 测试

- 服务测：学辅修成功（落库/扣点/assist 列表/事件行 type=techniqueLearned）；学主修成功（无主修时）；alreadyOwned / tier 超阶（§5.3 红线）/ 主修已存在 / 辅修槽满 / 领悟点不足 / 角色缺失 各拒绝态零副作用；同事务原子。
- widget 测：入口常驻/灰显两态；dialog 列出境界内候选、超阶灰显；二确流出现。
- 经济：不加硬断言（学习成本初值已配置，真机体感后按「先诊断再调数」纪律处理）。

## 5. 红线自查

§5.1 无日课无抽卡确定性消费 ✓ §5.3 learn 服务硬拦 + UI 灰显不可达 ✓ §5.5 领悟点产出在线=离线同源，本批只加消费 ✓ §5.6 成本走 numbers 现配置、文案进 UiStrings ✓ §5.7 无教程弹窗，入口常驻不推销 ✓ 无 schema/saveVersion 变更（Technique collection 现成字段）✓
