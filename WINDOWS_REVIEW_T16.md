# Windows 验收派单 prompt — T15 + T16

> 复制下面的 prompt 块到 Windows 端 Claude Code（DeepSeek）即可。第一行的
> `<Windows 端 wuxia_idle 绝对路径>` 替换成实际路径；首次拉代码前先
> `git clone https://github.com/Zed1118/wuxia_idle.git`。
>
> Mac 端反馈后再决定下一步（修问题 / 合 main / 开 T17）。

---

```
项目: wuxia_idle (<Windows 端 wuxia_idle 绝对路径>)
分支: feat/t16-riverpod-wiring
任务: T15+T16 验收（仅运行 + 视觉反馈，不改代码）

【背景】
wuxia_idle 是 Flutter Desktop 写实武侠挂机项目，Mac 端用 Opus 写代码，
Windows 端做视觉验收。当前 main 停在 T14（52085e7），feat/t16-riverpod-wiring
分支含 T15（攻击动画+伤害飘字）+ T16（Riverpod 串接+大招触发+结算 overlay）
共 8 个 commit。需要你拉最新分支，跑应用，验视觉效果。

【硬约束】
- **绝对不改任何 Dart 代码 / numbers.yaml / strings.dart**。CLAUDE.md §8
  锁死「Windows DeepSeek 只写 data/narratives, lore, events 文案」，本次任务
  纯验收，发现问题反馈给 Mac 端处理，不要自己动手修
- 不要 push 任何分支。如果有 build artifact / .g.dart 等本地生成物 git status
  里冒出来，**不 add 不 commit**
- 不要 merge / 不要发 PR

【执行步骤】

1. 拉最新代码:
   git fetch origin
   git checkout feat/t16-riverpod-wiring
   git pull

2. setup（首次拉 / .g.dart 不入库，必跑）:
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs

3. 验静态:
   flutter analyze    # 期望 No issues found
   flutter test       # 期望 All tests passed (156/156)

   两个里任何一个不绿 → 立刻停下，把完整输出贴回反馈，**不继续往下跑应用**

4. 跑 Windows desktop:
   flutter run -d windows

5. 视觉验收（按下面 8 项逐一截图+文字描述）:

   **T14 静态布局**
   - [ ] 6 个角色（左 3 / 右 3，最右下死亡变灰 opacity 0.3）
   - [ ] 三流派色都出现：刚猛红 / 灵巧金 / 阴柔紫边框
   - [ ] HP 条三段色（>50% 绿 / 25-50% 黄 / <25% 红）

   **T15 动画 + 飘字**
   - [ ] 攻击动画：左队角色攻击时向右前冲再退回（约 400ms 整体）
   - [ ] 普通伤害飘字白色，向上漂浮淡出
   - [ ] 暴击金色 +1.5 倍字号 + 整屏轻微抖动
   - [ ] 闪避灰色「闪」字
   - [ ] 克制时 ⬆ 标记（金）/ 被克制时 ⬇ 标记（灰）

   **T16 大招 + 结算（spec §16 验收）**
   - [ ] 内力不够的角色（左 #3 苏锦书）大招按钮永久置灰
   - [ ] 内力够的角色按下大招按钮 → 立即置灰；下次该角色行动 → 真的用大招
        （动画里能看到大招特效或日志里能看到「使用 XXX 大招」）
   - [ ] 战斗结束 → 弹出胜利/失败 dialog，显示总伤害/暴击次数/用时 tick

6. flutter inspector 验 rebuild 颗粒度（spec §16 验收 ②）:
   - 应用跑起来后用 IDE 的 Flutter inspector 或 DevTools 打开
   - 触发一次普攻造成 HP 变化
   - 看 rebuild 范围：理想只有受伤角色的 CharacterAvatar widget 重建，
     不是整个 _BattleField / 整屏重建
   - 如果整队 rebuild，记录下来（这是已知设计妥协，Mac 端可能后续细化到
     单角色 currentHp provider）

【反馈格式】
把以下内容打成一段文字（必要时附截图，截图建议存到 wuxia_idle 项目根目录的
`reviews/t16/` 临时文件夹下，方便 Mac 端 git pull 看；不要 commit 截图）:

  - flutter analyze 结果（一行）
  - flutter test 结果（一行）
  - 上面 8 项验收的逐项 ✅ / ❌ + 一句话观察
  - rebuild 颗粒度判断
  - 任何意外（崩溃 / 卡死 / 视觉异常 / 数值看着不对）

【兜底】
- 跑不起来（编译失败、SDK 版本不对、build_runner 报错）→ 完整复制错误堆栈
  反馈，不要自己琢磨改代码
- Flutter SDK 版本要求：>=3.4.0 <4.0.0。如果 Windows 端版本不在范围内，
  反馈版本号给 Mac 端，**不要自行升级 SDK**
- 战斗 mock 数据已经预设：左 3 活 / 右 2 活 + 1 死，左队会主动攻击对面，
  几十秒内一定能打完一场，看到结算 dialog 就算战斗流跑通

开工。
```
