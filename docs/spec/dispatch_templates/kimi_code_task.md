# Kimi 代码任务派单模板

> 使用方式:Claude 派单时以本模板为底稿,填全部 `[ ]` 占位段;基线数(全量 pass 数/覆盖率)**派发当日实测**,禁转抄。交付给用户时全文展开(不引用本文件),复制边界按哨兵行约定。

---

# Kimi 代码任务派单 · [日期] · [任务名]

## 0. 角色与边界
你是挂机武侠项目(Flutter Desktop · macOS 开发)的代码执行端。只做本单「任务定义」内的事;
规划与终审在 Claude 端。拿不准的设计决策:停下,在恢复点文件写明阻塞项,不要自作主张折中。

## 1. 环境准备(硬性第一步,跳过必失败)
```bash
cd /Users/a10506/Desktop/Projects/挂机武侠
git worktree add .worktrees/[worktree名] -b kimi/[分支名] main
cd .worktrees/[worktree名]
cp /Users/a10506/Desktop/Projects/挂机武侠/libisar.dylib .
export PUB_HOSTED_URL=https://pub.flutter-io.cn
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze --no-pub        # 必须 0 issues 才开工
```
环境自查锚:全量 `flutter test --no-pub` 基线 **[N] pass / 0 fail**([日期]实测)。
若 analyze 报上万 undefined 错误 = build_runner 没跑成,回本段重来,不要去查 SDK 版本。

## 2. 任务定义
- **目标**:[一句话目标 + 当前实测基线]
- **验收标准**:[可验证条目清单;语义化目标优先于裸数字;定量目标附实测口径]
- **可碰文件域**:[明确目录/文件白名单]
- **禁区**:一切未列入可碰域的 `lib/` 生产文件、`data/*.yaml`、`lib/shared/strings.dart`、
  `GDD.md`、`PROGRESS.md`、`CLAUDE.md`、`pubspec.*`、schema/saveVersion。
  发现生产疑似 bug:**不修**,在恢复点文件记录现象+复现路径,交 Claude 定夺。
- **红线预判**:[Claude 填:是否触及 §5.4 数值/§5.3 三系锁死/§5.5 在线=离线/§5.1 反主流]
- **实现提示(非强制)**:[现有 harness/模式指路]

## 3. 执行纪律
1. 每片新测/新码先证能红(断言真的会失败)再定稿。
2. 过程 targeted + `flutter analyze`;批末一次全量 `flutter test --no-pub`。
3. Edit 过的 dart 文件 commit 前 `dart format <文件>`;批末
   `dart format --output=none --set-exit-if-changed lib test` 兜底。
4. commit 中文动宾、小切片,每个可独立验证的切片一次 commit。
5. 禁止:push、切分支、动主 checkout 或其他 worktree、升级/新增依赖。

## 4. 恢复点文件(必建)
`docs/superpowers/plans/[日期]-[任务名].md`:
目标/分支/验收标准/任务切片/当前恢复点(状态·最后完成·下一步·已跑验证·阻塞项)。

## 5. 交付标准(缺项=未交付)
1. 生产接线/覆盖对象说明(file:line)。
2. targeted 结果贴命令+通过数;[定量验收的实测前后对比]。
3. 红线影响说明:逐项声明。
4. 残留风险:未覆盖面/发现的疑似问题列清。

## 6. 冻结信号(完工必做)
全部 commit、`git status` 干净,tip commit 前缀 `[READY]`
(可空 commit:`git commit --allow-empty -m "[READY] <一句话交付摘要>"`);
需人拍板 → `[BLOCKED]` + 恢复点写明拍板点。
