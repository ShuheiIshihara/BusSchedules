#!/usr/bin/env python3
"""本番DB(A)と検証DB(B)に同じ条件でRPCを呼び、重複除去前の生データを比較する。

接続先は環境変数で切り替える(鍵はコード・リポジトリに入れない):
  SUPABASE_A_URL / SUPABASE_A_KEY   例: 本番  https://xxxx.supabase.co
  SUPABASE_B_URL / SUPABASE_B_KEY   例: 検証
RPC関数名はDBごとに異なる(環境変数で上書き可):
  SUPABASE_A_RPC  既定 get_phase1_bus_schedule_3(本番)
  SUPABASE_B_RPC  既定 get_bus_schedule_2026(検証)
引数名は両DBとも departure_station / arrival_station / target_date を想定(未確認)。

使い方:
  python3 scripts/compare_dbs.py <区間CSV> --date 2026-10-05 [--sample N] [--seed S] [--out-dir reports/compare]
区間CSV: h_departure_station,h_arrival_station 列を持つCSV(check_dedup.py の入力CSVでも可)。
オフライン比較(取得済みCSV同士): --offline A.csv B.csv
出力: <out-dir>/raw_A.csv, raw_B.csv(h_departure_station,h_arrival_station,h_result_json)と compare_report.md
比較は重複除去前の生データで、同一内容の行は件数(多重集合)まで含めて照合する。
"""
import argparse, collections, csv, datetime, json, os, random, sys, time, urllib.request, urllib.error

csv.field_size_limit(10**9)
DEFAULT_RPC = {"A": "get_phase1_bus_schedule_3", "B": "get_bus_schedule_2026"}
SEL = "\U000e0100"


def search_form(name):
    # アプリの normalizedForSearch と同じ: DBでセレクタ付きの「辻」に、無ければ付与
    out, i = [], 0
    while i < len(name):
        out.append(name[i])
        if name[i] == "辻" and name[i + 1:i + 2] != SEL:
            out.append(SEL)
        i += 1
    return "".join(out)


def call_rpc(url, key, rpc, dep, arr, date, retries=3):
    req = urllib.request.Request(
        f"{url.rstrip('/')}/rest/v1/rpc/{rpc}",
        data=json.dumps({"departure_station": search_form(dep), "arrival_station": search_form(arr),
                         "target_date": date}).encode(),
        headers={"apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "application/json"})
    for n in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.loads(r.read().decode() or "null") or []
        except (urllib.error.URLError, TimeoutError) as e:
            if n == retries - 1:
                raise RuntimeError(f"{dep}→{arr}: {e}")
            time.sleep(n + 1)


def load(path):
    return {(r["h_departure_station"], r["h_arrival_station"]): json.loads(r["h_result_json"] or "[]")
            for r in csv.DictReader(open(path, encoding="utf-8"))}


def save(path, data):
    with open(path, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["h_departure_station", "h_arrival_station", "h_result_json"])
        for (d, a), trips in data.items():
            w.writerow([d, a, json.dumps(trips, ensure_ascii=False, separators=(",", ":"))])


def canon(t):
    return json.dumps(t, ensure_ascii=False, sort_keys=True)


def diff(a, b):
    ca, cb = collections.Counter(map(canon, a)), collections.Counter(map(canon, b))
    return list((ca - cb).elements()), list((cb - ca).elements())


def report(a, b, header):
    keys = sorted(set(a) | set(b))
    rows, ndiff = [], 0
    for k in keys:
        if k not in a or k not in b:
            rows.append((k, "片方のみ取得", "", "", [], [])); ndiff += 1; continue
        only_a, only_b = diff(a[k], b[k])
        status = "一致" if not only_a and not only_b else "差分"
        ndiff += status == "差分"
        rows.append((k, status, len(a[k]), len(b[k]), only_a, only_b))
    lines = [f"# DB比較レポート ({datetime.date.today()})", "", *header, "",
             f"- 対象 {len(keys)} 区間 / 差分あり {ndiff} 区間(重複除去前の生データ、完全一致で照合)", "",
             "| 出発 | 到着 | 結果 | A件数 | B件数 | Aのみ | Bのみ |", "|---|---|---|--:|--:|--:|--:|"]
    for k, st, na, nb, oa, ob in rows:
        lines.append(f"| {k[0]} | {k[1]} | {st} | {na} | {nb} | {len(oa)} | {len(ob)} |")
    detail = [(k, oa, ob) for k, st, _, _, oa, ob in rows if oa or ob]
    if detail:
        lines += ["", "## 差分の例(各区間 最大3件)"]
        for k, oa, ob in detail:
            lines += ["", f"### {k[0]} → {k[1]}"]
            for label, l in (("Aのみ", oa), ("Bのみ", ob)):
                for t in map(json.loads, l[:3]):
                    lines.append(f"- {label}: {t['departureTime']} {t['routeName']} → {t['destination']} 到着{t.get('arrivalTime')} ホーム{t.get('platform')}")
    return "\n".join(lines) + "\n", ndiff


def main():
    p = argparse.ArgumentParser()
    p.add_argument("csv", nargs="?")
    p.add_argument("--date")
    p.add_argument("--sample", type=int)
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--out-dir", default="reports/compare")
    p.add_argument("--offline", nargs=2, metavar=("A_CSV", "B_CSV"))
    x = p.parse_args()
    os.makedirs(x.out_dir, exist_ok=True)

    if x.offline:
        a, b = load(x.offline[0]), load(x.offline[1])
        header = [f"- A: `{x.offline[0]}` / B: `{x.offline[1]}`(取得済みCSVの比較)"]
    else:
        if not x.csv or not x.date:
            p.error("区間CSVと --date が必要です")
        env = {k: os.environ.get(k, "") for k in ("SUPABASE_A_URL", "SUPABASE_A_KEY", "SUPABASE_B_URL", "SUPABASE_B_KEY")}
        missing = [k for k, v in env.items() if not v]
        if missing:
            sys.exit("環境変数が未設定: " + ", ".join(missing))
        pairs = list(dict.fromkeys((r["h_departure_station"], r["h_arrival_station"])
                                   for r in csv.DictReader(open(x.csv, encoding="utf-8"))))
        if x.sample and x.sample < len(pairs):
            pairs = random.Random(x.seed).sample(pairs, x.sample)
        rpc = {k: os.environ.get(f"SUPABASE_{k}_RPC") or DEFAULT_RPC[k] for k in "AB"}
        a, b = {}, {}
        for d, ar in pairs:
            a[(d, ar)] = call_rpc(env["SUPABASE_A_URL"], env["SUPABASE_A_KEY"], rpc["A"], d, ar, x.date)
            b[(d, ar)] = call_rpc(env["SUPABASE_B_URL"], env["SUPABASE_B_KEY"], rpc["B"], d, ar, x.date)
        save(os.path.join(x.out_dir, "raw_A.csv"), a)
        save(os.path.join(x.out_dir, "raw_B.csv"), b)
        header = [f"- 区間CSV: `{x.csv}` / date={x.date}" + (f" / sample={x.sample}, seed={x.seed}" if x.sample else ""),
                  f"- RPC: A=`{rpc['A']}` / B=`{rpc['B']}`", "- A・B の接続先URLは記録しない(環境変数から取得)"]
    text, n = report(a, b, header)
    open(os.path.join(x.out_dir, "compare_report.md"), "w", encoding="utf-8").write(text)
    print("\n".join(text.splitlines()[:6]))
    sys.exit(1 if n else 0)


main()
