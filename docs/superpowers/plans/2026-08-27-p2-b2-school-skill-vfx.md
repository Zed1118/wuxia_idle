# 批二 2.1：三系技能两段特效实施合同

## 单一目标

让正式数字技能从 `Phase0aSkillStarted/Applied` 生产事件进入 VFX 控制器，并在真实 `Phase0aBattleScreen` 中按刚猛、灵巧、阴柔三系显示可辨认的“起手 + 命中”两段程序化水墨特效。

## 固定验收门

- 生产映射以 typed `skill.style ?? player.school` 写入技能绑定，不按技能 ID 猜流派。
- `SkillStarted` 生成起手 VFX；`SkillApplied` 的每个 outcome 生成命中 VFX，同时保留既有伤害飘字。
- 三系起手和命中均有不同几何语言；大招只增强尺寸/强度，不新增文案或美术资产。
- 真实数字键和技能印路径能渲染非零尺寸 `CustomPaint`。
- 渲染级测试覆盖三系和两段；移除/短路任一技能 painter 时测试会红。
- 相关回归与 `flutter analyze --no-pub lib test` 通过，禁区文件除本门不涉及者全部不变。
- 分支工作区 clean，tip commit 以 `[READY]` 开头；不 merge、不 push、不碰 main。

## 实施切片

1. 扩充 VFX typed entry 与事件映射，补控制器单测。
2. 将技能绑定的流派语义接入正式 stage mapper。
3. 在反馈层按绑定解析三系，绘制明确尺寸的两段程序化水墨特效。
4. 补生产屏幕渲染级测试与破坏证红，运行相关回归和静态检查。

## 基线与计数

- 基线：`8c2753b3 [READY] 建立批二视觉基线`。
- 本门完成前，批二正式进度仍为 `0/3`；局部测试、提交或孤立实现不计完成。
