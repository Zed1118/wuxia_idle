# 立绘图标全批计划

## 目标

用现有透明厚涂 battle 资产作风格锚，补齐 16 个敌人立绘与断魂庄 3 件装备的 icon/detail 图；逐张完成色键抠图、战斗底合成验收、生产路径接线与资产守卫验证。时间允许再升级撑伞高人源图。

## 分支

`codex/art-standee-gen`

## 验收标准

- [ ] 16 个敌人 `iconPath` 指向真实透明 RGBA PNG，生产消费方为 `boss_gauntlets.yaml` / `expeditions.yaml` → `GameRepository` → battle `CharacterAvatar`。
- [ ] 每张敌立绘均记录风格锚，并通过透明角、alpha 包围盒、战斗灰雾底合成目检；发现白边时按连通背景、收边 1px、轻羽化重抠。
- [ ] 立绘脚底 fraction 由 alpha 包围盒实测，并按现有 `_stageStandeeFootFraction` / `_stageStandeeOpticalProfile` 接入必要校准。
- [ ] 断魂庄 3 件装备各有 icon/detail 两图，路径与 `data/equipment.yaml` 一致，`known_missing_assets.txt` 对应 6 行清账。
- [ ] targeted：`flutter test --no-pub test/tools/asset_audit_test.dart test/data/pubspec_asset_declaration_test.dart` 通过，并运行相关 battle 视觉测试。
- [ ] `flutter analyze` 0 issue；工作树仅含允许范围内改动且最终干净。
- [ ] 红线影响：不改数值、三系、在线/离线、反主流机制、schema；不新增 Dart 中文文案或数值配置。
- [ ] 残留风险：逐张记录未目检/风格漂移/透明边缘/可选撑伞图状态，不把未达标图接入生产。

## 任务切片

1. 盘点 16 个空 `iconPath`、提示词、风格锚、校准机制与 allowlist。
2. 生成并验收断魂庄 7 敌，接线、校准、targeted 后提交。
3. 生成并验收百草岭 9 敌，接线、校准、targeted 后提交。
4. 生成并验收 3 件装备 icon/detail，清 allowlist 后提交。
5. 时间允许升级撑伞高人；否则明确记 `[BLOCKED]`。
6. 新鲜运行最终验证，写四证据，清理临时产物并以 `[READY]` tip 冻结。

## 当前恢复点

- 状态：进行中。
- 最后完成：断魂庄 7 敌已生成、抠透明、双底色合成目检、接入 `boss_gauntlets.yaml`，并按 alpha 包围盒补透明识别、脚底 fraction 与水平重心/尺度校准。
- 下一步：提交断魂庄 7 敌切片；随后生成百草岭 9 敌。
- 已跑验证：`flutter test --no-pub test/tools/asset_audit_test.dart test/data/pubspec_asset_declaration_test.dart test/features/battle/presentation/character_avatar_test.dart test/features/boss_gauntlet/gauntlet_enemy_validation_test.dart` → 33/33 通过。此前一次命令误写不存在的短路径导致 1 个加载错误，已用正确路径完整重跑转绿。
- 阻塞项：无。
- 出图统计：7 生成（苏无咎复用已达标探针）/ 7 达标 / 0 `[BLOCKED]`。
- 合成验收：7/7 均在战斗山林底与深灰面板底无白边、粉边、残留投影或明显锯齿；透明四角 alpha 全为 0。
