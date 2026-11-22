---
name: regenerate-stops-json
description: GTFS-JP の翻訳テーブルから、iOS と Web のバス停名候補データ(stops.json)を再生成して内容を確認する。「stops.json」「バス停データ再生成」「停留所名の更新」と言われたときに使う。
---

# Regenerate stops.json

`scripts/generate_stops_json.py` builds the stop-name list used for autocomplete (`StopNameRepository` on iOS) from the GTFS-JP translations table.

- Input: `10_Document/05_多言語/translations.txt` (rows with `stops,stop_name`; `ja` = kanji name, `ja-Hrkt` = hiragana reading)
- Outputs (both written every run):
  - `20_Source/BusNow/BusNow/Resources/stops.json` (iOS)
  - `20_Source/Web/public/data/stops.json` (Web — on hold, but keep it in sync)
- Format: `[{"name": "相川一丁目", "reading": "あいかわ１ちょうめ"}, ...]`, sorted by name; `reading` is `null` when missing

## Steps

1. If the GTFS-JP data was updated, confirm `translations.txt` was replaced with the new release's file (ask the developer which release).
2. Run from the repo root:
   ```bash
   python3 scripts/generate_stops_json.py
   ```
   It prints each output path and `バス停数: N 件（読みがな付き: M 件）`.
3. Sanity-check:
   ```bash
   python3 -c "import json,sys; a=json.load(open('20_Source/BusNow/BusNow/Resources/stops.json')); b=json.load(open('20_Source/Web/public/data/stops.json')); print(len(a), a==b, sum(1 for s in a if not s['reading']))"
   git diff --stat -- 20_Source/BusNow/BusNow/Resources/stops.json 20_Source/Web/public/data/stops.json
   ```
   - Both files must be identical.
   - Compare the count with the previous version (`git show HEAD:20_Source/BusNow/BusNow/Resources/stops.json`). A large drop usually means the input file is wrong or truncated — stop and report.
   - List added/removed stop names for the report (diff the `name` sets of HEAD vs new).
4. Run the related iOS test class (see the `ios-build-test` skill):
   `StopNameRepositoryTests`.

## Report to the developer

- Stop count before → after, and how many lack a reading
- Added / removed stop names (or the count if the list is long)
- Test result
- Remind them both iOS and Web copies changed and should be committed together
