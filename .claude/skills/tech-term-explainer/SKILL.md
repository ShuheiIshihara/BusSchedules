---
name: tech-term-explainer
description: Use this skill whenever a user asks to explain, look up, or understand any technical term, technology, concept, framework, protocol, algorithm, or jargon. Triggers on phrases like "〇〇とは何ですか", "〇〇を説明して", "〇〇について教えて", "explain X", "what is X", "how does X work". Always invoke this skill when technical terminology needs clarification — even for seemingly simple questions.
---

# Tech Term Explainer

Explain technical terms accurately in Japanese using only established knowledge. No speculation.

See `references/ja_instructions.md` for detailed instructions in Japanese.

## Constraints

- **Facts only**: No speculation, prediction, or hypothesis. Mark uncertain info as "情報不足のため記載なし".
- **Japanese output**: All explanations in Japanese (keep English technical terms as-is).
- **Haiku model**: Always use `model: "haiku"` for the sub-agent to reduce cost.
- **Token logging**: Record `total_tokens` and `duration_ms` from the sub-agent completion notification.

## Steps

### 1. Identify term(s)

Extract the technical term(s) from the user's message.

### 2. Determine output path

Check `CLAUDE.md` in the project root for a `tech_term_output` setting:
- Found → use that directory
- Not found → use the project root (same level as `CLAUDE.md`), or current directory if no `CLAUDE.md` exists

Filename: `{term_in_snake_case}.md` (e.g. `web_socket.md`, `docker.md`)

### 3. Run Haiku sub-agent

Spawn a sub-agent with `model: "haiku"` using this prompt (fill in `{TERM}`):

```
You are a technical glossary expert. Follow these rules strictly:
1. Include only established facts — no speculation, predictions, or personal opinions.
2. Mark anything uncertain as "情報不足のため記載なし".
3. Write entirely in Japanese (keep English technical terms as-is).
4. If you fetch any URLs during research, collect them for the sources list.

Output format (use exactly this structure):
## {TERM}

### 概要
(1–3 sentence definition: what it is and what it is for)

### 仕組み・動作原理
(How it works technically)

### 主な用途・ユースケース
(Real-world use cases)

### 関連技術・概念
(Related technologies, alternatives, prerequisites)

### 参照ソース
(List every URL actually fetched during research, one per line as a Markdown link.
If no URLs were fetched, write "なし（学習データのみ使用）".)

Term to explain: {TERM}
```

### 4. Save to Markdown and log tokens

After the sub-agent completes, append the token record to the output, then save:

```
---
📊 **トークン使用記録**
- モデル: claude-haiku-4-5-20251001
- トークン合計: {total_tokens}
- 実行時間: {duration_ms} ms
```

Save to the path determined in Step 2. Create the directory if it does not exist.

### 5. Report and suggest CLAUDE.md entry

Tell the user the saved path, then suggest adding to `CLAUDE.md`:

```
💡 **提案**: CLAUDE.md に以下を追加すると出力先が自動で統一されます。
## tech-term-explainer
tech_term_output: docs/terms/
```

## Notes

- One file per term when explaining multiple terms simultaneously.
- For version-specific info, note the version: e.g. "〇〇 vX.X 時点の情報".
- Auto-create output directories as needed.

