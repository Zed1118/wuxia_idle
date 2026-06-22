# DeepSeek 派单 · narrative schema 对齐（P1 #1 清账）

- **日期**：2026-05-12
- **派单方**：Mac + Opus 4.7
- **执行方**：Pen + Windows DeepSeek（F:\Projects\wuxia_idle）
- **关联挂账**：PROGRESS.md #27（方案 B：改 stages.yaml + 通知 DeepSeek 拆文件）
- **关联审计**：docs/audit/yaml_integrity_2026-05-12.md §2.1 / §3.1

## 背景

Mac 端 `NarrativeLoader` 期望扁平路径 + `paragraphs[]` schema，
DeepSeek 现已写 `data/narratives/stages/` 子目录 + `opening` / `post_victory` 双段单文件，
导致主线/爬塔剧情在运行时被代码侧识别为「[剧情待补]」placeholder，
即使你们已经写好了文案玩家也看不到。

外部审查（2026-05-12）确认此 bug，Mac 端与用户对齐方案 B：
DeepSeek 端拆文件 + 改 schema，Mac 端改 stages.yaml 引用新 id。
`chapters/` 和 `techniques/` 代码侧暂未引用，此次不动，留给后续。

---

## DeepSeek 端 Prompt（Pen 直接复制粘贴给他的 Claude Code 会话）

```
项目：wuxia_idle（F:\Projects\wuxia_idle）

# 任务：narrative schema 对齐（P1 #1 清账，方案 B）

## 背景

Mac 端 NarrativeLoader 期望扁平路径 + paragraphs[] schema，
你们写的 data/narratives/stages/ 用了子目录 + opening/post_victory 双段单文件，
导致主线/爬塔剧情在运行时被代码侧识别为「[剧情待补]」placeholder，
即使你们已经写好了文案玩家也看不到。

外部审查（2026-05-12）确认了这个 bug，Mac 端与用户对齐方案 B：
你们这边拆文件 + 改 schema，Mac 端我那边改 stages.yaml 引用新 id。
chapters/ 和 techniques/ 代码侧暂未引用，这次不动，留给后续。

## 你的工作范围（只动 stages/）

只改 data/narratives/stages/ 目录下的 15 个文件：
stage_01_01.yaml ~ stage_01_05.yaml
stage_02_01.yaml ~ stage_02_05.yaml
stage_03_01.yaml ~ stage_03_05.yaml

不要动：
- data/narratives/chapters/
- data/narratives/techniques/
- data/narratives/codex/
- data/lore/
- data/events/
- 任何 Dart / 根目录 yaml

## 拆分规则

每个 stage_NN_NN.yaml 当前形如：

  id: stage_01_01
  title: 山门之外
  opening: |
    A 段文字…
  post_victory: |
    B 段文字…

请拆成两个文件：

文件 1：stage_NN_NN_opening.yaml

  id: stage_NN_NN_opening
  title: 山门之外 · 启
  paragraphs:
    - A 段第一句/第一自然段
    - A 段第二自然段
    - A 段第三自然段
    （按现有 | 段落里的换行分句，每行/每自然段一条数组项；
     避免一整段塞进单个 paragraphs 元素，UI 渲染要按条分页显示）

文件 2：stage_NN_NN_victory.yaml

  id: stage_NN_NN_victory
  title: 山门之外 · 终
  paragraphs:
    - B 段第一自然段
    - B 段第二自然段
    …

关键约束：
1. id 字段必须等于文件名（不含 .yaml），Mac 端 loader 会做 fail-fast 校验
2. paragraphs 必须是 list，至少 1 条；不允许空列表
3. title 字段可空（写「key: null」或省略），但建议都填，UI 用作章节标题
4. 不允许残留 opening / post_victory 字段名 —— 全部走 paragraphs
5. 拆完后删除原 stage_NN_NN.yaml（15 个原文件 → 30 个新文件）

## title 后缀约定

为了 UI 区分战前/战后，建议 title 加后缀：
- _opening 文件 title 加「· 启」或「· 上」
- _victory 文件 title 加「· 终」或「· 下」
任选一套但全 15 关统一。

## paragraphs 切分原则

- 不要机械按 \n 切，要按语义段落
- 一条 paragraphs 元素对应 UI 一屏文字（玩家一次性读完的量），
  大约 30-80 字一条，太长强行拆开
- 保持现有文案的节奏感 —— 你们的写法本来就是「短句空行+留白」，
  那种空行就是天然的切分点

## 同步更新 IDS_REGISTRY.md

在 IDS_REGISTRY.md 的 stage narrative 区块：
- 删除 15 条 stage_NN_NN 旧 id
- 添加 30 条 stage_NN_NN_opening / stage_NN_NN_victory 新 id
- 顺手把「自报 143 个内容 ID」的总数修正为实际值（之前挂账 #4 就有这条）

## 交付与同步点

完成后：
1. git diff --stat 确认改动只在 data/narratives/stages/ + IDS_REGISTRY.md
2. 提交一个 commit：
   docs(narrative): stages 拆分 _opening/_victory + paragraphs[] schema 对齐
3. push 到 main，告诉用户 / Mac 端「DeepSeek 端 P1 #1 拆分完成，可继续」
4. Mac 端会做：
   - stages.yaml 关卡数从 6 扩到 15
   - stages.yaml 的 narrativeOpeningId / narrativeVictoryId 改成
     stage_NN_NN_opening / stage_NN_NN_victory
   - 加 NarrativeLoader 子目录扫描（data/narratives/stages/<id>.yaml）
   - 加防回归测试
   - 清开发态存档里 mainline_test_* MainlineProgress 数据

## 不要做的事

- 不要顺手改 chapters/ 或 techniques/ 的文件结构
- 不要给 paragraphs 加额外字段（type / speaker / effect 等），这次只做 schema 对齐
- 不要改文案内容，仅切分；写错了字也保留原状（Mac 端不审稿）
- 不要动 stages.yaml（Mac 端的领地）
- 拿不准的切分边界（哪一句该归 opening 还是 post_victory）保持现有归属，
  不重新设计叙事节奏
```

---

## Mac 端接手清单（等 Pen push 后）

| # | 工作 | 备注 |
|---|---|---|
| 1 | `stages.yaml` 6 → 15 关扩容 | 学徒/三流/二流梯度续写到第 3 章 |
| 2 | `stages.yaml` narrativeOpeningId/VictoryId 改为 `stage_NN_NN_opening`/`_victory` | id 全套迁移 |
| 3 | `NarrativeLoader` 加子目录扫描 `data/narratives/stages/<id>.yaml` | 兼容根目录扁平路径，子目录优先 |
| 4 | 新增 narrative loader test 覆盖两条路径 | 扁平 + stages/ 子目录 |
| 5 | 清开发态 Isar 存档 mainline_test_* MainlineProgress 数据 | 开发态直接清 wuxia_save_slot1.isar |
| 6 | 销账 #27 | PROGRESS.md 更新 |

预计工时：~半天，等 Pen 拆完单独一个 commit/PR。
