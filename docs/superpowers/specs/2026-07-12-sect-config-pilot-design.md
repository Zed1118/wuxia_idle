# 宗门月结配置依赖收窄设计

## 背景

`SectMonthlyTickService` 当前接收完整的 `NumbersConfig`，但实现只读取
`numbers.sectEvent`。这使服务边界大于实际需求，也迫使月结测试用
`noSuchMethod` 伪造整个配置根对象。

## 目标

- 将月结编排服务的配置依赖收窄为现有具体值对象 `SectEventDef`。
- production provider 继续从 `numbersConfigProvider` 取得真实配置，并只把
  `.sectEvent` 注入月结服务。
- 测试直接构造 `SectEventDef`，移除仅为月结服务存在的宽接口 stub。

## 非目标

- 不新增抽象接口或依赖注入框架。
- 不修改 `data/*.yaml`、配置字段、概率、冷却、声望或月结算法。
- 不改 `SectEventService` 与 `SectReputationDecayService` 的现有依赖；它们不在本试点范围。
- 不扩展到其他 NumbersConfig 消费者。

## 方案

1. `SectMonthlyTickService` 字段从 `NumbersConfig numbers` 改为
   `SectEventDef config`，`compute` 直接读取该值对象。
2. `sectMonthlyTickServiceProvider` 传入
   `ref.watch(numbersConfigProvider).sectEvent`，保留真实生产接线。
3. 两组月结测试继续用相同 YAML fixture 生成 `SectEventDef`；只有仍被
   `SectEventService` / `SectReputationDecayService` 使用的完整 stub 保留。
4. 用编译失败证明测试先约束新构造 API，再实现 production 代码使其转绿。

## 风险与控制

- 风险：provider 漏改导致编译失败。控制：targeted tests + `flutter analyze`。
- 风险：测试 fixture 在收窄过程中发生数值漂移。控制：复用原 map，不改字段和值。
- 风险：误删仍被相邻服务使用的 stub。控制：只删除不再有引用的 stub，并运行宗门月结与 Isar 持久化测试。

