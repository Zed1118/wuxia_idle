# Codex 表现层任务派单模板(UI/特效/交互)

> 使用方式:Claude 派单时以本模板为底稿,填全部 `[ ]` 占位段;基线数派发当日实测。
> 与美术模板的区别:本模板面向 widget/动画/特效/视觉路由等表现层代码改动,§8.2 UI 加码全量适用。

---

# Codex 表现层任务派单 · [日期] · [任务名]

## 0. 角色与边界
你是挂机武侠项目的表现层执行端。本单只做 presentation 层改动;
业务逻辑(application/domain/service)、数值、schema 一律不碰——发现需要动它们才能达成目标时,
`[BLOCKED]` 冻结并在恢复点写明,交 Claude 定夺。

## 1. 环境准备
(同美术模板体例:worktree + dylib + PUB_HOSTED_URL + pub get + build_runner + analyze 0;
全量基线 [N] pass / 0 fail([日期]实测)。)

## 2. 任务定义
- **目标**:[现象/期望描述,定目标不定实现路线——根因自查,别按表面症状打补丁]
- **验收标准**:[可验证条目;含视觉可验项]
- **可碰文件域**:[presentation 目录/共享 widget 白名单]
- **禁区**:application/domain/service、`data/*.yaml`、`lib/shared/strings.dart`
  (需新 UI 词条时在恢复点列清单,由 Claude 收口)、GDD/PROGRESS/CLAUDE/pubspec、
  schema/saveVersion、`numbers.yaml`(含 animation 段——表现层时长数据化也是数值,要动先 [BLOCKED])。
- **红线预判**:[Claude 填;表现层单默认:零数值/零 schema/在线=离线不触]

## 3. 验收标准(§8.2 UI 加码全量适用)
1. targeted widget/visual-route 测试 + 批末全量绿。
2. **常规桌面视口 visual smoke:1280×720 + 1440×900 双档截图**,禁只用超高视口证「内容存在」。
3. 改交互组件(按钮/输入/焦点)须验 semantics / 键盘激活 / focus / mouse cursor
   (InkWell→GestureDetector 一类改动易丢桌面语义);未改则显式声明「交互组件未动」。
4. 高频路径零 debug 日志噪声(build() 内 debugPrint 随 rebuild 刷屏即打回)。

## 4-6. 恢复点 / 交付标准 / 冻结信号
- 恢复点文件 `docs/superpowers/plans/[日期]-[任务名].md`(§8.0 体例)。
- 交付四证据:生产接线证据(入口与消费方 file:line)/ targeted 命令+通过数 /
  红线影响声明 / 残留风险(未穷举视口、未目检态、多屏环境差异等)。
- 完工冻结:全 commit 树干净 + tip `[READY]`;方向拿不准 → `[BLOCKED]` 列拍板点。
- commit 中文动宾;截图不入库。
