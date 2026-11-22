#!/bin/bash
# Stop hook: Claude のターン終了時に、Swift の変更があれば iOS アプリをビルドする。
# - 編集ごとではなくターン終了時に1回だけ実行する(ビルドに時間がかかるため)
# - Swift の差分(HEAD との差分 + 未追跡の .swift)が前回ビルド時と同じならスキップする。
#   ビルド失敗時にエラーを Claude に返して修正させるが、差分が変わらなければ再ビルドしないのでループしない。
# - ビルド失敗時は {"decision":"block"} でエラーを返し、Claude に修正を続けさせる。

input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // "default"')
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "$root" ] || exit 0
cd "$root" || exit 0

ios_dir="20_Source/BusNow"
state="${TMPDIR:-/tmp}/busnow-build-${session}.state"

# Swift の変更内容をまとめて hash にする(変更がなければ終了)
changes=$( { git diff HEAD -- "$ios_dir" ':(glob)**/*.swift'; \
             git ls-files --others --exclude-standard -- "$ios_dir" | grep '\.swift$' | while read -r f; do echo "== $f"; cat "$f"; done; } 2>/dev/null )
[ -z "$changes" ] && exit 0
hash=$(printf '%s' "$changes" | shasum | cut -d' ' -f1)

# 同じ状態はビルド済み(成功・失敗とも)なら何もしない
[ -f "$state" ] && [ "$(cat "$state")" = "$hash" ] && exit 0
echo "$hash" > "$state"

log=$(mktemp)
( cd "$ios_dir" && xcodebuild -scheme BusNow -destination 'generic/platform=iOS Simulator' build -quiet ) > "$log" 2>&1
status=$?

if [ $status -eq 0 ]; then
  rm -f "$log"
  echo '{"systemMessage": "iOS ビルド成功(Swift の変更を確認)"}'
  exit 0
fi

errors=$(grep -E '^[^[:space:]|].*error:' "$log" | sed "s|$root/||" | sort -u | head -15)
[ -z "$errors" ] && errors=$(tail -15 "$log")
rm -f "$log"

jq -n --arg e "$errors" '{
  decision: "block",
  reason: ("iOS のビルドが失敗しました。以下のエラーを修正してください(このビルドは Stop hook .claude/hooks/build-on-stop.sh が実行):\n" + $e)
}'
exit 0
