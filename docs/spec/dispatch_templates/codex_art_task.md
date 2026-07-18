# Codex 美术任务派单模板

> 使用方式:Claude 派单时以本模板为底稿,填全部 `[ ]` 占位段;资产规格**必须 file 命令实测现有实物先例**,禁凭记忆;风格锚指向实物资产而非文字描述。交付给用户时全文展开。

---

# Codex 美术任务派单 · [日期] · [任务名]

## 0. 角色与边界
你是挂机武侠项目的美术/表现层执行端。本单产出图像资产入库[+清账 allowlist];
形象/构图自主发挥,但风格必须与现有资产一致。规划与终审在 Claude 端。

## 1. 环境准备
```bash
cd /Users/a10506/Desktop/Projects/挂机武侠
git worktree add .worktrees/[worktree名] -b codex/[分支名] main
cd .worktrees/[worktree名]
cp /Users/a10506/Desktop/Projects/挂机武侠/libisar.dylib .
export PUB_HOSTED_URL=https://pub.flutter-io.cn
flutter pub get && dart run build_runner build --delete-conflicting-outputs
flutter analyze --no-pub   # 0 issues 才开工
```
全量基线 [N] pass / 0 fail([日期]实测)。

## 2. 任务定义
- **目标**:[N 张图清单与入库路径;若有 allowlist 以其为权威清单,勿改名]
- **规格(按现有实物先例实测,勿自创)**:
  [逐类:尺寸/格式/透明度要求 + 参照实物文件名。已知先例:战斗立绘 1024×1536 PNG RGBA
  透明全身脚底站位;章封面与 narrative 背景 1456×816 webp-in-png(文件名 .png 内容 webp)]
- **形象权威源(先读再画)**:[stages.yaml 段/narratives 文件/GDD 章节指路]
- **风格红线**:水墨克制(青、墨、宣纸黄、绛红点缀),禁 Material 饱和色、禁网游风;
  与现有同目录资产并排看不突兀是硬标准。
- **体积**:出图入库后跑 `python3 tool/convert_assets_webp.py`(幂等,仅转有收益的),
  交付时报告新增总体积(立绘批 66 张 69.86MiB 是已知体积债,别重演)。
- **可碰文件域**:[assets 子目录清单 + allowlist 文件];仅当[锚点/映射]不适配时可调
  [表现层映射文件],改动列进交付说明。
- **禁区**:数值/schema/saveVersion/叙事文案 yaml/strings/GDD/PROGRESS/pubspec。

## 3. 验收标准
1. [守卫测试清单] 全绿 + 批末全量绿。
2. 视觉自验截图(1280×720 + 1440×900):[逐消费场景列 route/屏]。
3. [格式自检:如透明立绘全部 RGBA + 四角 alpha=0]。

## 4-6. 恢复点 / 交付标准 / 冻结信号
- 恢复点文件 `docs/superpowers/plans/[日期]-[任务名].md`(§8.0 体例)。
- 交付四证据:接线证据 / targeted 命令+通过数 / 红线影响声明 / 残留风险
  (未目检项、体积、风格存疑项)。
- 完工冻结:全 commit 树干净 + tip `[READY]`;形象方向拿不准 → `[BLOCKED]` 列拍板点。
- commit 中文动宾;截图不入库(放 /tmp 或 build/visual_acceptance/)。
