#!/bin/bash
# PreToolUse hook for Bash.
# Blocks shell commands that would read/write secret files or write to the production DB.
# permissions.deny only covers the Read/Edit tools; this closes the shell-side gap (cat, cp, psql, ...).
# Exit 2 = block (stderr is shown to Claude). Exit 0 = allow.

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

block() {
  echo "BLOCKED by .claude/hooks/guard-bash.sh: $1" >&2
  echo "このコマンドはハーネスで禁止されています。必要なら開発者に手動実行を依頼してください。" >&2
  exit 2
}

# 単語境界(パス区切り・空白・引用符などはOK、英数字 . _ - は不可)
B='(^|[^A-Za-z0-9_.-])'
E='($|[^A-Za-z0-9_.-])'

# --- 1. 秘密情報ファイル(.example / .template は対象外) ---
if [[ "$cmd" =~ ${B}\.env(\.local)?${E} ]]; then
  block "secret file (.env / .env.local) is referenced"
fi
if [[ "$cmd" =~ ${B}Config-(Debug|Release)\.xcconfig${E} ]]; then
  block "secret file (Config-Debug/Release.xcconfig) is referenced"
fi

# --- 2. 本番DBへの書き込み ---
# 2a. supabase CLI: 本番に効く書き込み系サブコマンド
if [[ "$cmd" =~ (^|[^A-Za-z0-9_-])supabase[[:space:]] ]]; then
  if [[ "$cmd" =~ supabase[[:space:]]+(db[[:space:]]+push|migration[[:space:]]+repair) ]]; then
    block "supabase command that writes to the linked (production) project"
  fi
  if [[ "$cmd" =~ --linked ]] && ! [[ "$cmd" =~ supabase[[:space:]]+(db[[:space:]]+(dump|pull|diff|lint)|inspect|migration[[:space:]]+list) ]]; then
    block "supabase --linked is only allowed for read-only subcommands (db dump/pull/diff/lint, inspect, migration list)"
  fi
  if [[ "$cmd" =~ --db-url ]] && ! [[ "$cmd" =~ --db-url[=[:space:]]+[\"\']?postgres(ql)?://[^@[:space:]]*@(127\.0\.0\.1|localhost)[:/] ]]; then
    block "supabase --db-url must point to the local stack (127.0.0.1 / localhost)"
  fi
fi

# 2b. psql / pg_restore: ローカル以外への接続
if [[ "$cmd" =~ (^|[^A-Za-z0-9_-])(psql|pg_restore)([[:space:]]|$) ]]; then
  if [[ "$cmd" =~ supabase\.(co|com) ]]; then
    block "psql/pg_restore to a hosted Supabase (production) database"
  fi
  if [[ "$cmd" =~ postgres(ql)?://[^@[:space:]]*@([^:/[:space:]\"\']+) ]]; then
    host="${BASH_REMATCH[2]}"
    case "$host" in
      127.0.0.1|localhost) ;;
      *) block "psql/pg_restore to non-local host: $host" ;;
    esac
  fi
  if [[ "$cmd" =~ (-h|--host)[=[:space:]]+([^[:space:]\"\']+) ]]; then
    host="${BASH_REMATCH[2]}"
    case "$host" in
      127.0.0.1|localhost) ;;
      *) block "psql/pg_restore to non-local host: $host" ;;
    esac
  fi
fi

exit 0
