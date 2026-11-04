#!/usr/bin/env python3
"""本番DBとローカルDBの public スキーマ全テーブルのレコード数(count(*) の厳密値)を比較する。

本番へは読み取り専用トランザクション(default_transaction_read_only=on)で接続する。
接続先:
  本番     環境変数 PROD_DB_URL。未設定なら supabase/.temp/pooler-url(supabase link で作成)
           パスワードは psql が聞く(PGPASSWORD でも可)。値はログ・レポートに出さない
  ローカル 環境変数 LOCAL_DB_URL。既定 postgresql://postgres:postgres@127.0.0.1:54322/postgres

使い方(リポジトリのルートで):
  python3 scripts/compare_row_counts.py [--out reports/row_counts_report.md]
出力: レポート(Markdown)。件数が1つでも違えば終了コード1。
"""
import argparse, datetime, os, subprocess, sys

LOCAL_DEFAULT = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
POOLER_FILE = "supabase/.temp/pooler-url"
# テーブルごとに count(*) を実行する(統計値の推定件数ではなく厳密値)
COUNT_SQL = """
select table_name,
       (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', table_schema, table_name), false, true, '')))[1]::text
from information_schema.tables
where table_schema = 'public' and table_type = 'BASE TABLE'
order by table_name;
"""


def counts(url):
    env = {**os.environ, "PGOPTIONS": "-c default_transaction_read_only=on"}
    r = subprocess.run(["psql", url, "-X", "-A", "-t", "-F", "\t", "-v", "ON_ERROR_STOP=1", "-c", COUNT_SQL],
                       env=env, stdout=subprocess.PIPE, text=True)
    if r.returncode:
        sys.exit("psql の実行に失敗しました")
    return {name: int(n) for name, n in (line.split("\t") for line in r.stdout.splitlines() if line)}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--out", default="reports/row_counts_report.md")
    x = p.parse_args()

    prod_url = os.environ.get("PROD_DB_URL")
    if not prod_url and os.path.isfile(POOLER_FILE):
        prod_url = open(POOLER_FILE, encoding="utf-8").read().strip()
    if not prod_url:
        sys.exit(f"PROD_DB_URL を設定するか、supabase link で {POOLER_FILE} を作成してください")
    local_url = os.environ.get("LOCAL_DB_URL", LOCAL_DEFAULT)

    print("本番DBの件数を取得中…")
    prod = counts(prod_url)
    print("ローカルDBの件数を取得中…")
    local = counts(local_url)

    rows, ndiff = [], 0
    for t in sorted(set(prod) | set(local)):
        a, b = prod.get(t), local.get(t)
        ok = a == b
        ndiff += not ok
        rows.append(f"| {t} | {'-' if a is None else a} | {'-' if b is None else b} | "
                    f"{'一致' if ok else '不一致'} | {'' if a is None or b is None else b - a} |")
    text = "\n".join([
        f"# レコード数比較レポート ({datetime.datetime.now():%Y-%m-%d %H:%M})", "",
        f"- 対象 {len(rows)} テーブル(public スキーマ) / 不一致 {ndiff} テーブル",
        "- 本番・ローカルの接続先URLは記録しない", "",
        "| テーブル | 本番 | ローカル | 結果 | 差(ローカル-本番) |", "|---|--:|--:|---|--:|", *rows]) + "\n"
    os.makedirs(os.path.dirname(x.out) or ".", exist_ok=True)
    open(x.out, "w", encoding="utf-8").write(text)
    print(text)
    sys.exit(1 if ndiff else 0)


main()
