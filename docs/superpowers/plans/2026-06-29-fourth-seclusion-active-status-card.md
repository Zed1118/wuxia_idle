# 第 4 梯队 · 闭关中状态牌

## 范围

- 只在闭关进行中页面内部展示状态牌。
- 展示当前地点、已闭关时长、计划时长、预计收获类型。
- 不在主菜单增加提醒,不制造登录/催促感。
- 不改闭关结算、概率、离线收益、存档结构或数值。

## 验收标准

- `ActiveRetreatScreen` 显示闭关状态牌。
- 状态牌包含地图名、已闭关时长和计划时长。
- 状态牌只展示收获类型,不计算具体收获数值。
- 预计类型来自当前地图定义:磨剑石、经验、银两、心法领悟、内力、地图小产物、装备机会。
- Widget test 覆盖状态牌渲染。

## 验证

- `flutter test test/features/seclusion/presentation/active_retreat_exit_test.dart`
- `flutter analyze`
