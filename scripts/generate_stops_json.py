#!/usr/bin/env python3
# translations.txt（GTFS-JP 翻訳テーブル）から、バス停名のオートコンプリート用
# 静的リソース stops.json を生成する開発用スクリプト。
#
# 使い方（リポジトリルートで実行）:
#   python3 scripts/generate_stops_json.py
#
# 入力: 10_Document/05_多言語/translations.txt
# 出力: 20_Source/BusNow/BusNow/Resources/stops.json
#       20_Source/Web/public/data/stops.json
#
# 出力フォーマット:
#   [ { "name": "相川一丁目", "reading": "あいかわ１ちょうめ" }, ... ]
#   name    = 漢字バス停名（ja 行の translation）
#   reading = ひらがな読み（ja-Hrkt 行の translation。無い場合は null）

import csv
import json
import os

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUT_PATH = os.path.join(REPO_ROOT, "10_Document", "05_多言語", "translations.txt")
OUTPUT_PATHS = [
    os.path.join(REPO_ROOT, "20_Source", "BusNow", "BusNow", "Resources", "stops.json"),
    os.path.join(REPO_ROOT, "20_Source", "Web", "public", "data", "stops.json"),
]


def main():
    ja = {}      # field_value(漢字キー) -> 漢字バス停名
    hrkt = {}    # field_value(漢字キー) -> ひらがな読み

    # CR を含む改行・埋め込みカンマに対応するため csv モジュールで読む
    with open(INPUT_PATH, encoding="utf-8", newline="") as f:
        for row in csv.reader(f):
            if len(row) < 7 or row[0] != "stops" or row[1] != "stop_name":
                continue
            key = row[6]  # field_value = 漢字名（言語間の結合キー）
            if row[2] == "ja":
                ja[key] = row[3]
            elif row[2] == "ja-Hrkt":
                hrkt[key] = row[3]

    stops = [
        {"name": name, "reading": hrkt.get(key)}
        for key, name in sorted(ja.items(), key=lambda kv: kv[1])
    ]

    for output_path in OUTPUT_PATHS:
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(stops, f, ensure_ascii=False, indent=2)
        print(f"生成完了: {output_path}")

    print(f"バス停数: {len(stops)} 件（読みがな付き: {sum(1 for s in stops if s['reading'])} 件）")


if __name__ == "__main__":
    main()
