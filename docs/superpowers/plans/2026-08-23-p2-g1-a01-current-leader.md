# P2-G1-A01 当前掌门指针 fail-closed

## 合同

- `SaveData.founderCharacterId` 是唯一当前掌门指针；不从角色集合猜测首角色。
- 存档缺失、指针为空或指向不存在的 `Character` 均抛可诊断 `StateError`。
- 主线、塔、扫荡仅替换入口解析，不改变已有合法指针的装配、结算或参与者 policy。
- 不处理重打、bot/headless/扫荡参与者决策，不新增 MainlineRun、个人记录或伤势归属。

## 验证

- resolver 单测覆盖 null、合法指针、悬空指针。
- 三宿主均通过 shared resolver 后再进入既有 snapshot assembler。
- `flutter analyze` 与 resolver/现有 wiring 定向测试。

## 恢复点与边界

生产 wiring 仅移除静默 `findFirst()` fallback；参与者 policy 和持久化 schema 留给后续已授权任务。
