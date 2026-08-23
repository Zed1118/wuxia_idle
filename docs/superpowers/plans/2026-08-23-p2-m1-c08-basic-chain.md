# P2-M1-C08：五武器普攻链候选

## 交付范围

- 在纯领域层提出五种武器身份：剑、重兵器、软兵器、双持/奇门、暗器。
- 用共享 `BasicAttackSegment` 表达每段的 geometry、timeline 与有序 effect 引用；链只保存 typed 引用，不执行效果。
- 提供确定性的连段推进与空闲/中断重置校验，拒绝空链、重复段 ID、空引用、非法重置 tick 和越界索引。
- 不写中文文案、最终平衡数值、生产接线、`SkillDef`/数据/YAML/model/reducer 修改。

## 恢复点与 G1 风险

1. 当前 API 的 `WeaponType`、段 ID 和三类 opaque reference 尚未接入公共 registry；后续接线前需由 G1 主审确认命名及 canonical ID。
2. `nextSegmentIndex` 是无状态候选函数，调用方仍需保存当前段和 idle tick；是否由 action timeline/session 持有快照需在 C03/C10 合同中统一。
3. 本切片没有写入最终段数量、攻击距离、伤害或节奏值；具体五武器内容与平衡应由数据层在 schema 冻结后注入。
