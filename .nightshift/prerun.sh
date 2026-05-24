#!/bin/bash
# Nightshift prerun · 项目类型特化预跑(worktree 创建后,claude 启动前)
#
# 解决问题:
#   - Flutter: *.g.dart gitignored,fresh worktree analyze 必爆(memory feedback_wuxia_pen_build_runner)
#   - Node: node_modules gitignored,fresh worktree 没装依赖
#   - Generic: 通常无 setup,直接跳过
#
# 由 dispatcher.sh run_prerun 调用,失败不阻塞 task(只 warn)。
# 在 worktree cwd 里跑,可访问项目所有文件。

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/nightshift.conf"

PRERUN_LOG="$SCRIPT_DIR/logs/prerun.log"
mkdir -p "$(dirname "$PRERUN_LOG")"
echo "=== prerun start $(date) cwd=$(pwd) type=$PROJECT_TYPE ===" >> "$PRERUN_LOG"

case "${PROJECT_TYPE:-generic}" in
  flutter)
    if [ ! -f "pubspec.yaml" ]; then
      echo "WARN: pubspec.yaml 不在 cwd($(pwd)),跳过 Flutter prerun" >> "$PRERUN_LOG"
      exit 0
    fi
    echo "[1/2] flutter pub get" >> "$PRERUN_LOG"
    if ! flutter pub get >> "$PRERUN_LOG" 2>&1; then
      echo "WARN: pub get failed, continuing" >> "$PRERUN_LOG"
      exit 0
    fi
    # 只有项目用 build_runner 才跑
    if grep -q "build_runner" pubspec.yaml 2>/dev/null; then
      echo "[2/2] dart run build_runner build --delete-conflicting-outputs" >> "$PRERUN_LOG"
      if ! dart run build_runner build --delete-conflicting-outputs >> "$PRERUN_LOG" 2>&1; then
        echo "WARN: build_runner failed, last 20 lines:" >> "$PRERUN_LOG"
        tail -20 "$PRERUN_LOG"
      fi
    else
      echo "[2/2] 项目无 build_runner 依赖,跳过 codegen" >> "$PRERUN_LOG"
    fi
    ;;

  node)
    if [ ! -f "package.json" ]; then
      echo "WARN: package.json 不在 cwd,跳过 Node prerun" >> "$PRERUN_LOG"
      exit 0
    fi
    # 优先 pnpm > yarn > npm
    if [ -f "pnpm-lock.yaml" ] && command -v pnpm >/dev/null 2>&1; then
      echo "[1/1] pnpm install --frozen-lockfile" >> "$PRERUN_LOG"
      pnpm install --frozen-lockfile >> "$PRERUN_LOG" 2>&1 || echo "WARN: pnpm install failed" >> "$PRERUN_LOG"
    elif [ -f "yarn.lock" ] && command -v yarn >/dev/null 2>&1; then
      echo "[1/1] yarn install --frozen-lockfile" >> "$PRERUN_LOG"
      yarn install --frozen-lockfile >> "$PRERUN_LOG" 2>&1 || echo "WARN: yarn install failed" >> "$PRERUN_LOG"
    elif [ -f "package-lock.json" ]; then
      echo "[1/1] npm ci" >> "$PRERUN_LOG"
      npm ci >> "$PRERUN_LOG" 2>&1 || echo "WARN: npm ci failed" >> "$PRERUN_LOG"
    else
      echo "[1/1] npm install (无 lock 文件,fallback)" >> "$PRERUN_LOG"
      npm install >> "$PRERUN_LOG" 2>&1 || echo "WARN: npm install failed" >> "$PRERUN_LOG"
    fi
    ;;

  generic|*)
    echo "Generic project, no prerun needed" >> "$PRERUN_LOG"
    ;;
esac

echo "=== prerun end $(date) ===" >> "$PRERUN_LOG"
exit 0
