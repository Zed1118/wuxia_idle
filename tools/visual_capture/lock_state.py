#!/usr/bin/env python3
"""判定当前 macOS 登录会话是否处于锁屏态。

打印 locked / unlocked / unknown 之一并 exit 0。判定本身永不以非零码失败,
调用方(visual_capture.sh)读 stdout。

判据(派单方 2026-08-12 实测,见 docs/audit/visual_capture_lock_rect_failure_2026-08-12.md):
`ioreg -n Root -d1 -w0` 的 IOConsoleUsers 字典里是否含键 CGSSessionScreenIsLocked——
  - 含该键                        -> locked
  - 有 IOConsoleUsers 但无该键     -> unlocked(未锁时该键整个不存在,不是 =No,
                                      所以只能判键的有无,不能比值)
  - ioreg 失败 / 空输出 / 无该结构  -> unknown(绝不默认判未锁:错报未锁会把
                                      锁屏事故误导成别的问题)

用法:
  python3 lock_state.py                 # 真跑 ioreg(真机/生产链路用)
  python3 lock_state.py --ioreg-file F  # 从文件读 ioreg 输出(注入,测试用)

测试注入另支持环境变量 VC_TEST_LOCK_IOREG_FILE(语义同 --ioreg-file,供
visual_capture.sh 链路的行为测注入;flag 优先,生产链路从不设该变量)。
"""
import argparse
import os
import subprocess
import sys

LOCKED = "locked"
UNLOCKED = "unlocked"
UNKNOWN = "unknown"

LOCK_KEY = "CGSSessionScreenIsLocked"
CONSOLE_USERS_KEY = "IOConsoleUsers"


def judge_lock_state(ioreg_output, ioreg_ok=True):
    """纯函数:由 ioreg 输出文本判锁屏态。测试直接注入 ioreg_output。

    ioreg_output: `ioreg -n Root -d1 -w0` 的 stdout 文本(可为 None)。
    ioreg_ok:     ioreg 命令本身是否成功(exit 0)。False 一律判 unknown。
    返回 'locked' / 'unlocked' / 'unknown'。
    """
    if not ioreg_ok:
        return UNKNOWN
    if ioreg_output is None:
        return UNKNOWN
    if LOCK_KEY in ioreg_output:
        return LOCKED
    # 只有确认看到 IOConsoleUsers 结构、且其中无锁屏键,才敢判未锁;
    # 非空但无该结构属异常输出,宁可 unknown 也不错报 unlocked。
    if CONSOLE_USERS_KEY in ioreg_output:
        return UNLOCKED
    return UNKNOWN


def read_real_ioreg():
    """真跑 ioreg,返回 (stdout 文本, 是否成功)。"""
    try:
        proc = subprocess.run(
            ["ioreg", "-n", "Root", "-d1", "-w0"],
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        return None, False
    if proc.returncode != 0:
        return None, False
    return proc.stdout, True


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Judge whether the current macOS session is screen-locked."
    )
    parser.add_argument(
        "--ioreg-file",
        help="从文件读 ioreg 输出(注入)而非真跑 ioreg;读取失败按 ioreg 失败处理。",
    )
    args = parser.parse_args(argv)

    ioreg_file = args.ioreg_file or os.environ.get("VC_TEST_LOCK_IOREG_FILE")
    if ioreg_file:
        try:
            with open(ioreg_file, "r") as fh:
                output, ok = fh.read(), True
        except OSError:
            output, ok = None, False
    else:
        output, ok = read_real_ioreg()

    print(judge_lock_state(output, ok))
    return 0


if __name__ == "__main__":
    sys.exit(main())
