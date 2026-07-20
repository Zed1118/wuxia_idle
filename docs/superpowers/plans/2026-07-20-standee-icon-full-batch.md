# 立绘图标全批计划

## 目标

用现有透明厚涂 battle 资产作风格锚，补齐 16 个敌人立绘与断魂庄 3 件装备的 icon/detail 图；逐张完成色键抠图、战斗底合成验收、生产路径接线与资产守卫验证。时间允许再升级撑伞高人源图。

## 分支

`codex/art-standee-gen`

## 验收标准

- [x] 16 个敌人 `iconPath` 指向真实透明 RGBA PNG，生产消费方为 `boss_gauntlets.yaml` / `expeditions.yaml` → `GameRepository` → battle `CharacterAvatar`。
- [x] 每张敌立绘均记录风格锚，并通过透明角、alpha 包围盒、战斗灰雾底合成目检；全批采用连通背景、收边 1px、轻羽化抠图。
- [x] 立绘脚底 fraction 由 alpha 包围盒实测，并按现有 `_stageStandeeFootFraction` / `_stageStandeeOpticalProfile` 接入校准。
- [x] 断魂庄 3 件装备各有 icon/detail 两图，路径与 `data/equipment.yaml` 一致，`known_missing_assets.txt` 对应 6 行清账。
- [x] targeted：资产/pubspec、battle 立绘/几何、断魂庄验证、远征配置共 52/52 通过。
- [x] `flutter analyze` 0 issue；工作树仅含允许范围内改动且最终干净。
- [x] 红线影响：不改数值、三系、在线/离线、反主流机制、schema；不新增 Dart 中文文案或数值配置。
- [x] 残留风险：20/20 已目检达标、0 `[BLOCKED]`；无未覆盖生产资产。

## 任务切片

1. 盘点 16 个空 `iconPath`、提示词、风格锚、校准机制与 allowlist。
2. 生成并验收断魂庄 7 敌，接线、校准、targeted 后提交。
3. 生成并验收百草岭 9 敌，接线、校准、targeted 后提交。
4. 生成并验收 3 件装备 icon/detail，清 allowlist 后提交。
5. 时间允许升级撑伞高人；否则明确记 `[BLOCKED]`。
6. 新鲜运行最终验证，写四证据，清理临时产物并以 `[READY]` tip 冻结。

## 当前恢复点

- 状态：已完成，待 `[READY]` 冻结。
- 最后完成：16 敌、3 件装备与撑伞升级均已提交；最终四证据与透明资产检查已转绿。
- 下一步：清理 `tmp/imagegen`，提交本恢复点并打 `[READY]` tip。
- 已跑验证：最终新鲜运行 `flutter analyze` → 0 issue；资产/pubspec、battle 立绘/几何、断魂庄验证、远征配置 → 52/52 通过；asset audit missing 0、allowlist 实质行 0；23/23 生产 PNG 均有非空 alpha 包围盒且四角透明。此前一次命令误写不存在的短路径导致 1 个加载错误，已用正确路径完整重跑转绿。
- 阻塞项：无；0 `[BLOCKED]`。
- 出图统计：20 张独立源图（16 敌，其中苏无咎复用已达标探针；3 装备；1 撑伞升级）/ 20 达标 / 0 `[BLOCKED]`；共落 23 个生产 PNG（16 敌 + 3×icon/detail + 1 撑伞替换）。
- 合成验收：17 立绘均在战斗山林底与深灰面板底通过；3 装备均在深灰面板底通过。20/20 无白边、粉边、残留投影或明显锯齿，透明四角 alpha 全为 0。
