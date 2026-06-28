# 2026-06-29 Night Shop Need Hints

## 目标

完成 backlog「商店货架需求提示」：商店物品在货架上显示当前谁用得上、哪个系统会消耗，降低经验丹、材料购买决策黑箱。

约束：只读派生提示；不改商店价格机制；不引入折扣、限时刷新、概率焦虑或新经济系统。

## 分支

`codex/night-shop-need-hints`

## 验收标准

- 商店货架每个商品展示用途提示，至少覆盖经验丹、强化材料、心血结晶、桃花岛材料/丹药等既有 item 类型。
- 经验丹提示能指出当前可使用角色；材料提示能指出会被哪些系统消耗。
- 优先复用 `ItemUsageLookupService`、`MaterialSourceLookupService`、现有 item def / active character provider / strings 层。
- `ShopService.purchase`、`ShopService.effectivePrice`、`data/shop.yaml` 标价与货架机制不变。
- 新增 targeted widget/unit tests；`flutter analyze` 通过。

## 任务切片

1. 阅读项目协议与 backlog，确认红线和范围。
2. 定位商店 UI、item use、usage lookup、material source 等现有实现。
3. 新增商店需求提示只读派生服务和字符串格式化。
4. 将提示接入商店货架 tile，不改变购买流程。
5. 补 targeted tests。
6. 运行 `dart format`、targeted tests、`flutter analyze`。
7. 更新恢复点并提交小切片。

## 当前恢复点

- 状态：实现完成，待提交。
- 最后完成：新增 `ShopNeedHintService`，商店货架已显示具体道具名、当前可用角色、消耗系统、其他来源；补充 service/widget tests；`flutter analyze` 与 targeted tests 已通过。
- 下一步：提交小切片并汇报。
- 已跑验证：`dart format ...`；`flutter analyze`；`flutter test --no-pub test/features/shop/shop_need_hint_service_test.dart test/features/shop/shop_screen_test.dart`。另试跑过 `flutter test --no-pub --no-test-assets ...`，因禁用 test assets 导致 shader asset 缺失，随后用正常 test assets 重跑通过。
- 阻塞项：当前 worktree 未初始化 CodeGraph，已用主项目 CodeGraph 索引辅助结构查询；实际修改以当前 worktree 文件为准。
