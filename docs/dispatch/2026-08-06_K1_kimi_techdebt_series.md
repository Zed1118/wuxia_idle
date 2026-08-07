# 夜批单 K1 · 技术债目标序列(2026-08-06)

## 背景与基线
- 仓库:/Users/a10506/Desktop/Projects/挂机武侠(Flutter macOS,Isar+Riverpod,买断制武侠挂机)
- 工作树(已建好并预热:pub get / libisar.dylib / build_runner 均完成):`.claude/worktrees/kimi-techdebt`,分支 `kimi/tonight-techdebt`,基线 main `74a7993c`
- 必读:项目 CLAUDE.md §9.1「执行端操作坑速查」,全部适用
- 目标序列制:目标 1 → 2 → 3 依次推进,做到哪冻到哪,未开始不算欠账;每目标完成即独立 commit

## 目标 1:生产代码裸用 `dart:math Random()` 位点收口(注入化)
现状(先自己 Phase 0 实测):lib/ 生产代码直接构造 `Random()`(dart:math 签名)约 15 处(历史盘点值,以实测为准;已知一处 `lib/features/mainline/presentation/stage_entry_flow.dart:233` 的 `rng: Random()`;`lib/features/debug/` 下不算生产)。这些位点绕开项目 `rngProvider`(Rng 抽象)注入体系,测试 override 不到。
期望终态(可观测验收):
- 立一个 Random 类型注入点(Provider<math.Random> 或构造注入,设计你定;参考先例:2026-07-26 对 DefaultRng 的收口体例=UI/flow 层 `ref.read` + service 层构造注入,grep `test/shared/utils/rng_provider_wiring_contract_test.dart` 看契约测样式)
- lib/ 生产代码 dart:math `Random(` 裸构造 grep 归 0(白名单:注入点定义处本身、lib/features/debug/)
- 不改任何行为/数值/概率:默认路径仍是无种子随机,纯接线重构
- 新增 wiring 契约测:注入固定种子 Random 可 override 生效(断言可预测结果)+ 破坏证红(任选一位点改回裸 `Random()`,契约测必红;记录红输出后还原复绿)
边界:不动 numbers.yaml 数值;不动既有 rngProvider/Rng 体系语义;确定性断言写在纯函数层,不在 widget 层。

## 目标 2:`extension ... on` 实体类硬编码周期清账
- 扫描 lib/ 全部 `extension ... on <实体/def 类>`(Isar collection 与 def 类优先),逐个检查体内硬编码(魔法数/阈值/中文文案串/id 字符串)
- 产出审计表(file:line / 硬编码内容 / 风险评级 / 建议去向)写进 REPORT_K1.md 附录
- 只修「低风险且归宿明确」项(如常量已存在于 tokens/config 只是没引用);拿不准的只列表不动

## 目标 3(弹性尾,时间富余才做):测试假绿抽查
- 判据:「破坏那行生产代码,这条断言必然红吗」;抽查战斗/结算/掉落域 10-15 个测试文件
- 每文件给结论(真守卫 / 疑似假绿+理由);明显假绿且修法自明的修掉(独立 commit),其余列报告

## 验收四证据(每目标)
1. 全项目 `flutter analyze --no-pub` 0 issues(输出贴 REPORT_K1.md)
2. targeted 测试逐文件单独跑,逐文件确认「All tests passed」出现(多文件批跑会静默漏跑)
3. 目标 1 破坏证红记录(改坏→红输出→还原→绿输出)
4. commit message 前缀:完成的目标 `[READY] K1-目标N ...`;冻结的 `[BLOCKED] K1-目标N 原因`;报告落 worktree 根 `REPORT_K1.md`

## 禁区
numbers.yaml / GDD.md / PROGRESS.md / BACKLOG.md / lib/shared/strings.dart / assets/ / pubspec.yaml 一律不动;不改任何数值与概率;不跑全量 test(收账方跑);写完 dart 文件必 `dart format <改动文件>`(CI 门禁);拿不准冻结 [BLOCKED],禁止硬做。
