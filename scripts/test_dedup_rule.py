#!/usr/bin/env python3
"""check_dedup.py の重複除去規則が、iOS(SupabaseService.deduplicatedSchedules)と同じであることを検証する。

共通のテストデータ 20_Source/BusNow/BusNowTests/Fixtures/dedup_cases.json を読み、
check_dedup.dedup の結果を期待値(残る便の platform を順に並べたもの)と照合する。
同じデータを iOS 側の BusNowTests/DedupRuleTests.swift も使う。

使い方(リポジトリのルートで):
  python3 scripts/test_dedup_rule.py
全ケース一致で終了コード0、1件でも違えば1。
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from check_dedup import dedup  # noqa: E402

FIXTURE = os.path.join(HERE, "..", "20_Source", "BusNow", "BusNowTests", "Fixtures", "dedup_cases.json")


def main():
    cases = json.load(open(FIXTURE, encoding="utf-8"))["cases"]
    failed = 0
    for c in cases:
        got = [t["platform"] for t in dedup(c["input"])]
        if got != c["expected"]:
            failed += 1
            print(f"FAIL: {c['name']}: expected {c['expected']}, got {got}")
    print(f"{len(cases) - failed}/{len(cases)} cases passed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
