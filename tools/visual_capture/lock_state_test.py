import unittest

import lock_state


# 派单方 2026-08-12 实测的未锁态真实片段:IOConsoleUsers 字典里
# CGSSessionScreenIsLocked 键整个不存在(未锁不是 =No,是键不存在)。
UNLOCKED_REAL = (
    '  "IOConsoleUsers" = ({"kCGSSessionOnConsoleKey"=Yes,'
    '"kSCSecuritySessionID"=100002,"kCGSSessionUserIDKey"=502})\n'
)

# 已锁态:在同一个 IOConsoleUsers 字典里加入 "CGSSessionScreenIsLocked"=Yes。
LOCKED_REAL = (
    '  "IOConsoleUsers" = ({"CGSSessionScreenIsLocked"=Yes,'
    '"kCGSSessionOnConsoleKey"=Yes,"kSCSecuritySessionID"=100002,'
    '"kCGSSessionUserIDKey"=502})\n'
)


class JudgeLockStateLockedTest(unittest.TestCase):
    """类别一:含 CGSSessionScreenIsLocked -> 判已锁。"""

    def test_locked_when_key_present(self):
        self.assertEqual(lock_state.judge_lock_state(LOCKED_REAL), lock_state.LOCKED)


class JudgeLockStateUnlockedTest(unittest.TestCase):
    """类别二:不含该键(正常未锁真实形态)-> 判未锁。"""

    def test_unlocked_when_key_absent(self):
        self.assertEqual(
            lock_state.judge_lock_state(UNLOCKED_REAL), lock_state.UNLOCKED
        )


class JudgeLockStateUnknownTest(unittest.TestCase):
    """类别三:ioreg 失败 / 空输出 / 异常 -> 判未知,绝不错报未锁。"""

    def test_unknown_on_empty_output(self):
        self.assertEqual(lock_state.judge_lock_state(""), lock_state.UNKNOWN)

    def test_unknown_on_none_output(self):
        self.assertEqual(lock_state.judge_lock_state(None), lock_state.UNKNOWN)

    def test_unknown_when_ioreg_failed_even_if_text_present(self):
        # ioreg 命令本身失败时,即使文本里有键也不得采信。
        self.assertEqual(
            lock_state.judge_lock_state(LOCKED_REAL, ioreg_ok=False),
            lock_state.UNKNOWN,
        )

    def test_unknown_when_output_lacks_console_users(self):
        # 非空但无 IOConsoleUsers 结构:异常输出,宁可 unknown 不错报 unlocked。
        self.assertEqual(
            lock_state.judge_lock_state("ioreg: unexpected garbage"),
            lock_state.UNKNOWN,
        )


if __name__ == "__main__":
    unittest.main()
