#!/usr/bin/env python3
"""RPC結果CSV(h_departure_station,h_arrival_station,h_result_json)の重複便を検査する。

SupabaseService.deduplicatedSchedules と同じ規則:
(departureTime, routeName, destination) が同じ便は arrivalTime が最も早いものを残す。

使い方:
  python3 scripts/check_dedup.py <input.csv> [--sample N] [--seed S] [--out reports/dedup_report.md]
--sample 省略時は全件。指定時は重複あり/なしを半々で層別抽出する。
"""
import argparse, collections, csv, json, random, datetime

csv.field_size_limit(10**9)


def dedup(trips):
    best = {}
    for t in trips:
        k = (t["departureTime"], t["routeName"], t["destination"])
        if k not in best or (t.get("arrivalTime") or "99:99") < (best[k].get("arrivalTime") or "99:99"):
            best[k] = t
    return list(best.values())


def check(row):
    trips = json.loads(row["h_result_json"] or "[]")
    kept = dedup(trips)
    arr = row["h_arrival_station"]
    # 残した便が到着駅で終わり、到着駅を1回だけ含むか
    ok = all(t["busStops"] and t["busStops"][-1] == arr and t["busStops"].count(arr) == 1 for t in kept)
    kind = {t["serviceId"] for t in trips}
    return dict(dep=row["h_departure_station"], arr=arr, before=len(trips), after=len(kept),
                removed=len(trips) - len(kept), ok=ok, service="/".join(sorted(kind)))


def main():
    p = argparse.ArgumentParser()
    p.add_argument("csv")
    p.add_argument("--sample", type=int)
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--out", default="reports/dedup_report.md")
    a = p.parse_args()

    rows = list(csv.DictReader(open(a.csv, encoding="utf-8")))
    results = [check(r) for r in rows]
    if a.sample and a.sample < len(results):
        rnd = random.Random(a.seed)
        dup = [r for r in results if r["removed"]]
        non = [r for r in results if not r["removed"]]
        h = a.sample // 2
        results = rnd.sample(dup, min(h, len(dup))) + rnd.sample(non, min(a.sample - h, len(non)))

    lines = [f"# 重複除去チェック ({datetime.date.today()})", "",
             f"- 入力: `{a.csv}` 全{len(rows)}行 / 対象{len(results)}行" + (f" (sample={a.sample}, seed={a.seed})" if a.sample else ""),
             f"- 除去前 {sum(r['before'] for r in results)} 件 → 除去後 {sum(r['after'] for r in results)} 件",
             f"- 到着駅検証NG: {sum(not r['ok'] for r in results)} 行", "",
             "| 出発 | 到着 | 区分 | 前 | 後 | 除去 | 検証 |", "|---|---|---|--:|--:|--:|:-:|"]
    for r in sorted(results, key=lambda r: -r["removed"]):
        lines.append(f"| {r['dep']} | {r['arr']} | {r['service']} | {r['before']} | {r['after']} | {r['removed']} | {'OK' if r['ok'] else 'NG'} |")
    open(a.out, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("\n".join(lines[:6]))


main()
