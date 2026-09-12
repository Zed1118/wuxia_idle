# 护送战斗反馈与 Q 快速施放核验（2026-09-06）

## 结论与版本

- 本地工程候选验证完成；正式 M0–M9 仍为 **1/10**。本批未合 main、未推远端，没有本批精确 SHA 的远端 CI 结论。
- 起点 `c890208e5`；生产实现/正常试玩构建 `92a45117f06ea97341fff037c88c407683991a86`；最终全量测试树 `46136226b0e13cf38b51e8feb7045df704d467ae`，**6114/6114 PASS**。
- 测试树只比构建树多 Ch9 测试夹具修正与计划记录；`git diff --exit-code 92a45117f 46136226b0e13cf38b51e8feb7045df704d467ae -- lib data macos pubspec.yaml pubspec.lock` 为空。后续 READY 提交仅收录交付文档。
- 证据根目录：`/Users/a10506/Documents/Codex/2026-09-06/wuxia-defend-quick-gather`。实际完整耗时、返回码和 SHA 见 `full-result.json`，不以单独进程退出 0 判 PASS。

## 用户问题与生产修复

| 问题 | 原因与修复 | 验证边界 |
| --- | --- | --- |
| 部分敌人不出手 | 冷却中的敌人仍索取攻击名额，固定排序使后续敌人饥饿。AI 只让本 tick 可出手者索取名额；Session 显式传入真实步长 | 移动策略、出手预算、伤害/冷却值均未改；恢复出手会提高实际压力 |
| “阵眼”含义突兀、看不出敌人在攻击什么 | stage_02_01 通过既有叙事加载器显示“镖货”及护送条件；守护物受击强调、敌人到实际目标的短攻击轨迹、剩余秒数 | 敌人在射程内攻击镖货时可以站定；并非每个敌人都应追玩家 |
| 约 5 秒后才显示失败 | 真正的目标损毁事件、终局和 Host 失败回调在同 tick；损毁原因同步传入既有重试正文 | 未复现原始固定 5 秒延迟，不能宣称该时长现象已彻底消除 |
| Q 需要再次左键确认 | 按 Q 时将当前鼠标全局位置经最新舞台/镜头转换为世界坐标，直接提交 Gather 命令 | 保留技能印点击选点；不打断移动/J/持续普攻；鼠标无有效位置时沿用脚下回退 |

生产改动：`phase0a_enemy_ai_adapter.dart`、`phase0a_combat_session.dart`、`phase0a_battle_screen.dart`、`phase0a_vfx_controller.dart`、`phase0a_mainline_battle_host.dart`、`stage_entry_flow.dart`、`lib/shared/strings.dart`、`data/narratives/stages/stage_02_01_defend_guidance.yaml`。

UI 文案集中到 UiStrings，护送叙事走 YAML；复用既有 VFX 时长/容量和攻击轨迹绘制器。未修改 numbers、属性倍率、奖励、解锁、存档/schema、依赖。目标损毁原因仅作为可选展示参数沿实际导航链传递，不新增结算真相源。

## 自动验证与失败留档

- Q 四文件 64/64：快照坐标、镜头移动但鼠标静止、非零窗口原点、Q repeat、冷却、暂停、失焦、持续普攻和两秒启动计时。见 `quick-gather-final.log`，旧实现 RED 见 `quick-cast-red.log`。
- AI 首轮 80/80，最终显式步长后的相关回归 115 + 9 = 124/124；见 `ai-delta-regression.log`、`ai-session-regression.log`。独立源码复核覆盖攻击令牌与输入生命周期。
- 真实主线护送 Host 6/6：真实攻击/镖货反馈、目标损毁且玩家存活的原因、玩家先死不伪造镖货原因、同 tick 单次回调。见 `defend-feedback-cache-evict2.log`；夹具在 fakeAsync 用例间清除已加载资源 Future，未给生产逻辑新增等待。
- `dart analyze lib test tool` 无问题；后续 Ch9 测试专门 analyze 无问题。见 `ai-delta-analyze.log`、`ch9-realm-analyze.log`。
- 首轮全量主动停止：3 个冷却夹具、1 个新参数默认值源码约束失败已修正，日志为 `full-first.log`/`full-first-result.json`；被取消的退出 0 不记 PASS。
- 第二轮 `92a45117f` 完整运行 6113 PASS / 1 FAIL，见 `full-second.log`/`full-second-result.json`。唯一 Ch9 迁移夹具默认学徒挑战二流，修复 AI 后同种子 83 拍败。夹具对齐章内境界后 32 拍胜，血/内力/攻防和胜利断言不变，Ch8/9/10 18/18。见 `ch9-fixture-comparison.json`、`ch8-ch10-realm-regression.log`。高属性迁移夹具不作为难度验收。
- 最终锁保护 `flutter test --no-pub`：**6114/6114 PASS**，见 `full.log`/`full-result.json`。未占用、删除或绕开其他任务的全量锁。

## 原生、存档与交付

- 1280×720、1440×900 两个原生窗口：镖货、秒数、受击指向可见；Q 后不再点击即扣真气并进入冷却。见 `native-escort-1280x720.png`、`native-escort-1440x900.png`、`native-q-1280x720.png`。
- 上述观察包用独立高防角色，护送失败原因由实际 Host 和实际 RetryBody 在观察外壳显示；不冒充正常导航和合法角色难度。详 `native-review.json`。
- 另用最新用户存档的独立副本运行正常 `lib/main.dart`：槽 2 → 江湖纪事 → 章节卷轴 → 第二章 → 镖局护送可见重打 → 祖师 → 战斗 → 失败重试 → 再战 → 返回章节。合法角色 4543 HP，受敌人正常攻击后很快失败；真实重试链可用。该轮未取得“玩家存活、镖货先毁”的正常导航截图，该分支以真实 Host 测试和观察包为证。
- 用户授权退出旧版后，正常结束试玩并冷备份三个槽及设置；此时已通 6 关，最新目标茶馆论剑，用户旧版护送胜利截图为 `user-escort-victory-before-update.png`。
- 更新既有试玩 bundle `com.pen.wuxia.humanfix20260905`，启动前三个槽与冷备份逐个 SHA256 相同。旧程序在 `previous-human-playtest-app.app` 可恢复；隔离观察副本不回写。原 `com.pen.wuxia.wuxiaIdle` 生产存档未操作。
- 正常新版：`/Users/a10506/.codex/worktrees/1454/挂机武侠/build/human-fixes-runtime-20260905/wuxia_human_fixes.app`；AOT SHA256 `6b54ee69fce9c2ad988178bc571cdf1cea6d21cdcd16f705f0d16e0b45264fcf`，codesign 验证通过。包元数据与备份清单见 `playtest-package.json`/`human-save-before.json`。
- 新版进程已启动并显示“轻触继续”页，截图 `reopened-playtest.png`。CUA 能读窗口并通过菜单置前，但坐标操作返回 `noWindowsAvailable`，因此停在启动页交给用户点击；未冒充已加载最新槽的 UI 读回。安装前最新三槽的哈希校验已完成，正常入口读取其独立副本的核验见上文。

## 保留缺口与下一步

1. 真人重点复核 Q 指向、恢复攻击后的应对时间，以及护送目标/失败原因是否一眼能懂；玩家站定后迅速失败说明压力变化真实存在，不能靠自动化绿测直接关闭难度验收。
2. 本轮未做新性能剖析，既有密集战斗 p99 超标仍开放；Windows 物理键鼠/音频/GPU、72h 和五武器手感不计为通过。
3. 同版本真实体验满足后再安排既有主线评审/集成合同；本批只交付本地可复核候选与新版试玩。
