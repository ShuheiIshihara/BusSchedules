#!/bin/bash
# Stop hook: 重複除去ルール(iOS の SupabaseService.deduplicatedSchedules と scripts/check_dedup.py)の同期を確認する。
# - 関係ファイルに差分がなければ何もしない
# - 差分があれば、共通テストデータで Python 側を検証する(数十ms。xcodebuild は使わない)
# - Swift の deduplicatedSchedules 本体だけが変わり、Python 側とテストデータが変わっていなければ同期漏れとして止める
# - 同じ差分では1回しか止めない(ループ防止)

input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // "default"')
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "$root" ] || exit 0
cd "$root" || exit 0

swift="20_Source/BusNow/BusNow/Services/SupabaseService.swift"
py="scripts/check_dedup.py"
fixture="20_Source/BusNow/BusNowTests/Fixtures/dedup_cases.json"
state="${TMPDIR:-/tmp}/busnow-dedup-${session}.state"

changes=$( { git diff HEAD -- "$swift" "$py" "$fixture"; git ls-files --others --exclude-standard -- "$fixture"; } 2>/dev/null )
[ -z "$changes" ] && exit 0
hash=$(printf '%s' "$changes" | shasum | cut -d' ' -f1)
[ -f "$state" ] && [ "$(cat "$state")" = "$hash" ] && exit 0
echo "$hash" > "$state"

block() {
  jq -n --arg r "$1" '{decision: "block", reason: $r}'
  exit 0
}

# 1. Python 側を共通テストデータで検証
out=$(python3 scripts/test_dedup_rule.py 2>&1)
if [ $? -ne 0 ]; then
  block "重複除去ルールの検証(scripts/test_dedup_rule.py)が失敗しました。check_dedup.py とテストデータ dedup_cases.json を確認してください(Stop hook .claude/hooks/dedup-sync-on-stop.sh):
$out"
fi

# 2. Swift の deduplicatedSchedules 本体が変わったのに、Python 側もテストデータも変わっていないか
extract() { awk '/static func deduplicatedSchedules/{f=1} f{print} f&&/^    }$/{exit}'; }
before=$(git show "HEAD:$swift" 2>/dev/null | extract)
after=$(extract < "$swift")
if [ "$before" != "$after" ] && git diff --quiet HEAD -- "$py" && git diff --quiet HEAD -- "$fixture" 2>/dev/null; then
  block "SupabaseService.deduplicatedSchedules が変更されましたが、scripts/check_dedup.py と BusNowTests/Fixtures/dedup_cases.json は変わっていません。ルールが変わったなら両方とテストデータを更新し、ルールが変わらない変更(リファクタリング等)ならその旨を開発者に伝えてください。iOS 側の検証は DedupRuleTests(xcodebuild は開発者に実行を依頼)。"
fi

echo '{"systemMessage": "重複除去ルール: Python 側の共通テストデータ検証に合格"}'
exit 0
