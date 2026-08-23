#!/usr/bin/env bash
# 真机决策局启动脚本(2026-08-12)
#
# 配合 docs/spec/2026-08-12-playtest-decision-session.md 使用。
# 本脚本只负责「把东西推到人眼前」和「打印事实」,不自动修改任何文件、
# 不 push、不 delete、不 merge。所有落笔由人拍板后另行实施。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_PROCESS_NAME="wuxia_idle"
TAOHUA_ART_DIR="$HOME/Desktop/Projects/挂机武侠素材/桃花岛美术候选_20260807"
FLUTTER_LOG="/tmp/decision_session_flutter.log"

DRY_RUN=0
STEP=""

usage() {
  cat <<'USAGE'
真机决策局启动脚本(2026-08-12)

配合 docs/spec/2026-08-12-playtest-decision-session.md 使用。本脚本只负责
「把东西推到人眼前」和「打印事实」,不自动修改任何东西。

用法:
  tools/playtest/decision_session.sh             # 列出所有步骤
  tools/playtest/decision_session.sh <步号>       # 直接跳到某步
  tools/playtest/decision_session.sh --dry-run    # 打印每步会做什么,不真启动
  tools/playtest/decision_session.sh --dry-run <步号>

步号:
  1  A·一#17 桃花岛入口候选图(open 候选图 + 真机对照提示)
  2  A·一#19 资质 chip(视觉路由 lineage_character_detail)
  3  A·二#7  旧 3v3 立绘融合决策（路线 C 已退役）
  4  B·一#4  丹房强度(启游戏,玩丹房)
  5  B·一#5  残页集齐(启游戏,玩爬塔残页)
  6  B·一#6  高熟练度难度(启游戏,玩高熟练度)
  7  C·一#18 死链扫描器定位 ✅已拍板(2026-08-12,保留供追溯)
  8  C·P12   远端分支清理 ✅已拍板并执行(2026-08-12,保留供追溯)

环境自检:
  开头会检测 DEVELOPER_DIR。若被设置,flutter build macos 会报
  `xcrun: unable to find utility "xcodebuild"`(本仓踩过多次),脚本会
  unset 并提示。--dry-run 模式下仅提示不 unset。

注意:
  - A/B 组真跑时会启动 flutter app,看完后按回车关闭并继续。
  - 本脚本不改任何源码、数值、美术、yaml;不 push/delete/merge。
  - 真机实跑是用户那一局的事;交付方只用 --dry-run 验证。
USAGE
}

# ── 参数解析 ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) STEP="$1"; shift ;;
  esac
done

# ── 环境自检:DEVELOPER_DIR ───────────────────────────────────────────
# DEVELOPER_DIR 被设置会导致 flutter build macos 报
# `xcrun: unable to find utility "xcodebuild"`(memory:
# feedback_developer_dir_breaks_flutter_macos_build)。
check_environment() {
  if [[ -n "${DEVELOPER_DIR:-}" ]]; then
    echo "⚠ 检测到 DEVELOPER_DIR=$DEVELOPER_DIR"
    echo "  这会导致 flutter build macos 报 xcrun: unable to find utility \"xcodebuild\"。"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "  [dry-run] 仅提示,不 unset。真跑时脚本会 unset DEVELOPER_DIR。"
    else
      unset DEVELOPER_DIR
      echo "  已 unset DEVELOPER_DIR。"
    fi
  else
    echo "✓ DEVELOPER_DIR 未设置,环境正常。"
  fi
  echo
}

# ── 关闭 app 进程(SIGTERM→5s→SIGKILL,参考 visual_capture.sh) ──────
stop_app() {
  local pid="${1:-}"
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null || true
    local elapsed=0
    while kill -0 "$pid" 2>/dev/null && [[ "$elapsed" -lt 5 ]]; do
      sleep 1; elapsed=$((elapsed + 1))
    done
    kill -9 "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  # 清理同名残留 app 进程(TERM 免疫僵尸)
  pkill -x "$APP_PROCESS_NAME" 2>/dev/null || true
  elapsed=0
  while pgrep -x "$APP_PROCESS_NAME" >/dev/null 2>&1 && [[ "$elapsed" -lt 3 ]]; do
    sleep 1; elapsed=$((elapsed + 1))
  done
  pkill -9 -x "$APP_PROCESS_NAME" 2>/dev/null || true
}

# ── 启动视觉路由(flutter run 后台,等回车后关) ─────────────────────
launch_route() {
  local route="$1"
  local title="$2"
  echo "── 视觉路由:$title ──"
  echo "路由 id: $route"
  echo
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] 将执行:"
    echo "  flutter run -d macos --dart-define=VISUAL_ROUTE=$route"
    echo "  (后台运行,等用户回车后 stop_app)"
    echo
    return
  fi
  echo "启动中(log: $FLUTTER_LOG),首次 build 可能需要几分钟,请等待窗口出现..."
  flutter run -d macos --dart-define=VISUAL_ROUTE="$route" \
    >"$FLUTTER_LOG" 2>&1 &
  local pid=$!
  echo "  flutter pid=$pid"
  echo
  echo ">>> 看完后按回车关闭 app 并继续..."
  read -r
  stop_app "$pid"
  echo "  app 已关闭。"
  echo
}

# ── 启动游戏(正常模式,无视觉路由) ─────────────────────────────────
launch_game() {
  local title="$1"
  echo "── 启动游戏:$title ──"
  echo
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] 将执行:"
    echo "  flutter run -d macos"
    echo "  (后台运行,等用户回车后 stop_app)"
    echo
    return
  fi
  echo "启动中(log: $FLUTTER_LOG)..."
  flutter run -d macos >"$FLUTTER_LOG" 2>&1 &
  local pid=$!
  echo "  flutter pid=$pid"
  echo
  echo ">>> 玩完后按回车关闭 app 并继续..."
  read -r
  stop_app "$pid"
  echo "  app 已关闭。"
  echo
}

# ── 打开图片 ─────────────────────────────────────────────────────────
open_image() {
  local path="$1"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] open \"$path\""
    return
  fi
  if [[ ! -f "$path" ]]; then
    echo "  ⚠ 文件不存在: $path"
    return
  fi
  open "$path"
  echo "  已打开: $(basename "$path")"
}

# ── 步骤 1:一#17 桃花岛入口候选图 ────────────────────────────────────
step1() {
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║ 步 1 · A 组 · 一#17 桃花岛入口背景图四张候选取舍            ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "要定什么:主菜单桃花岛入口按钮现复用城防图,挑哪张专属候选图、还是维持现状。"
  echo "选项:(a) 采用 v1 /(b) 采用 v2 /(c) 都不采用维持现役 /(d) 下次真机看完整场景再定"
  echo
  echo "── 打开候选图与复检对照图 ──"
  echo "目录: $TAOHUA_ART_DIR"
  echo
  if [[ ! -d "$TAOHUA_ART_DIR" ]]; then
    echo "⚠ 候选图目录不存在: $TAOHUA_ART_DIR"
    echo "  请确认素材夹已就位。"
  else
    echo "[C 类原图 1456×816]"
    open_image "$TAOHUA_ART_DIR/entry_taohua_island_v1.png"
    open_image "$TAOHUA_ART_DIR/entry_taohua_island_v2.png"
    echo
    echo "[D 类 2448 扩幅版]"
    open_image "$TAOHUA_ART_DIR/_entry_v1_scaled.png"
    open_image "$TAOHUA_ART_DIR/_entry_v2_scaled.png"
    echo
    echo "[复检对照图]"
    open_image "$TAOHUA_ART_DIR/_复检_三图对照_现役vs候选.png"
    open_image "$TAOHUA_ART_DIR/_复检_建筑区放大_查文字污染.png"
  fi
  echo
  echo "── 真机现役对照(可选) ──"
  echo "现役缩略图 = WuxiaUi.entryJianghu = assets/ui/mj/entry_city_defense_01.png"
  echo "  (lib/shared/theme/wuxia_tokens.dart:97,城防图被复用)"
  echo "入口按钮在 lib/features/main_menu/presentation/main_menu.dart:532"
  echo "需第二章通关存档才解锁可见(main_menu.dart:184-194)。"
  echo "仓里无专属视觉路由展示「主菜单桃花岛入口态」;taohua_island 路由进的是"
  echo "桃花岛主屏(背景 assets/maps/taohuaIsland.webp 地图,非入口图)。"
  echo
  echo "已有证据:构图同构、零文字污染、色调比现役略暗(160.6/159.8 vs 168.6)、"
  echo "墨占比更高(16.1% vs 12.3%);一项未独立验证(原生 1774×887 放大到 2448,"
  echo "频谱自校验失败,已如实标未验证)。"
  echo
  echo "拍完之后:若选 (a)/(b),另开实装任务(给桃花岛新立 token,替换"
  echo "main_menu.dart:532 的 entryJianghu;entryJianghu 被多入口共用不能直接改)。"
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "完成。下一步:tools/playtest/decision_session.sh 2"
}

# ── 步骤 2:一#19 资质 chip ──────────────────────────────────────────
step2() {
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║ 步 2 · A 组 · 一#19(实为 P11 视觉档位化)资质 chip 视觉表达 ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "编号说明:本项 = BACKLOG 一#19「资质视觉档位化」,与 P11 滚动池条目同源,"
  echo "源出 BACKLOG 一#15/#16(已拍,chip 已改显出生点数)。视觉档位化仍未做,"
  echo "代码注释 lineage_character_detail_screen.dart:303-304 明文「待视觉终拍」。"
  echo
  echo "要定什么:资质 chip 六档(庸才/寻常/标准/资优/天才/绝世)要不要做视觉档位化。"
  echo "选项:(a) 色阶 /(b) 印章 /(c) 边框 /(d) 底纹 /(e) 维持现状"
  echo
  launch_route "lineage_character_detail" "门派谱角色详情屏·祖师态(资质四项 chip)"
  echo "代码:lib/features/character_panel/presentation/lineage_character_detail_screen.dart:303-310"
  echo "  资质 chip 沿用 _AttrChip 同款灰底文字(:319-331),六档仅靠档名+出生点数区分。"
  echo "六档定义:lib/core/domain/enums.dart:150-157(庸才16-17/寻常18-19/标准20/资优21-22/天才23/绝世24)"
  echo
  echo "已有证据:代码自注「视觉表现为临时版,待视觉终拍」;P11 已拍 #15/#16,"
  echo "视觉档位化明确「并入试玩局再定」。"
  echo
  echo "拍完之后:若选 (a)-(d),另开实装任务(改 _AttrChip 或新建 chip widget,"
  echo "不触数值,纯展示层);若选 (e) 销账。"
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "完成。下一步:tools/playtest/decision_session.sh 3"
}

# ── 步骤 3:二#7 立绘融合 ────────────────────────────────────────────
step3() {
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║ 步 3 · A 组 · 二#7 旧 3v3 立绘融合决策（已退役）            ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "该决策依赖的旧 Battle UI V2 路由、融合组件与测试已随路线 C 原子删除。"
  echo "历史证据保留在 docs/audit；当前 Phase 0A 视觉验收请使用"
  echo "phase0a_battle_playable / phase0a_battle_boss_mechanics。"
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "完成。下一步:tools/playtest/decision_session.sh 4"
}

# ── 步骤 4:一#4 丹房强度 ────────────────────────────────────────────
step4() {
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║ 步 4 · B 组 · 一#4 丹房强度(已定不动,复核)               ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "要定什么:桃花岛丹房产出强度是否合适。已定「不动」,待真人试玩复核。"
  echo "选项:(a) 维持不动(2026-07-19 1A 批决议)/(b) 调整"
  echo
  echo "玩哪段:主菜单 → 桃花岛 → 丹房建筑(danFang)→ 看产出队列与产出物。"
  echo "需第二章通关解锁桃花岛。约 10 分钟观察 1-2 轮产出。"
  echo
  launch_game "丹房试玩"
  echo "已有证据:BACKLOG 一#4 原文仅一行「已定不动,待真人试玩数据复核"
  echo "(2026-07-19 1A 批决议)」;数值在 data/numbers.yaml taohua_island 段。"
  echo
  echo "拍完之后:若选 (a) 销账;若选 (b) 改 numbers.yaml taohua_island 段,守数值红线。"
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "完成。下一步:tools/playtest/decision_session.sh 5"
}

# ── 步骤 5:一#5 残页集齐数量 ────────────────────────────────────────
step5() {
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║ 步 5 · B 组 · 一#5 残页集齐数量(默认 5)                   ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "要定什么:残页集齐多少片解锁一招。当前默认 5 片。"
  echo "选项:(a) 维持默认(真解1/残页5)/(b) 调整阈值/(c) 调整掉率"
  echo
  echo "玩哪段:爬塔 Boss 层(5/10/15/20/25/30)+ 章末重打关掉残页,集齐 5 片解锁。"
  echo "判断「集齐节奏太快/太慢/合适」。"
  echo
  launch_game "残页集齐试玩"
  echo "已有证据(2026-08-12 现查):"
  echo "  fragmentThreshold = 5(lib/data/numbers_config.dart:2893)"
  echo "  towerFragmentDropProb = 0.20(:2894)"
  echo "  P1a spec §16#4 拍板(docs/spec/2026-06-09-playability-p1a-cultivation-core-design.md:69)"
  echo "  测试契约:test/data/numbers_config_skill_unlock_test.dart:11 断言 ==5"
  echo
  echo "拍完之后:若选 (b)/(c) 改 numbers.yaml skill_unlock 段,同步测试。"
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "完成。下一步:tools/playtest/decision_session.sh 6"
}

# ── 步骤 6:一#6 高熟练度难度 ────────────────────────────────────────
step6() {
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║ 步 6 · B 组 · 一#6 高熟练度难度微调候选                     ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "要定什么:当前 105 关主线在高熟练度态的难度曲线是否需微调。"
  echo "选项:(a) 维持现状/(b) 微调具体关卡"
  echo
  echo "玩哪段:从当前主线选择代表关,分别用低/高熟练起手画像试玩。"
  echo "历史旧核曾重点标记 01_05 / 05_05；当时胜率不继承为当前结论。"
  echo
  launch_game "高熟练度试玩"
  echo "已有证据:"
  echo "  历史旧核证据(仅供追溯,不是当前常驻门禁):"
  echo "    30 mainline × floor/ceiling × uses{0,800} × 25 seed,mean +8.3pt"
  echo "  当前常驻测:test/tools/phase0a_full_content_balance_diagnostic_test.dart"
  echo "    Ch1 起手画像 × 154 生产内容 × 5 熟练阶段 × 3 流派 = 2310 次真实路径；"
  echo "    不继承旧 floor/ceiling +8.3pt 结论,最终仍以本步真人试玩判断。"
  echo
  echo "拍完之后:若选 (b) 另立调优任务,改对应关卡 YAML 前先跑当前 Phase 0A 证据链。"
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "完成。下一步:tools/playtest/decision_session.sh 7"
}

# ── 步骤 7:一#18 死链扫描器定位 ────────────────────────────────────
step7() {
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║ 步 7 · C 组 · 一#18 死链扫描器「可试用·非终审」定位是否升级 ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "✅ 【已于 2026-08-12 拍板并执行,本步无需再做,保留仅供追溯】"
  echo "   用户选:升级为可引用事实源。tools/README.md 定位句已改,"
  echo "   别处引用扫描器输出不再需要加免责标注。BACKLOG 一#18 已销账。"
  echo "   下方为拍板当时的备料,原样保留。"
  echo
  echo "要定什么:tools/README.md 里 doc_link_scan.py 的定位要不要从「可试用·非终审"
  echo "事实源」升级为终审事实源。"
  echo "选项:(a) 升级为终审事实源 /(b) 维持「可试用·非终审事实源」"
  echo
  echo "── 前提核验:P10(死链扫描归档类单列)合入状态 ──"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] 将执行: git log --oneline -1 68692a90"
  else
    if git -C "$REPO_ROOT" log --oneline -1 68692a90 >/dev/null 2>&1; then
      local commit_line
      commit_line="$(git -C "$REPO_ROOT" log --oneline -1 68692a90)"
      echo "✓ P10 已合入 origin/main:$commit_line"
      echo "  BACKLOG 一#18 原文写「建议先做 P10 再拍此项」→ 前提已满足。"
    else
      echo "⚠ 未找到 P10 commit 68692a90,前提可能未满足。"
    fi
  fi
  echo
  echo "── 当前 tools/README.md 里 doc_link_scan.py 的定位(摘录)──"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] 将执行: grep doc_link_scan $REPO_ROOT/tools/README.md"
  else
    grep "doc_link_scan" "$REPO_ROOT/tools/README.md" | head -3 || echo "  (未匹配到 doc_link_scan 行)"
  fi
  echo
  echo "已有证据(摘自 BACKLOG 一#18 + tools/README.md P10 后现状):"
  echo "  支持升级:P6 标注验证 precision 95.0%/recall 100%;两处假阳已修(ab38b43c);"
  echo "  工作树漂移归零(refs=7442 alive=5929 dead=908 ignored=605)。"
  echo "  P10 后 dead 已收敛:tools/README.md 现登记 dead 从 908 降至 322"
  echo "  (归档类 585 条单列,ARCHIVAL_DIRS 现仅 docs/handoff)。"
  echo "  原反对理由(handoff 噪声约 600 条)已被 P10 处理;dead 322 是否可直接当"
  echo "  修复清单仍待判断(未逐条核)。"
  echo
  echo "拍完之后:若选 (a) 改 tools/README.md 那行定位描述;若选 (b) 销账。"
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "完成。下一步:tools/playtest/decision_session.sh 8"
}

# ── 步骤 8:P12 远端备份分支清理 ────────────────────────────────────
step8() {
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║ 步 8 · C 组 · P12 远端 4 个遗留备份分支清理                 ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "✅ 【已于 2026-08-12 拍板并执行,本步无需再做,保留仅供追溯】"
  echo "   用户选:删两个零风险的,留两个。已 is-ancestor 正面验证后删除"
  echo "   codex/taohua-art-0807 与 qoder/p4-audit-scripts-0808;"
  echo "   保留 pi/p6-link-label-0808 与 worktree-claude-rarity。池 P12 已销。"
  echo "   下方现算逻辑保留(现在只会列出剩余两个分支)。"
  echo
  echo "要定什么:远端 4 个遗留备份分支要不要删。"
  echo
  echo "── 现算每个分支 origin/main..origin/<b> 独有 commit 数 ──"
  local branches=("codex/taohua-art-0807" "qoder/p4-audit-scripts-0808" "pi/p6-link-label-0808" "worktree-claude-rarity")
  for b in "${branches[@]}"; do
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[dry-run] git rev-list --count origin/main..origin/$b"
      continue
    fi
    local n
    n="$(git -C "$REPO_ROOT" rev-list --count "origin/main..origin/$b" 2>&1 || echo "ref 不存在")"
    echo "  origin/$b: $n 独有 commit"
  done
  echo
  echo "选项(逐分支 删/留):"
  echo "  codex/taohua-art-0807    (0 独有 = git 可断言已包含,删除零风险)"
  echo "  qoder/p4-audit-scripts-0808 (0 独有 = 同上)"
  echo "  pi/p6-link-label-0808    (2 独有 = rebase/cherry-pick 前旧 SHA,内容在 main 但 git 证明不了)"
  echo "  worktree-claude-rarity   (3 独有 = 同上)"
  echo
  echo "已有证据:上表为 2026-08-12 现算(git rev-list --count origin/main..origin/<b>),"
  echo "与 docs/dispatch/pool/README.md P12 登记数 0/0/2/3 一致。"
  echo
  echo "拍完之后:若决定删,另开任务执行 git push origin --delete <分支名>(本脚本不执行)。"
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "全部 8 步完成。"
}

# ── 列出所有步骤 ────────────────────────────────────────────────────
list_steps() {
  echo "真机决策局(2026-08-12)· 共 8 步 · 预计 66 分钟"
  echo "清单详见:docs/spec/2026-08-12-playtest-decision-session.md"
  echo
  echo "  1  A·一#17 桃花岛入口候选图(15min)"
  echo "  2  A·一#19 资质 chip(5min)"
  echo "  3  A·二#7  立绘融合(5min)"
  echo "  4  B·一#4  丹房强度(10min)"
  echo "  5  B·一#5  残页集齐(10min)"
  echo "  6  B·一#6  高熟练度难度(15min)"
  echo "  7  C·一#18 死链扫描器定位 ✅已拍板(保留供追溯)"
  echo "  8  C·P12   远端分支清理 ✅已拍板并执行(保留供追溯)"
  echo
  echo "用法:"
  echo "  tools/playtest/decision_session.sh <步号>       # 跳到某步"
  echo "  tools/playtest/decision_session.sh --dry-run    # 打印每步会做什么"
  echo "  tools/playtest/decision_session.sh --dry-run <步号>"
  echo
  echo "最少必做子集(约 45min):A 组全(1-3)+ C 组全(7-8)+ B 组选一(5 或 6)。"
}

# ── 主逻辑 ──────────────────────────────────────────────────────────
main() {
  check_environment

  if [[ -z "$STEP" ]]; then
    list_steps
    exit 0
  fi

  case "$STEP" in
    1) step1 ;;
    2) step2 ;;
    3) step3 ;;
    4) step4 ;;
    5) step5 ;;
    6) step6 ;;
    7) step7 ;;
    8) step8 ;;
    *)
      echo "未知步号: $STEP(有效范围 1-8)" >&2
      usage
      exit 2
      ;;
  esac
}

main
